module Processador(
    logic clock,
    logic reset,
    dual_port_ram_if mem_a.CPU,
    dual_port_ram_if mem_b.CPU
);

regbank_if rb_if(clock, reset);
regbank rb(clock, reset, rb_if);

spi_if alu_if(clock, reset);
alu alu_mod(clock, reset, alu_if);

spi_if mul_if(clock, reset);
// mul

spi_if bas_if(clock, reset);
// bas



// ======================================
// REGISTRADORES DA CPU (DE CONTROLE)
// ======================================
logic[15:0] PC;

logic[3:0] stall;

if $onehot(stall)

// ======================================
// BARREIRAS TEMPORAIS 
// ======================================
typedef struct packed {
    logic[15:0] instrucao_atual
} fetch_to_decode;

typedef struct packed {
    logic[15:0] ...
} decode_to_execute;

typedef struct packed {
    logic[15:0] ...
} execute_to_writeback;

assign mem_a.wb = 0;
assign mem_a.data_in = 0;

// ======================================
// LÓGICA DOS ESTÁGIOS 
// ======================================
// fetch
always @(posedge clock, negedge reset) begin
    if (~reset) begin
        PC <= 0;
    end else begin
        mem_a.addr_in <= PC;
        instrucao_atual <= mem_a.data_out;
    end
end

//decode
always @(posedge clock, negedge reset) begin
    if (~reset) begin
        PC <= 0;
    end else begin
        mem_a.addr_in <= PC;
        instrucao_atual <= mem_a.data_out;
    end
end

// execute
always @(posedge clock, negedge reset) begin
    if (~reset) begin
        PC <= 0;
    end else begin
        mem_a.addr_in <= PC;
        instrucao_atual <= mem_a.data_out;
    end
end

// writeback
always @(posedge clock, negedge reset) begin
    if (~reset) begin
        PC <= 0;
    end else begin
        mem_a.addr_in <= PC;
        instrucao_atual <= mem_a.data_out;
    end
end

endmodule