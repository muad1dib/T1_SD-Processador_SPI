module alu (
    input  logic clock,
    input  logic reset,
    spi_if.SLAVE spi_if
);

    localparam OP_ADD  = 4'b0000;
    localparam OP_SUB  = 4'b0001;
    localparam OP_AND  = 4'b0010;
    localparam OP_OR   = 4'b0011;
    localparam OP_XOR  = 4'b0100;
    localparam OP_NOT  = 4'b0101;
    localparam OP_SHL  = 4'b0110;
    localparam OP_SHR  = 4'b0111;
        
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
    logic [31:0] result;
    logic [31:0] alu_result;
    logic zero, carry, overflow;
    
    state_t current_state, next_state;
    logic [5:0] bit_counter;
    logic [31:0] spi_shift_reg;
    
    logic [32:0] add_sub;
    logic [31:0] logic_out;
    logic        add_carry, sub_carry, add_overflow, sub_overflow;
    
    assign add_sub = (opcode == OP_SUB) ? {1'b0, operand_a} - {1'b0, operand_b} : {1'b0, operand_a} + {1'b0, operand_b};
    assign add_carry = add_sub[32];
    assign sub_carry = add_sub[32];
    assign add_overflow = (~operand_a[31] & ~operand_b[31] & add_sub[31]) | (operand_a[31] & operand_b[31] & ~add_sub[31]);
    assign sub_overflow = (operand_a[31] & ~operand_b[31] & ~add_sub[31]) | (~operand_a[31] & operand_b[31] & add_sub[31]);
    
    always_comb begin
        case (opcode)
            OP_AND: logic_out = operand_a & operand_b;
            OP_OR:  logic_out = operand_a | operand_b;
            OP_XOR: logic_out = operand_a ^ operand_b;
            OP_NOT: logic_out = ~operand_a;
            OP_SHL: logic_out = operand_a << operand_b[4:0];
            OP_SHR: logic_out = operand_a >> operand_b[4:0];
            OP_SAR: logic_out = $signed(operand_a) >>> operand_b[4:0];
            default: logic_out = 32'b0;
        endcase
    end
    
    always_comb begin
        case (opcode)
            OP_ADD: alu_result = add_sub[31:0];
            OP_SUB: alu_result = add_sub[31:0];
            OP_AND, OP_OR, OP_XOR, OP_NOT, OP_SHL, OP_SHR, OP_SAR: alu_result = logic_out;
            default: alu_result = 32'b0;
        endcase
    end
    
    assign zero = (alu_result == 32'b0);
    assign carry = (opcode == OP_ADD) ? add_carry :
                   (opcode == OP_SUB) ? sub_carry : 1'b0;
    assign overflow = (opcode == OP_ADD) ? add_overflow :
                      (opcode == OP_SUB) ? sub_overflow : 1'b0;

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
                    result <= alu_result;
                    spi_shift_reg <= alu_result;
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