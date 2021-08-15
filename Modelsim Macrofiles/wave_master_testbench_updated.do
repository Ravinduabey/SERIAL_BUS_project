onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -expand -group Reset -color White /master_tb/rstN
add wave -noupdate -expand -group {From TOP Module} -color Yellow -label {External burst write} /master_tb/burst
add wave -noupdate -expand -group {From TOP Module} -color Yellow -label {Read or Write} /master_tb/rdWr
add wave -noupdate -expand -group {From TOP Module} -color Yellow -label {Internal or external (0/1)} /master_tb/inEx
add wave -noupdate -expand -group {From TOP Module} -color Cyan -label {DATA in from TOP} -radix unsigned /master_tb/data
add wave -noupdate -expand -group {From TOP Module} -color Magenta -label {Address Ext} -radix unsigned /master_tb/address
add wave -noupdate -expand -group {From TOP Module} -color Gold -label SlaveId /master_tb/slaveId
add wave -noupdate -expand -group {From TOP Module} -label Start /master_tb/start
add wave -noupdate -expand -group {From TOP Module} -color Thistle -label EOC /master_tb/eoc
add wave -noupdate -expand -group {From TOP Module} -color White -label States /master_tb/dut/state
add wave -noupdate -expand -group {From TOP Module} -label {Start Address} -radix unsigned /master_tb/dut/addressInternalBurtstBegin
add wave -noupdate -expand -group {From TOP Module} -label {End Address} -radix unsigned /master_tb/dut/addressInternalBurtstEnd
add wave -noupdate -expand -group {From TOP Module} -label {Burst len} -radix unsigned /master_tb/dut/burstLen
add wave -noupdate -expand -group {Internal RAM} -color {Slate Blue} -label {Input DATA} -radix unsigned /master_tb/dut/bram/data
add wave -noupdate -expand -group {Internal RAM} -color Yellow -label {Write enable} /master_tb/dut/bram/wr
add wave -noupdate -expand -group {Internal RAM} -color {Medium Violet Red} -label Addresss -radix unsigned /master_tb/dut/bram/address
add wave -noupdate -expand -group {Internal RAM} -color {Slate Blue} -label {DATA OUT} -radix unsigned /master_tb/dut/bram/q
add wave -noupdate -label tempBurst /master_tb/dut/tempBurst
add wave -noupdate -color {Spring Green} -label clk /master_tb/clk
add wave -noupdate -radix unsigned /master_tb/dut/clock_counter
add wave -noupdate -group {TO TOP  Module} -color {Slate Blue} -label {Done Communication} /master_tb/doneCom
add wave -noupdate -group {TO TOP  Module} -color Magenta -label {Address Ext} /master_tb/address
add wave -noupdate -group {TO TOP  Module} -color Cyan -label {DATA Out to TOP} /master_tb/dataOut
add wave -noupdate -group {From slave} -label {READ or WRITE} /master_tb/dut/tempRdWr
add wave -noupdate -group {From slave} -label {bit position} -radix unsigned /master_tb/dut/i
add wave -noupdate -group {From slave} -color {Slate Blue} -label {Read data temp} -radix binary /master_tb/dut/tempReadData
add wave -noupdate -group {From slave} -color Goldenrod -label {Read data} -radix unsigned /master_tb/rD
add wave -noupdate -group {From slave} -color Yellow -label Ready /master_tb/ready
add wave -noupdate -expand -group {TO Slave} -color {Pale Green} -label {Control counter} -radix unsigned /master_tb/dut/controlCounter
add wave -noupdate -expand -group {TO Slave} -color White -label {TEMP CONTROL} /master_tb/dut/tempControl
add wave -noupdate -expand -group {TO Slave} -color {Yellow Green} -label Control /master_tb/control
add wave -noupdate -expand -group {TO Slave} -color {Slate Blue} -label {Write DATA} /master_tb/wrD
add wave -noupdate -expand -group {TO Slave} -label {Data To be sent} -radix unsigned /master_tb/dut/tempReadData
add wave -noupdate -expand -group {TO Slave} -radix decimal /master_tb/dut/address_counter
add wave -noupdate -expand -group {TO Slave} -label Valid /master_tb/valid
add wave -noupdate -expand -group {TO Slave} -color Gold -label Last /master_tb/last
add wave -noupdate -group burst -label BurstLen -radix unsigned -childformat {{{/master_tb/dut/burstLen[11]} -radix unsigned} {{/master_tb/dut/burstLen[10]} -radix unsigned} {{/master_tb/dut/burstLen[9]} -radix unsigned} {{/master_tb/dut/burstLen[8]} -radix unsigned} {{/master_tb/dut/burstLen[7]} -radix unsigned} {{/master_tb/dut/burstLen[6]} -radix unsigned} {{/master_tb/dut/burstLen[5]} -radix unsigned} {{/master_tb/dut/burstLen[4]} -radix unsigned} {{/master_tb/dut/burstLen[3]} -radix unsigned} {{/master_tb/dut/burstLen[2]} -radix unsigned} {{/master_tb/dut/burstLen[1]} -radix unsigned} {{/master_tb/dut/burstLen[0]} -radix unsigned}} -subitemconfig {{/master_tb/dut/burstLen[11]} {-height 15 -radix unsigned} {/master_tb/dut/burstLen[10]} {-height 15 -radix unsigned} {/master_tb/dut/burstLen[9]} {-height 15 -radix unsigned} {/master_tb/dut/burstLen[8]} {-height 15 -radix unsigned} {/master_tb/dut/burstLen[7]} {-height 15 -radix unsigned} {/master_tb/dut/burstLen[6]} {-height 15 -radix unsigned} {/master_tb/dut/burstLen[5]} {-height 15 -radix unsigned} {/master_tb/dut/burstLen[4]} {-height 15 -radix unsigned} {/master_tb/dut/burstLen[3]} {-height 15 -radix unsigned} {/master_tb/dut/burstLen[2]} {-height 15 -radix unsigned} {/master_tb/dut/burstLen[1]} {-height 15 -radix unsigned} {/master_tb/dut/burstLen[0]} {-height 15 -radix unsigned}} /master_tb/dut/burstLen
add wave -noupdate -label i -radix unsigned /master_tb/dut/i
add wave -noupdate -label States /master_tb/dut/state
add wave -noupdate -label Start /master_tb/start
add wave -noupdate -label {Internal com states} /master_tb/dut/communicationState
add wave -noupdate -label {Internale read write states} /master_tb/dut/internalComState
add wave -noupdate -expand -group {From Arbiter} -label arbCont /master_tb/arbCont
add wave -noupdate -expand -group {From Arbiter} -label {From Arbiter} /master_tb/dut/fromArbiter
add wave -noupdate -group {To Arbiter} -label From_arbiter -radix binary /master_tb/dut/fromArbiter
add wave -noupdate -group {To Arbiter} -label Counter_arb -radix unsigned /master_tb/dut/arbiterCounnter
add wave -noupdate -group {To Arbiter} -label {arbiter request} /master_tb/dut/arbiterRequest
add wave -noupdate -group {To Arbiter} -color {Slate Blue} -label arbSend /master_tb/arbSend
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 2} {227000 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 121
configure wave -valuecolwidth 154
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
WaveRestoreZoom {0 ps} {1263938 ps}
