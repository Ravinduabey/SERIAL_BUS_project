module controller(

  input logic clk,
	input logic rstN,

  //===================//
  //      master 0     //
  //===================// 
  input logic [1:0] id0,
	input logic [1:0] com0_state,
  input logic done0,
  output logic [1:0] cmd0,

  //===================//
  //      master 1     //
  //===================// 
  input logic [1:0] id1,
	input logic [1:0] com1_state,
  input logic done1,
  output logic [1:0] cmd1,
  
  //===================//
  //    multiplexers   //
  //===================// 
	input logic ready,

  output logic [2:0] bus_state = 0,
	output logic addr_select,
	output logic MOSI_data_select,
	output logic [1:0] MISO_data_select,
	output logic valid_select,
	output logic last_select,
	output logic [1:0] ready_select
);

typedef enum logic [3:0] {
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

logic interrupt = 0;

logic [1:0] com_state;
logic done, thresh;
logic [1:0] cmd;
logic cur_master, nxt_master, old_master;
logic [1:0] cur_slave, nxt_slave, old_slave;

localparam WAIT = 2'b00;
localparam STOP_S = 2'b01;
localparam STOP_P = 2'b10;
localparam CLEAR = 2'b11;

localparam end_com = 2'b00;
localparam nak = 2'b01;
localparam wait_ack = 2'b10;
localparam com = 2'b11;

////////////////////////////////
////    internal modules    ////
////////////////////////////////
demux #(.DATA_WIDTH(2)) cmd_port_select (
  .din(cmd),
  .select(cur_master),
  .dout0(cmd0),
  .dout1(cmd1)
);

mux #(.DATA_WIDTH(2)) com_port_select (
  .dina(com0_state),
  .dinb(com1_state),
  .select(cur_master),
  .dout(com_state)
);

mux #(.DATA_WIDTH(1)) done_port_select (
  .dina(done0),
  .dinb(done1),
  .select(cur_master),
  .dout(done)
);

thresh_counter #(.THRESH(100)) thresh_cnt (.*);

always_comb begin : stateMachine
    unique case(state)

    RST: next_state = START;

    START: begin
        if(id0 || id1) next_state = ALLOC;
        else next_state = START;
    end

    ALLOC: next_state = ACK;

    ACK: begin
      if (com_state == nak) next_state = OVER;
      else if (com_state == com) next_state = COM;
      else next_state <= ACK;
    end

    COM: begin 
      if(com_state == end_com) next_state = OVER;
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

////////////////////////
//// external muxes ////
///////////////////////
always_comb begin : muxController
  addr_select = bus_state[2];
	MOSI_data_select = bus_state[2];
	valid_select = bus_state[2];
	last_select = bus_state[2];
  MISO_data_select = bus_state[1:0];
	ready_select = bus_state[1:0];
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
      bus_state <= 0;
      interrupt <= 0;
    end

    START : begin
      //there should be an efficient way to do this
      if(id0 || id1) begin
        if (id0) begin
          cur_master <= 0;
          cur_slave <= id0;
        end
      else if (id1) begin
          cur_master <= 1;
          cur_slave <= id1;
        end
      end
    end

    ALLOC : begin
        cmd <= CLEAR;
    end

    ACK : begin
      $display("com0 state %b, com state %b", com0_state, com_state);
      if(com_state == nak) bus_state <= 0;  //nak
      else if (com_state == com) begin //ack
        bus_state <= {cur_master, cur_slave};  
      end
    end

    COM : begin
      if(com_state == end_com) bus_state <= 0;
      /////////////////////////////////////////////////
    /// split and priority need to add in an efficient way////
    end

    OVER : begin
      if(interrupt) begin
        interrupt <= 0;
      end
      cmd <= WAIT;
    end

    endcase 
end

endmodule : controller