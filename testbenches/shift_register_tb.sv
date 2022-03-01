`timescale 1ns / 1ps

module shift_register_tb();
    logic [7:0]  din;
    logic         clk,reset_n;
    logic         load;
    logic         dout;

    shift_register dut(
        .din(din),
        .clk(clk),
        .reset_n(reset_n),
        .load(load),
        .dout(dout)
    );

    localparam CLK_PERIOD = 10;
    initial begin
        clk <= 0;
            forever #(CLK_PERIOD/2) clk <= ~clk;
    end


    initial begin
        @(posedge clk);
        load <= 0;
        din <= $urandom;
        reset_n <= 1;
 
        #(CLK_PERIOD*2);
        load <=1;
        
        #(CLK_PERIOD*2);
        load <= 0;

        #(CLK_PERIOD*8);

        $stop;

    end

endmodule