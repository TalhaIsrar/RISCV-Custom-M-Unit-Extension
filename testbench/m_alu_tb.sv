`include "../soc/m_definitions.svh"

module m_alu_tb;

// CONTROL INPUTS
logic clk, resetn;
logic [`MUX_MULTA_LENGTH-1:0] mux_multA;
logic [`MUX_MULTB_LENGTH-1:0] mux_multB;
logic [`MUX_DIV_REM_LENGTH-1:0] mux_div_rem;
// ALU inputs
logic [31:0] R; // remainder
logic [62:0] D; // divisor
logic [31:0] Z; // quotient
// ALU outputs
logic [31:0] sub_result;  // subtraction's result
logic [31:0] div_rem;     // divider's result
logic [31:0] div_rem_neg; // divider's result inverted
logic [63:0] product;     // multiplier's result

// Instantiate the ALU
m_alu alu(.*);

// Define the struct
typedef struct {
    logic [`MUX_MULTA_LENGTH-1:0] sel_mult_a;
    logic [`MUX_MULTB_LENGTH-1:0] sel_mult_b;
    logic [31:0] mult_a;
    logic [31:0] mult_b;
    logic [63:0] result_mult;
} mult_t;

// Declare an array of the struct
mult_t mult_array[40];

// counter to facilitate debug
int count = 0;


// set clock and reset
initial begin
    clk = '0;
    resetn = '0;
    #5ns resetn = '1;
    forever #5ns clk = ~clk;
end



// Set and test values
initial begin
    // Test unsigned multiplication
    for (int i = 0; i < 10; i++) begin
        mult_array[i].sel_mult_a = `MUX_MULTA_R_UNSIGNED;
        mult_array[i].sel_mult_b = `MUX_MULTA_R_UNSIGNED;
        mult_array[i].mult_a = $urandom_range({32{1'b1}}, 0);
        mult_array[i].mult_b = $urandom_range({32{1'b1}}, 0);
        mult_array[i].result_mult = mult_array[i].mult_a * mult_array[i].mult_b;
    end

    // Test signed by unsigned multiplication
    for (int i = 10; i < 20; i++) begin
        mult_array[i].sel_mult_a = `MUX_MULTA_R_SIGNED;
        mult_array[i].sel_mult_b = `MUX_MULTA_R_UNSIGNED;
        mult_array[i].mult_a = $urandom_range({32{1'b1}}, 0);
        mult_array[i].mult_b = $urandom_range({32{1'b1}}, 0);
        mult_array[i].result_mult = $signed(mult_array[i].mult_a) * $signed({1'b0,mult_array[i].mult_b}); // one 0 bit added to make sure number is read as positive
    end

    // Test signed multiplication
    for (int i = 20; i < 30; i++) begin
        mult_array[i].sel_mult_a = `MUX_MULTA_R_SIGNED;
        mult_array[i].sel_mult_b = `MUX_MULTA_R_SIGNED;
        mult_array[i].mult_a = $urandom_range({32{1'b1}}, 0);
        mult_array[i].mult_b = $urandom_range({32{1'b1}}, 0);
        mult_array[i].result_mult = $signed(mult_array[i].mult_a) * $signed(mult_array[i].mult_b);
    end

    D[30:0] = {31{1'b0}}; // set lower unused bits
    // leave this zero for now
    mux_div_rem = '0;
    Z = '0;

    #20ns;

    // Iterate through the array and test all values
    for (count = 0; count < 30; count++) begin
        R = mult_array[count].mult_a;
        D[62:31] = mult_array[count].mult_b;
        mux_multA = mult_array[count].sel_mult_a;
        mux_multB = mult_array[count].sel_mult_b;
        #5ns assert(product == mult_array[count].result_mult); // if fails, means we need to check
        #5ns;
    end

    #100ns
    count = 0;

    $stop;
end

endmodule
