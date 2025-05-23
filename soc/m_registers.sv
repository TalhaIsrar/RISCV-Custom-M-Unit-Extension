`include "m_definitions.svh"

module m_registers(
    // CONTROL INPUTS
    input logic clk, resetn,
    //input logic ALU_neg, // whether the result in the ALU is negative. Not needed
    input logic sub_neg,
    input logic [`MUX_R_LENGTH-1:0] mux_R, // multiplexer selection for remainder
    input logic [`MUX_D_LENGTH-1:0] mux_D, // multiplexer selection for divisor
    input logic [`MUX_Z_LENGTH-1:0] mux_Z, // multiplexer selection for quotient
    // DATA INPUTS
    input logic [31:0] rs1, rs2, // registers at the input
    input logic [31:0] rs1_neg, rs2_neg,
    input logic [31:0] sub_result, // result from the subtractor
    // CONTROL OUTPUTS
    // DATA OUTPUTS
    output logic [31:0] R, // remainder
    output logic [62:0] D, // divisor
    output logic [31:0] Z  // quotient
);


// REGISTERS
logic [31:0] next_R; // remainder
logic [62:0] next_D; // divisor
logic [31:0] next_Z; // quotient



// SEQUENTIAL BLOCK
// All registers are updated
always_ff @(posedge clk, negedge resetn) // Asynchronous reset
begin
    if(~resetn)
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

    unique case (mux_R)
        `MUX_R_KEEP:     next_R = R;
        `MUX_R_A:        next_R = rs1;
        `MUX_R_A_NEG:    next_R = rs1_neg;
        `MUX_R_SUB_KEEP: next_R = sub_neg ? R : sub_result;
    endcase

    unique case (mux_D)
        `MUX_D_KEEP:  next_D = D;
        `MUX_D_B:     next_D = {rs2,31'd0};
        `MUX_D_B_NEG: next_D = {rs2_neg,31'd0};
        `MUX_D_SHR:   next_D = {1'b0,D[62:1]};
    endcase

    unique case (mux_Z)
        `MUX_Z_KEEP:    next_Z = Z;
        `MUX_Z_ZERO:    next_Z = '0;
        `MUX_Z_SHL_ADD: begin
            next_Z[31:1] = Z[30:0];
            next_Z[0]    = sub_neg ? 1'b0 : 1'b1;
        end
    endcase
end



endmodule