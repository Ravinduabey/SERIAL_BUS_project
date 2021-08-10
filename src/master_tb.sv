module master_tb();
timeunit 1ns; timeprecision 1ps;
    localparam DATA_WIDTH = 16;
    localparam ADDRESS_WIDTH = $clog2(4096);
    ///////////////////////
    //===================//
    //  with topModule   //
    //===================// 
    ///////////////////////
    logic clk;
    logic rstN;
    logic burst;
    logic rdWr;
    logic inEx;
    logic [DATA_WIDTH -1 : 0] data;
    logic [ADDRESS_WIDTH-1:0] address;
    logic [1:0] slaveId;
    logic start;       
    logic doneCom ;
    logic [DATA_WIDTH-1:0] dataOut;

  
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
    logic last;

    ///////////////////////
    //===================//
    //    with arbiter   //
    //===================// 
    ///////////////////////
    logic arbCont;

    logic arbSend;
    

  
    localparam CLOCK_PERIOD = 20;
    initial begin
        clk <= 0;
            forever begin
                #(CLOCK_PERIOD/2) clk <= ~clk;
            end
    end


    master  #(
        .MEMORY_DEPTH (4096),
        .DATA_WIDTH     (DATA_WIDTH)
    ) dut (
        .clk(clk),
        .rstN(rstN),
        .burst(burst),
        .rdWr(rdWr),
        .inEx(inEx),
        .data(data),
        .address(address),
        .slaveId(slaveId),
        .start(start),
        .rD(rD),
        .ready(ready),
        .control(control),
        .wrD(wrD),
        .valid(valid),
        .arbCont(arbCont),
        .arbSend(arbSend)
    );

    

    initial begin
        @(posedge clk);
        start <= 0;
        rstN <= 0;

        #(CLOCK_PERIOD*2);
        start <= 1;

        #(CLOCK_PERIOD);
        start <= 0;

        #(CLOCK_PERIOD*5);

        start <= 0;
        rstN <= 1;

        //============================//
        //    state == startConfig    //
        //===========================//
        #(CLOCK_PERIOD*2);
        #17;
        inEx <=1;
        data <= 16'd10;
        slaveId <= 2'b01;
        rdWr <= 0;
        burst <= 1;
        address <= 12'd13;
        
        #3;
        start <= 1;
        #(CLOCK_PERIOD);
        start <= 0;

        

        #17;
        data <= 16'd14;
        #3;
        #(CLOCK_PERIOD);
        start <= 0;

        //============================//
        //  state == startEndConfig   //
        //===========================//
        #(CLOCK_PERIOD);
        start <= 1;
        address <= 12'd16;
        data <= 16'd17;

        #(CLOCK_PERIOD);
        start <= 0;

        data <= 16'd18;
        //============================//
        //     state == startCom      //
        //===========================//
        #(CLOCK_PERIOD);
        start <= 1;
        
        #(CLOCK_PERIOD);
        start <= 0;
        slaveId <= 2'b10;
        rdWr <= 1;

        #(CLOCK_PERIOD*20);
        rstN <=1;

        #(CLOCK_PERIOD);
        rstN <= 0 ;

        #(CLOCK_PERIOD*5);

        $stop;
    end

endmodule
