module Processador(
    input logic clock,
    input logic reset,
    dual_port_ram_port_if.CPU mem_a,
    dual_port_ram_port_if.CPU mem_b
);

    // ======================================
    // INTERFACES E INSTANCIAÇÕES
    // ======================================
    
    regbank_if rb_if(clock, ~reset);
    regbank rb_inst(clock, ~reset, rb_if.REGBANK);

    spi_if alu_spi(clock, reset);
    spi_if mul_spi(clock, reset);
    spi_if bas_spi(clock, reset);

    alu alu_inst(clock, reset, alu_spi.SLAVE);
    multiplicador mul_inst(clock, reset, mul_spi.SLAVE);
    barrel_shifter bas_inst(clock, reset, bas_spi.SLAVE);

    // ======================================
    // BARREIRAS TEMPORAIS 
    // ======================================
    
    typedef struct packed {
        logic [15:0] instrucao;
        logic [15:0] pc_atual;
    } fetch_to_decode_t;

    typedef struct packed {
        logic [3:0] opcode;
        logic [3:0] rd;     
        logic [3:0] rs1;    
        logic [3:0] rs2;    
        logic [31:0] operand_a;
        logic [31:0] operand_b;
        logic [15:0] pc_atual;
    } decode_to_execute_t;

    typedef struct packed {
        logic [31:0] resultado;
        logic [3:0] rd;
        logic write_enable;
        logic [15:0] pc_atual;
    } execute_to_writeback_t;

    fetch_to_decode_t fetch_decode_reg;
    decode_to_execute_t decode_execute_reg;
    execute_to_writeback_t execute_writeback_reg;

    // ======================================
    // REGISTRADORES DE CONTROLE DA CPU
    // ======================================
    
    logic [15:0] PC;
    logic [3:0] cycle_counter;
    
    typedef enum logic [1:0] {
        FETCH    = 2'b00,
        DECODE   = 2'b01,
        EXECUTE  = 2'b10,
        WRITEBACK = 2'b11
    } cpu_state_t;
    
    cpu_state_t current_state, next_state;

    // ======================================
    // MÁQUINA DE ESTADOS PRINCIPAL
    // ======================================
    
    always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
            current_state <= FETCH;
            PC <= 16'b0;
            cycle_counter <= 4'b0;
            fetch_decode_reg <= '0;
            decode_execute_reg <= '0;
            execute_writeback_reg <= '0;
        end else begin
            current_state <= next_state;
            cycle_counter <= cycle_counter + 1;
        end
    end

    always_comb begin
        case (cycle_counter[1:0])
            2'b00: next_state = FETCH;
            2'b01: next_state = DECODE;
            2'b10: next_state = EXECUTE;
            2'b11: next_state = WRITEBACK;
        endcase
    end

    // ======================================
    // ESTÁGIO FETCH
    // ======================================
    
    always_ff @(posedge clock) begin
        if (current_state == FETCH) begin
            mem_a.en <= 1'b1;
            mem_a.we <= 1'b0;
            mem_a.addr <= PC[7:0];
            mem_a.wdata <= 32'b0;
            
            fetch_decode_reg.instrucao <= mem_a.rdata[15:0];
            fetch_decode_reg.pc_atual <= PC;
            
            PC <= PC + 1;
        end
    end

    // ======================================
    // ESTÁGIO DECODE
    // ======================================
    
    always_ff @(posedge clock) begin
        if (current_state == DECODE) begin
            decode_execute_reg.opcode <= fetch_decode_reg.instrucao[15:12];
            decode_execute_reg.rd <= fetch_decode_reg.instrucao[11:8];
            decode_execute_reg.rs1 <= fetch_decode_reg.instrucao[7:4];
            decode_execute_reg.rs2 <= fetch_decode_reg.instrucao[3:0];
            decode_execute_reg.pc_atual <= fetch_decode_reg.pc_atual;
            
            rb_if.raddr1 <= fetch_decode_reg.instrucao[7:4];  // rs1
            rb_if.raddr2 <= fetch_decode_reg.instrucao[3:0];  // rs2
            
            decode_execute_reg.operand_a <= rb_if.rdata1;
            decode_execute_reg.operand_b <= rb_if.rdata2;
        end
    end

    // ======================================
    // ESTÁGIO EXECUTE
    // ======================================
    
    typedef enum logic [1:0] {
        EXEC_IDLE,
        EXEC_SEND,
        EXEC_WAIT,
        EXEC_RECEIVE
    } exec_state_t;
    
    exec_state_t exec_current_state;
    logic [31:0] exec_result;
    logic exec_done;

    always_ff @(posedge clock) begin
        if (current_state == EXECUTE) begin
            case (decode_execute_reg.opcode)
                4'b0000, 4'b0001, 4'b0010, 4'b0011, 4'b0100, 4'b0101: begin
                    exec_result <= decode_execute_reg.operand_a + decode_execute_reg.operand_b; 
                    exec_done <= 1'b1;
                end
                
                4'b1001: begin
                    exec_result <= decode_execute_reg.operand_a * decode_execute_reg.operand_b; 
                    exec_done <= 1'b1;
                end
                
                4'b0110, 4'b0111, 4'b1000: begin
                    exec_result <= decode_execute_reg.operand_a << decode_execute_reg.operand_b[4:0]; 
                    exec_done <= 1'b1;
                end
                
                default: begin
                    exec_result <= 32'b0;
                    exec_done <= 1'b1;
                end
            endcase
            
            execute_writeback_reg.resultado <= exec_result;
            execute_writeback_reg.rd <= decode_execute_reg.rd;
            execute_writeback_reg.write_enable <= 1'b1;
            execute_writeback_reg.pc_atual <= decode_execute_reg.pc_atual;
        end
    end

    // ======================================
    // ESTÁGIO WRITEBACK
    // ======================================
    
    always_ff @(posedge clock) begin
        if (current_state == WRITEBACK) begin
            if (execute_writeback_reg.write_enable) begin
                rb_if.we <= 1'b1;
                rb_if.waddr <= execute_writeback_reg.rd;
                rb_if.wdata <= execute_writeback_reg.resultado;
            end else begin
                rb_if.we <= 1'b0;
            end
        end else begin
            rb_if.we <= 1'b0;
        end
    end

    // ======================================
    // INICIALIZAÇÃO E CONTROLE
    // ======================================
    
    initial begin
        PC = 16'b0;
        cycle_counter = 4'b0;
    end

endmodule
