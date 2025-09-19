if {[file isdirectory work]} {vdel -all -lib work}
vlib work
vmap work work

set TOP_ENTITY {work.tb_processador}

vlog -work work spi_if.sv
vlog -work work regbank_if.sv  
vlog -work work dual_port_ram_port_if.sv

vlog -work work alu.sv # Refeito, checar se tá tudo ok
vlog -work work regbank.sv
vlog -work work dual_port_ram.sv
vlog -work work shifter.sv # Falta fazer
vlog -work work Processador.sv # Fata fazer

vlog -work work tb_processador.sv # Falta fazer

vsim -voptargs=+acc ${TOP_ENTITY}

quietly set StdArithNoWarnings 1
quietly set StdVitalGlitchNoWarnings 1

do wave.do

run 100ns