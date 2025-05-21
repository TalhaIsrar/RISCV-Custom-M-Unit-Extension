
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
	assign rd = 0;
	assign busy = 0;
	assign ready = 0;

endmodule