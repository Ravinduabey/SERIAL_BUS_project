module masterExternal #(
    parameter DATA_WIDTH    = 8,        // datawidth of the sent data
    parameter logic [DATA_WIDTH-1:0] DATA_FROM_TOP = 8'b00001010,    // initial start data
    parameter CLK_FREQ     = 5, // internal clock frequency
    parameter CLOCK_DURATION = 1, // how long the data should be displayed in seconds
    parameter NUM_OF_SLAVES = 4,
    parameter SLAVEID = 3'b101
    // parameter SLAVES        = 4,
    // parameter SLAVE_WIDTH   = $clog2(SLAVES + 1)
)( 

	    ///////////////////////
        //===================//
        //  with topModule   //
        //===================// 
	    ///////////////////////
		  
        input   logic                             clk,      // clock
        input   logic                             rstN,     // reset
        input   logic                             start,    // to start the module and initiate write in the next state
        input   logic                             eoc,      // to notify the end of communication  
		  
	    output  logic [1:0]                       doneCom,  // used to notify the top module the end of external communication
        output  logic [DATA_WIDTH-1:0]            dataOut,  // to send data to the top module to display
        output  logic                             disData,   // to notify the top module whether to display data or not 
		  
	    ///////////////////////
        //===================//
        //    with slave     //
        //===================// 
	    ///////////////////////
        input   logic                             rD,       // data in wire from the slave  
        input   logic                             ready,    // ready wire from the slave

	    output  logic                             control,  // START|SLAVE_ID|r/w 
        output  logic                             wrD,      // data out wire from master to slave
        output  logic                             valid,    // valid signal to slave during write
		  

        ///////////////////////
        //===================//
        //    with arbiter   //
        //===================// 
	    ///////////////////////
        input   logic                             arbCont,  // master to arbiter wire


        output  logic                             arbSend  // arbiter to master wire
);



localparam CONTROL_LEN = 4 + $clog2(NUM_OF_SLAVES+1);
localparam ARBITER_REQUEST_LEN = 3+$clog2(NUM_OF_SLAVES+1); // get the length of the arbiter request
localparam ACK = 4'b1100;
localparam NAK = 4'b1010;


logic                       splitOnot;
logic [1:0]                 tempHold;
logic [1:0]                 clock_counter;
logic [1:0]                 fromArbiter;
logic [CONTROL_LEN:0]       tempControl,tempControl_2;
logic [DATA_WIDTH+3:0]      tempReadWriteData = 0;
logic [3:0]                 tempDataAck;
logic [$clog2(DATA_WIDTH+4)-1:0]                  i;
logic [$clog2(CONTROL_LEN):0]                 controlCounter;
logic [$clog2(CLK_FREQ*CLOCK_DURATION)-1:0]     clock_;
logic [ARBITER_REQUEST_LEN-1:0]                 arbiterRequest, tempArbiterRequest;
logic [$clog2(ARBITER_REQUEST_LEN):0]           arbiterCounnter;

// define states for the top module
typedef enum logic [2:0]{
    configMaster,
    idle,
    write_data,
    read_data,
    displayData,
    end_com
 } start_;
start_ state;

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
	over,
    checkAck
} comStates;
comStates communicationState;



//==========================================//
//Instantiate the bram for the master module//
//==========================================//

logic communicationDone;

always_ff @( posedge clk or negedge rstN) begin : topModule
    if (~rstN) begin
        fromArbiter                       <= 0;
        i                                 <= 0;
        control                           <= 0;
        valid                             <= 0;
        doneCom                           <= 0;
        controlCounter                    <= 0;
        tempHold                          <= 0;
        clock_                            <= 0;
        clock_counter                     <= 0;
        disData                           <= 0;
        arbiterCounnter                   <= 0;
        splitOnot                         <= 0;
        state                             <= configMaster;
        communicationState                <= idleCom;
        tempReadWriteData[DATA_WIDTH-1:0] <= DATA_FROM_TOP;
        
    end
    else begin : topStates
        case (state) 
            //==========================//
            //=======Config Master======// 
            //==========================//
            configMaster:
                if (start)begin
                    state                       <= idle;
                    tempControl                 <= {3'b111, SLAVEID, 1'b1};
                    tempControl_2               <= {3'b111, SLAVEID, 1'b1};
                    arbiterRequest              <= {3'b111, SLAVEID};
                    tempArbiterRequest          <= {3'b111, SLAVEID};
                    tempReadWriteData[DATA_WIDTH-1:0] <= DATA_FROM_TOP;
                end
                else begin
                    state <= configMaster;
                end
            
            //==========================//
            //===========IDLE===========// 
            //==========================//
            idle:
                if (start && ~eoc) begin    
                    /*  set state to write data 
                        assign the control signal with signal to slave
                        assign the arbiter request
                    */
                    state                       <= displayData;
                    tempControl                 <= {3'b111, SLAVEID, 1'b1};
                    tempControl_2               <= {3'b111, SLAVEID, 1'b1};
                    arbiterRequest              <= {3'b111, SLAVEID};
                    tempArbiterRequest          <= {3'b111, SLAVEID};
                    tempReadWriteData[DATA_WIDTH-1:0] <= DATA_FROM_TOP;
                    
                end
                else if (~start && eoc) begin
                    /*
                        when it is required to stop the communication 
                        externally 
                    */
                    state <= end_com;
                end

                else if (~start && ~eoc)begin
                    /*
                        go to master default state in which it would be in continous 
                        read waiting for slave to send data to be read and displayed
                        from another board 
                    */
                    fromArbiter         <= 0;
                    i                   <= 0;
                    control             <= 0;
                    valid               <= 0;
                    doneCom             <= 0;
                    controlCounter      <= 0;
                    clock_              <= 0;
                    tempHold            <= 0;
                    clock_counter       <= 0;
                    disData             <= 0;
                    arbiterCounnter     <= 0;
                    splitOnot           <= 0;
                    state               <= read_data;
                    communicationState  <= idleCom;
                    tempControl         <= {3'b111, SLAVEID, 1'b0};
                    tempControl_2       <= {3'b111, SLAVEID, 1'b0};
                    arbiterRequest      <= {3'b111, SLAVEID};
                    tempArbiterRequest  <= {3'b111, SLAVEID};
                    tempReadWriteData[DATA_WIDTH-1:0] <= DATA_FROM_TOP;
                end

            //==========================//
            //=======Dsiplay Data======// 
            //==========================//    
            displayData:
                begin
                    if (clock_ == 0)begin
                        dataOut      <= tempReadWriteData[DATA_WIDTH*0 +:DATA_WIDTH];
                        clock_       <= clock_ + 1'b1;
                        doneCom      <= 2'b11;
                        disData      <= 1;
                        arbSend      <= 0;
                    end
                    else if (clock_ == 1) begin
                        clock_       <= clock_ + 1'b1;
                        arbSend      <= 1;
                    end
                    else if (clock_ < CLK_FREQ*CLOCK_DURATION)begin
                    // else if (clock_ < 10000*CLOCK_DURATION)begin
                        /*
                        Dispay data for n seconds defined by "CLOCK_DURARION" 
                        */
                        clock_       <= clock_ + 1'b1;
                        dataOut      <= tempReadWriteData[DATA_WIDTH-1:0];
                        disData      <= 1;
                        arbSend      <= 0;
                    end
                    else begin
                        clock_      <= 1'b0;
                        dataOut     <= tempReadWriteData[DATA_WIDTH-1:0];
                        tempReadWriteData <= tempReadWriteData +1'b1;
                        tempArbiterRequest  <= {3'b111, SLAVEID};
                        state       <= write_data;
                        disData     <= 0;
                    end
                end

            //===========================//
            //=========Write Data========// 
            //===========================//   
            write_data:
                begin
                    if (~eoc)begin
                        state               <= write_data;
                        fromArbiter[1]      <= fromArbiter[0];
                        fromArbiter[0]      <= arbCont;
                        case (communicationState) 
                            idleCom:
                                if (~arbCont) begin
                                    tempControl                 <= {3'b111, SLAVEID, 1'b1};
                                    tempControl_2               <= {3'b111, SLAVEID, 1'b1};
                                    communicationState          <= reqCom;
                                    tempHold                    <= 0;
                                    arbiterCounnter             <= 0;
                                    controlCounter              <= 0;
                                    clock_counter               <= 0;
                                    arbiterRequest              <= tempArbiterRequest;
                                end

                            reqCom:
                            /*  
                                send the request to arbiter to inform that the 
                                master requires to communicate with a slave
                            */
                                if (arbiterCounnter < ARBITER_REQUEST_LEN) begin
                                    arbSend                 <= arbiterRequest[5];
                                    arbiterRequest          <= {arbiterRequest[4:0], 1'b0};
                                    arbiterCounnter         <= arbiterCounnter + 1'b1;
                                end
                                 else if (arbiterCounnter == ARBITER_REQUEST_LEN) begin
                                    arbiterCounnter     <= arbiterCounnter+1'b1;
                                    arbSend             <= 0;
                                end

                                else if (arbiterCounnter == ARBITER_REQUEST_LEN+1) begin
                                    arbiterCounnter     <= arbiterCounnter;
                                    arbSend             <= 0;
                                    if (fromArbiter == 2'b11) begin: ClearNew
                                        arbSend             <= 1'b1;            // first ack
                                        tempControl         <= tempControl_2;
                                        controlCounter      <= 0;
                                        communicationState  <= reqAck;
                                    end
                                    else begin 
                                        communicationState  <= reqCom;
                                    end
                                end
                            
                            reqAck:
                            /* 
                                Send the ackownledgement for the clear signal for the
                                clear signal sent by the arbiter
                            */
                                if (arbiterCounnter < ARBITER_REQUEST_LEN+2) begin
                                    arbSend             <= 1'b0;        // second ack
                                    arbiterCounnter     <= arbiterCounnter + 1'b1;
                                    communicationState  <= reqAck;
                                end
                                else if (arbiterCounnter < ARBITER_REQUEST_LEN+3) begin
                                    arbSend             <= 1'b1;        // 3rd ack
                                    arbiterCounnter     <= arbiterCounnter + 1'b1;
                                    communicationState  <= reqAck;
                                end
                                else if (arbiterCounnter < ARBITER_REQUEST_LEN+7) begin
                                    arbiterCounnter     <= arbiterCounnter + 1'b1;
                                end
                                else if (arbiterCounnter == ARBITER_REQUEST_LEN+7) begin
                                    arbSend             <= 1'b1;
                                    arbiterCounnter     <= 3'd0;
                                    control             <= tempControl[6];
                                    tempControl         <= {tempControl[5:0] ,1'b0};
                                    controlCounter      <= controlCounter + 1'b1;
                                    communicationState  <= masterCom;
                                end

                            masterCom:
                            
                                if (fromArbiter == 2'b11 || fromArbiter == 2'b10) begin

                                    if (controlCounter < CONTROL_LEN) begin
                                        control             <= tempControl[CONTROL_LEN-1];
                                        tempControl         <= {tempControl[CONTROL_LEN-2:0] ,1'b0};
                                        controlCounter      <= controlCounter + 1'b1;

                                        
                                    end  
                                    else if (controlCounter == CONTROL_LEN) begin
                                        controlCounter      <= controlCounter;
                                        control             <= 0;
                                        

                                        //========================//
                                        //========= Write ========//
                                        //========================//
                                        if (i < DATA_WIDTH) begin
                                            doneCom             <= 2'b11;
                                            wrD                 <= tempReadWriteData[DATA_WIDTH-1-i];
                                            i                   <= i + 1'b1;
                                            valid               <= 1;
                                        end
                                        
                                        else begin
                                            valid               <= 0;
                                            i                   <= 0;
                                            communicationState  <= over;
                                        end  
                                    end
                                end


                                else if (fromArbiter == 2'b00)begin  
                                /*  
                                    check if arbiter sends a priority hold signal
                                */
                                    communicationState <= masterHold;
                                    arbSend <= 0;       // fisrt hold bit
                                    if (controlCounter < CONTROL_LEN) begin
                                        control             <= tempControl[CONTROL_LEN-1];
                                        tempControl         <= {tempControl[CONTROL_LEN-2:0] ,1'b0};
                                        controlCounter      <= controlCounter + 1'b1;                                    
                                    end  
                                    else if (controlCounter == CONTROL_LEN) begin
                                        controlCounter      <= controlCounter;
                                        control             <= 0;

                                        //========================//
                                        //========= Write ========//
                                        //========================//
                                        if (i < DATA_WIDTH) begin
                                            wrD                 <= tempReadWriteData[DATA_WIDTH-1-i];
                                            i                   <= i + 1'b1;
                                            valid               <= 1;
                                        end
                                        
                                        else begin
                                            valid               <= 0;
                                            i                   <= 0;
                                            communicationState  <= over;
                                    end

                                    end
                                end
                                

                            masterHold:
                                begin
                                    control <= 0;
                                    if (tempHold < 2'd1) begin
                                        tempHold <=  tempHold + 1'b1;
                                        arbSend  <= 0;
                                    end    
                                    else if (tempHold == 2'd1) begin
                                        arbSend <= 1;
                                    end 

                                    if (controlCounter < CONTROL_LEN) begin
                                        control             <= tempControl[CONTROL_LEN-1];
                                        tempControl         <= {tempControl[CONTROL_LEN-2:0] ,1'b0};
                                        controlCounter      <= controlCounter + 1'b1;                                    
                                    end  
                                    else if (controlCounter == CONTROL_LEN) begin
                                        controlCounter      <= controlCounter;
                                        control             <= 0;

                                        //========================//
                                        //========= Write ========//
                                        //========================//
                                        if (i < DATA_WIDTH) begin
                                            wrD                 <= tempReadWriteData[DATA_WIDTH-1-i];
                                            i                   <= i + 1'b1;
                                            valid               <= 1;
                                        end
                                        
                                        else begin
                                            valid               <= 0;
                                            i                   <= 0;
                                            communicationState  <= over;
                                            arbSend             <= 0;
                                        end
                                    end
                                end

                            masterDone: begin 
                                if (clock_counter < 2'd1) begin
                                    arbSend            <= 1;
                                    valid              <= 0;
                                    control            <= 0;
                                    clock_counter <= clock_counter + 1'b1;
                                end
                                else if (clock_counter < 2'd2) begin
                                    arbSend <= 0;
                                    control <= 1;
                                    clock_counter <= clock_counter + 1'b1;
                                end
                                else if (clock_counter == 2'd2) begin
                                    communicationState <= idleCom;
                                    state              <= read_data;
                                    control            <= 0;
                                end
                            end
                            

                            over:
                            /*  
                                Send the arbiter the over signal signifying the 
                                end of communication between master and slave
                            */ 
                                begin
                                    valid           <= 0;
                                    if (clock_counter < 2'd1) begin
                                        arbSend <= 0;
                                        control <= 1;
                                        clock_counter <= clock_counter + 1'b1;
                                    end
                                    else if (clock_counter < 2'd3) begin
                                        arbSend <= 1;
                                        control <= 0;
                                        clock_counter <= clock_counter + 1'b1;
                                    end
                                    else if (clock_counter == 2'd3) begin
                                        arbSend         <= 0;
                                        state           <= read_data;
                                        communicationState <= idleCom;
                                    end
                                end

                        endcase
                    end
                    else if (eoc) begin
                        /*  
                            When the top module requests to stop communication
                            state changes to end communication state
                        */
                        state               <= end_com;
                        communicationState  <= idleCom;
                    end
                end

            //=====================================//
            //==========Read Communication=========// 
            //=====================================//
            read_data:
                begin 
                    if(~start && ~eoc) begin
                        state               <= read_data;
                        fromArbiter[1]      <= fromArbiter[0];
                        fromArbiter[0]      <= arbCont;
                        case (communicationState) 
                            idleCom:
                                if (~arbCont) begin
                                    communicationState  <= reqCom;
                                    tempHold            <= 0;
                                    arbiterCounnter     <= 0;
                                    controlCounter      <= 0;
                                    clock_counter       <= 0;
                                    arbiterRequest      <= tempArbiterRequest;
                                    tempControl         <= {3'b111, SLAVEID, 1'b0};
                                    tempControl_2       <= {3'b111, SLAVEID, 1'b0};
                                end

                            reqCom:
                            /*  
                                Request the arbiter for communication
                            */
                                if (arbiterCounnter < ARBITER_REQUEST_LEN) begin
                                    arbSend                 <= arbiterRequest[5];
                                    arbiterRequest          <= {arbiterRequest[4:0], 1'b0};
                                    arbiterCounnter         <= arbiterCounnter + 1'b1;
                                end
                                else if (arbiterCounnter == ARBITER_REQUEST_LEN) begin
                                    arbiterCounnter         <= arbiterCounnter+1'b1;
                                    arbSend                 <= 0;
                                end
                                else if (arbiterCounnter == ARBITER_REQUEST_LEN+1) begin
                                    arbiterCounnter         <= arbiterCounnter;
                                    /*  
                                        Wait till arbiter sends a clear signal 
                                        to start communication
                                    */
                                    if (fromArbiter == 2'b11) begin // start communication "new"
                                        arbSend             <= 1'b1;            // first ack
                                        tempControl         <= tempControl_2;
                                        controlCounter      <= 0;
                                        communicationState  <= reqAck;
                                    end
                                    else if (fromArbiter == 2'b10) begin // start communication after Split
                                        arbSend             <= 1'b1;
                                        communicationState  <= reqAck;
                                        splitOnot           <= 1;
                                    end
                                    else begin 
                                        communicationState  <= reqCom;
                                    end
                                end
                            
                            reqAck:
                            /*  
                                Send the ackownledgement to the arbiter for 
                                the clear signal
                            */
                                if (arbiterCounnter < ARBITER_REQUEST_LEN+2) begin
                                    arbSend             <= 1'b0;        // second ack
                                    arbiterCounnter     <= arbiterCounnter + 1'b1;
                                    communicationState  <= reqAck;
                                end
                                else if (arbiterCounnter < ARBITER_REQUEST_LEN+3) begin
                                    arbSend             <= 1'b1;        // 3rd ack
                                    arbiterCounnter     <= arbiterCounnter + 1'b1;
                                    communicationState  <= reqAck;
                                end
                                else if (arbiterCounnter < ARBITER_REQUEST_LEN+7) begin
                                    arbiterCounnter     <= arbiterCounnter + 1'b1;
                                end
                                else if (arbiterCounnter == ARBITER_REQUEST_LEN+7) begin
                                    arbSend             <= 1'b1;
                                    arbiterCounnter     <= 3'd0;
                                    control             <= tempControl[CONTROL_LEN-1];
                                    tempControl         <= {tempControl[CONTROL_LEN-2:0] ,1'b0};
                                    controlCounter      <= controlCounter + 1'b1;
                                    if (splitOnot == 1)begin
                                        communicationState <= splitComContinue;
                                        clock_counter      <= 0;
                                    end
                                    else begin
                                    communicationState  <= masterCom;
                                    end
                                end

                            masterCom:
                            /*  
                                Start communication with the slave
                            */
                                if (fromArbiter == 2'b11 || fromArbiter == 2'b10) begin

                                    if (controlCounter < CONTROL_LEN+1) begin
                                        control             <= tempControl[CONTROL_LEN-1];
                                        tempControl         <= {tempControl[CONTROL_LEN-2:0] ,1'b0};
                                        controlCounter      <= controlCounter + 1'b1;

                                    end  
                                    else if (controlCounter == CONTROL_LEN+1) begin
                                        controlCounter      <= controlCounter;
                                        control             <= 0;
                                        

                                        //========================//
                                        //========= Read =========//
                                        //========================//
                                        if ((i < DATA_WIDTH+4) && ready) begin
                                            doneCom                   <= 2'b11;
                                            tempReadWriteData[DATA_WIDTH+3-i] <= rD;
                                            i                            <= i + 1'b1;
                                        end
                                        else if (i == DATA_WIDTH+4) begin
                                            i <= 0;
                                            communicationState  <= over;
                                        end
                                    end
                                end


                                else if (fromArbiter == 2'b00)begin: priorityStop
                                /*  
                                    Check for a priority stop from the arbiter and
                                    if receive follow the following steps
                                */
                                    communicationState <= masterHold;
                                    arbSend <= 0;       // fisrt hold bit
                                    if (controlCounter < CONTROL_LEN) begin
                                        control             <= tempControl[CONTROL_LEN-1];
                                        tempControl         <= {tempControl[CONTROL_LEN-2:0] ,1'b0};
                                        controlCounter      <= controlCounter + 1'b1;                                    
                                    end  
                                    else if (controlCounter == CONTROL_LEN) begin
                                        controlCounter      <= controlCounter;
                                        control             <= 0;

                                        if ((i < DATA_WIDTH+4) && ready) begin
                                            tempReadWriteData[DATA_WIDTH+3-i] <= rD;
                                            i                            <= i + 1'b1;
                                        end
                                        else if (i == DATA_WIDTH+4) begin
                                            i <= 0;
                                            communicationState  <= over;
                                        end
                                    end

                                end

                                else if (fromArbiter == 2'b01)begin: splitStop
                                    communicationState <= masterSplit; 
                                    splitOnot          <= 1;                               
                                end
                                

                            masterHold:
                            /*  
                                inform the arbiter hold till the current byte of 
                                data is communicated
                            */
                                begin
                                    control <= 0;
                                    if (tempHold < 2'd1) begin
                                        tempHold <=  tempHold + 1'b1;
                                        arbSend  <= 0;
                                    end    
                                    else if (tempHold == 2'd1) begin
                                        arbSend <= 1;
                                    end 

                                    if (controlCounter < CONTROL_LEN) begin
                                        control             <= tempControl[CONTROL_LEN-1];
                                        tempControl         <= {tempControl[CONTROL_LEN-2:0] ,1'b0};
                                        controlCounter      <= controlCounter + 1'b1;                                    
                                    end  
                                    else if (controlCounter == CONTROL_LEN) begin
                                        controlCounter      <= controlCounter;
                                        control             <= 0;
                                        if (!arbCont) begin
                                            if ((i < DATA_WIDTH+4) && ready) begin
                                                tempReadWriteData[DATA_WIDTH+3-i] <= rD;
                                                i                            <= i + 1'b1;
                                            end
                                            else if (i == DATA_WIDTH+4) begin
                                                i <= 0;
                                                communicationState <= masterDone;
                                            end
                                            else if (~ready) begin
                                                communicationState <= masterDone;
                                                i <= 0;
                                            end
                                        end
                                    end
                                end

                            masterDone: begin
                                /*  
                                    inform the arbiter its clear to allocate the bus
                                    to the high priority master
                                */
                                if (clock_counter < 2'd1 && splitOnot == 0) begin
                                    arbSend            <= 0;
                                    valid              <= 0;
                                    control            <= 0;
                                    clock_counter <= clock_counter + 1'b1;
                                end
                                else if (clock_counter < 2'd2 && splitOnot == 0 ) begin
                                    arbSend <= 1;
                                    control <= 1;
                                    clock_counter <= clock_counter + 1'b1;
                                end
                                else if (clock_counter == 2'd2 && splitOnot == 0 ) begin
                                    communicationState <= idleCom;
                                    control            <= 0;
                                    arbSend            <= 0;
                                end
                                
                                else if (clock_counter < 2'd1 && splitOnot == 1) begin
                                    arbSend            <= 0;
                                    valid              <= 0;
                                    control            <= 1;
                                    clock_counter <= clock_counter + 1'b1;
                                end
                                else if (clock_counter < 2'd2 && splitOnot == 1 ) begin
                                    arbSend <= 1;
                                    control <= 1;
                                    clock_counter <= clock_counter + 1'b1;
                                end
                                else if (clock_counter == 2'd2 && splitOnot == 1 ) begin
                                    communicationState <= idleCom;
                                    control            <= 0;
                                    arbSend            <= 0;
                                end
                            end
                            
                            masterSplit:
                            begin
                                communicationState <= masterDone; 
                                arbSend            <= 0;
                            end 
                            
                            //=======================================//
                            //   Split Communication continue state  //
                            //=======================================//
                            splitComContinue: 
                                if (fromArbiter == 2'b11 || fromArbiter == 2'b10) begin
                                    fromArbiter[1]      <= fromArbiter[0];
                                    fromArbiter[0]      <= arbCont;
                                    if (clock_counter < 2'd1) begin
                                        control         <= 1;
                                        clock_counter   <= clock_counter + 1'b1;
                                    end
                                    else if (clock_counter < 2'd2) begin
                                        control         <= 0;
                                        clock_counter   <= clock_counter + 1'b1;
                                    end
                                    else if (clock_counter < 2'd3) begin
                                        control         <= 1;
                                        clock_counter   <= clock_counter + 1'b1;
                                    end
                                    else if (clock_counter == 2'd3) begin
                                        control         <= 0;
                                        clock_counter   <= clock_counter;

                                        //========================//
                                        //========= Read =========//
                                        //========================//
                                        if ((i < DATA_WIDTH+4) && ready) begin
                                            tempReadWriteData[DATA_WIDTH+3-i] <= rD;
                                            i                            <= i + 1'b1;
                                        end
                                        else if (i == DATA_WIDTH+4) begin
                                            i <= 0;
                                            communicationState  <= over;
                                        end       
                                    end
                                end
                            
                                else if (fromArbiter == 2'b00)begin 
                                    communicationState <= masterHold;
                                    splitOnot          <= 0;
                                    arbSend <= 0;       // fisrt hold bit
                                    if (controlCounter < CONTROL_LEN) begin
                                        control             <= tempControl[CONTROL_LEN-1];
                                        tempControl         <= {tempControl[CONTROL_LEN-2:0] ,1'b0};
                                        controlCounter      <= controlCounter + 1'b1;                                    
                                    end  
                                    else if (controlCounter == CONTROL_LEN) begin
                                        controlCounter      <= controlCounter;
                                        control             <= 0;

                                        if ((i < DATA_WIDTH+4) && ready) begin
                                            tempReadWriteData[DATA_WIDTH+3-i] <= rD;
                                            i                            <= i + 1'b1;
                                        end
                                        else if (i == DATA_WIDTH+4) begin
                                            i <= 0;
                                            communicationState  <= over;
                                        end
                                    end
                                end
                            
                            

                            over:
                            /*  
                                Inform the arbiter the end of the current communication
                            */ 
                                begin
                                    valid           <= 0;
                                    if (clock_counter < 2'd1) begin
                                        arbSend <= 0;
                                        control <= 1;
                                        clock_counter <= clock_counter + 1'b1;
                                    end
                                    else if (clock_counter < 2'd3) begin
                                        arbSend <= 1;
                                        control <= 0;
                                        clock_counter <= clock_counter + 1'b1;
                                    end
                                    else if (clock_counter == 2'd3) begin
                                        arbSend         <= 0;
                                        communicationState <= checkAck;
                                    end
                                end
                            
                            checkAck:
                            /*  
                                check whether the master received the acknowledgement 
                                for the external communication between the two boards
                            */
                                begin
                                    arbSend <= 0;
                                    if (tempReadWriteData[(DATA_WIDTH+3) -: 4] == NAK) begin
                                        /* 
                                        acknowledgement received correctly
                                        */
                                        state              <= end_com;
                                        communicationState <= idleCom;
                                        doneCom            <= 2'b01;
                                    end
                                    else begin
                                        state              <= displayData;
                                        communicationState <= idleCom;
                                        doneCom            <= 2'b11;
                                        end
                                end

                        endcase
                    end
                    else if (start && ~eoc)begin
                        /*  
                            if the top module wants to initiate the communication 
                            from the current board go to display data state and display
                            the data before sending it to the next master
                        */
                        state              <= displayData;
                        communicationState <= idleCom;
                        tempReadWriteData[DATA_WIDTH-1 :0]  <= DATA_FROM_TOP;
                    end
                    else if (~start && eoc) begin
                        /*  
                            end external communication in the case where the top
                            module requests for the end of communication
                        */
                        state              <= end_com;
                        communicationState <= idleCom;
                        doneCom            <= 2'b01;
                    end
                end
                
            //==========================//
            //========End Com===========// 
            //==========================//
            end_com: 
                begin
                    doneCom         <= 1;
                    dataOut         <= tempReadWriteData[DATA_WIDTH-1:0];    
                end   
        endcase
    end
    
end

endmodule: masterExternal 