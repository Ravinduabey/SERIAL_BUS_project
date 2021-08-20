module top import details::*;
#(
    parameter SLAVE_COUNT=3,  // number of slaves
    parameter MASTER_COUNT=2,  // number of masters
    parameter DATA_WIDTH = 16,   // width of a data word in slave & master
    parameter int SLAVE_DEPTHS[SLAVE_COUNT] = '{4096,4096,2048}, // give each slave's depth
    parameter MAX_MASTER_WRITE_DEPTH = 16,  // maximum number of addresses of a master that can be externally written
    parameter MAX_SPLIT_TRANS_WAIT_CLK_COUNT = 100 ,
    parameter FIRST_START_MASTER = 0, // this master will start communication first
    parameter COM_START_DELAY = 1000 //gap between 2 masters communication start signal

)
(
    input logic CLOCK_50,
    input logic [3:0]KEY,
    input logic [17:0]SW,
    output logic [17:0]LEDR,
    output logic [3:0]LEDG,
    output logic [6:0]HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, HEX6, HEX7,
    output logic [7:0]LCD_DATA,
    output logic LCD_RW,LCD_EN,LCD_RS,LCD_BLON,LCD_ON
        
);

// localparam SLAVE_COUNT=3;  // number of slaves
// localparam MASTER_COUNT=2; // number of masters
// localparam DATA_WIDTH = 16; // width of a data word in slave & master

// localparam int SLAVE_DEPTHS[SLAVE_COUNT] = '{4096,4096,2048}; // give each slave's depth
localparam int SLAVE_ADDR_WIDTHS[SLAVE_COUNT] = '{$clog2(SLAVE_DEPTHS[0]), $clog2(SLAVE_DEPTHS[1]), $clog2(SLAVE_DEPTHS[2])};

localparam MASTER_DEPTH = SLAVE_DEPTHS[0]; // master should be able to write or read all the slave address locations without loss
localparam MASTER_ADDR_WIDTH = $clog2(MASTER_DEPTH); 
localparam S_ID_WIDTH = $clog2(SLAVE_COUNT+1);
localparam M_ID_WIDTH = $clog2(MASTER_COUNT);


logic rstN, clk, jump_stateN, jump_next_addr;
logic [3:0]KEY_OUT;

assign rstN = KEY_OUT[0];
assign jump_stateN = KEY_OUT[1];
assign jump_next_addr = KEY_OUT[2];
assign clk = CLOCK_50;

///////////// debouncing (start) //////////////

localparam TIME_DELAY = 500; // time delay for debouncing in ms
genvar ii;
generate
    for (ii=0;ii<4;ii=ii+1) begin: debouncing
        debouncer #(.TIME_DELAY(TIME_DELAY)) debouncer(
            .clk(clk),
            .value_in(KEY[ii]),
            .value_out(KEY_OUT[ii])
        );
    end
endgenerate
////////// debouncing (end) ////////////

//////////////// TOP module & MASTER module wires and registers /////////////

logic M_burst[0:MASTER_COUNT-1];
logic M_burst_next[0:MASTER_COUNT-1];
logic M_rdWr[0:MASTER_COUNT-1];
logic M_rdWr_next[0:MASTER_COUNT-1];
logic M_inEx[0:MASTER_COUNT-1];
logic M_inEx_next[0:MASTER_COUNT-1];
logic [DATA_WIDTH-1:0] M_data[0:MASTER_COUNT-1];
logic [DATA_WIDTH-1:0] M_data_next[0:MASTER_COUNT-1];
logic [MASTER_ADDR_WIDTH-1:0] M_address[0:MASTER_COUNT-1];
logic [MASTER_ADDR_WIDTH-1:0] M_address_next[0:MASTER_COUNT-1];
logic [$clog2(SLAVE_COUNT)-1:0] M_slaveId[0:MASTER_COUNT-1];
logic [$clog2(SLAVE_COUNT)-1:0] M_slaveId_next[0:MASTER_COUNT-1];
logic M_start[0:MASTER_COUNT-1];
logic M_start_next[0:MASTER_COUNT-1];
logic M_eoc[0:MASTER_COUNT-1];
logic M_eoc_next[0:MASTER_COUNT-1];

logic M_doneCom[0:MASTER_COUNT-1];
logic [DATA_WIDTH-1:0] M_dataOut[0:MASTER_COUNT-1];
logic [DATA_WIDTH-1:0] M_dataOut_reg[0:MASTER_COUNT-1]; // to keep the values reed from masters
logic [DATA_WIDTH-1:0] M_dataOut_next[0:MASTER_COUNT-1];

logic M_rD[0:MASTER_COUNT-1];         
logic M_ready[0:MASTER_COUNT-1];
logic M_control[0:MASTER_COUNT-1];           // START|SLAVE_ID|r/w|B|address| 
logic M_wrD[0:MASTER_COUNT-1];
logic M_valid[0:MASTER_COUNT-1];
logic M_last[0:MASTER_COUNT-1];

logic arbCont[0:MASTER_COUNT-1];
logic arbSend[0:MASTER_COUNT-1];

// slave module input outputs
logic S_rD[0:SLAVE_COUNT-1];      
logic S_ready[0:SLAVE_COUNT-1];   
logic S_control[0:SLAVE_COUNT-1]; 
logic S_wD[0:SLAVE_COUNT-1];      
logic S_valid[0:SLAVE_COUNT-1];   
logic S_last[0:SLAVE_COUNT-1];    


/// arbiter module related wires
logic [S_ID_WIDTH+M_ID_WIDTH-1:0] a_bus_state;
logic a_ready;

logic [DATA_WIDTH-1:0]M_data_bank[0:MASTER_COUNT-1][0:MAX_MASTER_WRITE_DEPTH-1]; // used to store values to be written on masters' memories.
logic [$clog2(MAX_MASTER_WRITE_DEPTH)-1:0]current_data_bank_addr, next_data_bank_addr; // used to select a location in "M_data_bank"
logic [$clog2(MAX_MASTER_WRITE_DEPTH)-1:0]data_bank_wr_count[0:MASTER_COUNT-1];
logic [$clog2(MAX_MASTER_WRITE_DEPTH)-1:0]data_bank_wr_count_next[0:MASTER_COUNT-1];  

logic [MASTER_ADDR_WIDTH-1:0]slave_first_addr[0:MASTER_COUNT-1];
logic [MASTER_ADDR_WIDTH-1:0]slave_first_addr_next[0:MASTER_COUNT-1]; // slave R/W first addr
logic [MASTER_ADDR_WIDTH-1:0]slave_last_addr[0:MASTER_COUNT-1];
logic [MASTER_ADDR_WIDTH-1:0]slave_last_addr_next[0:MASTER_COUNT-1]; // slave R/W last addr (when burst R/W)

localparam COM_START_DELAY_COUNTER_WIDTH = (COM_START_DELAY==0)? 1:$clog2(COM_START_DELAY); // if widht==0 can not synthesize
logic [COM_START_DELAY_COUNTER_WIDTH-1:0]current_com_start_delay_count, next_com_start_delay_count;
logic both_masters_com_started, both_masters_com_started_next; 


//////////////////// master configuration state related logics /////////////////
localparam CONFIG_CLK_COUNT = 2;
logic [$clog2(MASTER_COUNT)-1:0]current_config_master, next_config_master;
logic [$clog2(CONFIG_CLK_COUNT)-1:0]current_config_clk_count, next_config_clk_count;
logic [$clog2(MAX_MASTER_WRITE_DEPTH)-1:0]current_config_write_count, next_config_write_count;

//////////////// MASTER module instantiate (start) /////////////
genvar jj;
generate
    for (jj=0;jj<MASTER_COUNT; jj=jj+1) begin:MASTER
        master #(.MEMORY_DEPTH(MASTER_DEPTH), .DATA_WIDTH(DATA_WIDTH)) master(

        //  with topModule   //
            .clk, .rstN, 
            .burst(M_burst[jj]), // used to tell whether external write is a burst or not
            .rdWr(M_rdWr[jj]),   // read or write: 0 1                        
            .inEx(M_inEx[jj]),   // internal or external                        
            .data(M_data[jj]),
            .address(M_address[jj]),
            .slaveId(M_slaveId[jj]),
            .start(M_start[jj]),
            .eoc(M_eoc[jj]),

            .doneCom(M_doneCom[jj]),
            .dataOut(M_dataOut[jj]),

            //    with slave     //
            .rD(M_rD[jj]),         
            .ready(M_ready[jj]),
            .control(M_control[jj]),           // START|SLAVE_ID|r/w|B|address| 
            .wrD(M_wrD[jj]),
            .valid(M_valid[jj]),
            .last(M_last[jj]),

            //    with arbiter   //
            .arbCont(arbCont[jj]),
            .arbSend(arbSend[jj])
        );
    end
endgenerate

/////// slave instantiation ////////////
generate 
    for (jj=0; jj<SLAVE_COUNT; jj++) begin : SLAVE
        slave #(
            .ADDR_DEPTH(SLAVE_DEPTHS[jj]),
            .SLAVES(SLAVE_COUNT),
            .DATA_WIDTH(DATA_WIDTH),
            .SLAVEID(jj+1)
        ) slave(
            // with Master (through interconnect)
            .rD(S_rD[jj]),                  //serial read_data
            .ready(S_ready[jj]),               //default HIGh

            .control(S_control[jj]),              //serial control setup info  start|slaveid|R/W|B|start_address -- 111|SLAVEID|1|1|WIDTH
            .wD(S_wD[jj]),                   //serial write_data
            .valid(S_valid[jj]),                //default LOW
            .last(S_last[jj]),                 //default LOW

            //with Top Module
            .clk,
            .rstN   
        );
    end

endgenerate

//////// arbiter instantiation
arbiter #(
    .NO_MASTERS(MASTER_COUNT),
    .NO_SLAVES(SLAVE_COUNT),
    .THRESH(MAX_SPLIT_TRANS_WAIT_CLK_COUNT) 
)arbiter(

  .clk,
  .rstN,
  
  //============//
  //  masters   //
  //============// 
  .port_in(arbSend),
  .port_out(arbCont),

  //===================//
  //    multiplexers   //
  //===================// 
	.ready(a_ready),
    .bus_state(a_bus_state)
);

//// bus_interconnect instantiation ////

bus_interconnect #(
    .NO_MASTERS(MASTER_COUNT),
    .NO_SLAVES(SLAVE_COUNT)
) bus_interconnect (

    // arbiter 
    .bus_state(a_bus_state),
    .ready(a_ready),

    //masters from First master: 0 - Second master :1 --- last
    .control_M(M_control), 
	.wD_M(M_wrD), //********* is this correct naming?????
	.valid_M(M_valid),
	.last_M(M_last),
    .rD_M(M_rD),
	.ready_M(M_ready),

    //slaves count  First Slave : 0 - Second Slave :1 --- last
    .control_S(S_control),
	.wD_S(S_wD),
	.valid_S(S_valid),
	.last_S(S_last),
    .rD_S(S_rD),
	.ready_S(S_ready)  
    );



main_state_t current_state, next_state;

//////////////////// master configuration state related logics /////////////////
typedef enum logic [2:0] {
    // config_ready = 3'd0,
    config_start = 3'd1,
    config_middle = 3'd2,
    config_last = 3'd3,  // last stream of configuration
    config_done = 3'd4
} config_sub_state_t;

config_sub_state_t current_config_state, next_config_state;


always_ff @(posedge clk or negedge rstN) begin
    if (!rstN) begin
        current_state <= master_slave_sel;

        /////////// master related variables /////////
        M_burst     <= '{default:'0};
        M_rdWr      <= '{default:'0};
        M_inEx      <= '{default:'0};
        M_address   <= '{default:'0}; 
        M_slaveId   <= '{default:'0}; 

        M_eoc   <= '{default:'0};

        slave_first_addr <= '{default:'0};  
        slave_last_addr  <= '{default:'0};

        //////////// config_sub_states related logic /////////
        current_config_state        <= config_start;
        current_config_master       <= '0;
        current_config_clk_count    <= '0;
        current_config_write_count  <= '0;

        M_start <= '{default: '0};
        M_data  <= '{default:'0};

        current_com_start_delay_count <= '0;
        both_masters_com_started <= 1'b0;

        M_dataOut_reg <= '{default: '0};

    end
    else begin
        current_state <= next_state;

        //////// master related variables ///////////
        M_burst     <= M_burst_next;
        M_rdWr      <= M_rdWr_next;
        M_inEx      <= M_inEx_next;
        M_address   <= M_address_next; 
        M_slaveId   <= M_slaveId_next; 

        M_eoc   <= M_eoc_next;

        slave_first_addr <= slave_first_addr_next;
        slave_last_addr  <= slave_last_addr_next;


        //////////// config_sub_states related logic /////////
        current_config_state        <= next_config_state;
        current_config_master       <= next_config_master;
        current_config_clk_count    <= next_config_clk_count;
        current_config_write_count  <= next_config_write_count;

        M_start <= M_start_next;
        M_data  <= M_data_next;
        
        current_com_start_delay_count <= next_com_start_delay_count;
        both_masters_com_started <= both_masters_com_started_next;

        M_dataOut_reg <= M_dataOut_next;

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
    next_config_state = current_config_state;

    case (current_state)
        master_slave_sel: begin
            if (!jump_stateN) begin
                if (SW[3:0] == '0) begin  // if no slave is selected to both master no communication happens
                    next_state = communication_done;
                end
                else begin
                    next_state = read_write_sel;
                end    
            end
        end

        read_write_sel: begin
            if(!jump_stateN) begin
                // if(SW[1:0] == 2'b00) begin
                //     next_state = slave_addr_sel_M1;
                // end
                // else begin
                //     next_state = external_write_sel;
                // end
                next_state = external_write_sel;  // always check whether need to externally write to master or not 
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
                next_config_state = config_start;
            end
        end

        config_masters: begin
            case (current_config_state)

                config_start: begin
                    if (current_config_clk_count == CONFIG_CLK_COUNT-1) begin
                        if (M_inEx[current_config_master] == 1'b0) begin
                            next_config_state = config_last;
                        end
                        else if ((data_bank_wr_count[current_config_master]==0) | (data_bank_wr_count[current_config_master]==1'b1) ) begin // only 1 external write
                            next_config_state = config_last;
                        end
                        else begin
                            next_config_state = config_middle;
                        end
                    end
                end
                
                config_middle: begin
                    if (current_config_clk_count == CONFIG_CLK_COUNT-1) begin
                        if (current_config_write_count == data_bank_wr_count[current_config_master]-1) begin // the value before last value
                            next_config_state = config_last;
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

                config_done: begin 
                    next_state = communication_ready;
                end

                default: next_config_state = config_start; // **************** not sure ***************************
            endcase

        end

        communication_ready: begin
            if (~jump_stateN)begin
                next_state = communicating;
            end
        end

        communicating: begin
            if ((M_doneCom[0] == 1'b1) & (M_doneCom[1]==1'b1)) begin
                next_state = communication_done;
            end
            else if ((M_slaveId[0]=='0) & (M_doneCom[1]==1'b1)) begin // only the master 1 communicates
                next_state = communication_done;
            end
            else if ((M_slaveId[1]=='0) & (M_doneCom[0]==1'b1)) begin // only the master 0 communicates
                next_state = communication_done;
            end
        end

        communication_done: begin // stay within this state until reset
            
        end

   endcase
end

/////// logic within the state ///////////

always_comb begin 
    
    M_burst_next     = M_burst;
    M_rdWr_next      = M_rdWr;
    M_inEx_next      = M_inEx;
    M_data_next      = M_data;
    M_address_next   = M_address;
    M_slaveId_next   = M_slaveId; 

    M_eoc_next       = M_eoc;

    next_data_bank_addr = current_data_bank_addr;
    data_bank_wr_count_next = data_bank_wr_count;

    slave_first_addr_next = slave_first_addr;
    slave_last_addr_next  = slave_last_addr;

    M_dataOut_next = M_dataOut_reg;

    // config_sub_states related logic
    M_start_next = M_start;
    next_config_master = current_config_master;
    next_config_clk_count = current_config_clk_count + 1'b1;
    next_config_write_count = current_config_write_count;

    next_com_start_delay_count = current_com_start_delay_count;
    both_masters_com_started_next = both_masters_com_started;

    case (current_state) 
        master_slave_sel: begin

            for (integer ii=0;ii<MASTER_COUNT;ii=ii+1) begin 
                M_slaveId_next[ii] = SW[2*ii+1 -:2];
            end

            if ((SW[3:0] == '0) & (next_state == communication_done)) begin
                M_eoc_next = '{default:1'b1};  // say masters to directly jump to last state without communication;
            end
        end   

        read_write_sel: begin 
            for (integer ii=0;ii<MASTER_COUNT;ii=ii+1)begin
                M_rdWr_next[ii] = SW[ii];
            end
            
        end 

        external_write_sel: begin
            for (integer ii=0;ii<MASTER_COUNT;ii=ii+1) begin
                M_inEx_next[ii] = SW[ii];
            end
                      
        end 

        external_write_M1: begin
            if (!jump_stateN) begin
                next_data_bank_addr = '0; // reset to 0 for next master value write
            end
            else if (!jump_next_addr) begin
                M_burst_next[0] = 1'b1; // externally write more than 1 address
                next_data_bank_addr = current_data_bank_addr + 1'b1;  // go to the next address of the same master
                data_bank_wr_count_next[0] = data_bank_wr_count[0] + 1'b1; // count the number of external writes
            end
        end 

        external_write_M1_2: begin
            if (!jump_stateN) begin
                next_data_bank_addr = '0; // reset to 0 for next master value write
            end
            else if (!jump_next_addr) begin
                M_burst_next[0] = 1'b1; // externally write more than 1 address
                next_data_bank_addr = current_data_bank_addr + 1'b1;  // go to the next address of the same master
                data_bank_wr_count_next[0] = data_bank_wr_count[0] + 1'b1; // count the number of external writes
            end
        end

        external_write_M2: begin
            if (!jump_stateN) begin
                next_data_bank_addr = '0; // reset to 0 for next master value write
            end
            else if (!jump_next_addr) begin
                M_burst_next[1] = 1'b1; // externally write more than 1 address
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
            // calculate the last address
            if ((SW[MASTER_ADDR_WIDTH-1:0]+slave_first_addr[0]) >= SLAVE_DEPTHS[M_slaveId[0]-1]) begin
                slave_last_addr_next[0] = MASTER_ADDR_WIDTH'(SLAVE_DEPTHS[M_slaveId[0]-1'b1]); // if given length is too large select untill the last address of the slave
            end
            else begin
                slave_last_addr_next[0] = SW[MASTER_ADDR_WIDTH-1:0]+slave_first_addr[0];
            end
            
        end 

        addr_count_sel_M2: begin
            // calculate the last address
            if ((SW[MASTER_ADDR_WIDTH-1:0]+slave_first_addr[1]) >= SLAVE_DEPTHS[M_slaveId[1]-1]) begin
                slave_last_addr_next[1] = MASTER_ADDR_WIDTH'(SLAVE_DEPTHS[M_slaveId[1]-1'b1]); // if given length is too large select untill the last address of the slave
            end
            else begin
                slave_last_addr_next[1] = SW[MASTER_ADDR_WIDTH-1:0]+slave_first_addr[1];
            end
            // setup for config_master_start
            if (!jump_stateN) begin
                next_config_master = '0;
                M_start_next[0] = 1'b1;
                M_address_next[0] = slave_first_addr[0];
                M_data_next[0] = M_data_bank[0][0]; // the first external write value of first master (need only if external write)
                next_config_write_count = '0;
            end
        end 

        config_masters: begin
            case (current_config_state)

                config_start: begin
                    M_start_next[current_config_master] = 1'b0;  // set to zero after 1st clk cycle
                    if (current_config_clk_count == CONFIG_CLK_COUNT-1) begin  // goes to next state 
                        next_config_clk_count = '0;
                        next_config_write_count = current_config_write_count + 1'b1; // set the address for next state
                        M_data_next[current_config_master] = M_data_bank[current_config_master][current_config_write_count+1'b1];  //set the value for next state

                        if (next_config_state == config_last) begin
                            M_start_next[current_config_master] = 1'b1; // set to one at the first cycle of "config_last"
                        end
                    end               
                end

                config_middle: begin
                    M_data_next[current_config_master] = M_data_bank[current_config_master][current_config_write_count];
                    if (current_config_clk_count == CONFIG_CLK_COUNT-1) begin
                        next_config_clk_count = '0;
                        next_config_write_count = current_config_write_count + 1'b1;
                        M_data_next[current_config_master] = M_data_bank[current_config_master][current_config_write_count+1'b1];
                        
                        if (next_config_state == config_last) begin
                            M_start_next[current_config_master] = 1'b1; // set to one at the first cycle of "config_last"
                        end
                    end
                end

                config_last: begin
                    M_start_next[current_config_master] = 1'b0;  // set to zero after 1st clk cycle
                    if (current_config_clk_count == CONFIG_CLK_COUNT-1) begin
                        next_config_clk_count = '0;
                        if (current_config_master != MASTER_COUNT-1) begin
                            next_config_master = current_config_master+1'b1;
                            next_config_write_count = '0;
                            M_start_next[current_config_master+1] = 1'b1; // send start configuration for next master
                            M_address_next[current_config_master+1] = slave_first_addr[current_config_master+1];
                            M_data_next[current_config_master+1] = M_data_bank[current_config_master+1][0]; // the first external write value of first master (need only if external write)
                        end
                    end
                end

                config_done: begin
                    M_start_next = '{default:1'b0};  // keep all start signals at zero until press start push button
                    M_address_next = '{default: '0}; // set the address bus to zero to read after the communication_done state
                end

            endcase
        end 

        communication_ready:begin
            if (!jump_stateN) begin
                if (COM_START_DELAY == 0) begin
                    M_start_next = '{default:1'b1}; // give start signal for 1 clk cycle for both masters simultaneously
                    both_masters_com_started_next = 1'b1;
                end
                else begin
                    M_start_next[FIRST_START_MASTER] = 1'b1; // give start signal for 1 clk cycle for first start master only
                end
                
            end
        end
        communicating: begin         
            M_start_next = '{default:'0}; 
            if (both_masters_com_started == 1'b0) begin
                next_com_start_delay_count = current_com_start_delay_count + 1'b1;
                if (current_com_start_delay_count == COM_START_DELAY) begin
                    both_masters_com_started_next = 1'b1;
                    if (FIRST_START_MASTER == 0) begin
                        M_start_next[1] = 1'b1;
                    end
                    else if (FIRST_START_MASTER == 1) begin
                        M_start_next[0] = 1'b1;
                    end
                end
            end
        end  

        communication_done: begin
            M_dataOut_next = M_dataOut; //read both masters same address
            if (!jump_next_addr) begin
                for (integer ii=0;ii<MASTER_COUNT;ii=ii+1) begin
                    M_address_next[ii] = SW[MASTER_ADDR_WIDTH-1:0];
                end          
            end
        end   
    endcase
end

//////// LEDs control //////
assign LEDG[0] = (current_state == master_slave_sel)? 1'b1:1'b0; // to indicate initial state
assign LEDG[1] = (current_state == communication_ready)? 1'b1:1'b0; // to indicate master configuration done. Now communication can be started.
assign LEDG[3] = (current_state == communicating)? 1'b1:1'b0; // master slave communicating
assign LEDG[2] = (current_state == communication_done)? 1'b1:1'b0; // master slave communication is over
assign LEDR[17:0] = SW[17:0]; // each red LED indicate corresponding SW state.


//////// LCD control //////////////

logic new_data, new_data_next, LCD_ready;
charactor_t line_1[0:15];
charactor_t line_2[0:15];
charactor_t line_1_next[0:15];
charactor_t line_2_next[0:15];
logic LCD_first_time_show, LCD_first_time_show_next;
logic [17:0]current_SW,current_SW_2, next_SW;

typedef enum logic {
    waiting = 1'b0,
    new_data_signal_sending = 1'b1
} new_data_state_t;

new_data_state_t current_new_data_state, next_new_data_state;

always_ff @(posedge clk) begin
    if (!rstN) begin
        line_1 <= '{space,space,space,space,space,space,space,space,space,space,space,space,space,space,space,space};
        line_2 <= '{space,space,space,space,space,space,space,space,space,space,space,space,space,space,space,space};
        new_data <= 1'b0;
        current_new_data_state <= waiting;
        LCD_first_time_show <= 1'b0;
        current_SW <= '0;
        current_SW_2 <='0;
    end
    else begin
        line_1 <= line_1_next;
        line_2 <= line_2_next;
        new_data <= new_data_next;
        current_new_data_state <= next_new_data_state;
        LCD_first_time_show <= LCD_first_time_show_next;
        current_SW <= next_SW;
        current_SW_2 <= current_SW; // shifting
    end
end

always_comb begin
    line_1_next = line_1;
    line_2_next = '{space,space,space,space,space,space,space,space,space,space,space,space,space,space,space,space};

    case (current_state) 

        master_slave_sel: begin
            line_1_next = '{M,a,s,t,e,r, space, s,l,a,v,e, space, s,e,l};
            line_2_next = '{M,num_1, space, right_arrow, space, S,get_slave_num(SW[1:0]),space,space,M,num_2, space, right_arrow, space, S,get_slave_num(SW[3:2])};
            
        end

        read_write_sel: begin
            line_1_next = '{R,e,a,d, space, w,r,i,t,e, space, s,e,l ,space,space};
            line_2_next = '{M,num_1, space, dash, space, get_operation(SW[0]), space,space, M,num_2, space, dash, space, get_operation(SW[1]), space,space};
        end

        external_write_sel: begin
            line_1_next = '{E,x,t,e,r,n,a,l, space, w,r,i,t,e,question_mark, space};
            line_2_next = '{M,num_1, space, dash, space, get_decision(SW[0]), space,space, M,num_2, space, right_arrow, space, get_decision(SW[1]), space,space};
        end

        external_write_M1: begin
            line_1_next = '{E,x,t,dot, space, w,r,i,t,e, space, M,num_1, space,space,space};
            line_2_next = '{A,d,d,r,dash,get_number(current_data_bank_addr), space, V,a,l,dash,get_number(SW[15:12]),get_number(SW[11:8]),get_number(SW[7:4]),get_number(SW[3:0]), space};
        end

        external_write_M1_2: begin
            line_1_next = '{E,x,t,dot, space, w,r,i,t,e, space, M,num_1, space,space,space};
            line_2_next = '{A,d,d,r,dash,get_number(current_data_bank_addr), space, V,a,l,dash,get_number(SW[15:12]),get_number(SW[11:8]),get_number(SW[7:4]),get_number(SW[3:0]), space};
        end

        external_write_M2: begin
            line_1_next = '{E,x,t,dot, space, w,r,i,t,e, space, M,num_2, space,space,space};
            line_2_next = '{A,d,d,r,dash,get_number(current_data_bank_addr), space, V,a,l,dash,get_number(SW[15:12]),get_number(SW[11:8]),get_number(SW[7:4]),get_number(SW[3:0]), space};
        end

        slave_addr_sel_M1: begin
            line_1_next = '{M,num_1, space, s,l,a,v,e, space, a,d,d,r,e,s,s};
            line_2_next = '{S,t,a,r,t, space, a,d,d,r,colon, space, get_number(SW[11:8]),get_number(SW[7:4]),get_number(SW[3:0]), space};
        end

        slave_addr_sel_M2: begin
            line_1_next = '{M,num_2, space, s,l,a,v,e, space, a,d,d,r,e,s,s};
            line_2_next = '{S,t,a,r,t, space, a,d,d,r,colon, space, get_number(SW[11:8]),get_number(SW[7:4]),get_number(SW[3:0]), space};
        end

        addr_count_sel_M1: begin
            line_1_next = '{M,num_1, space, S,l,v, space, A,d,d,r,C,o,u,n,t};
            line_2_next = '{C,o,u,n,t,colon, space, get_number(SW[11:8]),get_number(SW[7:4]),get_number(SW[3:0]), space,space,space,space,space,space};
        end

        addr_count_sel_M2: begin
            line_1_next = '{M,num_2, space, S,l,v, space, A,d,d,r,C,o,u,n,t};
            line_2_next = '{C,o,u,n,t,colon, space, get_number(SW[11:8]),get_number(SW[7:4]),get_number(SW[3:0]), space,space,space,space,space,space};
        end

        config_masters: begin
            line_1_next = '{C,o,n,f,i,g,u,r,e, space, m,a,s,t,e,r};
        end

        communication_ready: begin
            line_1_next = '{C,o,m,dot, space, r,e,a,d,y, space,space,space,space,space,space};
        end

        communicating: begin
            line_1_next = '{C,o,m,m,u,n,i,c,a,t,i,n,g, dot,dot,dot};
        end

        communication_done: begin
            line_1_next = '{M,s,t,r,dot, space, a,d,d,r,dot, space, get_number(SW[11:8]),get_number(SW[7:4]),get_number(SW[3:0]), space};
            line_2_next = '{M,num_1,dash, get_number(M_dataOut[0][15:12]),get_number(M_dataOut[0][11:8]),get_number(M_dataOut[0][7:4]),get_number(M_dataOut[0][3:0]), space, M,num_2,dash, get_number(M_dataOut[1][15:12]),get_number(M_dataOut[1][11:8]),get_number(M_dataOut[1][7:4]),get_number(M_dataOut[1][3:0]), space};
        end


    endcase
end

// set new_data signal to the LCD_module after reset, when state change, when swich changed, jump to next address (external write)
always_comb begin
    new_data_next = new_data;
    next_new_data_state = current_new_data_state;
    LCD_first_time_show_next = LCD_first_time_show;
    next_SW = SW[17:0];

    case (current_new_data_state) 
        waiting: begin
            new_data_next = 1'b0;

            if (current_state != next_state) begin
                next_new_data_state = new_data_signal_sending;
            end 
            else if (current_SW != current_SW_2) begin
                next_new_data_state = new_data_signal_sending;
            end
            else if (current_data_bank_addr != next_data_bank_addr) begin
                next_new_data_state = new_data_signal_sending;
            end
            else if (!LCD_first_time_show) begin
                next_new_data_state = new_data_signal_sending;
                LCD_first_time_show_next = 1'b1;
            end
        end 

        new_data_signal_sending: begin
            if (LCD_ready) begin
                new_data_next = 1'b1;
                next_new_data_state = waiting;
            end
        end
    endcase
end

LCD_TOP LCD_TOP(.clk, .rstN, .new_data, .line_1, .line_2, .ready(LCD_ready), 
                .LCD_DATA, .LCD_RW, .LCD_EN, .LCD_RS, .LCD_BLON, .LCD_ON);


function automatic charactor_t get_slave_num(input logic[1:0]value_in);
    charactor_t slave_num;
    case (value_in)
        2'b00: slave_num = underscore;
        2'b01: slave_num = num_1;
        2'b10: slave_num = num_2;
        2'b11: slave_num = num_3;
    endcase

    return slave_num;
endfunction

function automatic charactor_t get_operation(input logic value_in);
    charactor_t operation;
    case (value_in)
        1'b0: operation = R;
        1'b1: operation = W;
    endcase

    return operation;

endfunction

function automatic charactor_t get_decision(input logic value_in);
    charactor_t decision;
    case(value_in)
        1'b0: decision = n;
        1'b1: decision = y;
    endcase

    return decision;

endfunction

function automatic charactor_t get_number(input logic[3:0] value_in);
    charactor_t number;
    if (value_in < 10)begin
        number = charactor_t'({4'b0011, value_in});
    end
    else begin
        number = charactor_t'({4'b0100, (value_in-4'd9)});
    end
    return number;

endfunction

endmodule : top