module top()(
    input logic CLOCK_50,
    input logic [3:0]KEY,
    output logic [17:0]LEDR,
    output logic [6:0]HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, HEX6, HEX7,
        
);

localparam SLAVE_COUNT=3;
localparam MASTER_COUNT=2;

logic rstN, clk;
assign rstN = KEY[0];
assign clk = CLOCK_50;

typedef enum logic [3:0]{
    master_slave_sel    = 4'd0,
    read_write_sel      = 4'd1,
    external_write_sel  = 4'd2,
    external_write_M1   = 4'd3,
    external_write_M1_2 = 4'd4,
    external_write_M2   = 4'd5,
    slave_addr_sel_M1   = 4'd6,
    slave_addr_sel_M2   = 4'd7,
    addr_count_sel_M1   = 4'd8,
    addr_count_sel_M2   = 4'd9,
    config_masters      = 4'd10,
    communication_ready = 4'd11,
    communication_done  = 4'd12
} state_t;

state_t current_state, next_state;

/////// state change logic /////////

always_ff @(posedge clk or negedge rstN) begin
    if (~rstN) begin
        current_state <= master_slave_sel;
    end
    else begin
        current_state <= next_state;
    end
end


always_comb begin
    next_state = current_state;

    case (current_state)
        master_slave_sel: begin
            if ()
        end



    endcase
end