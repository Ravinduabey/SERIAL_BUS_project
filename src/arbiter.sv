module arbiter #(
    parameter NO_MASTERS = 2,
    parameter NO_SLAVES = 3,
    parameter S_ID_WIDTH = $clog2(NO_SLAVES+1),
    parameter M_ID_WIDTH = $clog2(NO_MASTERS)
)(

  input logic clk,
  input logic rstN,
  
  //===================//
  //  masters         //
  //===================// 
  input logic port_in [NO_MASTERS-1:0],
  output logic port_out [NO_MASTERS-1:0],
  output logic [S_ID_WIDTH+M_ID_WIDTH-1:0] bus_state,

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

  logic [S_ID_WIDTH-1:0] id [NO_MASTERS-1:0];
  logic [1:0] com_state [NO_MASTERS-1:0];
  logic done [NO_MASTERS-1:0];
  logic [1:0] cmd [NO_MASTERS-1:0];

  genvar i;
  generate
    for (i = '0; i< NO_MASTERS; i = i+1) begin : master
    master_port #(.NO_SLAVES(NO_SLAVES)) master_interconnector (
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

controller control_unit (.*);

endmodule : arbiter