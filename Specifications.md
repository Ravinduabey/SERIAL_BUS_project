### **Internal communication specifications**
- No. of Masters (Internal) : 2
- No. of Slaves (Internal) : 3
- Memory size of slaves : 4k, 4k, 2k
- Data Transfer Types : Read, Write, Read Burst, Write Burst
- Arbitration : Centralized
- Bus Width - Address : 12 bits
- Bus Width - Data : 16 
- btis
 > Further, **priority-based** as well as **delay-based split transaction** is implemented in this protocol. 
 
 ### **External communication specifications**
 External mode supports single byte data transfer through an **external UART** communication , with a dedicated master-slave pair for this purpose. 

### * External communication specifications
UART
* Baud Rate : 19200
* Received data display time : 5s
* ACK wait time : 1ms
* No. of re-transmissions : 5 

When external communication is initialized (by pressing key[3])
 - Data will be displayed for 5 seconds in the current board
 - Then this data will be sent to the next board via UART
 - The data received will then be displayed which is incremented by 1 with respect to the previous displayed data.

> This will continue indefinitely untill a the external communication is interupted externally (by pressing key[3]). 
