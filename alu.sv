module alu (
    logic clock,
    logic reset,
    spi_if.SLAVE spi_if
);


    input  logic [31:0] a,
    input  logic [31:0] b,
    input  logic [3:0]  op,      // operation selector
    output logic [31:0] result,
    output logic        zero,
    output logic        carry,
    output logic        overflow

    // Operation encoding (example for SH-1)
    localparam OP_ADD  = 4'b0000;
    localparam OP_SUB  = 4'b0001;
    localparam OP_AND  = 4'b0010;
    localparam OP_OR   = 4'b0011;
    localparam OP_XOR  = 4'b0100;
    localparam OP_NOT  = 4'b0101;
    localparam OP_SHL  = 4'b0110;
    localparam OP_SHR  = 4'b0111;
    localparam OP_SAR  = 4'b1000;

    logic [32:0] add_sub;
    logic [31:0] logic_out;
    logic        add_carry, sub_carry, add_overflow, sub_overflow;

    // Arithmetic
    assign add_sub    = (op == OP_SUB) ? {1'b0, a} - {1'b0, b} : {1'b0, a} + {1'b0, b};
    assign add_carry  = add_sub[32];
    assign sub_carry  = add_sub[32];
    assign add_overflow = (~a[31] & ~b[31] & add_sub[31]) | (a[31] & b[31] & ~add_sub[31]);
    assign sub_overflow = (a[31] & ~b[31] & ~add_sub[31]) | (~a[31] & b[31] & add_sub[31]);

    // Logic
    always_comb begin
        case (op)
            OP_AND: logic_out = a & b;
            OP_OR:  logic_out = a | b;
            OP_XOR: logic_out = a ^ b;
            OP_NOT: logic_out = ~a;
            OP_SHL: logic_out = a << b[4:0];
            OP_SHR: logic_out = a >> b[4:0];
            OP_SAR: logic_out = $signed(a) >>> b[4:0];
            default: logic_out = 32'b0;
        endcase
    end

    // Result selection
    always_comb begin
        case (op)
            OP_ADD: result = add_sub[31:0];
            OP_SUB: result = add_sub[31:0];
            OP_AND, OP_OR, OP_XOR, OP_NOT, OP_SHL, OP_SHR, OP_SAR: result = logic_out;
            default: result = 32'b0;
        endcase
    end

    // Flags
    assign zero     = (result == 32'b0);
    assign carry    = (op == OP_ADD) ? add_carry :
                      (op == OP_SUB) ? sub_carry : 1'b0;
    assign overflow = (op == OP_ADD) ? add_overflow :
                      (op == OP_SUB) ? sub_overflow : 1'b0;

endmodule