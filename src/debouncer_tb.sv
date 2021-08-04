timeunit 1ns;
timeprecision 1ns;

module debouncer_tb();

localparam CLK_PERIOD = 20;  //nS
localparam CLK_FREQ = 50; // MHz
localparam TIME_DELAY = 1; // mS
localparam MAX_CLK_COUNT = TIME_DELAY * CLK_FREQ * 1000;

logic clk, value_in, value_out;


initial begin
    clk = 1'b0;
    forever begin
        #(CLK_PERIOD/2);
        clk = ~clk;
    end
end


debouncer #(.TIME_DELAY(TIME_DELAY)) dut(.*);

initial begin

    @(posedge clk);
    value_in <= 1'b1;

    #(CLK_PERIOD*10);

    @(posedge clk);
    value_in <= 1'b0;

    @(posedge clk);
    value_in <= 1'b1;

    #(CLK_PERIOD*MAX_CLK_COUNT/2);
    @(posedge clk);
    value_in <= 1'b0;

    @(posedge clk);
    value_in <= 1'b1;

    #(CLK_PERIOD*MAX_CLK_COUNT*2);
    @(posedge clk);
    #(CLK_PERIOD*3/4);
    value_in <= 1'b0;

    @(posedge clk);
    value_in <= 1'b1;

    $stop;

end



endmodule: debouncer_tb