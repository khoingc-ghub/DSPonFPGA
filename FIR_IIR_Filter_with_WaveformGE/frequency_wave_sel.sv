module frequency_wave_sel(
  input  logic [1:0] i_sel,
  output logic [31:0] o_phase_step
);
  always_comb begin
    case(i_sel)
	   	2'b00:  o_phase_step = 32'b10000000000000000000000;  //1024 sample
		2'b01:  o_phase_step = 32'b100000000000000000000000; //512 sapmle
		2'b10:  o_phase_step = 32'b1000000000000000000000000; // 256 sample
		default: o_phase_step = 32'b10000000000000000000000;
	 endcase
  end
endmodule