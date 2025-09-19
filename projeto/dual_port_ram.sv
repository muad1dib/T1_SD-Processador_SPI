module dual_port_ram #(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 32,
    parameter DEPTH = 1 << ADDR_WIDTH
)(
    input  logic                   clk,
    input  dual_port_ram_port_if.MEM a,
    input  dual_port_ram_port_if.MEM b
);

    logic [DATA_WIDTH-1:0] mem [DEPTH-1:0];

    always_ff @(posedge clk) begin
        if (a.en) begin
            if (a.we)
                mem[a.addr] <= a.wdata; 
        end
    end

    assign a.rdata = mem[a.addr];

    always_ff @(posedge clk) begin
        if (b.en) begin
            if (b.we)
                mem[b.addr] <= b.wdata;
        end
    end

    assign b.rdata = mem[b.addr];

endmodule