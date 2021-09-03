module uart_slave
#(
    parameter SLAVES = 3,
    parameter DATA_WIDTH = 32,
    parameter S_ID_WIDTH = $clog2(SLAVES+1), //3
    parameter SLAVEID = 1,
    parameter ACK_TIMEOUT = 1000000,
    parameter RETRANSMIT_TIMES = 5,
    parameter DATA_COUNTER = $clog2(DATA_WIDTH)
)(

    // with Master (through interconnect)
    output logic rD,                  //serial read_data
    output logic ready,               //default HIGH

    input logic control,              //serial control setup info  
    input logic wD,                   //serial write_data
    input logic valid,                //default LOW

    //with Top Module
    input logic clk,
    input logic rstN,

    //debug
    output logic [DATA_WIDTH-1   :0]  rD_buffer_out,          
    // output logic [DATA_COUNTER*2 :0]  rD_counter_out,            
    output logic [DATA_WIDTH-1   :0]  wD_buffer_out,             
    output logic [DATA_COUNTER   :0]  wD_counter_out,
    output logic [6              :0] config_buffer_out,
    output logic [3:0] state_out,
     

    //==================uart to get data==============//
    //with uart transmitter_get
    output logic g_txStart,
    output logic [DATA_WIDTH-1:0] g_byteForTx,
    input  logic g_txReady,  

    //with uart receiver_get
    input   logic g_rxStart,
    input   logic g_rxDone,
    input   logic [DATA_WIDTH-1:0] g_byteFromRx,
    input   logic g_rxReady,

    //=================uart to send data=============//
    //with uart receiver_send
    input logic s_rxStart,
    input logic s_rxDone,
    input logic [DATA_WIDTH-1:0] s_byteFromRx,
    input logic s_rxReady,

    //with uart transmitter_send
    output  logic s_txStart,
    output  logic [DATA_WIDTH-1:0] s_byteForTx,
    input   logic s_txReady
  
);
   /* 
   |=========|-1-write-->    |=========|                |==========|
   | master  |-2-write data->| slave   |                | next_fpga|
   |         |               |     s_tx|-3-write data-> |          |
   |         |               |     s_rx|<--4-ACK------- |          |
   |=========|               |=========|                |==========|

   next read

   |=========| --1-read---> |=========|                 |==========|
   |         |              |     g_rx| <-2-read data-  |          |
   | master  |<-4-ACK/NAK-- |     g_tx| ---3-ACK----->  |prev_fpga |
   |         | of prev write|  slave  |                 |          |
   |         |              |         |                 |          |
   |=========|<-5-read-data-|=========|                 |==========|

    if rx_get  sends data : send to master
    -- input from rx
    -- slave in READ mode : ready LOW
    -- send ack
    -1- if g_rxStart : read g_byteFromRx
    -2--- send ACK
    -3--- for DATA_WIDTH clock cycles : ready and send rD

    if master sends data : send to tx_send
    -- slave in WRITE mode
    -- output to rx
    -- receive ack 
    -1- if valid : write for DATA_WIDTH clock cycles
    -2--- if wD_buffer full : assign s_byteForTx and send s_txStart
    -3--- wait for ACK

    */

    // localparam DATA_COUNTER = $clog2(DATA_WIDTH);

    //control signal length: start|slaveid|R/W -- 111|SLAVEID|1
    localparam CON          = 3 + S_ID_WIDTH + 1;  
    localparam CON_COUNTER  = $clog2(CON+1);

    logic [CON-1         :0] config_buffer;
    logic [CON_COUNTER-1 :0] config_counter;
    logic                    temp_control;

    //data out fifo buffer for READ  RAM -->|_|_|_|_|_..._|--> |rD_temp|
    //rD reads as readData
    logic [DATA_WIDTH-1   :0]  rD_buffer;             
    logic [DATA_COUNTER*2 :0]  rD_counter;            
    logic                      rD_temp;

    //data_in fifo buffer for WRITE  |wD_temp| -->|_|_|_|_|_..._|--> RAM 
    //wD reads as writeData              
    logic [DATA_WIDTH-1   :0]  wD_buffer;             
    logic [DATA_COUNTER   :0]  wD_counter;
    logic                      wD_temp;
    
    //master ack/nak buffer
    logic [3:0] masterAck_buffer;
    logic check=0;
    logic reconfigured=0;
    //ack for uart
    logic [DATA_WIDTH-1              :0] sAck_buffer;
    logic [$clog2(ACK_TIMEOUT)-1     :0] ack_counter;
    logic [$clog2(RETRANSMIT_TIMES)-1:0] reTx_counter;
    logic [DATA_WIDTH-1              :0] reTx_data;
    
    typedef enum logic [2:0] {
        ABORT       = 3'b110,
        CONTINUE    = 3'b101,
        HOLD        = 3'b100,
        START       = 3'b111
    } control_;
    
    //when com_status is comm: data or control transmission can happen
    //when com_status is hold: no change in any internal reg
    //                         no rx or tx 
    //                         wait for continue control signal
    typedef enum logic { 
        comm,
        hold
    } com_;
    com_ com_status = comm;

    typedef enum logic [7:0] {
        ACK = 8'b11001100,
        NAK = 8'b10101010
    }ack_param;
    
  
    typedef enum logic [3:0] { 
       INIT,        //initialize
       IDLE,        //wait for control signal

       //control
       RECONFIG,    
       CONFIG_NEXT, 

       //data from rx --> internal master
       READ,
       SEND_ACK,

       //data from internal master --> tx      
       WRITE,
       GET_ACK,
       CHECK_ACK
    } state_;
	 
    state_ state = INIT;
    state_ prev_state;

    // genvar i;
    // generate 
    //     for (i = 0; i<DATA_WIDTH; i++) begin : uart_data
    //         assign s_byteForTx    [i] = wD_buffer[i];
    //     end
    // endgenerate

    always_ff @( posedge clk or negedge rstN ) begin : slaveStateMachine
        if (!rstN) begin
            s_txStart       <= 0;
            g_txStart       <= 0;
            g_byteForTx     <= 0;
            s_byteForTx     <= 0;
            ack_counter     <= 0;
            reTx_counter    <= 0;
            config_buffer   <= 0;
            masterAck_buffer<= 0;
            rD_counter      <= 0;
            wD_counter      <= 0;
            config_counter  <= 0;
            rD_buffer       <= 0;
            wD_buffer       <= 0;
            rD_temp         <= 0;
            ready           <= 1;
            state           <= INIT;
        end
        else begin
            case (state)
                INIT : begin
                    //initialize all counters, buffers, registers, outputs
                    s_txStart           <= 0;
                    g_txStart           <= 0;
                    ack_counter         <= 0;
                    reTx_counter        <= 0;
                    config_counter      <= 0;
                    rD_counter          <= 0;
                    wD_counter          <= 0;
                    ready               <= 1;
                    rD_temp             <= 0;
                    masterAck_buffer    <= 0;
                    rD_buffer           <= 0;
                    wD_buffer           <= 0;
                    config_buffer       <= 0;
                    state               <= IDLE;
                end
                IDLE : begin
                    //set counters and txStart outputs to 0
                    reconfigured    <= 0;
                    com_status      <= comm;
                    s_txStart       <= 0;
                    g_txStart       <= 0;
                    ack_counter     <= 0;
                    reTx_counter    <= 0;                    
                    ready           <= 1;
                    config_counter  <= 0;
                    rD_counter      <= 0;
                    wD_counter      <= 0;
                    //start to receive new configuration
                    if (control == 1'b1) begin
                        config_counter   <= config_counter + 1'b1; 
                        config_buffer[0] <= temp_control;                        
                        state            <= RECONFIG;                   
                    end
                end
                RECONFIG : begin
                    //if reconfiguration during configuration
                    //receive the next three bits to decide next step
                    if (config_counter < 3) begin
                        config_counter   <= config_counter + 1'b1; 
                        config_buffer    <= config_buffer << 1'b1;
                        config_buffer[0] <= temp_control;                                                
                    end 
                    else if (config_counter == 3) begin
                        //if communication is starting
                        if (config_buffer[2:0] == START) begin
                            com_status       <= comm;
                            config_counter   <= config_counter + 1'b1; 
                            config_buffer    <= config_buffer << 1'b1;
                            config_buffer[0] <= temp_control; 
                            state       <= RECONFIG; 
                        end
                        //or wait for master reconnect
                        //continue action until communication
                        //with master is required : then wait
                        else if  (config_buffer[2:0] == HOLD) begin
                            com_status  <= hold;
                            state       <= prev_state;
                        end 
                        //or continue current configuration   
                        else if (config_buffer[2:0] == CONTINUE) begin
                            com_status  <= comm;
                            state       <= prev_state;
                        end
                        //or abort current configuration 
                        else if (config_buffer[2:0] == ABORT) begin
                            state       <= IDLE;
                        end
                    end
                    else if (config_counter < CON-1 ) begin
                        config_counter   <= config_counter + 1'b1; 
                        config_buffer    <= config_buffer << 1'b1;
                        config_buffer[0] <= temp_control;
					end
                    else if (config_counter == CON-1) begin
                        config_counter   <= config_counter + 1'b1; 
                        config_buffer    <= config_buffer << 1'b1;
                        config_buffer[0] <= temp_control;

                        ready <= 0;
                    end
                    //if start and slave id sent by master is correct: 
                    //process the rest of the control signal
                    else if (config_counter == CON) begin
                        if  (config_buffer[S_ID_WIDTH:1] == SLAVEID) begin
                            state <= CONFIG_NEXT;
                        end
                        else state <= IDLE;
                    end                                              
                end                
                CONFIG_NEXT : begin
                    //reconfigure if master sends control HIGH
                    if (control) begin
                        config_counter      <= 1; 
                        config_buffer       <= config_buffer << 1'b1;
                        config_buffer[0]    <= temp_control;                                                
                        prev_state          <= CONFIG_NEXT;
                        state               <= RECONFIG;
                    end
                    //READ 
                    if ((prev_state == GET_ACK || prev_state == CHECK_ACK) && !reconfigured) begin
                        state <= prev_state;
                        com_status <= comm;
                    end
                    else if (config_buffer[0] == 0) begin
                    //==========receive data from uart rx===========//
                        if (g_rxDone) begin
                            rD_buffer   <= g_byteFromRx;
                            g_byteForTx <= ACK;
                            state       <= SEND_ACK;
                        end
                    end
                    //WRITE 
                    //========start receiving data from master======//
                    else if (config_buffer[0] == 1) begin
                        //send data to uart tx
                        ready <= 1;
                        if (valid && com_status==comm)  begin
                            wD_buffer       <= wD_buffer << 1;
                            wD_buffer[0]    <= wD_temp;                    
                            state           <= WRITE;
                        end
                    end 
                end
                //==============Comm with get_uart===================//
                //send acknowledgement to previous board
                SEND_ACK : begin
                    //reconfigure if master sends control HIGH
                    if (control) begin
                        config_counter      <= 1; 
                        config_buffer       <= config_buffer << 1'b1;
                        config_buffer[0]    <= temp_control;
                        prev_state          <= SEND_ACK;
                        state               <= RECONFIG;
                    end
                    else begin
                        if (g_txReady) begin
                            g_txStart           <= 1;
                            state               <= READ;
                        end
                    end
                end                 
                READ : begin
                    g_txStart <= 0;
                    //reconfigure if master sends control HIGH
                    if (control) begin
                        config_counter      <= 1; 
                        config_buffer       <= config_buffer << 1'b1;
                        config_buffer[0]    <= temp_control;
                        prev_state          <= READ;
                        state               <= RECONFIG;
                    end
                    else if (com_status == comm) begin
                        //send ACK or NAK to master
                        //from previous external write
                        if (rD_counter < 3 && !ready) begin
                            masterAck_buffer<= masterAck_buffer << 1;
                            rD_temp         <= masterAck_buffer[3];
                            ready           <= 1;
                        end
                        else if (rD_counter < 3 && ready) begin
                            masterAck_buffer<= masterAck_buffer << 1;
                            rD_temp         <= masterAck_buffer[3];
                            rD_counter      <= rD_counter + 1'b1;                       
                        end
                        //after ack is fully sent : 
                        //send the read data from external read
                        else if (rD_counter < DATA_WIDTH+3 && ready) begin
                            rD_buffer       <= rD_buffer << 1;
                            rD_temp         <= rD_buffer[DATA_WIDTH-1];
                            rD_counter      <= rD_counter + 1'b1;  
                        end                     
                        else if (rD_counter == DATA_WIDTH+3 && ready) begin
                            rD_counter      <= 0;
                            ready           <= 0;
                            if (valid) begin
                                state        <= IDLE;
                            end
                        end
                    end
                end 
                //==============Comm with send_uart==================//
                WRITE: begin
                    //reconfigure if master sends control HIGH
                    if (control) begin
                        config_counter      <= 1; 
                        config_buffer       <= config_buffer << 1'b1;
                        config_buffer[0]    <= temp_control;
                        prev_state          <= WRITE;
                        state               <= RECONFIG;
                    end
                    else if (com_status == comm) begin
                        if (wD_counter < DATA_WIDTH-2 && valid) begin
                            wD_counter      <= wD_counter + 1'b1;
                            wD_buffer       <= wD_buffer << 1;
                            wD_buffer[0]    <= wD_temp;                    //msb first
                        end
                        else if (wD_counter == DATA_WIDTH-2) begin
                                wD_counter      <= wD_counter + 1'b1;
                                s_byteForTx     <= wD_buffer;
                                ready           <= 0;
                        
                        end
                        else if (wD_counter == DATA_WIDTH-1) begin
                            if (s_txReady) begin
                                s_txStart       <= 1;
                                state           <= GET_ACK;
                            end
                        end  
                    end
                    else begin
                        if (wD_counter == DATA_WIDTH-1) begin
                            if (s_txReady) begin
                                // check <= 1;
                                s_txStart       <= 1;
                                state           <= GET_ACK;
                            end
                        end 
                    end
                end
                GET_ACK : begin
                    ready <= 0;
                    wD_counter <= 0;
                    //reconfigure if master sends control HIGH
                    if (control) begin
                        config_counter      <= 1; 
                        config_buffer       <= config_buffer << 1'b1;
                        config_buffer[0]    <= temp_control;
                        prev_state          <= GET_ACK;
                        state               <= RECONFIG;
                    end
                    //if ACK is received
                    //from send_Receiver
                    else if (s_rxDone) begin
                                    sAck_buffer     <= s_byteFromRx;
                                    state           <= CHECK_ACK;
                    end
                    //wait for ACK 
                    //retransmit after timeout 
                    else begin
                        if (reTx_counter < RETRANSMIT_TIMES) begin
                            if (ack_counter < ACK_TIMEOUT) begin
                                s_txStart           <= 0;
                                ack_counter         <= ack_counter + 1'b1;
                            end
                            else if (ack_counter == ACK_TIMEOUT) begin
                                //retransmit
                                if (s_txReady) begin 
                                    ack_counter     <= 0;
                                    s_txStart       <= 1;
                                    reTx_counter    <= reTx_counter + 1'b1;
                                end
                            end
                        end
                        else state     <= CHECK_ACK;
                    end                    
                end
                CHECK_ACK : begin
                    ready <= 0;
                    if (control) begin
                        config_counter      <= 1; 
                        config_buffer       <= config_buffer << 1'b1;
                        config_buffer[0]    <= temp_control;
                        prev_state          <= CHECK_ACK;
                        state               <= RECONFIG;
                    end  
                    //if send_rx has sent an acknowledgement 
                    //send 4-bit ACK to master 
                    //during next READ                 
                    if (sAck_buffer == ACK) begin
                        masterAck_buffer    <= ACK[7:4];
                    end
                    //if communication failed
                    //no ack/nak will be sent --> default nak
                    else begin
                        masterAck_buffer    <= NAK[7:4];
                    end
                    if (config_counter != 0) begin
                        reconfigured    <= 1;
                        state           <= CONFIG_NEXT;
                    end
                    else state          <= IDLE;
                end
            endcase

        end 
    end


assign temp_control = control;
assign wD_temp = wD;
assign rD = rD_temp;
assign rD_buffer_out = rD_buffer;
// assign rD_counter_out = rD_counter;
assign wD_buffer_out = wD_buffer;
assign wD_counter_out = wD_counter;
assign config_buffer_out = config_buffer;
assign state_out = state;
endmodule