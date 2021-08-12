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

    rstN <= 1'b1;

    master_request(port_in[1]);
    master_sendack_startcom(port_in[1]);
    master_end_comm(port_in[1]);

    master_request(port_in[0]);
    master_sendack_startcom(port_in[0]);
    master_end_comm(port_in[0]);
    
    // master_request(port_in[1]);
    // #(CLK_PERIOD*2);
    // master_sendack_startcom(port_in[1]);
    // master_request(port_in[0]);
    // #(CLK_PERIOD*4);
    // master_hold_com(port_in[1]);
    // master_sendack_startcom(port_in[0]);
    // #(CLK_PERIOD*4);
    // master_end_comm(port_in[0]);
    // #(CLK_PERIOD*2);
    // master_sendack_startcom(port_in[1]);
    // #(CLK_PERIOD*4);
    // master_end_comm(port_in[1]);
    // #(CLK_PERIOD*3);

    @(posedge clk);
    $stop;
end

task automatic master_request(ref logic port);
    @(posedge clk);
    port = 0;
    @(posedge clk); //start 
    port = 1; 
    @(posedge clk);
    port = 1;
    @(posedge clk);
    port = 1;  
    @(posedge clk); //slave id
    port = 1;
    @(posedge clk);
    port = 0;
    @(posedge clk); //low
    port = 0;  
endtask

task automatic master_sendack_startcom(ref logic port);
    @(posedge clk); //ack 
    port = 1;
    @(posedge clk);
    port = 0;
    @(posedge clk);
    port = 1; 
    @(posedge clk);//com high
    port = 1; 
endtask

task automatic master_end_comm(ref logic port);
    @(posedge clk);//over
    port = 0;
    @(posedge clk);
    port = 1;
    @(posedge clk);
    port = 1;
    @(posedge clk);
    port = 0;  
endtask

task automatic master_hold_com(ref logic port);
    @(posedge clk);//done
    port = 0;
    @(posedge clk);
    port = 1;
    @(posedge clk);
    port = 0;
    @(posedge clk);
    port = 0;  
endtask

endmodule