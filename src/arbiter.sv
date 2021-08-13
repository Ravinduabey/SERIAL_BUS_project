/*
    the top module of the arbiter which connects all the master ports with the central controller
*/ 
module arbiter #(
    parameter NO_MASTERS = 2,
    parameter NO_SLAVES = 3,
    parameter THRESH = 1000, 
    parameter S_ID_WIDTH = $clog2(NO_SLAVES+1),
    parameter M_ID_WIDTH = $clog2(NO_MASTERS)
)(

  input logic clk,
  input logic rstN,
  
  //============//
  //  masters   //
  //============// 
  input logic port_in [NO_MASTERS-1:0],
  output logic port_out [NO_MASTERS-1:0],

  //===================//
  //    multiplexers   //
  //===================// 
	input logic ready,

	output logic [M_ID_WIDTH-1:0] addr_select,
	output logic [M_ID_WIDTH-1:0] MOSI_data_select,
	output logic [M_ID_WIDTH-1:0] valid_select,
	output logic [M_ID_WIDTH-1:0] last_select,
  output logic [S_ID_WIDTH-1:0] MISO_data_select,
	output logic [S_ID_WIDTH-1:0] ready_select
);

  //===============================================//
  //    wires between master ports and controller  //
  //===============================================// 
  logic [S_ID_WIDTH-1:0] id [NO_MASTERS-1:0];
  logic [1:0] com_state [NO_MASTERS-1:0];
  logic done [NO_MASTERS-1:0];
  logic [1:0] cmd [NO_MASTERS-1:0];

  //=============================//
  //    master ports generator   //
  //=============================// 
  genvar i;
  generate
    for (i = '0; i< NO_MASTERS; i = i+1) begin : master
    master_port #(
      .NO_SLAVES(NO_SLAVES)
      ) master_interconnector (
      .clk(clk),
      .rstN(rstN),
      .port_in(port_in[i]),
      .port_out(port_out[i]),
      .cmd(cmd[i]),
      .id(id[i]),
      .com_state(com_state[i]),
      .done(done[i])
    );
    end
endgenerate

  //===================//
  //    controller     //
  //===================// 
controller #(
  .NO_MASTERS(NO_MASTERS),
  .NO_SLAVES(NO_SLAVES),
  .THRESH(THRESH)
  )control_unit(
  .clk(clk),
  .rstN(rstN),
  .id(id),
  .com_state(com_state),
  .done(done),
  .cmd(cmd),
  .ready(ready),
  .addr_select(addr_select),
  .MOSI_data_select(MOSI_data_select),
  .valid_select(valid_select),
  .last_select(last_select),
  .MISO_data_select(MISO_data_select),
  .ready_select(ready_select)
);

endmodule : arbiter