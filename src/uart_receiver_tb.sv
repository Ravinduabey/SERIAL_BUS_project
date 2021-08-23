module uart_receiver_tb();

timeunit 1ns;
timeprecision 1ps;
localparam CLK_PERIOD = 20;
logic clk;

initial begin
    clk <= 1'b0;
    forever begin
        #(CLK_PERIOD/2);
        clk <= ~clk;
    end
end

localparam DATA_WIDTH = 8;
localparam BAUD_RATE = 19200;
localparam BAUD_TIME_PERIOD = 10**9 / BAUD_RATE;

logic rstN,baudTick;
logic rx, rx_ready;
logic [DATA_WIDTH-1:0]dataOut;
logic new_byte_indicate;

uart_baudRateGen #(.BAUD_RATE(BAUD_RATE)) baudRateGen(.*);
uart_receiver #(.DATA_WIDTH(DATA_WIDTH)) receiver(.*);

initial begin
    @(posedge clk);
    rstN <= 1'b0;
    rx <= 1'b1;
    @(posedge clk);
    rstN <= 1'b1;

    repeat(10) begin
        @(posedge clk);  //starting delimiter
        rx <= 1'b0;
        #(BAUD_TIME_PERIOD);
        for (int i=0;i<DATA_WIDTH;i++) begin:data  //data
            @(posedge clk);
            rx = $urandom();
            #(BAUD_TIME_PERIOD);
        end
        @(posedge clk);  // end delimiter
        rx <= 1'b1;
        #(BAUD_TIME_PERIOD);
    end
    $stop;
end

endmodule:uart_receiver_tb