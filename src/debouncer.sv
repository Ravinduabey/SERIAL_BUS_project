module debouncer 
#(
    parameter TIME_DELAY = 500 //mS
)
(
    input logic clk,
    input logic value_in,
    output logic value_out
);

localparam CLK_FREQ = 50; // MHz
localparam MAX_CLK_COUNT = TIME_DELAY * CLK_FREQ * 1000;
localparam COUNTER_WIDTH = $clog2(MAX_CLK_COUNT);

logic [COUNTER_WIDTH-1:0]counter;

always_ff @(posedge clk) begin
    if (value_in == 1'b0) begin
        counter <= counter + COUNTER_WIDTH'(1);
    end
    else if (counter == MAX_CLK_COUNT) begin
        counter <= '0;
    end
    else if (counter != '0) begin
        counter <= counter + COUNTER_WIDTH'(1);
    end
end

assign value_out = (counter == '0)? value_in: 1'b0;  // while counting value_out is always zero

endmodule : debouncer