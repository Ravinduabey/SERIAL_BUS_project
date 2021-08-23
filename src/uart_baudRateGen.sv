module uart_baudRateGen 
#(
    parameter BAUD_RATE = 19200
)
(
    input logic clk,rstN,
    output logic baudTick
);
localparam CLK_RATE = 50*(10**6);
localparam RESOLUTION = 16;  // samples per 1 baud
localparam int MAX_COUNT = (CLK_RATE/BAUD_RATE/RESOLUTION); //round to smaller integer
localparam WIDTH = $clog2(MAX_COUNT);

logic [WIDTH-1:0]count;

always_ff @(posedge clk) begin
    if (~rstN)
        count <= '0;
    else if (count < MAX_COUNT)
        count <= count + WIDTH'(1'b1);
    else
        count <= '0;
end

assign  baudTick = (count==MAX_COUNT)? 1'b1:1'b0;


endmodule:uart_baudRateGen