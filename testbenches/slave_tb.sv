module slave_tb ();
timeunit 1ns; timeprecision 1ps;

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


    slave #(.ADDR_DEPTH(2048),.SLAVES(3), .DATA_WIDTH(8), .SLAVEID(1), .DELAY(5)) dut (.rD(rD), .ready(ready), .control(control), .wD(wD), .valid(valid), .last(last),.rstN(resetn),.clk(clk));

    initial begin
        resetn <= 1;
        @(posedge clk);
        resetn <= 0;
        slave_ID <= 2'b01;
        control <= 0;
        valid <= 0;
        last <= 0;
        wD <= 0;
        #(CLOCK_PERIOD)
        resetn <= 1;

        //control signal 111_01_11_00000000000 : write burst from ram[0]
        #(CLOCK_PERIOD*3);
        control <= 1;
        #(CLOCK_PERIOD*3);
        control <= 0;
        #(CLOCK_PERIOD);
        control <= 1;
        #(CLOCK_PERIOD*3);
        control <= 0;
        #(CLOCK_PERIOD*11);
        control <= 1;           
        #(CLOCK_PERIOD*2);
        control <= 0;

        repeat (50) @(posedge clk) begin        //write data
            if (ready) begin
            valid <= 1;
            wD <= 0;
            #(CLOCK_PERIOD);
            wD <= 1;
            #(CLOCK_PERIOD*3);
            wD <= 0;
            #(CLOCK_PERIOD*4);
            valid <= 0;
            #(CLOCK_PERIOD*8);
            valid <= 1;
            #(CLOCK_PERIOD);
            wD <= 1;
            #(CLOCK_PERIOD*3);
            wD <= 0;
            #(CLOCK_PERIOD*5);
            valid <= 0;
            #(CLOCK_PERIOD);
            end
        end
        valid <= 1;
        last <= 1;
        wD <= 1;
        #(CLOCK_PERIOD*5);
        wD <= 0;
        #(CLOCK_PERIOD*3);

        // @(posedge clk);
        // resetn <= 0;
        // #(CLOCK_PERIOD)
        // resetn <= 1;
        // last <= 0;

        #(CLOCK_PERIOD*4);

        //control signal 111010100000000000 read burst from ram[0]
        control <= 1;
        #(CLOCK_PERIOD*3);
        control <= 0;
        #(CLOCK_PERIOD);
        control <= 1;
        #(CLOCK_PERIOD);
        control <= 0;
        #(CLOCK_PERIOD);
        control <= 1;
        #(CLOCK_PERIOD);
        control <= 0;
        #(CLOCK_PERIOD*11);
        control <= 1;           //just to make sure following bits are ignored
        #(CLOCK_PERIOD*2);
        control <= 0;
        #(CLOCK_PERIOD);
        #(CLOCK_PERIOD*3);
        valid <= 0;
        #(CLOCK_PERIOD*8*50);      // send last HIGH after 50 words? 
        last <= 1;

                #(CLOCK_PERIOD*3)
        //control signal 111_01_10_00000000000 write to ram[0]
        control <= 1;
        #(CLOCK_PERIOD*3);
        control <= 0;
        #(CLOCK_PERIOD);
        control <= 1;
        #(CLOCK_PERIOD*2);
        control <= 0;
        #(CLOCK_PERIOD*12);
        control <= 1;           //just to make sure following bits are ignored
        #(CLOCK_PERIOD);
        control <= 0;
        #(CLOCK_PERIOD);
        wD <= 1;
        valid <= 1;
        #(CLOCK_PERIOD*8);
        wD <= 0;
        valid <= 0;

        #(CLOCK_PERIOD*3)
        //control signal 111_00_00_00000000000 read from ram[0]
        control <= 1;
        #(CLOCK_PERIOD*3);
        control <= 0;
        #(CLOCK_PERIOD*15);
        #(CLOCK_PERIOD*20);

        #(CLOCK_PERIOD*20)
        //control signal 111_01_00_00000000011 read from ram[3]
        control <= 1;
        #(CLOCK_PERIOD*3);
        control <= 0;
        #(CLOCK_PERIOD);
        control <= 1;
        #(CLOCK_PERIOD);
        control <= 0;
        #(CLOCK_PERIOD*11);
        control <= 1;           //just to make sure following bits are ignored
        #(CLOCK_PERIOD*2);
        control <= 0;
        #(CLOCK_PERIOD*50);
        $stop;

    end

    
endmodule