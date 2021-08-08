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
logic rstn;

logic m1_in;
logic m1_out;
logic com_m1;

logic ready;

logic m2_in;
logic m2_out;
logic com_m2;



logic addr_select;
logic MOSI_data_select;
logic [1:0] MISO_data_select;
logic valid_select;
logic last_select;
logic [1:0] ready_select;

arbiter dut (.*);

initial begin

    @(posedge clk);
    m1_in <= 0; 
    m2_in <= 0; 
    @(posedge clk); //start 
    m1_in <= 1; 
    m2_in <= 1; 
    @(posedge clk);
    m1_in <= 1;
    m2_in <= 1; 
    @(posedge clk);
    m1_in <= 1;  
    m2_in <= 1; 
    @(posedge clk); //slave id
    m1_in <= 0;
    m2_in <= 1; 
    @(posedge clk);
    m1_in <= 1;
    m2_in <= 0; 


    @(posedge clk);
    m1_in <= 0;  
    #(CLK_PERIOD*2);
    @(posedge clk); //ack receive
    m1_in <= 1;
    @(posedge clk);
    m1_in <= 0;
    @(posedge clk);
    m1_in <= 1; 
    @(posedge clk);//com high
    m1_in <= 1; 
    @(posedge clk);
    m1_in <= 1;
    @(posedge clk);//over
    m1_in <= 0;
    @(posedge clk);
    m1_in <= 1;
    @(posedge clk);
    m1_in <= 1;
    @(posedge clk);
    m1_in <= 0;  
    @(posedge clk);
    m1_in <= 0;
    @(posedge clk);
    m1_in <= 0;

    // @(posedge clk);
    // m2_in <= 0; 
    // @(posedge clk); //start 
    // m2_in <= 1; 
    // @(posedge clk);
    // m2_in <= 1;
    // @(posedge clk);
    // m2_in <= 1;  
    // @(posedge clk); //slave id
    // m2_in <= 0;
    // @(posedge clk);
    // m2_in <= 1;
    // @(posedge clk);
    // m2_in <= 0;  
    // #(CLK_PERIOD*2);
    // @(posedge clk); //ack receive
    // m2_in <= 1;
    // @(posedge clk);
    // m2_in <= 0;
    // @(posedge clk);
    // m2_in <= 1; 
    // @(posedge clk);//com high
    // m2_in <= 1; 
    // @(posedge clk);
    // m2_in <= 1;
    // @(posedge clk);//over
    // m2_in <= 0;
    // @(posedge clk);
    // m2_in <= 1;
    // @(posedge clk);
    // m2_in <= 1;
    // @(posedge clk);
    // m2_in <= 0;  
    // @(posedge clk);
    // m2_in <= 0;
    // @(posedge clk);
    // m2_in <= 0;

  @(posedge clk);
  $stop;
end
endmodule