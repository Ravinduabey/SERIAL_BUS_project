module interconnect #(
)(
    input [2:0] master, 
    input [2:0] slave,

    input       m1_valid, m1_last, m1_wD,
    output      m1_ready, m1_rD,
    input       m2_valid, m2_last, m2_wD,
    output      m2_ready, m2_rD,

    output      s1_valid, s1_last, s1_wD,
    input       s1_ready, s1_rD,
    output      s2_valid, s2_last, s2_wD,
    input       s2_ready, s2_rD,
    output      s3_valid, s3_last, s3_wD,
    input       s3_ready, s3_rD
);
    always @(*) begin
        case (master)
            2'b01 : begin
                case (slave)
                    2'b01 : begin
                        s1_valid    <= m1_valid;
                        s1_last     <= m1_last;
                        s1_wD       <= m1_wD;
                        m1_rD       <= s1_rD;
                        m1_ready    <= s1_ready;
                    end
                    2'b10 : begin
                        s2_valid    <= m1_valid;
                        s2_last     <= m1_last;
                        s2_wD       <= m1_wD;
                        m1_rD       <= s2_rD;
                        m1_ready    <= s2_ready;
                    end
                    2'b11 : begin
                        s3_valid    <= m1_valid;
                        s3_last     <= m1_last;
                        s3_wD       <= m1_wD;
                        m1_rD       <= s3_rD;
                        m1_ready    <= s3_ready;
                    end
            end
            2'b10 : begin
                2'b01 : begin
                        s1_valid    <= m2_valid;
                        s1_last     <= m2_last;
                        s1_wD       <= m2_wD;
                        m2_rD       <= s1_rD;
                        m2_ready    <= s1_ready;
                    end
                2'b10 : begin
                        s2_valid    <= m2_valid;
                        s2_last     <= m2_last;
                        s2_wD       <= m2_wD;
                        m2_rD       <= s2_rD;
                        m2_ready    <= s2_ready;
                    end
                2'b11 : begin
                        s3_valid    <= m2_valid;
                        s3_last     <= m2_last;
                        s3_wD       <= m2_wD;
                        m2_rD       <= s3_rD;
                        m2_ready    <= s3_ready;
                    end
            end 
            default: 
        endcase
    end
    
endmodule