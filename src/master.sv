module master #(
    parameter ADDRESS_DEPTH = $clog2(4096),
    parameter DATA_WIDTH = 16
)( 

	    ///////////////////////
        //===================//
        //  with topModule   //
        //===================// 
	    ///////////////////////
		  
        input logic clk,                            // clock
        input logic rstN,                           // reset
        input logic burst,                          // burst
        input logic rdWr,                           // read or write: 0 1
        input logic inEx,                           // internal or external
        input logic [DATA_WIDTH-1:0] data,
        input logic [ADDRESS_DEPTH-1:0] address,
        input logic [1:0] slaveId,
        input logic start,
		  
	    output logic doneCom = 1'b0,
        output logic [DATA_WIDTH-1:0] dataOut,

		  
	    ///////////////////////
        //===================//
        //    with slave     //
        //===================// 
	    ///////////////////////
        input logic rD,         
        input logic ready,

	    output logic control,           // START|SLAVE_ID|r/w|B|address| 
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



typedef enum logic [1:0]{
    idle,
    startConfig, 
    startCom
    // done
 } start_;

start_ state, nextstate;

always_ff @(posedge clk or negedge rstN) begin
    if (~rstN) begin 
        state <= idle;
    end
    else if (start && state == idle) begin
        state <= nextstate;
    end
    else if (start && state == startConfig)  begin
        state <= nextstate;
    end
    // if (doneCom) begin
    //     state <= done;
    // end     
end


always_comb begin
case (state)
idle           : nextstate = startConfig;
startConfig    : nextstate = startCom;
default        : nextstate = idle;
endcase
end

always_ff @( posedge clk or negedge rstN) begin : topModule
    if (~rstN) begin
        control <= 1'b0;
        wrD     <= 1'b0;
        valid   <= 1'b0;
        last    <= 1'b0;
        doneCom <= 1'b0;
    end
    else begin
        if (state == idle) begin
            control <= 1'b0;
            wrD     <= 1'b0;
            valid   <= 1'b0;
            last    <= 1'b0;
            doneCom <= 1'b0;
        end
       else if (state == startConfig) begin
            control <= {3'b111, slaveId, rdWr, burst, address};
            if (state == startConfig && inEx) begin
                /*
                Write the external data from masters zeroth address
                till all data is received
                */
            end
       end
       else if (state == startCom) begin
           /*
           start communication process
           */
       end
        // else if (state == done) begin
        //     /*
        //     Allow external read for the master
        //     */
        // end
    end
    
end

endmodule: master 
