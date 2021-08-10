module demux #(
    parameter DATA_WIDTH = 2
) (
    input logic [DATA_WIDTH-1:0] din,
    input logic select,
    output logic [DATA_WIDTH-1:0] dout0,
    output logic [DATA_WIDTH-1:0] dout1
);

always_comb begin : demultiplexer
    unique case (select)

    1'b0 : begin
        dout0 = din;
        dout1 = 0;
    end

    1'b1 : begin
        dout0 = 0;
        dout1 = din;
    end  
    endcase  
end
endmodule : demux