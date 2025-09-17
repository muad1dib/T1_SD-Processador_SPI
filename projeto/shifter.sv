module barrel_shifter #(parameter REG_WIDTH=32)(
    input logic clock,
    input logic reset,
    input logic[REG_WIDTH-1:0] op_a,
    input logic[4:0] nbits,
    input logic[2:0] mode,  // Adicionado o sinal mode
    input logic start,              
    output logic[REG_WIDTH-1:0] result,
    output logic done,              
    spi_if.SLAVE spi_if
);
    localparam OP_SHL = 4'b0110;  
    localparam OP_SHR = 4'b0111;  
    
    logic[REG_WIDTH-1:0] result_reg;
    logic done_reg;

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
            result = (op_a >> nbits) | (op_a[REG_WIDTH-1] << (REG_WIDTH-1);
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