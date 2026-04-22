transcript on

if {[file exists work]} {
    vdel -lib work -all
}

vlib work
vmap work work

vlog -f rtl.f
vlog -sv tb_rv32i_pipline_check.sv

vsim -c -voptargs=+acc work.tb_rv32i_pipline_check -do "run -all; quit -f"
