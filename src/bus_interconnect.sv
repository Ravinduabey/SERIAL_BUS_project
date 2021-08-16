module bus_interconnect (
    //arbiter
    input  [2:0] master, 
    input  [2:0] slave,

    //master1
    input       m1_valid, m1_last, m1_wD,
    output      m1_ready, m1_rD,
    //master2
    input       m2_valid, m2_last, m2_wD,
    output      m2_ready, m2_rD,

    //slave1
    output      s1_valid, s1_last, s1_wD,
    input       s1_ready, s1_rD,
    //slave2
    output      s2_valid, s2_last, s2_wD,
    input       s2_ready, s2_rD,
    //slave3
    output      s3_valid, s3_last, s3_wD,
    input       s3_ready, s3_rD
);

mux_2to3 valid (.master(master), .slave(slave), .master1(m1_valid), .master2(m2_valid), .slave1(s1_valid), .slave2(s2_valid), .slave3(s3_valid));
mux_2to3 last  (.master(master), .slave(slave), .master1(m1_last) , .master2(m2_last) , .slave1(s1_last) , .slave2(s2_last) , .slave3(s3_last));
mux_2to3 wD    (.master(master), .slave(slave), .master1(m1_wD)   , .master2(m2_wD)   , .slave1(s1_wD)   , .slave2(s2_wD)   , .slave3(s3_wD));
mux_2to3 control(.master(master), .slave(slave), .master1(control)   , .master2(control)   , .slave1(control)   , .slave2(control)   , .slave3(control));

mux_3to2 ready (.master(master), .slave(slave), .master1(m1_ready), .master2(m2_ready), .slave1(s1_ready), .slave2(s2_ready), .slave3(s3_ready));
mux_3to2 rD    (.master(master), .slave(slave), .master1(m1_rD)   , .master2(m2_rD)   , .slave1(s1_rD)   , .slave2(s2_rD)   , .slave3(s3_rD));


endmodule
    