/*
    This module will lookout for delay in slave ready signal. If it's getting delayed than the threshold value, a low priority master will get the chance to use the bus for comm.
*/
module a_thresh_counter #(
    parameter THRESH = 1000 //maximum time a slave gets to ready its data
) (
    input logic clk,
    input logic rstN,
    input logic ready,
    output logic thresh
);

logic [31:0] counter = '0;

always_comb begin : threshold_detector
    if(counter > THRESH) thresh = '1;
    else thresh = '0;
end

always_ff @( posedge clk or negedge rstN ) begin : counterReg
    if (!rstN) counter <= '0;
    else begin
        if (ready) counter <= '0;
        else counter <= counter + 1'b1;
    end
    
end
    
endmodule : a_thresh_counter