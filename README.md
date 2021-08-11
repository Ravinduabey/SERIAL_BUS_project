# SERIAL_BUS_project
## modules
* arbiter.sv - top module of the arbiter
* controller.sv - module which control the bus 
* master_port.sv - module which connects with each master
* demux.sv - 1 to 2 demultiplexer
* mux.sv - 2 to 1 multiplexer
* thresh_counter.sv - module which lookout for delay in comm.

## work remaining
write port
master port generator - done
parameterized demux
split complete algorithm - handle the loop issue
split complete coding 
priority selection - ask samare
request discard technique - master send give up message

