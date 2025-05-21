module m_registers(
    // CONTROL INPUTS
    input logic clk, reset,
    //input logic ALU_neg, // whether the result in the ALU is negative. Not needed
    input logic muxR [`MUX_R_LENGTH-1:0], // multiplexer selection for remainder
    input logic muxD [`MUX_D_LENGTH-1:0], // multiplexer selection for divisor
    input logic muxZ [`MUX_Z_LENGTH-1:0], // multiplexer selection for quotient
    // DATA INPUTS
    input logic rs1 [31:0], rs2 [31:0], // registers at the input
    input logic sub_result [31:0], // result from the subtractor
    // CONTROL OUTPUTS
    // DATA OUTPUTS
    output logic R [31:0], // remainder
    output logic D [62:0], // divisor
    output logic Z [31:0]  // quotient
);

// AUXILIARY FUNCTIONS
// Function to determine whether a number is negative (MSB bit check)
function logic is_negative(unsigned value[31:0]);
    return value[31];
endfunction


// REGISTERS
logic next_R [31:0]; // remainder
logic next_D [62:0]; // divisor
logic next_Z [31:0]; // quotient



// SEQUENTIAL BLOCK
// All registers are updated
always_ff @(posedge clk, posedge reset) // Asynchronous reset
begin
    if(reset)
    begin
        R <= '0;
        D <= '0;
        Z <= '0;
    end
    else
    begin
        R <= next_R;
        D <= next_D;
        Z <= next_Z;
    end
end


// COMBINATORIAL BLOCK
// Update registers according to selection signals activated
always_comb
begin
    // Default values are values already saved in registers (redundant to avoid latches)
    next_R = R;
    next_D = D;
    next_Z = Z;

    unique case (muxR)
        `MUX_R_KEEP:     next_R = R;
        `MUX_R_A:        next_R = rs1;
        `MUX_R_A_NEG:    next_R = -rs1;
        `MUX_R_SUB_KEEP: next_R = is_negative(sub_result) ? R : sub_result;
    endcase

    unique case (muxD)
        `MUX_D_KEEP:  next_D = D;
        `MUX_D_B:     next_D = rs2;
        `MUX_D_B_NEG: next_D = -rs2;
        `MUX_D_SHR:   next_D = {1'b0,D[31:1]};
    endcase

    unique case (next_Z)
        `MUX_Z_KEEP:    next_Z = Z;
        `MUX_Z_ZERO:    next_Z = '0;
        `MUX_Z_SHL_ADD: begin
            next_Z[31:1] = Z[30:0];
            next_Z[0]    = is_negative(sub_result) ? 1'b0 : 1'b1;
        end
    endcase
end



endmodule
