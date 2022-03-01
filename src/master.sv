module master #(
    parameter MEMORY_DEPTH  = 4096,
    parameter DATA_WIDTH    = 8,
    parameter NO_SLAVES     = 4
)( 

	    ///////////////////////
        //===================//
        //  with topModule   //
        //===================// 
	    ///////////////////////
		  
        input   logic                             clk,      // clock
        input   logic                             rstN,     // reset
        input   logic                             burst,                          
        input   logic                             rdWr,     // read or write for internal communication
        input   logic                             inEx,     // internal or external
        input   logic [DATA_WIDTH-1:0]            data,     // data wire used to write data from top to master externally
        input   logic [$clog2(MEMORY_DEPTH)-1:0]  address,  // used to give the start and end address for internal communication (single/burst)
        input   logic [$clog2(NO_SLAVES+1)-1:0]   slaveId,  // to give the information about which slave to communicate with 
        input   logic                             start,    // used start configuration and communication of the master module
        input   logic                             eoc,      // used to end the communication of the master module
		  
	    output  logic                             doneCom,  // used to tell the top module the end of communication
        output  logic [DATA_WIDTH-1:0]            dataOut,  // used to send data from the master to top module to display data

		  
	    ///////////////////////
        //===================//
        //    with slave     //
        //===================// 
	    ///////////////////////
        input   logic                             rD,       // 1-bit data wire in which the slave sends data to the master     
        input   logic                             ready,    // control signal used by the slave to inform when the data is ready to be read

	    output  logic                             control,  // START|SLAVE_ID|r/w|B|address| 
        output  logic                             wrD,      // 1-bit data wire in which the master sends data to the slave 
        output  logic                             valid,    // control signal used by the master to inform when the data is ready to be written
        output  logic                             last,     // used by the master to inform the slave of the last byte of a burst communication
		  

        ///////////////////////
        //===================//
        //    with arbiter   //
        //===================// 
	    ///////////////////////
        input   logic                             arbCont,  // the control signal sent by the arbiter to master


        output  logic                             arbSend   // wire used by master to communicate woith the arbiter
);




localparam ADDRESS_WIDTH = $clog2(MEMORY_DEPTH);  // get the address width given the memory depth
localparam CONTROL_LEN = 5 + ADDRESS_WIDTH + $clog2(NO_SLAVES+1); // get the length of the control signal
localparam ARBITER_REQUEST_LEN = 3+$clog2(NO_SLAVES+1); // get the length of the arbiter request


logic                       wr;             // read/write enable signal for internal Bram
logic                       tempRdWr;       // read/write indication buffer
logic                       tempBurst;      // burst indication buffer for master and top module
logic [1:0]                 tempHold;       // buffer to check the hold state
logic                       splitOnot;      // buffer to check whether a split happend or not
logic [1:0]                 clock_counter;  // counter
logic [1:0]                 fromArbiter;    // buffer to check arbiter control signals during communication
logic [2:0]                 arbGrant;       // buffer to check whether the arbiter granted the bus

logic [$clog2(CONTROL_LEN)-1:0]         controlCounter; // counter for control signal
logic [CONTROL_LEN-1:0]                 tempControl,tempControl_2; // buffers to store the control signal
logic [ARBITER_REQUEST_LEN-1:0]         arbiterRequest, tempArbiterRequest; // buffers to store the arbiter request
logic [ADDRESS_WIDTH-1:0]               addressInternal, addresstemp;    // bufers for internal bram address
logic [ADDRESS_WIDTH-1:0]               addressInternalBurtstBegin, addressInternalBurtstEnd; // buffers to get the start and end address of the slave communication
logic [$clog2(ARBITER_REQUEST_LEN):0]   arbiterCounnter;  // counter for arbiter request
logic [ADDRESS_WIDTH:0]                 burstLen;   // burst length for burst communication
logic [DATA_WIDTH-1:0]                  dataInternal, internalDataOut, tempReadWriteData; /// bufers for internal bram adta


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

// define states for the communication process types
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
    .DATA_WIDTH                 ( DATA_WIDTH    )
//    .MEM_INIT_FILE              ("mem.txt"      )
    ) bram(
        .clk            (clk                ),
        .wr             (wr                 ),
        .address        (addressInternal    ),
        .data           (dataInternal       ),
        .q              (internalDataOut    )
);

logic communicationDone;

//====================================================//
//Start to the configuration and communication process//
//====================================================//
always_ff @( posedge clk or negedge rstN) begin : topModule
    if (~rstN) begin
        addresstemp         <= 0;
        fromArbiter         <= 0;
        tempReadWriteData   <= 0;
        i                   <= 0;
        control             <= 0;
        wrD                 <= 0;
        wr                  <= 0;
        valid               <= 0;
        last                <= 0;
        doneCom             <= 0;
        controlCounter      <= 0;
        tempHold            <= 0;
        clock_counter       <= 0;
        arbiterCounnter     <= 0;
        splitOnot           <= 0;
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
                    /*  
                        assign the control signal with signal to slave
                        assign the arbiter request
                    */ 
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
                    if (inEx) begin 
                    /*  
                        Top module write data into the master from external
                        inputs
                    */
                        if (tempBurst == 1) begin
                            /*  
                                Top module writes multiple data into master
                            */
                            if (clock_counter < 2'd1) begin
                                dataInternal                <= data;
                                addressInternal             <= addresstemp;
                                wr                          <= 1;
                                clock_counter               <= clock_counter + 2'd1;
                            end

                            else begin
                                addresstemp                 <= addresstemp + 1'b1;
                                wr                          <= 0;
                                clock_counter               <= 2'd0;
                            end
                        end
                        else begin
                            /*   
                                Top module writes only a signle data to master
                            */
                            if (clock_counter < 2'd1) begin
                                addressInternal             <= addresstemp;
                                dataInternal                <= data;
                                clock_counter               <= clock_counter + 1'b1;
                                // wr                          <= 1;
                                wr                          <= 1;
                                clock_counter               <= clock_counter + 2'd1;
                            end
                            else begin
                                wr                          <= 0;
                                clock_counter               <= '0;
                            end
                        end
                    
                    end
                end
                else if (~start && eoc ) begin
                    state <= done;
                end
                else if (~start && ~eoc)begin
                    addresstemp         <= 0;
                    fromArbiter         <= 0;
                    tempReadWriteData   <= 0;
                    i                   <= 0;
                    control             <= 0;
                    wrD                 <= 0;
                    wr                  <= 0;
                    valid               <= 0;
                    last                <= 0;
                    doneCom             <= 0;
                    tempHold            <= 0;
                    controlCounter      <= 0;
                    clock_counter       <= 0;
                    arbiterCounnter     <= 0;
                    splitOnot           <= 0;
                    state               <= idle;
                    communicationState  <= idleCom;
                    internalComState    <= checkState;
                end

            //==========================//
            //=======startConfig========// 
            //==========================//
            startConfig:
                if (start) begin
                    state                       <= startEndConfig;

                    if (inEx) begin
                        if (tempBurst == 1) begin
                            state                       <= startEndConfig;
                            addressInternalBurtstEnd    <= address;
                            wr                          <= 1;
                            dataInternal                <= data;
                            addressInternal             <= addresstemp;
                            addresstemp                 <= addresstemp + 1'b1; //check /////////////////
                        end
                        else begin
                            state                       <= startEndConfig;
                            addressInternalBurtstEnd    <= address;
                            wr                          <= 0;
                        end
                    end
                    else begin
                        addressInternalBurtstEnd    <= address;
                        state                       <= startEndConfig;
                        wr                          <= 0;
                    end
                end
                else begin                   
                    
                    if (inEx) begin : internalExternalWrite
                    /*  
                        Top module write data into the master from external
                        inputs
                    */
                        if (tempBurst == 1) begin
                            /*  
                                Top module writes multiple data into master
                            */
                                dataInternal                <= data;
                                addressInternal             <= addresstemp;
                            if (clock_counter < 2'd1) begin
                                wr                          <= 1;
                                clock_counter               <= clock_counter + 2'd1;
                            end

                            else begin
                                addresstemp                 <= addresstemp + 1'b1;
                                wr                          <= 0;
                                clock_counter               <= '0;
                            end
                        end
                        else begin
                            /*   
                                Top module writes only a signle data to master
                            */
                            if (clock_counter < 2'd1) begin
                                addressInternal             <= addresstemp;
                                dataInternal                <= data;
                                // clock_counter               <= clock_counter + 2'd1;
                                // wr                          <= 1;/
                                wr                          <= 1;
                                clock_counter               <= clock_counter + 1'b1;
                            end
                            else begin
                                wr                          <= 0;
                                clock_counter               <= '0;
                            end
                        end
                            
                    end
                end
            

            //==========================//
            //======startEndConfig======// 
            //==========================//
            startEndConfig:
                if (start) begin
                    /* IF start; start communication */
                    state                              <= startCom;
                    wr                                 <= 0;
                    if(burstLen == 0)begin  // check whether internal communication has a burst or not
                        tempControl[ADDRESS_WIDTH]     <= 0;                   
                        tempControl_2[ADDRESS_WIDTH]   <= 0;
                    end
                    else begin
                        tempControl[ADDRESS_WIDTH]     <= 1;
                        tempControl_2[ADDRESS_WIDTH]   <= 1;
                    end
                end
                else begin
                    state                       <= startEndConfig;
                    // wr                          <= 1;
                    if (addressInternalBurtstEnd == addressInternalBurtstBegin) begin
                        burstLen         <= 0;
                    end
                    else begin
                        burstLen         <= addressInternalBurtstEnd - addressInternalBurtstBegin + 1'b1;
                    end
                    if (inEx) begin
                        if (tempBurst == 1) begin
                            if (clock_counter < 2'd1) begin
                                addressInternal             <= addresstemp;
                                dataInternal                <= data;
                                // clock_counter               <= clock_counter + 2'd1;
                                // wr                          <= 1;/
                                wr                          <= 1;
                                clock_counter               <= clock_counter + 1'b1;
                            end
                            else begin
                                wr                          <= 0;
                                clock_counter               <= '0;
                            end
                        end
                    end
                end

            //==========================//
            //=========startCom=========// 
            //==========================//
            startCom:
                if(doneCom == 1'b0 && slaveId != 0) begin : start_internal_communication
                    state               <= startCom;
                    fromArbiter[1]      <= fromArbiter[0];
                    fromArbiter[0]      <= arbCont;
                    case (communicationState) 
                        idleCom:
                        /*  
                            Default master state
                        */
                            if (~arbCont) begin
                                communicationState  <= reqCom;
                                tempHold            <= 0;
                                arbiterCounnter     <= 0;
                                controlCounter      <= 0;
                                clock_counter       <= 0;
                                arbiterRequest      <= tempArbiterRequest;
                            end

                        reqCom:
                        /*  
                            send the request to arbiter to inform that the 
                            master requires to communicate with a slave
                        */

                            if (arbiterCounnter < ARBITER_REQUEST_LEN) begin
                                arbSend                 <= arbiterRequest[ARBITER_REQUEST_LEN-1];
                                arbiterRequest          <= {arbiterRequest[ARBITER_REQUEST_LEN-2:0], 1'b0};
                                arbiterCounnter         <= arbiterCounnter + 1'b1;
                            end
                            else if (arbiterCounnter == ARBITER_REQUEST_LEN) begin
                                arbiterCounnter     <= arbiterCounnter+1'b1;
                                arbSend             <= 0;
                            end
                            else if (arbiterCounnter == ARBITER_REQUEST_LEN+1) begin
                                arbiterCounnter     <= arbiterCounnter;
                                if (fromArbiter == 2'b11) begin: ClearNew
                                    arbSend             <= 1'b1;            // first ack
                                    tempControl         <= tempControl_2;
                                    controlCounter      <= 0;
                                    communicationState  <= reqAck;
                                end
                                else if (fromArbiter == 2'b10) begin: ClearSplit
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
                            Send the ackownledgement for the clear signal for the
                            clear signal sent by the arbiter
                        */
                            if (arbiterCounnter < ARBITER_REQUEST_LEN+2) begin
                                arbSend             <= 1'b0;        // second ack
                                arbiterCounnter     <= arbiterCounnter + 1'b1;
                                communicationState  <= reqAck;
                            end
                            else if (arbiterCounnter <ARBITER_REQUEST_LEN+3) begin
                                arbSend             <= 1'b1;        // 3rd ack
                                arbiterCounnter     <= arbiterCounnter + 1'b1;
                                communicationState  <= reqAck;
                            end
                            else if (arbiterCounnter < ARBITER_REQUEST_LEN+7) begin
                                arbiterCounnter     <= arbiterCounnter + 1'b1;
                            end
                            else if (arbiterCounnter == ARBITER_REQUEST_LEN+7) begin
                                arbSend             <= 1'b1;
                                arbiterCounnter     <= 0;
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
                           
                            if (fromArbiter == 2'b11 || fromArbiter == 2'b10) begin

                                if (controlCounter < CONTROL_LEN) begin
                                    control             <= tempControl[CONTROL_LEN-1]; 
                                    tempControl         <= {tempControl[CONTROL_LEN-2:0] ,1'b0};
                                    controlCounter      <= controlCounter + 1'b1;
                                end  
                                else if (controlCounter == CONTROL_LEN) begin
                                    controlCounter      <= controlCounter;
                                    control             <= 0;
                                    

                                    //=======================//
                                    //=====Read or Write=====//
                                    //=======================//
                                    case(internalComState)

                                    checkState:
                                    /*  
                                        Check the mode of process 
                                        Read or write
                                        single or busrt
                                    */
                                        if (tempRdWr == 1) begin
                                            if (burstLen == 0) begin
                                                /*  
                                                    Single Write Mode
                                                */
                                                wr = 0;
                                                addressInternal  <= addressInternalBurtstBegin;
                                                if (~valid)begin
                                                    if (i < 2)begin
                                                        i = i + 1'b1;
                                                    end
                                                    else begin
                                                        tempReadWriteData           <= internalDataOut;
                                                        i                           <= 0; 
                                                        internalComState            <= singleWrite;
                                                    end
                                                end
                                            end
                                            else begin
                                                /*  
                                                    Burst write mode
                                                */
                                                addressInternal  <= addressInternalBurtstBegin;
                                                wr               <= 0;
                                                if (~valid)begin
                                                    if (i < 2)begin
                                                        i = i + 1'b1;
                                                    end
                                                    else begin
                                                        tempReadWriteData           <= internalDataOut;
                                                        addressInternalBurtstBegin  <= addressInternalBurtstBegin + 1'b1;
                                                        i                           <= 0; 
                                                        internalComState            <= burstWrite;
                                                    end
                                                end
                                            end
                                        end
                                        else if (tempRdWr == 0) begin
                                            if (burstLen == 0) begin
                                                /*  
                                                    Single read mode
                                                */
                                                internalComState <= singleRead;
                                                valid            <= 1;
                                            end
                                            else begin
                                                /*  
                                                    Burst read mode
                                                */
                                                internalComState <= burstRead;
                                                valid            <= 1;
                                            end
                                        end

                                    singleRead:
                                    /*  
                                        Procedure for single read                                    
                                    */
                                            if (i < DATA_WIDTH && ready) begin
                                                tempReadWriteData[DATA_WIDTH-1-i] <= rD;
                                                i                            <= i + 1'b1;
                                            end
                                            else if (i == DATA_WIDTH) begin
                                                dataInternal        <= tempReadWriteData;
                                                addressInternal     <= addressInternalBurtstBegin;
                                                wr                  <= 1;
                                                i                   <= i + 1'b1;    
                                            end
                                            else if (~ready && i <= DATA_WIDTH) begin
                                                wr                  <= 0;
                                            end
                                            else if (i > DATA_WIDTH) begin
                                                i                   <= 0;
                                                wr                  <=0;
                                                communicationState  <= over;
                                                clock_counter       <= 1'b0;
                                            end


                                    burstRead:
                                    /*  
                                        Procedure for burst read
                                    */
                                            if(burstLen > 1 ) begin
                                                if (i < DATA_WIDTH && ready) begin
                                                    tempReadWriteData[DATA_WIDTH-1-i] <= rD;
                                                    i               <= i + 1'b1;
                                                    wr              <= 0;
                                                    valid           <= 1; //set valid high
                                                end
                                                else if (i == DATA_WIDTH || ready) begin
                                                    tempReadWriteData[i]        <= rD;
                                                    dataInternal                <= tempReadWriteData;
                                                    addressInternal             <= addressInternalBurtstBegin;
                                                    addressInternalBurtstBegin  <= addressInternalBurtstBegin + 1'b1;
                                                    wr                          <= 1;
                                                    i                           <= 0; 
                                                    valid                       <= 0;
                                                    burstLen                    <= burstLen - 1'b1; // reduce the burst length  
                                                end
                                                else if (~ready) begin
                                                    wr                          <= 0;
                                                end
                                            end
                                            else if( burstLen == 1 ) begin
                                                if (i < DATA_WIDTH && ready) begin
                                                    tempReadWriteData[DATA_WIDTH-1-i] <= rD;
                                                    i               <= i + 1'b1;
                                                    wr              <= 0;
                                                    valid           <= 1;
                                                    last            <= 1;
                                                end
                                                else if (i == DATA_WIDTH || ready ) begin
                                                    tempReadWriteData[i]        <= rD;
                                                    dataInternal                <= tempReadWriteData;
                                                    addressInternal             <= addressInternalBurtstBegin;
                                                    addressInternalBurtstBegin  <= addressInternalBurtstBegin + 1'b1;
                                                    wr                  <= 1;
                                                    i                   <= 0; 
                                                    last                <= 1;
                                                    valid               <= 0;
                                                    burstLen            <= burstLen - 1'b1;   
                                                end
                                                else if (~ready) begin
                                                    wr              <= 0;
                                                end
                                            end
                                            else begin
                                                last                <= 0;
                                                wr                  <= 0;
                                                communicationState  <= over;
                                                clock_counter       <= 1'b0;
                                            end
                                    
                                    singleWrite:
                                    /*  
                                        Procedure for single write
                                    */
                                            if (i < DATA_WIDTH) begin
                                                wrD                 <= tempReadWriteData[DATA_WIDTH-1-i];
                                                addressInternal     <= addressInternalBurtstBegin;
                                                i                   <= i + 1'b1;
                                                valid               <= 1;
                                            end
                                            
                                            else begin
                                                valid               <= 0;
                                                i                   <= 0;
                                                communicationState  <= over;
                                                last                <= 0;
                                                clock_counter       <= 1'b0;
                                            end

                                    
                                    burstWrite:
                                    /*  
                                        Procedure for burst Write
                                    */
                                        if(burstLen > 1) begin
                                            if (i < DATA_WIDTH) begin
                                                wrD                 <= tempReadWriteData[DATA_WIDTH-1-i];
                                                addressInternal     <= addressInternalBurtstBegin;
                                                i                   <= i + 1'b1;
                                                valid               <= 1;
                                            end
                                            else if (i == DATA_WIDTH) begin
                                                i                           <= 0;
                                                burstLen                    <= burstLen - 1'b1;
                                                addressInternalBurtstBegin  <= addressInternalBurtstBegin + 1'b1;
                                                tempReadWriteData                <= internalDataOut;
                                                valid                       <= 0;
                                            end
                                        end
                                        else if (burstLen == 1) begin
                                            if (i < DATA_WIDTH-1) begin
                                                wrD                 <= tempReadWriteData[DATA_WIDTH-1-i];
                                                addressInternal     <= addressInternalBurtstBegin;
                                                i                   <= i + 1'b1;
                                                valid               <= 1;
                                                last                <= 1;
                                            end
                                            else if (i == DATA_WIDTH-1) begin
                                                i                           <= 0;
                                                wrD                         <= tempReadWriteData[DATA_WIDTH-1-i];
                                                burstLen                    <= burstLen - 1'b1 ;
                                                addressInternalBurtstBegin  <= addressInternalBurtstBegin + 1'b1;
                                                tempReadWriteData                <= internalDataOut;
                                                valid                       <= 1;
                                                last                        <= 1;
                                            end
                                        end
                                        else begin
                                            valid               <= 0;
                                            communicationState  <= over;
                                            clock_counter       <= 1'b0;
                                            last                <= 0;
                                        end
                                    endcase 
                                end
                            end


                            else if (fromArbiter == 2'b00)begin: priorityStop
                            /*  
                                When the arbiter sends priority stop signal
                                master will check whether it is possible to 
                                stop the current communnication or not.
                            */
                                communicationState <= masterHold;
                                arbSend <= 0;       // fisrt hold bit
                                if (controlCounter < CONTROL_LEN) begin
                                    control             <= tempControl[18];
                                    tempControl         <= {tempControl[17:0] ,1'b0};
                                    controlCounter      <= controlCounter + 5'd1;

                                    
                                end  
                                else if (controlCounter == CONTROL_LEN) begin
                                    controlCounter      <= controlCounter;
                                    control             <= 0;

                                
                                    if (burstLen == 0) begin    // single
                                        if (tempRdWr == 0) begin   // read single 
                                            if (ready) begin
                                                if (i < DATA_WIDTH) begin
                                                    tempReadWriteData[DATA_WIDTH-1-i] <= rD;
                                                    i                            <= i + 1'b1;
                                                end
                                                else if (i == DATA_WIDTH) begin
                                                dataInternal        <= tempReadWriteData;
                                                addressInternal     <= addressInternalBurtstBegin;
                                                wr                  <= 1;
                                                i                   <= i + 1'b1;     
                                                end
                                                else if (~ready && i <= DATA_WIDTH) begin
                                                    wr <= 0;
                                                end
                                                else if (i > DATA_WIDTH) begin
                                                    i <= 0;
                                                    wr <=0;
                                                    communicationState <= over;
                                                    clock_counter       <= 1'b0;
                                                end
                                            end
                                        end
                                        else begin  // single write 
                                            if (i < DATA_WIDTH) begin
                                                wrD                 <= tempReadWriteData[DATA_WIDTH-1-i];
                                                addressInternal     <= addressInternalBurtstBegin;
                                                i                   <= i + 1'b1;
                                                valid               <= 1;
                                            end
                                            
                                            else begin
                                                valid               <= 0;
                                                i                   <= 0;
                                                communicationState  <= over;
                                                last                <= 0;
                                                clock_counter       <= 1'b0;
                                            end
                                        end
                                    end
                                    else begin // burst
                                        if (tempRdWr == 0) begin  // burst read   
                                            if(burstLen > 1 ) begin
                                                if (i < DATA_WIDTH && ready) begin
                                                    tempReadWriteData[DATA_WIDTH-1-i] <= rD;
                                                    i               <= i + 1'b1;
                                                    wr              <= 0;
                                                    valid           <= 1;
                                                end
                                                else if (i == DATA_WIDTH || ready) begin
                                                    tempReadWriteData[i]             <= rD;
                                                    dataInternal                <= tempReadWriteData;
                                                    addressInternal             <= addressInternalBurtstBegin;
                                                    addressInternalBurtstBegin  <= addressInternalBurtstBegin + 1'b1;
                                                    wr                  <= 1;
                                                    i                   <= 0; 
                                                    valid               <= 0;
                                                    burstLen            <= burstLen - 1'b1;   
                                                    communicationState  <= masterDone;   
                                                end
                                                else if (~ready) begin
                                                    wr <= 0;
                                                end
                                            end
                                            else if( burstLen == 1 ) begin
                                                if (i < DATA_WIDTH && ready) begin
                                                    tempReadWriteData[DATA_WIDTH-1-i] <= rD;
                                                    i               <= i + 1'b1;
                                                    wr              <= 0;
                                                    valid           <= 1;
                                                    last            <= 1;
                                                end
                                                else if (i == DATA_WIDTH || ready ) begin
                                                    tempReadWriteData[i]             <= rD;
                                                    dataInternal                <= tempReadWriteData;
                                                    addressInternal             <= addressInternalBurtstBegin;
                                                    addressInternalBurtstBegin  <= addressInternalBurtstBegin + 1'b1;
                                                    wr                  <= 1;
                                                    i                   <= 0; 
                                                    last                <= 1;
                                                    valid               <= 0;
                                                    burstLen            <= burstLen - 1'b1;  
                                                    communicationState  <= over; 
                                                    clock_counter       <= 1'b0;
                                                end
                                                else if (~ready) begin
                                                    wr <= 0;
                                                end
                                            end
                                        end

                                        else begin: burstWriteMode
                                            if(burstLen > 1) begin
                                                if (i < DATA_WIDTH) begin
                                                    wrD                 <= tempReadWriteData[DATA_WIDTH-1-i];
                                                    addressInternal     <= addressInternalBurtstBegin;
                                                    i                   <= i + 1'b1;
                                                    valid               <= 1;
                                                end
                                                else if (i == DATA_WIDTH) begin
                                                    i                           <= 0;
                                                    burstLen                    <= burstLen - 1'b1;
                                                    addressInternalBurtstBegin  <= addressInternalBurtstBegin + 1'b1;
                                                    tempReadWriteData                <= internalDataOut;
                                                    valid                       <= 0;
                                                    communicationState          <= masterDone;
                                                end
                                            end
                                            else if (burstLen == 1) begin
                                                if (i < DATA_WIDTH-1) begin
                                                    wrD                 <= tempReadWriteData[DATA_WIDTH-1-i];
                                                    addressInternal     <= addressInternalBurtstBegin;
                                                    i                   <= i + 1'b1;
                                                    valid               <= 1;
                                                    last                <= 1;
                                                end
                                                else if (i == DATA_WIDTH-1) begin
                                                    i                           <= 0;
                                                    wrD                         <= tempReadWriteData[DATA_WIDTH-1-i];
                                                    burstLen                    <= burstLen - 1'b1;
                                                    addressInternalBurtstBegin  <= addressInternalBurtstBegin + 1'b1;
                                                    tempReadWriteData                <= internalDataOut;
                                                    valid                       <= 1;
                                                    last                        <= 1;
                                                    communicationState          <= over;
                                                    clock_counter       <= 1'b0;
                                                end
                                            end
                                        end: burstWriteMode
                                    end
                                end

                            end

                            else if (fromArbiter == 2'b01)begin: splitStop
                                /*  
                                    When the arbiter send the split stop signal
                                */
                                communicationState <= masterSplit; 
                                splitOnot          <= 1;                               
                            end
                            
                        //========================//
                        //=======Master Hold======//
                        //========================//
                        masterHold:
                            /*  
                                When the arbiter sends a priority stop signal
                                the master will follow the following depending on the postion
                                in which it was in communication with the slave
                            */
                            begin
                            control <= 0;
                            if (tempHold < 2'd1) begin
                                tempHold <=  tempHold + 1'b1;
                                arbSend  <= 0;
                            end    
                            else if (tempHold == 2'd1) begin
                                arbSend <= 1;
                                tempHold <=  tempHold + 1'b1;
                            end 

                            if (controlCounter < CONTROL_LEN) begin
                                control             <= tempControl[18];
                                tempControl         <= {tempControl[17:0] ,1'b0};
                                controlCounter      <= controlCounter + 1'b1;     
                            end 

                            else if (controlCounter == CONTROL_LEN) begin
                                controlCounter      <= controlCounter;
                                control             <= 0;

                                if (burstLen == 0) begin: singleMode
                                    if (tempRdWr == 0) begin    // single read
                                        if (i < DATA_WIDTH && ready) begin
                                            tempReadWriteData[DATA_WIDTH-1-i] <= rD;
                                            i                            <= i + 1'b1;
                                        end
                                        else if (i == DATA_WIDTH) begin
                                            dataInternal        <= tempReadWriteData;
                                            addressInternal     <= addressInternalBurtstBegin;
                                            wr                  <= 1;
                                            i                   <= i + 1'b1;    
                                        end
                                        else if (~ready && i <= DATA_WIDTH) begin
                                            wr <= 0;
                                        end
                                        else if (i > DATA_WIDTH) begin
                                            i <= 0;
                                            wr <=0;
                                            communicationState <= over;
                                            clock_counter       <= 1'b0;
                                        end
                                    end
                                    else begin
                                        if (i < DATA_WIDTH) begin
                                            wrD                 <= tempReadWriteData[DATA_WIDTH-1-i];
                                            addressInternal     <= addressInternalBurtstBegin;
                                            i                   <= i + 1'b1;
                                            valid               <= 1;
                                        end
                                        else begin
                                            valid               <= 0;
                                            i                   <= 0;
                                            communicationState  <= over;
                                            last                <= 0;
                                            clock_counter       <= 1'b0;
                                        end
                                    end
                                end
                                else begin: burstMode
                                    if (tempRdWr == 0)begin: burstReadMode  
                                        if(burstLen > 1 ) begin
                                            if (i < DATA_WIDTH && ready) begin
                                                tempReadWriteData[DATA_WIDTH-1-i] <= rD;
                                                i               <= i + 1'b1;
                                                wr              <= 0;
                                                valid           <= 1;
                                            end
                                            else if (i == DATA_WIDTH || ready) begin
                                                tempReadWriteData[i]             <= rD;
                                                dataInternal                <= tempReadWriteData;
                                                addressInternal             <= addressInternalBurtstBegin;
                                                addressInternalBurtstBegin  <= addressInternalBurtstBegin + 1'b1;
                                                wr                          <= 1;
                                                i                           <= 0; 
                                                valid                       <= 0;
                                                burstLen                    <= burstLen - 1'b1;   
                                                communicationState          <= masterDone; 
                                                arbSend                     <= 0;  
                                                clock_counter               <= 0;
                                            end
                                            else if (~ready) begin
                                                wr <= 0;
                                            end
                                        end
                                        else if (burstLen == 1)begin
                                            if (i < DATA_WIDTH && ready) begin
                                                    tempReadWriteData[DATA_WIDTH-1-i] <= rD;
                                                    i               <= i + 1'b1;
                                                    wr              <= 0;
                                                    valid           <= 1;
                                                    last            <= 1;
                                                end
                                                else if (i == DATA_WIDTH || ready ) begin
                                                    tempReadWriteData[i]             <= rD;
                                                    dataInternal                <= tempReadWriteData;
                                                    addressInternal             <= addressInternalBurtstBegin;
                                                    addressInternalBurtstBegin  <= addressInternalBurtstBegin + 1'b1;
                                                    wr                  <= 1;
                                                    i                   <= 0; 
                                                    last                <= 1;
                                                    valid               <= 0;
                                                    burstLen            <= burstLen - 1'b1;   
                                                end
                                                else if (~ready) begin
                                                    wr <= 0;
                                                end
                                        end
                                    end: burstReadMode

                                    else begin: burstWriteMode
                                        if(burstLen > 1) begin
                                            if (i < DATA_WIDTH) begin
                                                wrD                 <= tempReadWriteData[DATA_WIDTH-1-i];
                                                addressInternal     <= addressInternalBurtstBegin;
                                                i                   <= i + 1'b1;
                                                valid               <= 1;
                                            end
                                            else if (i == DATA_WIDTH) begin
                                                i                           <= 0;
                                                burstLen                    <= burstLen - 1'b1;
                                                addressInternalBurtstBegin  <= addressInternalBurtstBegin + 1'b1;
                                                tempReadWriteData                <= internalDataOut;
                                                valid                       <= 0;
                                                communicationState          <= masterDone;
                                                arbSend                     <= 0;
                                                clock_counter               <= 0;
                                            end
                                        end
                                        else if (burstLen == 1) begin
                                            if (i < DATA_WIDTH) begin
                                                wrD                 <= tempReadWriteData[DATA_WIDTH-1-i];
                                                addressInternal     <= addressInternalBurtstBegin;
                                                i                   <= i + 1'b1;
                                                valid               <= 1;
                                                last                <= 1;
                                            end
                                            else if (i == DATA_WIDTH) begin
                                                i                           <= 0;
                                                wrD                         <= tempReadWriteData[DATA_WIDTH-1-i];
                                                burstLen                    <= burstLen - 1'b1;
                                                addressInternalBurtstBegin  <= addressInternalBurtstBegin + 1'b1;
                                                tempReadWriteData                <= internalDataOut;
                                                valid                       <= 0;
                                                last                        <= 0;
                                                clock_counter               <= 1'b0;
                                                communicationState          <= over;
                                            end
                                        end
                                    end: burstWriteMode
                                end
                            end
                        end

                        //========================//
                        //=======Master Done======//
                        //========================//
                        masterDone: begin
                            /*  
                                After the master has finished the master hold process 
                                for priority stop it will inform the arbiter to 
                                changee the bus allocation
                            */
                            if (clock_counter < 2'd1 && splitOnot == 0) begin
                                arbSend            <= 0;
                                wr                 <= 0;
                                valid              <= 0;
                                control            <= 0;
                                tempControl_2[ADDRESS_WIDTH-1 : 0]    <= addressInternalBurtstBegin;
                                clock_counter      <= clock_counter + 1'b1;
                            end
                            else if (clock_counter < 2'd2 && splitOnot == 0 ) begin
                                arbSend             <= 1;
                                control             <= 1;
                                clock_counter       <= clock_counter + 1'b1;
                            end
                            else if (clock_counter == 2'd2 && splitOnot == 0 ) begin
                                communicationState <= idleCom;
                                control            <= 0;
                                arbSend            <= 0;
                            end
                            
                            else if (clock_counter < 2'd1 && splitOnot == 1) begin
                                arbSend            <= 0;
                                wr                 <= 0;
                                valid              <= 0;
                                control            <= 1;
                                tempControl_2[ADDRESS_WIDTH-1 : 0]    <= addressInternalBurtstBegin;
                                clock_counter <= clock_counter + 1'b1;
                            end
                            else if (clock_counter < 2'd2 && splitOnot == 1 ) begin
                                arbSend         <= 1;
                                control         <= 1;
                                clock_counter   <= clock_counter + 1'b1;
                            end
                            else if (clock_counter == 2'd2 && splitOnot == 1 ) begin
                                communicationState <= idleCom;
                                control            <= 0;
                                arbSend            <= 0;
                            end
                        end
                        
                        //========================//
                        //======Master Split======//
                        //========================//
                        masterSplit:
                        begin
                            communicationState <= masterDone; 
                            arbSend            <= 0;
                        end 
                        
                        //=======================================//
                        //   Split Communication continue state  //
                        //=======================================//
                        splitComContinue:
                        /*  
                            When the bus is reallocated to the master
                            after a split transaction
                        */ 
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
                                    
                                    if (burstLen == 0) begin 
                                        if (tempRdWr == 0) begin  // single read
                                            if (i < DATA_WIDTH && ready) begin
                                                tempReadWriteData[DATA_WIDTH-1-i] <= rD;
                                                i                            <= i + 1'b1;
                                            end
                                            else if (i == DATA_WIDTH) begin
                                                dataInternal        <= tempReadWriteData;
                                                addressInternal     <= addressInternalBurtstBegin;
                                                wr                  <= 1;
                                                i                   <= i + 1'b1;    
                                            end
                                            else if (~ready && i <= DATA_WIDTH) begin
                                                wr <= 0;
                                            end
                                            else if (i > DATA_WIDTH) begin
                                                i <= 0;
                                                wr <=0;
                                                clock_counter       <= 1'b0;
                                                communicationState <= over;
                                            end
                                        end
                                    end
                                    else begin // burst read
                                        if(burstLen > 1 ) begin
                                            if (i < DATA_WIDTH && ready) begin
                                                tempReadWriteData[DATA_WIDTH-1-i] <= rD;
                                                i               <= i + 1'b1;
                                                wr              <= 0;
                                                valid           <= 1;
                                            end
                                            else if (i == DATA_WIDTH || ready) begin
                                                tempReadWriteData[i]             <= rD;
                                                dataInternal                <= tempReadWriteData;
                                                addressInternal             <= addressInternalBurtstBegin;
                                                addressInternalBurtstBegin  <= addressInternalBurtstBegin + 1'b1;
                                                wr                          <= 1;
                                                i                           <= 0; 
                                                valid                       <= 0;
                                                burstLen                    <= burstLen - 1'b1;   
                                            end
                                            else if (~ready) begin
                                                wr <= 0;
                                            end
                                        end
                                        else if( burstLen == 1 ) begin
                                            if (i < DATA_WIDTH && ready) begin
                                                tempReadWriteData[DATA_WIDTH-1-i] <= rD;
                                                i               <= i + 1'b1;
                                                wr              <= 0;
                                                valid           <= 1;
                                                last            <= 1;
                                            end
                                            else if (i == DATA_WIDTH || ready ) begin
                                                tempReadWriteData[i]             <= rD;
                                                dataInternal                <= tempReadWriteData;
                                                addressInternal             <= addressInternalBurtstBegin;
                                                addressInternalBurtstBegin  <= addressInternalBurtstBegin + 1'b1;
                                                wr                  <= 1;
                                                i                   <= 0; 
                                                last                <= 1;
                                                valid               <= 0;
                                                burstLen            <= burstLen - 1'b1;   
                                            end
                                            else if (~ready) begin
                                                wr <= 0;
                                            end
                                        end
                                        else begin
                                            last                <= 0;
                                            wr <= 0;
                                            clock_counter       <= 1'b0;
                                            communicationState <= over;
                                        end
                                    end
                                end
                            end
                            else if (fromArbiter == 2'b00)begin 
                                communicationState <= masterHold;
                                splitOnot          <= 0;
                                arbSend            <= 0;
                                if (burstLen == 0) begin    // single
                                    if (tempRdWr == 0) begin   // read single 
                                        if (ready) begin
                                            if (i < DATA_WIDTH) begin
                                                tempReadWriteData[DATA_WIDTH-1-i] <= rD;
                                                i                            <= i + 1'b1;
                                            end
                                            else if (i == DATA_WIDTH) begin
                                            dataInternal        <= tempReadWriteData;
                                            addressInternal     <= addressInternalBurtstBegin;
                                            wr                  <= 1;
                                            i                   <= i + 1'b1;     
                                            end
                                            else if (~ready && i <= DATA_WIDTH) begin
                                                wr <= 0;
                                            end
                                            else if (i > DATA_WIDTH) begin
                                                i <= 0;
                                                wr <=0;
                                                clock_counter       <= 1'b0;
                                                communicationState <= over;
                                            end
                                        end
                                    end
                                    else begin  // single write 
                                        if (i < DATA_WIDTH) begin
                                            wrD                 <= tempReadWriteData[DATA_WIDTH-1-i];
                                            addressInternal     <= addressInternalBurtstBegin;
                                            i                   <= i + 1'b1;
                                            valid               <= 1;
                                        end
                                        
                                        else begin
                                            valid               <= 0;
                                            i                   <= 0;
                                            communicationState  <= over;
                                            last                <= 0;
                                        end
                                    end
                                end
                                else begin // burst
                                    if (tempRdWr == 0)begin  // burst read   
                                        if(burstLen > 1 ) begin
                                            if (i < DATA_WIDTH && ready) begin
                                                tempReadWriteData[DATA_WIDTH-1-i] <= rD;
                                                i               <= i + 1'b1;
                                                wr              <= 0;
                                                valid           <= 1;
                                            end
                                            else if (i == DATA_WIDTH || ready) begin
                                                tempReadWriteData[i]             <= rD;
                                                dataInternal                <= tempReadWriteData;
                                                addressInternal             <= addressInternalBurtstBegin;
                                                addressInternalBurtstBegin  <= addressInternalBurtstBegin + 1'b1;
                                                wr                  <= 1;
                                                i                   <= 0; 
                                                valid               <= 0;
                                                burstLen            <= burstLen - 1'b1;   
                                                communicationState  <= masterDone;   
                                            end
                                            else if (~ready) begin
                                                wr <= 0;
                                            end
                                        end
                                         else if( burstLen == 1 ) begin
                                            if (i < DATA_WIDTH && ready) begin
                                                tempReadWriteData[DATA_WIDTH-1-i] <= rD;
                                                i               <= i + 1'b1;
                                                wr              <= 0;
                                                valid           <= 1;
                                                last            <= 1;
                                            end
                                            else if (i == DATA_WIDTH || ready ) begin
                                                tempReadWriteData[i]             <= rD;
                                                dataInternal                <= tempReadWriteData;
                                                addressInternal             <= addressInternalBurtstBegin;
                                                addressInternalBurtstBegin  <= addressInternalBurtstBegin + 1'b1;
                                                wr                  <= 1;
                                                i                   <= 0; 
                                                last                <= 1;
                                                valid               <= 0;
                                                burstLen            <= burstLen - 1'b1;  
                                                clock_counter       <= 1'b0; 
                                                communicationState  <= over; 
                                            end
                                            else if (~ready) begin
                                                wr <= 0;
                                            end
                                        end
                                    end

                                    else begin
                                        if(burstLen > 1) begin
                                            if (i < DATA_WIDTH) begin
                                                wrD                 <= tempReadWriteData[DATA_WIDTH-1-i];
                                                addressInternal     <= addressInternalBurtstBegin;
                                                i                   <= i + 1'b1;
                                                valid               <= 1;
                                            end
                                            else if (i == DATA_WIDTH) begin
                                                i                           <= 0;
                                                burstLen                    <= burstLen - 1'b1;
                                                addressInternalBurtstBegin  <= addressInternalBurtstBegin + 1'b1;
                                                tempReadWriteData           <= internalDataOut;
                                                valid                       <= 0;
                                                communicationState          <= masterDone;
                                            end
                                        end
                                        else if (burstLen == 1) begin
                                            if (i < DATA_WIDTH-1) begin
                                                wrD                 <= tempReadWriteData[DATA_WIDTH-1-i];
                                                addressInternal     <= addressInternalBurtstBegin;
                                                i                   <= i + 1'b1;
                                                valid               <= 1;
                                                last                <= 1;
                                            end
                                            else if (i == DATA_WIDTH-1) begin
                                                i                           <= 0;
                                                wrD                         <= tempReadWriteData[DATA_WIDTH-1-i];
                                                burstLen                    <= burstLen - 1'b1;
                                                addressInternalBurtstBegin  <= addressInternalBurtstBegin + 1'b1;
                                                tempReadWriteData           <= internalDataOut;
                                                valid                       <= 1;
                                                last                        <= 1;
                                                communicationState          <= over;
                                                clock_counter               <= 1'b0; 
                                            end
                                        end
                                    end
                                end
                            end
                        
                        
                        //=========================//
                        //========== Over =========//
                        //=========================//
                        over: 
                        /*  
                            Notify the arbiter the end of communication
                        */
                            begin
                                last            <= 0;
                                valid           <= 0;
                                wr              <= 0;
                                if (clock_counter < 2'd1) begin
                                    arbSend <= 0;
                                    clock_counter <= clock_counter + 1'b1;
                                end
                                else if (clock_counter < 2'd3) begin
                                    arbSend <= 1;
                                    clock_counter <= clock_counter + 1'b1;
                                end
                                else if (clock_counter == 2'd3) begin
                                    arbSend         <= 0;
                                    doneCom         <= 1;
                                    dataOut         <= dataInternal;
                                    addressInternal <= address;
                                end
                            end

                    endcase
                end
                
            //==========================//
            //===========Done===========// 
            //==========================//
                else begin
                    state <= done;
                    communicationState  <= over; 
                end
            done: 
            /*  
                State in which master allows the top module to read the data
                stored in its memory
            */
                begin
                    doneCom         <= 1;
                    addressInternal <= address;
                    dataOut         <= internalDataOut;    
                end
        endcase
        end
    
    end

endmodule: master 
