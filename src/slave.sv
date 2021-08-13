/*
Slave Module: 
*/
module slave #(
    parameter ADDR_DEPTH = 2000,
    parameter SLAVES = 3,
    parameter DATA_WIDTH = 32,
    parameter SLAVEID = $clog2(SLAVES)
) (
    // with Master (through interconnect)
    output logic rD,                  //serial read_data
    output logic ready,               //default HIGh

    input logic control,              //serial control setup info  start|slaveid|R/W|B|start_address -- 111|SLAVEID|1|1|WIDTH
    input logic wD,                   //serial write_data
    input logic valid,                //default LOW
    input logic last,                 //default LOW

    //with Top Module
    input logic [SLAVEID-1:0]slave_ID,
    input logic clk,
    input logic resetn   
);
    localparam ADDR_WIDTH   = $clog2(ADDR_DEPTH);
    localparam DATA_COUNTER = $clog2(DATA_WIDTH);
    localparam CON = 5+ADDR_WIDTH+SLAVEID-1;

    //logic [$clog2(ADDR_WIDTH)+]control_size = 5;


    logic [SLAVEID-1:0] reg_slave_ID;

    logic [2:0] state;
    logic [2:0] next_state;

    logic [CON           :0] config_buffer;
    logic [$clog2(CON)-1 :0] config_counter;
    logic                    temp_control;

    logic [ADDR_WIDTH-1   :0]  address;
    logic [DATA_WIDTH-1   :0]  rD_buffer;             //data out buffer for READ  RAM -->|_|_|_|_|_..._|--> |_|
    logic [DATA_COUNTER-1 :0]  rD_counter;            
    logic                      rD_temp;
    logic [DATA_WIDTH-1   :0]  wD_buffer;             //data_in buffer for WRITE  |_| -->|_|_|_|_|_..._|--> RAM
    logic [DATA_COUNTER-1 :0]  wD_counter;
    logic                      wD_temp;

    // Declare the RAM variable
	logic [DATA_WIDTH-1:0] ram[ADDR_DEPTH-1:0];

	// Variable to hold the registered read address
	logic [ADDR_WIDTH-1:0] addr_reg;

    
    localparam IDLE = 4'd0;
    localparam CONFIG = 4'd1;
    localparam CONFIG2 = 4'd2;
    localparam READ = 4'd3;
    localparam READ2 = 4'd4;
    localparam READB = 4'd5;
    localparam WRITE = 4'd6;
    localparam WRITEB = 4'd7;
    localparam WRITEB2 = 4'd8;

    initial begin
        state <= IDLE;
        next_state <= IDLE;
        //config_counter <= 0;
        rD_counter <= 0;
        wD_counter <= 0;
        //temp_control <= 0;
        ready <= 1;
        config_buffer <= 0;
        rD_buffer <= 0;
        wD_buffer <= 0;
    end

    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            config_buffer <= 0;
            rD_buffer <= 0;
            wD_buffer <= 0;
            rD_temp <= 0;
            ready <= 1;
        end
        else begin
            state<=next_state;
            case (state)
                IDLE : begin 
                    if (control == 1) begin
                        config_buffer[0] <= temp_control;
                        next_state <= CONFIG;                   
                    end
                end
                CONFIG : begin
                    config_buffer <= config_buffer << 1;
                    config_buffer[0] <= temp_control;
                    config_counter <= config_counter + 1;                    
                    if (config_counter < CON-2) begin
                        next_state <= CONFIG;
                    end
                    else begin
                        config_counter <= 0;
                        ready <= 0;
                        next_state <= CONFIG2;
                    end
                end
                CONFIG2 : begin
                    //                  start                       slaveid
                    if (config_buffer[CON:CON-2]==3'b111 && config_buffer[CON-3:CON-3-SLAVEID]==reg_slave_ID) begin
                        address <= config_buffer[ADDR_WIDTH-1:0];
                        if (config_buffer[CON-3-SLAVEID-1]==0) begin     //read
                            rD_buffer <= ram[address];
                            next_state <= READ;                                                   
                        end
                        else begin                          //write
                            next_state <= WRITE;
                        end
                    end
                end 
                READ : begin
                    rD_temp         <= rD_buffer[0];
                    rD_buffer       <= rD_buffer << 1;
                    rD_counter      <= rD_counter + 1;
                    if (rD_counter < DATA_COUNTER) begin
                        next_state  <= READ;
                    end 
                    else begin
                        ready <= 1;                      
                        rD_counter  <= 0;
                        next_state  <= READ2;
                    end
                end
                READ2: begin
                    if (config_buffer[CON-3-SLAVEID-2]==0) 
                        next_state  <= IDLE;
                    else begin
                        address     <= address + 1;
                        next_state  <= READB;
                    end
                    
                end
                READB: begin
                    if ((last == 0) && (rD_counter < DATA_COUNTER)) begin
                        rD_temp    <= rD_buffer[0];
                        rD_buffer  <= rD_buffer << 1;
                        rD_counter <= rD_counter + 1;
                    end
                end
                
                
                
                default: next_state <= IDLE;
                    
            endcase
        end 
    end
assign temp_control = control;
assign wD_temp = wD;
assign rD = rD_temp;
assign reg_slave_ID = slave_ID;
endmodule