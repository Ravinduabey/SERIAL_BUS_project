# SERIAL_BUS_project
## modules
* arbiter.sv - top module of the arbiter
* controller.sv - module which control the bus 
* master_port.sv - module which connects with each master
* demux.sv - 1 to 2 demultiplexer
* mux.sv - 2 to 1 multiplexer
* thresh_counter.sv - module which lookout for delay in comm.

## work remaining
priority module - adds a cycle delay
write port
split complete algorithm - handle the loop issue
split complete coding 
request discard technique - master send give up message

