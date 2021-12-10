package a_definitions;

typedef enum logic [1:0] { 
    WAIT = 2'b00,
    STOP_S,
    STOP_P,
    CLEAR
} ctrl_cmd_t;


typedef enum logic [1:0] {
    END_COM = 2'b00,
    NAK = 2'b01,
    WAIT_ACK = 2'b10,
    COM_ = 2'b11
} mst_cmd_t;

    
endpackage

