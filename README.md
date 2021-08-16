# SERIAL_BUS_project
## modules
* arbiter.sv - top module of the arbiter
* controller.sv - module which control the bus 
* master_port.sv - an intermediate module which connects each master to controller
* thresh_counter.sv - module which lookout for delay in comm.
* priority selector.sv - module which updates controller about master requests 
* write_buffer.sv - module which writes the master according to the protocol

## testbenches
* arbiter_tb.sv  
* priority_selector_tb.sv
* write_buffer_tb.sv 
