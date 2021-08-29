module uart_master_slave_tb ();
timeunit 1ns; timeprecision 1ps;


    localparam DATA_WIDTH = 8;
    localparam ADDRESS_WIDTH = $clog2(4096);
    
    logic rD;                  //serial read_data
    logic ready;               //default HIGh

    logic control;              //serial control setup info  start|slaveid|R/W|B|start_address -- 111|SLAVEID|1|1|WIDTH
    logic wrD;                   //serial write_data
    logic valid;                //default LOW

    //with Top Module
    logic [1:0]slave_ID;
    logic clk = 0;
    logic rstN; 

    logic [DATA_WIDTH -1 : 0] data;

    logic start;
    logic eoc;       
    logic doneCom ;
    logic [DATA_WIDTH-1:0] dataOut;

    logic arbCont;

    logic arbSend;
    integer  i;


    localparam CLOCK_PERIOD = 20;
   initial begin
       clk <= 0;
           forever begin
               #(CLOCK_PERIOD/2) clk <= ~clk;
           end
   end


    uart_slave_system #(
        .SLAVES(4), 
        .DATA_WIDTH(DATA_WIDTH), 
        .SLAVEID(4),
        .BAUD_RATE(19200)
    ) ext_Slave_dut (
        .rD(rD), 
        .ready(ready), 
        .control(control), 
        .wD(wrD), 
        .valid(valid), 
        .rstN(rstN),
        .clk(clk),
        .rx(rx),
        .tx(tx)
    );

    masterExternal  #(
        .DATA_WIDTH (DATA_WIDTH)
    ) ext_Master_dut (
        .clk(clk),
        .rstN(rstN),
        .start(start),
        .eoc(eoc),
        .doneCom(doneCom),
        .dataOut(dataOut),
        .rD(rD),
        .ready(ready),
        .control(control),
        .wrD(wrD),
        .valid(valid),
        .arbCont(arbCont),
        .arbSend(arbSend)
    );

    task automatic master_control();
        begin
            #(CLOCK_PERIOD*10);
        end
    endtask

    task automatic master_display(); 
        begin
            #(CLK_FREQ*CLOCK_DURATION);
        end
    endtask

    task automatic data_write_duration(); 
        begin
            #(CLOCK_PERIOD*12);
        end
    endtask

    initial begin
        @(posedge clk);
        start   <= 0;
        rstN    <= 0;
        eoc     <= 0;
        arbCont <= 0;

        #(CLOCK_PERIOD*2);
        start   <= 1;

        #(CLOCK_PERIOD);
        start   <= 0;

        #(CLOCK_PERIOD*5);

        start   <= 0;
        rstN    <= 1;
        
        #(CLOCK_PERIOD*5);
        start   <= 1;
        #(CLOCK_PERIOD);
        start   <= 0;

        /* display first */
        master_display();
        // wait for arbiter request
        #(CLOCK_PERIOD*7);

        /* go to write mode */
        arbCont <= 0;   // wait period
        #(CLOCK_PERIOD*5);
        arbCont <= 1;
        #(CLOCK_PERIOD*2);
        arbCont <= 0;

        #(CLOCK_PERIOD*3);

        // wait for arbiter clear for ack
        arbCont <= 1;
        #(CLOCK_PERIOD*2);


        //-- master will send the control signal for 10 clock_cycles--//
        master_control();
        ready <= 0;
        rD    <= 1;

        data_write_duration(); 
        arbCont <= 0;

        /* go to read mode */
        // wait for arbiter request
        #(CLOCK_PERIOD*7);

        arbCont <= 0;   // wait period
        #(CLOCK_PERIOD*5);
        arbCont <= 1;
        #(CLOCK_PERIOD*2);
        arbCont <= 0;

        #(CLOCK_PERIOD*3);

        // wait for arbiter clear for ack
        arbCont <= 1;
        #(CLOCK_PERIOD*2);


        //-- master will send the control signal for 10 clock_cycles--//
        master_control();

        ready <= 1;
        rD    <= 1; // 11
        #(CLOCK_PERIOD*2);
        rD    <= 0; // 1100    
        #(CLOCK_PERIOD*2);
        rD    <= 1; // 110011
        #(CLOCK_PERIOD*2);
        rD    <= 0; // 11001100
        #(CLOCK_PERIOD*2);

        /* send data now */
        rD    <= 0;
        #(CLOCK_PERIOD*6);
        rD    <= 1;
        #(CLOCK_PERIOD*3); 
        ready <= 0;
        arbCont <=0;

        /* Second display */
        master_display();
        // wait for arbiter request
        #(CLOCK_PERIOD*7);

        arbCont <= 0;   // wait period
        #(CLOCK_PERIOD*5);
        arbCont <= 1;
        #(CLOCK_PERIOD*2);
        arbCont <= 0;

        #(CLOCK_PERIOD*3);

        // wait for arbiter clear for ack
        arbCont <= 1;
        #(CLOCK_PERIOD*2);


        //-- master will send the control signal for 10 clock_cycles--//
        master_control();
        ready <= 0;
        rD    <= 1;

        data_write_duration(); 
        #(CLOCK_PERIOD*5);

        $stop;

    end
endmodule