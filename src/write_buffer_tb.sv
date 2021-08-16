module write_buffer_tb();

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

    parameter WIDTH = 3;

    logic [WIDTH-1:0] din;
    logic rstN;
    logic load;
    logic dout;

    write_buffer dut(.*);


    initial begin
        rstN = 1;
        load = 0;
        din = 0;
        @(posedge clk);
        load = 1;
        din = 3'b101;
        @(posedge clk);
        load = 0;
        #(CLK_PERIOD*6);
        @(posedge clk);
        load = 1;
        din = 010;
        @(posedge clk);
        load = 0;
        #(CLK_PERIOD*6);
        @(posedge clk);
        $stop;

    end

endmodule