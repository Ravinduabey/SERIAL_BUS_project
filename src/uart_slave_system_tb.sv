module uart_slave_system_tb ();
timeunit 1ns; timeprecision 1ps;


logic rD;                  //serial read_data
logic ready;               //default HIGh

logic control=0;              //serial control setup info  start|slaveid|R/W|
logic wrD=0;                   //serial write_data
logic valid=0;                //default LOW

logic clk = 0;
logic rstN; 

logic g_rx;
logic g_tx;
logic s_rx;
logic s_tx;

localparam DATA_WIDTH = 8;
localparam BAUD_RATE = 19200;
localparam BAUD_TIME_PERIOD = 10**9 / BAUD_RATE;
localparam CLOCK_PERIOD = 20;


logic baudTick;

logic ext_txByteStart;
logic [DATA_WIDTH-1:0] ext_byteForTx;
logic ext_tx_ready;

logic ext_new_byte_start;
logic ext_new_byte_received;
logic [DATA_WIDTH-1:0] ext_byteFromRx;
logic ext_rx_ready;



   initial begin
       clk <= 0;
           forever begin
               #(CLOCK_PERIOD/2) clk <= ~clk;
           end
   end

    uart_slave_system #(
        .SLAVES(4), 
        .DATA_WIDTH(DATA_WIDTH), 
        .SLAVEID(4),
        .BAUD_RATE(19200)
    ) Slave_dut (
        .rD(rD), 
        .ready(ready), 
        .control(control), 
        .wD(wrD), 
        .valid(valid), 
        .rstN(rstN),
        .clk(clk),
        .g_rx(g_rx),
        .g_tx(g_tx),
        .s_rx(s_rx),
        .s_tx(s_tx)
    );

    initial begin
        @(posedge clk);
        control <= 0;
        #(CLOCK_PERIOD*3);
        //control = 11110010
        control <= 1;
        valid <= 0;
        wrD <= 0;
        #(CLOCK_PERIOD*4);
        control <= 0;
        #(CLOCK_PERIOD*2);
        control <= 1;
        #(CLOCK_PERIOD);
        control <= 0;
        #(CLOCK_PERIOD);
        repeat (5) begin
            @(posedge clk);
            wrD <= 1;
            valid <= 1;
            #(CLOCK_PERIOD*2);
            wrD <= $random();;
    
        end
        wrD <= 0;

        #(CLOCK_PERIOD*10);
        //control = 11110000
        // control <= 1;
        // valid <= 1;
        // wrD <= 0;
        // #(CLOCK_PERIOD*4);
        // control <= 0;
        // #(CLOCK_PERIOD*3);
        // control <= 1;
        // #(CLOCK_PERIOD);
        // control <= 0;
        // #(CLOCK_PERIOD);

        // repeat(10) begin
        //     g_rx <= 1'b0;
        //     #(BAUD_TIME_PERIOD);
        //     for (int i=0;i<DATA_WIDTH;i++) begin:data  //data
        //         @(posedge clk);
        //         g_rx = $urandom();
        //         #(BAUD_TIME_PERIOD);
        //     end
        //     @(posedge clk);  // end delimiter
        //     g_rx <= 1'b1;
        //     #(BAUD_TIME_PERIOD);
        // end

        // @(posedge clk);
        // $stop;

      
        

        // #(CLOCK_PERIOD*1000);
        // $stop;
    end

endmodule
