/*
      this module will write the master according to the protocol designed. 
*/
module a_write_buffer #(
    WIDTH = 3
)(
    input  logic [WIDTH-1:0] din,
    input  logic clk,rstN,
    input  logic load,
    output logic dout
    );

   //counter is used to stop the buffer shifting and maintain the master write value
    localparam COUNT = 2;
    
    logic [WIDTH-1:0] buffer;
    logic [$clog2(WIDTH)-1:0] counter = '0;

    assign dout = buffer[0];

    always_ff @ (posedge clk or negedge rstN) begin
       if (!rstN) begin
          buffer <= '0;
          counter <= '0;          
       end
       else begin
         if (load) begin
            buffer <= din;
            counter <= '0;
         end
         else if (counter< COUNT) begin
            buffer <= buffer >> 1;
            counter <= counter + 1'b1;
         end
       end
    end

endmodule