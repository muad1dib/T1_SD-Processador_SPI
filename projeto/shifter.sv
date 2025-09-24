module shifter #(
    parameter REG_WIDTH = 32
)(
    input logic clock,
    input logic reset,
    spi_if.SLAVE spi_if
);

    localparam OP_SHL = 4'b0110; 
    localparam OP_SHR = 4'b0111;  
    localparam OP_SAR = 4'b1000;  

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
    
    state_t current_state, next_state;
    logic [5:0] bit_counter;
    logic [REG_WIDTH-1:0] spi_shift_reg;
    logic operation_done;

    always_comb begin
        case (opcode)
            OP_SHL: begin 
                shift_result = operand_a << operand_b[4:0]; 
            end
            OP_SHR: begin 
                shift_result = operand_a >> operand_b[4:0];
            end
            OP_SAR: begin 
                shift_result = $signed(operand_a) >>> operand_b[4:0];
            end
            default: begin
                shift_result = operand_a; 
            end
        endcase
    end

    always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
            current_state <= IDLE;
            operand_a <= 32'b0;
            operand_b <= 32'b0;
            opcode <= 4'b0;
            result <= 32'b0;
            bit_counter <= 6'b0;
            spi_shift_reg <= 32'b0;
            operation_done <= 1'b0;
        end else begin
            current_state <= next_state;
            
            case (current_state)
                IDLE: begin
                    bit_counter <= 6'b0;
                    operation_done <= 1'b0;
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
                    result <= shift_result; 
                    operation_done <= 1'b1;
                    spi_shift_reg <= shift_result;
                    bit_counter <= 6'b0;
                end
                
                SEND_RESULT: begin
                    if (~spi_if.nss && ~spi_if.sclk) begin 
                        spi_shift_reg <= {spi_shift_reg[30:0], 1'b0};
                        bit_counter <= bit_counter + 1;
                        if (bit_counter == 31) begin
                            operation_done <= 1'b0;
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

    always_comb begin
        case (current_state)
            IDLE: begin
                if (~spi_if.nss) begin
                    next_state = RECEIVE_OP;
                end else begin
                    next_state = IDLE;
                end
            end
            
            RECEIVE_OP: begin
                if (spi_if.nss) begin
                    next_state = IDLE;
                end else if (bit_counter == 3 && spi_if.sclk) begin
                    next_state = RECEIVE_A;
                end else begin
                    next_state = RECEIVE_OP;
                end
            end
            
            RECEIVE_A: begin
                if (spi_if.nss) begin
                    next_state = IDLE;
                end else if (bit_counter == 31 && spi_if.sclk) begin
                    next_state = RECEIVE_B;
                end else begin
                    next_state = RECEIVE_A;
                end
            end
            
            RECEIVE_B: begin
                if (spi_if.nss) begin
                    next_state = IDLE;
                end else if (bit_counter == 31 && spi_if.sclk) begin
                    next_state = EXECUTE;
                end else begin
                    next_state = RECEIVE_B;
                end
            end
            
            EXECUTE: begin
                next_state = SEND_RESULT;
            end
            
            SEND_RESULT: begin
                if (spi_if.nss) begin
                    next_state = IDLE;
                end else if (bit_counter == 31 && ~spi_if.sclk) begin
                    next_state = IDLE;
                end else begin
                    next_state = SEND_RESULT;
                end
            end
            
            default: begin
                next_state = IDLE;
            end
        endcase
    end

    assign spi_if.miso = (current_state == SEND_RESULT) ? spi_shift_reg[31] : 1'b0;

endmodule
