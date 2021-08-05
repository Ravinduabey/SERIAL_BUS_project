module bram #(
    parameter ADDRESS_DEPTH = 4092,
    parameter DATA_WIDTH = 16
)(
    input   logic                                       clk,
    input   logic                                       wr,
    input   logic   [DATA_WIDTH-1:0]                    data,
    input   logic   [$clog2(ADDRESS_DEPTH)-1:0]         address,
    
    output  logic   [DATA_WIDTH-1:0]                    q
);

    logic [DATA_WIDTH-1:0] ram[ADDRESS_DEPTH-1:0];
	
	logic [$clog2(ADDRESS_DEPTH)-1:0] addr_reg;
	
	always @ (posedge clk)
	begin
		if (wr)                     // Write
			ram[address] <= data;
		else                        // get address to read data
		    addr_reg <= address;
		
	end

	assign q = ram[addr_reg];       // Read data

endmodule