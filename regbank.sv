module regbank #(
    parameter int REG_WIDTH = 32,
    parameter int REG_COUNT = 16
) (
    input  logic clk,
    input  logic rst_n,
    regbank_if.REGBANK rb
);

    // SH-1 has 16 general purpose registers (R0-R15)
    logic [REG_WIDTH-1:0] regs [REG_COUNT];

    // Read ports
    assign rb.rdata1 = regs[rb.raddr1];
    assign rb.rdata2 = regs[rb.raddr2];

    // Write port
    always_ff @(posedge clk or negedge rst_n) begin
        if (rst_n) begin
            module regbank #(
    parameter int REG_WIDTH = 32,
    parameter int REG_COUNT = 16
) (
    input  logic clk,
    input  logic rst_n,
    regbank_if.REGBANK rb
);

    // SH-1 has 16 general purpose registers (R0-R15)
    logic [REG_WIDTH-1:0] regs [REG_COUNT];

    // Read ports
    assign rb.rdata1 = regs[rb.raddr1];
    assign rb.rdata2 = regs[rb.raddr2];

    // Write port
    always_ff @(posedge clk or negedge rst_n) begin
        if (rst_n) begin
            if (we) begin
                regs[waddr] <= wdata;
            end
        end else begin
            regs <= '{default: '0}; // Reset all registers to 0
        end
    end

endmoduleif (we) begin
                regs[waddr] <= wdata;
            end
        end else begin
            regs <= '{default: '0}; // Reset all registers to 0
        end
    end

endmodule