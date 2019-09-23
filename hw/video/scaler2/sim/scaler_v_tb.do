#-----------------------------------------------------------------------
#
# Engineer    : Golovachenko Victor
#
#------------------------------------------------------------------------
file delete -force -- work

vlib work

vlog ../src/scaler_rom_coe.v +define+../src/
vlog ../src/scaler_v.v -sv +define+SIM_FSM +define+INITAL

vlog ./bmp_io.sv -sv
vlog ./monitor.sv -sv
vlog ./scaler_v_tb.sv -sv

vsim -t 1ps -novopt -lib work scaler_v_tb \

do scaler_v_tb_wave.do

#--------------------------
#View waveform
#--------------------------
view wave
config wave -timelineunits us
view structure
view signals
run 2us

#quit -force
