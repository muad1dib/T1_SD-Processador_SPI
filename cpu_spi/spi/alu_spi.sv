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
    
    state_t current_state, next_state;
    logic [5:0] bit_counter;
    logic [31:0] spi_shift_reg;
    
    logic spi_clk_prev;
    logic spi_clk_rising;
    
    always_ff @(posedge clock) begin
        spi_clk_prev <= spi_if.sclk;
    end
    
    assign spi_clk_rising = spi_if.sclk && !spi_clk_prev;
    
    logic [32:0] add_sub;
    logic [31:0] logic_out;
    
    assign add_sub = (opcode == OP_SUB) ? {1'b0, operand_a} - {1'b0, operand_b} : {1'b0, operand_a} + {1'b0, operand_b};
    
    always_comb begin
        case (opcode)
            OP_AND: logic_out = operand_a & operand_b;
            OP_OR:  logic_out = operand_a | operand_b;
            OP_XOR: logic_out = operand_a ^ operand_b;
            OP_NOT: logic_out = ~operand_a;
            default: logic_out = 32'b0;
        endcase
    end
    
    always_comb begin
        case (opcode)
            OP_ADD, OP_SUB: alu_result = add_sub[31:0];
            OP_AND, OP_OR, OP_XOR, OP_NOT: alu_result = logic_out;
            default: alu_result = 32'b0;
        endcase
    end

    // Máquina de estados principal
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
                        
                        if (bit_counter == 31) begin 
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
                        
                        if (bit_counter == 31) begin 
                            operand_b <= {spi_shift_reg[30:0], spi_if.mosi};
                            current_state <= EXECUTE;
                            bit_counter <= 6'b0;
                        end
                    end
                end
                
                EXECUTE: begin
                    result <= alu_result;
                    spi_shift_reg <= alu_result;
                    current_state <= SEND_RESULT;
                    bit_counter <= 6'b0;
                end
                
                SEND_RESULT: begin
                    if (spi_if.nss) begin
                        current_state <= IDLE;
                    end else if (spi_clk_rising) begin
                        spi_shift_reg <= {spi_shift_reg[30:0], 1'b0};
                        bit_counter <= bit_counter + 1;
                        
                        if (bit_counter == 31) begin 
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

    assign spi_if.miso = (current_state == SEND_RESULT) ? spi_shift_reg[31] : 1'b0;

endmodule