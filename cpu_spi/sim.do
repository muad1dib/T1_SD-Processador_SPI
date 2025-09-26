# ======================================
# Script de Simulação - Processador T1
# ======================================

quit -sim
.main clear

vlib work
vmap work work

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

configure wave -namecolwidth 200
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2

echo "=== Executando simulação por 400ns ==="
run 400ns

echo "=== Simulação concluída ==="
echo "Tempo total de simulação: 400ns"


wave zoom full

echo "=== ANÁLISE COMPLETA ==="
echo "Use 'run 100ns' para continuar a simulação se necessário"
echo "Use 'restart -f' para reiniciar a simulação"


