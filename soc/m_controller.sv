`include "m_definitions.h"

module m_controller(
    // CONTROL INPUTS
    input logic clk, resetn,
    input logic pcpi_valid, // signal to start process
    // DATA INPUTS
    input logic [31:0] instruction, // instruction to analyze
    input logic [31:0] rs1, rs2, // operands to analyze
    // CONTROL OUTPUTS
    output logic [`MUX_R_LENGTH-1:0] mux_R, // multiplexer for remainder
    output logic [`MUX_D_LENGTH-1:0] mux_D, // multiplexer for divisor
    output logic [`MUX_Z_LENGTH-1:0] mux_Z, // multiplexer for quocient
    output logic [`MUX_MULTA_LENGTH-1:0] mux_multA, // multiplexer for mult input A
    output logic [`MUX_MULTB_LENGTH-1:0] mux_multB, // multiplexer for mult input B
    output logic [`MUX_DIV_REM_LENGTH-1:0] mux_div_rem, // multiplexer for Z/R selection
    output logic [`MUX_OUT_LENGTH-1:0] mux_out, // multiplexer for output
    output logic pcpi_ready,
    output logic pcpi_wr,
    output logic pcpi_busy
    // DATA OUTPUTS
    // none for now
);

// Internal Counter Signal
reg [4:0] counter;
reg [4:0] counter_next;

// Internal Signal to store input function
logic [2:0] current_func;

// CONTROL SIGNALS 
// STATE
typedef enum logic [2:0] {
    IDLE = 2'b000,
    VALID = 2'b001,
    DIV = 2'b010,
    SELECT = 2'b011,
    DONE = 2'b100
} state_t;
state_t state, next_state;


// SEQUENTIAL BLOCK
always_ff @(posedge clk, posedge resetn) // Asynchronous reset
begin
    if(resetn) begin
        state <= IDLE;
        counter <= 5'b00000;
    end
    else begin
        state <= next_state;
        counter <= counter_next;
    end
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

    // State machine control
    unique case (state)
        IDLE: begin
            // Reset output signals
            pcpi_ready = 1'b0;
            pcpi_wr = 1'b0;
            pcpi_busy = 1'b0;

            // Set multiplier mux to zero to save dynamic power
            mux_multA = `MUX_MULTA_ZERO;
            mux_multB = `MUX_MULTB_ZERO;

            // Reset the counter
            counter_next = 0;

            // Get the current func3
            current_func = get_ir_func3(instruction)

            // Input conditions for valid co-processor instruction
            if (pcpi_valid && !resetn && (get_ir_opcode(instruction) == OPCODE) 
                            && (get_ir_func7(instruction) == FUNC7)) begin            
                next_state = VALID;
            end else begin
                next_state = IDLE;
            end      
        end

        VALID: begin
            // Set busy to 1showing computation is in process
            pcpi_busy = 1'b1;

            // reset quotient mux
            mux_Z = `MUX_Z_ZERO;

            // Mux selection for signed DIV and REM and negative rs1
            if ((current_func == DIV || current_func == REM) 
                        && is_negative(rs1)) begin
                mux_R = `MUX_R_A_NEG;
            end else begin
                mux_R = `MUX_R_A;
            end

            // Mux selection for signed DIV and REM and negative rs2
            if ((current_func == DIV || current_func == REM) 
                        && is_negative(rs2)) begin
                mux_D = `MUX_D_B_NEG;
            end else begin
                mux_D = `MUX_D_B;
            end

            // Next state logic
            // Same state for DIV/REM and different for MUL
            if (is_div(current_func) || is_rem(current_func)) begin
                next_state = DIV;
            end else begin
                next_state = SELECT;
            end
        end

        DIV: begin
            //  Updating the R, D, Z signals using mux
            mux_R = `MUX_R_SUB_KEEP;
            mux_D = `MUX_D_SHR;
            mux_Z = `MUX_Z_SHL_ADD;

            // Incrementing the counter
            counter_next = counter + 5'b00001;

            // Next state logic
            // If counter is 31, it means we have ran the loop from 0 to 31
            if (counter < 5'b11111) begin
                next_state = DIV;
            end else begin
                next_state = SELECT;
            end
        end

        SELECT: begin
            // Selection for div or rem mux
            is_div(current_func) ? mux_div_rem = `MUX_DIV_REM_Z : mux_div_rem = `MUX_DIV_REM_R;

            // Selection for mul mux
            if (is_mult(current_func)) begin
                unique case(current_func):
                    // For MULH both inputs should be signed
                    MULH: begin
                        mux_multA = `MUX_MULTA_R_SIGNED;
                        mux_multB = `MUX_MULTB_D_SIGNED;
                    end
            
                    // For MULHSU first input is signed and second unsigned
                    MULHSU: begin
                        mux_multA = `MUX_MULTA_R_SIGNED;
                        mux_multB = `MUX_MULTB_D_UNSIGNED;
                    end

                    // For MUL & MULHU both inputs are unsigned
                    default: begin
                        mux_multA = `MUX_MULTA_R_UNSIGNED;
                        mux_multB = `MUX_MULTB_D_UNSIGNED;
                    end
                endcase
            end

            next_state = DONE;
        end

        DONE: begin
            // Output mux logic
            // Check if it is multiplication
            if (is_mult(current_func)) begin
                // If function is MUL then we use lower bits otherwise upper bits
                if (current_func == MUL) begin
                    mux_out = `MUX_OUT_MULT_LOWER;
                end else begin
                    mux_out = `MUX_OUT_MULT_UPPER;
                end

            // If its not multiplication, it must be division or remainder
            end else begin
                // Checking condition of signed DIV or REM and also negative output conditions
                // Quotient is negative if sign of rs1 is not equal to sign of rs2
                // Remainder has the same sign as the dividend
                if ((current_func == DIV && (is_negative(rs1) != is_negative(rs2)))
                        || (current_func == REM && is_negative(rs1))) begin
                    mux_out = `MUX_OUT_DIV_REM_NEG;
                end else begin
                    mux_out = `MUX_OUT_DIV_REM;
                end
            end

            // Set output signals
            pcpi_ready = 1'b1;
            pcpi_wr = 1'b1;
            pcpi_busy = 1'b0;

            next_state = IDLE;
        end
    endcase

end

endmodule