module lcd_display(

input logic CLK;			// For this code to work without modification, CLK should equal 24MHz
input logic [7:0]DATA;			// The Data to send to the LCD Module
input logic [1:0]OPER;			// The Type of operation to perform (data or instruction) 
input logic ENB;			// Tells the module that the data is valid and start reading DATA and OPER
input logic RST;

output logic RDY;			// Indicates that the module is Idle and ready to take more data
output logic LCD_RS, LCD_RW, LCD_E;     
output logic [7:0] LCD_DB;  
);

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
localparam [19:0] t_40ns 	= 1;		//40ns 		== ~1clk
localparam [19:0] t_250ns 	= 6;		//250ns 	== ~6clks
localparam [19:0] t_42us 	= 1008;		//42us 		== ~1008clks
localparam [19:0] t_100us 	= 2400;		//100us		== ~2400clks
localparam [19:0] t_1640us 	= 39360;	//1.64ms 	== ~39360clks
localparam [19:0] t_4100us 	= 98400;	//4.1ms    	== ~98400clks
localparam [19:0] t_15000us	= 360000;	//15ms 		== ~360000clks

//===============================================================================================
//------------------------------Define the BASIC Command Set-------------------------------------
//===============================================================================================
localparam [7:0] SETUP		= 8'b00111000;	//Execution time = 42us, sets to 8-bit interface, 2-line display, 5x7 dots
localparam [7:0] DISP_ON		= 8'b00001100;	//Execution time = 42us, Turn ON Display
localparam [7:0] ALL_ON		= 8'b00001111;	//Execution time = 42us, Turn ON All Display
localparam [7:0] ALL_OFF		= 8'b00001000;	//Execution time = 42us, Turn OFF All Display
localparam [7:0] CLEAR 		= 8'b00000001; 	//Execution time = 1.64ms, Clear Display
localparam [7:0] ENTRY_N		= 8'b00000110;	//Execution time = 42us, Normal Entry, Cursor increments, Display is not shifted
localparam [7:0] HOME 		= 8'b00000010; 	//Execution time = 1.64ms, Return Home
localparam [7:0] C_SHIFT_L 	= 8'b00010000; 	//Execution time = 42us, Cursor Shift
localparam [7:0] C_SHIFT_R 	= 8'b00010100; 	//Execution time = 42us, Cursor Shift
localparam [7:0] D_SHIFT_L 	= 8'b00011000; 	//Execution time = 42us, Display Shift
localparam [7:0] D_SHIFT_R 	= 8'b00011100; 	//Execution time = 42us, Display Shift


endmodule: lcd_display