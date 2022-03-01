
# Methodology
## Internal Comm
* First the user needs to provide the requirements to setup the communication variables. These inputs are taken using the 18 switches in the FPGA board in several consecutive
states. 
* The requirements and the given value by the user is visible on the LCD display. Push buttons are used to go to the next state in order to give the next
input. 
* The usage of the push buttons is as follows
  * PB[0] - Reset system to initial state
  * PB[1] - Go to next state
  * PB[2] - Go to next address (Used during externally write only)
  * PB[3] - Start external communication

* The user inputs can be taken in the appropriate states. The following table describes the states that the user see during internal communication testing.

![](images/table.png)

* If no slaves are selected for both masters in state 1, the rest of the states will not be activated. Instead, the system directly goes to the "done" state as described in table.
*  The user can use this to display the memory content of the masters before initializing the communication. If the user does not select any data transfer that externally changes master’s memory content in state 3, states 4 & 5 may not appear accordingly.

*  Following images shows the LCD display in each of the above described states. 

![](images/lcd.png)

---
## External Comm

* To connect a device for external communication, the ground pin should be connected to a common ground. 
* Next, the UART should be connected through General Purpose
Input Output (GPIO) pins. The GPIO pins are used as
follows.
  * Rx pins:
    * GPIO[0] - Receive data. (an 8 bit value)
    * GPIO[1] - Transmit acknowledgement for the received data. (Acknowledgement bit pattern)
  * Tx pins:
    * GPIO[2] - Receive acknowledgement for transmitted data. (Acknowledgement bit pattern)
    * GPIO[3] - Transmit data. (an 8 bit value)
  
* Connect the Rx data pin (GPIO[0]) and acknowledgement (GPIO[1]) to the Tx data pin and acknowledgement pin respectively of the external device, and vice versa.
* To initialize the external communication, first set the initial value (from 0 to 63) using SW[5:0] switches. 
* Press BP[3] button to start external communication. Then the initialized value will be displayed on the seven segment display for 5 seconds and after increment by one, the value will be sent to the next FPGA board.
* When a value from a external FPGA is received by this FPGA board, that value will be displayed on the seven segment for 5 seconds, then increment by one and sends to the other FPGA board via UART protocol.
