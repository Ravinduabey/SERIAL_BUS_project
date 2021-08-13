module thresh_counter #(
    parameter THRESH = 1000
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
    
endmodule : thresh_counter