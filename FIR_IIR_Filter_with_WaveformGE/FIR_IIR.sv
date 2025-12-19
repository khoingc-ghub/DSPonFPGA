module FIR_IIR (
    input CLOCK_50,
    input [2:0] KEY,
    input [9:0] SW,
    output [9:0] LEDR,
    output AUD_XCK,
    output AUD_BCLK, AUD_DACLRCK,
    output AUD_DACDAT,
    output FPGA_I2C_SCLK,
    inout FPGA_I2C_SDAT
);
	 wire signed [15:0] data_16bit, data_fir, data_iir;
	 wire AUD_DACDAT_temp; 
    wire reset_n = KEY[0];
    wire signed [15:0] wave_sample;
    wire i2c_done;
	 wire locked;
	 wire new_data;
	 
    // CLOCK_500: Tạo MCLK
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

    // Waveform Generator
    wave_generator #(
        .PHASE_WORD_WIDTH(32)
    ) u_wave_gen (
        .i_clk(CLOCK_50), // ~50MHz từ i2s_tx
		  .i_clk48(AUD_DACLRCK),
        .i_rst(reset_n),
        .i_sw1(SW[0]), .i_sw2(SW[1]), .i_sw3(SW[2]), .i_sw4(SW[3]),
        .i_sw5(SW[4]), .i_sw6(SW[5]), .i_sw7(SW[6]), .i_sw8(SW[7]),
        //.i_sw9(SW[8]),
        .i_button0(~KEY[1]), // Tần số sóng
        .i_button1(~KEY[2]), // Biên độ sóng 
        //.i_button3(~KEY[3]), // Tần số/biên độ nhiễu (tùy SW[8])
        .o_wave_out(data_16bit)
    );
	 
	 fir fir_fillter( 
      .clk(AUD_BCLK),
		.rst_n(reset_n),
	   .new_data(new_data),
      .x_in(data_16bit),
      .y_out(data_fir)
	 );

	 iir iir_fillter(
      .clk(AUD_BCLK),
		.rst_n(reset_n),
	   .new_data(new_data),
      .x_in(data_16bit),
      .y_out(data_iir)
    );

	 mux3to1 mux(
		.i_a(data_16bit),
		.i_b(data_fir),
		.i_c(data_iir),
		.i_sel(SW[9:8]),
		.o_out(wave_sample)
    );

	 reg lrclk_d;
	 always_ff @(negedge AUD_BCLK) begin
		      lrclk_d <= AUD_DACLRCK;

            new_data <= 1'b0;
        if (lrclk_d && !AUD_DACLRCK) begin
            new_data <= 1'b1; // chỉ bật khi 1 xuống 0
        end
    end
	 
    // I2S Transmitter
    i2s_tx u_i2s (
        .rst_n(reset_n),
        .sample_in(wave_sample), // Mono
        .bclk(AUD_BCLK), // ~3.072 MHz
        .lrclk(AUD_DACLRCK), // ~46.083 kHz
        .dacdat(AUD_DACDAT_temp)
    );
	
	 assign AUD_DACDAT = AUD_DACDAT_temp;
    assign LEDR[0] = i2c_done;
    assign LEDR[1] = locked; 
    assign LEDR[9:2] = 8'b0;// Không có ready
endmodule