module uart_slave_system
#(
    parameter BAUD_RATE = 19200,
    parameter SLAVES = 3,
    parameter DATA_WIDTH = 8,
    parameter S_ID_WIDTH = $clog2(SLAVES+1), //3
    parameter SLAVEID = 1,
    parameter ACK_TIMEOUT = 10000,
    parameter RETRANSMIT_TIMES = 3
)(
    // with Master (through interconnect)
    output logic rD,                  //serial read_data
    output logic ready,               //default HIGH

    input logic control,              //serial control setup info  
    input logic wD,                   //serial write_data
    input logic valid,                //default LOW

    //with Top Module
    input logic clk,
    input logic rstN, 

    //get data
    input logic g_rx,
    output logic g_tx,

    //send data
    input  logic s_rx,
    output logic s_tx

);
    //get data uart modules
    logic g_txByteStart;
    logic [DATA_WIDTH-1:0] g_byteForTx;
    logic g_tx_ready;
    logic g_new_byte_start;
    logic g_new_byte_received;
    logic [DATA_WIDTH-1:0] g_byteFromRx;
    logic g_rx_ready;

    //send data uart modules
    logic s_txByteStart;
    logic [DATA_WIDTH-1:0] s_byteForTx;
    logic s_tx_ready;
    logic s_new_byte_start;
    logic s_new_byte_received;
    logic [DATA_WIDTH-1:0] s_byteFromRx;
    logic s_rx_ready;

    logic baudTick;


uart_slave #(
    .SLAVES(SLAVES),
    .DATA_WIDTH(DATA_WIDTH),
    .SLAVEID(SLAVEID) ,
    .ACK_TIMEOUT(ACK_TIMEOUT),
    .RETRANSMIT_TIMES(RETRANSMIT_TIMES)              
) uart_slave (
    .rD(rD),
    .ready(ready),
    .control(control),
    .wD(wD),
    .valid(valid),
    .clk(clk),
    .rstN(rstN), 
    // get uart
    .g_txStart(g_txByteStart),
    .g_byteForTx(g_byteForTx),
    .g_txReady(g_tx_ready),
    .g_rxStart(g_new_byte_start),
    .g_rxDone(g_new_byte_received),
    .g_byteFromRx(g_byteFromRx),
    .g_rxReady(g_rx_ready),
    // send uart
    .s_txStart(s_txByteStart),
    .s_byteForTx(s_byteForTx),
    .s_txReady(s_tx_ready),
    .s_rxStart(s_new_byte_start),
    .s_rxDone(s_new_byte_received),
    .s_byteFromRx(s_byteFromRx),
    .s_rxReady(s_rx_ready)
);

uart_baudRateGen #(.BAUD_RATE(BAUD_RATE)) baudRateGen(.clk(clk), .rstN(rstN), .baudTick(baudTick));

uart_transmitter #(.DATA_WIDTH(DATA_WIDTH)) transmitter_send (
                    .dataIn(s_byteForTx),
                    .txStart(s_txByteStart), 
                    .clk(clk), .rstN(rstN), .baudTick(baudTick),                     
                    .tx(s_tx), 
                    .tx_ready(s_tx_ready)
                    );

uart_receiver #(.DATA_WIDTH(DATA_WIDTH)) receiver_send (
                .rx(s_rx), 
                .clk(clk), .rstN(rstN), .baudTick(baudTick), 
                .rx_ready(s_rx_ready), 
                .dataOut(s_byteFromRx), 
                .new_byte_start(s_new_byte_start),
                .new_byte_received(s_new_byte_received)
                );

uart_transmitter #(.DATA_WIDTH(DATA_WIDTH)) transmitter_get (
                    .dataIn(g_byteForTx),
                    .txStart(g_txByteStart), 
                    .clk(clk), .rstN(rstN), .baudTick(baudTick),                     
                    .tx(g_tx), 
                    .tx_ready(g_tx_ready)
                    );

uart_receiver #(.DATA_WIDTH(DATA_WIDTH)) receiver_get (
                .rx(g_rx), 
                .clk(clk), .rstN(rstN), .baudTick(baudTick), 
                .rx_ready(g_rx_ready), 
                .dataOut(g_byteFromRx), 
                .new_byte_start(g_new_byte_start),
                .new_byte_received(g_new_byte_received)
                );
                
endmodule:uart_slave_system