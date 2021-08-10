onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -color {Spring Green} /master_tb/clk
add wave -noupdate -expand -group Reset -color White /master_tb/rstN
add wave -noupdate -expand -group {From TOP Module} -color Yellow -label {External burst write} /master_tb/burst
add wave -noupdate -expand -group {From TOP Module} -color Yellow -label {Read or Write} /master_tb/rdWr
add wave -noupdate -expand -group {From TOP Module} -color Yellow -label {Internal or external (0/1)} /master_tb/inEx
add wave -noupdate -expand -group {From TOP Module} -color Cyan -label {DATA in from TOP} -radix unsigned /master_tb/data
add wave -noupdate -expand -group {From TOP Module} -color Magenta -label {Address Ext} -radix unsigned /master_tb/address
add wave -noupdate -expand -group {From TOP Module} -color Gold -label SlaveId /master_tb/slaveId
add wave -noupdate -expand -group {From TOP Module} -label Start /master_tb/start
add wave -noupdate -expand -group {From TOP Module} -color White -label States /master_tb/dut/state
add wave -noupdate -expand -group {From TOP Module} -label {Start Address} -radix unsigned /master_tb/dut/addressInternalBurtstBegin
add wave -noupdate -expand -group {From TOP Module} -label {End Address} -radix unsigned /master_tb/dut/addressInternalBurtstEnd
add wave -noupdate -expand -group {From TOP Module} -label {Burst len} -radix unsigned /master_tb/dut/burstLen
add wave -noupdate -group {Internal RAM} -color {Slate Blue} -label {Input DATA} -radix unsigned /master_tb/dut/bram/data
add wave -noupdate -group {Internal RAM} -color Yellow -label {Write enable} /master_tb/dut/bram/wr
add wave -noupdate -group {Internal RAM} -color {Medium Violet Red} -label Addresss -radix unsigned /master_tb/dut/bram/address
add wave -noupdate -group {Internal RAM} -color {Slate Blue} -label {DATA OUT} -radix unsigned /master_tb/dut/bram/q
add wave -noupdate -group {TO TOP  Module} -color {Slate Blue} -label {Done Communication} /master_tb/doneCom
add wave -noupdate -group {TO TOP  Module} -color Magenta -label {Address Ext} /master_tb/address
add wave -noupdate -group {TO TOP  Module} -color Cyan -label {DATA Out to TOP} /master_tb/dataOut
add wave -noupdate -group {From slave} -color Goldenrod -label {Read data} -radix unsigned /master_tb/rD
add wave -noupdate -group {From slave} -color Yellow -label Ready /master_tb/ready
add wave -noupdate -group {TO Slave} -color White -label {TEMP CONTROL} /master_tb/dut/tempControl
add wave -noupdate -group {TO Slave} -color {Yellow Green} -label Control /master_tb/control
add wave -noupdate -group {TO Slave} -color {Slate Blue} -label {Write DATA} /master_tb/wrD
add wave -noupdate -group {TO Slave} -label Valid /master_tb/valid
add wave -noupdate -group {TO Slave} -color Gold -label Last /master_tb/last
add wave -noupdate -expand -group {From Arbiter} -label arbCont /master_tb/arbCont
add wave -noupdate -expand -group {To Arbiter} -color {Slate Blue} -label arbSend /master_tb/arbSend
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {77677 ps} 0} {{Cursor 2} {252831 ps} 0}
quietly wave cursor active 2
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ps} {970200 ps}
