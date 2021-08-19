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
    logic eoc;       
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
    integer  i;

  
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
        .eoc(eoc),
        .doneCom(doneCom),
        .dataOut(dataOut),
        .rD(rD),
        .ready(ready),
        .control(control),
        .wrD(wrD),
        .valid(valid),
        .last(last),
        .arbCont(arbCont),
        .arbSend(arbSend)
    );

    task automatic top_burst_write(
        output [DATA_WIDTH -1 : 0] data
    );
       
        begin
            #17;
            data = $random;
            #3;
            #CLOCK_PERIOD;
        end
    endtask
    
    task automatic master_control();
        begin
            #(CLOCK_PERIOD*19);
        end
    endtask

    // task automatic single_read(
    //     output rD
    // );
    //     begin
    //         // #20;
    //         for (i = 0; i < 5 ; i = i + 1)begin
    //            rD =  $random;
    //            #20;
    //         end
    //     end
    // endtask

    typedef enum logic  {
        Read_slave  = 1'b0,
        Write_slave = 1'b1
    } Read_write_slave;

    typedef enum logic  {
        non_burst       = 1'b0,
        burst_master    = 1'b1
    } top_master_burst;
    



    initial begin
        @(posedge clk);
        start   <= 0;
        rstN    <= 0;
        eoc     <= 0;

        #(CLOCK_PERIOD*2);
        start   <= 1;

        #(CLOCK_PERIOD);
        start   <= 0;

        #(CLOCK_PERIOD*5);

        start   <= 0;
        rstN    <= 1;

        //============================//
        //    state == startConfig    //
        //===========================//
        #(CLOCK_PERIOD*2);
        #17;
        inEx    <=1;
        data    <= 16'd32778;
        slaveId <= 2'b01;

        //===to change read-write mode===//
        // rdWr    <= Write_slave;
        rdWr    <= Read_slave;
        burst   <= burst_master;
        address <= 12'd0;
        
        #3;
        eoc     <= 0;
        start   <= 1;
        #(CLOCK_PERIOD);
        start   <= 0;

        

        #17;
        data    <= 16'd14;
        #3;
        top_burst_write(.data(data));
        top_burst_write(.data(data));
        top_burst_write(.data(data));
        top_burst_write(.data(data));
        top_burst_write(.data(data));
        top_burst_write(.data(data));
        
        #(CLOCK_PERIOD);
        start   <= 0;

        //============================//
        //  state == startEndConfig   //
        //===========================//
        #(CLOCK_PERIOD);
        start   <= 1;
        // last data
        address <= 12'd3;
        data    <= 16'd17;

        #(CLOCK_PERIOD);
        start   <= 0;

        // send data to check whether the master module save this data
        data    <= 16'd18;

        //============================//
        //     state == startCom      //
        //===========================//
        #(CLOCK_PERIOD);
        start   <= 1;
        arbCont <=0;
        #(CLOCK_PERIOD);
        start   <= 0;
        slaveId <= 2'b10;
        rdWr    <= 0;

        // wait for arbiter request
        #(CLOCK_PERIOD*5);

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

        #(CLOCK_PERIOD*10);

        //=======single read==========//

        
        rD      <= 0;
        #(CLOCK_PERIOD*3);
        // single_read(.rD(rD));
        ready   = 0;
        #(CLOCK_PERIOD*5);

        // initiate split transaction
        #(CLOCK_PERIOD*5);
        arbCont <=0;
        #CLOCK_PERIOD;
        arbCont <=1;
        #CLOCK_PERIOD;

        arbCont <= 0;
        // arbiter send split clear
        #(CLOCK_PERIOD*15);
        arbCont  = 1;
        #(CLOCK_PERIOD);
        arbCont  = 0;
        // arbiter waits for ack
        #(CLOCK_PERIOD*3);
        // arbiter send clear for ack
        arbCont  = 1;

    
        rD      <=1;
        #(CLOCK_PERIOD*22)
        // wait for control signal
        ready   <= 0;
        #(CLOCK_PERIOD*10)
        arbCont <= 1;
        #(CLOCK_PERIOD*2);
        // arbCont <= 0;
        // #(CLOCK_PERIOD*10);
        // arbCont <= 1;
        // #(CLOCK_PERIOD);
        // arbCont <= 0;
        // #(CLOCK_PERIOD*2);
        // arbCont <= 0;
        // #(CLOCK_PERIOD*2);

        // #(CLOCK_PERIOD)
        // 1st data
        ready   <= 1;
        rD      <= 0; //1
        #(CLOCK_PERIOD);
        rD      <= 0;  //2
        #(CLOCK_PERIOD);
        rD      <= 0;   //3
        #(CLOCK_PERIOD);
        rD      <= 0;    //4
        #(CLOCK_PERIOD);
        rD      <= 0;    //5
        #(CLOCK_PERIOD);
        rD      <= 0;    //6
        #(CLOCK_PERIOD);
        rD      <= 0;    //7
        #(CLOCK_PERIOD);
        rD      <= 0;    //8
        #(CLOCK_PERIOD);
        rD      <= 0;    //9
        #(CLOCK_PERIOD);    
        rD      <= 1;    //10 64 
        #(CLOCK_PERIOD);
        rD      <= 1;    //11 32
        #(CLOCK_PERIOD);
        rD      <= 0;   //12 16 
        #(CLOCK_PERIOD);
        rD      <= 0;    //13 8
        #(CLOCK_PERIOD);
        rD      <= 0;    //14 4
        #(CLOCK_PERIOD);
        rD      <= 1;    //15 2
        #(CLOCK_PERIOD);
        rD      <= 1;    //16 1  99

        #(CLOCK_PERIOD*2);

        //2nd data
        rD      <= 0; //1
        #(CLOCK_PERIOD);
        rD      <= 0;  //2
        #(CLOCK_PERIOD);
        rD      <= 0;   //3
        #(CLOCK_PERIOD);
        rD      <= 0;    //4
        #(CLOCK_PERIOD);
        rD      <= 0;    //5
        #(CLOCK_PERIOD);
        rD      <= 0;    //6
        #(CLOCK_PERIOD);
        rD      <= 0;    //7
        #(CLOCK_PERIOD);
        rD      <= 0;    //8
        #(CLOCK_PERIOD);
        rD      <= 0;    //9
        #(CLOCK_PERIOD);    
        rD      <= 1;    //10 64
        #(CLOCK_PERIOD);
        // stop prority
        arbCont <= 0;
        rD      <= 1;    //11 32
        #(CLOCK_PERIOD);
        arbCont <= 0;
        rD      <= 0;   //12
        #(CLOCK_PERIOD);
        rD      <= 0;    //13
        #(CLOCK_PERIOD);
        rD      <= 1;    //14 4
        #(CLOCK_PERIOD);
        rD      <= 0;    //15
        #(CLOCK_PERIOD);
        rD      <= 0;    //16 100
        #(CLOCK_PERIOD*10);



        #(CLOCK_PERIOD*10);
        arbCont <= 1;
        #(CLOCK_PERIOD);
        arbCont <= 1;
        #(CLOCK_PERIOD);
        // arbCont <= 0;
        rD      <=1;
        #(CLOCK_PERIOD*22)

        // 3rd data
        rD      <= 0; //1
        #(CLOCK_PERIOD);
        rD      <= 0;  //2
        #(CLOCK_PERIOD);
        rD      <= 0;   //3
        #(CLOCK_PERIOD);
        rD      <= 0;    //4
        #(CLOCK_PERIOD);
        rD      <= 0;    //5
        #(CLOCK_PERIOD);
        rD      <= 0;    //6
        #(CLOCK_PERIOD);
        rD      <= 0;    //7
        #(CLOCK_PERIOD);
        rD      <= 0;    //8
        #(CLOCK_PERIOD);
        rD      <= 0;    //9
        #(CLOCK_PERIOD);    
        rD      <= 1;    //10 64
        #(CLOCK_PERIOD);
        arbCont <= 0;
        rD      <= 1;    //11 32
        #(CLOCK_PERIOD);
        arbCont <= 0;
        rD      <= 0;   //12
        #(CLOCK_PERIOD);
        rD      <= 0;    //13
        #(CLOCK_PERIOD);
        rD      <= 1;    //14 4
        #(CLOCK_PERIOD);
        rD      <= 1;    //15 2
        #(CLOCK_PERIOD);
        rD      <= 0;    //16  102
        #(CLOCK_PERIOD*2);

        #(CLOCK_PERIOD*10);
        arbCont <= 1;
        #(CLOCK_PERIOD);
        arbCont <= 1;
        #(CLOCK_PERIOD);
        arbCont <= 0;
        rD      <=1;
        #(CLOCK_PERIOD*22)

        //4th data

        rD      <= 0; //1
        #(CLOCK_PERIOD);
        rD      <= 0;  //2
        #(CLOCK_PERIOD);
        rD      <= 0;   //3
        #(CLOCK_PERIOD);
        rD      <= 0;    //4
        #(CLOCK_PERIOD);
        rD      <= 0;    //5
        #(CLOCK_PERIOD);
        rD      <= 0;    //6
        #(CLOCK_PERIOD);
        rD      <= 0;    //7
        #(CLOCK_PERIOD);
        rD      <= 0;    //8
        #(CLOCK_PERIOD);
        rD      <= 0;    //9
        #(CLOCK_PERIOD);    
        rD      <= 1;    //10
        #(CLOCK_PERIOD);
        rD      <= 1;    //11
        #(CLOCK_PERIOD);
        rD      <= 0;   //12
        #(CLOCK_PERIOD);
        rD      <= 0;    //13
        #(CLOCK_PERIOD);
        arbCont <= 1;
        rD      <= 1;    //14
        #(CLOCK_PERIOD);
        arbCont <= 0;
        rD      <= 1;    //15
        #(CLOCK_PERIOD);
        rD      <= 1;    //16
        #(CLOCK_PERIOD*2);


        #(CLOCK_PERIOD*10);
        arbCont  <= 1;
        #(CLOCK_PERIOD);
        arbCont  <= 1;
        #(CLOCK_PERIOD);
        arbCont  <= 0;
        rD      <=1;
        #(CLOCK_PERIOD*22)
        // 5th data
        rD      <= 0; //1
        #(CLOCK_PERIOD);
        rD      <= 0;  //2
        #(CLOCK_PERIOD);
        rD      <= 0;   //3
        #(CLOCK_PERIOD);
        rD      <= 0;    //4
        #(CLOCK_PERIOD);
        rD      <= 0;    //5
        #(CLOCK_PERIOD);
        rD      <= 0;    //6
        #(CLOCK_PERIOD);
        rD      <= 0;    //7
        #(CLOCK_PERIOD);
        rD      <= 0;    //8
        #(CLOCK_PERIOD);
        rD      <= 0;    //9
        #(CLOCK_PERIOD);    
        rD      <= 1;    //10
        #(CLOCK_PERIOD);
        rD      <= 1;    //11
        #(CLOCK_PERIOD);
        rD      <= 0;   //12
        #(CLOCK_PERIOD);
        rD      <= 1;    //13
        #(CLOCK_PERIOD);
        rD      <= 0;    //14
        #(CLOCK_PERIOD);
        rD      <= 0;    //15
        #(CLOCK_PERIOD);
        rD      <= 0;    //16
        #(CLOCK_PERIOD*2);


        #(CLOCK_PERIOD*200);
        rstN <=1;

        #(CLOCK_PERIOD);
        rstN <= 0 ;

        #(CLOCK_PERIOD*5);

        $stop;
    end

endmodule: master_tb
