module riscv_m_unit(
	input logic clk, 
	input logic resetn, 
	
	input logic valid;
	input logic[31:0] instruction;
	input logic[31:0] rs1;
	input logic[31:0] rs2;

	output logic wr;
	output logic[31:0] rd;
	output logic busy;
	output logic ready;
	);


//// DATA SIGNALS
// ALU inputs
logic R [31:0]; // remainder
logic D [62:0]; // divisor
logic Z [31:0]; // quotient
// ALU outputs
logic sub_result [31:0]; // subtraction's result
logic div_rem [31:0]; // divider's result
logic div_rem_neg [31:0]; // divider's result inverted
logic product [63:0]; // multiplier's result


//// CONTROL SIGNALS
logic mux_R[`MUX_R_LENGTH-1:0];
logic mux_D[`MUX_D_LENGTH-1:0];
logic mux_Z[`MUX_Z_LENGTH-1:0];
logic mux_multA[`MUX_MULTA_LENGTH-1:0];
logic mux_multB[`MUX_MULTB_LENGTH-1:0];
logic mux_div_rem[`MUX_DIV_REM_LENGTH-1:0];
logic mux_out[`MUX_OUT_LENGTH-1:0];


//// SUB-BLOCK INSTANTIATION

// CONTROLLER
m_controller controller (
    .clk(clk), .resetn(resetn), .pcpi_valid(valid), // control input
    .instruction(instruction), // data inputs
    .mux_R(mux_R), .mux_D(mux_D), .mux_Z(mux_Z), .mux_multA(mux_multA), .mux_multB(mux_multB), // control inputs
    .mux_div_rem(mux_div_rem), .mux_out(mux_out), .pcpi_ready(ready), .pcpi_wr(wr), .pcpi_busy(busy) // control inputs
);


// REGISTER FILE
m_registers registers(
    .clk(clk), .resetn(resetn), .mux_R(mux_R), .mux_D(mux_D), .mux_Z(mux_Z), // control inputs
    .rs1(rs1), .rs2(rs2), .sub_result(sub_result), // data inputs
    .R(R), .D(D), .Z(Z) // data outputs
);


// ALU
m_alu alu(
    .clk(clk), .resetn(resetn), .mux_multA(mux_multA), .mux_multB(mux_multB), .mux_div_rem(mux_div_rem), // control inputs
    .R(R), .D(D), .Z(Z) // data inputs
    .sub_result(sub_result), .div_rem(div_rem), .div_rem_neg(div_rem_neg), .product(product) // data outputs
);


// COMBINATORIAL BLOCK
always_comb begin
    // MUX output selection
    unique case (mux_out)
        `MUX_OUT_ZERO:        rd = '0;
        `MUX_OUT_DIV_REM:     rd = div_rem;
        `MUX_OUT_DIV_REM_NEG: rd = div_rem_neg;
        `MUX_OUT_MULT_LOWER:  rd = product[31:0];
        `MUX_OUT_MULT_UPPER:  rd = product[63:32];
    endcase
end



endmodule
