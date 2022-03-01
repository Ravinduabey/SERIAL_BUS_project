# SERIAL_BUS_project

Design and implementation of a serial bus with multiple masters and slaves, arbiter and
top-level design that can carry out a specific set of tasks, including data transfer, prioritybased and split arbiter transaction & top-level verification.

## Design Architecture
![Design Architecture](images/Design_Architecture.png)

 This repository include the design and the source files of custom serial bus protocol. This protocol uses a centralized bus arbiter to support both internal and external communication.

 ### Internal communication specifications
- No. of Masters (Internal) : 2
- No. of Slaves (Internal) : 3
- Memory size of slaves : 4k, 4k, 2k
- Data Transfer Types : Read, Write, Read Burst, Write Burst
- Arbitration : Centralized
- Bus Width - Address : 12 bits
- Bus Width - Data : 16 bits

### External communication specifications
 - Protocol : UART
 - Baud Rate : 19200
 - Received data display time : 5s
 - ACK wait time : 1ms
 - No. of re-transmissions : 5
 
 * Multiple masters
 * Slave modules
 * A centralized bus arbiter
 * Internal and external communication modes
 * while Internal mode supports four types of data transfer: 
    * read
    * burst read
    * write
    * burst write. 
 * External mode supports single byte data transfer through **external UART** communication protocol, with a dedicated master-slave pair for this purpose. 
 * Further, **priority-based** as well as **delay-based split transaction** is supported through this custom bus protocol. 
  
## Main modules

* top.sv - The top module allows user to control system, instantiates and connects all the other components. 
* arbiter.sv - Handles the selection of master that is given access to the bus
* master.sv - Instantiates and carries out communication via the bus
* slave.sv - Receives communication request and carries it out 

## testbenches
* arbiter_tb.sv  
* a_priority_selector_tb.sv
* a_write_buffer_tb.sv 

