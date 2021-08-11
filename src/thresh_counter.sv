module thresh_counter #(
    parameter THRESH = 100
) (
    input logic clk,
    input logic rstN,
    input logic ready,
    output logic thresh
);

logic [$clog2(THRESH)-1:0] counter;

always_comb begin : threshold_detector
    if(counter == THRESH) thresh = 1;
    else thresh = 0;
end

always_ff @( posedge clk or negedge rstN ) begin
    if (!rstN) counter <= 0;
    else begin
        if (ready) counter <= 0;
        else counter <= counter + 1'b1;
    end
    
end
    
endmodule