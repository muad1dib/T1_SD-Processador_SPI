module Processador(
    input logic clock,
    input logic reset,
    single_port_ram_port_if.CPU mem_port
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
    // REGISTRADORES DE UMA ÚNICA INSTRUÇÃO
    // ======================================
    
    logic [15:0] instrucao_atual;
    logic [3:0] opcode;
    logic [3:0] rd, rs1, rs2;
    logic [31:0] operand_a, operand_b;
    logic [31:0] resultado;

    // ======================================
    // CONTROLE DA CPU
    // ======================================
    
    logic [15:0] PC;
    logic [1:0] cycle_counter;
    
    typedef enum logic [1:0] {
        FETCH    = 2'b00,
        DECODE   = 2'b01,
        EXECUTE  = 2'b10,
        WRITEBACK = 2'b11
    } cpu_state_t;
    
    cpu_state_t current_state;

    // ======================================
    // MÁQUINA DE ESTADOS
    // ======================================
    
    always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
            current_state <= FETCH;
            PC <= 16'b0;
            cycle_counter <= 2'b00;
            instrucao_atual <= 16'b0;
            operand_a <= 32'b0;
            operand_b <= 32'b0;
            resultado <= 32'b0;
        end else begin
            case (cycle_counter)
                2'b00: current_state <= FETCH;
                2'b01: current_state <= DECODE;
                2'b10: current_state <= EXECUTE;
                2'b11: current_state <= WRITEBACK;
            endcase
            
            cycle_counter <= cycle_counter + 1;
        end
    end

    // ======================================
    // CONTROLE DE MEMÓRIA - FETCH
    // ======================================
    
    always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
            mem_port.en <= 1'b0;
            mem_port.we <= 1'b0;
            mem_port.addr <= 8'b0;
            mem_port.wdata <= 32'b0;
        end else if (current_state == FETCH) begin
            mem_port.en <= 1'b1;
            mem_port.we <= 1'b0;
            mem_port.addr <= PC[7:0];
            mem_port.wdata <= 32'b0;
        end else begin
            mem_port.en <= 1'b0;
            mem_port.we <= 1'b0;
        end
    end

    // ======================================
    // ESTÁGIO DECODE - CAPTURA E DECODIFICAÇÃO
    // ======================================
    
    always_ff @(posedge clock) begin
        if (current_state == DECODE) begin
            instrucao_atual <= mem_port.rdata[15:0];
            
            opcode <= mem_port.rdata[31:28];
            rd <= mem_port.rdata[27:24];
            rs1 <= mem_port.rdata[23:20];
            rs2 <= mem_port.rdata[19:16];
        end
    end
    
    always_comb begin
        rb_if.raddr1 = rs1;
        rb_if.raddr2 = rs2;
    end

    // ======================================
    // ESTÁGIO EXECUTE - CAPTURA DE OPERANDOS E EXECUÇÃO
    // ======================================
    
    always_ff @(posedge clock) begin
        if (current_state == EXECUTE) begin
            operand_a <= rb_if.rdata1;
            operand_b <= rb_if.rdata2;
            
            case (opcode)
                4'b0000: resultado <= rb_if.rdata1 + rb_if.rdata2; 
                4'b0001: resultado <= rb_if.rdata1 - rb_if.rdata2;  
                4'b0010: resultado <= rb_if.rdata1 & rb_if.rdata2; 
                4'b0011: resultado <= rb_if.rdata1 | rb_if.rdata2; 
                4'b0100: resultado <= rb_if.rdata1 ^ rb_if.rdata2; 
                4'b0101: resultado <= ~rb_if.rdata1;                
                4'b0110: resultado <= rb_if.rdata1 << rb_if.rdata2[4:0]; 
                4'b0111: resultado <= rb_if.rdata1 >> rb_if.rdata2[4:0]; 
                4'b1001: resultado <= rb_if.rdata1 * rb_if.rdata2;  
                default: resultado <= 32'b0;
            endcase
        end
    end

    // ======================================
    // ESTÁGIO WRITEBACK
    // ======================================
    
    always_ff @(posedge clock) begin
        if (current_state == WRITEBACK) begin
            if (rd != 4'b0000) begin 
                rb_if.we <= 1'b1;
                rb_if.waddr <= rd;
                rb_if.wdata <= resultado;
            end else begin
                rb_if.we <= 1'b0;
            end
            
            PC <= PC + 1;
            
        end else begin
            rb_if.we <= 1'b0;
        end
    end

endmodule