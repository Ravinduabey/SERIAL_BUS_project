module bus_interconnect #(
    parameter NO_MASTERS = 2,
    parameter NO_SLAVES = 3,
    parameter S_ID_WIDTH = $clog2(NO_SLAVES+1), //2
    parameter M_ID_WIDTH = $clog2(NO_MASTERS) //1
)(

    // arbiter 
    input logic [S_ID_WIDTH+M_ID_WIDTH-1:0] bus_state,
    output logic ready,

    //masters from First master: 0 - Second master :1 --- last
    input   logic  control_M    [0:NO_MASTERS-1], 
	input   logic  wD_M         [0:NO_MASTERS-1],
	input   logic  valid_M      [0:NO_MASTERS-1],
	input   logic  last_M       [0:NO_MASTERS-1],
    output  logic  rD_M         [0:NO_MASTERS-1],
	output  logic  ready_M      [0:NO_MASTERS-1],

    //slaves count  First Slave : 0 - Second Slave :1 --- last
    output  logic control_S     [0:NO_SLAVES-1],
	output  logic wD_S          [0:NO_SLAVES-1],
	output  logic valid_S       [0:NO_SLAVES-1],
	output  logic last_S        [0:NO_SLAVES-1],
    input   logic rD_S          [0:NO_SLAVES-1],
	input   logic ready_S       [0:NO_SLAVES-1]
    );

    logic [M_ID_WIDTH-1:0] master_sel;
    logic [S_ID_WIDTH-1:0] slave_sel;

    always_comb begin : muxController
        master_sel  = bus_state [S_ID_WIDTH+M_ID_WIDTH-1:S_ID_WIDTH];
        slave_sel   = bus_state [S_ID_WIDTH-1:0];
    end


    logic control_mux; 
    logic wD_mux; 
    logic valid_mux; 
    logic last_mux; 
    logic ready_mux; 
    logic rD_mux; 

    assign control_mux  = control_M [master_sel ];      
    assign wD_mux       = wD_M      [master_sel ];
    assign valid_mux    = valid_M   [master_sel ];
    assign last_mux     = last_M    [master_sel ];
    assign ready_mux    = ready_S   [slave_sel-1];
    assign rD_mux       = rD_S      [slave_sel-1];

    assign ready        = ready_mux;
    
    genvar i;
    genvar j;
    generate 
        for (i = 0; i<NO_SLAVES; i++) begin : master_to_slave
            assign control_S[i] = (i==slave_sel-1) ? control_mux  : '0;
            assign wD_S     [i] = (i==slave_sel-1) ? wD_mux       : '0; 
            assign valid_S  [i] = (i==slave_sel-1) ? valid_mux    : '0;
            assign last_S   [i] = (i==slave_sel-1) ? last_mux     : '0;
        end 
        for (j = 0; j<NO_MASTERS; j++) begin : slave_to_master
            assign ready_M  [j] = (j==master_sel) ? ready_mux   : '1;
            assign rD_M     [j] = (j==master_sel) ? rD_mux      : '0;
        end 
    endgenerate
    
endmodule
    