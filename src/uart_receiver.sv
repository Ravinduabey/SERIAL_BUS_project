module uart_receiver 
#(
    parameter DATA_WIDTH = 8
)
(
    input  logic rx, clk, rstN, baudTick,
    output logic rx_ready, 
    output logic [DATA_WIDTH-1:0]dataOut,
    output logic new_byte_indicate
);

typedef enum logic [1:0]{
    idle = 2'd0,
    start = 2'd1,
    data_receive = 2'd2,
    stop = 2'd3
} state_t;

localparam COUNTER_WIDTH = $clog2(DATA_WIDTH);

state_t currentState, nextState;
logic [COUNTER_WIDTH-1:0]currentCount,nextCount;
logic [DATA_WIDTH-1:0]currentData, nextData;
logic [3:0]currentTick, nextTick;

always_ff @(posedge clk) begin
    if(~rstN) begin
        currentState <= idle;
        currentCount <= '0;
        currentTick <= 4'b0;
        currentData <= '0;
    end
    else begin
        currentState <= nextState;
        currentCount <= nextCount;
        currentTick <= nextTick;
        currentData <= nextData;
    end
end

always_comb begin
    nextState = currentState;
    nextCount = currentCount;
    nextTick = currentTick;
    nextData = currentData;

    case (currentState )
        idle: begin
            nextTick = 4'b0;
            nextCount = '0;
            if (rx == 1'b0) begin
                nextState = start;
            end
        end

        start: begin
           if (baudTick) begin
               nextTick = currentTick + 4'b1;
               if (currentTick == 4'd7) begin
                   if (~rx) begin
                        nextState = data_receive;
                        nextCount = '0;
                        nextTick = 4'b0;
                        nextData = '0;
                   end
                   else begin
                       nextState = idle;
                   end                   
               end
           end 
        end

        data_receive: begin
            if (baudTick) begin
                nextTick = currentTick + 4'b1;
                if (currentTick == 4'd15) begin
                    nextData = {rx,currentData[DATA_WIDTH-1:1]};
                    nextCount = currentCount + COUNTER_WIDTH'(1'b1);
                    if (currentCount == (DATA_WIDTH-1)) begin
                        nextState = stop;
                    end
                end
            end
        end

        stop: begin
            if (baudTick) begin
                nextTick = currentTick + 4'b1;
                if (currentTick == 4'd15) begin
                    nextState = idle;
                end
            end
        end

    endcase
end

assign dataOut = currentData;
assign rx_ready = (currentState == idle)? 1'b1: 1'b0;
assign new_byte_indicate = ((currentState == start) && (baudTick) && (currentTick == 4'd7) && (~rx))? 1'b1:1'b0; //start of new data_receive byte

endmodule //uart_receiver