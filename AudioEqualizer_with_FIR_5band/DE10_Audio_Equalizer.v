module DE10_Audio_Equalizer (
    input 	CLOCK_50,
    input 	[3:0] KEY,
    input 	[9:0] SW,
    output 	[9:0] LEDR,
	 input	AUD_ADCDAT,
	 output	AUD_ADCLRCK,
    output 	AUD_XCK,
    output 	AUD_BCLK, 
	 output	AUD_DACLRCK,
    output 	AUD_DACDAT,
    output 	FPGA_I2C_SCLK,
    inout 	FPGA_I2C_SDAT
);
	 wire AUD_DACDAT_temp; 
    wire reset_n = KEY[0];
    wire clk_mclk;
    wire signed [15:0] wave_in;
	 reg  signed [15:0] wave_out;
    wire i2c_done;
	 wire done_rx;
    wire bclk, lrclk;
	 wire locked;
	 wire signed [15:0] data_fir1, data_fir2, data_fir3, data_fir4, data_fir5;
	 wire signed [15:0] data_fir1_out, data_fir2_out, data_fir3_out, data_fir4_out, data_fir5_out;
	 
	 mypll mypll_inst (
		.refclk   (CLOCK_50),   //  refclk.clk
		.rst      (~reset_n),      //   reset.reset
		.outclk_0 (AUD_XCK), // outclk0.clk 12,288
		.outclk_1 (AUD_BCLK), // outclk1.clk 3,072
		.locked   (locked)    //  locked.export
	 );
	 
	 // I2C config
    i2c_config u_i2c (
      .clk(CLOCK_50), // 50 MHz
      .rst_n(reset_n),
      .i2c_sclk(FPGA_I2C_SCLK), // 100khz
      .i2c_sdat(FPGA_I2C_SDAT),
      .i2c_done(i2c_done)
    );
	 
	 //fir 5 band
	 fir_lowpass fir_0_1000( 
      .clk(AUD_BCLK),
		.rst_n(reset_n),
	   .new_data(done_rx),
      .x_in(wave_in),
      .y_out(data_fir1)
	 );
	 
	 fir_bandpass1 fir_1000_5000( 
      .clk(AUD_BCLK),
		.rst_n(reset_n),
	   .new_data(done_rx),
      .x_in(wave_in),
      .y_out(data_fir2)
	 );
	 
	 fir_bandpass2 fir_5000_10000( 
      .clk(AUD_BCLK),
		.rst_n(reset_n),
	   .new_data(done_rx),
      .x_in(wave_in),
      .y_out(data_fir3)
	 );
	 
	 fir_bandpass3 fir_10000_15000( 
      .clk(AUD_BCLK),
		.rst_n(reset_n),
	   .new_data(done_rx),
      .x_in(wave_in),
      .y_out(data_fir4)
	 );
	 
	 fir_highpass fir_15000_20000( 
      .clk(AUD_BCLK),
		.rst_n(reset_n),
	   .new_data(done_rx),
      .x_in(wave_in),
      .y_out(data_fir5)
	 );
	 
	 //gain
	 ampl_2bit low(
		.i_wave(data_fir1),
		.i_sel(SW[1:0]),
		.o_wave(data_fir1_out)
	 );
	 
	 ampl_2bit band1(
		.i_wave(data_fir2),
		.i_sel(SW[3:2]),
		.o_wave(data_fir2_out)
	 );
	 
	 ampl_2bit band2(
		.i_wave(data_fir3),
		.i_sel(SW[5:4]),
		.o_wave(data_fir3_out)
	 );
	 
	 ampl_2bit band3(
		.i_wave(data_fir4),
		.i_sel(SW[7:6]),
		.o_wave(data_fir4_out)
	 );
	 
	 ampl_2bit high(
		.i_wave(data_fir5),
		.i_sel(SW[9:8]),
		.o_wave(data_fir5_out)
	 );
	 
	 wire signed [18:0] mix = data_fir1_out + data_fir2_out + data_fir3_out + data_fir4_out + data_fir5_out;

	 always @(*) begin
		  if (mix > 32767)        wave_out = 32767;
        else if (mix < -32768)  wave_out = -32768;
        else                    wave_out = mix[15:0];
    end
	 
	 // I2S Transmitter
    i2s_tx u_i2s (
      .rst_n(reset_n),
      .sample_in(wave_out), // Mono
      .bclk(AUD_BCLK), // ~3.072 MHz
      .lrclk(lrclk), // ~46.083 kHz
		.dacdat(AUD_DACDAT_temp)
    );
	 
	 i2s_rx r_i2s (
		.rst_n(reset_n),
		.bclk(AUD_BCLK),
		.lrclk(lrclk),
		.adcdat(AUD_ADCDAT),
		.done_rx(done_rx),
		.sample_out(wave_in)
	 );
	 
	 assign AUD_DACDAT = AUD_DACDAT_temp;
	 assign AUD_DACLRCK = lrclk;
	 assign AUD_ADCLRCK = lrclk;
    assign LEDR[0] = i2c_done;
    assign LEDR[1] = locked; 
	 assign LEDR[2] = done_rx;
    assign LEDR[9:3] = 8'b0;// Không có ready
endmodule
	 
	 
	 
	 
	 