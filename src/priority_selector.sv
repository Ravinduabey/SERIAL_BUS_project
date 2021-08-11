module priority_selector #(
    parameter NO_MASTERS = 3,
    parameter NO_SLAVES = 5,
    parameter S_ID_WIDTH = $clog2(NO_SLAVES+1),
    parameter M_ID_WIDTH = $clog2(NO_MASTERS)
) (
    input logic [S_ID_WIDTH-1:0] slave_id [NO_MASTERS-1:0], //width //array size
    input clk,
    input rstN,
    output logic [M_ID_WIDTH-1:0] master,
    output logic [S_ID_WIDTH-1:0] slave
);
// 00 01 10 11 10 

logic [M_ID_WIDTH-1:0] cur_master, next_master;
logic [S_ID_WIDTH-1:0] cur_slave, next_slave;

always_ff @(posedge clk or negedge rstN ) begin
    if (!rstN) begin
        cur_master <= '0; 
        cur_slave <= '0;
    end
    else begin 
        cur_slave <= next_slave;
        cur_master <= next_master;  
    end  
end

always_comb begin 
    next_master = cur_master;
    next_slave = cur_slave;
    for (int i = 0; i<NO_MASTERS ; i=i+1) begin
        if (slave_id[i] != '0) begin
            next_master = M_ID_WIDTH'(i);
            next_slave = slave_id[i];
            break;
        end
    end
end  

assign master = cur_master;
assign slave = cur_slave;
endmodule