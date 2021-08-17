module bus_mux_StoM #(
    parameter NO_MASTERS=7,
    parameter NO_SLAVES=10,
    parameter S_ID_WIDTH = $clog2(NO_SLAVES+1), //2
    parameter M_ID_WIDTH = $clog2(NO_MASTERS) //1
)(
    
    input   logic [M_ID_WIDTH-1:0] master_sel,
    input   logic [S_ID_WIDTH-1:0] slave_sel,  
    output  logic [NO_MASTERS-1:0] master,    
    input   logic [NO_SLAVES-1 :0] slave
    );

logic mux_out;
logic mux_in;

//    int i;
//   int j;
    always_latch begin : blockName
        // for (int i=0,j=0; i < NO_MASTERS, j < NO_SLAVES; i++, j++) begin
            for (int i = 0; i <NO_SLAVES; i++) begin
                if (i===slave_sel) begin
                    mux_in <= slave[i-1];
                end 
                $display(i, slave_sel); 
                $display(slave);
            end

            for (int j=0 ; j < NO_MASTERS; j++) begin
                if (j===master_sel) begin
                    master[j-1] <= mux_out;
                end
                $display(j, master_sel); 
                $display(master);
            end
    end

assign mux_out = mux_in;
    	  
endmodule


// genvar i;
// genvar j;
//     generate
//         for (i=0,j=0; i < NO_MASTERS, j < NO_SLAVES; i++, j++) begin
// 			if (i==master_sel && j==slave_sel) begin
// //            for (j=0 ; j < NO_SLAVES; j++) begin
//                 // assign master[i] = {(master_sel == i), (slave_sel == j)}? slave[j] : 0;
// //                    if (j==slave_sel) begin
//                         master[i] <= slave[j];
// //							end
// //                end
//             end
//         end
//     endgenerate

//     assign sla = temp[0] | temp[1] | temp[2] | temp[3] |
//                      temp[4] | temp[5] | temp[6] | temp[7] |
//                      temp[8] | temp[9] | temp[10] | temp[11] |
//                      temp[12] | temp[13] | temp[14] | temp[15];

    // logic [M_ID_WIDTH-1:0] m_sel = master_sel;
    // logic [S_ID_WIDTH-1:0] s_sel = slave_sel; 

    // always_latch begin : assign_stom
    //     master[m_sel] = slave[s_sel];
    // end

    // assign master[m_sel] = slave[s_sel];

    
