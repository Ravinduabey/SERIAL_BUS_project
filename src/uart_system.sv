module uart_system
#(
    parameter DATA_WIDTH = 8,
    parameter BAUD_RATE = 19200
)(
    input  logic clk, rstN,txByteStart,rx,
    input  logic [DATA_WIDTH-1:0]byteForTx,
    output logic tx,tx_ready,rx_ready,rx_new_byte_indicate,
    output logic [DATA_WIDTH-1:0]byteFromRx
);

logic baudTick;

uart_baudRateGen #(.BAUD_RATE(BAUD_RATE)) baudRateGen(.clk, .rstN, .baudTick);

uart_transmitter #(.DATA_WIDTH(DATA_WIDTH)) transmitter(
                    .dataIn(byteForTx), .clk, .baudTick, .rstN, .txStart(txByteStart), .tx, .tx_ready
                    );

uart_receiver #(.DATA_WIDTH(DATA_WIDTH)) receiver (
                .rx, .clk, .rstN, .baudTick, .rx_ready, .dataOut(byteFromRx), .new_byte_indicate(rx_new_byte_indicate)
                );

endmodule:uart_system