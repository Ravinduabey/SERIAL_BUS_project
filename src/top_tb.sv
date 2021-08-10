module top_tb();

timeunit 1ns;
timeprecision 1ns;

localparam CLK_PERIOD = 20;

logic clk;
initial begin
    clk = 1'b0;
    forever begin
        #(CLK_PERIOD/2);
        clk = ~clk;
    end
end

logic CLOCK_50;
logic [3:0]KEY;
logic [17:0]SW;
logic [17:0]LEDR;
logic [6:0]HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, HEX6, HEX7;

assign CLOCK_50 = clk;

top dut(.*);  // instantiate the top module



task automatic master_slave_select(logic [1:0]M1_slave, M2_slave); 

endtask

task automatic master_read_write_select(logic M1_RW, M2_RW);

endtask

task automatic external_write_select (logic M1_external_write, M2_external_write);

endtask

task automatic master_external_write(logic master, int ADDRESS_COUNT);

endtask

task automatic get_slave_address(logic master, logic [MASTER_ADDR_WIDTH-1:0]address);

endtask

task automatic configure_masters();

endtask

task automatic start_communication();

endtask

task automatic get_data_from_masters(int address);

endtask


endmodule : top_tb