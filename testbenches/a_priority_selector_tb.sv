module a_priority_selector_tb();
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
parameter NO_MASTERS = 3;
parameter NO_SLAVES = 5;
parameter S_ID_WIDTH = $clog2(NO_SLAVES+1);
parameter M_ID_WIDTH = $clog2(NO_MASTERS);

logic rstN;
logic state;
logic thresh;
logic request;
logic [M_ID_WIDTH-1:0] master_in;
logic [S_ID_WIDTH-1:0] slave_in;
logic [M_ID_WIDTH-1:0] master_out;
logic [S_ID_WIDTH-1:0] slave_out;
logic [S_ID_WIDTH-1:0] slave_id [0:NO_MASTERS-1];

localparam NRML = 1'b0;
localparam SPLIT = 1'b1;

a_priority_selector dut(.*);

initial begin
    rstN = 1;
    thresh = 0;
    @(posedge clk);
    @(posedge clk);
    state = NRML;
    slave_id[0] = 3'b0;
    slave_id[1] = 3'b101;
    slave_id[2] = 3'b100;

    @(posedge clk);
    state = SPLIT;
    master_in = 2'b10;
    slave_in = 3'b101;
    slave_id[0] = 3'b0;
    slave_id[1] = 3'b111;
    slave_id[2] = 3'b100;

    @(posedge clk);
    thresh = 1;
    state = SPLIT;
    master_in = 2'b01;
    slave_in = 3'b111;
    slave_id[0] = 3'b0;
    slave_id[1] = 3'b111;
    slave_id[2] = 3'b100;

    #(CLK_PERIOD*2);
    $stop;
end
endmodule