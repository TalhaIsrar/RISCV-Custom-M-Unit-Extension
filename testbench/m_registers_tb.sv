`include "../soc/m_definitions.svh"

module m_registers_tb;

// CONTROL INPUTS
logic clk, resetn;
//input logic ALU_neg, // whether the result in the ALU is negative. Not needed
logic [`MUX_R_LENGTH-1:0] mux_R; // multiplexer selection for remainder
logic [`MUX_D_LENGTH-1:0] mux_D; // multiplexer selection for divisor
logic [`MUX_Z_LENGTH-1:0] mux_Z; // multiplexer selection for quotient
// DATA INPUTS
logic [31:0] rs1, rs2; // registers at the input
logic [31:0] sub_result; // result from the subtractor
// CONTROL OUTPUTS
// DATA OUTPUTS
logic [31:0] R; // remainder
logic [62:0] D; // divisor
logic [31:0] Z; // quotient

m_registers registers(.*);

logic [31:0] D_lower, D_upper;
assign D_lower = D[31:0];
assign D_upper = D[62:31];
logic [31:0] test_Z;

initial begin
    clk = '0;
    resetn = '0;
    #5ns resetn = '1;
    forever #5ns clk = ~clk;
end

initial begin
    // Set all inputs initially to 0 (avoid X or Z)
    mux_R = '0;
    mux_D = '0;
    mux_Z = '0;
    rs1 = '0;
    rs2 = '0;
    sub_result = '0;
    test_Z = '0;

    #21ns

    //// TEST R
    // R should get from input
    mux_R = `MUX_R_A;
    rs1 = 32'd789;
    @(posedge clk) @(clk) assert(R == rs1) else $error("R = %d, rs1 = %d", R, rs1);
    #4ns

    // R should negate input's value
    mux_R = `MUX_R_A_NEG;
    rs1 = -32'd7890;
    @(posedge clk) @(clk) assert(R == -rs1) else $error("R = %d, rs1 = %d", R, rs1);
    #4ns

    // R should keep previous value
    mux_R = `MUX_R_KEEP;
    @(posedge clk) @(clk) assert(R == -rs1) else $error("R = %d, rs1 = %d", R, rs1);
    #4ns

    // R should keep previous value since sub_result is negative
    mux_R = `MUX_R_SUB_KEEP;
    sub_result = -32'd123;
    @(posedge clk) @(clk) assert(R == -rs1) else $error("R = %d, rs1 = %d", R, rs1);
    #4ns

    // R should get value from sub_result since it's negative
    mux_R = `MUX_R_SUB_KEEP;
    sub_result = 32'd123;
    @(posedge clk) @(clk) assert(R == sub_result) else $error("R = %d, rs2 = %d", D, rs2);
    #4ns


    //// TEST D
    // D should get value from input
    mux_D = `MUX_D_B;
    rs2 = 32'd456;
    @(posedge clk) @(clk) assert(D[62:31] == rs2) else $error("D[62:31] = %d, rs2 = %d", D, rs2);
    #4ns

    // D should keep the value from input
    mux_D = `MUX_D_KEEP;
    @(posedge clk) @(clk) assert(D[62:31] == rs2) else $error("D[62:31] = %d, rs2 = %d", D, rs2);
    #4ns

    // D should negate the value from input
    mux_D = `MUX_D_B_NEG;
    rs2 = -32'd4567;
    @(posedge clk) @(clk) assert(D[62:31] == -rs2) else $error("D[62:31] = %d, rs2 = %d", D, rs2);
    #4ns

    // D should shift right by 1 bit
    mux_D = `MUX_D_SHR;
    @(posedge clk) @(clk) assert(D[61:30] == -rs2) else $error("D[61:30] = %d, rs2 = %d", D, rs2);
    #4ns


    //// TEST Z
    // Z should be set to 0
    mux_Z = `MUX_Z_ZERO;
    test_Z = 32'd0;
    @(posedge clk) @(clk) assert(Z == test_Z) else $error("Z = %d, test_Z = %d", Z, test_Z);
    #4ns

    // Z should be 1
    mux_Z = `MUX_Z_SHL_ADD;
    sub_result = 32'd123;
    test_Z = (test_Z << 1) + 1;
    @(posedge clk) @(clk) assert(Z == test_Z) else $error("Z = %d, test_Z = %d", Z, test_Z);
    #4ns

    // Z should keep current value
    mux_Z = `MUX_Z_KEEP;
    sub_result = 32'd123;
    @(posedge clk) @(clk) assert(Z == test_Z) else $error("Z = %d, test_Z = %d", Z, test_Z);
    #4ns

    // Z should double
    mux_Z = `MUX_Z_SHL_ADD;
    sub_result = -32'd123;
    test_Z = (test_Z << 1);
    @(posedge clk) @(clk) assert(Z == test_Z) else $error("Z = %d, test_Z = %d", Z, test_Z);
    #4ns

    // Z should double and add by 1
    mux_Z = `MUX_Z_SHL_ADD;
    sub_result = 32'd123;
    test_Z = (test_Z << 1) + 1;
    @(posedge clk) @(clk) assert(Z == test_Z) else $error("Z = %d, test_Z = %d", Z, test_Z);
    #4ns

    // Z should double and add by 1
    mux_Z = `MUX_Z_SHL_ADD;
    sub_result = 32'd123;
    test_Z = (test_Z << 1) + 1;
    @(posedge clk) @(clk) assert(Z == test_Z) else $error("Z = %d, test_Z = %d", Z, test_Z);
    #4ns

    // Z should double and add by 1
    mux_Z = `MUX_Z_SHL_ADD;
    sub_result = 32'h80000000;
    test_Z = (test_Z << 1);
    @(posedge clk) @(clk) assert(Z == test_Z) else $error("Z = %d, test_Z = %d", Z, test_Z);
    #4ns

    $stop;

end

endmodule