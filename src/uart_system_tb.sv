module uart_system_tb();

timeunit 1ns;
timeprecision 1ps;
localparam CLK_PERIOD = 20;
logic clk;

initial begin
    clk <=  0;
    forever begin
        #(CLK_PERIOD/2);
        clk <= ~clk;
    end
end

localparam DATA_WIDTH = 8;
localparam BAUD_RATE = 19200;
localparam BAUD_TIME_PERIOD = 10**9 / BAUD_RATE;

logic rstN,txByteStart,rx;
logic [DATA_WIDTH-1:0]byteForTx;
logic tx,tx_ready,rx_ready,rx_new_byte_indicate;
logic [DATA_WIDTH-1:0]byteFromRx;

uart_system #(.DATA_WIDTH(DATA_WIDTH), .BAUD_RATE(BAUD_RATE)) dut(.*);

///////// initial reset
initial begin
    @(posedge clk);
    rstN <= 1'b0;
    @(posedge clk);
    rstN <= 1'b1;
end


///////// Trasmitter test
initial begin
    #(CLK_PERIOD*2); // to initialize

    repeat(10) begin
        @(posedge clk);
        wait(tx_ready);
        @(posedge clk);
        byteForTx = $urandom();
        txByteStart = 1'b1;

        @(posedge clk);
        txByteStart = 1'b0;
    end
    @(posedge clk);
    wait(tx_ready);
    $stop;
end

/////////  Receier test
initial begin
    #(CLK_PERIOD*2); // to initialize

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
endmodule:uart_system_tb