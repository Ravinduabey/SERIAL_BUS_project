module LCD_interface import top_details::*;
#(
    parameter MAX_MASTER_WRITE_DEPTH = 16,
    parameter DATA_WIDTH = 16,
    parameter MASTER_COUNT=2
)
(
    input logic clk, rstN,
    input main_state_t current_state, next_state,
    input logic [17:0]SW,
    input logic [$clog2(MAX_MASTER_WRITE_DEPTH)-1:0]current_data_bank_addr,next_data_bank_addr,
    input logic [DATA_WIDTH-1:0] M_dataOut[0:MASTER_COUNT-1],

    output logic [7:0]LCD_DATA,
    output logic LCD_RW,LCD_EN,LCD_RS,LCD_BLON,LCD_ON
);


logic new_data, new_data_next, LCD_ready;
charactor_t line_1[0:15];
charactor_t line_2[0:15];
charactor_t line_1_next[0:15];
charactor_t line_2_next[0:15];
logic LCD_first_time_show, LCD_first_time_show_next;
logic [17:0]current_SW,current_SW_2, next_SW;
main_state_t current_state_2; // to store the previous state

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
        current_state_2 <= master_slave_sel; // initial state
    end
    else begin
        line_1 <= line_1_next;
        line_2 <= line_2_next;
        new_data <= new_data_next;
        current_new_data_state <= next_new_data_state;
        LCD_first_time_show <= LCD_first_time_show_next;
        current_SW <= next_SW;
        current_SW_2 <= current_SW; // shifting
        current_state_2 <= current_state;
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

        slave_start_addr_sel_M1: begin
            line_1_next = '{M,num_1, space, s,l,a,v,e, space, a,d,d,r,e,s,s};
            line_2_next = '{S,t,a,r,t, space, a,d,d,r,colon, space, get_number(SW[11:8]),get_number(SW[7:4]),get_number(SW[3:0]), space};
        end

        slave_start_addr_sel_M2: begin
            line_1_next = '{M,num_2, space, s,l,a,v,e, space, a,d,d,r,e,s,s};
            line_2_next = '{S,t,a,r,t, space, a,d,d,r,colon, space, get_number(SW[11:8]),get_number(SW[7:4]),get_number(SW[3:0]), space};
        end

        slave_end_addr_sel_M1: begin
            line_1_next = '{M,num_1, space, s,l,a,v,e, space, a,d,d,r,e,s,s};
            line_2_next = '{E,n,d, space, a,d,d,r,colon, space, get_number(SW[11:8]),get_number(SW[7:4]),get_number(SW[3:0]), space,space,space};
        end

        slave_end_addr_sel_M2: begin
            line_1_next = '{M,num_2, space, s,l,a,v,e, space, a,d,d,r,e,s,s};
            line_2_next = '{E,n,d, space, a,d,d,r,colon, space, get_number(SW[11:8]),get_number(SW[7:4]),get_number(SW[3:0]), space,space,space};
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

            if (current_state != current_state_2) begin  // when go to the next state
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


endmodule: LCD_interface