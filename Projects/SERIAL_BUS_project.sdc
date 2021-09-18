## Generated SDC file "SERIAL_BUS_project.sdc"

## Copyright (C) 2018  Intel Corporation. All rights reserved.
## Your use of Intel Corporation's design tools, logic functions 
## and other software and tools, and its AMPP partner logic 
## functions, and any output files from any of the foregoing 
## (including device programming or simulation files), and any 
## associated documentation or information are expressly subject 
## to the terms and conditions of the Intel Program License 
## Subscription Agreement, the Intel Quartus Prime License Agreement,
## the Intel FPGA IP License Agreement, or other applicable license
## agreement, including, without limitation, that your use is for
## the sole purpose of programming logic devices manufactured by
## Intel and sold by Intel or its authorized distributors.  Please
## refer to the applicable agreement for further details.


## VENDOR  "Altera"
## PROGRAM "Quartus Prime"
## VERSION "Version 18.1.0 Build 625 09/12/2018 SJ Lite Edition"

## DATE    "Wed Sep 15 20:57:50 2021"

##
## DEVICE  "EP4CE115F29C7"
##


#**************************************************************
# Time Information
#**************************************************************

set_time_format -unit ns -decimal_places 3



#**************************************************************
# Create Clock
#**************************************************************

create_clock -name {CLOCK_50} -period 20.000 -waveform { 0.000 10.000 } [get_ports {CLOCK_50}]


#**************************************************************
# Create Generated Clock
#**************************************************************



#**************************************************************
# Set Clock Latency
#**************************************************************



#**************************************************************
# Set Clock Uncertainty
#**************************************************************



#**************************************************************
# Set Input Delay
#**************************************************************

set_input_delay -add_delay -max -clock [get_clocks {CLOCK_50}]  4.000 [get_ports {GPIO[0]}]
set_input_delay -add_delay -min -clock [get_clocks {CLOCK_50}]  3.000 [get_ports {GPIO[0]}]
set_input_delay -add_delay -max -clock [get_clocks {CLOCK_50}]  4.000 [get_ports {GPIO[2]}]
set_input_delay -add_delay -min -clock [get_clocks {CLOCK_50}]  3.000 [get_ports {GPIO[2]}]
set_input_delay -add_delay -max -clock [get_clocks {CLOCK_50}]  4.000 [get_ports {KEY[0]}]
set_input_delay -add_delay -min -clock [get_clocks {CLOCK_50}]  3.000 [get_ports {KEY[0]}]
set_input_delay -add_delay -max -clock [get_clocks {CLOCK_50}]  4.000 [get_ports {KEY[1]}]
set_input_delay -add_delay -min -clock [get_clocks {CLOCK_50}]  3.000 [get_ports {KEY[1]}]
set_input_delay -add_delay -max -clock [get_clocks {CLOCK_50}]  4.000 [get_ports {KEY[2]}]
set_input_delay -add_delay -min -clock [get_clocks {CLOCK_50}]  3.000 [get_ports {KEY[2]}]
set_input_delay -add_delay -max -clock [get_clocks {CLOCK_50}]  4.000 [get_ports {KEY[3]}]
set_input_delay -add_delay -min -clock [get_clocks {CLOCK_50}]  3.000 [get_ports {KEY[3]}]
set_input_delay -add_delay -max -clock [get_clocks {CLOCK_50}]  4.000 [get_ports {SW[0]}]
set_input_delay -add_delay -min -clock [get_clocks {CLOCK_50}]  3.000 [get_ports {SW[0]}]
set_input_delay -add_delay -max -clock [get_clocks {CLOCK_50}]  4.000 [get_ports {SW[1]}]
set_input_delay -add_delay -min -clock [get_clocks {CLOCK_50}]  3.000 [get_ports {SW[1]}]
set_input_delay -add_delay -max -clock [get_clocks {CLOCK_50}]  4.000 [get_ports {SW[2]}]
set_input_delay -add_delay -min -clock [get_clocks {CLOCK_50}]  3.000 [get_ports {SW[2]}]
set_input_delay -add_delay -max -clock [get_clocks {CLOCK_50}]  4.000 [get_ports {SW[3]}]
set_input_delay -add_delay -min -clock [get_clocks {CLOCK_50}]  3.000 [get_ports {SW[3]}]
set_input_delay -add_delay -max -clock [get_clocks {CLOCK_50}]  4.000 [get_ports {SW[4]}]
set_input_delay -add_delay -min -clock [get_clocks {CLOCK_50}]  3.000 [get_ports {SW[4]}]
set_input_delay -add_delay -max -clock [get_clocks {CLOCK_50}]  4.000 [get_ports {SW[5]}]
set_input_delay -add_delay -min -clock [get_clocks {CLOCK_50}]  3.000 [get_ports {SW[5]}]
set_input_delay -add_delay -max -clock [get_clocks {CLOCK_50}]  4.000 [get_ports {SW[6]}]
set_input_delay -add_delay -min -clock [get_clocks {CLOCK_50}]  3.000 [get_ports {SW[6]}]
set_input_delay -add_delay -max -clock [get_clocks {CLOCK_50}]  4.000 [get_ports {SW[7]}]
set_input_delay -add_delay -min -clock [get_clocks {CLOCK_50}]  3.000 [get_ports {SW[7]}]
set_input_delay -add_delay -max -clock [get_clocks {CLOCK_50}]  4.000 [get_ports {SW[8]}]
set_input_delay -add_delay -min -clock [get_clocks {CLOCK_50}]  3.000 [get_ports {SW[8]}]
set_input_delay -add_delay -max -clock [get_clocks {CLOCK_50}]  4.000 [get_ports {SW[9]}]
set_input_delay -add_delay -min -clock [get_clocks {CLOCK_50}]  3.000 [get_ports {SW[9]}]
set_input_delay -add_delay -max -clock [get_clocks {CLOCK_50}]  4.000 [get_ports {SW[10]}]
set_input_delay -add_delay -min -clock [get_clocks {CLOCK_50}]  3.000 [get_ports {SW[10]}]
set_input_delay -add_delay -max -clock [get_clocks {CLOCK_50}]  4.000 [get_ports {SW[11]}]
set_input_delay -add_delay -min -clock [get_clocks {CLOCK_50}]  3.000 [get_ports {SW[11]}]
set_input_delay -add_delay -max -clock [get_clocks {CLOCK_50}]  4.000 [get_ports {SW[12]}]
set_input_delay -add_delay -min -clock [get_clocks {CLOCK_50}]  3.000 [get_ports {SW[12]}]
set_input_delay -add_delay -max -clock [get_clocks {CLOCK_50}]  4.000 [get_ports {SW[13]}]
set_input_delay -add_delay -min -clock [get_clocks {CLOCK_50}]  3.000 [get_ports {SW[13]}]
set_input_delay -add_delay -max -clock [get_clocks {CLOCK_50}]  4.000 [get_ports {SW[14]}]
set_input_delay -add_delay -min -clock [get_clocks {CLOCK_50}]  3.000 [get_ports {SW[14]}]
set_input_delay -add_delay -max -clock [get_clocks {CLOCK_50}]  4.000 [get_ports {SW[15]}]
set_input_delay -add_delay -min -clock [get_clocks {CLOCK_50}]  3.000 [get_ports {SW[15]}]
set_input_delay -add_delay -max -clock [get_clocks {CLOCK_50}]  4.000 [get_ports {SW[16]}]
set_input_delay -add_delay -min -clock [get_clocks {CLOCK_50}]  3.000 [get_ports {SW[16]}]
set_input_delay -add_delay -max -clock [get_clocks {CLOCK_50}]  4.000 [get_ports {SW[17]}]
set_input_delay -add_delay -min -clock [get_clocks {CLOCK_50}]  3.000 [get_ports {SW[17]}]


#**************************************************************
# Set Output Delay
#**************************************************************

set_output_delay -add_delay -max -clock [get_clocks {CLOCK_50}]  3.000 [get_ports {GPIO[1]}]
set_output_delay -add_delay -min -clock [get_clocks {CLOCK_50}]  2.000 [get_ports {GPIO[1]}]
set_output_delay -add_delay -max -clock [get_clocks {CLOCK_50}]  3.000 [get_ports {GPIO[3]}]
set_output_delay -add_delay -min -clock [get_clocks {CLOCK_50}]  2.000 [get_ports {GPIO[3]}]
set_output_delay -add_delay -max -clock [get_clocks {CLOCK_50}]  3.000 [get_ports {HEX0[0]}]
set_output_delay -add_delay -min -clock [get_clocks {CLOCK_50}]  2.000 [get_ports {HEX0[0]}]
set_output_delay -add_delay -max -clock [get_clocks {CLOCK_50}]  3.000 [get_ports {HEX0[1]}]
set_output_delay -add_delay -min -clock [get_clocks {CLOCK_50}]  2.000 [get_ports {HEX0[1]}]
set_output_delay -add_delay -max -clock [get_clocks {CLOCK_50}]  3.000 [get_ports {HEX0[2]}]
set_output_delay -add_delay -min -clock [get_clocks {CLOCK_50}]  2.000 [get_ports {HEX0[2]}]
set_output_delay -add_delay -max -clock [get_clocks {CLOCK_50}]  3.000 [get_ports {HEX0[3]}]
set_output_delay -add_delay -min -clock [get_clocks {CLOCK_50}]  2.000 [get_ports {HEX0[3]}]
set_output_delay -add_delay -max -clock [get_clocks {CLOCK_50}]  3.000 [get_ports {HEX0[4]}]
set_output_delay -add_delay -min -clock [get_clocks {CLOCK_50}]  2.000 [get_ports {HEX0[4]}]
set_output_delay -add_delay -max -clock [get_clocks {CLOCK_50}]  3.000 [get_ports {HEX0[5]}]
set_output_delay -add_delay -min -clock [get_clocks {CLOCK_50}]  2.000 [get_ports {HEX0[5]}]
set_output_delay -add_delay -max -clock [get_clocks {CLOCK_50}]  3.000 [get_ports {HEX0[6]}]
set_output_delay -add_delay -min -clock [get_clocks {CLOCK_50}]  2.000 [get_ports {HEX0[6]}]
set_output_delay -add_delay -max -clock [get_clocks {CLOCK_50}]  3.000 [get_ports {HEX1[0]}]
set_output_delay -add_delay -min -clock [get_clocks {CLOCK_50}]  2.000 [get_ports {HEX1[0]}]
set_output_delay -add_delay -max -clock [get_clocks {CLOCK_50}]  3.000 [get_ports {HEX1[1]}]
set_output_delay -add_delay -min -clock [get_clocks {CLOCK_50}]  2.000 [get_ports {HEX1[1]}]
set_output_delay -add_delay -max -clock [get_clocks {CLOCK_50}]  3.000 [get_ports {HEX1[2]}]
set_output_delay -add_delay -min -clock [get_clocks {CLOCK_50}]  2.000 [get_ports {HEX1[2]}]
set_output_delay -add_delay -max -clock [get_clocks {CLOCK_50}]  3.000 [get_ports {HEX1[3]}]
set_output_delay -add_delay -min -clock [get_clocks {CLOCK_50}]  2.000 [get_ports {HEX1[3]}]
set_output_delay -add_delay -max -clock [get_clocks {CLOCK_50}]  3.000 [get_ports {HEX1[4]}]
set_output_delay -add_delay -min -clock [get_clocks {CLOCK_50}]  2.000 [get_ports {HEX1[4]}]
set_output_delay -add_delay -max -clock [get_clocks {CLOCK_50}]  3.000 [get_ports {HEX1[5]}]
set_output_delay -add_delay -min -clock [get_clocks {CLOCK_50}]  2.000 [get_ports {HEX1[5]}]
set_output_delay -add_delay -max -clock [get_clocks {CLOCK_50}]  3.000 [get_ports {HEX1[6]}]
set_output_delay -add_delay -min -clock [get_clocks {CLOCK_50}]  2.000 [get_ports {HEX1[6]}]
set_output_delay -add_delay -max -clock [get_clocks {CLOCK_50}]  3.000 [get_ports {LCD_BLON}]
set_output_delay -add_delay -min -clock [get_clocks {CLOCK_50}]  2.000 [get_ports {LCD_BLON}]
set_output_delay -add_delay -max -clock [get_clocks {CLOCK_50}]  3.000 [get_ports {LCD_DATA[0]}]
set_output_delay -add_delay -min -clock [get_clocks {CLOCK_50}]  2.000 [get_ports {LCD_DATA[0]}]
set_output_delay -add_delay -max -clock [get_clocks {CLOCK_50}]  3.000 [get_ports {LCD_DATA[1]}]
set_output_delay -add_delay -min -clock [get_clocks {CLOCK_50}]  2.000 [get_ports {LCD_DATA[1]}]
set_output_delay -add_delay -max -clock [get_clocks {CLOCK_50}]  3.000 [get_ports {LCD_DATA[2]}]
set_output_delay -add_delay -min -clock [get_clocks {CLOCK_50}]  2.000 [get_ports {LCD_DATA[2]}]
set_output_delay -add_delay -max -clock [get_clocks {CLOCK_50}]  3.000 [get_ports {LCD_DATA[3]}]
set_output_delay -add_delay -min -clock [get_clocks {CLOCK_50}]  2.000 [get_ports {LCD_DATA[3]}]
set_output_delay -add_delay -max -clock [get_clocks {CLOCK_50}]  3.000 [get_ports {LCD_DATA[4]}]
set_output_delay -add_delay -min -clock [get_clocks {CLOCK_50}]  2.000 [get_ports {LCD_DATA[4]}]
set_output_delay -add_delay -max -clock [get_clocks {CLOCK_50}]  3.000 [get_ports {LCD_DATA[5]}]
set_output_delay -add_delay -min -clock [get_clocks {CLOCK_50}]  2.000 [get_ports {LCD_DATA[5]}]
set_output_delay -add_delay -max -clock [get_clocks {CLOCK_50}]  3.000 [get_ports {LCD_DATA[6]}]
set_output_delay -add_delay -min -clock [get_clocks {CLOCK_50}]  2.000 [get_ports {LCD_DATA[6]}]
set_output_delay -add_delay -max -clock [get_clocks {CLOCK_50}]  3.000 [get_ports {LCD_DATA[7]}]
set_output_delay -add_delay -min -clock [get_clocks {CLOCK_50}]  2.000 [get_ports {LCD_DATA[7]}]
set_output_delay -add_delay -max -clock [get_clocks {CLOCK_50}]  3.000 [get_ports {LCD_EN}]
set_output_delay -add_delay -min -clock [get_clocks {CLOCK_50}]  2.000 [get_ports {LCD_EN}]
set_output_delay -add_delay -max -clock [get_clocks {CLOCK_50}]  3.000 [get_ports {LCD_ON}]
set_output_delay -add_delay -min -clock [get_clocks {CLOCK_50}]  2.000 [get_ports {LCD_ON}]
set_output_delay -add_delay -max -clock [get_clocks {CLOCK_50}]  3.000 [get_ports {LCD_RS}]
set_output_delay -add_delay -min -clock [get_clocks {CLOCK_50}]  2.000 [get_ports {LCD_RS}]
set_output_delay -add_delay -max -clock [get_clocks {CLOCK_50}]  3.000 [get_ports {LCD_RW}]
set_output_delay -add_delay -min -clock [get_clocks {CLOCK_50}]  2.000 [get_ports {LCD_RW}]
set_output_delay -add_delay -max -clock [get_clocks {CLOCK_50}]  3.000 [get_ports {LEDG[0]}]
set_output_delay -add_delay -min -clock [get_clocks {CLOCK_50}]  2.000 [get_ports {LEDG[0]}]
set_output_delay -add_delay -max -clock [get_clocks {CLOCK_50}]  3.000 [get_ports {LEDG[1]}]
set_output_delay -add_delay -min -clock [get_clocks {CLOCK_50}]  2.000 [get_ports {LEDG[1]}]
set_output_delay -add_delay -max -clock [get_clocks {CLOCK_50}]  3.000 [get_ports {LEDG[2]}]
set_output_delay -add_delay -min -clock [get_clocks {CLOCK_50}]  2.000 [get_ports {LEDG[2]}]
set_output_delay -add_delay -max -clock [get_clocks {CLOCK_50}]  3.000 [get_ports {LEDG[3]}]
set_output_delay -add_delay -min -clock [get_clocks {CLOCK_50}]  2.000 [get_ports {LEDG[3]}]
set_output_delay -add_delay -max -clock [get_clocks {CLOCK_50}]  3.000 [get_ports {LEDR[0]}]
set_output_delay -add_delay -min -clock [get_clocks {CLOCK_50}]  2.000 [get_ports {LEDR[0]}]
set_output_delay -add_delay -max -clock [get_clocks {CLOCK_50}]  3.000 [get_ports {LEDR[1]}]
set_output_delay -add_delay -min -clock [get_clocks {CLOCK_50}]  2.000 [get_ports {LEDR[1]}]
set_output_delay -add_delay -max -clock [get_clocks {CLOCK_50}]  3.000 [get_ports {LEDR[2]}]
set_output_delay -add_delay -min -clock [get_clocks {CLOCK_50}]  2.000 [get_ports {LEDR[2]}]
set_output_delay -add_delay -max -clock [get_clocks {CLOCK_50}]  3.000 [get_ports {LEDR[3]}]
set_output_delay -add_delay -min -clock [get_clocks {CLOCK_50}]  2.000 [get_ports {LEDR[3]}]
set_output_delay -add_delay -max -clock [get_clocks {CLOCK_50}]  3.000 [get_ports {LEDR[4]}]
set_output_delay -add_delay -min -clock [get_clocks {CLOCK_50}]  2.000 [get_ports {LEDR[4]}]
set_output_delay -add_delay -max -clock [get_clocks {CLOCK_50}]  3.000 [get_ports {LEDR[5]}]
set_output_delay -add_delay -min -clock [get_clocks {CLOCK_50}]  2.000 [get_ports {LEDR[5]}]
set_output_delay -add_delay -max -clock [get_clocks {CLOCK_50}]  3.000 [get_ports {LEDR[6]}]
set_output_delay -add_delay -min -clock [get_clocks {CLOCK_50}]  2.000 [get_ports {LEDR[6]}]
set_output_delay -add_delay -max -clock [get_clocks {CLOCK_50}]  3.000 [get_ports {LEDR[7]}]
set_output_delay -add_delay -min -clock [get_clocks {CLOCK_50}]  2.000 [get_ports {LEDR[7]}]
set_output_delay -add_delay -max -clock [get_clocks {CLOCK_50}]  3.000 [get_ports {LEDR[8]}]
set_output_delay -add_delay -min -clock [get_clocks {CLOCK_50}]  2.000 [get_ports {LEDR[8]}]
set_output_delay -add_delay -max -clock [get_clocks {CLOCK_50}]  3.000 [get_ports {LEDR[9]}]
set_output_delay -add_delay -min -clock [get_clocks {CLOCK_50}]  2.000 [get_ports {LEDR[9]}]
set_output_delay -add_delay -max -clock [get_clocks {CLOCK_50}]  3.000 [get_ports {LEDR[10]}]
set_output_delay -add_delay -min -clock [get_clocks {CLOCK_50}]  2.000 [get_ports {LEDR[10]}]
set_output_delay -add_delay -max -clock [get_clocks {CLOCK_50}]  3.000 [get_ports {LEDR[11]}]
set_output_delay -add_delay -min -clock [get_clocks {CLOCK_50}]  2.000 [get_ports {LEDR[11]}]
set_output_delay -add_delay -max -clock [get_clocks {CLOCK_50}]  3.000 [get_ports {LEDR[12]}]
set_output_delay -add_delay -min -clock [get_clocks {CLOCK_50}]  2.000 [get_ports {LEDR[12]}]
set_output_delay -add_delay -max -clock [get_clocks {CLOCK_50}]  3.000 [get_ports {LEDR[13]}]
set_output_delay -add_delay -min -clock [get_clocks {CLOCK_50}]  2.000 [get_ports {LEDR[13]}]
set_output_delay -add_delay -max -clock [get_clocks {CLOCK_50}]  3.000 [get_ports {LEDR[14]}]
set_output_delay -add_delay -min -clock [get_clocks {CLOCK_50}]  2.000 [get_ports {LEDR[14]}]
set_output_delay -add_delay -max -clock [get_clocks {CLOCK_50}]  3.000 [get_ports {LEDR[15]}]
set_output_delay -add_delay -min -clock [get_clocks {CLOCK_50}]  2.000 [get_ports {LEDR[15]}]
set_output_delay -add_delay -max -clock [get_clocks {CLOCK_50}]  3.000 [get_ports {LEDR[16]}]
set_output_delay -add_delay -min -clock [get_clocks {CLOCK_50}]  2.000 [get_ports {LEDR[16]}]
set_output_delay -add_delay -max -clock [get_clocks {CLOCK_50}]  3.000 [get_ports {LEDR[17]}]
set_output_delay -add_delay -min -clock [get_clocks {CLOCK_50}]  2.000 [get_ports {LEDR[17]}]


#**************************************************************
# Set Clock Groups
#**************************************************************



#**************************************************************
# Set False Path
#**************************************************************



#**************************************************************
# Set Multicycle Path
#**************************************************************



#**************************************************************
# Set Maximum Delay
#**************************************************************



#**************************************************************
# Set Minimum Delay
#**************************************************************



#**************************************************************
# Set Input Transition
#**************************************************************

