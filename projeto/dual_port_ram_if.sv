interface dual_port_ram_port_if #(
    parameter int ADDR_WIDTH = 8,
    parameter int DATA_WIDTH = 32
)(
    input logic clk
);
    
    logic en;
    logic we;
    logic [ADDR_WIDTH-1:0] addr;
    logic [DATA_WIDTH-1:0] wdata;
    logic [DATA_WIDTH-1:0] rdata;

    modport MEM (
        input en, we, addr, wdata,
        output rdata
    );
    
    modport CPU (
        output en, we, addr, wdata,
        input rdata
    );

endinterface
