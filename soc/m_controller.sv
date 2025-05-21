`include "m_definitions.svh"

module m_controller(
    // CONTROL INPUTS
    input logic clk, reset,
    input logic pcpi_valid, // signal to begin process
    // DATA INPUTS
    input logic instruction[31:0], // instruction to analyze
    // CONTROL OUTPUTS
    output logic mux_R [`MUX_R_LENGTH-1:0], // multiplexer for remainder
    output logic mux_D [`MUX_D_LENGTH-1:0], // multiplexer for divisor
    output logic mux_Z [`MUX_Z_LENGTH-1:0], // multiplexer for quocient
    output logic mux_multA [`MUX_MULTA_LENGTH-1:0], // multiplexer for mult input A
    output logic mux_multB [`MUX_MULTB_LENGTH-1:0], // multiplexer for mult input B
    output logic mux_div_rem [`MUX_DIV_REM_LENGTH-1:0], // multiplexer for Z/R selection
    output logic mux_out [`MUX_OUT_LENGTH-1:0], // multiplexer for output
    output logic pcpi_ready,
    output logic pcpi_wr,
    output logic pcpi_busy
    // DATA OUTPUTS
    // none for now
);

// CONTROL SIGNALS 
// STATE
typedef enum logic [1:0] { // TODO
    IDLE = 2'b00,
    RUNNING = 2'b01,
    STOPPED = 2'b10
} state_t;
state_t state, next_state;



// SEQUENTIAL BLOCK
always_ff @(posedge clk, posedge reset) // Asynchronous reset
begin
    if(reset) state <= IDLE;
    else      state <= next_state;
end



// COMBINATORIAL BLOCK
// State machine to handle whole design
always_comb
begin
    // Set all outputs to default (avoid latches)
    mux_R = `MUX_R_KEEP;
    mux_D = `MUX_D_KEEP;
    mux_Z = `MUX_Z_KEEP;
    mux_multA = `MUX_MULTA_ZERO;
    mux_multB = `MUX_MULTB_ZERO;
    mux_div_rem = `MUX_DIV_REM_R;
    mux_out = `MUX_OUT_ZERO;
    
    // setting registers to previous state
    next_state = state;

    unique case (state)
        IDLE: begin
            next_state =
        end
    endcase

end

endmodule
