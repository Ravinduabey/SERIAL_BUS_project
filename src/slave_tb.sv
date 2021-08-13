module slave_tb ();
    timeunit 1ns;

    logic rD;                  //serial read_data
    logic ready;               //default HIGh

    logic control;              //serial control setup info  start|slaveid|R/W|B|start_address -- 111|SLAVEID|1|1|WIDTH
    logic wD;                   //serial write_data
    logic valid;                //default LOW
    logic last;                 //default LOW

    //with Top Module
    logic [1:0]slave_ID;
    logic clk;
    logic resetn; 

    localparam CLOCK_PERIOD = 20;
    initial begin
        clk <= 0;
            forever begin
                #(CLOCK_PERIOD/2) clk <= ~clk;
            end
    end


    slave #(.ADDR_DEPTH(2000),.SLAVES(3), .DATA_WIDTH(8)) dut (.rD(rD), .ready(ready), .control(control), .wD(wD), .valid(valid), .last(last),.slave_ID(slave_ID),.resetn(resetn),.clk(clk));

    initial begin
        resetn <= 1;
        @(posedge clk);
        slave_ID <= 2'b01;
        control <= 0;

        #(CLOCK_PERIOD*2);
        control <= 1;
        valid <= 0;
        last <= 0;

        @(posedge clk);
        control <= 1;
        @(posedge clk);
        control <= 1;
        @(posedge clk);
        control <= 0;
        @(posedge clk);
        control <= 1;
        @(posedge clk);
        control <= 0;
        @(posedge clk);
        control <= 0;
        @(posedge clk);
        control <= 1;
        @(posedge clk);
        control <= 0;
        @(posedge clk);
        control <= 1;
        @(posedge clk);
        control <= 0;
        @(posedge clk);
        control <= 0;
        @(posedge clk);
        control <= 0;
        @(posedge clk);
        control <= 0;
        @(posedge clk);
        control <= 1;
        @(posedge clk);
        control <= 1;
        @(posedge clk);
        control <= 1;
        @(posedge clk);
        control <= 0;
        @(posedge clk);

        

    end
endmodule