### **Internal communication specifications**

- No. of Masters (Internal) : 2
- No. of Slaves (Internal) : 3
- Memory size of slaves : 4k, 4k, 2k
- Data Transfer Types : Read, Write, Read Burst, Write Burst
- Arbitration : Centralized
- Bus Width - Address : 12 bits
- Bus Width - Data : 16
- bits
  > Further, **priority-based** as well as **delay-based split transaction** is implemented in this protocol.

It is possible to increase the number of masters and slaves by changing the parameters in the [top.sv file](/src/top.sv)

```Verilog
parameter INT_MASTER_COUNT=2,  // number of masters
parameter INT_SLAVE_COUNT=3,  // number of slaves
parameter int SLAVE_DEPTHS[INT_SLAVE_COUNT] = '{4096,4096,2048}, // give each slave's depth
```

During internal communication to choose which master to start communication first and the delay between two masters change the following parametes in [top.sv file](/src/top.sv)

```Verilog
parameter FIRST_START_MASTER = 0, // this master will start communication first
parameter COM_START_DELAY = 0, //gap between 2 masters communication start signal
```

### **External communication specifications**

External mode supports single byte data transfer through an **external UART** communication , with a dedicated master-slave pair for this purpose.

### \* External communication specifications

UART

- Baud Rate : 19200
- Received data display time : 5s
- ACK wait time : 1ms
- No. of re-transmissions : 5

When external communication is initialized (by pressing key[3])

- Data will be displayed for 5 seconds in the current board
- Then this data will be sent to the next board via UART
- The data received will then be displayed which is incremented by 1 with respect to the previous displayed data.

> This will continue indefinitely untill a the external communication is interupted externally (by pressing key[3]).

To change the baud rate of the UART change the following parameter in the in [top.sv file](/src/top.sv).

```verilog
parameter UART_BAUD_RATE = 19200,
```

To set the duration at which the result of the external communication to be displayed change the following parameter.

```verilog
parameter EXT_DISPLAY_DURATION = 5, // external communication value display duration
```
