module uart_test
#(    
    parameter BAUD_RATE = 19200,
    parameter UART_WIDTH = 8
)
(
    input logic CLOCK_50,
    input logic [3:0]KEY,
    inout logic [3:0]GPIO,
    output logic [6:0]HEX0,HEX1,
    output logic [2:0]LEDG
);

localparam [UART_WIDTH-1:0] ACK_PATTERN = 8'b11001100;
localparam [UART_WIDTH-1:0] INITIAL_TX_VAL = 8'd5;

logic clk, rstN, startN;
logic g_rx, g_tx; //get data
logic s_rx, s_tx; //send data

logic [3:0]KEY_OUT;

assign clk = CLOCK_50;
assign rstN = KEY_OUT[0];
assign startN = KEY_OUT[1];

///////////// debouncing  //////////////

localparam TIME_DELAY = 500; // time delay for debouncing in ms
genvar ii;
generate
    for (ii=0;ii<4;ii=ii+1) begin: debouncing
        top_debouncer #(.TIME_DELAY(TIME_DELAY)) debouncer(
            .clk(clk),
            .value_in(KEY[ii]),
            .value_out(KEY_OUT[ii])
        );
    end
endgenerate

assign g_rx = GPIO[0];
assign GPIO[1] = g_tx;
assign s_rx = GPIO[2];
assign GPIO[3] = s_tx;

//get data uart modules
logic g_txByteStart, g_txByteStart_next;
logic [UART_WIDTH-1:0] g_byteForTx = ACK_PATTERN; // always sends ack_pattern
logic g_tx_ready;
logic g_new_byte_start;
logic g_new_byte_received;
logic [UART_WIDTH-1:0] g_byteFromRx;
logic g_rx_ready;

//send data uart modules
logic s_txByteStart, s_txByteStart_next;
logic [UART_WIDTH-1:0] s_byteForTx, s_byteForTx_next;
logic s_tx_ready;
logic s_new_byte_start;
logic s_new_byte_received;
logic [UART_WIDTH-1:0] s_byteFromRx;
logic s_rx_ready;
logic resend_data, resend_data_next;
logic first_tx, first_tx_next;

logic baudTick;



uart_baudRateGen #(.BAUD_RATE(BAUD_RATE)) baudRateGen(.clk, .rstN, .baudTick);

uart_transmitter #(.DATA_WIDTH(UART_WIDTH)) transmitter_send (
                    .dataIn(s_byteForTx),
                    .txStart(s_txByteStart), 
                    .clk(clk), .rstN(rstN), .baudTick(baudTick),                     
                    .tx(s_tx), 
                    .tx_ready(s_tx_ready)
                    );

uart_receiver #(.DATA_WIDTH(UART_WIDTH)) receiver_send (
                .rx(s_rx), 
                .clk(clk), .rstN(rstN), .baudTick(baudTick), 
                .rx_ready(s_rx_ready), 
                .dataOut(s_byteFromRx), 
                .new_byte_start(s_new_byte_start),
                .new_byte_received(s_new_byte_received)
                );

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


logic [UART_WIDTH-1:0]received_data, next_received_data;
logic [UART_WIDTH-1:0]received_ack, next_received_ack;
logic [24:0] disp_time_count, next_disp_time_count;

typedef enum logic [3:0]{
    read_data = 4'd0,
    send_ack_1 = 4'd1,
    send_ack_2 = 4'd2,
    send_ack_3 = 4'd3,
    disp_data = 4'd4,
    send_data_1 = 4'd5,
    send_data_2 = 4'd6,
    send_data_3 = 4'd7,
    receive_ack = 4'd8

} state_t;

state_t current_state, next_state;

always_ff @(posedge clk) begin
    if (~rstN) begin
        current_state <= read_data;
        disp_time_count <= '0;

        received_data <= '0;
        received_ack <= '0;
        resend_data <= 1'b0;
        first_tx <= 1'b0;

        g_txByteStart <= 1'b0;
        s_txByteStart <= 1'b0;
        s_byteForTx <= '0;


    end
    else begin
        current_state <= next_state;
        disp_time_count <= next_disp_time_count;

        received_data <= next_received_data;
        received_ack <= next_received_ack;
        resend_data <= resend_data_next;
        first_tx <= first_tx_next;

        g_txByteStart <= g_txByteStart_next;
        s_txByteStart <= s_txByteStart_next;
        s_byteForTx <= s_byteForTx_next;

    end
end

always_comb begin

    next_state = current_state;
    next_disp_time_count = disp_time_count;

    next_received_data = received_data;
    next_received_ack = received_ack;
    resend_data_next = resend_data;
    first_tx_next = first_tx;

    g_txByteStart_next = g_txByteStart;
    s_txByteStart_next = s_txByteStart;
    s_byteForTx_next = s_byteForTx;

    case (current_state)
        read_data: begin
            if (~startN) begin
                next_state = send_data_1;
                first_tx_next = 1'b1;  //set flag to indicate initial tx
            end
            else if (g_new_byte_received) begin
                next_received_data = g_byteFromRx;
                next_state = send_ack_1;        
            end
        end

        send_ack_1: begin
            if (g_tx_ready) begin
                g_txByteStart_next = 1'b1;  // tell the transmitter to send the ack;  
                next_state = send_ack_2;  
            end
        end

        send_ack_2: begin  // stay untill start ack transmission
            if (~g_tx_ready) begin
                next_state = send_ack_3;
            end
        end

        send_ack_3: begin
            g_txByteStart_next = 1'b0; // set to zero after 1 clk cycle being high 
            if (g_tx_ready) begin // wait untill sends ack
                next_state = disp_data;
                next_disp_time_count = '0;
            end
        end

        disp_data: begin
            next_disp_time_count = disp_time_count + 1'b1;
            if (disp_time_count == '1) begin
                next_state = send_data_1;
            end
        end

        send_data_1: begin
            if (s_tx_ready) begin
                s_txByteStart_next = 1'b1;
                next_state = send_data_2;
                if (first_tx) begin
                    s_byteForTx_next = INITIAL_TX_VAL;
                end
                else if (resend_data == 1'b1) begin  // if a resend don't increment
                    s_byteForTx_next = received_data;
                end
                else begin // increment previously received value by one and send
                    s_byteForTx_next = received_data + 1'b1;
                end  
            end
        end

        send_data_2: begin
            if (~s_tx_ready) begin
                next_state = send_data_3;
            end
        end

        send_data_3: begin
            s_txByteStart_next = 1'b0; // set to zero after 1 clk cycle being high 
            resend_data_next = 1'b0; // reset the resend_data flag if it was set
            if (s_tx_ready) begin // wait untill sends data
                next_state = receive_ack;
            end
        end

        receive_ack: begin
            if (s_new_byte_received) begin
                if (s_byteFromRx == ACK_PATTERN) begin
                    next_state = read_data;
                end
                else begin
                    next_state = send_data_1;  // resend data
                    resend_data_next = 1'b1; // set flag to indicate a resend_data situation
                end
            end
        end

    endcase
end

///////// HEX display control ////////
logic show; 
assign show = (current_state == disp_data)? 1'b1:1'b0; 

top_seven_segment segment_0(.in(received_data[3:0]), .show, .out(HEX0));
top_seven_segment segment_1(.in(received_data[7:4]), .show, .out(HEX1));

assign LEDG[2:0] = logic'(current_state);



endmodule : uart_test