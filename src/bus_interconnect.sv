module bus_interconnect #(
    parameter NO_MASTERS = 2,
    parameter NO_SLAVES = 3,
    parameter THRESH = 1000,
    parameter S_ID_WIDTH = $clog2(NO_SLAVES+1), //2
    parameter M_ID_WIDTH = $clog2(NO_MASTERS) //1
)(

    // arbiter controllers
    input logic [M_ID_WIDTH-1:0] addr_select,
	input logic [M_ID_WIDTH-1:0] MOSI_data_select,
	input logic [M_ID_WIDTH-1:0] valid_select,
	input logic [M_ID_WIDTH-1:0] last_select,
    input logic [S_ID_WIDTH-1:0] MISO_data_select,
	input logic [S_ID_WIDTH-1:0] ready_select,

    output logic ready,

    //masters
    input   logic [M_ID_WIDTH-1:0] control,
	input   logic [M_ID_WIDTH-1:0] wD,
	input   logic [M_ID_WIDTH-1:0] valid,
	input   logic [M_ID_WIDTH-1:0] last,
    output  logic [S_ID_WIDTH-1:0] rD,
	output  logic [S_ID_WIDTH-1:0] ready,

    //slaves
    output  logic [M_ID_WIDTH-1:0] control,
	output  logic [M_ID_WIDTH-1:0] wD,
	output  logic [M_ID_WIDTH-1:0] valid,
	output  logic [M_ID_WIDTH-1:0] last,
    input   logic [S_ID_WIDTH-1:0] rD,
	input   logic [S_ID_WIDTH-1:0] ready,
    );



endmodule
    