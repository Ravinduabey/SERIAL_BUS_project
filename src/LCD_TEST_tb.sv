module LCD_TEST_tb ();

timeunit 1ns;
timeprecision 1ps;
localparam CLK_PERIOD = 20;

logic clk,rstN;
initial begin
    clk = 1'b0;
    forever begin
        #(CLK_PERIOD/2);
        clk = ~clk;
    end
end

logic CLOCK_50;
logic [0:0]KEY;
logic [7:0]LCD_DATA;
logic LCD_RW,LCD_EN,LCD_RS,LCD_BLON,LCD_ON;
logic [1:0]LEDG;

assign CLOCK_50 = clk;
assign KEY[0] = rstN;

LCD_TEST_TOP dut(.*);

localparam TIME = 1; //S
localparam CLK_RATE = 50_000_000;
localparam CLK_COUNT = TIME*CLK_RATE;
localparam COUNTER_WIDTH = $clog2(CLK_COUNT);

logic [COUNTER_WIDTH-1:0]counter;

initial begin
    @(posedge clk);
    rstN = 1'b0;
    @(posedge clk);
    rstN = 1'b1;
end


initial begin
    counter = '0;
    forever begin
        @(posedge clk);
        counter = counter + 1'b1;
        if (counter == CLK_COUNT) begin
            #(CLK_PERIOD*10);
            $stop;
        end
    end
end


endmodule:LCD_TEST_tb