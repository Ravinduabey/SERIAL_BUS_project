onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -expand -group {slave 0} -group {s0 logic} -label address {/top_tb/dut/SLAVE[0]/slave/address}
add wave -noupdate -expand -group {slave 0} -group {s0 logic} -label {wD buffer} {/top_tb/dut/SLAVE[0]/slave/wD_buffer}
add wave -noupdate -expand -group {slave 0} -group {s0 logic} -label {rD buffer} {/top_tb/dut/SLAVE[0]/slave/rD_buffer}
add wave -noupdate -expand -group {slave 0} -group {s0 logic} -label {delay counter} {/top_tb/dut/SLAVE[0]/slave/delay_counter}
add wave -noupdate -expand -group {slave 0} -group {s0 logic} -label {config counter} {/top_tb/dut/SLAVE[0]/slave/config_counter}
add wave -noupdate -expand -group {slave 0} -group {s0 logic} -label {config buffer} {/top_tb/dut/SLAVE[0]/slave/config_buffer}
add wave -noupdate -expand -group {slave 0} -group {s0 logic} -label {rD counter} {/top_tb/dut/SLAVE[0]/slave/rD_counter}
add wave -noupdate -expand -group {slave 0} -group {s0 logic} -label {wD counter} {/top_tb/dut/SLAVE[0]/slave/wD_counter}
add wave -noupdate -expand -group {slave 0} -label {comm. status} {/top_tb/dut/SLAVE[0]/slave/com_status}
add wave -noupdate -expand -group {slave 0} -label state {/top_tb/dut/SLAVE[0]/slave/state}
add wave -noupdate -expand -group {slave 1} -group {slave 1 logic} -label {config buffer} {/top_tb/dut/SLAVE[1]/slave/config_buffer}
add wave -noupdate -expand -group {slave 1} -group {slave 1 logic} -label {config counter} {/top_tb/dut/SLAVE[1]/slave/config_counter}
add wave -noupdate -expand -group {slave 1} -group {slave 1 logic} -label {temp address} {/top_tb/dut/SLAVE[1]/slave/temp_address}
add wave -noupdate -expand -group {slave 1} -group {slave 1 logic} -label {rD buffer} -radix hexadecimal {/top_tb/dut/SLAVE[1]/slave/rD_buffer}
add wave -noupdate -expand -group {slave 1} -group {slave 1 logic} -label {temp rD buffer} -radix hexadecimal {/top_tb/dut/SLAVE[1]/slave/temp_rD_buffer}
add wave -noupdate -expand -group {slave 1} -group {slave 1 logic} -label read? {/top_tb/dut/SLAVE[1]/slave/read}
add wave -noupdate -expand -group {slave 1} -group {slave 1 logic} -label {rD counter} {/top_tb/dut/SLAVE[1]/slave/rD_counter}
add wave -noupdate -expand -group {slave 1} -group {slave 1 logic} -label {wD buffer} {/top_tb/dut/SLAVE[1]/slave/wD_buffer}
add wave -noupdate -expand -group {slave 1} -group {slave 1 logic} -label {wD counter} {/top_tb/dut/SLAVE[1]/slave/wD_counter}
add wave -noupdate -expand -group {slave 1} -group {slave 1 logic} -label address {/top_tb/dut/SLAVE[1]/slave/address}
add wave -noupdate -expand -group {slave 1} -label {comm. status} {/top_tb/dut/SLAVE[1]/slave/com_status}
add wave -noupdate -expand -group {slave 1} -label state {/top_tb/dut/SLAVE[1]/slave/state}
add wave -noupdate -expand -group {slave 2} -group {s2 logic} -label {control counter} {/top_tb/dut/SLAVE[2]/slave/config_counter}
add wave -noupdate -expand -group {slave 2} -group {s2 logic} -label address {/top_tb/dut/SLAVE[2]/slave/address}
add wave -noupdate -expand -group {slave 2} -group {s2 logic} -label {read counter} {/top_tb/dut/SLAVE[2]/slave/rD_counter}
add wave -noupdate -expand -group {slave 2} -group {s2 logic} -label {write counter} {/top_tb/dut/SLAVE[2]/slave/wD_counter}
add wave -noupdate -expand -group {slave 2} -group {s2 logic} -label {read data buffer} {/top_tb/dut/SLAVE[2]/slave/rD_buffer}
add wave -noupdate -expand -group {slave 2} -group {s2 logic} -label {write data buffer} {/top_tb/dut/SLAVE[2]/slave/wD_buffer}
add wave -noupdate -expand -group {slave 2} -group {s2 logic} -label {delay counter} -radix unsigned {/top_tb/dut/SLAVE[2]/slave/delay_counter}
add wave -noupdate -expand -group {slave 2} -group {s2 logic} -label {control buffer} {/top_tb/dut/SLAVE[2]/slave/config_buffer}
add wave -noupdate -expand -group {slave 2} -label {comm. status} {/top_tb/dut/SLAVE[2]/slave/com_status}
add wave -noupdate -expand -group {slave 2} -label state {/top_tb/dut/SLAVE[2]/slave/state}
add wave -noupdate -expand -group {master-slave interconnect} -label control /top_tb/dut/bus_interconnect/control_mux
add wave -noupdate -expand -group {master-slave interconnect} -label {write data} /top_tb/dut/bus_interconnect/wD_mux
add wave -noupdate -expand -group {master-slave interconnect} -label valid /top_tb/dut/bus_interconnect/valid_mux
add wave -noupdate -expand -group {master-slave interconnect} -label last /top_tb/dut/bus_interconnect/last_mux
add wave -noupdate -expand -group {master-slave interconnect} -label {read data} /top_tb/dut/bus_interconnect/rD_mux
add wave -noupdate -expand -group {master-slave interconnect} -label ready /top_tb/dut/bus_interconnect/ready_mux
add wave -noupdate -expand -group {Master 0} -label state {/top_tb/dut/MASTER[0]/master/state}
add wave -noupdate -expand -group {Master 0} -label {communication state} {/top_tb/dut/MASTER[0]/master/communicationState}
add wave -noupdate -expand -group {Master 0} -label {internal comm state} {/top_tb/dut/MASTER[0]/master/internalComState}
add wave -noupdate -expand -group {Master 0} -group {Master 0 logic} {/top_tb/dut/MASTER[0]/master/addressInternal}
add wave -noupdate -expand -group {Master 0} -group {Master 0 logic} {/top_tb/dut/MASTER[0]/master/addresstemp}
add wave -noupdate -expand -group {Master 0} -group {Master 0 logic} {/top_tb/dut/MASTER[0]/master/addressInternalBurtstBegin}
add wave -noupdate -expand -group {Master 0} -group {Master 0 logic} {/top_tb/dut/MASTER[0]/master/addressInternalBurtstEnd}
add wave -noupdate -expand -group {Master 0} -group {Master 0 logic} -label {control counter} -radix unsigned {/top_tb/dut/MASTER[0]/master/controlCounter}
add wave -noupdate -expand -group {Master 0} -group {Master 0 logic} -label {control out} {/top_tb/dut/MASTER[0]/master/tempControl_2}
add wave -noupdate -expand -group {Master 0} -group {Master 0 logic} -label {burst length} -radix unsigned {/top_tb/dut/MASTER[0]/master/burstLen}
add wave -noupdate -expand -group {Master 0} -group {Master 0 logic} -label {data internal} {/top_tb/dut/MASTER[0]/master/dataInternal}
add wave -noupdate -expand -group {Master 0} -group {Master 0 logic} -label {internal data out} {/top_tb/dut/MASTER[0]/master/internalDataOut}
add wave -noupdate -expand -group {Master 0} -group {Master 0 logic} -label {read/write data} {/top_tb/dut/MASTER[0]/master/tempReadWriteData}
add wave -noupdate -expand -group {Master 0} -group {Master 0 logic} -label {data counter} -radix unsigned {/top_tb/dut/MASTER[0]/master/i}
add wave -noupdate -label {bus state} -radix octal /top_tb/dut/arbiter/control_unit/bus_state
add wave -noupdate -expand -group {Master 1} -label {internal comm. state} {/top_tb/dut/MASTER[1]/master/internalComState}
add wave -noupdate -expand -group {Master 1} -label {communication state} {/top_tb/dut/MASTER[1]/master/communicationState}
add wave -noupdate -expand -group {Master 1} -label state {/top_tb/dut/MASTER[1]/master/state}
add wave -noupdate -expand -group {Master 1} -group {Master 1 logic} -label {data counter} -radix unsigned {/top_tb/dut/MASTER[1]/master/i}
add wave -noupdate -expand -group {Master 1} -group {Master 1 logic} -label {read/write data} {/top_tb/dut/MASTER[1]/master/tempReadWriteData}
add wave -noupdate -expand -group {Master 1} -group {Master 1 logic} -label {internal data out} {/top_tb/dut/MASTER[1]/master/internalDataOut}
add wave -noupdate -expand -group {Master 1} -group {Master 1 logic} -label {internal data} {/top_tb/dut/MASTER[1]/master/dataInternal}
add wave -noupdate -expand -group {Master 1} -group {Master 1 logic} -label {burst length} {/top_tb/dut/MASTER[1]/master/burstLen}
add wave -noupdate -expand -group {Master 1} -group {Master 1 logic} -label {control out} {/top_tb/dut/MASTER[1]/master/tempControl_2}
add wave -noupdate -expand -group {Master 1} -group {Master 1 logic} -label {control counter} -radix unsigned {/top_tb/dut/MASTER[1]/master/controlCounter}
add wave -noupdate -expand -group {Master 1} -group {Master 1 logic} {/top_tb/dut/MASTER[1]/master/addressInternalBurtstEnd}
add wave -noupdate -expand -group {Master 1} -group {Master 1 logic} {/top_tb/dut/MASTER[1]/master/addressInternalBurtstBegin}
add wave -noupdate -expand -group {Master 1} -group {Master 1 logic} {/top_tb/dut/MASTER[1]/master/addresstemp}
add wave -noupdate -expand -group {Master 1} -group {Master 1 logic} -label {int. address} {/top_tb/dut/MASTER[1]/master/addressInternal}
add wave -noupdate -height 15 -group {arbiter CU} -label request /top_tb/dut/arbiter/control_unit/request
add wave -noupdate -height 15 -group {arbiter CU} -label {priority state} /top_tb/dut/arbiter/control_unit/priority_state
add wave -noupdate -height 15 -group {arbiter CU} -label threshold /top_tb/dut/arbiter/control_unit/thresh
add wave -noupdate -height 15 -group {arbiter CU} -label intr /top_tb/dut/arbiter/control_unit/intr
add wave -noupdate -height 15 -group {arbiter CU} -label state /top_tb/dut/arbiter/control_unit/state
add wave -noupdate -group {ext. master} -label {control out} /top_tb/dut/masterExternal/tempControl_2
add wave -noupdate -group {ext. master} -label {read/write data} /top_tb/dut/masterExternal/tempReadWriteData
add wave -noupdate -group {ext. master} -label {ack data} /top_tb/dut/masterExternal/tempDataAck
add wave -noupdate -group {ext. master} -label {data counter} /top_tb/dut/masterExternal/i
add wave -noupdate -group {ext. master} -label {control counter} /top_tb/dut/masterExternal/controlCounter
add wave -noupdate -group {ext. master} -label state /top_tb/dut/masterExternal/state
add wave -noupdate -group {ext. master} -label {communication state} /top_tb/dut/masterExternal/communicationState
add wave -noupdate -group {ext. master} -label {communication done} /top_tb/dut/masterExternal/communicationDone
add wave -noupdate -group {uart signals} -group {get uart} -label {gTx start} /top_tb/dut/uart_slave_system/g_txByteStart
add wave -noupdate -group {uart signals} -group {get uart} -label {gTx byte} /top_tb/dut/uart_slave_system/g_byteForTx
add wave -noupdate -group {uart signals} -group {get uart} -label {gTx ready} /top_tb/dut/uart_slave_system/g_tx_ready
add wave -noupdate -group {uart signals} -group {get uart} -label {gRx start} /top_tb/dut/uart_slave_system/g_new_byte_start
add wave -noupdate -group {uart signals} -group {get uart} -label {gRx done} /top_tb/dut/uart_slave_system/g_new_byte_received
add wave -noupdate -group {uart signals} -group {get uart} -label {gRx byte} /top_tb/dut/uart_slave_system/g_byteFromRx
add wave -noupdate -group {uart signals} -group {get uart} -label {gRx ready} /top_tb/dut/uart_slave_system/g_rx_ready
add wave -noupdate -group {uart signals} -group {send uart} -label {sTx start} /top_tb/dut/uart_slave_system/s_txByteStart
add wave -noupdate -group {uart signals} -group {send uart} -label {sTx byte} /top_tb/dut/uart_slave_system/s_byteForTx
add wave -noupdate -group {uart signals} -group {send uart} -label {sTx ready} /top_tb/dut/uart_slave_system/s_tx_ready
add wave -noupdate -group {uart signals} -group {send uart} -label {sRx start} /top_tb/dut/uart_slave_system/s_new_byte_start
add wave -noupdate -group {uart signals} -group {send uart} -label {sRx done} /top_tb/dut/uart_slave_system/s_new_byte_received
add wave -noupdate -group {uart signals} -group {send uart} -label {sRx byte} /top_tb/dut/uart_slave_system/s_byteFromRx
add wave -noupdate -group {uart signals} -group {send uart} -label {sRx ready} /top_tb/dut/uart_slave_system/s_rx_ready
add wave -noupdate -group {uart slave} -label {control buffer} /top_tb/dut/uart_slave_system/uart_slave/config_buffer
add wave -noupdate -group {uart slave} -label {read buffer} /top_tb/dut/uart_slave_system/uart_slave/rD_buffer
add wave -noupdate -group {uart slave} -label {write buffer} /top_tb/dut/uart_slave_system/uart_slave/wD_buffer
add wave -noupdate -group {uart slave} -label {ack to master} /top_tb/dut/uart_slave_system/uart_slave/masterAck_buffer
add wave -noupdate -group {uart slave} -label {ack to ext. device} /top_tb/dut/uart_slave_system/uart_slave/sAck_buffer
add wave -noupdate -group {uart slave} -label {ack timeout counter} /top_tb/dut/uart_slave_system/uart_slave/ack_counter
add wave -noupdate -group {uart slave} -label {retransmit counter} /top_tb/dut/uart_slave_system/uart_slave/reTx_counter
add wave -noupdate -group {uart slave} -label {control store state} /top_tb/dut/uart_slave_system/uart_slave/sto_status
add wave -noupdate -group {uart slave} -label {communication state} /top_tb/dut/uart_slave_system/uart_slave/com_status
add wave -noupdate -group {uart slave} -label state /top_tb/dut/uart_slave_system/uart_slave/state
add wave -noupdate -group {uart slave} -group arbiter-master-ext. {/top_tb/dut/arbiter/master[2]/master_interconnector/port_in}
add wave -noupdate -group {uart slave} -group arbiter-master-ext. {/top_tb/dut/arbiter/master[2]/master_interconnector/port_out}
add wave -noupdate -group {uart slave} -group arbiter-master-ext. {/top_tb/dut/arbiter/master[2]/master_interconnector/state}
add wave -noupdate -group {uart slave} -group arbiter-master-ext. -label {input buf} {/top_tb/dut/arbiter/master[2]/master_interconnector/input_buf}
add wave -noupdate -group {uart slave} -group arbiter-master-ext. {/top_tb/dut/arbiter/master[2]/master_interconnector/request}
add wave -noupdate -group {arbiter-master 0} -label request {/top_tb/dut/arbiter/master[0]/master_interconnector/request}
add wave -noupdate -group {arbiter-master 0} -label {input buffer} {/top_tb/dut/arbiter/master[0]/master_interconnector/input_buf}
add wave -noupdate -group {arbiter-master 0} -label state {/top_tb/dut/arbiter/master[0]/master_interconnector/state}
add wave -noupdate -group {arbiter-master 0} -label {arbiter to master} {/top_tb/dut/arbiter/master[0]/master_interconnector/port_out}
add wave -noupdate -group {arbiter-master 0} -label {master to arbiter} {/top_tb/dut/arbiter/master[0]/master_interconnector/port_in}
add wave -noupdate -group {arbiter-master 1} -label request {/top_tb/dut/arbiter/master[1]/master_interconnector/request}
add wave -noupdate -group {arbiter-master 1} -label {input buf} {/top_tb/dut/arbiter/master[1]/master_interconnector/input_buf}
add wave -noupdate -group {arbiter-master 1} -label state {/top_tb/dut/arbiter/master[1]/master_interconnector/state}
add wave -noupdate -group {arbiter-master 1} -label {arbiter to master} {/top_tb/dut/arbiter/master[1]/master_interconnector/port_out}
add wave -noupdate -group {arbiter-master 1} -label {master to arbiter} {/top_tb/dut/arbiter/master[1]/master_interconnector/port_in}
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Master done} {8490 ns} 0} {{Slave hold} {38701799 ns} 0}
quietly wave cursor active 2
configure wave -namecolwidth 176
configure wave -valuecolwidth 134
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
WaveRestoreZoom {198486 ns} {16245300 ns}
