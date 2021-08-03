`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 	Carrier Frequency, Inc.
// Engineer: 	Jon Carrier
// 
// Create Date:    21:33:11 06/17/2011 
// Design Name: 
// Module Name:    FPGA_2_LCD 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 	The clock should be set to 24MHz. Slower clocks should also work.
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: This module performs the full initialization procedure.
//								Once init is done, the module takes in DATA and processes
//								it according to OPER. When idle, the module indicates RDY.
//								ENB, indicates that DATA and OPER are valid and the module 
//								should start to read the lines.
//								Note: the calling module must keep DATA valid until RDY re-asserts
//
//////////////////////////////////////////////////////////////////////////////////
module FPGA_2_LCD(
	CLK, LCD_RS, LCD_RW, LCD_E, LCD_DB, RDY, DATA, OPER, ENB, RST
);
input CLK;			// For this code to work without modification, CLK should equal 24MHz
input DATA;			// The Data to send to the LCD Module
input OPER;			// The Type of operation to perform (data or instruction) 
input ENB;			// Tells the module that the data is valid and start reading DATA and OPER
input RST;

output RDY;			// Indicates that the module is Idle and ready to take more data
output LCD_RS, LCD_RW, LCD_E;
output [7:0] LCD_DB;


wire [7:0] DATA;
wire [1:0] OPER;
wire ENB;
reg RDY;

reg [7:0] LCD_DB=0;
reg LCD_RW=0;			// always write to (and never read from) the LCD
reg LCD_RS=0;			// HI means Data, LOW means Instruction/Command
reg LCD_E=0;

/*----------------------SOME NOTES-------------------
when RS and R/W change STATE...wait for at least 40ns ( ~1clock cycle )
after that period of time bring E high and invert E every 250ns (can be larger) ( ~6 clock cycles)
while E is HI, set DATA
when E goes LOW, maintain DATA for atleast 10ns
CLOCK=24MHz ==> 41.667ns
-------------------------END OF NOTES-------------------*/
//===============================================================================================
//------------------------------Define the Timing Parameters-------------------------------------
//===============================================================================================
parameter [19:0] t_40ns 	= 1;		//40ns 		== ~1clk
parameter [19:0] t_250ns 	= 6;		//250ns 	== ~6clks
parameter [19:0] t_42us 	= 1008;		//42us 		== ~1008clks
parameter [19:0] t_100us 	= 2400;		//100us		== ~2400clks
parameter [19:0] t_1640us 	= 39360;	//1.64ms 	== ~39360clks
parameter [19:0] t_4100us 	= 98400;	//4.1ms    	== ~98400clks
parameter [19:0] t_15000us	= 360000;	//15ms 		== ~360000clks

//===============================================================================================
//------------------------------Define the BASIC Command Set-------------------------------------
//===============================================================================================
parameter [7:0] SETUP		= 8'b00111000;	//Execution time = 42us, sets to 8-bit interface, 2-line display, 5x7 dots
parameter [7:0] DISP_ON		= 8'b00001100;	//Execution time = 42us, Turn ON Display
parameter [7:0] ALL_ON		= 8'b00001111;	//Execution time = 42us, Turn ON All Display
parameter [7:0] ALL_OFF		= 8'b00001000;	//Execution time = 42us, Turn OFF All Display
parameter [7:0] CLEAR 		= 8'b00000001; 	//Execution time = 1.64ms, Clear Display
parameter [7:0] ENTRY_N		= 8'b00000110;	//Execution time = 42us, Normal Entry, Cursor increments, Display is not shifted
parameter [7:0] HOME 		= 8'b00000010; 	//Execution time = 1.64ms, Return Home
parameter [7:0] C_SHIFT_L 	= 8'b00010000; 	//Execution time = 42us, Cursor Shift
parameter [7:0] C_SHIFT_R 	= 8'b00010100; 	//Execution time = 42us, Cursor Shift
parameter [7:0] D_SHIFT_L 	= 8'b00011000; 	//Execution time = 42us, Display Shift
parameter [7:0] D_SHIFT_R 	= 8'b00011100; 	//Execution time = 42us, Display Shift

//===============================================================================================
//-----------------------------Create the counting mechanisms------------------------------------
//===============================================================================================
reg [19:0] cnt_timer=0; 			//39360 clks, used to delay the STATEmachine during a command execution (SEE above command set)
reg flag_250ns=0,flag_42us=0,flag_100us=0,flag_1640us=0,flag_4100us=0,flag_15000us=0;
reg flag_rst=1;					//Start with flag RST set. so that the counting has not started

always @(posedge CLK) begin
	if(flag_rst) begin
		flag_250ns	<=	1'b0;		//Unlatch the flag
		flag_42us	<=	1'b0;		//Unlatch the flag
		flag_100us	<=	1'b0;		//Unlatch the flag
		flag_1640us	<=	1'b0;		//Unlatch the flag
		flag_4100us	<=	1'b0;		//Unlatch the flag
		flag_15000us    <=	1'b0;		//Unlatch the flag
		cnt_timer	<=	20'b0;		
	end
	else begin
		if(cnt_timer>=t_250ns) begin			
			flag_250ns	<=	1'b1;
		end
		else begin			
			flag_250ns	<=	flag_250ns;
		end
		//----------------------------
		if(cnt_timer>=t_42us) begin			
			flag_42us	<=	1'b1;
		end
		else begin			
			flag_42us	<=	flag_42us;
		end
		//----------------------------
		if(cnt_timer>=t_100us) begin			
			flag_100us	<=	1'b1;
		end
		else begin			
			flag_100us	<=	flag_100us;
		end
		//----------------------------
		if(cnt_timer>=t_1640us) begin			
			flag_1640us	<=	1'b1;
		end
		else begin			
			flag_1640us	<=	flag_1640us;
		end
		//----------------------------
		if(cnt_timer>=t_4100us) begin			
			flag_4100us	<=	1'b1;
		end
		else begin			
			flag_4100us	<=	flag_4100us;
		end
		//----------------------------
		if(cnt_timer>=t_15000us) begin			
			flag_15000us	<=	1'b1;
		end
		else begin			
			flag_15000us	<=	flag_15000us;
		end
		//----------------------------
		cnt_timer	<= cnt_timer + 1;
	end
end

//##########################################################################################
//-----------------------------Create the STATE MACHINE------------------------------------
//##########################################################################################
reg [3:0] STATE=0;
reg [1:0] SUBSTATE=0;

always @(posedge CLK) begin
	case(STATE)
		//---------------------------------------------------------------------------------------
		0: begin //---------------Initiate Command Sequence (RS=LOW)-----------------------------
			LCD_RS	<=		1'b0;										//Indicate an instruction is to be sent soon
			LCD_RW	<= 	1'b0;										//Indicate a write operation
			LCD_E		<=		1'b0;										//We are in the initial setup, keep low until 250ns has past
			LCD_DB 	<= 	8'b00000000;
			RDY					<= 1'b0;								//Indicate that the module is busy
			SUBSTATE	<=		0;
			if(!flag_15000us) begin									//WAIT 15ms...worst case scenario
				STATE				<=	STATE;						//Remain in current STATE
				flag_rst			<=	1'b0; 						//Start or Continue counting				
			end
			else begin 				
				STATE				<=	STATE+1;						//Go to next STATE
				flag_rst			<=	1'b1; 						//Stop counting				
			end		
		end
		//---------------------------------------------------------------------------------------
		1: begin //-----------SET FUNCTION #1, 8-bit interface, 2-line display, 5x7 dots---------
			LCD_RS				<=	1'b0;						//Indicate an instruction is to be sent soon
			LCD_RW				<=	1'b0;						//Indicate a write operation
			RDY					<= 1'b0;						//Indicate that the module is busy
			if(SUBSTATE==0)begin	 		
				LCD_E				<=	1'b0;						//Disable Bus
				LCD_DB 			<=	LCD_DB;					//Maintain Previous Data on the Bus
				STATE				<=	STATE;					
				SUBSTATE			<=	1;
			end			
			if(SUBSTATE==1)begin				
				LCD_E				<=	1'b1;						//Enable Bus		
				LCD_DB 			<= SETUP;					//Data Valid
				if(!flag_250ns) begin						//WAIT at least 250ns (required for LCD_E)
					SUBSTATE		<=	SUBSTATE;				//Maintain current SUBSTATE
					flag_rst		<=	1'b0; 					//Start or Continue counting									
				end
				else begin 				
					SUBSTATE		<=	SUBSTATE+1;				//Go to next SUBSTATE
					flag_rst		<=	1'b1; 					//Stop counting					
				end
			end
			if(SUBSTATE==2)begin
				LCD_E				<=	1'b0;						//Disable Bus, Triggers LCD to read BUS
				LCD_DB 			<= LCD_DB;					//Keep Data Valid
				if(!flag_4100us) begin						//WAIT at least 4.1ms (required for Initialization)
					STATE			<=	STATE;					//Maintain current STATE
					SUBSTATE		<=	SUBSTATE;				//Maintain current SUBSTATE
					flag_rst		<=	1'b0; 					//Start or Continue counting									
				end
				else begin 		
					STATE			<=	STATE+1;					//Go to next STATE
					SUBSTATE		<=	0;							//Reset SUBSTATE
					flag_rst		<=	1'b1; 					//Stop counting					
				end
			end	
		end	
		//---------------------------------------------------------------------------------------
		2: begin //-----------SET FUNCTION #2, 8-bit interface, 2-line display, 5x7 dots---------
			LCD_RS				<=	1'b0;						//Indicate an instruction is to be sent soon
			LCD_RW				<=	1'b0;						//Indicate a write operation	
			RDY					<= 1'b0;						//Indicate that the module is busy
			if(SUBSTATE==0)begin	 		
				LCD_E				<=	1'b0;						//Disable Bus
				LCD_DB 			<=	LCD_DB;					//Maintain Previous Data on the Bus
				STATE				<=	STATE;				
				SUBSTATE			<=	1;
			end			
			if(SUBSTATE==1)begin				
				LCD_E				<=	1'b1;						//Enable Bus		
				LCD_DB 			<= SETUP;					//Data Valid
				if(!flag_250ns) begin						//WAIT at least 250ns (required for LCD_E)
					SUBSTATE		<=	SUBSTATE;				//Maintain current SUBSTATE
					flag_rst		<=	1'b0; 					//Start or Continue counting									
				end
				else begin 				
					SUBSTATE		<=	SUBSTATE+1;				//Go to next SUBSTATE
					flag_rst		<=	1'b1; 					//Stop counting					
				end
			end
			if(SUBSTATE==2)begin
				LCD_E				<=	1'b0;						//Disable Bus, Triggers LCD to read BUS
				LCD_DB 			<= LCD_DB;					//Keep Data Valid
				if(!flag_100us) begin						//WAIT at least 100us (required for Initialization)
					STATE			<=	STATE;					//Maintain current STATE
					SUBSTATE		<=	SUBSTATE;				//Maintain current SUBSTATE
					flag_rst		<=	1'b0; 					//Start or Continue counting									
				end
				else begin 		
					STATE			<=	STATE+1;					//Go to next STATE
					SUBSTATE		<=	0;							//Reset SUBSTATE
					flag_rst		<=	1'b1; 					//Stop counting					
				end
			end	
		end
		//---------------------------------------------------------------------------------------
		3: begin //-----------SET FUNCTION #3, 8-bit interface, 2-line display, 5x7 dots---------
			LCD_RS				<=	1'b0;						//Indicate an instruction is to be sent soon
			LCD_RW				<=	1'b0;						//Indicate a write operation	
			RDY					<= 1'b0;						//Indicate that the module is busy
			if(SUBSTATE==0)begin	 		
				LCD_E				<=	1'b0;						//Disable Bus
				LCD_DB 			<=	LCD_DB;					//Maintain Previous Data on the Bus
				STATE				<=	STATE;				
				SUBSTATE			<=	1;
			end			
			if(SUBSTATE==1)begin				
				LCD_E				<=	1'b1;						//Enable Bus		
				LCD_DB 			<= SETUP;					//Data Valid
				if(!flag_250ns) begin						//WAIT at least 250ns (required for LCD_E)
					SUBSTATE		<=	SUBSTATE;				//Maintain current SUBSTATE
					flag_rst		<=	1'b0; 					//Start or Continue counting									
				end
				else begin 				
					SUBSTATE		<=	SUBSTATE+1;				//Go to next SUBSTATE
					flag_rst		<=	1'b1; 					//Stop counting					
				end
			end
			if(SUBSTATE==2)begin
				LCD_E				<=	1'b0;						//Disable Bus, Triggers LCD to read BUS
				LCD_DB 			<= LCD_DB;					//Keep Data Valid
				if(!flag_100us) begin						//WAIT at least 100us (required for Initialization)
					STATE			<=	STATE;					//Maintain current STATE
					SUBSTATE		<=	SUBSTATE;				//Maintain current SUBSTATE
					flag_rst		<=	1'b0; 					//Start or Continue counting									
				end
				else begin 		
					STATE			<=	STATE+1;					//Go to next STATE
					SUBSTATE		<=	0;							//Reset SUBSTATE
					flag_rst		<=	1'b1; 					//Stop counting					
				end
			end
		end
		//---------------------------------------------------------------------------------------
		4: begin //-----------SET FUNCTION #4, 8-bit interface, 2-line display, 5x7 dots---------
			LCD_RS				<=	1'b0;						//Indicate an instruction is to be sent soon
			LCD_RW				<=	1'b0;						//Indicate a write operation	
			RDY					<= 1'b0;						//Indicate that the module is busy
			if(SUBSTATE==0)begin	 		
				LCD_E				<=	1'b0;						//Disable Bus
				LCD_DB 			<=	LCD_DB;					//Maintain Previous Data on the Bus
				STATE				<=	STATE;					
				SUBSTATE			<=	1;
			end			
			if(SUBSTATE==1)begin				
				LCD_E				<=	1'b1;						//Enable Bus		
				LCD_DB 			<= SETUP;					//Data Valid
				if(!flag_250ns) begin						//WAIT at least 250ns (required for LCD_E)
					SUBSTATE		<=	SUBSTATE;				//Maintain current SUBSTATE
					flag_rst		<=	1'b0; 					//Start or Continue counting									
				end
				else begin 				
					SUBSTATE		<=	SUBSTATE+1;				//Go to next SUBSTATE
					flag_rst		<=	1'b1; 					//Stop counting					
				end
			end
			if(SUBSTATE==2)begin
				LCD_E				<=	1'b0;						//Disable Bus, Triggers LCD to read BUS
				LCD_DB 			<= LCD_DB;					//Keep Data Valid
				if(!flag_100us) begin						//WAIT at least 100us (required for Initialization)
					STATE			<=	STATE;					//Maintain current STATE
					SUBSTATE		<=	SUBSTATE;				//Maintain current SUBSTATE
					flag_rst		<=	1'b0; 					//Start or Continue counting									
				end
				else begin 		
					STATE			<=	STATE+1;					//Go to next STATE
					SUBSTATE		<=	0;							//Reset SUBSTATE
					flag_rst		<=	1'b1; 					//Stop counting					
				end
			end
		end
		//---------------------------------------------------------------------------------------
		5: begin //-----------------DISPLAY, Display OFF, Cursor OFF, Blinking OFF------------------
			LCD_RS				<=	1'b0;						//Indicate an instruction is to be sent soon
			LCD_RW				<=	1'b0;						//Indicate a write operation	
			RDY					<= 1'b0;						//Indicate that the module is busy
			if(SUBSTATE==0)begin	 		
				LCD_E				<=	1'b0;						//Disable Bus
				LCD_DB 			<=	LCD_DB;					//Maintain Previous Data on the Bus
				STATE				<=	STATE;				
				SUBSTATE			<=	1;
			end			
			if(SUBSTATE==1)begin				
				LCD_E				<=	1'b1;						//Enable Bus		
				LCD_DB 			<= ALL_OFF;					//Data Valid
				if(!flag_250ns) begin						//WAIT at least 250ns (required for LCD_E)
					SUBSTATE		<=	SUBSTATE;				//Maintain current SUBSTATE
					flag_rst		<=	1'b0; 					//Start or Continue counting									
				end
				else begin 				
					SUBSTATE		<=	SUBSTATE+1;				//Go to next SUBSTATE
					flag_rst		<=	1'b1; 					//Stop counting					
				end
			end
			if(SUBSTATE==2)begin
				LCD_E				<=	1'b0;						//Disable Bus, Triggers LCD to read BUS
				LCD_DB 			<= LCD_DB;					//Keep Data Valid
				if(!flag_42us) begin							//WAIT at least 42us (required for operation to process)
					STATE			<=	STATE;					//Maintain current STATE
					SUBSTATE		<=	SUBSTATE;				//Maintain current SUBSTATE
					flag_rst		<=	1'b0; 					//Start or Continue counting									
				end
				else begin 		
					STATE			<=	STATE+1;					//Go to next STATE
					SUBSTATE		<=	0;							//Reset SUBSTATE
					flag_rst		<=	1'b1; 					//Stop counting					
				end
			end
		end
		//---------------------------------------------------------------------------------------
		6: begin //-------------------DISPLAY CLEAR, clear the display screen--------------------
			LCD_RS				<=	1'b0;						//Indicate an instruction is to be sent soon
			LCD_RW				<=	1'b0;						//Indicate a write operation	
			RDY					<= 1'b0;						//Indicate that the module is busy
			if(SUBSTATE==0)begin	 		
				LCD_E				<=	1'b0;						//Disable Bus
				LCD_DB 			<=	LCD_DB;					//Maintain Previous Data on the Bus
				STATE				<=	STATE;				
				SUBSTATE			<=	1;
			end			
			if(SUBSTATE==1)begin				
				LCD_E				<=	1'b1;						//Enable Bus		
				LCD_DB 			<= CLEAR;					//Data Valid
				if(!flag_250ns) begin						//WAIT at least 250ns (required for LCD_E)
					SUBSTATE		<=	SUBSTATE;				//Maintain current SUBSTATE
					flag_rst		<=	1'b0; 					//Start or Continue counting									
				end
				else begin 				
					SUBSTATE		<=	SUBSTATE+1;				//Go to next SUBSTATE
					flag_rst		<=	1'b1; 					//Stop counting					
				end
			end
			if(SUBSTATE==2)begin
				LCD_E				<=	1'b0;						//Disable Bus, Triggers LCD to read BUS
				LCD_DB 			<= LCD_DB;					//Keep Data Valid
				if(!flag_1640us) begin						//WAIT at least 1640us (required for operation to process)
					STATE			<=	STATE;					//Maintain current STATE
					SUBSTATE		<=	SUBSTATE;				//Maintain current SUBSTATE
					flag_rst		<=	1'b0; 					//Start or Continue counting									
				end
				else begin 		
					STATE			<=	STATE+1;					//Go to next STATE
					SUBSTATE		<=	0;							//Reset SUBSTATE
					flag_rst		<=	1'b1; 					//Stop counting					
				end
			end			
		end
		//---------------------------------------------------------------------------------------
		7: begin //---------Normal ENTRY, Cursor increments, Display is not shifted--------------
			LCD_RS				<=	1'b0;						//Indicate an instruction is to be sent soon
			LCD_RW				<=	1'b0;						//Indicate a write operation	
			RDY					<= 1'b0;						//Indicate that the module is busy
			if(SUBSTATE==0)begin	 		
				LCD_E				<=	1'b0;						//Disable Bus
				LCD_DB 			<=	LCD_DB;					//Maintain Previous Data on the Bus
				STATE				<=	STATE;				
				SUBSTATE			<=	1;
			end			
			if(SUBSTATE==1)begin				
				LCD_E				<=	1'b1;						//Enable Bus		
				LCD_DB 			<= ENTRY_N;					//Data Valid
				if(!flag_250ns) begin						//WAIT at least 250ns (required for LCD_E)
					SUBSTATE		<=	SUBSTATE;				//Maintain current SUBSTATE
					flag_rst		<=	1'b0; 					//Start or Continue counting									
				end
				else begin 				
					SUBSTATE		<=	SUBSTATE+1;				//Go to next SUBSTATE
					flag_rst		<=	1'b1; 					//Stop counting					
				end
			end
			if(SUBSTATE==2)begin
				LCD_E				<=	1'b0;						//Disable Bus, Triggers LCD to read BUS
				LCD_DB 			<= LCD_DB;					//Keep Data Valid
				if(!flag_42us) begin							//WAIT at least 42us (required for operation to process)
					STATE			<=	STATE;					//Maintain current STATE
					SUBSTATE		<=	SUBSTATE;				//Maintain current SUBSTATE
					flag_rst		<=	1'b0; 					//Start or Continue counting									
				end
				else begin 		
					STATE			<=	STATE+1;					//Go to next STATE
					SUBSTATE		<=	0;							//Reset SUBSTATE
					flag_rst		<=	1'b1; 					//Stop counting					
				end
			end
		end
		//---------------------------------------------------------------------------------------
		8: begin //-----------------DISPLAY, Display ON, Cursor ON, Blinking ON------------------
			LCD_RS				<=	1'b0;						//Indicate an instruction is to be sent soon
			LCD_RW				<=	1'b0;						//Indicate a write operation	
			RDY					<= 1'b0;						//Indicate that the module is busy
			if(SUBSTATE==0)begin	 		
				LCD_E				<=	1'b0;						//Disable Bus
				LCD_DB 			<=	LCD_DB;					//Maintain Previous Data on the Bus
				STATE				<=	STATE;				
				SUBSTATE			<=	1;
			end			
			if(SUBSTATE==1)begin				
				LCD_E				<=	1'b1;						//Enable Bus		
				LCD_DB 			<= DISP_ON;//ALL_ON;					//Data Valid
				if(!flag_250ns) begin						//WAIT at least 250ns (required for LCD_E)
					SUBSTATE		<=	SUBSTATE;				//Maintain current SUBSTATE
					flag_rst		<=	1'b0; 					//Start or Continue counting									
				end
				else begin 				
					SUBSTATE		<=	SUBSTATE+1;				//Go to next SUBSTATE
					flag_rst		<=	1'b1; 					//Stop counting					
				end
			end
			if(SUBSTATE==2)begin
				LCD_E				<=	1'b0;						//Disable Bus, Triggers LCD to read BUS
				LCD_DB 			<= LCD_DB;					//Keep Data Valid
				if(!flag_42us) begin							//WAIT at least 42us (required for operation to process)
					STATE			<=	STATE;					//Maintain current STATE
					SUBSTATE		<=	SUBSTATE;				//Maintain current SUBSTATE
					flag_rst		<=	1'b0; 					//Start or Continue counting									
				end
				else begin 		
					STATE			<=	STATE+1;					//Go to next STATE
					SUBSTATE		<=	0;							//Reset SUBSTATE
					flag_rst		<=	1'b1; 					//Stop counting					
				end
			end
		end
		//---------------------------------------------------------------------------------------
		9: begin //-------------------DISPLAY CLEAR, clear the display screen--------------------		
			LCD_RS				<=	1'b0;						//Indicate an instruction is to be sent soon
			LCD_RW				<=	1'b0;						//Indicate a write operation	
			RDY					<= 1'b0;						//Indicate that the module is busy
			if(SUBSTATE==0)begin	 		
				LCD_E				<=	1'b0;						//Disable Bus
				LCD_DB 			<=	LCD_DB;					//Maintain Previous Data on the Bus
				STATE				<=	STATE;				
				SUBSTATE			<=	1;
			end			
			if(SUBSTATE==1)begin				
				LCD_E				<=	1'b1;						//Enable Bus		
				LCD_DB 			<= CLEAR;					//Data Valid
				if(!flag_250ns) begin						//WAIT at least 250ns (required for LCD_E)
					SUBSTATE		<=	SUBSTATE;				//Maintain current SUBSTATE
					flag_rst		<=	1'b0; 					//Start or Continue counting									
				end
				else begin 				
					SUBSTATE		<=	SUBSTATE+1;				//Go to next SUBSTATE
					flag_rst		<=	1'b1; 					//Stop counting					
				end
			end
			if(SUBSTATE==2)begin
				LCD_E				<=	1'b0;						//Disable Bus, Triggers LCD to read BUS
				LCD_DB 			<= LCD_DB;					//Keep Data Valid
				if(!flag_1640us) begin						//WAIT at least 1640us (required for operation to process)
					STATE			<=	STATE;					//Maintain current STATE
					SUBSTATE		<=	SUBSTATE;				//Maintain current SUBSTATE
					flag_rst		<=	1'b0; 					//Start or Continue counting									
				end
				else begin 		
					STATE			<=	15;						//Go to next STATE
					SUBSTATE		<=	0;							//Reset SUBSTATE
					flag_rst		<=	1'b1; 					//Stop counting					
				end
			end
		end
		//---------------------------------------------------------------------------------------
		10: begin//----------------------------- WRITE DATA -------------------------------------
			LCD_RS				<=	1'b1;						//Indicate an instruction is to be sent soon
			LCD_RW				<=	1'b0;						//Indicate a write operation	
			RDY					<= 1'b0;						//Indicate that the module is busy
			if(SUBSTATE==0)begin	 		
				LCD_E				<=	1'b0;						//Disable Bus
				LCD_DB 			<=	LCD_DB;					//Maintain Previous Data on the Bus
				STATE				<=	STATE;				
				SUBSTATE			<=	1;
			end			
			if(SUBSTATE==1)begin				
				LCD_E				<=	1'b1;						//Enable Bus		
				LCD_DB 			<= DATA;						//WRITE THE CHARACTER
				if(!flag_250ns) begin						//WAIT at least 250ns (required for LCD_E)
					SUBSTATE		<=	SUBSTATE;				//Maintain current SUBSTATE
					flag_rst		<=	1'b0; 					//Start or Continue counting									
				end
				else begin 				
					SUBSTATE		<=	SUBSTATE+1;				//Go to next SUBSTATE
					flag_rst		<=	1'b1; 					//Stop counting					
				end
			end
			if(SUBSTATE==2)begin
				LCD_E				<=	1'b0;						//Disable Bus, Triggers LCD to read BUS
				LCD_DB 			<= LCD_DB;					//Keep Data Valid
				if(!flag_250ns) begin						//WAIT at least 250ns (required for LCD_E)
					STATE			<=	STATE;					//Maintain current STATE
					SUBSTATE		<=	SUBSTATE;				//Maintain current SUBSTATE
					flag_rst		<=	1'b0; 					//Start or Continue counting									
				end
				else begin 		
					STATE			<=	15;//STATE+1;			//Go to next STATE
					SUBSTATE		<=	0;							//Reset SUBSTATE
					flag_rst		<=	1'b1; 					//Stop counting					
				end
			end		
		end	
		//---------------------------------------------------------------------------------------
		11: begin//----------------------- WRITE INSTRUCTION ------------------------------------
			LCD_RS				<=	1'b0;						//Indicate an instruction is to be sent soon
			LCD_RW				<=	1'b0;						//Indicate a write operation	
			RDY					<= 1'b0;						//Indicate that the module is busy
			if(SUBSTATE==0)begin	 		
				LCD_E				<=	1'b0;						//Disable Bus
				LCD_DB 			<=	LCD_DB;					//Maintain Previous Data on the Bus
				STATE				<=	STATE;				
				SUBSTATE			<=	1;
			end			
			if(SUBSTATE==1)begin				
				LCD_E				<=	1'b1;						//Enable Bus		
				LCD_DB 			<= DATA;						//Data Valid
				if(!flag_250ns) begin						//WAIT at least 250ns (required for LCD_E)
					SUBSTATE		<=	SUBSTATE;				//Maintain current SUBSTATE
					flag_rst		<=	1'b0; 					//Start or Continue counting									
				end
				else begin 				
					SUBSTATE		<=	SUBSTATE+1;				//Go to next SUBSTATE
					flag_rst		<=	1'b1; 					//Stop counting					
				end
			end
			if(SUBSTATE==2)begin
				LCD_E				<=	1'b0;						//Disable Bus, Triggers LCD to read BUS
				LCD_DB 			<= LCD_DB;					//Keep Data Valid
				if(!flag_42us) begin							//WAIT at least 49us (required for operation to process)
					STATE			<=	STATE;					//Maintain current STATE
					SUBSTATE		<=	SUBSTATE;				//Maintain current SUBSTATE
					flag_rst		<=	1'b0; 					//Start or Continue counting									
				end
				else begin 		
					STATE			<=	15;//STATE+1;			//Go to next STATE
					SUBSTATE		<=	0;							//Reset SUBSTATE
					flag_rst		<=	1'b1; 					//Stop counting					
				end
			end
		end
		//---------------------------------------------------------------------------------------
		default: begin//----------This is the IDLE STATE, DO NOTHING UNTIL OPER is set-----------
			LCD_RS	<=		LCD_RS;								//Indicate an instruction is to be sent soon
			LCD_RW	<= 	1'b0;									//Indicate a write operation
			LCD_DB 	<= 	LCD_DB;								//Maintain Data Bus
			LCD_E		<=		1'b0;									//Disable Bus
			RDY		<=		1'b1;									//Indicate that the system is ready to taking in data
			if(ENB==1 && RST==0)begin
				case(OPER)
					0:STATE<=STATE; 	//IDLE
					1:STATE<=10;		//WRITE CHARACTER
					2:STATE<=11;		//WRITE INSTRUCTION (assumes 49us or less time to process instr)
					3:STATE<=0;			//RESET
				endcase
			end
			else if(RST==1)begin
				STATE<=0;
			end
		end
	endcase
end
endmodule