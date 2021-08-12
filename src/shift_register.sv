module shift_register(
    input  logic [7:0]  din,
    input  logic        clk,reset_n,
    input  logic        load,
    output logic        dout
    );
    
    logic [15:0] temp;
    
    always_ff @ (posedge clk or negedge reset_n) begin
       if (!reset_n)
          temp <= 8'h0000;
       else begin
         if (load) begin
            temp <= din;
         end
         else begin
            dout <= temp[7];
            temp <= {temp[6:0],1'b0};
         end
       end
    end

endmodule
