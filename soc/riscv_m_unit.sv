
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

assign wr = 0;
//assign rd = 0;
assign busy = 0;
assign ready = 0;

//// DATA SIGNALS
logic div_rem [31:0];
logic div_rem_neg [31:0];
logic product [63:0];


//// CONTROL SIGNALS
logic mux_R[`MUX_R_LENGTH-1:0];
logic mux_D[`MUX_D_LENGTH-1:0];
logic mux_Z[`MUX_Z_LENGTH-1:0];
logic mux_multA[`MUX_MULTA_LENGTH-1:0];
logic mux_multB[`MUX_MULTB_LENGTH-1:0];
logic mux_div_rem[`MUX_DIV_REM_LENGTH-1:0];
logic mux_out[`MUX_OUT_LENGTH-1:0];


//// SUB-BLOCK INSTANTIATION (TODO)

// CONTROLLER



// REGISTER FILE



// ALU


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