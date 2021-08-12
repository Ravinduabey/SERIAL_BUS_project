module priority_selector #(
    parameter NO_MASTERS = 3,
    parameter NO_SLAVES = 5,
    parameter S_ID_WIDTH = $clog2(NO_SLAVES+1),
    parameter M_ID_WIDTH = $clog2(NO_MASTERS)
) (
    
    // input clk,
    // input rstN,
    input [1:0] state,
    input logic [M_ID_WIDTH-1:0] master_in,
    input logic [S_ID_WIDTH-1:0] slave_in,
    // input logic [M_ID_WIDTH-1:0] cur_master,
    // input logic [S_ID_WIDTH-1:0] cur_slave,

    input logic [S_ID_WIDTH-1:0] slave_id [NO_MASTERS-1:0],

    output logic [M_ID_WIDTH-1:0] master_out,
    output logic [S_ID_WIDTH-1:0] slave_out,
    output logic request
);

// logic [M_ID_WIDTH-1:0] cur_master, next_master;
// logic [S_ID_WIDTH-1:0] cur_slave, next_slave;
int i, j;
// always_ff @(posedge clk or negedge rstN ) begin
//     $display("master %b slave %b", master_out, slave_out);
//     if (!rstN) begin
//         cur_master <= '0; 
//         cur_slave <= '0;
//     end
//     else begin 
//         cur_slave <= next_slave;
//         cur_master <= next_master;  
//     end  
// end
always_comb begin 
	 request = 0;
    for (j = 0; j<NO_MASTERS; j++) begin
        if (slave_id[j] != '0) begin
            request = 1;
            break;
        end
    end
end

always_comb begin
    master_out = master_in;
    slave_out = slave_in;

    unique case (state)

    2'b00 : begin
    for (i = 0; i<NO_MASTERS; i++) begin
        if (slave_id[i] != '0) begin
            master_out = M_ID_WIDTH'(i);
            slave_out = slave_id[i];
            break;
        end
    end
    end

    2'b01 : begin
    for (i = 0; i<NO_MASTERS; i++) begin
        if ((slave_id[i] != '0) && (slave_id[i] != slave_in) ) begin
            master_out = M_ID_WIDTH'(i);
            slave_out = slave_id[i];
            break;
        end
    end 
    end

    2'b10 : begin
    for (i = 0; i<NO_MASTERS; i++) begin
        if ((slave_id[i] != '0) && (i < master_in) ) begin
            master_out = M_ID_WIDTH'(i);
            slave_out = slave_id[i];
            break;
        end
    end
    end
endcase
end  

// assign master_out = master_out;
// assign slave_out = slave_out;
endmodule