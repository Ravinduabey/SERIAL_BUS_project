/*
    this intermediate module will connect each master with the controller. inside the arbiter this port will be communicating with controller. only essential commands are send to the controller. rest is taken care by the port
*/
module a_master_port # (
  parameter NO_SLAVES = 3,
  parameter S_ID_WIDTH = $clog2(NO_SLAVES+1)
)
(
    input logic clk,
    input logic rstN,

  //=============//
  // with master //
  //=============// 
    input logic port_in,
    output logic port_out,

  //===================//
  //   with controller //
  //===================// 
    input logic [1:0] cmd,
    output logic [S_ID_WIDTH-1:0] id,
    output logic [1:0] com_state,
    output logic done
);

  //=========================================//
  //   commands received from the controller //
  //=========================================// 
localparam CLEAR = 2'b11;
localparam STOP_S = 2'b01;
localparam STOP_P = 2'b10;

  //=============================================//
  //   com state commands send to the controller //
  //=============================================// 
localparam end_com = 2'b00;
localparam nak = 2'b01;
localparam wait_ack = 2'b10;
localparam com = 2'b11;

typedef enum logic [2:0] {
    RST,
    START,
    ALLOC1,
    ALLOC2,
    ACK, 
    COM,
    DONE
} state_t;

state_t state = START;
state_t next_state;

logic [S_ID_WIDTH:0] input_buf; //master in shift buffer
logic request;
logic old = '0;

///////////////////////////////
/// master write module      //
///////////////////////////////
localparam WIDTH = 3;
logic [WIDTH-1:0] write_val;
logic write;

a_write_buffer # (.WIDTH(WIDTH))
master_write(
  .clk(clk),
  .rstN(rstN),
  .din(write_val),
  .load(write),
  .dout(port_out)
);


always_comb begin : stateMachine

    write_val = '0;
    write = '0;
    unique case(state)

    RST: begin
      next_state = START; 
      //send 0
      write = '1;
    end

    START: begin 
        if (request) begin
          next_state = ALLOC1;
          //send 0
          write = '1;
        end
        else next_state = START;
    end

    ALLOC1: next_state = ALLOC2; 

    ALLOC2: begin 
      if (cmd==CLEAR && old) begin //split
        //send 100
        write_val = 3'b001;
        write = '1;
        next_state = ACK;
      end
      else if (cmd==CLEAR) begin 
        //send 110
        write_val = 3'b011;
        write = '1;
        next_state = ACK;
      end
      else begin
        next_state = ALLOC2;
      end
    end

    ACK: begin
      if (com_state == nak) next_state = START; 
      else if (com_state == com) begin
        next_state = COM; 
        //send 111
        write_val = 3'b111;
        write = 1;
      end
      else next_state = ACK; 
    end

    COM: begin 
      if (cmd==STOP_S) begin
        //send 010
        write_val = 3'b010;
        write = '1;
        next_state = DONE;
      end
      else if (cmd==STOP_P) begin
        //send 000  
        write = '1;
        next_state = DONE;
      end
      else if (com_state == end_com) begin
        //send 000
        write = '1;
        next_state = START; 
      end
      else begin
        next_state = COM;
      end
	  end

    DONE : begin
      if (done) next_state = ALLOC2;
      else next_state = DONE;
    end
	 
    endcase   
end

always_ff @(posedge clk or negedge rstN) begin : stateShifter

  if (!rstN) begin
    state <= RST;
    input_buf <= '0;
  end

  else begin
    state <= next_state;
    input_buf <= {input_buf[S_ID_WIDTH-1:0], port_in};
  end
end

always_ff @( posedge clk ) begin : stateLogicDecoder
  // $display("master state %s and input_buf %b", state, input_buf);
    unique case (state) 

    RST : begin
      request <= '0;
      id <= '0;
    end

    START : begin
      if (input_buf[S_ID_WIDTH:S_ID_WIDTH-2] == 3'b111) request <= '1; 
      else id <= '0;
    end
    

    ALLOC1 : begin
      id <= input_buf[S_ID_WIDTH-1:0];
      request <= '0;
	 end

    ALLOC2 : begin
      if (cmd==CLEAR) id <= '0; 
    end

    ACK : begin
      done <= '0;
      old <= '0;
      if (input_buf[2:0] == 3'b110) com_state <= nak; //nak
      else if (input_buf[2:0] == 3'b101) com_state <= com; //ack
      else com_state <= wait_ack; //waiting
    end

    COM : begin
      if (input_buf[1:0] == 2'b01) com_state <= end_com; //over
      else if (cmd==STOP_S) old <= 1; //stop[split]
	 end

    DONE : if (input_buf[2:0] == 3'b010) done <= '1;
	 
    endcase 
end

endmodule : a_master_port
