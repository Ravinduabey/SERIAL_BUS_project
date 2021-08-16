module bus_interconnect_tb #(
    parameter NO_MASTERS = 2,
    parameter NO_SLAVES = 3,
    parameter THRESH = 1000,
    parameter S_ID_WIDTH = $clog2(NO_SLAVES+1), //2
    parameter M_ID_WIDTH = $clog2(NO_MASTERS) //1
)(

    // arbiter controllers
    input logic [M_ID_WIDTH-1:0] addr_select,
	input logic [M_ID_WIDTH-1:0] MOSI_data_select,
	input logic [M_ID_WIDTH-1:0] valid_select,
	input logic [M_ID_WIDTH-1:0] last_select,
    input logic [S_ID_WIDTH-1:0] MISO_data_select,
	input logic [S_ID_WIDTH-1:0] ready_select,

    output logic ready,

    //masters
    input   logic [M_ID_WIDTH-1:0] control,
	input   logic [M_ID_WIDTH-1:0] wD,
	input   logic [M_ID_WIDTH-1:0] valid,
	input   logic [M_ID_WIDTH-1:0] last,
    output  logic [S_ID_WIDTH-1:0] rD,
	output  logic [S_ID_WIDTH-1:0] ready,

    //slaves
    output  logic [M_ID_WIDTH-1:0] control,
	output  logic [M_ID_WIDTH-1:0] wD,
	output  logic [M_ID_WIDTH-1:0] valid,
	output  logic [M_ID_WIDTH-1:0] last,
    input   logic [S_ID_WIDTH-1:0] rD,
	input   logic [S_ID_WIDTH-1:0] ready,
    );

    logic clk;
    localparam CLOCK_PERIOD = 20;
    initial begin
        clk <= 0;
            forever begin
                #(CLOCK_PERIOD/2) clk <= ~clk;
            end
    end

    
    initial begin
        @(posedge clk);
        master <= 2'b01;
        slave  <= 2'b10;
        m1_valid <= 1;
        m1_last <= 0;
        m1_wD <= 1;
        m2_valid <= 0;
        m2_last <= 1;
        m2_wD <= 0;
        #(CLOCK_PERIOD*5);
        master <= 2'b10;

    end

endmodule