module masterExternal #(
    parameter DATA_WIDTH    = 8,        // datawidth of the sent data
    parameter DATA_FROM_TOP = 8'b00001010,    // initial start data
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
        input   logic                             arbCont,


        output  logic                             arbSend
);



localparam CONTROL_LEN = 4 + $clog2(NUM_OF_SLAVES);
// localparam SLAVEID = 3'b101 ;
localparam ACK = 8'b11001100;


logic [1:0]                 tempHold;
logic                       splitOnot;
logic [1:0]                 clock_counter;
// logic                       priority_;

logic [1:0]                 fromArbiter;
logic [4:0]                 arbiterCounnter;

logic [4:0]                 controlCounter;
logic [5:0]                 arbiterRequest, tempArbiterRequest;

logic [CONTROL_LEN:0]     tempControl,tempControl_2;
logic [DATA_WIDTH*2-1:0]      tempReadWriteData;
logic [DATA_WIDTH-1:0]      tempDataAck;
logic [$clog2(2*DATA_WIDTH):0] i;
logic [$clog2(CLK_FREQ*CLOCK_DURATION)-1:0]    clock_;
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
        fromArbiter         <= 0;
        tempReadWriteData   <= 0;
        i                   <= 0;
        control             <= 0;
        valid               <= 0;
        doneCom             <= 0;
        controlCounter      <= 0;
        tempHold            <= 0;
        clock_              <= 0;
        clock_counter       <= 0;
        arbiterCounnter     <= 0;
        splitOnot           <= 0;
        state               <= configMaster;
        communicationState  <= idleCom;
        
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
                    tempReadWriteData        <= 0;
                    i                   <= 0;
                    control             <= 0;
                    valid               <= 0;
                    doneCom             <= 0;
                    controlCounter      <= 0;
                    clock_              <= 0;
                    tempHold            <= 0;
                    clock_counter       <= 0;
                    arbiterCounnter     <= 0;
                    splitOnot           <= 0;
                    state               <= read_data;
                    communicationState  <= idleCom;
                    tempControl         <= {3'b111, SLAVEID, 1'b0};
                    tempControl_2       <= {3'b111, SLAVEID, 1'b0};
                    arbiterRequest      <= {3'b111, SLAVEID};
                    tempArbiterRequest  <= {3'b111, SLAVEID};
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
                    end
                    else if (clock_ < CLK_FREQ*CLOCK_DURATION)begin
                        clock_       <= clock_ + 1'b1;
                        dataOut      <= tempReadWriteData[DATA_WIDTH-1:0];
                        disData      <= 1;
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
                                if (arbiterCounnter < 4'd6) begin
                                    arbSend                 <= arbiterRequest[5];
                                    arbiterRequest          <= {arbiterRequest[4:0], 1'b0};
                                    arbiterCounnter         <= arbiterCounnter + 1'b1;
                                end

                                else if (arbiterCounnter == 4'd6) begin
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
                                if (arbiterCounnter < 4'd7) begin
                                    arbSend             <= 1'b0;        // second ack
                                    arbiterCounnter     <= arbiterCounnter + 3'd1;
                                    communicationState  <= reqAck;
                                end
                                else if (arbiterCounnter < 4'd8) begin
                                    arbSend             <= 1'b1;        // 3rd ack
                                    arbiterCounnter     <= arbiterCounnter + 3'd1;
                                    communicationState  <= reqAck;
                                end
                                else if (arbiterCounnter < 4'd12) begin
                                    arbiterCounnter     <= arbiterCounnter + 3'd1;
                                end
                                else if (arbiterCounnter == 4'd12) begin
                                    arbSend             <= 1'b1;
                                    arbiterCounnter     <= 3'd0;
                                    control             <= tempControl[6];
                                    tempControl         <= {tempControl[5:0] ,1'b0};
                                    controlCounter      <= controlCounter + 5'd1;
                                    communicationState  <= masterCom;
                                end

                            masterCom:
                            
                                if (fromArbiter == 2'b11 || fromArbiter == 2'b10) begin

                                    if (controlCounter < CONTROL_LEN) begin
                                        control             <= tempControl[6];
                                        tempControl         <= {tempControl[5:0] ,1'b0};
                                        controlCounter      <= controlCounter + 5'd1;

                                        
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
                                    // control 		<= 1;
                                    communicationState <= masterHold;
                                    arbSend <= 0;       // fisrt hold bit
                                    if (controlCounter < CONTROL_LEN) begin
                                        control             <= tempControl[6];
                                        tempControl         <= {tempControl[5:0] ,1'b0};
                                        controlCounter      <= controlCounter + 5'd1;                                    
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
                                        control             <= tempControl[6];
                                        tempControl         <= {tempControl[5:0] ,1'b0};
                                        controlCounter      <= controlCounter + 5'd1;                                    
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

                            masterDone: begin //this will not happen cause we are sending only 1 byte of data
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
                        state <= end_com;
                        communicationState <= idleCom;
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
                                if (arbiterCounnter < 4'd7) begin
                                    arbSend                 <= arbiterRequest[5];
                                    arbiterRequest          <= {arbiterRequest[4:0], 1'b0};
                                    arbiterCounnter         <= arbiterCounnter + 1'b1;
                                end
                                else if (arbiterCounnter == 4'd7) begin
                                    arbiterCounnter     <= arbiterCounnter;
                                    if (fromArbiter == 2'b11) begin
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
                                if (arbiterCounnter < 4'd8) begin
                                    arbSend             <= 1'b0;        // second ack
                                    arbiterCounnter     <= arbiterCounnter + 3'd1;
                                    communicationState  <= reqAck;
                                end
                                else if (arbiterCounnter < 4'd9) begin
                                    arbSend             <= 1'b1;        // 3rd ack
                                    arbiterCounnter     <= arbiterCounnter + 3'd1;
                                    communicationState  <= reqAck;
                                end
                                else if (arbiterCounnter < 4'd13) begin
                                    arbiterCounnter     <= arbiterCounnter + 3'd1;
                                end
                                else if (arbiterCounnter == 4'd13) begin
                                    arbSend             <= 1'b1;
                                    arbiterCounnter     <= 3'd0;
                                    control             <= tempControl[6];
                                    tempControl         <= {tempControl[5:0] ,1'b0};
                                    controlCounter      <= controlCounter + 5'd1;
                                    if (splitOnot == 1)begin
                                        communicationState <= splitComContinue;
                                        clock_counter      <= 0;
                                        // control            <= 1;
                                    end
                                    else begin
                                    communicationState  <= masterCom;
                                    end
                                end

                            masterCom:
                            
                                if (fromArbiter == 2'b11 || fromArbiter == 2'b10) begin

                                    if (controlCounter < CONTROL_LEN) begin
                                        control             <= tempControl[6];
                                        tempControl         <= {tempControl[5:0] ,1'b0};
                                        controlCounter      <= controlCounter + 5'd1;

                                        
                                    end  
                                    else if (controlCounter == CONTROL_LEN) begin
                                        controlCounter      <= controlCounter;
                                        control             <= 0;
                                        

                                        //========================//
                                        //========= Read =========//
                                        //========================//
                                        if (i < 2*DATA_WIDTH && ready) begin
                                            doneCom                   <= 2'b11;
                                            tempReadWriteData[2*DATA_WIDTH-1-i] <= rD;
                                            i                            <= i + 1'b1;
                                        end
                                        else if (i == 2*DATA_WIDTH) begin
                                            i <= 0;
                                            communicationState  <= over;
                                        end
                                    end
                                end


                                else if (fromArbiter == 2'b00)begin: priorityStop
                                    // control 		<= 1;
                                    communicationState <= masterHold;
                                    arbSend <= 0;       // fisrt hold bit
                                    if (controlCounter < CONTROL_LEN) begin
                                        control             <= tempControl[6];
                                        tempControl         <= {tempControl[5:0] ,1'b0};
                                        controlCounter      <= controlCounter + 5'd1;                                    
                                    end  
                                    else if (controlCounter == CONTROL_LEN) begin
                                        controlCounter      <= controlCounter;
                                        control             <= 0;

                                        if (i < 2*DATA_WIDTH && ready) begin
                                            tempReadWriteData[2*DATA_WIDTH-1-i] <= rD;
                                            i                            <= i + 1'b1;
                                        end
                                        else if (i == 2*DATA_WIDTH) begin
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
                                        control             <= tempControl[6];
                                        tempControl         <= {tempControl[5:0] ,1'b0};
                                        controlCounter      <= controlCounter + 5'd1;                                    
                                    end  
                                    else if (controlCounter == CONTROL_LEN) begin
                                        controlCounter      <= controlCounter;
                                        control             <= 0;
                                        if (arbCont == 1 || fromArbiter == 2'b11) begin
                                            if (i < 2*DATA_WIDTH && ready) begin
                                                tempReadWriteData[2*DATA_WIDTH-1-i] <= rD;
                                                i                            <= i + 1'b1;
                                            end
                                            else if (i == 2*DATA_WIDTH) begin
                                                i <= 0;;
                                                communicationState <= masterDone;
                                            end
                                        end
                                    end
                                end

                            masterDone: begin
                                if (clock_counter < 2'd1 && splitOnot == 0) begin
                                    arbSend            <= 1;
                                    valid              <= 0;
                                    control            <= 0;
                                    clock_counter <= clock_counter + 1'b1;
                                end
                                else if (clock_counter < 2'd2 && splitOnot == 0 ) begin
                                    arbSend <= 0;
                                    control <= 1;
                                    clock_counter <= clock_counter + 1'b1;
                                end
                                else if (clock_counter == 2'd2 && splitOnot == 0 ) begin
                                    communicationState <= idleCom;
                                    control            <= 0;
                                end
                                
                                else if (clock_counter < 2'd1 && splitOnot == 1) begin
                                    arbSend            <= 1;
                                    valid              <= 0;
                                    control            <= 1;
                                    clock_counter <= clock_counter + 1'b1;
                                end
                                else if (clock_counter < 2'd2 && splitOnot == 1 ) begin
                                    arbSend <= 0;
                                    control <= 1;
                                    clock_counter <= clock_counter + 1'b1;
                                end
                                else if (clock_counter == 2'd2 && splitOnot == 1 ) begin
                                    communicationState <= idleCom;
                                    control            <= 0;
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
                                        if (i < 2*DATA_WIDTH && ready) begin
                                            tempReadWriteData[2*DATA_WIDTH-1-i] <= rD;
                                            i                            <= i + 1'b1;
                                        end
                                        else if (i == 2*DATA_WIDTH) begin
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
                                        control             <= tempControl[6];
                                        tempControl         <= {tempControl[5:0] ,1'b0};
                                        controlCounter      <= controlCounter + 5'd1;                                    
                                    end  
                                    else if (controlCounter == CONTROL_LEN) begin
                                        controlCounter      <= controlCounter;
                                        control             <= 0;

                                        if (i < 2*DATA_WIDTH && ready) begin
                                            tempReadWriteData[2*DATA_WIDTH-1-i] <= rD;
                                            i                            <= i + 1'b1;
                                        end
                                        else if (i == 2*DATA_WIDTH) begin
                                            i <= 0;
                                            communicationState  <= over;
                                        end
                                    end
                                end
                            
                            

                            over: 
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
                                begin
                                    if (tempReadWriteData[(DATA_WIDTH*2-1) -: DATA_WIDTH] == ACK) begin
                                        /* 
                                        acknowledgement received correctly
                                        */
                                        state              <= displayData;
                                        communicationState <= idleCom;
                                        doneCom            <= 2'b11;
                                    end
                                    else begin
                                        state              <= end_com;
                                        communicationState <= idleCom;
                                        doneCom            <= 2'b01;
                                        end
                                end

                        endcase
                    end
                    else if (start && ~eoc)begin
                        state              <= displayData;
                        communicationState <= idleCom;
                        tempReadWriteData[DATA_WIDTH-1 :0]  <= DATA_FROM_TOP;
                    end
                    else if (~start && eoc) begin
                        state              <= end_com;
                        communicationState <= idleCom;
                        doneCom            <= 2'b01;
                    end
                end

            

           
                
            //==========================//
            //===========Done===========// 
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