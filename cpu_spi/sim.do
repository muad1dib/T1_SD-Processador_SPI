quit -sim
.main clear

vlib work
vmap work work

echo "== Trabalho 1 - Sistemas Digitais: Processador com SPI =="

echo "=== Compilando arquivos ==="
vlog -sv [pwd]/spi/spi_if.sv
vlog -sv [pwd]/regbank/regbank_if.sv  
vlog -sv [pwd]/regbank/regbank.sv
vlog -sv [pwd]/memory/single_port_ram_port_if.sv
vlog -sv [pwd]/memory/single_port_ram.sv
vlog -sv [pwd]/spi/alu_spi.sv
vlog -sv [pwd]/spi/multiplier.sv
vlog -sv [pwd]/spi/barrel_shifter.sv
vlog -sv [pwd]/cpu/cpu.sv
vlog -sv [pwd]/cpu/tb_cpu.sv

echo "=== Iniciando simulação ==="
vsim -voptargs=+acc tb_cpu

echo "=== Configurando waves ==="
add wave -divider "CLOCK & RESET"
add wave -radix binary /tb_cpu/clock
add wave -radix binary /tb_cpu/reset

add wave -divider "CPU CONTROL"
add wave -radix unsigned /tb_cpu/cpu/PC
add wave -radix ascii /tb_cpu/cpu/current_state
add wave -radix unsigned /tb_cpu/cpu/cycle_counter

add wave -divider "SPI CONTROL - DEBUG"
add wave -radix ascii /tb_cpu/cpu/spi_state
add wave -radix unsigned /tb_cpu/cpu/spi_bit_counter
add wave -radix binary /tb_cpu/cpu/spi_operation_complete
add wave -radix binary /tb_cpu/cpu/use_alu
add wave -radix binary /tb_cpu/cpu/use_mul
add wave -radix binary /tb_cpu/cpu/use_bas

add wave -divider "SPI SIGNALS - ALU"
add wave -radix binary /tb_cpu/cpu/alu_spi/sclk
add wave -radix binary /tb_cpu/cpu/alu_spi/mosi
add wave -radix binary /tb_cpu/cpu/alu_spi/miso
add wave -radix binary /tb_cpu/cpu/alu_spi/nss

add wave -divider "SPI SIGNALS - MUL"
add wave -radix binary /tb_cpu/cpu/mul_spi/sclk
add wave -radix binary /tb_cpu/cpu/mul_spi/mosi
add wave -radix binary /tb_cpu/cpu/mul_spi/miso
add wave -radix binary /tb_cpu/cpu/mul_spi/nss

add wave -divider "SPI SIGNALS - BARREL SHIFTER"
add wave -radix binary /tb_cpu/cpu/bas_spi/sclk
add wave -radix binary /tb_cpu/cpu/bas_spi/mosi
add wave -radix binary /tb_cpu/cpu/bas_spi/miso
add wave -radix binary /tb_cpu/cpu/bas_spi/nss

add wave -divider "SPI DATA"
add wave -radix hex /tb_cpu/cpu/spi_tx_data
add wave -radix hex /tb_cpu/cpu/spi_rx_data

add wave -divider "INSTRUCTION STAGES"
add wave -radix hex /tb_cpu/cpu/instrucao_atual
add wave -radix hex /tb_cpu/cpu/opcode
add wave -radix unsigned /tb_cpu/cpu/rd
add wave -radix unsigned /tb_cpu/cpu/rs1  
add wave -radix unsigned /tb_cpu/cpu/rs2

add wave -divider "OPERANDS & RESULT"
add wave -radix hex /tb_cpu/cpu/operand_a
add wave -radix hex /tb_cpu/cpu/operand_b
add wave -radix hex /tb_cpu/cpu/resultado

add wave -divider "REGISTER BANK"
add wave -radix hex /tb_cpu/cpu/rb_inst/regs(0)
add wave -radix hex /tb_cpu/cpu/rb_inst/regs(1)
add wave -radix hex /tb_cpu/cpu/rb_inst/regs(2)
add wave -radix hex /tb_cpu/cpu/rb_inst/regs(3)
add wave -radix hex /tb_cpu/cpu/rb_inst/regs(4)
add wave -radix hex /tb_cpu/cpu/rb_inst/regs(5)
add wave -radix hex /tb_cpu/cpu/rb_inst/regs(6)
add wave -radix hex /tb_cpu/cpu/rb_inst/regs(7)
add wave -radix hex /tb_cpu/cpu/rb_inst/regs(8)
add wave -radix hex /tb_cpu/cpu/rb_inst/regs(9)
add wave -radix hex /tb_cpu/cpu/rb_inst/regs(10)

add wave -divider "MEMORY ACCESS"
add wave -radix binary /tb_cpu/cpu/mem_port/en
add wave -radix binary /tb_cpu/cpu/mem_port/we
add wave -radix hex /tb_cpu/cpu/mem_port/addr
add wave -radix hex /tb_cpu/cpu/mem_port/rdata
add wave -radix hex /tb_cpu/cpu/mem_port/wdata

add wave -divider "REGISTER BANK INTERFACE"
add wave -radix binary /tb_cpu/cpu/rb_if/we
add wave -radix unsigned /tb_cpu/cpu/rb_if/waddr
add wave -radix hex /tb_cpu/cpu/rb_if/wdata
add wave -radix unsigned /tb_cpu/cpu/rb_if/raddr1
add wave -radix unsigned /tb_cpu/cpu/rb_if/raddr2
add wave -radix hex /tb_cpu/cpu/rb_if/rdata1
add wave -radix hex /tb_cpu/cpu/rb_if/rdata2

add wave -divider "ALU INTERNAL STATE - DEBUG"
add wave -radix ascii /tb_cpu/cpu/alu_inst/current_state
add wave -radix unsigned /tb_cpu/cpu/alu_inst/bit_counter
add wave -radix hex /tb_cpu/cpu/alu_inst/operand_a
add wave -radix hex /tb_cpu/cpu/alu_inst/operand_b
add wave -radix hex /tb_cpu/cpu/alu_inst/opcode
add wave -radix hex /tb_cpu/cpu/alu_inst/result

configure wave -namecolwidth 200
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2

echo "=== Executando simulação por 500ns ==="
run 500ns

echo "=== Simulação concluída ==="
echo "Tempo total de simulação: 500ns"

wave zoom full

echo "=== ANÁLISE COMPLETA COM SINAIS SPI ==="
echo "Verifique os sinais SPI para confirmar funcionamento:"
echo "1. spi_state deve alternar entre estados"
echo "2. nss deve ir para 0 durante transações"
echo "3. sclk deve gerar pulsos"
echo "4. mosi deve enviar dados"
echo "5. miso deve receber resultados"
echo ""
echo "Use 'run 100ns' para continuar a simulação se necessário"
echo "Use 'restart -f' para reiniciar a simulação"