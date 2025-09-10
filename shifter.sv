module shifter #(REG_WIDTH=32)(
    input logic sin,
    input logic[REG_WIDTH-1:0] op_a,
    output logic[REG_WIDTH-1:0] result,
    output logic sout,
    input logic[4:0] nbits,
    input logic[2:0] mode,  // 
        // mode is:
        // mode[0]: left or right
        // mode[1]: is arith 
        // mode[2]: is rotatory
);

always_comb begin
    unique case (mode)
        3'b000: begin // logical left
            result = op_a << nbits;
            sout = op_a[REG_WIDTH-1 - nbits + 1];
        end
        3'b001: begin // logical right
            result = op_a >> nbits;
            sout = op_a[nbits - 1];
        end
        3'b010: begin // arith left
            result = op_a << nbits;
            sout = op_a[REG_WIDTH-1 - nbits + 1];
        end
        3'b011: begin // arith right
            result = (op_a >> nbits) | ({nbits{op_a[REG_WIDTH-1]}} << (REG_WIDTH - nbits));
            sout = op_a[nbits - 1];
        end
        3'b100: begin // rotatory left
            result = (op_a << nbits) | (op_a >> (REG_WIDTH - nbits));
            sout = op_a[REG_WIDTH-1 - nbits + 1];
        end
        3'b101: begin // rotatory right
            result = (op_a >> nbits) | (op_a << (REG_WIDTH - nbits));
            sout = op_a[nbits - 1];
        end
    endcase
end

endmodule: shifter