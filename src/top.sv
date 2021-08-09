module top(
    input logic CLOCK_50,
    input logic [3:0]KEY,
    output logic [17:0]LEDR,
    output logic [6:0]HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, HEX6, HEX7
        
);

localparam SLAVE_COUNT=3;  // number of slaves
localparam MASTER_COUNT=2; // number of masters
localparam DATA_WIDTH = 16; // width of a data word in slave & master

localparam SLAVE_DEPTHS[SLAVE_COUNT] = '{4096,4096,2048}; // give each slave's depth
localparam SLAVE_ADDR_WIDTHS[SLAVE_COUNT] = '{$clog2(SLAVE_DEPTHS[0]), $clog2(SLAVE_DEPTHS[1]), $clog2(SLAVE_DEPTHS[2])}
localparam MASTER_ADDR_WIDTH = SLAVE_ADDR_WIDTHS.max(); // master should be able to write or read all the slave address locations without loss



localparam MAX_MASTER_WRITE_DEPTH = 16;  // maximum number of addresses of a master that can be externally written

///////////// debouncing (start) //////////////
logic [3:0]KEY_OUT;

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
////////// debouncing (end) ////////////

logic rstN, clk, jump_stateN, jump_next_addr;

assign rstN = KEY_OUT[0];
assign jump_stateN = KEY_OUT[1];
assign jump_next_addr = KEY_OUT[2];
assign clk = CLOCK_50;

//////////////// TOP module & MASTER module wires and registers /////////////

logic M_burst, M_burst_next[0:MASTER_COUNT-1];
logic M_rdWr, M_rdWr_next[0:MASTER_COUNT-1];
logic M_inEx, M_inEx_next[0:MASTER_COUNT-1];
logic [DATA_WIDTH-1:0] M_data, M_data_next[0:MASTER_COUNT-1];
logic [MASTER_ADDR_WIDTH-1:0] M_address, M_address_next[0:MASTER_COUNT-1];
logic [$clog2(SLAVE_COUNT)-1:0] M_slaveId, M_slaveId_next[0:MASTER_COUNT];
logic M_start, M_start_next[0:MASTER_COUNT-1];

logic M_doneCom[0:MASTER_COUNT-1];
logic [DATA_WIDTH-1:0] M_dataOut[0:MASTER_COUNT-1];

logic M_read_write_sel, M_read_write_sel_next[0:MASTER_COUNT-1];
logic M_external_write_sel, M_exteral_write_sel_next[0:MASTER_COUNT-1];

logic [DATA_WIDTH-1:0]M_data_bank[0:MASTER_COUNT-1][0:MAX_MASTER_WRITE_DEPTH]; // used to store values to be written on masters' memories.
logic [$clog2(MAX_MASTER_WRITE_DEPTH)-1:0]current_data_bank_addr, next_data_bank_addr; // used to select a location in "M_data_bank"
logic [$clog2(MAX_MASTER_WRITE_DEPTH)-1:0]data_bank_wr_count, data_bank_wr_count_next[0:MASTER_COUNT-1];  

logic [MASTER_ADDR_WIDTH-1:0]slave_first_addr, slave_first_addr_next[0:MASTER_COUNT-1]; // slave R/W first addr
logic [MASTER_ADDR_WIDTH-1:0]slave_last_addr, slave_last_addr_next[0:MASTER_COUNT-1]; // slave R/W last addr (when burst R/W)

//////////////// MASTER module instantiate (start) /////////////
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
            .start(M_start[i]),

            .doneCom(M_doneCom[i]),
            .dataOut(M_dataOut[i])
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



always_ff @(posedge clk or negedge rstN) begin
    if (!rstN) begin
        current_state <= master_slave_sel;

        /////////// master related variables /////////
        M_burst     <= '{default:'0};
        M_rdWr      <= '{default:'0};
        M_inEx      <= '{default:'0};
        M_data      <= '{default:'0};
        M_address   <= '{default:'0}; 
        M_slaveId   <= '{default:'0}; 

        M_read_write_sel        <= '{default: '0};
        M_external_write_sel    <= '{default: '0};

        slave_first_addr <= '{default:'0};  
        slave_last_addr  <= '{default:'0};

    end
    else begin
        current_state <= next_state;

        //////// master related variables ///////////
        M_burst     <= M_burst_next;
        M_rdWr      <= M_rdWr_next;
        M_inEx      <= M_inEx_next;
        M_data      <= M_data_next;
        M_address   <= M_address_next; 
        M_slaveId   <= M_slaveId_next; 

        M_read_write_sel        <= M_read_write_sel_next;
        M_external_write_sel    <= M_exteral_write_sel_next;

        slave_first_addr <= slave_first_addr_next;
        slave_last_addr  <= slave_last_addr_next;

    end
end

//////// handle the memory "M_data_bank" //////////////
always_ff @(posedge clk) begin
    if (~rstN) begin
        current_data_bank_addr  <= '0;
        data_bank_wr_count      <= '{default:'0};
    end
    else begin
        current_data_bank_addr  <= next_data_bank_addr;
        data_bank_wr_count      <= data_bank_wr_count_next;

        if ((current_state == external_write_M1) | (current_state == external_write_M1_2)) begin
            M_data_bank[0][current_data_bank_addr] <= SW[DATA_WIDTH-1:0];
        end
        else if (current_state == external_write_M2) begin
            M_data_bank[1][current_data_bank_addr] <= SW[DATA_WIDTH-1:0];
        end
    end
end

/////// state change logic (start) /////////
always_comb begin
    next_state = current_state;

    case (current_state)
        master_slave_sel: begin
            if (!jump_stateN) begin
                next_state = read_write_sel;
            end
        end

        read_write_sel: begin
            if(!jump_stateN) begin
                if(SW[1:0] == 2'b00) begin
                    next_state = slave_addr_sel_M1;
                end
                else begin
                    next_state = external_write_sel;
                end
            end
        end

        external_write_sel: begin
            if (!jump_stateN) begin
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
            if (!jump_stateN) begin
                next_state = slave_addr_sel_M1;
            end
        end

        external_write_M1_2: begin
            if (!jump_stateN) begin
                next_state = external_write_M2;
            end       
        end

        external_write_M2: begin
            if (!jump_stateN) begin
                next_state = slave_addr_sel_M1;
            end        
        end

        slave_addr_sel_M1: begin
            if (!jump_stateN) begin
                next_state = slave_addr_sel_M2;
            end         
        end

        slave_addr_sel_M2: begin
            if (!jump_stateN) begin
                next_state = addr_count_sel_M1;
            end           
        end

        addr_count_sel_M1: begin
            if (!jump_stateN) begin
                next_state = addr_count_sel_M2;
            end          
        end

        addr_count_sel_M2: begin
            if (!jump_stateN) begin
                next_state = config_masters;
            end
        end

        config_masters: begin
            if (config_masters_done) begin
                next_state = communication_ready;
            end
        end

        communication_ready: begin
            if (!jump_stateN) begin
                next_state = communicating;
            end
        end

        communicating: begin
            if (M_doneCom == 2'b11) begin
                next_state = communication_done;
            end
        end

   endcase
end

/////// state change logic (end) /////////

/////// logic within the state ///////////
always_comb begin 
    
    M_burst_next     <= M_burst;
    M_rdWr_next      <= M_rdWr;
    M_inEx_next      <= M_inEx;
    M_data_next      <= M_data;
    M_slaveId_next   <= M_slaveId; 

    M_read_write_sel_next       <= M_read_write_sel;
    M_exteral_write_sel_next    <= M_external_write_sel;

    next_data_bank_addr = current_data_bank_addr;

    slave_first_addr_next <= slave_first_addr;
    slave_last_addr_next  <= slave_last_addr;

    case (current_state) 
        master_slave_sel: begin
            for (i=0;i<MASTER_COUNT;i++) begin
                M_slaveId_next[i] = SW[*(2*i+1) :- 2];
            end
        end   

        read_write_sel: begin 
            M_read_write_sel <= SW[MASTER_COUNT-1:0];
        end 

        external_write_sel: begin
            M_exteral_write_sel_next <= SW[MASTER_COUNT-1:0];          
        end 

        external_write_M1: begin
            if (!jump_stateN) begin
                next_data_bank_addr = '0; // reset to 0 for next master value write
            end
            else if (!jump_next_addr) begin
                next_data_bank_addr = current_data_bank_addr + 1'b1;  // go to the next address of the same master
                data_bank_wr_count_next[0] = data_bank_wr_count[0] + 1'b1; // count the number of external writes
            end
        end 

        external_write_M1_2: begin
            if (!jump_stateN) begin
                next_data_bank_addr = '0; // reset to 0 for next master value write
            end
            else if (!jump_next_addr) begin
                next_data_bank_addr = current_data_bank_addr + 1'b1;  // go to the next address of the same master
                data_bank_wr_count_next[0] = data_bank_wr_count[0] + 1'b1; // count the number of external writes
            end
        end

        external_write_M2: begin
            if (!jump_stateN) begin
                next_data_bank_addr = '0; // reset to 0 for next master value write
            end
            else if (!jump_next_addr) begin
                next_data_bank_addr = current_data_bank_addr + 1'b1;  // go to the next address of the same master
                data_bank_wr_count_next[1] = data_bank_wr_count[1] + 1'b1; // count the number of external writes
            end
        end  

        slave_addr_sel_M1: begin
            slave_first_addr_next[0] = SW[MASTER_ADDR_WIDTH-1:0];  // slave address width is less than or equal to master address width
        end

        slave_addr_sel_M2: begin
            slave_first_addr_next[1] = SW[MASTER_ADDR_WIDTH-1:0]; // slave address width is less than or equal to master address width
        end 
         
        addr_count_sel_M1: begin
            // decide burst or not
            if (Sw[MASTER_ADDR_WIDTH-1:0] == '0) begin
                M_burst_next[0] = 1'b0;
            end
            else begin
                M_burst_next[0] = 1'b1;
            end
            // calculate the last address
            if ((SW[MASTER_ADDR_WIDTH-1:0]+slave_first_addr[0]) >= SLAVE_DEPTHS[M_slaveId[0]-1]) begin
                slave_last_addr_next[0] = SLAVE_DEPTHS[M_slaveId[0]-1]; // if given length is too large select untill the last address of the slave
            end
            else begin
                slave_last_addr_next[0] = SW[MASTER_ADDR_WIDTH-1:0]+slave_first_addr[0];
            end
            
        end 

        addr_count_sel_M2: begin
            // decide burst or not
            if (Sw[MASTER_ADDR_WIDTH-1:0] == '0) begin
                M_burst_next[1] = 1'b0;
            end
            else begin
                M_burst_next[1] = 1'b1;
            end
            // calculate the last address
            if ((SW[MASTER_ADDR_WIDTH-1:0]+slave_first_addr[1]) >= SLAVE_DEPTHS[M_slaveId[1]-1]) begin
                slave_last_addr_next[1] = SLAVE_DEPTHS[M_slaveId[1]-1]; // if given length is too large select untill the last address of the slave
            end
            else begin
                slave_last_addr_next[1] = SW[MASTER_ADDR_WIDTH-1:0]+slave_first_addr[1];
            end
        end 

        config_masters: begin
            
        end 

        communication_ready: begin
            
        end

        communicating: begin // do nothing (in this state only the next state selection happens.)           
        end  

        communication_done: begin
            
        end   



    endcase
end

//////////////////// master configuration state related logics /////////////////

localparam CONFIG_CLK_COUNT = 2;
logic [$clog2(MASTER_COUNT)-1:0]current_config_master, next_config_master;
logic [$clog2(CONFIG_CLK_COUNT)-1:0]current_config_clk_count, next_config_clk_count;
logic [$clog2(MAX_MASTER_WRITE_DEPTH)-1:0]current_config_write_count, next_config_write_count;

typedef enum logic [2:0] {
    config_ready = 3'd0,
    config_start = 3'd1,
    config_middle = 3'd2,
    config_last = 3'd3,  // last stream of configuration
    config_done = 3'd4
} config_sub_state_t;

config_sub_state_t current_config_state, next_config_state;

always_ff @(posedge clk) begin
    if (~rstN) begin
        current_config_state        <= config_ready;
        current_config_master       <= '0;
        current_config_clk_count    <= '0;
        current_config_write_count  <= '0;

        M_start <= '{default: '0};
    end
    else begin
        current_config_state        <= next_config_state;
        current_config_master       <= next_config_master;
        current_config_clk_count    <= next_config_clk_count;
        current_config_write_count  <= next_config_write_count;

        M_start <= M_start_next;
    end
end


//////////////// master config substate change logic //////////////

always_comb begin
    next_config_state = current_config_state;

    case (current_config_state)

        config_ready: begin
            if (next_state == config_masters) begin  //***************** double check this ***********
                next_config_state = config_start;
            end
        end

        config_start: begin
            if (current_config_clk_count == CONFIG_CLK_COUNT-1) begin
                if (M_external_write_sel[current_config_master] == 1'b0) begin
                    next_config_state = config_last;
                end
                else begin
                    next_config_state = config_middle;
                end
            end
        end
        
        config_middle: begin
            if (current_config_clk_count == CONFIG_CLK_COUNT-1) begin
                if (current_config_write_count == data_bank_wr_count[current_config_master]) begin
                    next_state = config_last;
                end
            end
        end

        config_last: begin
            if (current_config_clk_count == CONFIG_CLK_COUNT-1) begin
                if (current_config_master == (MASTER_COUNT-1)) begin
                    next_config_state = config_done;
                end
                else begin
                    next_config_state = config_start;   // go back to first state to configure the next master
                end
            end
        end

        config_done: begin // do nothing and stay in this state
        end

        default: next_config_state = config_ready; // **************** not sure ***************************
    endcase
end


//////// logic within the master config sub states /////////////////////////

always_comb begin

    M_start_next = M_start;
    next_config_master = current_config_master
    next_config_clk_count = current_config_clk_count + 1'b1;
    
    case (current_config_state)

        config_ready: begin
            M_start_next = '{default:'0};
            if (next_config_state == config_start) begin   //***************** double check this ***********               
                M_start_next[current_config_master] = 1'b1;
                next_config_clk_count = '0;
            end             
        end

        config_start: begin
            M_start_next[current_config_master] = 1'b1;
            if (current_config_clk_count == CONFIG_CLK_COUNT-1) begin  // goes to next state 
                next_config_clk_count = '0;
                M_start_next[current_config_master] = 1'b0;
                M_data_next[current_config_master] = M_data_bank[current_config_master]['0];  // useful only when external write
            end               
        end

        config_middle: begin
            M_data_next[current_config_master] = M_data_bank[current_config_master][current_config_write_count];
            if (current_config_clk_count == CONFIG_CLK_COUNT-1) begin
                next_config_clk_count = '0;
                next_config_write_count = current_config_write_count + 1'b1;
                if (next_config_state == config_last) begin
                    M_start_next[current_config_master] = 1'b1;
                end
            end
        end

        config_last: begin
            if (current_config_clk_count == CONFIG_CLK_COUNT-1) begin
                next_config_clk_count = '0;
                M_start_next[current_config_master] = 1'b0;
            end

        end

        config_done: begin
            if (~jump_stateN) begin
                
            end            
        end


    endcase

end


endmodule : top