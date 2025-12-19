module phase_accumulator#(
  parameter PHASE_WORD_WIDTH =32
)(
  input  logic i_clk, i_rst,
  input  logic [PHASE_WORD_WIDTH - 1:0] i_PhaseStep,
  output logic [PHASE_WORD_WIDTH - 1:0] o_CurrentPhase
);
  logic [PHASE_WORD_WIDTH-1:0] NextPhaseReg;
  logic [PHASE_WORD_WIDTH-1:0] PhaseRegister; 
  assign NextPhaseReg = PhaseRegister + i_PhaseStep;
  always_ff @(posedge i_clk) begin
    if(!i_rst)
	   PhaseRegister <= 0;
	 else
	   PhaseRegister <= NextPhaseReg;
  end
  assign o_CurrentPhase = PhaseRegister;
endmodule