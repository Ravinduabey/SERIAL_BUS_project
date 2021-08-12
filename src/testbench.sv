module arbiter_tb();

timeunit 1ns;
timeprecision 1ps;

logic clk = '0;
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
    parameter NO_MASTERS = 2;
    parameter NO_SLAVES = 3;
    parameter S_ID_WIDTH = $clog2(NO_SLAVES+1);
    parameter M_ID_WIDTH = $clog2(NO_MASTERS);

  logic rstN;
  logic port_in [NO_MASTERS-1:0];
  logic port_out [NO_MASTERS-1:0];
  logic [S_ID_WIDTH+M_ID_WIDTH-1:0] bus_state;

  logic ready;

 logic [M_ID_WIDTH-1:0] addr_select;
 logic [M_ID_WIDTH-1:0] MOSI_data_select;
 logic [M_ID_WIDTH-1:0] valid_select;
 logic [M_ID_WIDTH-1:0] last_select;
 logic [S_ID_WIDTH-1:0] MISO_data_select;
 logic [S_ID_WIDTH-1:0] ready_select;

arbiter dut (.*);

initial begin
    rstN = 1;

    // @(posedge clk);
    // port_in[1] <= 0; 
    // port_in[0] <= 0; 
    // @(posedge clk); //start 
    // port_in[1] <= 1; 
    // port_in[0] <= 1; 
    // @(posedge clk);
    // port_in[1] <= 1;
    // port_in[0] <= 1; 
    // @(posedge clk);
    // port_in[1] <= 1;  
    // port_in[0] <= 1; 
    // @(posedge clk); //slave id
    // port_in[1] <= 0;
    // port_in[0] <= 1; 
    // @(posedge clk);
    // port_in[1] <= 1;
    // port_in[0] <= 0; 
    // @(posedge clk);
    // port_in[1] <= 0;
    // port_in[0] <= 0; 

    // @(posedge clk);
    // port_in[0] <= 0;  
    // #(CLK_PERIOD*2);
    // @(posedge clk); //ack receive
    // port_in[0] <= 1;
    // @(posedge clk);
    // port_in[0] <= 0;
    // @(posedge clk);
    // port_in[0] <= 1; 
    // @(posedge clk);//com high
    // port_in[0] <= 1; 
    // @(posedge clk);
    // port_in[0] <= 1;
    // @(posedge clk);//over
    // port_in[0] <= 0;
    // @(posedge clk);
    // port_in[0] <= 1;
    // @(posedge clk);
    // port_in[0] <= 1;
    // @(posedge clk);
    // port_in[0] <= 0;  
    // @(posedge clk);
    // port_in[0] <= 0;
    // @(posedge clk);
    // port_in[0] <= 0;


//this leads to interrupt transaction. once it is handled this should be tried. 
    @(posedge clk);
    port_in[0] <= 0; 
    port_in[1] <= 0;
    @(posedge clk); //start 
    port_in[1] <= 1; 
    @(posedge clk);
    port_in[1] <= 1;
    @(posedge clk);
    port_in[1] <= 1;  
    @(posedge clk); //slave id
    port_in[1] <= 1;
    @(posedge clk);
    port_in[1] <= 0;
    @(posedge clk);
    port_in[1] <= 0;  
    #(CLK_PERIOD*2);
    @(posedge clk); //ack receive
    port_in[0] <= 1 //start 0
    port_in[1] <= 1;
    @(posedge clk);
    port_in[0] <= 1
    port_in[1] <= 0;
    @(posedge clk);
    port_in[0] <= 1
    port_in[1] <= 1; 
    @(posedge clk);//com high
    port_in[0] <= 1 //slave id 0
    port_in[1] <= 1; 
    @(posedge clk);
    port_in[0] <= 0;
    port_in[1] <= 1;
    #(CLK_PERIOD*4);
    @(posedge clk);//over
    port_in[0] <= 1
    port_in[1] <= 0;
    @(posedge clk);
    port_in[1] <= 1;
    @(posedge clk);
    port_in[1] <= 1;
    @(posedge clk);
    port_in[1] <= 0;  
    @(posedge clk);
    port_in[1] <= 0;
    @(posedge clk);
    port_in[1] <= 0;
    @(posedge clk);
    port_in[1] <= 0;  
    @(posedge clk);
    port_in[1] <= 1;
    @(posedge clk);
    port_in[1] <= 1;

    // @(posedge clk);
    // port_in[0] <= 0; 
    // port_in[1] <= 0;
    // @(posedge clk); //start 
    // port_in[0] <= 1; 
    // @(posedge clk);
    // port_in[0] <= 1;
    // @(posedge clk);
    // port_in[0] <= 1;  
    // @(posedge clk); //slave id
    // port_in[0] <= 1;
    // @(posedge clk);
    // port_in[0] <= 1;
    // @(posedge clk);
    // port_in[0] <= 0;  
    // #(CLK_PERIOD*2);
    // @(posedge clk); //ack receive
    // port_in[0] <= 1;
    // @(posedge clk);
    // port_in[0] <= 0;
    // @(posedge clk);
    // port_in[0] <= 1; 
    // @(posedge clk);//com high
    // port_in[0] <= 1; 
    // @(posedge clk);
    // port_in[0] <= 1;
    // @(posedge clk);//over
    // port_in[0] <= 0;
    // @(posedge clk);
    // port_in[0] <= 1;
    // @(posedge clk);
    // port_in[0] <= 1;
    // @(posedge clk);
    // port_in[0] <= 0;  
    // @(posedge clk);
    // port_in[0] <= 0;
    // @(posedge clk);
    // port_in[0] <= 0;
    // @(posedge clk);
    // port_in[0] <= 0;  
    // @(posedge clk);
    // port_in[0] <= 1;
    // @(posedge clk);
    // port_in[0] <= 1;

  @(posedge clk);
  $stop;
end
endmodule