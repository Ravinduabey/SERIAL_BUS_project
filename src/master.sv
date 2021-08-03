module master #(
    parameter ADDRESS_DEPTH = $clog2(4096),
    parameter DATA_WIDTH = 16
)( 

		  ///////////////////////
        //===================//
        //  with topModule   //
        //===================// 
		  ///////////////////////
		  
        input logic clk, 
        input logic rstN,
        input logic burst,
        input logic rdWr,
        input logic inEx,
        input logic [DATA_WIDTH-1:0] data,
        input logic [ADDRESS_DEPTH-1:0] address,
        input logic [ADDRESS_DEPTH-1:0] slaveId,
		  
		  output logic doneCom,
        output logic [DATA_WIDTH-1:0] dataOut,

		  
		  ///////////////////////
        //===================//
        //    with slave     //
        //===================// 
		  ///////////////////////
        input logic rD,
        input logic ready,
		  
		  output logic control,
        output logic wrD,
        output logic valid,
        output logic last,
		  

		  ///////////////////////
        //===================//
        //    with arbiter   //
        //===================// 
		  ///////////////////////
        input logic arbCont,


        output logic arbSend
);


endmodule: master 