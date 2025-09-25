
module single_port_ram #(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 32,
    parameter DEPTH = 1 << ADDR_WIDTH
)(
    input logic clk,
    single_port_ram_port_if.MEM a
);

    logic [DATA_WIDTH-1:0] mem [DEPTH-1:0];

    always_ff @(posedge clk) begin
        if (a.en) begin
            if (a.we)
                mem[a.addr] <= a.wdata; 
        end
    end

    assign a.rdata = mem[a.addr];

endmodule