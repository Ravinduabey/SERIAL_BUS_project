module bus_mux_StoM_tb ();
    logic clk;
    localparam CLOCK_PERIOD = 20;
    initial begin
        clk <= 0;
            forever begin
                #(CLOCK_PERIOD/2) clk <= ~clk;
            end
    end

    // localparam NO_MASTERS = 2'd3;
    // localparam NO_SLAVES = 3'd5;
    logic [2:0]master_sel = 2'b01;
    logic [3:0]slave_sel = 3'b010;
    logic rD_M = '0;
    logic rD_S = '0;

    initial begin
        @(posedge clk);
        rD_S <= 1;
        #(CLOCK_PERIOD*3);
        rD_S <= 0;

    end

    bus_mux_StoM #(
        .NO_MASTERS(3),
        .NO_SLAVES(5)
    ) rD_mux (
        .master_sel(master_sel),
        .slave_sel(slave_sel),
        .master(rD_M),
        .slave(rD_S)
    );
    
endmodule