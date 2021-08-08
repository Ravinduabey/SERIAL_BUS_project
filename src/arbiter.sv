module arbiter(
    input logic clk,
	input logic rstn,
    input logic m1_in,
	input logic m2_in,
	output logic m1_out,
	output logic m2_out,
	input logic ready,
	output logic addr_select,
	output logic MOSI_data,
	output logic MISO_data,
	output logic valid_select,
	output logic last_select,
	output logic [1:0] ready_select
);


endmodule : arbiter