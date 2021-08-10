module mux #(
    parameter DATA_WIDTH
) (
    input logic [DATA_WIDTH-1:0] dina,
    input logic [DATA_WIDTH-1:0] dinb,
    input logic select,
    output logic [DATA_WIDTH-1:0] dout
); 

assign dout = dinb ? select : dina;
    
endmodule : mux

module demux #(
    parameter DATA_WIDTH
) (
    input logic [DATA_WIDTH-1:0] din,
    input logic select,
    output logic [DATA_WIDTH-1:0] douta,
    output logic [DATA_WIDTH-1:0] doutb
);

always_comb begin : demultiplexer
    unique case (select)

    1'b0 : begin
        douta = din;
        doutb = 0;
    end

    1'b1 : begin
        doutb = din;
        douta = 0;
    end  
    endcase  
end
endmodule : demux