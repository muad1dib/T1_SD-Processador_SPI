module barrel_shifter #(
    parameter REG_WIDTH = 32
)(
    input logic clock,
    input logic reset,
    spi_if.SLAVE spi_if
);

    localparam OP_SHL = 4'b0110; 
    localparam OP_SHR = 4'b0111;  

    typedef enum logic [2:0] {
        IDLE,
        RECEIVE_OP,
        RECEIVE_A,
        RECEIVE_B,
        EXECUTE,
        SEND_RESULT
    } state_t;

    logic [REG_WIDTH-1:0] operand_a;
    logic [REG_WIDTH-1:0] operand_b;
    logic [3:0] opcode;
    logic [REG_WIDTH-1:0] result;
    logic [REG_WIDTH-1:0] shift_result;
    
    state_t current_state;
    logic [5:0] bit_counter;
    logic [REG_WIDTH-1:0] spi_shift_reg;

    // Detecção de borda simplificada
    logic spi_clk_prev;
    logic spi_clk_rising;
    
    always_ff @(posedge clock) begin
        spi_clk_prev <= spi_if.sclk;
    end
    
    assign spi_clk_rising = spi_if.sclk && !spi_clk_prev;

    always_comb begin
        case (opcode)
            OP_SHL: begin 
                shift_result = operand_a << operand_b[4:0]; 
            end
            OP_SHR: begin 
                shift_result = operand_a >> operand_b[4:0];
            end
            default: begin
                shift_result = operand_a; 
            end
        endcase
    end

    // Máquina de estados simplificada (igual à ALU)
    always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
            current_state <= IDLE;
            operand_a <= 32'b0;
            operand_b <= 32'b0;
            opcode <= 4'b0;
            result <= 32'b0;
            bit_counter <= 6'b0;
            spi_shift_reg <= 32'b0;
        end else begin
            
            case (current_state)
                IDLE: begin
                    if (~spi_if.nss) begin
                        current_state <= RECEIVE_OP;
                        bit_counter <= 6'b0;
                        spi_shift_reg <= 32'b0;
                    end
                end
                
                RECEIVE_OP: begin
                    if (spi_if.nss) begin
                        current_state <= IDLE;
                    end else if (spi_clk_rising) begin
                        spi_shift_reg <= {spi_shift_reg[30:0], spi_if.mosi};
                        bit_counter <= bit_counter + 1;
                        
                        if (bit_counter == 3) begin // Recebeu 4 bits (0,1,2,3)
                            opcode <= {spi_shift_reg[2:0], spi_if.mosi};
                            current_state <= RECEIVE_A;
                            bit_counter <= 6'b0;
                            spi_shift_reg <= 32'b0;
                        end
                    end
                end
                
                RECEIVE_A: begin
                    if (spi_if.nss) begin
                        current_state <= IDLE;
                    end else if (spi_clk_rising) begin
                        spi_shift_reg <= {spi_shift_reg[30:0], spi_if.mosi};
                        bit_counter <= bit_counter + 1;
                        
                        if (bit_counter == 31) begin // Recebeu 32 bits (0-31)
                            operand_a <= {spi_shift_reg[30:0], spi_if.mosi};
                            current_state <= RECEIVE_B;
                            bit_counter <= 6'b0;
                            spi_shift_reg <= 32'b0;
                        end
                    end
                end
                
                RECEIVE_B: begin
                    if (spi_if.nss) begin
                        current_state <= IDLE;
                    end else if (spi_clk_rising) begin
                        spi_shift_reg <= {spi_shift_reg[30:0], spi_if.mosi};
                        bit_counter <= bit_counter + 1;
                        
                        if (bit_counter == 31) begin // Recebeu 32 bits (0-31)
                            operand_b <= {spi_shift_reg[30:0], spi_if.mosi};
                            current_state <= EXECUTE;
                            bit_counter <= 6'b0;
                        end
                    end
                end
                
                EXECUTE: begin
                    result <= shift_result;
                    spi_shift_reg <= shift_result;
                    current_state <= SEND_RESULT;
                    bit_counter <= 6'b0;
                end
                
                SEND_RESULT: begin
                    if (spi_if.nss) begin
                        current_state <= IDLE;
                    end else if (spi_clk_rising) begin
                        // Shift para próximo bit
                        spi_shift_reg <= {spi_shift_reg[30:0], 1'b0};
                        bit_counter <= bit_counter + 1;
                        
                        if (bit_counter == 31) begin // Enviou 32 bits
                            current_state <= IDLE;
                            bit_counter <= 6'b0;
                        end
                    end
                end
                
                default: begin
                    current_state <= IDLE;
                end
            endcase
        end
    end

    // MISO sempre transmite o bit mais significativo durante SEND_RESULT
    assign spi_if.miso = (current_state == SEND_RESULT) ? spi_shift_reg[31] : 1'b0;

endmodule