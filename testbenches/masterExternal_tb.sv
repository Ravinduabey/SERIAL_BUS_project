module masterExternal_tb();
timeunit 1ns; timeprecision 1ps;
    localparam DATA_WIDTH = 8;
    localparam CLK_FREQ = 5;
    localparam CLOCK_DURATION = 1;
    ///////////////////////
    //===================//
    //  with topModule   //
    //===================// 
    ///////////////////////
    logic clk;
    logic rstN;
    logic start;
    logic eoc;

    logic [1:0] doneCom;
    logic [DATA_WIDTH-1:0] dataOut;
    logic disData;

  
    ///////////////////////
    //===================//
    //    with slave     //
    //===================// 
    ///////////////////////
    logic rD;         
    logic ready;

    logic control;           // START|SLAVE_ID|r/w|B|address| 
    logic wrD;
    logic valid;

    ///////////////////////
    //===================//
    //    with arbiter   //
    //===================// 
    ///////////////////////
    logic arbCont;

    logic arbSend;

    masterExternal  #(
        .DATA_WIDTH     (DATA_WIDTH),
        .CLK_FREQ       (CLK_FREQ  ),
        .CLOCK_DURATION (CLOCK_DURATION)
    ) dut (
        .clk(clk),
        .rstN(rstN),
        .start(start),
        .eoc(eoc),
        .doneCom(doneCom),
        .dataOut(dataOut),
        .logic (disData),
        .rD(rD),
        .ready(ready),
        .control(control),
        .wrD(wrD),
        .valid(valid),
        .arbCont(arbCont),
        .arbSend(arbSend)
    );
  
    localparam CLOCK_PERIOD = 20;
    initial begin
        clk <= 0;
            forever begin
                #(CLOCK_PERIOD/2) clk <= ~clk;
            end
    end

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


        //-- master will send the control signal for 19 clock_cycles--//
        master_control();
        ready <= 0;
        rD    <= 1;

        data_write_duration(); 
        #(CLOCK_PERIOD*5);

        $stop;


    end

endmodule