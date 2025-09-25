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

        // Programa de teste simples
        mem[0] = 32'h0123_0007; // só exemplo
        mem[1] = 32'h1234_0000;
        mem[2] = 32'hABCD_0000;
    end

    // Escrita síncrona (não precisa ser always_ff, pode ser always)
    always @(posedge clk) begin
        if (a.en && a.we) begin
            mem[a.addr] <= a.wdata;
        end
    end

    // Leitura combinacional
    assign a.rdata = mem[a.addr];

endmodule
