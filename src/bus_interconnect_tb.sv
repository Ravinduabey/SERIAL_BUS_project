module bus_interconnect_tb ();
    localparam  NO_SLAVES= 10;
    localparam  NO_MASTERS= 5;

    localparam S_ID_WIDTH = $clog2(NO_SLAVES+1); //2
    localparam M_ID_WIDTH = $clog2(NO_MASTERS); //1

    logic [S_ID_WIDTH+M_ID_WIDTH-1:0] bus_state;
    logic ready;

    logic  control_M    [0:NO_MASTERS-1]; 
    logic  wD_M         [0:NO_MASTERS-1];
    logic  valid_M      [0:NO_MASTERS-1];
    logic  last_M       [0:NO_MASTERS-1];
    logic  rD_M         [0:NO_MASTERS-1];
    logic  ready_M      [0:NO_MASTERS-1];

//slaves
    logic control_S     [0:NO_SLAVES-1];
    logic wD_S          [0:NO_SLAVES-1];
    logic valid_S       [0:NO_SLAVES-1];
    logic last_S        [0:NO_SLAVES-1];
    logic rD_S          [0:NO_SLAVES-1];
    logic ready_S       [0:NO_SLAVES-1];


    logic clk;
    localparam CLOCK_PERIOD = 20;
    initial begin
        clk <= 0;
            forever begin
                #(CLOCK_PERIOD/2) clk <= ~clk;
            end
    end

    bus_interconnect#(
        .NO_MASTERS(NO_MASTERS),
        .NO_SLAVES(NO_SLAVES)
    ) bus (
        .bus_state(bus_state),
        .ready(ready),
        .control_M(control_M),
        .wD_M(wD_M),
        .valid_M(valid_M),
        .last_M(last_M),
        .rD_M(rD_M),
        .ready_M(ready_M),
        .control_S(control_S),
        .wD_S(wD_S),
        .valid_S(valid_S),
        .last_S(last_S),
        .rD_S(rD_S),
        .ready_S(ready_S)
    );
    
    initial begin
        @(posedge clk);
        bus_state <= 7'b0110011;
        control_M <= '{5{'0}};
        wD_M <= '{5{'0}};
        valid_M <= '{5{'0}};
        last_M <= '{5{'0}};
        rD_S <= '{10{'0}};
        ready_S <= '{10{'0}};
        #(CLOCK_PERIOD*5);
        control_M <= '{5{'1}};
        wD_M <= '{5{'1}};
        valid_M <= '{5{'1}};
        last_M <= '{5{'1}};
        rD_S <= '{10{'1}};
        ready_S <= '{10{'1}};
        #(CLOCK_PERIOD*5);
        $stop;

    end

endmodule