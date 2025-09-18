if {[file isdirectory work]} {vdel -all -lib work}
vlib work
vmap work work

set TOP_ENTITY {work.tb_memory}

vlog -work work dual_port_ram_if.sv
vlog -work work dual_port_ram.sv
vlog -work work tb_memory.sv
vlog -work work regbank.sv
vlog -work work regbank_if.sv
vlog -work work alu.sv
vlog -work work Processador.sv
vlog -work work shifter.sv
vlog -work work spi_if.sv

vsim -voptargs=+acc ${TOP_ENTITY}

quietly set StdArithNoWarnings 1
quietly set StdVitalGlitchNoWarnings 1

do wave.do
run 100ns

