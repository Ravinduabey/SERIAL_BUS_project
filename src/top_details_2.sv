package top_details;

typedef enum logic[7:0]{
    // numbers
    num_0  = {4'b0011,4'd0},
    num_1  = {4'b0011,4'd1},
    num_2  = {4'b0011,4'd2},
    num_3  = {4'b0011,4'd3},
    num_4  = {4'b0011,4'd4},
    num_5  = {4'b0011,4'd5},
    num_6  = {4'b0011,4'd6},
    num_7  = {4'b0011,4'd7},
    num_8  = {4'b0011,4'd8},
    num_9  = {4'b0011,4'd9},

    // capital letters
    A = {4'b0100,4'd1},
    B = {4'b0100,4'd2},
    C = {4'b0100,4'd3},
    D = {4'b0100,4'd4},
    E = {4'b0100,4'd5},
    F = {4'b0100,4'd6},
    G = {4'b0100,4'd7},
    H = {4'b0100,4'd8},
    I = {4'b0100,4'd9},
    J = {4'b0100,4'd10},
    K = {4'b0100,4'd11},
    L = {4'b0100,4'd12},
    M = {4'b0100,4'd13},
    N = {4'b0100,4'd14},
    O = {4'b0100,4'd15},
    P = {4'b0101,4'd0},
    Q = {4'b0101,4'd1},
    R = {4'b0101,4'd2},
    S = {4'b0101,4'd3},
    T = {4'b0101,4'd4},
    U = {4'b0101,4'd5},
    V = {4'b0101,4'd6},
    W = {4'b0101,4'd7},
    X = {4'b0101,4'd8},
    Y = {4'b0101,4'd9},
    Z = {4'b0101,4'd10},

    // simple letters
    a = {4'b0110,4'd1},
    b = {4'b0110,4'd2},
    c = {4'b0110,4'd3},
    d = {4'b0110,4'd4},
    e = {4'b0110,4'd5},
    f = {4'b0110,4'd6},
    g = {4'b0110,4'd7},
    h = {4'b0110,4'd8},
    i = {4'b0110,4'd9},
    j = {4'b0110,4'd10},
    k = {4'b0110,4'd11},
    l = {4'b0110,4'd12},
    m = {4'b0110,4'd13},
    n = {4'b0110,4'd14},
    o = {4'b0110,4'd15},
    p = {4'b0111,4'd0},
    q = {4'b0111,4'd1},
    r = {4'b0111,4'd2},
    s = {4'b0111,4'd3},
    t = {4'b0111,4'd4},
    u = {4'b0111,4'd5},
    v = {4'b0111,4'd6},
    w = {4'b0111,4'd7},
    x = {4'b0111,4'd8},
    y = {4'b0111,4'd9},
    z = {4'b0111,4'd10},

    // signs
    space           = 8'b0010_0000,
    hash            = 8'b0010_0011,
    AND             = 8'b0010_0010,
    comma           = 8'b0010_1100,    
    dash            = 8'b0010_1101,
    dot             = 8'b0010_1110,
    colon           = 8'b0011_1010,
    equal           = 8'b0011_1101,
    question_mark   = 8'b0011_1111,
    underscore      = 8'b0101_1111,
    right_arrow     = 8'b0111_1110,
    left_arrow      = 8'b0111_1111
}charactor_t;   

/////////// main states //////////////////
typedef enum logic [2:0]{
    get_user_data = 3'd0,
    config_masters = 3'd1,
    com_ready = 3'd2,
    int_communication = 3'd3,
    int_com_done = 3'd4
} main_state_t;

//////////////////// master configuration state related logics /////////////////
typedef enum logic [2:0] {
    config_start = 3'd1,
    config_middle = 3'd2,
    config_last = 3'd3,  // last stream of configuration
    config_done = 3'd4
} config_sub_state_t;

typedef enum logic [2:0]{
    user_slave_sel = 3'd0,
    user_read_write_sel = 3'd1,
    user_ext_write_sel = 3'd2,
    user_slave_start_addr_sel = 3'd3,
    user_slave_end_addr_sel = 3'd4
} user_data_sub_state_t;

endpackage : top_details