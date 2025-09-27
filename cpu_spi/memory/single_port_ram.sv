module single_port_ram #(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 32,
    parameter DEPTH = 1 << ADDR_WIDTH
)(
    input logic clk,
    single_port_ram_port_if.MEM a
);

    logic [DATA_WIDTH-1:0] mem [DEPTH-1:0];

    // Inicialização com instruções incluindo MUL
    initial begin
        for (int i = 0; i < DEPTH; i++) begin
            mem[i] = '0;
        end

        mem[0] = 32'h0122_0000; // ADD  opcode=0, rd=1, rs1=2, rs2=2  -> R1 = R2 + R2 = 14
        mem[1] = 32'h1312_0000; // SUB  opcode=1, rd=3, rs1=1, rs2=2  -> R3 = R1 - R2 = 7
        mem[2] = 32'h2412_0000; // AND  opcode=2, rd=4, rs1=1, rs2=2  -> R4 = R1 & R2
        mem[3] = 32'h3512_0000; // OR   opcode=3, rd=5, rs1=1, rs2=2  -> R5 = R1 | R2
        mem[4] = 32'h4612_0000; // XOR  opcode=4, rd=6, rs1=1, rs2=2  -> R6 = R1 ^ R2
        mem[5] = 32'h5710_0000; // NOT  opcode=5, rd=7, rs1=1, rs2=0  -> R7 = ~R1
        mem[6] = 32'h6812_0000; // SHL  opcode=6, rd=8, rs1=1, rs2=2  -> R8 = R1 << R2
        mem[7] = 32'h7912_0000; // SHR  opcode=7, rd=9, rs1=1, rs2=2  -> R9 = R1 >> R2
        mem[8] = 32'h9A12_0000; // MUL  opcode=9, rd=A, rs1=1, rs2=2  -> R10 = R1 * R2
        mem[9] = 32'h0000_0000; // NOP
    end

    always @(posedge clk) begin
        if (a.en && a.we) begin
            mem[a.addr] <= a.wdata;
        end
    end

    assign a.rdata = mem[a.addr];

endmodule

