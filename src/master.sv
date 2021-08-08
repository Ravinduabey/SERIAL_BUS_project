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
        input logic [$clog2(MEMORY_DEPTH)-1:0] address,
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
typedef enum logic [2:0]{
    idle,
    startConfig,
    startEndConfig, 
    startCom,
    done
 } start_;

start_ state,nextstate;




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
} comStates;

comStates comState, comNextState;


/* 
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
        else if (arbPStop == 3'b111 /stop_priority/ && comState == masterCom) begin
            comState <= comNextState;
        end
        else if (arbSplit == 3'b111 /stop_split/ && comState == masterCom) begin
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
*/




logic [ADDRESS_WIDTH-1:0] addressInternal;
logic [ADDRESS_WIDTH-1:0] addressInternalBurtstEnd;
logic clock_counter;
logic burstLen;
//logic [2:0] fromArbiter;
// logic [2:0] arbGrant;
// logic [2:0] arbPStop;
// logic [2:0] arbSplit;

//==========================================//
//Instantiate the bram for the master module//
//==========================================//

bram #(
    .MEMORY_DEPTH               ( MEMORY_DEPTH ),
    .DATA_WIDTH                  ( DATA_WIDTH )
    ) bram(
        .clk            (clk        ),
        .wr             (wr         ),
        .address        (addressInternal    ),
        .data           (data       ),
        .q              (dataOut    )
);

logic communicationDone;
// logic counter = 2'b00;
initial begin
    communicationDone <= 0;
end 
    



always_ff @( posedge clk or negedge rstN) begin : topModule
    if (~rstN) begin
        control <= 1'b0;
        wrD     <= 1'b0;
        valid   <= 1'b0;
        last    <= 1'b0;
        doneCom <= 1'b0;
        state   <= idle;
        comState <= idleCom;
    end
    else begin : topStates
        case (state) 
            //==========================//
            //===========IDLE===========// 
            //==========================//
            idle:
                if (start) begin 
                    state <= startConfig;
                end
                else begin
                    state <= idle;
                    control <= 1'b0;
                    wrD     <= 1'b0;
                    valid   <= 1'b0;
                    last    <= 1'b0;
                    doneCom <= 1'b0;                    
                end

            //==========================//
            //=======startConfig========// 
            //==========================//
            startConfig:
                if (start) begin
                    state <= startEndConfig;
                end
                else begin
                    state <= startConfig;
                    tempControl <= {3'b111, slaveId, rdWr, burst, address};
                    if (inEx) begin : internalExternalWrite
                        if (clock_counter == 2'd0) begin
                            addressInternal <= address;
                            wr <= 1;
                        end
                        else if (clock_counter == 2'd1) begin
                            addressInternalBurtstEnd <= address;
                            wr <= 0;
                        end
                        else begin
                            if (clock_counter == 2'd3)begin
                                burstLen <= addressInternalBurtstEnd - addressInternal;
                            end
                        end 
                        clock_counter <= clock_counter + 2'd1;
                    end
                    else begin
                        addressInternal <= address;
                    end
                end
            
            //==========================//
            //======startEndConfig======// 
            //==========================//
            startEndConfig:
                if (start) begin
                    state <= startCom;
                end
                else begin
                    state <= startEndConfig;
                end

            startCom:
                if(doneCom == 1'b0) begin
                    valid <= 1'b1;
                    state <= startCom;

                end
                else begin
                    state <= done;
                end
        
        endcase
    //     if (state == idle) begin
            
    //     end
    //    else if (state == startConfig && ~inEx) begin
    //         tempControl <= {3'b111, slaveId, rdWr, burst, address};
    //         if (state == startConfig && inEx) begin
    //             // counter <= counter + 2'b01;

    //             /*
    //             Write the external data from masters zeroth address
    //             till all data is received
    //             */
    //         end
    //    end
    //    else if (state == startCom) begin
    //        /*
    //        start communication process
    //        */
    //    end
        // else if (state == done) begin
        //     /*
        //     Allow external read for the master
        //     */
        // end
    end
    
end

endmodule: master 
