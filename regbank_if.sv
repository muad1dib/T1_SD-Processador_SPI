module regbank_if #(
    parameter int REG_WIDTH = 32,
    parameter int REG_COUNT = 16
) (
    input  logic                  clk,
    input  logic                  rst_n
);
   
    logic we,                             // Write enable
    logic [$clog2(REG_COUNT)-1:0] waddr,  // Write address
    logic [REG_WIDTH-1:0]  wdata,         // Write data
    logic [$clog2(REG_COUNT)-1:0] raddr1, // Read address 1
    logic [$clog2(REG_COUNT)-1:0] raddr2, // Read address 2
    logic [REG_WIDTH-1:0]  rdata1,        // Read data 1
    logic [REG_WIDTH-1:0]  rdata2         // Read data 2

    modport REGBANK (
        input we, waddr, wdata, raddr1, raddr2,
        output rdata1, rdata2
    );

    modport CPU (
        output we, waddr, wdata, raddr1, raddr2,
        input rdata1, rdata2
    );

endmodule