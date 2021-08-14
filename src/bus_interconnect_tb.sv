module bus_interconnect_tb ();
    logic [2:0] master;
    logic [2:0] slave;

    logic   m1_valid, m1_last, m1_wD;
    logic   m1_ready, m1_rD;
    logic   m2_valid, m2_last, m2_wD;
    logic   m2_ready, m2_rD;

    logic   s1_valid, s1_last, s1_wD;
    logic   s1_ready, s1_rD;
    logic   s2_valid, s2_last, s2_wD;
    logic   s2_ready, s2_rD;
    logic   s3_valid, s3_last, s3_wD;
    logic   s3_ready, s3_rD;

    bus_interconnect dut (
        master, slave, 
        m1_valid, m1_last, m1_wD,
        m1_ready, m1_rD;
        m2_valid, m2_last, m2_wD;
        m2_ready, m2_rD;

        s1_valid, s1_last, s1_wD;
        s1_ready, s1_rD;
        s2_valid, s2_last, s2_wD;
        s2_ready, s2_rD;
        s3_valid, s3_last, s3_wD;
        s3_ready, s3_rD;
    );

    initial begin
        master <= 2'b01;
        slave  <= 2'b10;
        m1_valid <= 1;
        m1_last <= 0;
        m1_control <= 1;
        master <= 2'b10;

    end

endmodule