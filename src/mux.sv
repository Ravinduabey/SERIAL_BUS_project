module mux #(
    parameter DATA_WIDTH = 2
) (
    input logic [DATA_WIDTH-1:0] dina,
    input logic [DATA_WIDTH-1:0] dinb,
    input logic select,
    output logic [DATA_WIDTH-1:0] dout
); 

always_comb begin : multiplexer
    unique case (select)

    1'b0 : begin
        dout = dina;
    end

    1'b1 : begin
        dout = dinb;
    end  
    endcase     
end
    
endmodule : mux

