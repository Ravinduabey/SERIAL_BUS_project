module uart_test_tb();

timeunit 1ns;
timeprecision 1ps;
localparam CLK_PERIOD = 20;

localparam BAUD_RATE = 19200;
localparam UART_WIDTH = 8;
localparam BAUD_TIME_PERIOD = 10**9 / BAUD_RATE;

localparam [UART_WIDTH-1:0]UART_ACK = 8'b11001100;

logic CLOCK_50;
logic [3:0]KEY;
wire [3:0]GPIO;
logic [6:0]HEX0,HEX1;
logic [2:0]LEDG;

logic clk, rstN, startN;
logic g_rx, g_tx; //get data
logic s_rx, s_tx; //send data

assign CLOCK_50 = clk;
assign KEY[0] = rstN;
assign KEY[1] = startN;

assign GPIO[0] = g_rx;
assign g_tx = GPIO[1];
assign GPIO[2] = s_rx;
assign s_tx = GPIO[3];

initial begin
    clk <=  0;
    forever begin
        #(CLK_PERIOD/2);
        clk <= ~clk;
    end
end

uart_test #(.BAUD_RATE(BAUD_RATE), .UART_WIDTH(UART_WIDTH)) uart_test(.*);

initial begin
    @(posedge clk);
    rstN = 1'b1;

    @(posedge clk);
    rstN = 1'b0;

    @(posedge clk);
    rstN = 1'b1;

    #(CLK_PERIOD*10);
    start_external_com(); 
    
    UART_receive_by_ext_FPGA(s_tx); //receive data

    #(CLK_PERIOD*10);
    UART_transmit_by_ext_FPGA(UART_ACK, s_rx); // send ack

    #(CLK_PERIOD*1000);
    UART_transmit_by_ext_FPGA(8'b0000_1111, g_rx); // send data

    UART_receive_by_ext_FPGA(g_tx); // receive ack

    #(CLK_PERIOD*1000);

    $stop;

end

task automatic start_external_com();
    #(CLK_PERIOD*10);
   
    @(posedge clk);
    startN = 1'b0; // press the push button
    #(CLK_PERIOD*10); // hold the push button untill pass some time period

    @(posedge clk);
    startN = 1'b1; // release the push button

    #(CLK_PERIOD*10); // wait some time before next KEY press / SW change

endtask

task automatic UART_transmit_by_ext_FPGA(logic [UART_WIDTH-1:0]value, ref logic rx);
    @(posedge clk);  //starting delimiter
    rx = 1'b0; 
    #(BAUD_TIME_PERIOD);
    for (int i=0;i<UART_WIDTH;i++) begin //send from LSB to MSB
        @(posedge clk);
        rx = value[i];
        #(BAUD_TIME_PERIOD);
    end
    @(posedge clk);  // end delimiter
    rx = 1'b1;
    #(BAUD_TIME_PERIOD);

endtask

task automatic UART_receive_by_ext_FPGA(ref logic tx);
    logic [UART_WIDTH-1:0]value;
    @(posedge clk);
    wait(~tx); // wait untill start of the start bit
    #(BAUD_TIME_PERIOD/2) // wait till the middle of the bit occur
    #(BAUD_TIME_PERIOD); // wait till the middle of 1st data bit occur
    for (int i=0;i<UART_WIDTH;i++) begin //receive from LSB to MSB
        @(posedge clk);
        value[i] = tx;
        #(BAUD_TIME_PERIOD);
    end
    $display("%b \n", value);
endtask




endmodule : uart_test_tb