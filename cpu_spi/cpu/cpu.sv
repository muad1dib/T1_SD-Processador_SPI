module cpu(
    input  logic clock,
    input  logic reset,
    single_port_ram_port_if.CPU mem_port
);

    // INTERFACES E INSTANCIAÇÕES
    regbank_if #(.REG_WIDTH(32), .REG_COUNT(16)) rb_if(clock, ~reset);
    regbank #(.REG_WIDTH(32), .REG_COUNT(16)) rb_inst(clock, ~reset, rb_if.REGBANK);

    spi_if alu_spi(clock, reset);
    spi_if mul_spi(clock, reset);
    spi_if bas_spi(clock, reset);

    alu           alu_inst(clock, reset, alu_spi.SLAVE);
    multiplier mul_inst(clock, reset, mul_spi.SLAVE);
    barrel_shifter bas_inst(clock, reset, bas_spi.SLAVE);

    logic [31:0] instrucao_atual;
    logic [3:0]  opcode;
    logic [3:0]  rd, rs1, rs2;
    logic [31:0] operand_a, operand_b;
    logic [31:0] resultado;

    logic [15:0] PC;
    logic [1:0]  cycle_counter;

    typedef enum logic [1:0] {
        FETCH     = 2'b00,
        DECODE    = 2'b01,
        EXECUTE   = 2'b10,
        WRITEBACK = 2'b11
    } cpu_state_t;

    cpu_state_t current_state;

    typedef enum logic [2:0] {
        SPI_IDLE,
        SPI_SEND_OP,
        SPI_SEND_A,
        SPI_SEND_B,
        SPI_WAIT_RESULT,
        SPI_RECEIVE_RESULT
    } spi_state_t;

    spi_state_t spi_state;
    logic [5:0] spi_bit_counter;
    logic [31:0] spi_tx_data;
    logic [31:0] spi_rx_data;
    logic spi_operation_complete;
    
    logic spi_clk;
    logic [2:0] spi_clk_div;
    
    always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
            spi_clk_div <= 3'b0;
        end else begin
            spi_clk_div <= spi_clk_div + 1;
        end
    end
    
    assign spi_clk = spi_clk_div[2]; // Clock 8x mais lento que o clock principal
    
    logic use_alu, use_mul, use_bas;
    
    always_comb begin
        use_alu = (opcode >= 4'b0000 && opcode <= 4'b0101); // ADD, SUB, AND, OR, XOR, NOT (0-5)
        use_mul = (opcode == 4'b1001); // MUL (9)
        use_bas = (opcode == 4'b0110 || opcode == 4'b0111); // SHL, SHR (6,7)
    end

    // MÁQUINA DE ESTADOS PRINCIPAL
    always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
            current_state   <= FETCH;
            PC              <= 16'b0;
            cycle_counter   <= 2'b00;
            instrucao_atual <= 32'b0;
            opcode          <= 4'b0;
            rd              <= 4'b0;
            rs1             <= 4'b0;
            rs2             <= 4'b0;
            operand_a       <= 32'b0;
            operand_b       <= 32'b0;
            resultado       <= 32'b0;
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

    // ESTÁGIO FETCH
    always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
            mem_port.en    <= 1'b0;
            mem_port.we    <= 1'b0;
            mem_port.addr  <= 8'b0;
            mem_port.wdata <= 32'b0;
        end else if (current_state == FETCH) begin
            mem_port.en    <= 1'b1;
            mem_port.we    <= 1'b0;
            mem_port.addr  <= PC[7:0];
        end else begin
            mem_port.en    <= 1'b0;
            mem_port.we    <= 1'b0;
        end
    end

    // ESTÁGIO DECODE
    always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
            instrucao_atual <= 32'b0;
            opcode          <= 4'b0;
            rd              <= 4'b0;
            rs1             <= 4'b0;
            rs2             <= 4'b0;
        end else if (current_state == DECODE) begin
            instrucao_atual <= mem_port.rdata;
            opcode          <= mem_port.rdata[31:28];
            rd              <= mem_port.rdata[27:24];
            rs1             <= mem_port.rdata[23:20];
            rs2             <= mem_port.rdata[19:16];
        end
    end

    // PREPARAR LEITURAS DO BANCO DE REGISTRADORES 
    always_comb begin
        rb_if.raddr1 = rs1[3:0]; 
        rb_if.raddr2 = rs2[3:0]; 
    end

    logic spi_clk_prev;
    logic spi_clk_rising, spi_clk_falling;
    
    always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
            spi_clk_prev <= 1'b0;
        end else begin
            spi_clk_prev <= spi_clk;
        end
    end
    
    assign spi_clk_rising = spi_clk && !spi_clk_prev;
    assign spi_clk_falling = !spi_clk && spi_clk_prev;

    always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
            operand_a <= 32'b0;
            operand_b <= 32'b0;
        end else if (current_state == DECODE) begin
            operand_a <= rb_if.rdata1;
            operand_b <= rb_if.rdata2;
        end
    end

    // MÁQUINA DE ESTADOS SPI 
    always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
            spi_state <= SPI_IDLE;
            spi_bit_counter <= 6'b0;
            spi_tx_data <= 32'b0;
            spi_rx_data <= 32'b0;
            spi_operation_complete <= 1'b0;
        end else begin
            case (spi_state)
                SPI_IDLE: begin
                    if (current_state == EXECUTE && opcode != 4'b0000) begin 
                        spi_state <= SPI_SEND_OP;
                        spi_bit_counter <= 6'b0;
                        spi_tx_data <= {28'b0, opcode};
                        spi_operation_complete <= 1'b0;
                    end
                end
                
                SPI_SEND_OP: begin
                    if (spi_clk_rising) begin
                        if (spi_bit_counter < 3) begin 
                            spi_bit_counter <= spi_bit_counter + 1;
                        end else begin
                            spi_state <= SPI_SEND_A;
                            spi_bit_counter <= 6'b0;
                            spi_tx_data <= operand_a;
                        end
                    end
                end
                
                SPI_SEND_A: begin
                    if (spi_clk_rising) begin
                        if (spi_bit_counter < 31) begin 
                            spi_bit_counter <= spi_bit_counter + 1;
                        end else begin
                            spi_state <= SPI_SEND_B;
                            spi_bit_counter <= 6'b0;
                            spi_tx_data <= operand_b;
                        end
                    end
                end
                
                SPI_SEND_B: begin
                    if (spi_clk_rising) begin
                        if (spi_bit_counter < 31) begin 
                            spi_bit_counter <= spi_bit_counter + 1;
                        end else begin
                            spi_state <= SPI_WAIT_RESULT;
                            spi_bit_counter <= 6'b0;
                            spi_rx_data <= 32'b0; 
                        end
                    end
                end
                
                SPI_WAIT_RESULT: begin
                    if (spi_clk_rising) begin
                        if (spi_bit_counter < 7) begin 
                            spi_bit_counter <= spi_bit_counter + 1;
                        end else begin
                            spi_state <= SPI_RECEIVE_RESULT;
                            spi_bit_counter <= 6'b0;
                        end
                    end
                end
                
                SPI_RECEIVE_RESULT: begin
                    if (spi_clk_falling) begin
                        if (spi_bit_counter < 31) begin 
                            spi_bit_counter <= spi_bit_counter + 1;
                            if (use_alu) begin
                                spi_rx_data <= {spi_rx_data[30:0], alu_spi.miso};
                            end else if (use_mul) begin
                                spi_rx_data <= {spi_rx_data[30:0], mul_spi.miso};
                            end else if (use_bas) begin
                                spi_rx_data <= {spi_rx_data[30:0], bas_spi.miso};
                            end
                        end else begin
                            // Último bit
                            if (use_alu) begin
                                resultado <= {spi_rx_data[30:0], alu_spi.miso};
                            end else if (use_mul) begin
                                resultado <= {spi_rx_data[30:0], mul_spi.miso};
                            end else if (use_bas) begin
                                resultado <= {spi_rx_data[30:0], bas_spi.miso};
                            end
                            spi_operation_complete <= 1'b1;
                            spi_state <= SPI_IDLE;
                        end
                    end
                end
            endcase
        end
    end

    // CONTROLE DOS SINAIS SPI 
    always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
            // Defaults para ALU
            alu_spi.sclk <= 1'b0;
            alu_spi.mosi <= 1'b0;
            alu_spi.nss <= 1'b1;
            
            // Defaults para MUL
            mul_spi.sclk <= 1'b0;
            mul_spi.mosi <= 1'b0;
            mul_spi.nss <= 1'b1;
            
            // Defaults para BAS
            bas_spi.sclk <= 1'b0;
            bas_spi.mosi <= 1'b0;
            bas_spi.nss <= 1'b1;
        end else begin
            alu_spi.sclk <= 1'b0;
            alu_spi.mosi <= 1'b0;
            alu_spi.nss <= 1'b1;
            mul_spi.sclk <= 1'b0;
            mul_spi.mosi <= 1'b0;
            mul_spi.nss <= 1'b1;
            bas_spi.sclk <= 1'b0;
            bas_spi.mosi <= 1'b0;
            bas_spi.nss <= 1'b1;

            case (spi_state)
                SPI_SEND_OP, SPI_SEND_A, SPI_SEND_B, SPI_WAIT_RESULT, SPI_RECEIVE_RESULT: begin
                    if (use_alu) begin
                        alu_spi.nss <= 1'b0;
                        alu_spi.sclk <= spi_clk;
                        case (spi_state)
                            SPI_SEND_OP: alu_spi.mosi <= spi_tx_data[3-spi_bit_counter];
                            SPI_SEND_A, SPI_SEND_B: alu_spi.mosi <= spi_tx_data[31-spi_bit_counter];
                            default: alu_spi.mosi <= 1'b0;
                        endcase
                    end else if (use_mul) begin
                        mul_spi.nss <= 1'b0;
                        mul_spi.sclk <= spi_clk;
                        case (spi_state)
                            SPI_SEND_OP: mul_spi.mosi <= spi_tx_data[3-spi_bit_counter];
                            SPI_SEND_A, SPI_SEND_B: mul_spi.mosi <= spi_tx_data[31-spi_bit_counter];
                            default: mul_spi.mosi <= 1'b0;
                        endcase
                    end else if (use_bas) begin
                        bas_spi.nss <= 1'b0;
                        bas_spi.sclk <= spi_clk;
                        case (spi_state)
                            SPI_SEND_OP: bas_spi.mosi <= spi_tx_data[3-spi_bit_counter];
                            SPI_SEND_A, SPI_SEND_B: bas_spi.mosi <= spi_tx_data[31-spi_bit_counter];
                            default: bas_spi.mosi <= 1'b0;
                        endcase
                    end
                end
                
                default: begin
                end
            endcase
        end
    end

    // ESTÁGIO EXECUTE - 
    always_ff @(posedge clock) begin
        if (current_state == EXECUTE) begin
            case (opcode)
                4'b0000: resultado <= 32'b0; 
                default: begin
                    if (!spi_operation_complete && spi_state == SPI_IDLE) begin
                    end
                end
            endcase
        end
    end

    // ESTÁGIO WRITEBACK - CORRIGIDO
    always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
            rb_if.we    <= 1'b0;
            rb_if.waddr <= '0;
            rb_if.wdata <= '0;
            PC          <= 16'b0;
        end else if (current_state == WRITEBACK) begin
            if (rd[3:0] != 4'b0000 && (opcode == 4'b0000 || spi_operation_complete)) begin 
                rb_if.we    <= 1'b1;
                rb_if.waddr <= rd[3:0]; 
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
