/*
    this module is the central arbiter controller module who controls the bus depending on the requests comes from any number of masters. 
*/
module a_controller #(
    parameter NO_MASTERS = 2,
    parameter NO_SLAVES = 3,
    parameter THRESH = 1000,
    parameter S_ID_WIDTH = $clog2(NO_SLAVES+1), //2
    parameter M_ID_WIDTH = $clog2(NO_MASTERS) //1
)(

  input logic clk,
  input logic rstN,

  //==========//
  //  master  //
  //==========// 

  input logic [S_ID_WIDTH-1:0] id [0:NO_MASTERS-1],
  input logic [1:0] com_state [0:NO_MASTERS-1],
  input logic done [0:NO_MASTERS-1],
  output logic [1:0] cmd [0:NO_MASTERS-1],
  
  //================================//
  //    external bus multiplexers   //
  //================================// 
	input logic ready,

  output logic [S_ID_WIDTH+M_ID_WIDTH-1:0] bus_state = '0
	// output logic [M_ID_WIDTH-1:0] addr_select,
	// output logic [M_ID_WIDTH-1:0] MOSI_data_select,
	// output logic [M_ID_WIDTH-1:0] valid_select,
	// output logic [M_ID_WIDTH-1:0] last_select,
  // output logic [S_ID_WIDTH-1:0] MISO_data_select,
	// output logic [S_ID_WIDTH-1:0] ready_select
);

  //===========================================//
  //commands given to the selected master port //
  //===========================================// 
localparam WAIT = 2'b00;
localparam STOP_S = 2'b01;
localparam STOP_P = 2'b10;
localparam CLEAR = 2'b11;

  //==========================================================//
  //com state commands received from the selected master port //
  //==========================================================// 
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

//this register is used for external multiplexer selection input
// logic [S_ID_WIDTH+M_ID_WIDTH-1:0] bus_state = '0;

//these registers trigger when interrupts occur
logic intr = '0;
logic intr_route = '0;


  ////////////////////////////////
  //      internal modules      //
  ////////////////////////////////

logic thresh;
a_thresh_counter #(.THRESH(THRESH)) thresh_detector (.*);


localparam NRML = 1'b0;
localparam STOP = 1'b1;
logic priority_state = NRML;
logic request;

//cur_master will select the master port with whom the controller communicates at a given time
logic [M_ID_WIDTH-1:0] cur_master = '0;
logic [M_ID_WIDTH-1:0] next_master, old_master, master_out;
logic [S_ID_WIDTH-1:0] cur_slave = '0;
logic [S_ID_WIDTH-1:0] next_slave, old_slave, slave_out;

a_priority_selector #(
  .NO_MASTERS(NO_MASTERS),
  .NO_SLAVES(NO_SLAVES)
  ) master_selector (
    .state(priority_state),
    .master_in(cur_master),
    .slave_in(cur_slave),
    .thresh(thresh),
    .slave_id(id),
    .master_out(master_out),
    .slave_out(slave_out),
    .request(request)
); 


  ////////////////////////////////
  //    internal mux/demux      //
  ////////////////////////////////

//demux
logic [1:0] cur_cmd;
always_comb begin 
    cmd = '{NO_MASTERS{'0}};
    cmd[cur_master] = cur_cmd; 
end

//mux
logic [1:0] cur_com_state;
assign cur_com_state = com_state[cur_master];

//mux
logic cur_done;
assign cur_done = done[cur_master];


////////////////////////////////
//   external mux selection   //
////////////////////////////////

// always_comb begin : muxController
  // addr_select       = bus_state [S_ID_WIDTH+M_ID_WIDTH-1:S_ID_WIDTH];
	// MOSI_data_select  = bus_state [S_ID_WIDTH+M_ID_WIDTH-1:S_ID_WIDTH];
	// valid_select      = bus_state [S_ID_WIDTH+M_ID_WIDTH-1:S_ID_WIDTH];
	// last_select       = bus_state [S_ID_WIDTH+M_ID_WIDTH-1:S_ID_WIDTH];
  // MISO_data_select  = bus_state [S_ID_WIDTH-1:0];
	// ready_select      = bus_state [S_ID_WIDTH-1:0];
// end


always_comb begin : stateMachine
    unique case(state)

    RST: next_state = START;

    START: begin
        if(request) next_state = ALLOC;
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
      else if (intr && !intr_route) next_state = DONE;
      else next_state = COM; 
	  end

    DONE: begin
      if (cur_done) next_state = ALLOC;
      else next_state = DONE;
    end 

    OVER: begin
      if(intr) next_state = ALLOC;
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
      intr <= '0;
      cur_slave <= '0;
      cur_master <= '0;
      intr_route <= '0;
      priority_state <= NRML;
    end

    START : begin
      if (request) begin
        cur_master <= master_out;
        cur_slave <= slave_out;
      end
    end

    ALLOC : begin
        cur_cmd <= CLEAR;
    end

    ACK : begin
      // $display("com0 state %b, com state %b", com_state[0], com_state[1]);
      if(cur_com_state == nak) bus_state <= '0;  //nak
      else if (cur_com_state == com) begin //ack
        bus_state <= {cur_master, cur_slave}; 
        priority_state = STOP; 
      end
    end

    COM : begin
      if(cur_com_state == end_com) bus_state <= '0;
      else if(request && !intr && (cur_master != master_out)) begin //interrupt
          next_master <= master_out;
          next_slave <= slave_out;
          old_master <= cur_master;
          old_slave <= cur_slave;
          intr <= '1;
          bus_state <= '0;
          if (thresh) cur_cmd <= STOP_S;
          else cur_cmd <= STOP_P;
      end
    end

	 DONE : begin
     if (cur_done) begin
       intr_route <= '1;
       cur_master <= next_master;
       cur_slave <= next_slave;
     end
   end
	 
    
   OVER : begin
      if(intr) begin
        intr <= '0;
        intr_route <= '0;
        cur_master <= old_master;
        cur_slave <= old_slave;
      end
      else begin
        priority_state <= NRML;
        cur_cmd <= WAIT;
      end  
    end
    endcase 
end

endmodule : a_controller