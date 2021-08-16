/*
    this module will lookout for any master requests. Depending on the state, controller gets to know for whom the bus should be allocated next. 
*/
module a_priority_selector #(
    parameter NO_MASTERS = 2,
    parameter NO_SLAVES = 3,
    parameter S_ID_WIDTH = $clog2(NO_SLAVES+1),
    parameter M_ID_WIDTH = $clog2(NO_MASTERS)
) (
    
    input logic state,
    input logic [M_ID_WIDTH-1:0] master_in,
    input logic [S_ID_WIDTH-1:0] slave_in,
    input logic thresh,
    input logic [S_ID_WIDTH-1:0] slave_id [0:NO_MASTERS-1],

    output logic [M_ID_WIDTH-1:0] master_out,
    output logic [S_ID_WIDTH-1:0] slave_out,
    output logic request
);

int i, j;

//check if there is any requests
always_comb begin : requestChecker
	request = 0;
    for (j = 0; j<NO_MASTERS; j++) begin
        if (slave_id[j] != '0) begin
            request = 1;
            break;
        end
    end
end

always_comb begin : masterSlaveSelector
    master_out = master_in;
    slave_out = slave_in;

    unique case (state)

    1'b0 : begin
        //select the top priority master to start the communication
        for (i = 0; i<NO_MASTERS; i++) begin
            if (slave_id[i] != '0) begin
                master_out = M_ID_WIDTH'(i);
                slave_out = slave_id[i];
                break;
            end
        end
    end

    1'b1 : begin
        //split transaction
        if (thresh) begin 
        //select the top priority master when requested slaves are not equal
            for (i = 0; i<NO_MASTERS; i++) begin
                if ((slave_id[i] != '0) && (slave_id[i] != slave_in) ) begin
                    master_out = M_ID_WIDTH'(i);
                    slave_out = slave_id[i];
                    break;
                end
            end 
        end
        //priority transaction
        else begin 
            //select the top priority master higher than current master
            for (i = 0; i<NO_MASTERS; i++) begin
                if ((slave_id[i] != '0) && (i < master_in) ) begin
                    master_out = M_ID_WIDTH'(i);
                    slave_out = slave_id[i];
                    break;
                end
            end            
        end

    end
endcase
end  
endmodule : a_priority_selector