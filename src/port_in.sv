// Code your design here
module port_in
(
    input logic read,
    input logic clk,
    output logic [1:0] id = 2'b0,
    output logic request=0,
    output logic [2:0] input_buf  
);

typedef enum logic [1:0] {
    START = 2'b00,
    ALLOCATION = 2'b01,
    NEXT = 2'b10
} state_t;

// logic [2:0] start = 3'b111;
state_t state = START;

logic read_bit;
state_t next_state;


always_comb begin
    unique case(state)
    START: begin
        if (request) 
            next_state = ALLOCATION;
        else 
            next_state = START;
    end
    ALLOCATION: begin
        if (request) //
            next_state = NEXT;
        else 
            next_state = ALLOCATION;
    end   
    NEXT: begin
            next_state = NEXT;
    end
    endcase   
end

always_ff @( posedge clk) begin
    state <= next_state;
    input_buf <= {input_buf[1:0], read};
end


always_ff @( posedge clk ) begin 
  $display("state %b and ID %b", state, id);
    unique case (state)
    START: begin
      if(input_buf == 3'b111) request <= 1;
    end
    ALLOCATION : begin
      id <= input_buf[1:0];
    end
    NEXT : begin
      request <= 0;
    end

    endcase 
end

endmodule