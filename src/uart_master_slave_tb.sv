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

    typedef enum logic  {
        Read_slave  = 1'b0,
        Write_slave = 1'b1
    } Read_write_slave;

    typedef enum logic  {
        non_burst       = 1'b0,
        burst_master    = 1'b1
    } top_master_burst;

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
            #(CLOCK_PERIOD*7);
        end
    endtask


    initial begin
        @(posedge clk);
        start   <= 0;
        rstN    <= 0;
        eoc     <= 0;

        #(CLOCK_PERIOD*2);
        start   <= 0;

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
        // inEx    <=1;
        data    <= 16'd32778;
        // slaveId <= 2'b01;

        //===to change read-write mode===//
        // rdWr    <= Write_slave;
        // rdWr    <= Read_slave;
        // burst   <= burst_master;
        //start adress 
        // address <= 12'd3;
        
        #3;
        eoc     <= 0;
        // start   <= 1;
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
        start   <= 0;
        // last data    
        // address <= 12'd5;
        data    <= 16'd17;

        #(CLOCK_PERIOD);
        start   <= 0;

        // send data to check whether the master module save this data
        data    <= 16'd18;

        //============================//
        //     state == startCom      //
        //===========================//
        #(CLOCK_PERIOD);
        // start   <= 1;
        arbCont <=0;
        // #(CLOCK_PERIOD);
        start   <= 0;
        // slaveId <= 2'b10;
        // rdWr    <= 0;

        // wait for arbiter request
        #(CLOCK_PERIOD*5);

        arbCont <= 0;
        #(CLOCK_PERIOD*5);
        arbCont <= 1;
        // #(CLOCK_PERIOD*2);
        // arbCont <= 0;

        //-- master will send the control signal for 19 clock_cycles--//
        master_control();

        #(CLOCK_PERIOD*100);
        // $stop;
    end

endmodule