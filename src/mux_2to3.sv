module mux_2to3 (
    input [2:0] master, slave,
    input master1, master2,
    output logic slave1, slave2, slave3
);

    always_latch begin : decoder
        case (master)
            2'b01: begin
                case (slave)
                    2'b01 : slave1 <= master1;
                    2'b10 : slave2 <= master1;
                    2'b11 : slave3 <= master1;
                    default: slave1 <= master1;
                endcase
            end
            2'b10 : begin
                case (slave)
                    2'b01 : slave1 <= master2;
                    2'b10 : slave2 <= master2;
                    2'b11 : slave3 <= master2;
                    default: slave1 <= master2;
                endcase     
            end
            default: slave1 <= master1;
        endcase 
    end
    
endmodule