`include "m_definitions.svh"

module m_alu(
    // CONTROL INPUTS
    input logic clk, resetn,
    input logic [`MUX_MULTA_LENGTH-1:0]   mux_multA,
    input logic [`MUX_MULTB_LENGTH-1:0]   mux_multB,
    input logic [`MUX_DIV_REM_LENGTH-1:0] mux_div_rem,
    // DATA INPUTS
    input logic [31:0] R, // remainder
    input logic [62:0] D, // divisor
    input logic [31:0] Z, // quotient
    // CONTROL OUTPUTS
    // DATA OUTPUTS
    output logic [31:0] sub_result,
    output logic [31:0] div_rem,
    output logic [31:0] div_rem_neg,
    output logic [63:0] product
);


//// SUBTRACTOR (FOR DIVISION)
// Auxiliary signed values to instantiate signed subtractor
logic signed [62:0] sub_result_sign;
logic signed [62:0] sub_a, sub_b;

// Instantiate subtractor
assign sub_a = {31'd0,R}; // Add 0 to the left
assign sub_b = D;
assign sub_result_sign = $signed(sub_a) - $signed(sub_b); // Perform subtraction
// concatenation to avoid overwriting bit sign being overwritten
assign sub_result = {sub_result_sign[62],sub_result_sign[30:0]};


//// MULTIPLIER
// Auxiliary signed values to instantiate signed multiplier
logic signed [65:0] mult_result;
logic signed [32:0] mult_a, mult_b;

// Instantiate multiplier
always_comb begin
    mult_a[31:0] = R;
    mult_b[31:0] = D[62:31];
    unique case (mux_multA)
        `MUX_MULTA_R_UNSIGNED: mult_a[32] = 1'b0;  // add 0 to the left
        `MUX_MULTA_R_SIGNED  : mult_a[32] = R[31]; // extend bit sign
        `MUX_MULTA_ZERO      : mult_a     = 33'd0; // make it 0
    endcase
    unique case (mux_multB)
        `MUX_MULTB_D_UNSIGNED: mult_b[32] = 1'b0;  // add 0 to the left
        `MUX_MULTB_D_SIGNED  : mult_b[32] = D[62]; // extend bit sign
        `MUX_MULTB_ZERO      : mult_b     = 33'd0; // make it 0
    endcase
    mult_result = $signed(mult_a) * $signed(mult_b); // Perform multiplication

    // Pass result onto output
    if (mux_multA == `MUX_MULTA_R_SIGNED || mux_multB == `MUX_MULTB_D_SIGNED) begin
        product = {mult_result[65],mult_result[62:0]}; // avoid skipping sign bit
    end
    else begin
        product = mult_result[63:0]; // Ignore two LSB 
    end
end


//// DIVISION/REMAINDER SELECTION
always_comb begin
    // Select which division result is passed to the output
    unique case(mux_div_rem)
        `MUX_DIV_REM_R: div_rem = R;
        `MUX_DIV_REM_Z: div_rem = Z;
    endcase
    div_rem_neg = -div_rem; // also calculate its inverse, in case it is needed
end


endmodule