module top_tb();

timeunit 1ns;
timeprecision 1ns;

localparam CLK_PERIOD = 20;

localparam INT_SLAVE_COUNT=3;  // number of slaves
localparam INT_MASTER_COUNT=2;  // number of masters
localparam DATA_WIDTH = 16;   // width of a data word in slave & master
localparam int SLAVE_DEPTHS[0:INT_SLAVE_COUNT-1] = '{4096,4096,2048}; // give each slave's depth
localparam int SLAVE_DELAYS[INT_SLAVE_COUNT] = '{0,0,100};
localparam MAX_MASTER_WRITE_DEPTH = 16;  // maximum number of addresses of a master that can be externally written

localparam MASTER_DEPTH = SLAVE_DEPTHS[0]; // master should be able to write or read all the slave address locations without loss
localparam MASTER_ADDR_WIDTH = $clog2(MASTER_DEPTH); 

localparam UART_WIDTH = 8;
localparam UART_BAUD_RATE = 19200;
localparam EXT_COM_INIT_VAL = 0;
localparam EXT_DISPLAY_DURATION = 5; // external communication value display duration

typedef enum logic[1:0]{
    no_slave = 2'b00,
    slave_1  = 2'b01,
    slave_2  = 2'b10,
    slave_3  = 2'b11    
} slave_t;

typedef enum logic{
    master_0 = 1'b0,
    master_1 = 1'b1
} master_t;

typedef enum logic{
    read = 1'b0,
    write = 1'b1
} operation_t;

//////// set the following parameters first before run the simulation ////////
localparam logic [1:0] masters_slave[0:1] = '{slave_1, no_slave};
localparam logic master_RW[0:1] = '{read,write};
localparam logic external_write[0:1] = '{1'b1, 1'b1};
localparam int   external_write_count[0:1] = '{1,1};
localparam logic [MASTER_ADDR_WIDTH-1:0] slave_start_address[0:1] = '{0,0};
localparam logic [MASTER_ADDR_WIDTH-1:0] slave_end_address[0:1] = '{1,1};
localparam logic [MASTER_ADDR_WIDTH-1:0] master_read_addr[0:9] = '{0,1,2,3,4,5,6,7,8,9}; // read the masters' memory after communication
localparam FIRST_START_MASTER = master_0; // this master will start communication first
localparam COM_START_DELAY = 0; //gap between 2 masters communication start signal
    

logic clk;
initial begin
    clk = 1'b0;
    forever begin
        #(CLK_PERIOD/2);
        clk = ~clk;
    end
end

logic CLOCK_50;
logic [3:0]KEY;
logic [17:0]SW;
logic [17:0]LEDR;
logic [3:0]LEDG;
logic [6:0]HEX0, HEX1;
logic [7:0]LCD_DATA;
logic LCD_RW,LCD_EN,LCD_RS,LCD_BLON,LCD_ON;
wire [3:0]GPIO;

logic rstN, jump_stateN, jump_next_addr, start_ext_com;
logic communication_ready, communication_done;
logic g_rx, g_tx, s_rx, s_tx;

assign CLOCK_50 = clk;
assign KEY[0] = rstN;
assign KEY[1] = jump_stateN;
assign KEY[2] = jump_next_addr;
assign KEY[3] = start_ext_com;
assign communication_ready = LEDG[1];
assign communication_done  = LEDG[2];

assign GPIO[0] = g_rx; // get data
assign GPIO[2] = s_rx; // send data
assign g_tx = GPIO[1]; // send ack
assign s_tx = GPIO[3]; // get ack

top #(.INT_SLAVE_COUNT(INT_SLAVE_COUNT), .INT_MASTER_COUNT(INT_MASTER_COUNT), .DATA_WIDTH(DATA_WIDTH), 
    .SLAVE_DEPTHS(SLAVE_DEPTHS), .SLAVE_DELAYS(SLAVE_DELAYS), .MAX_MASTER_WRITE_DEPTH(MAX_MASTER_WRITE_DEPTH), 
    .FIRST_START_MASTER(FIRST_START_MASTER), .COM_START_DELAY(COM_START_DELAY),
    .UART_WIDTH(UART_WIDTH), .UART_BAUD_RATE(UART_BAUD_RATE), .EXT_COM_INIT_VAL(EXT_COM_INIT_VAL), 
    .EXT_DISPLAY_DURATION(EXT_DISPLAY_DURATION) ) dut (.*);
    
initial begin
    @(posedge clk);
    jump_next_addr = 1'b1;  // initially at pulled up (high) state
    jump_stateN = 1'b1;
    rstN = 1'b1;
    start_ext_com = 1'b1;

    SW[17:0] = '0; // all switches are off at the beginning.

    s_rx = 1'b1; // keep the UART receive wires at high
    g_rx = 1'b1;

    @(posedge clk);
    rstN <= 1'b0;

    @(posedge clk);
    rstN <= 1'b1;

    // if ((slave_t'(masters_slave[0]) == no_slave) & (slave_t'(masters_slave[1]) == no_slave)) begin
        
    #(CLK_PERIOD*10);
    @(posedge clk);
    master_slave_select(slave_t'(masters_slave[0]), slave_t'(masters_slave[1]));

    #(CLK_PERIOD*10);
    @(posedge clk);
    master_read_write_select(operation_t'(master_RW[0]), operation_t'(master_RW[1]));

    #(CLK_PERIOD*10);
    @(posedge clk);
    external_write_select(external_write[0], external_write[1]);

    @(posedge clk);
    if (external_write[0]==1'b1) begin
        #(CLK_PERIOD*10);
        master_external_write(external_write_count[0]);
    end

    @(posedge clk);
    if (external_write[1]==1'b1) begin
        #(CLK_PERIOD*10);
        master_external_write(external_write_count[1]);
    end

    #(CLK_PERIOD*10);
    @(posedge clk);
    set_slave_start_address(slave_start_address[0]);

    #(CLK_PERIOD*10);
    @(posedge clk);
    set_slave_start_address(slave_start_address[1]);

    #(CLK_PERIOD*10);
    @(posedge clk);
    set_slave_end_address(slave_end_address[0]);

    #(CLK_PERIOD*10);
    @(posedge clk);
    set_slave_end_address(slave_end_address[1]); 

    ///////// after the end of above state automatically goes to master configuration state //////////
    
    wait(communication_ready);  // wait untill configuration is done 

    #(CLK_PERIOD*10);
    @(posedge clk);
    start_communication();

    // end 

    wait(communication_done);

    #(CLK_PERIOD*10);
    @(posedge clk);
    get_data_from_masters();

    // #(CLK_PERIOD*10);
    // change_external_com(); // start ext_com

    // #(CLK_PERIOD*100);
    // change_external_com(); // finish ext_com

    $stop;



end



task automatic master_slave_select(slave_t M1_slave, M2_slave); 
    @(posedge clk);
    SW[1:0] = logic'(M1_slave); // set the switches
    SW[3:2] = logic'(M2_slave);

    @(posedge clk);
    #(CLK_PERIOD*10);

    @(posedge clk);
    jump_stateN = 1'b0; // press the push button
    #(CLK_PERIOD*10); // hold the push button untill pass some time period

    @(posedge clk);
    jump_stateN = 1'b1; // release the push button

    #(CLK_PERIOD*10); // wait some time before next KEY press / SW change 

endtask

task automatic master_read_write_select(operation_t M1_RW, M2_RW);
    @(posedge clk);
    SW[0] = M1_RW; // set the switches
    SW[1] = M2_RW;

    @(posedge clk);
    #(CLK_PERIOD*10);

    @(posedge clk);
    jump_stateN = 1'b0; // press the push button
    #(CLK_PERIOD*10); // hold the push button untill pass some time period

    @(posedge clk);
    jump_stateN = 1'b1; // release the push button

    #(CLK_PERIOD*10); // wait some time before next KEY press / SW change 

endtask

task automatic external_write_select (logic M1_external_write, M2_external_write);
    @(posedge clk);
    SW[0] = M1_external_write; // set the switches
    SW[1] = M2_external_write;

    @(posedge clk);
    #(CLK_PERIOD*10);

    @(posedge clk);
    jump_stateN = 1'b0; // press the push button
    #(CLK_PERIOD*10); // hold the push button untill pass some time period

    @(posedge clk);
    jump_stateN = 1'b1; // release the push button

    #(CLK_PERIOD*10); // wait some time before next KEY press / SW change 

endtask

task automatic master_external_write(int count);
    for (int i=0;i<count-1; i++) begin
        @(posedge clk);
        SW[DATA_WIDTH-1:0] = $urandom();   // set a random value
        
        #(CLK_PERIOD*10);
        @(posedge clk);
        jump_next_addr = 1'b0;      // press push button to jump to next address

        #(CLK_PERIOD*10);
        @(posedge clk);
        jump_next_addr = 1'b1;  // release push button

        #(CLK_PERIOD*10); // wait some time before next KEY press / SW change 
    end

    @(posedge clk);
    SW[DATA_WIDTH-1:0] = $urandom(); // sets the last value 

    #(CLK_PERIOD*10);
    @(posedge clk);
    jump_stateN = 1'b0; // press push button to go to next state

    #(CLK_PERIOD*10);
    @(posedge clk);
    jump_stateN = 1'b1;  // release push button
endtask

task automatic set_slave_start_address(logic [MASTER_ADDR_WIDTH-1:0]address);
    @(posedge clk);
    SW[MASTER_ADDR_WIDTH-1:0] = address; // set the switches

    @(posedge clk);
    #(CLK_PERIOD*10);

    @(posedge clk);
    jump_stateN = 1'b0; // press the push button
    #(CLK_PERIOD*10); // hold the push button untill pass some time period

    @(posedge clk);
    jump_stateN = 1'b1; // release the push button

    #(CLK_PERIOD*10); // wait some time before next KEY press / SW change 
endtask

task automatic set_slave_end_address(logic [MASTER_ADDR_WIDTH-1:0]addr);
    @(posedge clk);
    SW[MASTER_ADDR_WIDTH-1:0] = addr; // set the switches

    @(posedge clk);
    #(CLK_PERIOD*10);

    @(posedge clk);
    jump_stateN = 1'b0; // press the push button
    #(CLK_PERIOD*10); // hold the push button untill pass some time period

    @(posedge clk);
    jump_stateN = 1'b1; // release the push button

    #(CLK_PERIOD*10); // wait some time before next KEY press / SW change 
endtask

task automatic start_communication();
    #(CLK_PERIOD*10);
   
    @(posedge clk);
    jump_stateN = 1'b0; // press the push button
    #(CLK_PERIOD*10); // hold the push button untill pass some time period

    @(posedge clk);
    jump_stateN = 1'b1; // release the push button

    #(CLK_PERIOD*10); // wait some time before next KEY press / SW change 
endtask

task automatic get_data_from_masters();

    foreach (master_read_addr[i]) begin
        @(posedge clk);
        SW[MASTER_ADDR_WIDTH-1:0] = master_read_addr[i]; // set the switches

        @(posedge clk);
        #(CLK_PERIOD*10);

        @(posedge clk);
        jump_next_addr = 1'b0; // press the push button
        #(CLK_PERIOD*10); // hold the push button untill pass some time period

        @(posedge clk);
        jump_next_addr = 1'b1; // release the push button

        #(CLK_PERIOD*10); // wait some time before next KEY press / SW change 
    end
    
endtask

task automatic change_external_com();
    #(CLK_PERIOD*10);
   
    @(posedge clk);
    start_ext_com = 1'b0; // press the push button
    #(CLK_PERIOD*10); // hold the push button untill pass some time period

    @(posedge clk);
    start_ext_com = 1'b1; // release the push button

    #(CLK_PERIOD*10); // wait some time before next KEY press / SW change

endtask

endmodule : top_tb