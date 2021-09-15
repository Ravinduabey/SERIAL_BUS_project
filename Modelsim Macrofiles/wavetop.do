onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -group Top_tb /top_tb/clk
add wave -noupdate -group Top_tb /top_tb/KEY
add wave -noupdate -group Top_tb -radix binary /top_tb/SW
add wave -noupdate -group Top_tb /top_tb/rstN
add wave -noupdate -group Top_tb /top_tb/communication_done
add wave -noupdate -group Top_tb /top_tb/communication_ready
add wave -noupdate {/top_tb/dut/MASTER[0]/master/communicationState}
add wave -noupdate {/top_tb/dut/MASTER[1]/master/communicationState}
add wave -noupdate {/top_tb/dut/MASTER[1]/master/control}
add wave -noupdate {/top_tb/dut/SLAVE[2]/slave/config_buffer}
add wave -noupdate {/top_tb/dut/SLAVE[1]/slave/config_buffer}
add wave -noupdate {/top_tb/dut/SLAVE[0]/slave/config_buffer}
add wave -noupdate -group Top /top_tb/dut/jump_stateN
add wave -noupdate -group Top /top_tb/dut/jump_next_addr
add wave -noupdate -group Top /top_tb/dut/current_state
add wave -noupdate -group Top /top_tb/dut/current_config_state
add wave -noupdate -group Top /top_tb/dut/M_dataOut
add wave -noupdate -group Top /top_tb/dut/M_start
add wave -noupdate -group Top /top_tb/dut/M_address
add wave -noupdate -group M0 {/top_tb/dut/MASTER[0]/master/tempReadData}
add wave -noupdate -group M0 {/top_tb/dut/MASTER[0]/master/internalComState}
add wave -noupdate -group M0 {/top_tb/dut/MASTER[0]/master/communicationState}
add wave -noupdate -group M0 {/top_tb/dut/MASTER[0]/master/address}
add wave -noupdate -group M0 {/top_tb/dut/MASTER[0]/master/burst}
add wave -noupdate -group M0 {/top_tb/dut/MASTER[0]/master/burstLen}
add wave -noupdate -group M0 {/top_tb/dut/MASTER[0]/master/addressInternalBurtstBegin}
add wave -noupdate -group M0 {/top_tb/dut/MASTER[0]/master/addressInternalBurtstEnd}
add wave -noupdate -group M0 {/top_tb/dut/MASTER[0]/master/tempControl_2}
add wave -noupdate -group S0 {/top_tb/dut/SLAVE[0]/slave/state}
add wave -noupdate -group S0 {/top_tb/dut/SLAVE[0]/slave/rD_buffer}
add wave -noupdate -group S0 {/top_tb/dut/SLAVE[0]/slave/wD_buffer}
add wave -noupdate -group S0 {/top_tb/dut/SLAVE[0]/slave/config_buffer}
add wave -noupdate -expand -group M1 {/top_tb/dut/MASTER[1]/master/tempReadData}
add wave -noupdate -expand -group M1 {/top_tb/dut/MASTER[1]/master/internalComState}
add wave -noupdate -expand -group M1 {/top_tb/dut/MASTER[1]/master/communicationState}
add wave -noupdate -expand -group M1 {/top_tb/dut/MASTER[1]/master/addressInternalBurtstBegin}
add wave -noupdate -expand -group M1 {/top_tb/dut/MASTER[1]/master/addressInternalBurtstEnd}
add wave -noupdate -expand -group M1 {/top_tb/dut/MASTER[1]/master/start}
add wave -noupdate -expand -group M1 {/top_tb/dut/MASTER[1]/master/burst}
add wave -noupdate -expand -group M1 {/top_tb/dut/MASTER[1]/master/state}
add wave -noupdate -expand -group M1 {/top_tb/dut/MASTER[1]/master/address}
add wave -noupdate -expand -group M1 {/top_tb/dut/MASTER[1]/master/burstLen}
add wave -noupdate -expand -group M1 -radix binary {/top_tb/dut/MASTER[1]/master/tempControl_2}
add wave -noupdate -group Arbiter /top_tb/dut/arbiter/control_unit/state
add wave -noupdate {/top_tb/dut/SLAVE[1]/slave/state}
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {24711223 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 294
configure wave -valuecolwidth 135
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
WaveRestoreZoom {24566642 ps} {24855804 ps}
