module multiplicador (
    input logic clock,
    input logic reset,
    spi_if.SLAVE spi_if
);

    localparam OP_MUL = 4'b1001;
    
    typedef enum logic [2:0] {
        IDLE,
        RECEIVE_OP,
        RECEIVE_A,
        RECEIVE_B,
        EXECUTE,
        SEND_RESULT
    } state_t;

    logic [31:0] operand_a;
    logic [31:0] operand_b;
    logic [3:0] opcode;
    logic [63:0] mul_result_full; 
    logic [31:0] result;
    
    state_t current_state, next_state;
    logic [5:0] bit_counter;
    logic [31:0] spi_shift_reg;

    assign mul_result_full = operand_a * operand_b;
    
    assign result = (opcode == OP_MUL) ? mul_result_full[31:0] : 32'b0;

    always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
            current_state <= IDLE;
            operand_a <= 32'b0;
            operand_b <= 32'b0;
            opcode <= 4'b0;
            bit_counter <= 6'b0;
            spi_shift_reg <= 32'b0;
        end else begin
            current_state <= next_state;
            
            case (current_state)
                IDLE: begin
                    bit_counter <= 6'b0;
                    if (~spi_if.nss) begin
                        spi_shift_reg <= 32'b0;
                    end
                end
                
                RECEIVE_OP: begin
                    if (~spi_if.nss && spi_if.sclk) begin
                        spi_shift_reg <= {spi_shift_reg[30:0], spi_if.mosi};
                        bit_counter <= bit_counter + 1;
                        if (bit_counter == 3) begin
                            opcode <= {spi_shift_reg[2:0], spi_if.mosi};
                            bit_counter <= 6'b0;
                        end
                    end
                end
                
                RECEIVE_A: begin
                    if (~spi_if.nss && spi_if.sclk) begin
                        spi_shift_reg <= {spi_shift_reg[30:0], spi_if.mosi};
                        bit_counter <= bit_counter + 1;
                        if (bit_counter == 31) begin
                            operand_a <= {spi_shift_reg[30:0], spi_if.mosi};
                            bit_counter <= 6'b0;
                        end
                    end
                end
                
                RECEIVE_B: begin
                    if (~spi_if.nss && spi_if.sclk) begin
                        spi_shift_reg <= {spi_shift_reg[30:0], spi_if.mosi};
                        bit_counter <= bit_counter + 1;
                        if (bit_counter == 31) begin
                            operand_b <= {spi_shift_reg[30:0], spi_if.mosi};
                            bit_counter <= 6'b0;
                        end
                    end
                end
                
                EXECUTE: begin
                    spi_shift_reg <= result;
                    bit_counter <= 6'b0;
                end
                
                SEND_RESULT: begin
                    if (~spi_if.nss && ~spi_if.sclk) begin
                        spi_shift_reg <= {spi_shift_reg[30:0], 1'b0};
                        bit_counter <= bit_counter + 1;
                        if (bit_counter == 31) begin
                            bit_counter <= 6'b0;
                        end
                    end
                end
            endcase
        end
    end

    always_comb begin
        case (current_state)
            IDLE: next_state = (~spi_if.nss) ? RECEIVE_OP : IDLE;
            RECEIVE_OP: next_state = (spi_if.nss) ? IDLE : 
                                   (bit_counter == 3 && spi_if.sclk) ? RECEIVE_A : RECEIVE_OP;
            RECEIVE_A: next_state = (spi_if.nss) ? IDLE : 
                                  (bit_counter == 31 && spi_if.sclk) ? RECEIVE_B : RECEIVE_A;
            RECEIVE_B: next_state = (spi_if.nss) ? IDLE : 
                                  (bit_counter == 31 && spi_if.sclk) ? EXECUTE : RECEIVE_B;
            EXECUTE: next_state = SEND_RESULT;
            SEND_RESULT: next_state = (spi_if.nss) ? IDLE : 
                                    (bit_counter == 31 && ~spi_if.sclk) ? IDLE : SEND_RESULT;
            default: next_state = IDLE;
        endcase
    end

    assign spi_if.miso = (current_state == SEND_RESULT) ? spi_shift_reg[31] : 1'b0;

endmodule