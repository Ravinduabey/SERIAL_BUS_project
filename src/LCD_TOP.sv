module	LCD_TOP import  details::charactor_t;
(//	Host Side
input logic clk, rstN,new_data,
input charactor_t line_1[0:15],
input charactor_t line_2[0:15],
output logic ready,
//	LCD Side
output logic [7:0]LCD_DATA,
output logic LCD_RW,LCD_EN,LCD_RS,LCD_BLON,LCD_ON
);

assign LCD_ON = 1'b1;
assign LCD_BLON = 1'b1;

logic [5:0]	LUT_INDEX, LUT_INDEX_next;
logic [8:0]	LUT_DATA;
logic [17:0]mDLY, mDLY_next;
logic 		mLCD_Start, mLCD_Start_next;
logic [7:0]	mLCD_DATA, mLCD_DATA_next;
logic 		mLCD_RS, mLCD_RS_next;
logic 		mLCD_Done;

localparam	LCD_INTIAL	=	0;
localparam	LCD_LINE1	=	5;
localparam	LCD_CH_LINE	=	LCD_LINE1+16;
localparam	LCD_LINE2	=	LCD_LINE1+16+1;
localparam	LUT_SIZE	=	LCD_LINE1+32+1;

typedef enum logic [3:0]{
	ready_state = 4'd0,
	sending_charactor = 4'd1,
	delay_state = 4'd2,
	finish_state = 4'd3,
	start_next_charactor = 4'd4

} state_t;

state_t	mLCD_ST, mLCD_ST_next;

always_ff @(posedge clk) begin
	if (!rstN) begin
		mLCD_ST <= ready_state;
		LUT_INDEX <= '0;
		mDLY <= '0;
		mLCD_DATA <= '0;
		mLCD_RS <= '0;
		mLCD_Start <= '0;
	end
	else begin
		mLCD_ST <= mLCD_ST_next;
		LUT_INDEX <= LUT_INDEX_next;
		mDLY <= mDLY_next;
		mLCD_DATA <= mLCD_DATA_next;
		mLCD_RS <= mLCD_RS_next;
		mLCD_Start <= mLCD_Start_next;
	end
end

always_comb begin
	mLCD_ST_next = mLCD_ST;
	LUT_INDEX_next = LUT_INDEX;
	mDLY_next = mDLY;
	mLCD_DATA_next = mLCD_DATA;
	mLCD_RS_next = mLCD_RS;
	mLCD_Start_next = mLCD_Start;

	case (mLCD_ST)
		ready_state: begin
			mLCD_Start_next = 1'b0;
			if (new_data) begin
				mLCD_ST_next = sending_charactor;
				mLCD_Start_next = 1'b1;
				mLCD_DATA_next	=	LUT_DATA[7:0];
				mLCD_RS_next	=	LUT_DATA[8];
			end
		end

		sending_charactor: begin
			if(mLCD_Done) begin
				mLCD_Start_next	=	1'b0;
				mLCD_ST_next	=	delay_state;
				mDLY_next = '0;					
			end
		end

		delay_state: begin
			mDLY_next = mDLY + 1'b1;
			if (mDLY > 18'h3FFFE) begin
				mDLY_next	 =	'0;
				mLCD_ST_next =	finish_state;
				LUT_INDEX_next = LUT_INDEX + 1'b1;
			end
		end

		finish_state: begin
			if (LUT_INDEX < LUT_SIZE) begin
				mLCD_ST_next = start_next_charactor;
				
			end
			else begin
				LUT_INDEX_next = '0;
				mLCD_ST_next = ready_state;
			end
		end

		start_next_charactor: begin
			mLCD_DATA_next	=	LUT_DATA[7:0];
			mLCD_RS_next	=	LUT_DATA[8];
			mLCD_Start_next	=	1'b1;
			mLCD_ST_next 	=	sending_charactor;
		end

	endcase
end

assign ready = (mLCD_ST == ready_state);

always_ff @(posedge clk)begin
	case(LUT_INDEX)
	//	Initial
	LCD_INTIAL+0:	LUT_DATA	<=	9'h038;
	LCD_INTIAL+1:	LUT_DATA	<=	9'h00C;
	LCD_INTIAL+2:	LUT_DATA	<=	9'h001;
	LCD_INTIAL+3:	LUT_DATA	<=	9'h006;
	LCD_INTIAL+4:	LUT_DATA	<=	9'h080;
	//	Line 1
	LCD_LINE1+0:	LUT_DATA	<=	{1'b1,line_1[0]};	//	Welcome to the
	LCD_LINE1+1:	LUT_DATA	<=	{1'b1,line_1[1]};
	LCD_LINE1+2:	LUT_DATA	<=	{1'b1,line_1[2]};
	LCD_LINE1+3:	LUT_DATA	<=	{1'b1,line_1[3]};
	LCD_LINE1+4:	LUT_DATA	<=	{1'b1,line_1[4]};
	LCD_LINE1+5:	LUT_DATA	<=	{1'b1,line_1[5]};
	LCD_LINE1+6:	LUT_DATA	<=	{1'b1,line_1[6]};
	LCD_LINE1+7:	LUT_DATA	<=	{1'b1,line_1[7]};
	LCD_LINE1+8:	LUT_DATA	<=	{1'b1,line_1[8]};
	LCD_LINE1+9:	LUT_DATA	<=	{1'b1,line_1[9]};
	LCD_LINE1+10:	LUT_DATA	<=	{1'b1,line_1[10]};
	LCD_LINE1+11:	LUT_DATA	<=	{1'b1,line_1[11]};
	LCD_LINE1+12:	LUT_DATA	<=	{1'b1,line_1[12]};
	LCD_LINE1+13:	LUT_DATA	<=	{1'b1,line_1[13]};
	LCD_LINE1+14:	LUT_DATA	<=	{1'b1,line_1[14]};
	LCD_LINE1+15:	LUT_DATA	<=	{1'b1,line_1[15]};
	//	Change Line
	LCD_CH_LINE:	LUT_DATA	<=	9'h0C0;
	//	Line 2
	LCD_LINE2+0:	LUT_DATA	<=	{1'b1,line_2[0]};	//	Altera DE2-70
	LCD_LINE2+1:	LUT_DATA	<=	{1'b1,line_2[1]};	
	LCD_LINE2+2:	LUT_DATA	<=	{1'b1,line_2[2]};
	LCD_LINE2+3:	LUT_DATA	<=	{1'b1,line_2[3]};
	LCD_LINE2+4:	LUT_DATA	<=	{1'b1,line_2[4]};
	LCD_LINE2+5:	LUT_DATA	<=	{1'b1,line_2[5]};
	LCD_LINE2+6:	LUT_DATA	<=	{1'b1,line_2[6]};
	LCD_LINE2+7:	LUT_DATA	<=	{1'b1,line_2[7]};
	LCD_LINE2+8:	LUT_DATA	<=	{1'b1,line_2[8]};
	LCD_LINE2+9:	LUT_DATA	<=	{1'b1,line_2[9]};
	LCD_LINE2+10:	LUT_DATA	<=	{1'b1,line_2[10]};
	LCD_LINE2+11:	LUT_DATA	<=	{1'b1,line_2[11]};
	LCD_LINE2+12:	LUT_DATA	<=	{1'b1,line_2[12]};
	LCD_LINE2+13:	LUT_DATA	<=	{1'b1,line_2[13]};
	LCD_LINE2+14:	LUT_DATA	<=	{1'b1,line_2[14]};
	LCD_LINE2+15:	LUT_DATA	<=	{1'b1,line_2[15]};
	default:		LUT_DATA	<=	{1'b1,line_2[0]};
	endcase
end


LCD_Controller 		u0	(	//	Host Side
						.iDATA(mLCD_DATA),
						.iRS(mLCD_RS),
						.iStart(mLCD_Start),
						.oDone(mLCD_Done),
						.clk(clk),
						.rstN(rstN),
						//	LCD Interface
						.LCD_DATA(LCD_DATA),
						.LCD_RW(LCD_RW),
						.LCD_EN(LCD_EN),
						.LCD_RS(LCD_RS)	
						);


endmodule:LCD_TOP