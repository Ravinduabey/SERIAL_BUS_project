module uart_slave_system
#(
    parameter BAUD_RATE = 19200,
    parameter SLAVES = 3,
    parameter DATA_WIDTH = 8,
    parameter S_ID_WIDTH = $clog2(SLAVES+1), //3
    parameter SLAVEID = 1
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

    //external receiver
    input  logic rx,

    //external transmitter
    output logic tx
);
    logic txByteStart;
    logic [DATA_WIDTH-1:0] byteForTx;
    logic tx_ready;
    logic new_byte_start;
    logic new_byte_received;
    logic [DATA_WIDTH-1:0] byteFromRx;
    logic rx_ready;


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
    .clk(clk),
    .rstN(rstN), 
    .txStart(txByteStart),
    .byteForTx(byteForTx),
    .txReady(tx_ready),
    .rxStart(new_byte_start),
    .rxDone(new_byte_received),
    .byteFromRx(byteFromRx),
    .rxReady(rx_ready)
);

uart_baudRateGen #(.BAUD_RATE(BAUD_RATE)) baudRateGen(.clk(clk), .rstN(rstN), .baudTick(baudTick));

uart_transmitter #(.DATA_WIDTH(DATA_WIDTH)) transmitter(
                    .dataIn(byteForTx),
                    .txStart(txByteStart), 
                    .clk(clk), .rstN(rstN), .baudTick(baudTick),                     
                    .tx(tx), 
                    .tx_ready(tx_ready)
                    );

uart_receiver #(.DATA_WIDTH(DATA_WIDTH)) receiver (
                .rx(rx), 
                .clk(clk), .rstN(rstN), .baudTick(baudTick), 
                .rx_ready(rx_ready), 
                .dataOut(byteFromRx), 
                .new_byte_start(new_byte_start),
                .new_byte_received(new_byte_received)
                );

endmodule:uart_slave_system