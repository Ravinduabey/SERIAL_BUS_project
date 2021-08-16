module bus_mux_MtoS #(
    parameter NO_MASTERS = 2,
    parameter NO_SLAVES = 3,
    parameter S_ID_WIDTH = $clog2(NO_SLAVES+1), //2
    parameter M_ID_WIDTH = $clog2(NO_MASTERS) //1
)(
    
    input   logic [M_ID_WIDTH-1:0] master_sel,      //1'b0
    input   logic [S_ID_WIDTH-1:0] slave_sel,       //2'b01
    input   logic [NO_MASTERS-1:0] master,          //
    output  logic [NO_SLAVES-1 :0] slave
);

    // logic [M_ID_WIDTH-1:0] m_sel = master_sel;
    // logic [S_ID_WIDTH-1:0] s_sel = slave_sel; 

    always_comb begin : assign_mtos
        slave[slave_sel] = master[master_sel];
    end
    // assign slave[s_sel] = master[m_sel];
    
endmodule