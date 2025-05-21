module m_alu(
    // CONTROL INPUTS
    input logic clk, resetn,
    input logic mux_multA [`MUX_MULTA_LENGTH-1:0],
    input logic mux_multB [`MUX_MULTB_LENGTH-1:0],
    input logic mux_div_rem [`MUX_DIV_REM_LENGTH-1:0],
    // DATA INPUTS
    input logic R [31:0], // remainder
    input logic D [62:0], // divisor
    input logic Z [31:0], // quotient
    // CONTROL OUTPUTS
    // DATA OUTPUTS
    output logic ALU_result [31:0],
    output logic div_rem [31:0],
    output logic div_rem_neg [31:0],
    output logic product [63:0]
);


//// SUBTRACTOR (FOR DIVISION)
// Auxiliary signed values to instantiate signed subtractor
logic signed sub_result [62:0];
logic signed sub_a [62:0], sub_b [62:0];

// Instantiate subtractor
always_comb begin
    sub_a = {31{1'b0},R}; // Add 0 to the left
    sub_b = D;
    sub_result = sub_a - sub_b; // Perform subtraction

    // concatenation to avoid overwriting bit sign being overwritten
    ALU_result = {sub_result[62],sub_result[30:0]};
end



//// MULTIPLIER
// Auxiliary signed values to instantiate signed multiplier
logic signed mult_result [65:0];
logic signed mult_a [32:0], mult_b [32:0];

// Instantiate multiplier
always_comb begin
    mult_a[31:0] = R;
    mult_b[31:0] = D[62:31];
    unique case (mux_multA)
        `MUX_MULTA_R_UNSIGNED: mult_a[32] = 1'b0;     // add 0 to the left
        `MUX_MULTA_R_SIGNED  : mult_a[32] = R[31];    // extend bit sign
        `MUX_MULTA_ZERO      : mult_a     = 33{1'b0}; // make it 0
    endcase
    unique case (mux_multB)
        `MUX_MULTB_D_UNSIGNED: mult_b[32] = 1'b0;     // add 0 to the left
        `MUX_MULTB_D_SIGNED  : mult_b[32] = D[62];    // extend bit sign
        `MUX_MULTB_ZERO      : mult_b     = 33{1'b0}; // make it 0
    endcase
    mult_result = mult_a * mult_b; // Perform multiplication

    // Pass result onto output
    if (mux_multA == `MUX_MULTA_R_SIGNED || mux_multB == `MUX_MULTB_D_SIGNED) begin
        product = {mult_result[65],mult_result[62:0]} // avoid skipping sign bit
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
