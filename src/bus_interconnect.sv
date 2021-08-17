module bus_interconnect #(
    parameter NO_MASTERS = 2,
    parameter NO_SLAVES = 3,
    parameter S_ID_WIDTH = $clog2(NO_SLAVES+1), //2
    parameter M_ID_WIDTH = $clog2(NO_MASTERS) //1
)(

    // arbiter controllers
    //this register is used for external multiplexer selection input
    input logic [S_ID_WIDTH+M_ID_WIDTH-1:0] bus_state,
    output logic ready,

    //masters
    input   logic  control_M    [0:NO_MASTERS-1], 
	input   logic  wD_M         [0:NO_MASTERS-1],
	input   logic  valid_M      [0:NO_MASTERS-1],
	input   logic  last_M       [0:NO_MASTERS-1],
    output  logic  rD_M         [0:NO_MASTERS-1],
	output  logic  ready_M      [0:NO_MASTERS-1],

    //slaves
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
    assign ready_mux    = ready_S   [slave_sel  ];
    assign rD_mux       = rD_S      [slave_sel  ];

    assign ready        = ready_mux;
    
    genvar i;
    genvar j;
    generate 
        for (i = 0; i<NO_SLAVES; i++) begin : master_to_slave
            assign control_S[i] = (i==slave_sel) ? control_mux  : '0;
            assign wD_S     [i] = (i==slave_sel) ? wD_mux       : '0; 
            assign valid_S  [i] = (i==slave_sel) ? valid_mux    : '0;
            assign last_S   [i] = (i==slave_sel) ? last_mux     : '0;
        end 
        for (j = 0; j<NO_MASTERS; j++) begin : slave_to_master
            assign ready_M  [j] = (j==master_sel) ? ready_mux   : '0;
            assign rD_M     [j] = (j==master_sel) ? rD_mux      : '0;
        end 
    endgenerate
    
    




    // bus_mux_MtoS #(
    //     .NO_MASTERS(NO_MASTERS),
    //     .NO_SLAVES(NO_SLAVES)
    // ) control_mux (
    //     .master_sel(master_sel),
    //     .slave_sel(slave_sel),
    //     .master(control_M),
    //     .slave(control_S)
    // );

    // bus_mux_MtoS #(
    //     .NO_MASTERS(NO_MASTERS),
    //     .NO_SLAVES(NO_SLAVES)
    // ) wD_mux (
    //     .master_sel(master_sel),
    //     .slave_sel(slave_sel),
    //     .master(wD_M),
    //     .slave(wD_S)
    // );

    // bus_mux_MtoS #(
    //     .NO_MASTERS(NO_MASTERS),
    //     .NO_SLAVES(NO_SLAVES)
    // ) valid_mux (
    //     .master_sel(master_sel),
    //     .slave_sel(slave_sel),
    //     .master(valid_M),
    //     .slave(valid_S)
    // );

    // bus_mux_MtoS #(
    //     .NO_MASTERS(NO_MASTERS),
    //     .NO_SLAVES(NO_SLAVES)
    // ) last_mux (
    //     .master_sel(master_sel),
    //     .slave_sel(slave_sel),
    //     .master(last_M),
    //     .slave(last_S)
    // );

    // bus_mux_StoM #(
    //     .NO_MASTERS(NO_MASTERS),
    //     .NO_SLAVES(NO_SLAVES)
    // ) rD_mux (
    //     .master_sel(master_sel),
    //     .slave_sel(slave_sel),
    //     .master(rD_M),
    //     .slave(rD_S)
    // );

    // bus_mux_StoM #(
    //     .NO_MASTERS(NO_MASTERS),
    //     .NO_SLAVES(NO_SLAVES)
    // ) ready_mux (
    //     .master_sel(master_sel),
    //     .slave_sel(slave_sel),
    //     .master(ready_M),
    //     .slave(ready_S)
    // );

endmodule
    