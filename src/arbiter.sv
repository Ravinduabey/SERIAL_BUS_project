module arbiter(
  input logic clk,
	input logic rstn,

  input logic m1_in,
	output logic m1_out,

  input logic m2_in,
	output logic m2_out,

	input logic ready,

	output logic addr_select,
	output logic MOSI_data_select,
	output logic MISO_data_select,
	output logic valid_select,
	output logic last_select,
	output logic [1:0] ready_select
);

typedef enum logic [2:0] {
    START = 3'b000,
    ALLOCATION1 = 3'b001,
    ALLOCATION2 = 3'b010,
    ACK = 3'b011,
    COM = 3'b100,
    OVER = 3'b101,
    RST = 3'b110
} state_t;

logic [1:0] bus_state = 0;
state_t state = START;

logic [2:0] input_buf;
state_t next_state;
logic request;
logic [1:0] id;
logic com = 0;

always_comb begin : stateMachine
    unique case(state)

    START: begin
        if (request) next_state = ALLOCATION1;
        else next_state = START;
    end

    ALLOCATION1: next_state = ALLOCATION2;

    ALLOCATION2: next_state = ACK;

    ACK: begin
      if (!bus_state) next_state = START;
      else if (com) next_state = COM;
      else next_state <= ACK;
    end

    COM: begin 
      if (!com) next_state = OVER;
      else next_state = COM; 
	  end
	 
    OVER: next_state = START;

    RST: next_state = START;
    endcase   
end

// always_comb begin : muxController
//   if(!bus_state or bus_state==1)
    
// end


always_ff @(posedge clk or negedge rstn) begin : stateController
  if (!rstn) begin
    state <= RST;
  end
  else begin
    state <= next_state;
    input_buf <= {input_buf[1:0], m1_in};
  end
end

always_ff @( posedge clk ) begin : stateLogic
  $display("state %b and input_buf %b", state, input_buf);
    unique case (state)

    RST: bus_state <= 0;
    
    START:
      if(input_buf == 3'b111) request <= 1; 

    ALLOCATION1 : 
    id <= input_buf[1:0];

    ALLOCATION2 : begin
    if (!bus_state && request) begin
      bus_state <= id;  //a comb to control muxes using bus_state
      m1_out <= 1;
      request <= 0;
    end
    end

    ACK : begin
      if(input_buf == 3'b110) bus_state <= 0; //nak delay is not optimal
      else if (input_buf == 3'b101) com <= 1; 
    end

    COM : if(input_buf[1:0] == 2'b01) com <= 0; //delay is not optimal

    OVER : m1_out <= 0;
    endcase 
end
endmodule : arbiter