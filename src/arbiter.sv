/*
    the top module of the arbiter which connects all the master ports 
    with the central controller
*/ 
module arbiter import a_definitions::*; #(
    parameter NO_MASTERS = 2,
    parameter NO_SLAVES = 3,
    parameter THRESH = 10000000, 
    parameter S_ID_WIDTH = $clog2(NO_SLAVES+1),
    parameter M_ID_WIDTH = $clog2(NO_MASTERS)
)(

  input logic clk,
  input logic rstN,
  
  //============//
  //  masters   //
  //============// 
  input logic port_in [0:NO_MASTERS-1],
  output logic port_out [0:NO_MASTERS-1],

  //===================//
  //    multiplexers   //
  //===================// 
	input logic ready,

  output logic [S_ID_WIDTH+M_ID_WIDTH-1:0] bus_state
);

  //===============================================//
  //    wires between master ports and controller  //
  //===============================================// 
  logic [S_ID_WIDTH-1:0] id [0:NO_MASTERS-1];
  mst_cmd_t com_state [0:NO_MASTERS-1];
  logic done [0:NO_MASTERS-1];
  ctrl_cmd_t cmd [0:NO_MASTERS-1];

  //=============================//
  //    master ports generator   //
  //=============================// 
  genvar ii;
  generate
    for (ii = '0; ii< NO_MASTERS; ii = ii+1) begin : master
    a_master_port #(
      .NO_SLAVES(NO_SLAVES)
      ) master_interconnector (
      .clk(clk),
      .rstN(rstN),
      .port_in(port_in[ii]),
      .port_out(port_out[ii]),
      .cmd(cmd[ii]),
      .id(id[ii]),
      .com_state(com_state[ii]),
      .done(done[ii])
    );
    end
endgenerate

  //===================//
  //    controller     //
  //===================// 
a_controller #(
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
  .bus_state(bus_state)
);

endmodule : arbiter