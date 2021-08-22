# SERIAL_BUS_project
## modules
* arbiter.sv - top module of the arbiter
* a_controller.sv - module which control the bus 
* a_master_port.sv - an intermediate module which connects each master to controller
* a_thresh_counter.sv - module which lookout for delay in comm.
* a_priority selector.sv - module which updates controller about master requests 
* a_write_buffer.sv - module which writes the master according to the protocol

## testbenches
* arbiter_tb.sv  
* a_priority_selector_tb.sv
* a_write_buffer_tb.sv 
