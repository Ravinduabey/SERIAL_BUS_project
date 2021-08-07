module master #(
    parameter MEMORY_DEPTH = 4096,
    parameter DATA_WIDTH = 16
)( 

	    ///////////////////////
        //===================//
        //  with topModule   //
        //===================// 
	    ///////////////////////
		  
        input logic clk,                            // clock
        input logic rstN,                           // reset
        input logic burst,                          // burst master to slave
        input logic rdWr,                           // read or write: 0 1
        input logic inEx,                           // internal or external
        input logic [DATA_WIDTH-1:0] data,
        input logic [ADDRESS_WIDTH-1:0] address,
        input logic [1:0] slaveId,
        input logic start,
		  
	    output logic doneCom ,
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

localparam ADDRESS_WIDTH = $clog2(MEMORY_DEPTH);

logic [18:0] tempControl;
logic wr;
logic [3:0] fromArbiter;

// define states for the top module
typedef enum logic [1:0]{
    idle,
    startConfig,
    startEndConfig, 
    startCom
 } start_;

start_ state, nextstate;

always_ff @(posedge clk or negedge rstN) begin : mainStateMachine
    if (~rstN) begin 
        state <= idle;
    end
    else begin
        if (start && state == idle) begin
            state <= nextstate;
        end
        else if (start && state == startConfig)  begin
            state <= nextstate;
		end
        else if (start && state == startEndConfig) begin
           state <= nextstate;
       end    
    end
    
end


always_comb begin
    case (state)
        idle           : nextstate = startConfig;
        startConfig    : nextstate = startEndConfig;
        startEndConfig : nextstate = startCom;
//        startCom       :
//			  if (doneCom) begin
//					nextState = done;
//				end
//				else
//					nextState = startCom;
        
        default        : nextstate = idle;
    endcase
end



// define states for the communication process
typedef enum logic [2:0]{
    idleCom,
    reqCom, 
    reqAck,
    masterCom,
	over,
    masterHold,
    masterDone,
    masterSplit
//    done
} comStates;

comStates comState, comNextState;

//logic [3:0] fromArbiter;


logic [2:0] arbGrant;
logic [2:0] arbPStop;
logic [2:0] arbSplit;

always_ff @(posedge clk or negedge rstN) begin 
    if (~rstN) begin
        comState <= idleCom;
    end
    else begin
        if (state == startCom && comState == idleCom) begin
            comState <= comNextState;
        end
        else if (arbGrant == 3'b111 && comState == reqCom) begin
            comState <= comNextState;
        end
        else if (~arbCont && comState == reqAck) begin
            comState <= comNextState;
        end
        else if (arbPStop == 3'b111 /*stop_priority*/ && comState == masterCom) begin
            comState <= comNextState;
        end
        else if (arbSplit == 3'b111 /*stop_split*/ && comState == masterCom) begin
            comState <= comNextState;
        end
		else if (comState == masterHold) begin
            comState <= comNextState;
        end
    end
end


always_comb begin
    case (comState)
        idleCom         : comNextState = reqCom;
        comNextState    : comNextState = reqAck;
        reqAck          : comNextState = masterCom;
	    masterCom       :   
            if (arbPStop == 3'b111) begin
                comNextState = masterHold;
            end
            else if (arbSplit == 3'b111)begin
                comNextState = masterSplit;
            end
            else begin
                comNextState = over;            
            end
        masterHold      : comNextState = masterDone;          
        default         : comNextState = idleCom; 
    endcase
end


// choose write enable signal depending on the state of communication 
initial begin
    if (state == startConfig) begin
        wr <= inEx;
    end
    else if (state == startCom) begin
        wr <= ready;
    end
end



//==========================================//
//Instantiate the bram for the master module//
//==========================================//

bram #(
    .MEMORY_DEPTH               ( MEMORY_DEPTH ),
    .DATA_WIDTH                  ( DATA_WIDTH )
    ) dut(
        .clk            (clk        ),
        .wr             (wr         ),
        .address        (address    ),
        .data           (data     ),
        .q              (dataOut    )
);

// logic counter = 2'b00;
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
       else if (state == startConfig && ~inEx) begin
            tempControl <= {3'b111, slaveId, rdWr, burst, address};
            if (state == startConfig && inEx) begin
                // counter <= counter + 2'b01;

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
