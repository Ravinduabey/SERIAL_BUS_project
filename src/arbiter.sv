module arbiter(

  input logic clk,
	input logic rstn,

  //===================//
  //  master 1    //
  //===================// 
  input logic m1_in,
	output logic m1_out,
  output logic com_m1 = 0,

  //===================//
  //  master 2    //
  //===================// 
  input logic m2_in,
	output logic m2_out,
  output logic com_m2 = 0,
  
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

typedef enum logic [3:0] {
    RST,
    START,
    ALLOCATION1,
    ALLOCATION2,
    ACK1,
    ACK2,
    COM1,
    COM2,
    OVER1,
    OVER2
} state_t;

logic [3:0] bus_state = 0;
state_t state = START;
state_t next_state;

logic [2:0] input_buf_m1;
logic request_m1;
logic [1:0] id_m1;
// logic com_m1 = 0;

logic [2:0] input_buf_m2;
logic request_m2;
logic [1:0] id_m2;
// logic com_m2 = 0;

always_comb begin : stateMachine
    unique case(state)

    START: begin
        if (request_m1 || request_m2) next_state = ALLOCATION1;
        else next_state = START;
    end

    ALLOCATION1: next_state = ALLOCATION2;

    ALLOCATION2: begin
      if (m1_out) next_state = ACK1;
      else if (m2_out) next_state = ACK2;
      else next_state = ALLOCATION2;
    end

    ACK1: begin
      if (!bus_state) next_state = START;
      else if (com_m1) next_state = COM1;
      else next_state <= ACK1;
    end
  
    ACK2: begin
      if (!bus_state) next_state = START;
      else if (com_m2) next_state = COM2;
      else next_state <= ACK2;
    end

    COM1: begin 
      if (!com_m1) next_state = OVER1;
      else next_state = COM1; 
	  end

    COM2: begin 
      if (!com_m2) next_state = OVER2;
      else next_state = COM2; 
	  end

    OVER1: next_state = START;

    OVER2: next_state = START;

    RST: next_state = START;
    endcase   
end

always_comb begin : muxController
  addr_select = bus_state[3];
	MOSI_data_select = bus_state[3];
	valid_select = bus_state[3];
	last_select = bus_state[3];
  MISO_data_select = bus_state[1:0];
	ready_select = bus_state[1:0];
end


always_ff @(posedge clk or negedge rstn) begin : stateShifter

  if (!rstn) begin
    state <= RST;
    input_buf_m1 <= 0;
    input_buf_m2 <= 0;
  end

  else begin
    state <= next_state;
    input_buf_m1 <= {input_buf_m1[1:0], m1_in};
    input_buf_m2 <= {input_buf_m2[1:0], m2_in};
  end
end

always_ff @( posedge clk ) begin : stateLogicDecoder
  $display("state %s and input_buf_m1 %b and input_buf_m2 %b", state, input_buf_m1, input_buf_m2);
    unique case (state)

    RST : bus_state <= 0;

    START : begin
      if(input_buf_m1 == 3'b111) request_m1 <= 1; 
      if(input_buf_m2 == 3'b111) request_m2 <= 1; 
    end

    ALLOCATION1 : begin
    id_m1 <= input_buf_m1[1:0];
    id_m2 <= input_buf_m2[1:0];
    end

    ALLOCATION2 : begin
    if (!bus_state && request_m1) begin
      bus_state <= {2'b01, id_m1};  //a comb to control muxes using bus_state
      m1_out <= 1; //clear[new] signal
    end
    else if (!bus_state && request_m2) begin
      bus_state <= {2'b10, id_m2};  //a comb to control muxes using bus_state
      m2_out <= 1; //clear[new] signal 
    end
    request_m2 <= 0;
    request_m1 <= 0;
    end

    ACK1 : begin
      if(input_buf_m1 == 3'b110) bus_state <= 0; //nak delay is not optimal
      else if (input_buf_m1 == 3'b101) com_m1 <= 1; 
    end

    ACK2 : begin
      if(input_buf_m2 == 3'b110) bus_state <= 0; //nak delay is not optimal
      else if (input_buf_m2 == 3'b101) com_m2 <= 1; 
    end

    COM1 : if(input_buf_m1[1:0] == 2'b01) com_m1 <= 0; //delay is not optimal

    COM2 : if(input_buf_m2[1:0] == 2'b01) com_m2 <= 0; //delay is not optimal

    OVER1 : begin
      m1_out <= 0;
      bus_state <= 0;
    end

    OVER2 : begin 
      m2_out <= 0;
      bus_state <= 0;
    end

    endcase 
end
endmodule : arbiter