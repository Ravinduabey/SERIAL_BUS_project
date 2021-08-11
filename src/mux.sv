module mux #(
    parameter NO_MASTERS = 3,
    parameter NO_SLAVES = 5,
    parameter S_ID_WIDTH = $clog2(NO_SLAVES+1),
    parameter M_ID_WIDTH = $clog2(NO_MASTERS)
) (
    input logic [S_ID_WIDTH-1:0] dina [NO_MASTERS:0],
    // input logic [DATA_WIDTH-1:0] dinb,
    input logic select,
    output logic [DATA_WIDTH-1:0] dout
); 


always_comb begin 

    dout = dina[select];
    
end






// always_comb begin : multiplexer
//     unique case (select)

//     1'b0 : begin
//         dout = dina;
//     end

//     1'b1 : begin
//         dout = dinb;
//     end

//     endcase     
// end
    
endmodule : mux

