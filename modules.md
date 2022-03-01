# Main Modules 

## top.sv
    The top module allows user to control the bus system, instantiates and connects all the other components. 
    This is the top level of the design hierarchy. All other modules are instantiated within this module. It is a state machine which changes its states according to user inputs and internal modules’ outputs. This module does following tasks.
    1. Act as a user interface to:
        * indicate current state of the overall process.
        * visualize user input requirement to setup master modules before communication process begin.
        * visualize user inserted inputs.
        * visualize the results after the communication process.
    2. Instantiate modules related to communication process
  
## arbiter.sv
    This is the top module of the arbiter which provides the access to the bus for all the masters with the use of a centralized controller. It is a fully parameterized module to instantiate any number of master ports with any number of slaves.
## master.sv 
    This is the top master module in which the master port is implemented. It is also a fully parameterized module which can be used to implement a master module with a memory of any depth and width. The top module has the full authority on managing on which state the master should function.
## slave.sv
    The slave module acts as the target of the communication initiated by the master. It has the capability to carry out read, write, read burst and write burst operations.
## masterExternal.sv 
    This is the module which is used to communicate with the slave module that communicates with the external boards. It is also a fully parameterized module. Its main functionalities are:
      * Initialize external communication when required
      * Display the data (numerical) received through external boards.
      * Increment the data received by 1 and send it to the slave that communicates with the external boards.
## uart_slave_system.sv
    The external communication slave consists of 
    * two sets of UART receiver (Rx) and transmitter (Tx) modules responsible for handling communication with external devices via UART protocol, 
    * a baud rate generator
    * the uart slave module that handles the state machine and communication between the UART modules and the internal master