module bus_mux_StoM #(
    parameter NO_MASTERS = 2,
    parameter NO_SLAVES = 3,
    parameter S_ID_WIDTH = $clog2(NO_SLAVES+1), //2
    parameter M_ID_WIDTH = $clog2(NO_MASTERS) //1
)(
    
    input   logic [M_ID_WIDTH-1:0] master_sel,
    input   logic [S_ID_WIDTH-1:0] slave_sel,  
    output  logic [NO_MASTERS-1:0] master,    
    input   logic [NO_SLAVES-1 :0] slave
);

    // logic [M_ID_WIDTH-1:0] m_sel = master_sel;
    // logic [S_ID_WIDTH-1:0] s_sel = slave_sel; 

    // always_latch begin : assign_stom
    //     master[m_sel] = slave[s_sel];
    // end

    // assign master[m_sel] = slave[s_sel];
    
    
endmodule