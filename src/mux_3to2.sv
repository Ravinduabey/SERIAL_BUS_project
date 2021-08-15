module mux_3to2 (
    input  [2:0] master, slave,
    input  slave1, slave2, slave3,
    output logic master1, master2

);

always_latch begin : decoder
    case (master)
        2'b01: begin
            case (slave)
                2'b01 : master1  <= slave1;
                2'b10 : master1  <= slave2;
                2'b11 : master1  <= slave3;
                default: master1 <= slave1;
            endcase
        end
        2'b10 : begin
            case (slave)
                2'b01 : master2  <= slave1;
                2'b10 : master2  <= slave2;
                2'b11 : master2  <= slave3;
                default: master2 <= slave1;
            endcase     
        end
        default: master1 <= slave1;
    endcase
end 
    
    
endmodule