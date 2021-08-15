module LCD_TEST import details::charactor_t;
(
    input logic CLOCK_50,
    input logic [0:0]KEY,

    output logic [7:0]LCD_DATA,
    output logic LCD_RW,LCD_EN,LCD_RS,LCD_BLON,LCD_ON,
    output logic [1:0]LEDG
);


localparam TIME = 5; //S
localparam CLK_RATE = 50_000_000;
localparam CLK_COUNT = TIME*CLK_RATE;
localparam COUNTER_WIDTH = $clog2(CLK_COUNT);


logic clk, rstN;
assign clk = CLOCK_50;
assign rstN = KEY[0];

logic [COUNTER_WIDTH-1:0] current_count, next_count;
charactor_t current_line_1[0:15];
charactor_t next_line_1[0:15];
charactor_t current_line_2[0:15];
charactor_t next_line_2[0:15];
logic [1:0]current_state, next_state;
logic current_new_data, next_new_data;
logic ready;

always_ff @(posedge clk) begin
    if (!rstN) begin
        current_count <= '0;
        current_line_1 <= '{a,a,a,a,a,a,a,a,a,a,a,a,a,a,a,a};
        current_line_2 <= '{a,a,a,a,a,a,a,a,a,a,a,a,a,a,a,a};
        current_state <= '0;
        current_new_data <= 1'b0;
    end
    else begin
        current_count <= next_count;
        current_line_1 <= next_line_1;
        current_line_2 <= next_line_2;
        current_state <= next_state;
        current_new_data <= next_new_data;
    end
end

always_comb begin
    next_count = current_count + 1'b1;
    next_line_1 = current_line_1;
    next_line_2 = current_line_2;
    next_state = current_state;
    next_new_data = current_new_data;

    case (current_state)

        0: begin
            next_count = '0;
            if(ready) begin
                next_state = 1;
                next_new_data = 1'b1;
            end
        end
        
        1:begin
            next_new_data = 1'b0;
            next_line_1 = '{a,B,c,d,e,f,g,h,space,i,j,k,l,m,O,P};
            next_line_2 = '{hash, dash, num_0,num_1, num_4, space,AND, equal, right_arrow, left_arrow,a,a,a,a,a,a};
            if (current_count == CLK_COUNT) begin
                next_count = '0;
                next_state = 2;
            end
        end
        2: begin
            next_count = '0;
            if(ready) begin
                next_state = 3;
                next_new_data = 1'b1;
            end
        end
        3: begin
            next_new_data = 1'b0;
            next_line_1 = '{M,Y,space,n,a,m,e,i,s,space,s,a,m,a,r,e};
            next_line_2 = '{T,h,a,r,i,n,d,u,space,s,a,r,a,k,o,o};
            if (current_count == CLK_COUNT) begin
                next_count = '0;
                next_state = 0;
                next_new_data = 1'b1;
            end
        end
        
        
        default: begin
            next_state = 0;
            next_line_1 = '{a,a,a,a,a,a,a,a,a,a,a,a,a,a,a,a};
            next_line_2 = '{a,a,a,a,a,a,a,a,a,a,a,a,a,a,a,a};
        end 

    endcase
end

LCD_TEST_NEW LCD_TOP(.clk, .rstN, .line_1(current_line_1), .line_2(current_line_2), .ready, .LCD_DATA, .LCD_RW, 
                        .LCD_EN, .LCD_RS, .new_data(current_new_data), .LCD_ON, .LCD_BLON);

assign LEDG[0] = (current_state==1)?1'b1:1'b0;
assign LEDG[1] = (current_state==3)?1'b1:1'b0;

endmodule :LCD_TEST