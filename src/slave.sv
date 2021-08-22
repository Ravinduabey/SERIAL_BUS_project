/*
Slave Module: 
*/
module slave #(
    parameter ADDR_DEPTH = 2000,
    parameter SLAVES = 3,
    parameter DATA_WIDTH = 32,
    parameter S_ID_WIDTH = $clog2(SLAVES+1),
    parameter SLAVEID = 1,
    parameter DELAY = 0
    // parameter MEM_INIT_FILE = ""
) (
    // with Master (through interconnect)
    output logic rD,                  //serial read_data
    output logic ready,               //default HIGH

    input logic control,              //serial control setup info  start|slaveid|R/W|B|start_address -- 111|SLAVEID|1|1|WIDTH
    input logic wD,                   //serial write_data
    input logic valid,                //default LOW
    input logic last,                 //default LOW

    //with Top Module
    // input logic [S_ID_WIDTH-1:0]slave_ID,
    input logic clk,
    input logic rstN   
);
    localparam ADDR_WIDTH   = $clog2(ADDR_DEPTH);
    localparam DATA_COUNTER = $clog2(DATA_WIDTH);
    localparam CON          = 3 + ADDR_WIDTH + 2 + S_ID_WIDTH-1;
    localparam CON_COUNTER  = $clog2(CON);
    localparam START        = 3'b111;
    localparam DEL          = DELAY;
    localparam DEL_COUNTER  = $clog2(DEL);


    // logic [S_ID_WIDTH-1:0] reg_slave_ID;

    logic [CON           :0] config_buffer;
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

    // Declare RAM 
	logic [DATA_WIDTH-1:0] ram [ADDR_DEPTH-1:0];

	// Variable to hold the registered read/write address
	logic [ADDR_WIDTH-1:0] address;

    //Variable to hold read address
    //when the read was not carried out
    //to allow next read to happen without delay
    //after split transaction
	logic [ADDR_WIDTH-1:0] failed_read_address;
    logic read_failed;

    logic [DEL_COUNTER-1 :0]  delay_counter;


    // logic check;

    typedef enum logic [3:0] { 
       INIT,
       IDLE,
       CONFIG,
       CONFIG_NEXT,
       READ,
       READB_GET,
       READB,
       WRITE,
       WRITEB,
       WRITEB_END 
    } state_;
	 
    state_ state = INIT;

    // typedef enum logic [CON_COUNTER-1:0] { 
    //     start_s = CON,
    //     start_f = CON-2,
    //     id_s    = CON-3, 
    //     id_f    = CON-2-S_ID_WIDTH,
    //     rw_     = CON-2-S_ID_WIDTH-1,
    //     burst_  = CON-2-S_ID_WIDTH-2,
    //     address_s= ADDR_WIDTH-1,
    //     address_f= 0
    // } control_;

    
    // initial begin
    // if (MEM_INIT_FILE != "") $readmemh(MEM_INIT_FILE, ram);
    // end

    initial begin
        $readmemh("C:\\Users\\ravin\Documents\\GitHub\\ads1\\src\\slave-mem-1.txt",ram);
    end

    
    always_ff @( posedge clk or negedge rstN ) begin : slaveStateMachine
        if (!rstN) begin
            config_buffer   <= 0;
            rD_counter      <= 0;
            wD_counter      <= 0;
            config_counter  <= 0;
            delay_counter   <= 0;
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
                    address             <= 0;
                    failed_read_address <= 0;
                    read_failed         <= 0;
                    config_counter      <= 0;
                    rD_counter          <= 0;
                    wD_counter          <= 0;
                    delay_counter       <= 0;
                    ready               <= 1;
                    rD_temp             <= 0;
                    rD_buffer           <= 0;
                    wD_buffer           <= 0;
                end
                IDLE : begin
                    ready           <= 1;
                    config_counter  <= 0;
                    rD_counter      <= 0;
                    wD_counter      <= 0;
                    delay_counter   <= 0;
                    if (control == 1'b1) begin
                        config_counter   <= config_counter + 1'b1; 
                        config_buffer    <= config_buffer << 1'b1;
                        config_buffer[0] <= temp_control;                        
                        state            <= CONFIG;                   
                    end
                end
                CONFIG : begin
                    if (config_counter < CON) begin
                        config_counter   <= config_counter + 1'b1;                                        
                        config_buffer    <= config_buffer << 1'b1;
                        config_buffer[0] <= temp_control;
                        state            <= CONFIG;
                    end
                    else if (config_counter == CON) begin
                        config_counter   <= config_counter + 1'b1;                                        
                        config_buffer    <= config_buffer << 1'b1;
                        config_buffer[0] <= temp_control;
                        state            <= CONFIG;
                        ready            <= 0;                        
                    end
                    else begin
                        config_counter  <= 0;
                        address         <= config_buffer[ADDR_WIDTH-1:0];
                        state           <= CONFIG_NEXT;
                    end
                end
                CONFIG_NEXT : begin
                    //if start and slave id sent by master is correct: 
                    //process the rest of the control signal
                    if (config_buffer[CON:CON-2]==START && config_buffer[CON-3:CON-2-S_ID_WIDTH]==SLAVEID ) begin
                        //if READ
                        if (config_buffer[CON-2-S_ID_WIDTH-1] == 0) begin 
                            //if the READ is being sent after a previously failed read
                            //and slave already has the data buffered and waiting: send data directly   
                            if (address == failed_read_address && read_failed) begin
                                read_failed     <= 0;
                                rD_temp         <= rD_buffer[DATA_WIDTH-1];
                                state           <= READ; 
                            end
                            //if new READ  
                            else begin
                                //once expected delay is done
                                //access ram and start sending the first bit 
                                //while assigning READ state in same clock cycle 
                                if (delay_counter == DELAY) begin
                                    read_failed <= 0;
                                    rD_buffer   <= ram[address];
                                    rD_temp     <= rD_buffer[DATA_WIDTH-1];
                                    state       <= READ;                                 
                                end
                                else delay_counter <= delay_counter + 1'b1;
                            end                                                
                        end
                        //if WRITE: ready is always HIGH until end of write
                        else if (config_buffer[CON-2-S_ID_WIDTH-1] == 1) begin  
                            ready <= 1;
                            //only begin write if master sends valid HIGH
                            //start receiving first write data bit 
                            //with valid HIGH in same clock cycle
                            if (valid)  begin
                                wD_buffer       <= wD_buffer << 1;
                                wD_buffer[0]    <= wD_temp;                    
                                state <= WRITE;
                            end
                            //if valid is LOW: wait
                            else  state <= CONFIG_NEXT;
                        end
                    end
                    //if start and slave id is wrong: go to IDLE
                    else begin
                        state <= IDLE;
                    end
                end 
                READ : begin
                    rD_buffer       <= rD_buffer << 1;
                    rD_temp         <= rD_buffer[DATA_WIDTH-1];
                    rD_counter      <= rD_counter + 1'b1;
                    if (rD_counter < DATA_WIDTH) begin
                        ready   <= 1;                                              
                        state   <= READ;
                    end
                    //after first read data is fully sent : 
                    else begin
                        rD_counter      <= 0;
                        delay_counter   <= 0;
                        ready           <= 0;
                        //if master did not send a READ BURST
                        if (config_buffer[CON-2-S_ID_WIDTH-2]==0) begin
                            //make sure that the read data was read, and continue to IDLE
                            if (valid) begin
                                read_failed <= 0;
                                state  <= IDLE;
                            end
                            //if read failed: prepare for the same read
                            //by accessing ram, then wait in IDLE 
                            //assign failed_read_address to check if next read
                            //is the same failed read                                                        
                            else begin
                                if (delay_counter == DELAY) begin
                                    rD_buffer           <= ram[address];
                                    read_failed         <= 1;
                                    failed_read_address <= address;
                                    state               <= IDLE;
                                end
                                else delay_counter <= delay_counter + 1'b1;                                
                            end
                        end
                        else begin
                            //make sure that the read data was read, and continue to READ BURST
                            if (valid) begin
                                read_failed     <= 0;
                                address         <= address + 1'b1;
                                state           <= READB_GET;
                            end
                            //if read failed: prepare for the same read
                            //by accessing ram, then wait in IDLE
                            //assign failed_read_address to check next read                             
                            else begin
                                if (delay_counter == DELAY) begin
                                    rD_buffer           <= ram[address];
                                    read_failed         <= 1;
                                    failed_read_address <= address;
                                    state               <= IDLE;
                                end
                                else delay_counter <= delay_counter + 1'b1;
                            end
                        end
                    end
                end                
                READB_GET: begin
                    //next ram access
                    //if (delay_counter == DELAY) begin
                    //    rD_buffer       <= ram[address];
                    //    state           <= READB;
                    //end
                    //else delay_counter <= delay_counter + 1'b1;
                    rD_buffer   <= ram[address];
                    state       <= READB;
                end
                READB: begin
                    ready <= 1;
                    //if last is HIGH: send one byte and stop
                    if (last) begin
                        if (rD_counter < DATA_WIDTH) begin
                            rD_counter <= rD_counter + 1'b1;
                            rD_buffer  <= rD_buffer << 1;
                            rD_temp    <= rD_buffer[DATA_WIDTH-1];
                        end
                        else if (rD_counter == DATA_WIDTH) begin
                            state               <= IDLE;
                        end                         
                    end
                    //if last is LOW: send one byte and increment address
                    //then go to READB_GET state to get next read data
                    else begin
                        if (rD_counter < DATA_WIDTH) begin
                            rD_counter  <= rD_counter + 1'b1;
                            rD_buffer   <= rD_buffer << 1;
                            rD_temp     <= rD_buffer[DATA_WIDTH-1];
                        end
                        //after rD_buffer is completely sent
                        else if (rD_counter == DATA_WIDTH) begin
                            ready           <= 0;
                            rD_counter      <= 0;
                            delay_counter   <= 0;
                            address         <= address + 1'b1;
                            state           <= READB_GET;
                        end 
                    end
                end
                WRITE: begin
                    if (wD_counter < DATA_WIDTH-1) begin
                        wD_counter      <= wD_counter + 1'b1;
                        wD_buffer       <= wD_buffer << 1;
                        wD_buffer[0]    <= wD_temp;                    //msb first
                    end
                    else begin 
                        wD_counter      <= 0;
                        ram[address]    <= wD_buffer;
                        //if master did not send a WRITE BURST
                        if (config_buffer[CON-2-S_ID_WIDTH-2]==0) state <= IDLE;
                        else begin
                            //for WRITE BURST, wait for valid HIGH
                            //before reading wD input
                            if (valid) begin
                                wD_counter      <= 1;
                                wD_buffer       <= wD_buffer << 1;
                                wD_buffer[0]    <= wD_temp;
                                address         <= address + 1'b1;
                                state           <= WRITEB;
                            end
                            else begin
                                address         <= address +1'b1;
                                state           <= WRITEB;
                            end
                        end
                    end 
                end
                WRITEB: begin
                    //if last is HIGH : receive one more byte
                    //then go to WRITEB_END state and store byte
                    if (last) begin
                        if (wD_counter < DATA_WIDTH-1 && valid) begin
                            wD_counter      <= wD_counter + 1'b1;
                            wD_buffer       <= wD_buffer << 1;
                            wD_buffer[0]    <= wD_temp;
                        end
                        else begin
                            state           <= WRITEB_END;
                            wD_buffer       <= wD_buffer << 1;
                            wD_buffer[0]    <= wD_temp; 
                            config_buffer   <= 0;                           
                        end
                    end
                    //if last is LOW: receive one byte and increment address
                    else begin
                        if (wD_counter < DATA_WIDTH && valid==1) begin
                            wD_counter      <= wD_counter + 1'b1;
                            wD_buffer       <= wD_buffer << 1;
                            wD_buffer[0]    <= wD_temp;
                        end
                        else if (wD_counter == DATA_WIDTH) begin
                            ram[address]    <= wD_buffer;
                            address         <= address + 1'b1;                            
                            wD_counter      <= 0;
                        end
                    end
                end
                WRITEB_END : begin
                    //store last byte 
                    ram[address]    <= wD_buffer;
                    state           <= IDLE;
                end                
                default: state <= IDLE;
                    
            endcase

            // if (MEM_INIT_FILE != "") $writememh(MEM_INIT_FILE, ram);

//            $writememh("D:\\ACA\\SEM7_TRONIC_ACA\\17 - Advance Digital Systems\\2020\\assignment_1\\SERIAL_BUS_project\\src\\slave-mem-1.txt",ram);
          $writememh("C:\\Users\\ravin\Documents\\GitHub\\ads1\\src\\slave-mem.txt",ram);

        end 
    end
assign temp_control = control;
assign wD_temp = wD;
assign rD = rD_temp;

endmodule