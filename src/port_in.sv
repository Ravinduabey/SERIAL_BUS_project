// Code your design here
module port_in
(
    input logic read,
    input logic clk,
    output logic [1:0] id,
    output logic request,
    output logic [2:0] input_buf,
    output logic write,
    output logic mux,
    output logic com = 0
);

typedef enum logic [2:0] {
    START = 3'b000,
    ALLOCATION1 = 3'b001,
    ALLOCATION2 = 3'b010,
    ACK = 3'b011,
    COM = 3'b100,
    OVER = 3'b101
} state_t;

state_t state = START;

logic [1:0] bus_state = 0;

logic read_bit;
state_t next_state;


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
    endcase   
end

// always_comb begin : muxController
//   if(!bus_state or bus_state==1)
    
// end


always_ff @( posedge clk) begin : stateController
    state <= next_state;
    input_buf <= {input_buf[1:0], read};
end

always_ff @( posedge clk ) begin : stateLogic
  $display("state %b and input_buf %b", state, input_buf);
    unique case (state)

    START:
      if(input_buf == 3'b111) request <= 1; 

    ALLOCATION1 : 
    id <= input_buf[1:0];

    ALLOCATION2 : begin
    if (!bus_state && request) begin
      bus_state <= id;  //a comb to control muxes using bus_state
      write <= 1;
      request <= 0;
    end
    end

    ACK : begin
      if(input_buf == 3'b110) bus_state <= 0; //nak cycle is not optimal
      else if (input_buf == 3'b101) com <= 1; 
    end

    COM : if(input_buf[1:0] == 2'b01) com <= 0; //com state delay is not optimal

    OVER : write <= 0;
    endcase 
end

endmodule