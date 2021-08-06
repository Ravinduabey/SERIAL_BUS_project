module top(
    input logic CLOCK_50,
    input logic [3:0]KEY,
    output logic [17:0]LEDR,
    output logic [6:0]HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, HEX6, HEX7
        
);

localparam SLAVE_COUNT=3;
localparam MASTER_COUNT=2;
localparam DATA_WIDTH = 16;
logic MASTER_DEPTHS[MASTER_COUNT] = '{4096,4096};   // give each master's depth
logic SLAVE_DEPTHS[SLAVE_COUNT] = '{4096,4096,2048}; // give each slave's depth

logic MASTER_ADDR_WIDTHS[MASTER_COUNT] = '{$log2(MASTER_DEPTHS[0]), $clog2(MASTER_DEPTHS[1])};  // ***** find a better method ************
logic SLAVE_ADDR_WIDTHS[SLAVE_COUNT] = '{$clog2(SLAVE_DEPTHS[0]), $clog2(SLAVE_DEPTHS[1]), $clog2(SLAVE_DEPTHS[2])}

// localparam MASTER_ADDR_WIDTHS[0:MASTER_COUNT] = master_addr_width_calc(MASTER_DEPTHS); //****************

// function int master_addr_width_calc // *******************************************



logic [3:0]KEY_OUT;
///////////// debouncing //////////////
localparam TIME_DELAY = 500 // time delay for debouncing in ms
genvar i = 0;
generate
    for (i=0;i<4;i++) begin: debouncing
        debouncer #(.TIME_DELAY(TIME_DELAY))(
            .clk(clk),
            .value_in(KEY[i]),
            .value_out(KEY_OUT[i])
        );
    end
endgenerate
////////// debouncing ////////////

logic rstN, clk, jump_stateN;

assign rstN = KEY_OUT[0];
assign jump_stateN = KEY_OUT[1];
assign clk = CLOCK_50;

//////////////// MASTER module instantiate (start) /////////////

logic M_burst[0:MASTER_COUNT-1];
logic M_rdWr[0:MASTER_COUNT-1];
logic M_inEx[0:MASTER_COUNT-1];
logic [DATA_WIDTH-1:0] M_data[0:MASTER_COUNT-1];
logic [ADDRESS_DEPTH-1:0] M_address[0:MASTER_COUNT-1];
logic [ADDRESS_DEPTH-1:0] M_slaveId[0:MASTER_COUNT];
logic M_start;

logic M_doneCom = 1'b0,
logic [DATA_WIDTH-1:0] M_dataOut,

genvar j;
generate
    for (j=0;j<MASTER_COUNT; j++) begin:MASTER
        master #(.ADDRESS_DEPTH(MASTER_DEPTHS[j], .DATA_WIDTH(DATA_WIDTH)) master(
            .clk, rstN, 
            .burst(M_burst[i]),
            .rdWr(M_rdWr[i]),                           
            .inEx(M_inEx[i]),                           
            .data(M_data[i]),
            .address(M_address[i]),
            .slaveId(M_slaveId[i]),
            .start(M_start)
        );
    end
endgenerate
//////////////// MASTER module instantiate (end) /////////////

/////////// states //////////////////
typedef enum logic [3:0]{
    master_slave_sel    = 4'd0,     // state - 0
    read_write_sel      = 4'd1,     // state - 1
    external_write_sel  = 4'd2,     // state - 1.5 
    external_write_M1   = 4'd3,     // state - 1.51
    external_write_M1_2 = 4'd4,     // state - 1.52
    external_write_M2   = 4'd5,     // state - 1.53
    slave_addr_sel_M1   = 4'd6,     // state - 2
    slave_addr_sel_M2   = 4'd7,     // state - 3
    addr_count_sel_M1   = 4'd8,     // state - 4
    addr_count_sel_M2   = 4'd9,     // state - 5
    config_masters      = 4'd10,    // state - 6    
    communication_ready = 4'd11,    // state - 6.5    
    communicating       = 4'd12,    // state - 7
    communication_done  = 4'd13     // state - 8
} state_t;

state_t current_state, next_state;

logic config_masters_done = 0;

/////// state change logic (start) /////////

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
            if (~jump_stateN) begin
                next_state = read_write_sel;
            end
        end

        read_write_sel: begin
            if(~jump_stateN) begin
                if(SW[1:0] == 2'b00) begin
                    next_state = slave_addr_sel_M1;
                end
                else begin
                    next_state = external_write_sel;
                end
            end
        end

        external_write_sel: begin
            if (~jump_stateN) begin
                case (SW[1:0])
                    2'b00: next_state = slave_addr_sel_M1;
                    2'b01: next_state = external_write_M1;
                    2'b10: next_state = external_write_M2;
                    2'b11: next_state = external_write_M1_2;

                    default: next_state = slave_addr_sel_M1;  // not required as all cases are included

                endcase
            end
            

        end

        external_write_M1: begin
            if (~jump_stateN) begin
                next_state = slave_addr_sel_M1;
            end
        end

        external_write_M1_2: begin
            if (~jump_stateN) begin
                next_state = external_write_M2;
            end           
        end

        external_write_M2: begin
            if (~jump_stateN) begin
                next_state = slave_addr_sel_M1;
            end        
        end

        slave_addr_sel_M1: begin
            if (~jump_stateN) begin
                next_state = slave_addr_sel_M2;
            end           
        end

        slave_addr_sel_M2: begin
            if (~jump_stateN) begin
                next_state = addr_count_sel_M1;
            end           
        end

        addr_count_sel_M1: begin
            if (~jump_stateN) begin
                next_state = addr_count_sel_M2;
            end          
        end

        addr_count_sel_M2: begin
            if (~jump_stateN) begin
                next_state = config_masters;
            end
        end

        config_masters: begin
            if (config_masters_done) begin
                next_state = communication_ready;
            end
        end

        communication_ready: begin
            if (~jump_stateN) begin
                next_state = communicating;
            end
        end

        communicating: begin
            if (commu)
        end

   endcase
end

/////// state change logic (end) /////////



endmodule : top