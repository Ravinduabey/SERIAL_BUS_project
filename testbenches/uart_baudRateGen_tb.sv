module uart_baudRateGen_tb();

timeunit 1ns;
timeprecision 1ps;

localparam CLK_PERIOD = 20;
logic clk;
initial begin
    clk = 0;
    forever begin
        #(CLK_PERIOD/2);
        clk <= ~clk;
    end
end

localparam BAUD_RATE = 115200;
localparam CLK_RATE = 50*(10**6);
localparam RESOLUTION = 16;  // samples per 1 baud
localparam MAX_COUNT = (CLK_RATE/BAUD_RATE/RESOLUTION);
initial begin
    $display("max_count = %d", MAX_COUNT);
end



logic rstN,baudTick;
uart_baudRateGen #(.BAUD_RATE(BAUD_RATE)) dut (.*);

initial begin
    @(posedge clk);
    rstN <= 1'b0;

    @(posedge clk);
    rstN <= 1'b1;
end

int clk_count = 0;
initial begin
    @(posedge clk);
    repeat(MAX_COUNT *5) begin
        @(posedge clk);
        if (baudTick == 1'b1) begin
            $display("clk_count = %d", clk_count);
            clk_count = 0;
        end
        else begin
            clk_count = clk_count + 1;
        end
    end
    $stop;
end

endmodule:uart_baudRateGen_tb