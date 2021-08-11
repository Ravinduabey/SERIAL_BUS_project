module arbiter(

  input logic clk,
  input logic rstN,

  //===================//
  //  master 0         //
  //===================// 
  input logic port0_in,
  output logic port0_out,
  
  //===================//
  //  master 1         //
  //===================// 
  input logic port1_in,
  output logic port1_out,
  output logic [2:0] bus_state,
  //===================//
  //    multiplexers   //
  //===================// 
	input logic ready,

	output logic addr_select,
	output logic MOSI_data_select,
	output logic [1:0] MISO_data_select,
	output logic valid_select,
	output logic last_select,
	output logic [1:0] ready_select
);

  logic [1:0] id0;
  logic [1:0] com0_state;
  logic done0;
  logic [1:0] cmd0;

  logic [1:0] id1;
  logic [1:0] com1_state;
  logic done1;
  logic [1:0] cmd1;

master_port #(.NO_SLAVES(3)) master0 (
  .clk(clk),
  .rstN(rstN),
  .port_in(port0_in),
  .port_out(port0_out),
  .cmd(cmd0),
  .id(id0),
  .com_state(com0_state),
  .done(done0)
);

master_port #(.NO_SLAVES(3)) master1 (
  .clk(clk),
  .rstN(rstN),
  .port_in(port1_in),
  .port_out(port1_out),
  .cmd(cmd1),
  .id(id1),
  .com_state(com1_state),
  .done(done1)
);

controller control_unit (.*);

endmodule : arbiter