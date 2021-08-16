module master #(
    parameter MEMORY_DEPTH  = 4096,
    parameter DATA_WIDTH    = 16,
    parameter NO_SLAVES     = 2
)( 

	    ///////////////////////
        //===================//
        //  with topModule   //
        //===================// 
	    ///////////////////////
		  
        input   logic                             clk,      // clock
        input   logic                             rstN,     // reset
        input   logic                             burst,                          
        input   logic                             rdWr,     // read or write: 0 1
        input   logic                             inEx,     // internal or external
        input   logic [DATA_WIDTH-1:0]            data,
        input   logic [$clog2(MEMORY_DEPTH)-1:0]  address,
        input   logic [NO_SLAVES-1:0]             slaveId,
        input   logic                             start,
        input   logic                             eoc,
		  
	    output  logic                             doneCom,
        output  logic [DATA_WIDTH-1:0]            dataOut,

		  
	    ///////////////////////
        //===================//
        //    with slave     //
        //===================// 
	    ///////////////////////
        input   logic                             rD,         
        input   logic                             ready,

	    output  logic                             control, // START|SLAVE_ID|r/w|B|address| 
        output  logic                             wrD,
        output  logic                             valid,
        output  logic                             last,
		  

        ///////////////////////
        //===================//
        //    with arbiter   //
        //===================// 
	    ///////////////////////
        input   logic                             arbCont,


        output  logic                             arbSend
);




localparam ADDRESS_WIDTH = $clog2(MEMORY_DEPTH);
localparam CONTROL_LEN = 7 + ADDRESS_WIDTH;



logic                       wr;
logic                       tempRdWr;
logic                       tempBurst;
integer 				    j, k;

logic [1:0]                 clock_counter;

logic [1:0]                 fromArbiter;
logic [2:0]                 arbGrant;
logic [4:0]                 arbiterCounnter;

logic [4:0]                 controlCounter;
logic [4:0]                 arbiterRequest, tempArbiterRequest;

logic [CONTROL_LEN-1:0]     tempControl,tempControl_2;

logic [ADDRESS_WIDTH-1:0]   burstLen;
logic [ADDRESS_WIDTH-1:0]   addressInternal, addresstemp;
logic [ADDRESS_WIDTH-1:0]   addressInternalBurtstBegin, addressInternalBurtstEnd;
logic [DATA_WIDTH-1:0]      dataInternal, internalDataOut, tempReadData;
logic [ADDRESS_WIDTH-1:0]   address_counter;

logic [$clog2(DATA_WIDTH):0] i;

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
typedef enum logic [3:0]{
    idleCom,
    reqCom, 
    reqAck,
    masterCom,
    masterHold,
    masterDone,
    masterSplit,
    splitComContinue,
	over
} comStates;

comStates communicationState;

typedef enum logic [2:0]{
    checkState,
    controlSignal,
    singleRead, 
    burstRead,
    singleWrite,
    burstWrite
} internalComStates;

internalComStates internalComState;


//==========================================//
//Instantiate the bram for the master module//
//==========================================//

masterBram #(
    .MEMORY_DEPTH               ( MEMORY_DEPTH  ),
    .DATA_WIDTH                 ( DATA_WIDTH    ),
    .MEM_INIT_FILE              ("mem.txt"      )
    ) bram(
        .clk            (clk                ),
        .wr             (wr                 ),
        .address        (addressInternal    ),
        .data           (dataInternal       ),
        .q              (internalDataOut    )
);

logic communicationDone;


always_ff @( posedge clk or negedge rstN) begin : topModule
    if (~rstN) begin
        addresstemp         <= 0;
        fromArbiter         <= 0;
        tempReadData        <= 0;
        i                   <= 0;
        control             <= 0;
        wrD                 <= 0;
        valid               <= 0;
        last                <= 0;
        doneCom             <= 0;
        controlCounter      <= 0;
        clock_counter       <= 0;
        arbiterCounnter     <= 0;
        address_counter     <= 0;
        j                   <= 0;
        k                   <= 0;
        state               <= idle;
        communicationState  <= idleCom;
        internalComState    <= checkState;
        
    end
    else begin : topStates
        case (state) 
            //==========================//
            //===========IDLE===========// 
            //==========================//
            idle:
                if (start && ~eoc) begin 
                    state                       <= startConfig;
                    addressInternalBurtstBegin  <= address;
                    tempBurst                   <= burst;
                    tempControl                 <= {3'b111, slaveId, rdWr, burst, address};
                    tempControl_2               <= {3'b111, slaveId, rdWr, burst, address};
                    arbiterRequest              <= {3'b111, slaveId};
                    tempArbiterRequest          <= {3'b111, slaveId};
                    tempRdWr                    <= rdWr;
                    dataInternal                <= data;
                    addressInternal             <= addresstemp;
                    
                end
                else if (~start && eoc) begin
                    state <= done;
                end
                else if (~start && ~eoc)begin
                    addresstemp         <= 0;
                    fromArbiter         <= 0;
                    tempReadData        <= 0;
                    i                   <= 0;
                    control             <= 0;
                    wrD                 <= 0;
                    valid               <= 0;
                    last                <= 0;
                    doneCom             <= 0;
                    controlCounter      <= 0;
                    clock_counter       <= 0;
                    arbiterCounnter     <= 0;
                    address_counter     <= 0;
                    j                   <= 0;
                    k                   <= 0;
                    state               <= idle;
                    communicationState  <= idleCom;
                    internalComState    <= checkState;
                end

            //==========================//
            //=======startConfig========// 
            //==========================//
            startConfig:
                if (start) begin
                    if (inEx) begin
                        state                       <= startEndConfig;
                        addressInternalBurtstEnd    <= address;
                        wr                          <= 1;
                        dataInternal                <= data;
                        addressInternal             <= addresstemp;
                    end
                    else begin
                        addressInternalBurtstEnd    <= address;
                        addressInternalBurtstBegin  <= address;
                        state                       <= startEndConfig;
                    end
                end
                else begin                   
                    
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
                    burstLen         <= addressInternalBurtstEnd - addressInternalBurtstBegin + 1;
                    if(burstLen == 0)begin
                        tempControl[12]     <= 0;
                        tempControl_2[12]   <= 0;
                    end
                    else begin
                        tempControl[12]     <= 1;
                        tempControl_2[12]   <= 1;
                    end
                end



            //==========================//
            //=========startCom=========// 
            //==========================//
            startCom:
                if(doneCom == 1'b0) begin : start_internal_communication
                    state               <= startCom;
                    fromArbiter[1]      <= fromArbiter[0];
                    fromArbiter[0]      <= arbCont;
                    case (communicationState) 
                        idleCom:
                            if (~arbCont) begin
                                communicationState  <= reqCom;
                                arbiterCounnter     <= 0;
                                controlCounter      <= 0;
                                arbiterRequest      <= tempArbiterRequest;
                            end

                        reqCom:
                            if (arbiterCounnter < 4'd6) begin
                                arbSend                 <= arbiterRequest[4];
                                arbiterRequest          <= {arbiterRequest[3:0], 1'b0};
                                arbiterCounnter         <= arbiterCounnter + 1;
                            end
                            else if (arbiterCounnter == 4'd6) begin
                                arbiterCounnter     <= arbiterCounnter;
                                if (fromArbiter == 2'b11) begin: ClearNew
                                    arbSend             <= 1'b1;
                                    tempControl         <= tempControl_2;
                                    controlCounter      <= 0;
                                    communicationState  <= reqAck;
                                end
                                else if (fromArbiter == 2'b10) begin: ClearSplit
                                    arbSend             <= 1'b1;
                                    communicationState  <= splitComContinue;
                                end
                                else begin 
                                    communicationState  <= reqCom;
                                end
                            end
                        
                        reqAck:
                            if (arbiterCounnter < 4'd8) begin
                                arbSend             <= 1'b1;
                                arbiterCounnter     <= arbiterCounnter + 3'd1;
                                communicationState  <= reqAck;
                            end
                            else if (arbiterCounnter == 4'd8) begin
                                arbSend             <= 1'b1;
                                arbiterCounnter     <= 3'd0;
                                control             <= tempControl[18];
                                tempControl         <= {tempControl[17:0] ,1'b0};
                                controlCounter      <= controlCounter + 5'd1;
                                communicationState  <= masterCom;
                            end

                        masterCom:
                           
                            if (fromArbiter == 2'b00 || fromArbiter == 2'b01) begin

                                if (controlCounter < CONTROL_LEN) begin
                                    control             <= tempControl[18];
                                    tempControl         <= {tempControl[17:0] ,1'b0};
                                    controlCounter      <= controlCounter + 5'd1;

                                    
                                end  
                                else if (controlCounter == CONTROL_LEN) begin : startSendOrReceive
                                    controlCounter      <= controlCounter;
                                    control             <= 0;
                                    

                                    //=======================//
                                    //=====Read or Write=====//
                                    //=======================//
                                    case(internalComState)

                                    checkState:
                                        if (tempRdWr == 1 && (arbCont == 0 || fromArbiter == 2'd1)) begin
                                            if (burstLen == 0) begin
                                                internalComState <= singleWrite;
                                                addressInternal  <= addressInternalBurtstBegin;
                                                valid            <= 0;
                                                wr               <= 0;
                                            end
                                            else begin
                                                addressInternal  <= addressInternalBurtstBegin;
                                                wr               <= 0;
                                                if (~valid)begin
                                                    if (i < 2)begin
                                                        i = i +1;
                                                    end
                                                    else begin
                                                        tempReadData                <= internalDataOut;
                                                        addressInternalBurtstBegin  <= addressInternalBurtstBegin + 1;
                                                        i                           <= 0; 
                                                        internalComState            <= burstWrite;
                                                    end
                                                end
                                            end
                                        end
                                        else if (tempRdWr == 0 && (arbCont == 0 || fromArbiter == 2'd1)) begin
                                            if (burstLen == 0) begin
                                                internalComState <= singleRead;
                                                valid            <= 1;
                                            end
                                            else begin
                                                internalComState <= burstRead;
                                                valid            <= 1;
                                            end
                                        end

                                    singleRead:
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

                                    burstRead:
                                        if (ready) begin
                                            if(burstLen > 0) begin
                                                if (i < DATA_WIDTH) begin
                                                    tempReadData[DATA_WIDTH-1-i] <= rD;
                                                    i               <= i + 1;
                                                    wr              <= 0;
                                                    valid           <= 1;
                                                end
                                                else if (i == DATA_WIDTH) begin
                                                    tempReadData[i]             <= rD;
                                                    dataInternal                <= tempReadData;
                                                    addressInternal             <= addressInternalBurtstBegin;
                                                    addressInternalBurtstBegin  <= addressInternalBurtstBegin + 1;
                                                    wr                  <= 1;
                                                    i                   <= 0; 
                                                    valid               <= 0;
                                                    burstLen            <= burstLen - 1;   
                                                end
                                                // else if (i > DATA_WIDTH) begin
                                                //     i <= 0;
                                                //     wr <=0;
                                                //     tempReadData <= 0;
                                                //     addressInternalBurtstBegin  <= addressInternalBurtstBegin + 1;
                                                //     burstLen <= burstLen - 1;
                                                // end
                                            end
                                            else begin
                                                wr <= 0;
                                                communicationState <= over;
                                            end

                                        end
                                    
                                    singleWrite:
                                        if (~valid)begin
                                            if (i < 1)begin
                                                i = i +1;
                                            end
                                            else begin
                                                tempReadData    <= internalDataOut;
                                                i               <= 0;
                                                valid           <= 1;                                                
                                            end
                                        end
                                        else begin
                                            if (i < DATA_WIDTH) begin
                                                wrD     <= tempReadData[DATA_WIDTH-1-i];
                                                i       <= i + 1;
                                            end
                                            else begin
                                                valid   <= 0;
                                                communicationState <= over;
                                            end
                                        end 
                                    
                                    burstWrite:
                                        if(burstLen > 1) begin
                                            if (i < DATA_WIDTH) begin
                                                wrD                 <= tempReadData[DATA_WIDTH-1-i];
                                                addressInternal     <= addressInternalBurtstBegin;
                                                i                   <= i + 1;
                                                valid               <= 1;
                                            end
                                            else if (i == DATA_WIDTH) begin
                                                i                           <= 0;
                                                burstLen                    <= burstLen -1 ;
                                                addressInternalBurtstBegin  <= addressInternalBurtstBegin + 1;
                                                tempReadData                <= internalDataOut;
                                                valid                       <= 0;
                                            end
                                        end
                                        else if (burstLen == 1) begin
                                            if (i < DATA_WIDTH-1) begin
                                                wrD                 <= tempReadData[DATA_WIDTH-1-i];
                                                addressInternal     <= addressInternalBurtstBegin;
                                                i                   <= i + 1;
                                                valid               <= 1;
                                            end
                                            else if (i == DATA_WIDTH-1) begin
                                                i                           <= 0;
                                                wrD                         <= tempReadData[DATA_WIDTH-1-i];
                                                burstLen                    <= burstLen -1 ;
                                                addressInternalBurtstBegin  <= addressInternalBurtstBegin + 1;
                                                tempReadData                <= internalDataOut;
                                                valid                       <= 1;
                                                last                        <= 1;
                                            end
                                        end
                                        else begin
                                            valid               <= 0;
                                            communicationState  <= over;
                                            last                <= 0;
                                        end
                                    endcase 
                                end
                            end


                            else if (fromArbiter == 2'b10)begin: priorityStop
                                communicationState <= masterHold;

                                if (burstLen == 0) begin
                                    if (tempRdWr == 0) begin
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
                                    end
                                    else begin
                                        if (~valid)begin
                                            if (i < 1)begin
                                                i = i +1;
                                            end
                                            else begin
                                                tempReadData    <= internalDataOut;
                                                i               <= 0;
                                                valid           <= 1;                                                
                                            end
                                        end
                                        else begin
                                            if (i < DATA_WIDTH) begin
                                                wrD     <= tempReadData[DATA_WIDTH-1-i];
                                                i       <= i + 1;
                                            end
                                            else begin
                                                valid   <= 0;
                                                communicationState <= over;
                                            end
                                        end 
                                    end
                                end
                                else begin
                                    if (tempRdWr == 0)begin 
                                        if (ready) begin    
                                            if(burstLen > 1) begin
                                                if (i < DATA_WIDTH) begin
                                                    tempReadData[DATA_WIDTH-1-i] <= rD;
                                                    i               <= i + 1;
                                                    wr              <= 0;
                                                    valid           <= 1;
                                                end
                                                else if (i == DATA_WIDTH) begin
                                                    tempReadData[i]             <= rD;
                                                    dataInternal                <= tempReadData;
                                                    addressInternal             <= addressInternalBurtstBegin;
                                                    addressInternalBurtstBegin  <= addressInternalBurtstBegin + 1;
                                                    wr                  <= 1;
                                                    i                   <= 0;
                                                    burstLen            <= burstLen - 1;
                                                    communicationState  <= masterDone;   
                                                end
                                            end
                                            else if (burstLen == 1)begin
                                                if (i < DATA_WIDTH) begin
                                                        tempReadData[DATA_WIDTH-1-i] <= rD;
                                                        i               <= i + 1;
                                                        wr              <= 0;
                                                        valid           <= 1;
                                                    end
                                                    else if (i == DATA_WIDTH) begin
                                                        tempReadData[i]             <= rD;
                                                        dataInternal                <= tempReadData;
                                                        addressInternal             <= addressInternalBurtstBegin;
                                                        addressInternalBurtstBegin  <= addressInternalBurtstBegin + 1;
                                                        wr                  <= 1;
                                                        i                   <= 0; 
                                                        valid               <= 0;
                                                        burstLen            <= burstLen - 1;
                                                        communicationState  <= over;
                                                    end
                                            end
                                        end
                                    end

                                    else begin: burstWriteMode
                                        if(burstLen > 1) begin
                                            if (i < DATA_WIDTH) begin
                                                wrD                 <= tempReadData[DATA_WIDTH-1-i];
                                                addressInternal     <= addressInternalBurtstBegin;
                                                i                   <= i + 1;
                                                valid               <= 1;
                                            end
                                            else if (i == DATA_WIDTH) begin
                                                i                           <= 0;
                                                burstLen                    <= burstLen -1 ;
                                                addressInternalBurtstBegin  <= addressInternalBurtstBegin + 1;
                                                tempReadData                <= internalDataOut;
                                                valid                       <= 0;
                                                communicationState          <= masterDone;
                                            end
                                        end
                                        else if (burstLen == 1) begin
                                            if (i < DATA_WIDTH-1) begin
                                                wrD                 <= tempReadData[DATA_WIDTH-1-i];
                                                addressInternal     <= addressInternalBurtstBegin;
                                                i                   <= i + 1;
                                                valid               <= 1;
                                            end
                                            else if (i == DATA_WIDTH-1) begin
                                                i                           <= 0;
                                                wrD                         <= tempReadData[DATA_WIDTH-1-i];
                                                burstLen                    <= burstLen -1 ;
                                                addressInternalBurtstBegin  <= addressInternalBurtstBegin + 1;
                                                tempReadData                <= internalDataOut;
                                                valid                       <= 1;
                                                last                        <= 1;
                                                communicationState          <= over;
                                            end
                                        end
                                    end: burstWriteMode
                                end




                            end
                            else if (fromArbiter == 2'b11)begin: splitStop
                                communicationState <= masterSplit;                                
                            end
                            

                        masterHold:

                            if (burstLen == 0) begin: singleMode
                                if (tempRdWr == 0) begin
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
                                end
                                else begin
                                    if (~valid)begin
                                        if (i < 1)begin
                                            i = i +1;
                                        end
                                        else begin
                                            tempReadData    <= internalDataOut;
                                            i               <= 0;
                                            valid           <= 1;                                                
                                        end
                                    end
                                    else begin
                                        if (i < DATA_WIDTH) begin
                                            wrD     <= tempReadData[DATA_WIDTH-1-i];
                                            i       <= i + 1;
                                        end
                                        else begin
                                            valid   <= 0;
                                            communicationState <= over;
                                        end
                                    end 
                                end
                            end
                            else begin: burstMode
                                if (tempRdWr == 0)begin: burstReadMode
                                    if (ready) begin    
                                        if(burstLen > 1) begin
                                            if (i < DATA_WIDTH) begin
                                                tempReadData[DATA_WIDTH-1-i] <= rD;
                                                i               <= i + 1;
                                                wr              <= 0;
                                                valid           <= 1;
                                            end
                                            else if (i == DATA_WIDTH) begin
                                                tempReadData[i]             <= rD;
                                                dataInternal                <= tempReadData;
                                                addressInternal             <= addressInternalBurtstBegin;
                                                addressInternalBurtstBegin  <= addressInternalBurtstBegin + 1;
                                                wr                          <= 1;
                                                i                           <= 0;
                                                burstLen                    <= burstLen - 1;
                                                communicationState          <= masterDone;   
                                            end
                                        end
                                        else if (burstLen == 1)begin
                                            if (i < DATA_WIDTH) begin
                                                    tempReadData[DATA_WIDTH-1-i] <= rD;
                                                    i               <= i + 1;
                                                    wr              <= 0;
                                                    valid           <= 1;
                                                end
                                                else if (i == DATA_WIDTH) begin
                                                    tempReadData[i]             <= rD;
                                                    dataInternal                <= tempReadData;
                                                    addressInternal             <= addressInternalBurtstBegin;
                                                    addressInternalBurtstBegin  <= addressInternalBurtstBegin + 1;
                                                    wr                  <= 1;
                                                    i                   <= 0; 
                                                    valid               <= 0;
                                                    burstLen            <= burstLen - 1;
                                                    communicationState  <= over;
                                                end
                                        end
                                    end
                                end: burstReadMode

                                else begin: burstWriteMode
                                    if(burstLen > 1) begin
                                        if (i < DATA_WIDTH) begin
                                            wrD                 <= tempReadData[DATA_WIDTH-1-i];
                                            addressInternal     <= addressInternalBurtstBegin;
                                            i                   <= i + 1;
                                            valid               <= 1;
                                        end
                                        else if (i == DATA_WIDTH) begin
                                            i                           <= 0;
                                            burstLen                    <= burstLen -1 ;
                                            addressInternalBurtstBegin  <= addressInternalBurtstBegin + 1;
                                            tempReadData                <= internalDataOut;
                                            valid                       <= 0;
                                            communicationState          <= masterDone;
                                        end
                                    end
                                    else if (burstLen == 1) begin
                                        if (i < DATA_WIDTH-1) begin
                                            wrD                 <= tempReadData[DATA_WIDTH-1-i];
                                            addressInternal     <= addressInternalBurtstBegin;
                                            i                   <= i + 1;
                                            valid               <= 1;
                                        end
                                        else if (i == DATA_WIDTH-1) begin
                                            i                           <= 0;
                                            wrD                         <= tempReadData[DATA_WIDTH-1-i];
                                            burstLen                    <= burstLen -1 ;
                                            addressInternalBurtstBegin  <= addressInternalBurtstBegin + 1;
                                            tempReadData                <= internalDataOut;
                                            valid                       <= 1;
                                            last                        <= 1;
                                            communicationState          <= over;
                                        end
                                    end
                                end: burstWriteMode
                            end

                        masterDone: begin
                            communicationState <= idleCom;
                            wr                 <= 0;
                            valid              <= 0;
                        end 
                        /*
                        if arbiter needs to set everything from scratch: masteridle
                        else masterAckownledgement
                        */
                        
                        masterSplit: communicationState <= reqCom;
                        
                        //=======================================//
                        //   Split Communication continue state  //
                        //=======================================//
                        splitComContinue: 
                            if (fromArbiter == 2'b00 || fromArbiter == 2'b01) begin
                                fromArbiter[1]      <= fromArbiter[0];
                                fromArbiter[0]      <= arbCont;
                                if (burstLen == 0) begin 
                                    if (tempRdWr == 0) begin
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
                                    end
                                end
                                else begin
                                    if (ready) begin    
                                        if(burstLen > 1) begin
                                            if (i < DATA_WIDTH) begin
                                                tempReadData[DATA_WIDTH-1-i] <= rD;
                                                i               <= i + 1;
                                                wr              <= 0;
                                                valid           <= 1;
                                            end
                                            else if (i == DATA_WIDTH) begin
                                                tempReadData[i]             <= rD;
                                                dataInternal                <= tempReadData;
                                                addressInternal             <= addressInternalBurtstBegin;
                                                addressInternalBurtstBegin  <= addressInternalBurtstBegin + 1;
                                                wr                          <= 1;
                                                i                           <= 0;
                                                burstLen                    <= burstLen - 1;
                                            end
                                        end
                                        else if (burstLen == 1)begin
                                            if (i < DATA_WIDTH) begin
                                                    tempReadData[DATA_WIDTH-1-i] <= rD;
                                                    i               <= i + 1;
                                                    wr              <= 0;
                                                    valid           <= 1;
                                                end
                                                else if (i == DATA_WIDTH) begin
                                                    tempReadData[i]             <= rD;
                                                    dataInternal                <= tempReadData;
                                                    addressInternal             <= addressInternalBurtstBegin;
                                                    addressInternalBurtstBegin  <= addressInternalBurtstBegin + 1;
                                                    wr                  <= 1;
                                                    i                   <= 0; 
                                                    valid               <= 0;
                                                    burstLen            <= burstLen - 1;
                                                    communicationState  <= over;
                                                end
                                        end
                                    end
                                end
                            end
                            else if (fromArbiter == 2'b10)begin 
                                communicationState <= masterHold;

                                if (burstLen == 0) begin
                                    if (tempRdWr == 0) begin
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
                                    end
                                end
                                else begin
                                    if (tempRdWr == 0)begin 
                                        if (ready) begin    
                                            if(burstLen > 1) begin
                                                if (i < DATA_WIDTH) begin
                                                    tempReadData[DATA_WIDTH-1-i]    <= rD;
                                                    i                               <= i + 1;
                                                    wr                              <= 0;
                                                    valid                           <= 1;
                                                end
                                                else if (i == DATA_WIDTH) begin
                                                    tempReadData[i]             <= rD;
                                                    dataInternal                <= tempReadData;
                                                    addressInternal             <= addressInternalBurtstBegin;
                                                    addressInternalBurtstBegin  <= addressInternalBurtstBegin + 1;
                                                    wr                          <= 1;
                                                    i                           <= 0;
                                                    burstLen                    <= burstLen - 1;
                                                    communicationState          <= masterDone;   
                                                end
                                            end
                                            else if (burstLen == 1)begin
                                                if (i < DATA_WIDTH) begin
                                                        tempReadData[DATA_WIDTH-1-i]    <= rD;
                                                        i                               <= i + 1;
                                                        wr                              <= 0;
                                                        valid                           <= 1;
                                                    end
                                                    else if (i == DATA_WIDTH) begin
                                                        tempReadData[i]             <= rD;
                                                        dataInternal                <= tempReadData;
                                                        addressInternal             <= addressInternalBurtstBegin;
                                                        addressInternalBurtstBegin  <= addressInternalBurtstBegin + 1;
                                                        wr                  <= 1;
                                                        i                   <= 0; 
                                                        valid               <= 0;
                                                        burstLen            <= burstLen - 1;
                                                        communicationState  <= over;
                                                    end
                                            end
                                        end
                                    end
                                end
                            end
                        
                        

                        over: 
                            begin
                                last            <= 0;
                                valid           <= 0;
                                doneCom         <= 1;
                                wr              <= 0;
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
            done: 
                begin
                    doneCom         <= 1;
                    addressInternal <= address;
                    dataOut         <= internalDataOut;    
                end
        endcase
        end
    
    end

endmodule: master 
