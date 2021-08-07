module port_in_tb();
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
logic read;
logic [1:0] id;
logic request;
logic [2:0] input_buf;
 
port_in dut (.*);

initial begin
    @(posedge clk);
    read <= 0; 
    @(posedge clk);
    read <= 1; 
    @(posedge clk);
    read <= 1;
    @(posedge clk);
    read <= 1;  
    @(posedge clk);
    read <= 0;
    @(posedge clk);
    read <= 1;
    @(posedge clk);
    read <= 1;  
    @(posedge clk);
    read <= 1;
    @(posedge clk);
    read <= 0;
  #(CLK_PERIOD*3);
  @(posedge clk);
  $stop;
end
endmodule