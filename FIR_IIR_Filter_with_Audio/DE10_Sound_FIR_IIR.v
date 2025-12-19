module DE10_Sound_FIR_IIR (
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
    wire signed [15:0] wave_out, wave_in;
    wire i2c_done;
	 wire done_rx;
    wire bclk, lrclk;
	 wire locked;
	 wire signed [15:0] data_fir, data_iir;
	 
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
	 
	 fir fir_fillter( 
      .clk(AUD_BCLK),
		.rst_n(reset_n),
	   .new_data(done_rx),
      .x_in(wave_in),
      .y_out(data_fir)
	 );
	 
	 iir iir_fillter(
      .clk(AUD_BCLK),
		.rst_n(reset_n),
	   .new_data(done_rx),
      .x_in(wave_in),
      .y_out(data_iir)
    );
	 
	 mux3to1 mux_3(
      .i_a(wave_in),
	   .i_b(data_fir),
	   .i_c(data_iir),
	   .i_sel(SW[1:0]),
	   .o_out(wave_out)
    );
	 
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
		.sample_out(wave_in),
	 );
	 
	 assign AUD_DACDAT = AUD_DACDAT_temp;
	 assign AUD_DACLRCK = lrclk;
	 assign AUD_ADCLRCK = lrclk;
    assign LEDR[0] = i2c_done;
    assign LEDR[1] = locked; 
	 assign LEDR[2] = done_rx;
    assign LEDR[9:3] = 8'b0;// Không có ready
endmodule
	 
	 
	 
	 
	 