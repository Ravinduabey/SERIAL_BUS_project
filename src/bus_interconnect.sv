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
    input   logic [NO_MASTERS-1:0] control_M,
	input   logic [NO_MASTERS-1:0] wD_M,
	input   logic [NO_MASTERS-1:0] valid_M,
	input   logic [NO_MASTERS-1:0] last_M,
    output  logic [NO_MASTERS-1:0] rD_M,
	output  logic [NO_MASTERS-1:0] ready_M,

    //slaves
    output  logic [NO_SLAVES-1:0] control_S,
	output  logic [NO_SLAVES-1:0] wD_S,
	output  logic [NO_SLAVES-1:0] valid_S,
	output  logic [NO_SLAVES-1:0] last_S,
    input   logic [NO_SLAVES-1:0] rD_S,
	input   logic [NO_SLAVES-1:0] ready_S
    );

    logic [M_ID_WIDTH-1:0]master_sel = bus_state[S_ID_WIDTH+M_ID_WIDTH-1:S_ID_WIDTH];
    logic [S_ID_WIDTH-1:0]slave_sel  = bus_state[S_ID_WIDTH-1:0];

    mux_MtoS #(
        .NO_MASTERS(NO_MASTERS),
        .NO_SLAVES(NO_SLAVES),
        .S_ID_WIDTH(S_ID_WIDTH),
        .M_ID_WIDTH(M_ID_WIDTH)
    ) control_mux (
        .master_sel(master_sel),
        .slave_sel(slave_sel),
        .master(control_M),
        .slave(control_S)
    );

    mux_MtoS #(
        .NO_MASTERS(NO_MASTERS),
        .NO_SLAVES(NO_SLAVES),
        .S_ID_WIDTH(S_ID_WIDTH),
        .M_ID_WIDTH(M_ID_WIDTH)
    ) wD_mux (
        .master_sel(master_sel),
        .slave_sel(slave_sel),
        .master(wD_M),
        .slave(wD_S)
    );

    mux_MtoS #(
        .NO_MASTERS(NO_MASTERS),
        .NO_SLAVES(NO_SLAVES),
        .S_ID_WIDTH(S_ID_WIDTH),
        .M_ID_WIDTH(M_ID_WIDTH)
    ) valid_mux (
        .master_sel(master_sel),
        .slave_sel(slave_sel),
        .master(valid_M),
        .slave(valid_S)
    );

    mux_MtoS #(
        .NO_MASTERS(NO_MASTERS),
        .NO_SLAVES(NO_SLAVES),
        .S_ID_WIDTH(S_ID_WIDTH),
        .M_ID_WIDTH(M_ID_WIDTH)
    ) last_mux (
        .master_sel(master_sel),
        .slave_sel(slave_sel),
        .master(last_M),
        .slave(last_S)
    );

    mux_StoM #(
        .NO_MASTERS(NO_MASTERS),
        .NO_SLAVES(NO_SLAVES),
        .S_ID_WIDTH(S_ID_WIDTH),
        .M_ID_WIDTH(M_ID_WIDTH)
    ) rD_mux (
        .master_sel(master_sel),
        .slave_sel(slave_sel),
        .master(rD_M),
        .slave(rD_S)
    );

    mux_StoM #(
        .NO_MASTERS(NO_MASTERS),
        .NO_SLAVES(NO_SLAVES),
        .S_ID_WIDTH(S_ID_WIDTH),
        .M_ID_WIDTH(M_ID_WIDTH)
    ) ready_mux (
        .master_sel(master_sel),
        .slave_sel(slave_sel),
        .master(ready_M),
        .slave(ready_S)
    );

endmodule
    