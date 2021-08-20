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
    localparam DEL          = DELAY * DATA_WIDTH;
    localparam DEL_COUNTER  = $clog2(DEL);


    // logic [S_ID_WIDTH-1:0] reg_slave_ID;

    logic [CON           :0] config_buffer;
    logic [CON_COUNTER-1 :0] config_counter;
    logic                    temp_control;

    logic [DATA_WIDTH-1   :0]  rD_buffer;             //data out buffer for READ  RAM -->|_|_|_|_|_..._|--> |_|
    logic [DATA_COUNTER   :0]  rD_counter;            
    logic                      rD_temp;
    logic [DATA_WIDTH-1   :0]  wD_buffer;             //data_in buffer for WRITE  |_| -->|_|_|_|_|_..._|--> RAM
    logic [DATA_COUNTER   :0]  wD_counter;
    logic                      wD_temp;

    // Declare the RAM variable
	logic [DATA_WIDTH-1:0] ram [ADDR_DEPTH-1:0];

	// Variable to hold the registered read address
	logic [ADDR_WIDTH-1:0] address;
	logic [ADDR_WIDTH-1:0] prev_read_address;

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

    // typedef enum logic { 
    //     start_  = CON:CON-2, 
    //     id_     = CON-3:CON-2-S_ID_WIDTH,
    //     rw_     = CON-2-S_ID_WIDTH-1,
    //     burst_  = CON-2-S_ID_WIDTH-2,
    //     address_= ADDR_WIDTH-1:0
    // } control_;

    
    // initial begin
    // if (MEM_INIT_FILE != "") $readmemh(MEM_INIT_FILE, ram);
    // end

   initial begin
       $readmemh("D:\\ads-bus\\SERIAL_BUS_project\\src\\slave-mem-1.txt",ram);
   end

    // initial begin
    //     $readmemh("slave-mem.txt",ram);
    // end

    
    always_ff @( posedge clk or negedge rstN ) begin : slaveStateMachine
        // state <= next_state;
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
                    address          <= 0;
                    prev_read_address<= 0;
                    config_counter   <= 0;
                    rD_counter       <= 0;
                    wD_counter       <= 0;
                    delay_counter    <= 0;
                    ready            <= 1;
                    rD_buffer        <= 0;
                    wD_buffer        <= 0;
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
                        state <= CONFIG;                   
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
                    //                  start                       slaveid
                    if (config_buffer[CON:CON-2]== START && config_buffer[CON-3:CON-2-S_ID_WIDTH]==SLAVEID ) begin
                        if (config_buffer[CON-2-S_ID_WIDTH-1]==0) begin     //read
                            if (address == prev_read_address) begin
                                rD_temp         <= rD_buffer[DATA_WIDTH-1];
                                state           <= READ; 
                            end  
                            else begin
                                if (delay_counter == DELAY) begin
                                    rD_buffer   <= ram[address];
                                    rD_temp     <= rD_buffer[DATA_WIDTH-1];
                                    state       <= READ;                                 
                                end
                                else delay_counter <= delay_counter + 1'b1;
                            end                                                
                        end
                        else if (config_buffer[CON-2-SLAVEID-1]==1) begin  //write
                            ready <= 1;
                            if (valid)  begin
                                state <= WRITE;
                            end
                            else  state <= CONFIG_NEXT;
                        end
                    end
                    else begin
                        state <= IDLE;
                    end
                end 
                READ : begin
                    // check <= 1'b1;
                    // rD_buffer       <= ram[address];
                    rD_buffer       <= rD_buffer << 1;
                    rD_temp         <= rD_buffer[DATA_WIDTH-1];
                    rD_counter      <= rD_counter + 1'b1;
                    if (rD_counter < DATA_WIDTH) begin
                        ready   <= 1;                                              
                        state   <= READ;
                    end 
                    else begin
                        rD_counter  <= 0;
                        ready       <= 0;
                        if (config_buffer[CON-2-S_ID_WIDTH-2]==0) begin
                            prev_read_address   <= address;
                            state               <= IDLE;
                        end
                        else begin
                        address     <= address + 1'b1;
                        state       <= READB_GET;
                        end
                    end
                end                
                READB_GET: begin
                    rD_buffer <= ram[address];
                    state   <= READB;
                end
                READB: begin
                    ready <= 1;
                    if (last == 0) begin
                        if (rD_counter < DATA_WIDTH) begin
                            rD_counter <= rD_counter + 1'b1;
                            rD_buffer  <= rD_buffer << 1;
                            rD_temp    <= rD_buffer[DATA_WIDTH-1];
                        end
                        else if (rD_counter == DATA_WIDTH) begin
                            ready      <= 0;
                            rD_counter <= 0;
                            address    <= address + 1'b1;
                            state      <= READB_GET;
                        end 
                    end
                    else begin
                        if (rD_counter < DATA_WIDTH) begin
                            rD_counter <= rD_counter + 1'b1;
                            rD_buffer  <= rD_buffer << 1;
                            rD_temp    <= rD_buffer[DATA_WIDTH-1];
                        end
                        else if (rD_counter == DATA_WIDTH) begin
                            state      <= IDLE;
                        end                         
                    end
                end
                WRITE: begin
                    if (wD_counter < DATA_WIDTH-1) begin
                        wD_counter  <= wD_counter + 1'b1;
                        wD_buffer   <= wD_buffer << 1;
                        wD_buffer[0] <= wD_temp;                    //msb first
                    end
                    else begin 
                        wD_counter <= 0;
                        ram[address] <= wD_buffer;
                        if (config_buffer[CON-2-S_ID_WIDTH-2]==0) state <= IDLE;
                        else begin
                            if (last==0 && valid==1) begin
                                wD_counter      <= 1;
                                wD_buffer       <= wD_buffer << 1;
                                wD_buffer[0]    <= wD_temp;
                                address         <= address + 1'b1;
                                state           <= WRITEB;
                            end
                            else if (last==0 && valid==0) begin
                                address         <= address +1'b1;
                                state           <= WRITEB;
                            end
                            else state <= IDLE;
                        end
                    end 
                end
                WRITEB: begin
                    if (last) begin
                        if (wD_counter < DATA_WIDTH-1 && valid) begin
                            wD_counter      <= wD_counter + 1'b1;
                            wD_buffer       <= wD_buffer << 1;
                            wD_buffer[0]    <= wD_temp;
                        end
                        else begin
                            // check <= 1;
                            state           <= WRITEB_END;
                            wD_buffer       <= wD_buffer << 1;
                            wD_buffer[0]    <= wD_temp; 
                            config_buffer   <= 0;                           
                        end
                    end
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
                    ram[address]    <= wD_buffer;
                    state           <= IDLE;
                end                
                default: state <= IDLE;
                    
            endcase

            // if (MEM_INIT_FILE != "") $writememh(MEM_INIT_FILE, ram);

            // $writememh("D:\\ads-bus\\SERIAL_BUS_project\\src\\slave-mem-1.txt",ram);
            // $writememh("slave-mem.txt",ram);

        end 
    end
assign temp_control = control;
assign wD_temp = wD;
assign rD = rD_temp;

endmodule