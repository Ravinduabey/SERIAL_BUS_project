module uart_slave_system
#(
    parameter BAUD_RATE = 19200,
    parameter SLAVES = 4,
    parameter DATA_WIDTH = 32,
    parameter S_ID_WIDTH = $clog2(SLAVES+1), //3
    parameter SLAVEID = 1,
)(
    // with Master (through interconnect)
    output logic rD,                  //serial read_data
    output logic ready,               //default HIGH

    input logic control,              //serial control setup info  
    input logic wD,                   //serial write_data
    input logic valid,                //default LOW
    input logic last,                 //default LOW

    //with Top Module
    input logic clk,
    input logic rstN 

    input  logic clk, rstN,txByteStart,rx,
    input  logic [DATA_WIDTH-1:0]byteForTx,
    output logic tx,tx_ready,rx_ready,rx_new_byte_indicate,
    output logic [DATA_WIDTH-1:0]byteFromRx
);

logic baudTick;

uart_slave #(
    .SLAVES(4),
    .DATA_WIDTH(8),
    .SLAVEID(4)               
) uart_slave (
    .rD(rD),
    .ready(ready),
    .control(control),
    .wD(wD),
    .valid(valid),
    .last(last),
    .clk(clk),
    .rstN(rstN) 
    .rxData(rxData),
    .rxStar(rxStart),
    .txData(txData),
    .txStart(txStart)
);

uart_baudRateGen #(.BAUD_RATE(BAUD_RATE)) baudRateGen(.clk, .rstN, .baudTick);

uart_transmitter #(.DATA_WIDTH(DATA_WIDTH)) transmitter(
                    .dataIn(byteForTx), .clk, .baudTick, .rstN, .txStart(txByteStart), .tx, .tx_ready
                    );

uart_receiver #(.DATA_WIDTH(DATA_WIDTH)) receiver (
                .rx, .clk, .rstN, .baudTick, .rx_ready, .dataOut(byteFromRx), .new_byte_indicate(rx_new_byte_indicate)
                );

endmodule:uart_slave_system