module bram #(
    parameter MEMORY_DEPTH = 4092,
    parameter DATA_WIDTH = 16
)(
    input   logic                                       clk,
    input   logic                                       wr,
    input   logic   [DATA_WIDTH-1:0]                    data,
    input   logic   [ADDRESS_WIDTH-1:0]         address,
    
    output  logic   [DATA_WIDTH-1:0]                    q
);

    logic [DATA_WIDTH-1:0] ram[MEMORY_DEPTH-1:0];
	localparam ADDRESS_WIDTH = $clog2(MEMORY_DEPTH);
	
	logic [ADDRESS_WIDTH-1:0] addr_reg;
	always @ (posedge clk)
	begin
		if (wr)                     // Write
			ram[address] <= data;
		else                        // get address to read data
		    addr_reg <= address;
		
	end

	assign q = ram[addr_reg];       // Read data

endmodule