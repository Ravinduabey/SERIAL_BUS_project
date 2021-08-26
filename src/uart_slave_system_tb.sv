module uart_slave_system_tb ();
timeunit 1ns; timeprecision 1ps;


logic rD;                  //serial read_data
logic ready;               //default HIGh

logic control=0;              //serial control setup info  start|slaveid|R/W|B|start_address -- 111|SLAVEID|1|1|WIDTH
logic wrD=0;                   //serial write_data
logic valid=0;                //default LOW
logic last=1;                 //default LOW

logic clk = 0;
logic rstN; 

logic tx;
logic rx;

localparam DATA_WIDTH = 8;
localparam BAUD_RATE = 19200;
localparam BAUD_TIME_PERIOD = 10**9 / BAUD_RATE;
localparam CLOCK_PERIOD = 20;

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
        .last(last),
        .rstN(rstN),
        .clk(clk),
        .rx(rx),
        .rx_ready(rx_ready),
        .tx(tx),
        .tx_ready(tx_ready)       
    );

    initial begin
        @(posedge clk);
        //control = 11110010
        control <= 1;
        valid <= 1;
        wrD <= 0;
        #(CLOCK_PERIOD*4);
        control <= 0;
        #(CLOCK_PERIOD*2);
        control <= 1;
        #(CLOCK_PERIOD);
        control <= 0;
        #(CLOCK_PERIOD);
        if (ready) begin
            @(posedge clk);
            wrD <= 1;
            valid <= 1;
            #(CLOCK_PERIOD*2);
            wrD <= 0;
            #(CLOCK_PERIOD*3);
            wrD <= 1;
 
        end

        repeat(10) begin
        @(posedge clk);
        wait(tx_ready);
        @(posedge clk);
        tx = $urandom();
        @(posedge clk);
        end

        @(posedge clk);
        wait(tx_ready);
        $stop;

      
        

        #(CLOCK_PERIOD*100);
        $stop;
    end

endmodule
