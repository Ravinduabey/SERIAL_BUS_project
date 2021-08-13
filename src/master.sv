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
// localparam CLEAR_NEW = 1'b111;


logic                       wr;
logic                       tempRdWr;
logic                       tempBurst;

logic [1:0]                 clock_counter;

logic [2:0]                 fromArbiter;
logic [2:0]                 arbGrant;
logic [3:0]                 arbiterCounnter;


logic [4:0]                 controlCounter, i;
logic [4:0]                 arbiterRequest, tempArbiterRequest;

logic [18:0]                tempControl;

logic [ADDRESS_WIDTH-1:0]   burstLen;
logic [ADDRESS_WIDTH-1:0]   addressInternal, addresstemp;
logic [ADDRESS_WIDTH-1:0]   addressInternalBurtstBegin, addressInternalBurtstEnd;
logic [DATA_WIDTH-1:0]      dataInternal, internalDataOut, tempReadData;
logic [ADDRESS_WIDTH-1:0]   address_counter;

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

comStates communicationState;



// logic [2:0] arbPStop;
// logic [2:0] arbSplit;

//==========================================//
//Instantiate the bram for the master module//
//==========================================//

bram #(
    .MEMORY_DEPTH               ( MEMORY_DEPTH ),
    .DATA_WIDTH                  ( DATA_WIDTH )
    ) bram(
        .clk            (clk                ),
        .wr             (wr                 ),
        .address        (addressInternal    ),
        .data           (dataInternal       ),
        .q              (internalDataOut    )
);

logic communicationDone;
// logic counter = 2'b00;
// initial begin
//     communicationDone   <= 0;
// end 
    



always_ff @( posedge clk or negedge rstN) begin : topModule
    if (~rstN) begin
        addresstemp         <= 0;
        fromArbiter         <= 0;
        tempReadData        <= 0;
        i                   <= 0;
        control             <= 1'b0;
        wrD                 <= 1'b0;
        valid               <= 1'b0;
        last                <= 1'b0;
        doneCom             <= 1'b0;
        controlCounter      <= 5'd0;
        clock_counter       <= 2'd0;
        arbiterCounnter     <= 3'd0;
        address_counter     <= 0;
        state               <= idle;
        communicationState  <= idleCom;
        
    end
    else begin : topStates
        case (state) 
            //==========================//
            //===========IDLE===========// 
            //==========================//
            idle:
                if (start) begin 
                    state                       <= startConfig;
                    addressInternalBurtstBegin  <= address;
                    tempBurst                   <= burst;
                    state                       <= startConfig;
                    tempControl                 <= {3'b111, slaveId, rdWr, burst, address};
                    arbiterRequest              <= {3'b111, slaveId};
                    tempArbiterRequest          <= {3'b111, slaveId};
                    tempRdWr                    <= rdWr;
                    dataInternal                <= data;
                    addressInternal             <= addresstemp;
                    
                end
                else begin
                    addresstemp         <= 0;
                    fromArbiter         <= 0;
                    tempReadData        <= 0;
                    i                   <= 0;
                    control             <= 1'b0;
                    wrD                 <= 1'b0;
                    valid               <= 1'b0;
                    last                <= 1'b0;
                    doneCom             <= 1'b0;
                    controlCounter      <= 5'd0;
                    clock_counter       <= 2'd0;
                    arbiterCounnter     <= 3'd0;
                    address_counter     <= 0;
                    state               <= idle;
                    communicationState  <= idleCom;                  
                end

            //==========================//
            //=======startConfig========// 
            //==========================//
            startConfig:
                if (start) begin
                    state                       <= startEndConfig;
                    addressInternalBurtstEnd    <= address;
                    wr                          <= 1;
                    dataInternal                <= data;
                    addressInternal             <= addresstemp;
                end
                else begin
                    // state               <= startConfig;
                    // tempControl         <= {3'b111, slaveId, rdWr, burst, address};
                    // arbiterRequest      <= {3'b111, slaveId};
                    // tempArbiterRequest  <= {3'b111, slaveId};
                    // tempRdWr            <= rdWr;
                    
                    
    
                    if (inEx) begin : internalExternalWrite
                        if (tempBurst == 1) begin
                                dataInternal                <= data;
                                addressInternal             <= addresstemp;
                            if (clock_counter < 2'd1) begin
                                wr                          <= 1;
                                addresstemp                 <= addresstemp + 1;
                                clock_counter               <= clock_counter + 2'd1;
                            end

                            else begin
                                wr                          <= 0;
                                clock_counter               <= 2'd0;
                            end
                        end
                        else begin
                            addressInternal             <= addresstemp;
                            dataInternal                <= data;
                            clock_counter               <= clock_counter + 2'd1;
                            if (clock_counter < 2'd1) begin
                                wr                          <= 1;
                                clock_counter               <= clock_counter + 2'd1;
                            end
                            else begin
                                wr                          <= 0;
                                clock_counter               <= 2'd0;
                            end
                        end
                            // else begin
                            // end
                    end
                    // else begin
                        // addressInternal <= address;
                        // addressInternalBurtstBegin <= address;
                        // dataInternal        <= data;
                    // end
                end
            

            //==========================//
            //======startEndConfig======// 
            //==========================//
            startEndConfig:
                if (start) begin
                    state            <= startCom;
                end
                else begin
                    state            <= startEndConfig;
                    wr               <= 0;
                    burstLen         <= addressInternalBurtstEnd - addressInternalBurtstBegin;
                end



            //==========================//
            //=========startCom=========// 
            //==========================//
            startCom:
                if(doneCom == 1'b0) begin : start_internal_communication
                    state           <= startCom;

                    case (communicationState) 
                        idleCom:
                            if (~arbCont) begin
                                communicationState <= reqCom;
                                arbiterCounnter    <= 0;
                            end
                            // else begin
                            //     communicationState <= idleCom;
                            // end

                        reqCom:
                            if (arbiterCounnter < 3'd6) begin
                                arbiterCounnter         <= arbiterCounnter + 3'd1;
                                arbSend                 <= arbiterRequest[4];
                                arbiterRequest          <= {arbiterRequest[3:0], 1'b0};
                                fromArbiter[2:1]        <= fromArbiter[1:0];
                                fromArbiter[0]          <= arbCont;
                            end
                            else if (arbiterCounnter >= 3'd6) begin
                                // arbiterCounnter         <= arbiterCounnter + 3'd1;
                                // fromArbiter             <= {fromArbiter[2:1], arbCont};
                                fromArbiter[2:1]    <= fromArbiter[1:0];
                                fromArbiter[0]      <= arbCont;
                                if (fromArbiter == 3'b111) begin
                                    arbiterCounnter     <= 3'd0;
                                    arbSend             <= 1'b1;
                                    communicationState  <= reqAck;
                                end
                                else begin
                                    // arbiterCounnter     <= 3'd0;
                                    // arbiterRequest      <= tempArbiterRequest;
                                    communicationState  <= reqCom;
                                end
                            end
                        
                        reqAck:
                            if (arbiterCounnter < 3'd2) begin
                                arbSend             <= 1'b1;
                                arbiterCounnter     <= arbiterCounnter + 3'd1;
                                communicationState  <= reqAck;
                            end
                            else if (arbiterCounnter == 3'd2) begin
                                arbSend             <= 1'b1;
                                arbiterCounnter     <= 3'd0;
                                fromArbiter         <= 3'b000;
                                control             <= tempControl[18];
                                tempControl         <= {tempControl[17:0] ,1'b0};
                                controlCounter      <= controlCounter + 5'd1;
                                communicationState  <= masterCom;
                            end

                        masterCom:
                        
                            if (arbCont == 0) begin
                                // arbsend what???
                                control             <= tempControl[18];
                                tempControl         <= {tempControl[17:0] ,1'b0};
                                controlCounter      <= controlCounter + 5'd1;

                                // fromArbiter             <= {fromArbiter[2:1], arbCont};
                                fromArbiter[2:1]    <= fromArbiter[1:0];
                                fromArbiter[0]      <= arbCont;
                                
                                if (controlCounter == 5'd19) begin : startSendOrReceive
                                    controlCounter      <= controlCounter;
                                    if (fromArbiter == 3'b000) begin
                                        
                                        /*
                                        add two counters
                                            burst counts if stopped due to priority issues 
                                            current bit pointer in the case of the above issue
                                        */
                                        if (tempRdWr == 1 && burstLen == 0) begin
                                            // wrD         <= dataOut[0];
                                            // dataOut     <= {1'b0,dataOut[DATA_WIDTH-2:0]};
                                        end
                                        else if (tempRdWr == 1 && burstLen == 1) begin
                                            /*
                                            do burst write
                                            */
                                        end
                                        else if (tempRdWr == 0 && burstLen > 0) begin: single_read
                                            if (ready) begin
                                                if (i < 4'd8) begin
                                                    tempReadData[i] <= rD;
                                                    i               <= i + 4'd1;
                                                end
                                                if (i == 4'd8) begin
                                                dataInternal        <= tempReadData;
                                                addressInternal     <= addressInternalBurtstBegin;
                                                wr                  <= 1;
                                                i                   <= i + 4'd1;    
                                                end
                                                if (i > 4'd8) begin
                                                    i <= 4'd0;
                                                    wr <=0;
                                                    communicationState <= over;
                                                end
                                            end
                                            /*
                                            single read
                                            */
                                        end
                                        else if (tempRdWr == 0 && burstLen == 0) begin
                                            /*
                                            burst read
                                            */
                                        end
                                        else if (fromArbiter <= 3'b111)begin
                                            communicationState <= masterHold;
                                        end
                                    end
                                end
                            end

                        masterHold: communicationState <= masterDone;

                        over: 
                            begin
                                doneCom         <= 1;
                                dataOut         <= dataInternal;
                                addressInternal <= address;
                            end

                    endcase
                end
            //==========================//
    
            //===========Done===========// 
            //==========================//
                else begin
                    state <= done;
                end
        
        endcase
        end
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
    // end
    
    end
// assign dataInternal = data;
endmodule: master 
