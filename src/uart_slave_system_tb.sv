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
        .last(last),
        .rstN(rstN),
        .clk(clk),
        .rx(rx),
        .tx(tx)
    );
    uart_baudRateGen #(.BAUD_RATE(BAUD_RATE)) ext_baudRateGen(.clk, .rstN, .baudTick);

    uart_transmitter #(.DATA_WIDTH(DATA_WIDTH)) ext_transmitter(
                        .dataIn(ext_byteForTx),
                        .txStart(ext_txByteStart), 
                        .clk(clk), .rstN(rstN), .baudTick(baudTick),                     
                        .tx(rx), 
                        .tx_ready(ext_tx_ready)
                        );

    uart_receiver #(.DATA_WIDTH(DATA_WIDTH)) ext_receiver (
                .rx(tx), 
                .clk(clk), .rstN(rstN), .baudTick(baudTick), 
                .rx_ready(ext_rx_ready), 
                .dataOut(ext_byteFromRx), 
                .new_byte_start(ext_new_byte_start),
                .new_byte_received(ext_new_byte_received)
                );

                


    initial begin
        @(posedge clk);
        control <= 0;
        #(CLOCK_PERIOD*3)
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

        #(CLOCK_PERIOD*10);
        //control = 11110001
        control <= 1;
        valid <= 1;
        wrD <= 0;
        #(CLOCK_PERIOD*4);
        control <= 0;
        #(CLOCK_PERIOD*3);
        control <= 1;
        #(CLOCK_PERIOD);
        control <= 0;
        #(CLOCK_PERIOD);

        rx <= 1;
        #(CLOCK_PERIOD*3);
        rx <= 0;
        #(CLOCK_PERIOD);
        rx <= 1;       
        // repeat(10) begin
        // @(posedge clk);
        // tx = $urandom();
        // @(posedge clk);
        // end

        // @(posedge clk);
        $stop;

      
        

        #(CLOCK_PERIOD*100);
        $stop;
    end

endmodule
