module bram_tb();
    timeunit 1ns; timeprecision 1ps;

    logic clk;
    localparam CLK_PRERIOD = 10;

    initial begin
    clk <= 0;
        forever #(CLK_PRERIOD/2) clk <= ~clk;
    end

    localparam MEMORY_DEPTH = 4096;
    localparam DATA_WIDTH = 16 ;
    
    logic [$clog2(MEMORY_DEPTH)-1:0]   address;
    logic [DATA_WIDTH-1:0]              data;
    logic                               wr;
    logic [DATA_WIDTH-1:0]              q;

bram #(
    .MEMORY_DEPTH               ( MEMORY_DEPTH ),
    .DATA_WIDTH                  ( DATA_WIDTH )
) dut(
    .clk            (clk        ),
    .wr             (wr         ),
    .address        (address    ),
    .data           (data       ),
    .q              (q          )
);


initial begin
    @(posedge clk);
    wr <=0;
    
    @(posedge clk);
    #CLK_PRERIOD;
    wr      <= 1;
    address <= 12'd1;
    data    <= 16'd5;
    
    @(posedge clk);
    #(CLK_PRERIOD*2);
    address <= 12'd2;
    data    <= 16'd10;

    @(posedge clk);
    #(CLK_PRERIOD*2);
    address <= 12'd3;
    data    <= 16'd12;

    @(posedge clk);
    #CLK_PRERIOD;
    wr      <= 0;
    
    @(posedge clk);
    #(CLK_PRERIOD*2);
    address <= 12'd1;
    
    @(posedge clk);
    #(CLK_PRERIOD*2);
    address <= 12'd2;

    @(posedge clk);
    #(CLK_PRERIOD*2);
    address <= 12'd3;
    
    @(posedge clk);
    #(CLK_PRERIOD*2);

    $finish;
end

endmodule