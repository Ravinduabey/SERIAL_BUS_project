onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -expand -group Top_tb /top_tb/clk
add wave -noupdate -expand -group Top_tb -expand /top_tb/KEY
add wave -noupdate -expand -group Top_tb -radix binary /top_tb/SW
add wave -noupdate -expand -group Top_tb /top_tb/rstN
add wave -noupdate -expand -group Top_tb /top_tb/communication_done
add wave -noupdate -expand -group Top_tb /top_tb/communication_ready
add wave -noupdate -expand -group Top_tb /top_tb/g_rx
add wave -noupdate -expand -group Top_tb /top_tb/g_tx
add wave -noupdate -expand -group Top_tb /top_tb/s_rx
add wave -noupdate -expand -group Top_tb /top_tb/s_tx
add wave -noupdate -expand -group Top_tb {/top_tb/dut/MASTER[1]/master/data}
add wave -noupdate {/top_tb/dut/MASTER[1]/master/state}
add wave -noupdate {/top_tb/dut/MASTER[1]/master/inEx}
add wave -noupdate {/top_tb/dut/MASTER[1]/master/wr}
add wave -noupdate {/top_tb/dut/MASTER[1]/master/start}
add wave -noupdate -group Top /top_tb/dut/jump_stateN
add wave -noupdate -group Top /top_tb/dut/jump_next_addr
add wave -noupdate -group Top /top_tb/dut/current_state
add wave -noupdate -group Top /top_tb/dut/current_config_state
add wave -noupdate -group Top /top_tb/dut/M_dataOut
add wave -noupdate -group Top /top_tb/dut/M_start
add wave -noupdate -group Top /top_tb/dut/M_address
add wave -noupdate -expand -group interconnector /top_tb/dut/bus_interconnect/bus_state
add wave -noupdate -expand -group interconnector /top_tb/dut/bus_interconnect/control_mux
add wave -noupdate -expand -group interconnector /top_tb/dut/bus_interconnect/last_mux
add wave -noupdate -expand -group interconnector /top_tb/dut/bus_interconnect/rD_mux
add wave -noupdate -expand -group interconnector /top_tb/dut/bus_interconnect/ready_mux
add wave -noupdate -expand -group interconnector /top_tb/dut/bus_interconnect/valid_mux
add wave -noupdate -expand -group interconnector /top_tb/dut/bus_interconnect/wD_mux
add wave -noupdate -expand -group M0 {/top_tb/dut/MASTER[0]/master/inEx}
add wave -noupdate -expand -group M0 {/top_tb/dut/MASTER[0]/master/data}
add wave -noupdate -expand -group M0 {/top_tb/dut/MASTER[0]/master/start}
add wave -noupdate -expand -group M0 -label wr_bram {/top_tb/dut/MASTER[0]/master/wr}
add wave -noupdate -expand -group M0 {/top_tb/dut/MASTER[0]/master/slaveId}
add wave -noupdate -expand -group M0 {/top_tb/dut/MASTER[0]/master/arbSend}
add wave -noupdate -expand -group M0 {/top_tb/dut/MASTER[0]/master/arbiterRequest}
add wave -noupdate -expand -group M0 {/top_tb/dut/MASTER[0]/master/arbiterCounnter}
add wave -noupdate -expand -group M0 {/top_tb/dut/MASTER[0]/master/state}
add wave -noupdate -expand -group M0 {/top_tb/dut/MASTER[0]/master/internalComState}
add wave -noupdate -expand -group M0 {/top_tb/dut/MASTER[0]/master/communicationState}
add wave -noupdate -expand -group M0 {/top_tb/dut/MASTER[0]/master/tempRdWr}
add wave -noupdate -expand -group M0 {/top_tb/dut/MASTER[0]/master/tempBurst}
add wave -noupdate -expand -group M0 {/top_tb/dut/MASTER[0]/master/CONTROL_LEN}
add wave -noupdate -expand -group M0 {/top_tb/dut/MASTER[0]/master/CONTROL_LEN}
add wave -noupdate -expand -group M0 {/top_tb/dut/MASTER[0]/master/rD}
add wave -noupdate -expand -group M0 {/top_tb/dut/MASTER[0]/master/ready}
add wave -noupdate -expand -group M0 -radix unsigned {/top_tb/dut/MASTER[0]/master/controlCounter}
add wave -noupdate -expand -group M0 {/top_tb/dut/MASTER[0]/master/address}
add wave -noupdate -expand -group M0 {/top_tb/dut/MASTER[0]/master/tempControl_2}
add wave -noupdate -expand -group M0 {/top_tb/dut/MASTER[0]/master/tempControl}
add wave -noupdate -expand -group M0 {/top_tb/dut/MASTER[0]/master/burst}
add wave -noupdate -expand -group M0 {/top_tb/dut/MASTER[0]/master/burstLen}
add wave -noupdate -expand -group M0 {/top_tb/dut/MASTER[0]/master/addressInternalBurtstBegin}
add wave -noupdate -expand -group M0 {/top_tb/dut/MASTER[0]/master/addressInternalBurtstEnd}
add wave -noupdate -expand -group {Slave 3} {/top_tb/dut/SLAVE[2]/slave/config_buffer}
add wave -noupdate -expand -group {Slave 3} {/top_tb/dut/SLAVE[2]/slave/DELAY}
add wave -noupdate -expand -group {Slave 3} {/top_tb/dut/SLAVE[2]/slave/config_counter}
add wave -noupdate -expand -group {Slave 3} {/top_tb/dut/SLAVE[2]/slave/temp_control}
add wave -noupdate -expand -group {Slave 3} {/top_tb/dut/SLAVE[2]/slave/rD_buffer}
add wave -noupdate -expand -group {Slave 3} {/top_tb/dut/SLAVE[2]/slave/rD_counter}
add wave -noupdate -expand -group {Slave 3} {/top_tb/dut/SLAVE[2]/slave/rD_temp}
add wave -noupdate -expand -group {Slave 3} {/top_tb/dut/SLAVE[2]/slave/wD_buffer}
add wave -noupdate -expand -group {Slave 3} {/top_tb/dut/SLAVE[2]/slave/wD_counter}
add wave -noupdate -expand -group {Slave 3} {/top_tb/dut/SLAVE[2]/slave/wD_temp}
add wave -noupdate -expand -group {Slave 3} {/top_tb/dut/SLAVE[2]/slave/ram}
add wave -noupdate -expand -group {Slave 3} {/top_tb/dut/SLAVE[2]/slave/address}
add wave -noupdate -expand -group {Slave 3} {/top_tb/dut/SLAVE[2]/slave/delay_counter}
add wave -noupdate -expand -group {Slave 3} {/top_tb/dut/SLAVE[2]/slave/control_buffer}
add wave -noupdate -expand -group {Slave 3} {/top_tb/dut/SLAVE[2]/slave/con_counter}
add wave -noupdate -expand -group {Slave 3} {/top_tb/dut/SLAVE[2]/slave/com_status}
add wave -noupdate -expand -group {Slave 3} {/top_tb/dut/SLAVE[2]/slave/state}
add wave -noupdate -expand -group {Slave 3} {/top_tb/dut/SLAVE[2]/slave/prev_state}
add wave -noupdate -group S0 {/top_tb/dut/SLAVE[0]/slave/state}
add wave -noupdate -group S0 {/top_tb/dut/SLAVE[0]/slave/rD_buffer}
add wave -noupdate -group S0 {/top_tb/dut/SLAVE[0]/slave/wD_buffer}
add wave -noupdate -group S0 {/top_tb/dut/SLAVE[0]/slave/config_buffer}
add wave -noupdate -group M1 {/top_tb/dut/MASTER[1]/master/slaveId}
add wave -noupdate -group M1 {/top_tb/dut/MASTER[1]/master/arbiterRequest}
add wave -noupdate -group M1 {/top_tb/dut/MASTER[1]/master/arbiterCounnter}
add wave -noupdate -group M1 {/top_tb/dut/MASTER[1]/master/arbSend}
add wave -noupdate -group M1 {/top_tb/dut/MASTER[1]/master/internalComState}
add wave -noupdate -group M1 {/top_tb/dut/MASTER[1]/master/communicationState}
add wave -noupdate -group M1 {/top_tb/dut/MASTER[1]/master/addressInternalBurtstBegin}
add wave -noupdate -group M1 {/top_tb/dut/MASTER[1]/master/addressInternalBurtstEnd}
add wave -noupdate -group M1 {/top_tb/dut/MASTER[1]/master/start}
add wave -noupdate -group M1 {/top_tb/dut/MASTER[1]/master/burst}
add wave -noupdate -group M1 {/top_tb/dut/MASTER[1]/master/state}
add wave -noupdate -group M1 {/top_tb/dut/MASTER[1]/master/address}
add wave -noupdate -group M1 {/top_tb/dut/MASTER[1]/master/burstLen}
add wave -noupdate -group M1 -radix binary {/top_tb/dut/MASTER[1]/master/tempControl_2}
add wave -noupdate -group Arbiter /top_tb/dut/arbiter/control_unit/state
add wave -noupdate -group Arbiter /top_tb/dut/arbiter/control_unit/cur_slave
add wave -noupdate -group Arbiter /top_tb/dut/arbiter/control_unit/cur_com_state
add wave -noupdate -group Arbiter /top_tb/dut/arbiter/control_unit/cur_master
add wave -noupdate -group Arbiter /top_tb/dut/arbiter/THRESH
add wave -noupdate -group Arbiter /top_tb/dut/arbiter/control_unit/thresh
add wave -noupdate -group Arbiter /top_tb/dut/arbiter/control_unit/THRESH
add wave -noupdate -group Arbiter /top_tb/dut/arbiter/NO_MASTERS
add wave -noupdate -group Arbiter /top_tb/dut/arbiter/NO_SLAVES
add wave -noupdate -group Arbiter /top_tb/dut/arbiter/control_unit/bus_state
add wave -noupdate -group Arbiter /top_tb/dut/arbiter/control_unit/cur_cmd
add wave -noupdate -group Arbiter /top_tb/dut/arbiter/control_unit/cur_done
add wave -noupdate -group ext_M /top_tb/dut/masterExternal/state
add wave -noupdate -group ext_M /top_tb/dut/masterExternal/communicationState
add wave -noupdate -group ext_M -radix unsigned /top_tb/dut/masterExternal/dataOut
add wave -noupdate -group ext_M /top_tb/dut/masterExternal/arbCont
add wave -noupdate -group ext_M /top_tb/clk
add wave -noupdate -group ext_M /top_tb/dut/masterExternal/start
add wave -noupdate -group ext_M -radix unsigned /top_tb/dut/masterExternal/CONTROL_LEN
add wave -noupdate -group ext_M /top_tb/dut/masterExternal/control
add wave -noupdate -group ext_M -radix unsigned /top_tb/dut/masterExternal/controlCounter
add wave -noupdate -group ext_M /top_tb/dut/masterExternal/doneCom
add wave -noupdate -group ext_M /top_tb/dut/masterExternal/eoc
add wave -noupdate -group ext_M -radix unsigned /top_tb/dut/masterExternal/i
add wave -noupdate -group ext_M /top_tb/dut/masterExternal/tempReadWriteData
add wave -noupdate -group ext_M -color Brown /top_tb/dut/masterExternal/ready
add wave -noupdate -group ext_M /top_tb/dut/masterExternal/rD
add wave -noupdate -group ext_M /top_tb/dut/masterExternal/arbSend
add wave -noupdate -group ext_slave /top_tb/dut/uart_slave_system/uart_slave/state
add wave -noupdate -group ext_slave /top_tb/dut/uart_slave_system/uart_slave/rD_buffer
add wave -noupdate -group ext_slave /top_tb/dut/uart_slave_system/uart_slave/com_status
add wave -noupdate -group ext_slave -radix unsigned /top_tb/dut/uart_slave_system/uart_slave/rD_counter
add wave -noupdate -group ext_slave -radix binary /top_tb/dut/uart_slave_system/uart_slave/config_buffer
add wave -noupdate -group ext_slave /top_tb/dut/uart_slave_system/uart_slave/wD_buffer
add wave -noupdate -group ext_slave -color Yellow -radix unsigned /top_tb/dut/uart_slave_system/uart_slave/wD_counter
add wave -noupdate -group ext_slave /top_tb/dut/uart_slave_system/g_rx
add wave -noupdate -group ext_slave /top_tb/dut/uart_slave_system/g_tx
add wave -noupdate -group ext_slave /top_tb/dut/uart_slave_system/s_rx
add wave -noupdate -group ext_slave /top_tb/dut/uart_slave_system/s_tx
add wave -noupdate -group ext_slave -radix unsigned /top_tb/dut/uart_slave_system/uart_slave/s_byteForTx
add wave -noupdate -group ext_slave /top_tb/dut/uart_slave_system/uart_slave/g_byteForTx
add wave -noupdate -group ext_slave /top_tb/dut/uart_slave_system/uart_slave/g_byteFromRx
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {5650713149 ps} 0} {{Cursor 2} {9182249722 ps} 0} {{Cursor 3} {10000 ps} 0}
quietly wave cursor active 3
configure wave -namecolwidth 276
configure wave -valuecolwidth 152
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
WaveRestoreZoom {0 ps} {161728 ps}
