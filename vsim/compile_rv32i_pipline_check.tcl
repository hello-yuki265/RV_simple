transcript on

if {[file exists work]} {
    vdel -lib work -all
}

vlib work
vmap work work

vlog -f rtl.f
vlog -sv tb_rv32i_pipline_check.sv

vsim -voptargs=+acc work.tb_rv32i_pipline_check 
add wave sim:/tb_rv32i_pipline_check/dut/*

run -all