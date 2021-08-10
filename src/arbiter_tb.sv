module arbiter_tb();

timeunit 1ns;
timeprecision 1ps;

logic clk = 0;
localparam CLK_PERIOD = 10;
initial begin
    forever begin
        #(CLK_PERIOD/2);
        clk <= ~clk;
    end
end

// initial begin
//   $dumpfile("dump.vcd");
//   $dumpvars(1);
// end

logic rstN = 1;

logic port0_in;
logic port0_out;

logic port1_in;
logic port1_out;

logic [2:0] bus_state;

// logic ready;

// logic addr_select;
// logic MOSI_data_select;
// logic [1:0] MISO_data_select;
// logic valid_select;
// logic last_select;
// logic [1:0] ready_select;

arbiter dut (.*);

initial begin

    // @(posedge clk);
    // port1_in <= 0; 
    // port0_in <= 0; 
    // @(posedge clk); //start 
    // port1_in <= 1; 
    // port0_in <= 1; 
    // @(posedge clk);
    // port1_in <= 1;
    // port0_in <= 1; 
    // @(posedge clk);
    // port1_in <= 1;  
    // port0_in <= 1; 
    // @(posedge clk); //slave id
    // port1_in <= 0;
    // port0_in <= 1; 
    // @(posedge clk);
    // port1_in <= 1;
    // port0_in <= 0; 


    // @(posedge clk);
    // port1_in <= 0;  
    // #(CLK_PERIOD*2);
    // @(posedge clk); //ack receive
    // port1_in <= 1;
    // @(posedge clk);
    // port1_in <= 0;
    // @(posedge clk);
    // port1_in <= 1; 
    // @(posedge clk);//com high
    // port1_in <= 1; 
    // @(posedge clk);
    // port1_in <= 1;
    // @(posedge clk);//over
    // port1_in <= 0;
    // @(posedge clk);
    // port1_in <= 1;
    // @(posedge clk);
    // port1_in <= 1;
    // @(posedge clk);
    // port1_in <= 0;  
    // @(posedge clk);
    // port1_in <= 0;
    // @(posedge clk);
    // port1_in <= 0;

    @(posedge clk);
    port0_in <= 0; 
    port1_in <= 0;
    @(posedge clk); //start 
    port0_in <= 1; 
    @(posedge clk);
    port0_in <= 1;
    @(posedge clk);
    port0_in <= 1;  
    @(posedge clk); //slave id
    port0_in <= 0;
    @(posedge clk);
    port0_in <= 1;
    @(posedge clk);
    port0_in <= 0;  
    #(CLK_PERIOD*2);
    @(posedge clk); //ack receive
    port0_in <= 1;
    @(posedge clk);
    port0_in <= 0;
    @(posedge clk);
    port0_in <= 1; 
    @(posedge clk);//com high
    port0_in <= 1; 
    @(posedge clk);
    port0_in <= 1;
    @(posedge clk);//over
    port0_in <= 0;
    @(posedge clk);
    port0_in <= 1;
    @(posedge clk);
    port0_in <= 1;
    @(posedge clk);
    port0_in <= 0;  
    @(posedge clk);
    port0_in <= 0;
    @(posedge clk);
    port0_in <= 0;
    @(posedge clk);
    port0_in <= 0;  
    @(posedge clk);
    port0_in <= 1;
    @(posedge clk);
    port0_in <= 1;

    @(posedge clk);
    port0_in <= 0; 
    port1_in <= 0;
    @(posedge clk); //start 
    port0_in <= 1; 
    @(posedge clk);
    port0_in <= 1;
    @(posedge clk);
    port0_in <= 1;  
    @(posedge clk); //slave id
    port0_in <= 0;
    @(posedge clk);
    port0_in <= 1;
    @(posedge clk);
    port0_in <= 0;  
    #(CLK_PERIOD*2);
    @(posedge clk); //ack receive
    port0_in <= 1;
    @(posedge clk);
    port0_in <= 0;
    @(posedge clk);
    port0_in <= 1; 
    @(posedge clk);//com high
    port0_in <= 1; 
    @(posedge clk);
    port0_in <= 1;
    @(posedge clk);//over
    port0_in <= 0;
    @(posedge clk);
    port0_in <= 1;
    @(posedge clk);
    port0_in <= 1;
    @(posedge clk);
    port0_in <= 0;  
    @(posedge clk);
    port0_in <= 0;
    @(posedge clk);
    port0_in <= 0;
    @(posedge clk);
    port0_in <= 0;  
    @(posedge clk);
    port0_in <= 1;
    @(posedge clk);
    port0_in <= 1;

  @(posedge clk);
  $stop;
end
endmodule