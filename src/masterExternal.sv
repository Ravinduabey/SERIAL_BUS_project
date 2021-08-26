module masterExternal #(
    parameter DATA_WIDTH    = 8
)( 

	    ///////////////////////
        //===================//
        //  with topModule   //
        //===================// 
	    ///////////////////////
		  
        input   logic                             clk,      // clock
        input   logic                             rstN,     // reset
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
		  

        ///////////////////////
        //===================//
        //    with arbiter   //
        //===================// 
	    ///////////////////////
        input   logic                             arbCont,


        output  logic                             arbSend
);




localparam CONTROL_LEN = 7;
localparam slaveId = 3'b100 ;



logic [1:0]                 tempHold;
logic                       splitOnot;
logic [1:0]                 clock_counter;
// logic                       priority_;

logic [1:0]                 fromArbiter;
logic [4:0]                 arbiterCounnter;

logic [4:0]                 controlCounter;
logic [4:0]                 arbiterRequest, tempArbiterRequest;

logic [CONTROL_LEN-1:0]     tempControl,tempControl_2;
logic [DATA_WIDTH-1:0]      tempReadData;
logic [$clog2(DATA_WIDTH):0] i;

// define states for the top module
typedef enum logic [2:0]{
    idle,
    write_data,
    read_data,
    increment_data,
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

logic communicationDone;

always_ff @( posedge clk or negedge rstN) begin : topModule
    if (~rstN) begin
        fromArbiter         <= 0;
        tempReadData        <= 0;
        i                   <= 0;
        control             <= 0;
        valid               <= 0;
        doneCom             <= 0;
        controlCounter      <= 0;
        tempHold            <= 0;
        clock_counter       <= 0;
        arbiterCounnter     <= 0;
        splitOnot           <= 0;
        state               <= idle;
        communicationState  <= idleCom;
        // internalComState    <= checkState;
        
    end
    else begin : topStates
        case (state) 
            //==========================//
            //===========IDLE===========// 
            //==========================//
            idle:
                if (start && ~eoc) begin    
                    /*  set state to write data 
                        assign the control signal with signal to slave
                        assign the arbiter request
                    */
                    state                       <= write_data;
                    tempControl                 <= {3'b111, slaveId, rdWr};
                    tempControl_2               <= {3'b111, slaveId, rdWr};
                    arbiterRequest              <= {3'b111, slaveId};
                    tempArbiterRequest          <= {3'b111, slaveId};
                    
                end
                else if (~start && eoc) begin
                    /*
                        when it is required to stop the communication 
                        externally 
                    */
                    state <= done;
                end

                else if (~start && ~eoc)begin
                    /*
                        go to master default state in which it would be in continous 
                        read waiting for slave to send data to be read and displayed
                        from another board 
                    */
                    fromArbiter         <= 0;
                    tempReadData        <= 0;
                    i                   <= 0;
                    control             <= 0;
                    valid               <= 0;
                    doneCom             <= 0;
                    controlCounter      <= 0;
                    tempHold            <= 0;
                    clock_counter       <= 0;
                    arbiterCounnter     <= 0;
                    splitOnot           <= 0;
                    state               <= read_data;
                    communicationState  <= idleCom;
                end

            

            //=====================================//
            //=========start Communication=========// 
            //=====================================//
            read_data:
                if(doneCom == 1'b0) begin
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
                            end

                        reqCom:
                            if (arbiterCounnter < 4'd6) begin
                                arbSend                 <= arbiterRequest[4];
                                arbiterRequest          <= {arbiterRequest[3:0], 1'b0};
                                arbiterCounnter         <= arbiterCounnter + 1'b1;
                            end
                            else if (arbiterCounnter == 4'd6) begin
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
                                control             <= tempControl[18];
                                tempControl         <= {tempControl[17:0] ,1'b0};
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
                                    if (i < DATA_WIDTH && ready) begin
                                        tempReadData[DATA_WIDTH-1-i] <= rD;
                                        i                            <= i + 1'b1;
                                    end
                                    else if (i == DATA_WIDTH) begin
                                        i <= 0;
                                        communicationState  <= over;
                                    end
                                    


                                    
                                    
                                    singleWrite:
                                        if (i < DATA_WIDTH) begin
                                            wrD                 <= tempReadData[DATA_WIDTH-1-i];
                                            addressInternal     <= addressInternalBurtstBegin;
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

                                    if (i < DATA_WIDTH && ready) begin
                                        tempReadData[DATA_WIDTH-1-i] <= rD;
                                        i                            <= i + 1'b1;
                                    end
                                    else if (i == DATA_WIDTH) begin
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
                                        if (i < DATA_WIDTH && ready) begin
                                            tempReadData[DATA_WIDTH-1-i] <= rD;
                                            i                            <= i + 1'b1;
                                        end
                                        else if (i == DATA_WIDTH) begin
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
                                    if (i < DATA_WIDTH && ready) begin
                                        tempReadData[DATA_WIDTH-1-i] <= rD;
                                        i                            <= i + 1'b1;
                                    end
                                    else if (i == DATA_WIDTH) begin
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

                                    if (i < DATA_WIDTH && ready) begin
                                        tempReadData[DATA_WIDTH-1-i] <= rD;
                                        i                            <= i + 1'b1;
                                    end
                                    else if (i == DATA_WIDTH) begin
                                        i <= 0;
                                        state <= increment_data;
                                    end
                                end
                            end
                        
                        

                        over: 
                            begin
                                valid           <= 0;
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
                                end
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
                    dataOut         <= tempReadData;    
                end
        endcase
        end
    
    end

endmodule: masterExternal 
