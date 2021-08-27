module uart_slave
#(
    parameter SLAVES = 3,
    parameter DATA_WIDTH = 32,
    parameter S_ID_WIDTH = $clog2(SLAVES+1), //3
    parameter SLAVEID = 1
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

    //with uart receiver
    input   logic rxStart,
    input   logic rxDone,
    input   logic [DATA_WIDTH-1:0] byteFromRx,
    input   logic rxReady,


    //with uart transmitter
    output  logic txStart,
    output  logic [DATA_WIDTH-1:0] byteForTx,
    input   logic txReady
  
);
    /*                         |----------------------------------------------      
    |===================|      |  |=================|        |===============|
    |   Int. Master   []| ---> |O |   uart slave    |  --->  |   uart tx     |
    |===================|      |  |=================|        |===============|
                               |----------------------------------------------

                               |----------------------------------------------
    |===================|      |  |=================|        |===============|
    |   Int. Master   []| <--- |O |   uart slave    |  <---  |   uart rx     |
    |===================|      |  |=================|        |===============|
                               |---------------------------------------------- 
    
    if rx     sends data : send to master
    -- input from rx
    -- slave in READ mode : ready LOW
    -- send ack
    -1- if rxStart : read byteFromRx
    -2--- for DATA_WIDTH clock cycles : ready and send rD

    if master sends data : send to tx
    -- slave in WRITE mode
    -- output to rx
    -- receive ack 
    -1- if valid : write for DATA_WIDTH clock cycles
    -2--- if wD_buffer full : assign byteForTx and send txStart

    */

    localparam DATA_COUNTER = $clog2(DATA_WIDTH);

    //control signal length: start|slaveid|R/W -- 111|SLAVEID|1
    localparam CON          = 3 + S_ID_WIDTH + 1;  
    localparam CON_COUNTER  = $clog2(CON+1);

    logic [CON-1         :0] config_buffer;
    logic [CON_COUNTER-1 :0] config_counter;
    logic                    temp_control;

    //data out fifo buffer for READ  RAM -->|_|_|_|_|_..._|--> |rD_temp|
    //rD reads as readData
    logic [DATA_WIDTH-1   :0]  rD_buffer;             
    logic [DATA_COUNTER   :0]  rD_counter;            
    logic                      rD_temp;

    //data_in fifo buffer for WRITE  |wD_temp| -->|_|_|_|_|_..._|--> RAM 
    //wD reads as writeData              
    logic [DATA_WIDTH-1   :0]  wD_buffer;             
    logic [DATA_COUNTER   :0]  wD_counter;
    logic                      wD_temp;
    
    logic check=0;

    typedef enum logic [2:0] {
        ABORT       = 3'b100,
        CONTINUE    = 3'b101,
        HOLD        = 3'b110,
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
    
  
    typedef enum logic [3:0] { 
       INIT,        //initialize
       IDLE,        //wait for control signal

       //control
       RECONFIG,    
       CONFIG_NEXT, 

       //data from rx --> internal master
       READ,        
    //    READB_GET,   

       //data from internal master --> tx      
       WRITE
    //    WRITEB_END 
    } state_;
	 
    state_ state = INIT;
    state_ prev_state;

    genvar i;
    generate 
        for (i = 0; i<DATA_WIDTH; i++) begin : uart_data
            assign byteForTx    [i] = wD_buffer[i];
        end
    endgenerate

    always_ff @( posedge clk or negedge rstN ) begin : slaveStateMachine
        if (!rstN) begin
            txStart         <= 0;
            config_buffer   <= 0;
            rD_counter      <= 0;
            wD_counter      <= 0;
            config_counter  <= 0;
            rD_buffer       <= 0;
            wD_buffer       <= 0;
            rD_temp         <= 0;
            ready           <= 1;
            state           <= IDLE;
        end
        else begin
            case (state)
                INIT : begin
                    //initialize all counters, buffers, registers, outputs
                    txStart             <= 0;
                    config_counter      <= 0;
                    rD_counter          <= 0;
                    wD_counter          <= 0;
                    ready               <= 1;
                    rD_temp             <= 0;
                    rD_buffer           <= 0;
                    wD_buffer           <= 0;
                    config_buffer       <= 0;
                    state               <= IDLE;
                end
                IDLE : begin
                    com_status      <= comm;
                    txStart         <= 0;
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
                            config_counter   <= config_counter + 1'b1; 
                            config_buffer    <= config_buffer << 1'b1;
                            config_buffer[0] <= temp_control; 

                            state       <= RECONFIG; 
                        end
                        //or wait for master reconnect
                        else if  (config_buffer[2:0] == HOLD) begin
                            com_status  <= hold;
                            state       <= RECONFIG;
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
                    else if (config_counter < CON ) begin
                        config_counter   <= config_counter + 1'b1; 
                        config_buffer    <= config_buffer << 1'b1;
                        config_buffer[0] <= temp_control;
						end
                    //if start and slave id sent by master is correct: 
                    //process the rest of the control signal
                    else if (config_counter == CON) begin
                        if  (config_buffer[S_ID_WIDTH+1:2] == SLAVEID) begin
                            ready <= 0;
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
                    else if (config_buffer[1] == 0) begin
                        //receive data from uart rx
                        // check <= 1;
                        if (rxDone) begin
                            rD_buffer <= byteFromRx;
                            state     <= READ;
                        end
                    end
                    else if (config_buffer[1] == 1) begin
                        //send data to uart tx
                        // check <= 1;
                        ready <= 1;
                        if (valid)  begin
                            wD_buffer       <= wD_buffer << 1;
                            wD_buffer[0]    <= wD_temp;                    
                            state           <= WRITE;
                        end
                    end 
                end
                READ : begin
                    //reconfigure if master sends control HIGH
                    if (control) begin
                        config_counter      <= 1; 
                        config_buffer       <= config_buffer << 1'b1;
                        config_buffer[0]    <= temp_control;
                        prev_state          <= READ;
                        state               <= RECONFIG;
                    end
                    else begin
                        if (rD_counter < DATA_WIDTH && !ready) begin
                            rD_buffer       <= rD_buffer << 1;
                            rD_temp         <= rD_buffer[DATA_WIDTH-1];
                            ready           <= 1;
                        end
                        else if (rD_counter < DATA_WIDTH && ready) begin
                            rD_buffer       <= rD_buffer << 1;
                            rD_temp         <= rD_buffer[DATA_WIDTH-1];
                            rD_counter      <= rD_counter + 1'b1;                       
                            ready           <= 1;
                        end
                        //after first read data is fully sent : 
                        else if (rD_counter == DATA_WIDTH && ready) begin
                            rD_counter      <= 0;
                            ready           <= 0;
                            if (valid) begin
                                state  <= IDLE;
                            end
                        end
                    end
                end                
                // READB_GET: begin
                //     //reconfigure if master sends control HIGH
                //     if (control) begin
                //         config_counter      <= 1; 
                //         config_buffer       <= config_buffer << 1'b1;
                //         config_buffer[0]    <= temp_control;
                //         prev_state          <= READB_GET;
                //         state               <= RECONFIG;
                //     end
                //     else if (rxDone) begin                    
                //         rD_buffer   <= byteFromRx;
                //         state       <= READB;
                //     end
                // end
                WRITE: begin
                    //reconfigure if master sends control HIGH
                    if (control) begin
                        config_counter      <= 1; 
                        config_buffer       <= config_buffer << 1'b1;
                        config_buffer[0]    <= temp_control;
                        prev_state          <= WRITE;
                        state               <= RECONFIG;
                    end
                    else begin
                        if (wD_counter < DATA_WIDTH-1) begin
                            wD_counter      <= wD_counter + 1'b1;
                            wD_buffer       <= wD_buffer << 1;
                            wD_buffer[0]    <= wD_temp;                    //msb first
                        end
                        else begin
                            check <= 1; 
                            if (txReady) begin
                                wD_counter <= 0;
                                check <= 1;
                                txStart         <= 1;
                            end
                        end 
                    end
                end
                // WRITEB_END : begin
                //     //store last byte 
                //     // byteForTx   <= wD_buffer;
                //     state       <= IDLE;
                // end
                // default: state <= IDLE;
                    
            endcase

        end 
    end


assign temp_control = control;
assign wD_temp = wD;
assign rD = rD_temp;
endmodule