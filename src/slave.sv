/*
Slave Module: 
*/
module slave #(
    parameter DEPTH = 2000,
    parameter SLAVES = 3,
    parameter WIDTH = $clog2(DEPTH),
    parameter SLAVEID = $clog2(SLAVES),
    parameter DATA_WIDTH = 32
) (
    // with Master (through interconnect)
    output rD,                  //serial read_data
    output ready,               //default HIGh

    input control,              //serial control setup info  start|slaveid|R/W|B|start_address -- 111|SLAVEID|1|1|WIDTH
    input wD,                   //serial write_data
    input valid,                //default LOW
    input last,                 //default LOW

    //with Top Module
    input [SLAVEID-1:0]slave_ID,
    input resetn   
);
    localparam int CON = 5 + SLAVEID + WIDTH;

    reg [SLAVEID-1:0] slave_ID;
    reg [2:0] state;
    reg [15:0] config_buffer;
    reg [3:0] config_counter;
    reg temp_control;
    reg [DATA_WIDTH-1:0] rD_buffer;             //data out buffer for READ
    reg [DATA_WIDTH-1:0] wD_buffer;             //data_in buffer for WRITE
    
    localparam IDLE = 4'd0;
    localparam CONFIG = 4'd1;
    localparam CONFIG2 = 4'd2;
    localparam READ = 4'd3;
    localparam READB = 4'd4;
    localparam READB2 = 4'd5;
    localparam WRITE = 4'd6;
    localparam WRITEB = 4'd7;
    localparam WRITEB2 = 4'd8;

    initial begin
        start <= 0;
        state <= IDLE;
        config_counter <= 0;
        temp_control <= 0;
        ready <= 1;
    end

    always @(posedge clk or negedge resetn) begin
        if (!reset) begin
            control <= 0;
            wD <= 0;
            valid <= 0;
            last <= 0;
            rD <= 0;
            ready <= 1;
        end
        else begin
            case (state)
                IDLE : begin 
                    if (conrol) state <= CONFIG;                   
                end
                CONFIG : begin
                    if (config_counter < 4'd16) begin
                        config_buffer << 1;
                        temp_control <= control;
                        config_counter = config_counter + 1;
                        state <= CONFIG2;
                    end
                end
                CONFIG2 : begin
                    start = config_buffer[15:13];
                    slaveid = config_buffer[12:11];
                    rw = config_buffer[10];
                    burst = config_buffer[9];
                    
                end 
                READ
                READB
                READB2
                WRITE
                WRITEB
                WRITEB2
                default: begin
                    
                end
            endcase
        end 
    end
assign config_buffer[0] = control;
endmodule