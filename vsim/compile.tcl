transcript on

if {[file exists work]} {
    vdel -lib work -all
}

vlib work
vmap work work

vlog -f rtl.f
vlog -sv -f sim.f

vsim -voptargs=+acc work.tb_top_core

add wave sim:/tb_top_core/top_core_inst/*
view -new wave
add wave sim:/tb_top_core/top_core_inst/regfile_inst/register

run -all
