module uart_test
#(    
    parameter BAUD_RATE = 19200,
    parameter UART_WIDTH = 8
)
(
    input logic CLOCK_50,
    input logic [3:0]KEY,
    inout logic [5:0]GPIO,
    output logic [6:0]HEX0,HEX1,
    output logic [3:0]LEDG
);

logic clk, rstN;
logic g_rx, g_tx; //get data
logic s_rx, s_tx; //send data

assign clk = CLOCK_50;
assign rstN = KEY[0];

assign g_rx = GPIO[0];
assign GPIO[1] = g_tx;
assign s_rx = GPIO[2];
assign GPIO[3] = s_tx;

//get data uart modules
logic g_txByteStart, g_txByteStart_next;
logic [UART_WIDTH-1:0] g_byteForTx, g_byteForTx_next;
logic g_tx_ready;
logic g_new_byte_start;
logic g_new_byte_received;
logic [UART_WIDTH-1:0] g_byteFromRx;
logic g_rx_ready;

//send data uart modules
logic s_txByteStart;
// logic [UART_WIDTH-1:0] s_byteForTx;
logic s_tx_ready;
logic s_new_byte_start;
logic s_new_byte_received;
logic [UART_WIDTH-1:0] s_byteFromRx;
logic s_rx_ready;

logic baudTick;



uart_baudRateGen #(.BAUD_RATE(BAUD_RATE)) baudRateGen(.clk, .rstN, .baudTick);

// uart_transmitter #(.DATA_WIDTH(UART_WIDTH)) transmitter_send (
//                     .dataIn(s_byteForTx),
//                     .txStart(s_txByteStart), 
//                     .clk(clk), .rstN(rstN), .baudTick(baudTick),                     
//                     .tx(s_tx), 
//                     .tx_ready(s_tx_ready)
//                     );

// uart_receiver #(.DATA_WIDTH(UART_WIDTH)) receiver_send (
//                 .rx(s_rx), 
//                 .clk(clk), .rstN(rstN), .baudTick(baudTick), 
//                 .rx_ready(s_rx_ready), 
//                 .dataOut(s_byteFromRx), 
//                 .new_byte_start(s_new_byte_start),
//                 .new_byte_received(s_new_byte_received)
//                 );

uart_transmitter #(.DATA_WIDTH(UART_WIDTH)) transmitter_get (
                    .dataIn(g_byteForTx),
                    .txStart(g_txByteStart), 
                    .clk(clk), .rstN(rstN), .baudTick(baudTick),                     
                    .tx(g_tx), 
                    .tx_ready(g_tx_ready)
                    );

uart_receiver #(.DATA_WIDTH(UART_WIDTH)) receiver_get (
                .rx(g_rx), 
                .clk, .rstN, .baudTick, 
                .rx_ready(g_rx_ready), 
                .dataOut(g_byteFromRx), 
                .new_byte_start(g_new_byte_start),
                .new_byte_received(g_new_byte_received)
                );


logic [25:0]current_clk_count, next_clk_count;
logic [UART_WIDTH-1:0]current_g_rx_val, next_g_rx_val;
logic [UART_WIDTH-1:0]current_g_tx_val, next_g_tx_val;
logic gpio_rx, gpio_rx_next;

typedef enum logic [2:0]{
    read = 3'd0,
    disp = 3'd1,
    waiting = 3'd2,
    write = 3'd3,
    waiting_2 = 3'd4
} state_t;

state_t current_state, next_state;


always_ff @(posedge clk) begin
    if (~rstN) begin
        current_state <= read;
        current_clk_count <= '0;
        current_g_rx_val <= '0;
        gpio_rx <= 1'b0;
        g_txByteStart <= 1'b0;
        g_byteForTx <= '0;
        current_g_tx_val <= 8'd10;
    end
    else begin
        current_state <= next_state;
        current_clk_count <= next_clk_count;
        current_g_rx_val <= next_g_rx_val;
        gpio_rx <= gpio_rx_next;
        g_txByteStart <= g_txByteStart_next;
        g_byteForTx <= g_byteForTx_next;
        current_g_tx_val <= next_g_tx_val;
    end
end

always_comb begin

    next_state = current_state;
    next_clk_count = current_clk_count;
    next_g_rx_val = current_g_rx_val;
    gpio_rx_next = gpio_rx;
    g_txByteStart_next = g_txByteStart;
    g_byteForTx_next = g_byteForTx;
    next_g_tx_val = current_g_tx_val;

    case (current_state)
        read: begin
            if (g_rx == 1'b0) begin
                gpio_rx_next = 1'b1;
            end
            if (g_new_byte_received) begin
                next_state = disp;
                next_clk_count = '0;
                next_g_rx_val = g_byteFromRx;
            end
        end
        disp: begin
            next_clk_count = current_clk_count+1'b1;
            if (current_clk_count == '1) begin
                next_state = waiting;
                next_clk_count = '0;
            end
        end

        waiting: begin
            next_clk_count = current_clk_count + 1'b1;
            if (current_clk_count == '1) begin
                next_state = read;
            end
        end
        write: begin
            if (g_tx_ready) begin
                g_byteForTx_next = current_g_tx_val;
                next_g_tx_val = current_g_tx_val+1'b1;
                g_txByteStart_next = 1'b1;
                next_clk_count = '0;
                next_state = waiting_2;
            end
        end

        waiting_2: begin
            g_txByteStart_next = 1'b0;    
            next_clk_count = current_clk_count + 1'b1;
            if (current_clk_count == '1) begin
                next_state = write;
            end
        end

    endcase
end

///////// HEX display control ////////
logic show; 
assign show = (current_state == disp)? 1'b1:1'b0; 

top_seven_segment segment_0(.in(current_g_rx_val[3:0]), .show, .out(HEX0));
top_seven_segment segment_1(.in(current_g_rx_val[7:4]), .show, .out(HEX1));

assign LEDG[2:0] = logic'(current_state);


assign LEDG[3] = 1'b1;


endmodule : uart_test