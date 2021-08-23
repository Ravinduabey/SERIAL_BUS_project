module uart_transmitter 
#(
    parameter DATA_WIDTH = 8
)
(
    input logic [DATA_WIDTH-1:0]dataIn,
    input logic clk, baudTick, rstN, txStart,
    output logic tx,tx_ready
);

typedef enum logic [1:0]{
    idle = 2'd0,
    start = 2'd1,
    data_transmit = 2'd2,
    stop = 2'd3
} state_t;

localparam COUNTER_WIDTH = $clog2(DATA_WIDTH);

state_t currentState, nextState;
logic [DATA_WIDTH-1:0]currentData, nextData;
logic currentBit, nextBit;
logic [COUNTER_WIDTH-1:0]currentCount, nextCount;
logic [3:0]currentTick, nextTick;


always_ff @(posedge clk) begin
    if (~rstN) begin
        currentTick <= 4'b0;
        currentCount <= '0;
        currentState <= idle;
        currentData <= '0;
        currentBit <= 1'b1;
    end
    else begin
        currentTick <= nextTick;
        currentCount <= nextCount;
        currentState <= nextState;
        currentData <= nextData;
        currentBit <= nextBit;
    end    
end

always_comb begin
    nextState = currentState;
    nextTick = currentTick;
    nextCount = currentCount;
    nextData = currentData;
    nextBit = currentBit;

    case (currentState) 
        idle: begin
            if (txStart) begin
                nextTick = 4'd0;
                nextBit = 1'b0;   //start of the data byte
                nextData = dataIn;
                nextState = start;
            end
            else
                nextBit = 1'b1;
        end

        start: begin
            if (baudTick) begin
                nextTick = currentTick + 4'b1;
                if (currentTick == 4'd15) begin
                    nextCount = '0;
                    nextBit = currentData[0];
                    nextState = data_transmit;
                end
            end
        end

        data_transmit: begin
            nextBit = currentData[0];
            if (baudTick) begin
                nextTick = currentTick + 4'b1;
                if (currentTick == 4'd15) begin
                    nextCount = currentCount + COUNTER_WIDTH'(1'b1);
                    nextData = currentData >>1;   
                    if (currentCount == (DATA_WIDTH-1)) begin
                        nextBit = 1'b1;
                        nextState = stop;
                    end
                end
            end
        end

        stop: begin
            if (baudTick) begin
                nextTick = currentTick + 4'b1;
                if (currentTick == 4'd15)
                    nextState = idle;
            end
        end
                
    endcase
end

assign tx = currentBit;
assign  tx_ready = (currentState == idle)? 1'b1:1'b0;

endmodule //uart_transmitter