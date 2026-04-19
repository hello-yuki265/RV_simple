transcript on

if {[file exists work]} {
    vdel -lib work -all
}

vlib work
vmap work work

vlog -f rtl.f
vlog -sv tb_rv32i_check.sv

vsim -voptargs=+acc work.tb_rv32i_check

add wave sim:/tb_rv32i_check/dut/*
add wave sim:/tb_rv32i_check/dut/regfile_inst/register

run -all
