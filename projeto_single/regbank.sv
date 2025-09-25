module regbank #(
    parameter int REG_WIDTH = 32,
    parameter int REG_COUNT = 16
) (
    input  logic clk,
    input  logic rst_n,
    regbank_if.REGBANK rb
);

    logic [REG_WIDTH-1:0] regs [REG_COUNT];

    assign rb.rdata1 = regs[rb.raddr1];
    assign rb.rdata2 = regs[rb.raddr2];

    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            regs <= '{default: '0}; // Reset all registers to 0
        end else begin
            if (rb.we) begin
                regs[rb.waddr] <= rb.wdata;
            end
        end
    end

endmodule