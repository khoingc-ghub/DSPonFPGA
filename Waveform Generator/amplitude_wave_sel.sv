module amplitude_wave_sel(
  input  logic [23:0] i_wave,
  input  logic [1:0]  i_sel,
  output logic [23:0] o_wave_ampl
);
  always_comb begin
    case(i_sel)
	   2'b00:   o_wave_ampl = i_wave;
		2'b01:   o_wave_ampl = {i_wave[22:0],1'b0};
		2'b10:   o_wave_ampl = {i_wave[21:0],2'b00};
	   default: o_wave_ampl = i_wave;
	 endcase
  end
endmodule