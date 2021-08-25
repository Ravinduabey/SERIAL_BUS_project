module uart_slave_system_tb ();
timeunit 1ns; timeprecision 1ps;


logic rD;                  //serial read_data
logic ready;               //default HIGh

logic control=0;              //serial control setup info  start|slaveid|R/W|B|start_address -- 111|SLAVEID|1|1|WIDTH
logic wrD=0;                   //serial write_data
logic valid=0;                //default LOW
logic last=1;                 //default LOW

//with Top Module
logic [1:0]slave_ID;
logic clk = 0;
logic rstN; 

logic tx_ready;
logic rx_ready;

localparam DATA_WIDTH = 8;
localparam BAUD_RATE = 19200;
localparam BAUD_TIME_PERIOD = 10**9 / BAUD_RATE;
   initial begin
       clk <= 0;
           forever begin
               #(CLOCK_PERIOD/2) clk <= ~clk;
           end
   end

    typedef enum logic  {
        Read_slave  = 1'b0,
        Write_slave = 1'b1
    } Read_write_slave;

    typedef enum logic  {
        non_burst       = 1'b0,
        burst_master    = 1'b1
    } top_master_burst;

    uart_slave_system #(
        .SLAVES(3), 
        .DATA_WIDTH(DATA_WIDTH), 
        .SLAVEID(1),
        .BAUD_RATE(19200)
    ) Slave_dut (
        .rD(rD), 
        .ready(ready), 
        .control(control), 
        .wD(wrD), 
        .valid(valid), 
        .last(last),
        .rstN(rstN),
        .clk(clk)
    );

    initial begin
        @(posedge clk);
        //control = 1110110
        control <= 1;
        #(CLOCK_PERIOD*3);
        control <= 0;
        #(CLOCK_PERIOD);
        control <= 1;
        #(CLOCK_PERIOD*2);
        control <= 0;


        repeat(10) begin
        @(posedge clk);
        wait(tx_ready);
        @(posedge clk);
        byteForTx = $urandom();
        txByteStart = 1'b1;
        @(posedge clk);
        txByteStart = 1'b0;
        end

        @(posedge clk);
        wait(tx_ready);
        $stop;

      
        

        #(CLOCK_PERIOD*100);
        $stop;
    end

endmodule
