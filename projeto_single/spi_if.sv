interface spi_if(
    input logic clock,
    input logic reset
);

logic sclk;
logic miso;
logic mosi;
logic nss;

modport SLAVE (
    input sclk, mosi, nss,
    output miso
);

modport MASTER (
    output sclk, mosi, nss,
    input miso
);

endinterface