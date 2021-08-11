module controller #(
    parameter NO_MASTERS = 2,
    parameter NO_SLAVES = 3,
    parameter THRESH = 1000,
    parameter S_ID_WIDTH = $clog2(NO_SLAVES+1), //2
    parameter M_ID_WIDTH = $clog2(NO_MASTERS) //1
)(

  input logic clk,
	input logic rstN,

  //===================//
  //      masters      //
  //===================// 

  input logic [S_ID_WIDTH-1:0] id [NO_MASTERS-1:0],
  input logic [1:0] com_state [NO_MASTERS-1:0],
  input logic done [NO_MASTERS-1:0],
  output logic [1:0] cmd [NO_MASTERS-1:0],
  
  //===================//
  //    multiplexers   //
  //===================// 
	input logic ready,

	output logic [M_ID_WIDTH-1:0] addr_select,
	output logic [M_ID_WIDTH-1:0] MOSI_data_select,
	output logic [M_ID_WIDTH-1:0] valid_select,
	output logic [M_ID_WIDTH-1:0] last_select,
  output logic [S_ID_WIDTH-1:0] MISO_data_select,
	output logic [S_ID_WIDTH-1:0] ready_select,

  output logic [S_ID_WIDTH+M_ID_WIDTH-1:0] bus_state = '0
);

localparam WAIT = 2'b00;
localparam STOP_S = 2'b01;
localparam STOP_P = 2'b10;
localparam CLEAR = 2'b11;

localparam end_com = 2'b00;
localparam nak = 2'b01;
localparam wait_ack = 2'b10;
localparam com = 2'b11;

typedef enum logic [2:0] {
    RST,
    START,
    ALLOC,
    ACK,
    COM,
    DONE,
    OVER
} state_t;

state_t state = START;
state_t next_state;

logic interrupt = '0;

logic [1:0] cur_com_state;
logic cur_done, thresh;
logic [1:0] cur_cmd;

logic [M_ID_WIDTH-1:0] cur_master = '0;
logic [M_ID_WIDTH-1:0] nxt_master, old_master;
logic [S_ID_WIDTH-1:0] cur_slave = '0;
logic [S_ID_WIDTH-1:0] nxt_slave, old_slave;

////////////////////////////////
////    internal modules    ////
////////////////////////////////
// demux #(.DATA_WIDTH(2)) cmd_port_select (
//   .din(cur_cmd),
//   .select(cur_master),
//   .dout0(cmd[0]),
//   .dout1(cmd[1])
// );

always_comb begin 
    cmd = '{NO_MASTERS{'0}};
    cmd[cur_master] = cur_cmd; 
end

assign cur_com_state = com_state[cur_master];

assign cur_done = done[cur_master];

thresh_counter #(.THRESH(THRESH)) thresh_cnt (.*);

////////////////////////
//// external muxes ////
///////////////////////

always_comb begin : muxController
  addr_select = bus_state [S_ID_WIDTH+M_ID_WIDTH-1:S_ID_WIDTH];
	MOSI_data_select = bus_state [S_ID_WIDTH+M_ID_WIDTH-1:S_ID_WIDTH];
	valid_select = bus_state [S_ID_WIDTH+M_ID_WIDTH-1:S_ID_WIDTH];
	last_select = bus_state [S_ID_WIDTH+M_ID_WIDTH-1:S_ID_WIDTH];
  MISO_data_select = bus_state[S_ID_WIDTH-1:0];
	ready_select = bus_state[S_ID_WIDTH-1:0];
end

always_comb begin : stateMachine
    unique case(state)

    RST: next_state = START;

    START: begin
        if(id[0] || id[1]) next_state = ALLOC;
        else next_state = START;
    end

    ALLOC: next_state = ACK;

    ACK: begin
      if (cur_com_state == nak) next_state = OVER;
      else if (cur_com_state == com) next_state = COM;
      else next_state <= ACK;
    end

    COM: begin 
      if(cur_com_state == end_com) next_state = OVER;
      else if (interrupt) next_state = DONE;
      else next_state = COM; 
	  end

    //DONE: 

    OVER: begin
      if(interrupt) next_state = ALLOC;
      else next_state = START;
	 end

    endcase   
end

always_ff @(posedge clk or negedge rstN) begin : stateShifter

  if (!rstN) begin
    state <= RST;
  end

  else begin
    state <= next_state;
  end
end

always_ff @( posedge clk ) begin : stateLogicDecoder
  $display("controller state %s, CM %b, CS %b, bus %b", state, cur_master, cur_slave, bus_state);
    unique case (state)

    RST : begin 
      bus_state <= '0;
      interrupt <= '0;
      cur_slave <= '0;
      cur_master <= '0;
    end

    START : begin
      //there should be an efficient way to do this
      if(id[0] || id[1]) begin
        if (id[0]) begin
          cur_master <= '0;
          cur_slave <= id[0];
        end
      else if (id[1]) begin
          cur_master <= '1;
          cur_slave <= id[1];
        end
      end
    end

    ALLOC : begin
        cur_cmd <= CLEAR;
    end

    ACK : begin
      $display("com0 state %b, com state %b", com_state[0], com_state[1]);
      if(cur_com_state == nak) bus_state <= '0;  //nak
      else if (cur_com_state == com) begin //ack
        bus_state <= {cur_master, cur_slave};  
      end
    end

    COM : begin
      if(cur_com_state == end_com) bus_state <= 0;
      /////////////////////////////////////////////////
    /// split and priority need to add in an efficient way////
    end

	 //DONE
	 
    OVER : begin
      if(interrupt) begin
        interrupt <= 0;
      end
      cur_cmd <= WAIT;
    end

    endcase 
end

endmodule : controller