module ampl_2bit (
    input  wire signed [15:0] i_wave,
    input  wire [1:0]         i_sel,
    output wire signed [15:0] o_wave
);

    reg signed [15:0] gain;

    always @(*) begin
        case(i_sel)
				2'b00:   gain = i_wave;
				2'b01:   gain = {i_wave[14:0],1'b0};
				2'b10:   gain = {i_wave[13:0],2'b00};
				2'b11: 	gain = i_wave >>> 2;
				default: gain = i_wave;
        endcase
    end
	 assign o_wave = gain;
endmodule
