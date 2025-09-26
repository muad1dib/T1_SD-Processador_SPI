module single_port_ram #(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 32,
    parameter DEPTH = 1 << ADDR_WIDTH
)(
    input logic clk,
    single_port_ram_port_if.MEM a
);

    logic [DATA_WIDTH-1:0] mem [DEPTH-1:0];

    // Inicialização fixa para teste
    initial begin
        for (int i = 0; i < DEPTH; i++) begin
            mem[i] = '0;
        end

        // ======================================
        // Programa de teste para ALU (1 instrução de cada operação)
        // Formato: {opcode[31:28], rd[27:24], rs1[23:20], rs2[19:16], unused[15:0]}
        // ======================================

        mem[0] = 32'h0001_0212; // ADD  R1 = R2 + R2
        mem[1] = 32'h1002_0312; // SUB  R3 = R1 - R2
        mem[2] = 32'h2003_0412; // AND  R4 = R1 & R2
        mem[3] = 32'h3004_0512; // OR   R5 = R1 | R2
        mem[4] = 32'h4005_0612; // XOR  R6 = R1 ^ R2
        mem[5] = 32'h5006_0710; // NOT  R7 = ~R1 (rs2 ignorado)
        mem[6] = 32'h6007_0812; // SHL  R8 = R1 << R2
        mem[7] = 32'h7008_0912; // SHR  R9 = R1 >> R2
        mem[8] = 32'h0000_0000; // NOP (encerra)

    end

    always @(posedge clk) begin
        if (a.en && a.we) begin
            mem[a.addr] <= a.wdata;
        end
    end

    // Leitura combinacional
    assign a.rdata = mem[a.addr];

endmodule
