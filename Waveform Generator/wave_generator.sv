module wave_generator #(
  parameter PHASE_WORD_WIDTH = 32
)(
  input  logic        i_clk, i_rst, i_clk48,                    // Clock và Reset
  input  logic i_sw1, i_sw2, i_sw3, i_sw4, i_sw5, i_sw6, i_sw7, i_sw8,i_sw9,
  input  logic i_button0, i_button1, i_button3,
  output logic signed [23:0]  o_wave_out                     
);
  logic [PHASE_WORD_WIDTH-1:0] current_phase; // Pha hiện tại (32-bit)
  logic [9:0] wave_addr; // Địa chỉ LUT (10-bit)
  logic [23:0] sine_wave, square_wave, triangle_wave, sawtooth_wave, noise_wave, ecg_wave;
  logic [23:0] noise_plus_wave;
  logic [23:0] noiseless_wave;
  //pin
  logic noise_enable;
  logic [3:0]  duty_cycle;
  logic [1:0] frequency;
  logic [1:0] amplitude_sel;
  logic [2:0]  wave_sel;
  logic [31:0] phase_step_temp;
  logic [23:0] wave_out;
  logic button_noise_freq, button_noise_ampl;
  logic [1:0] noise_freq_sel, noise_ampl_sel;
  logic [31:0] current_phase_noise;
  logic [31:0] phase_step_noise_temp;
  logic [11:0] noise_addr;
  logic [23:0] noise_wave_ampl;
    
  //switch
  assign noise_enable = i_sw8;
  assign duty_cycle = {i_sw7,i_sw6,i_sw5,i_sw4};
  assign wave_sel = {i_sw3,i_sw2,i_sw1};
  assign button_noise_freq = (!i_sw9) ? i_button3 : 1'b0;
  assign button_noise_ampl = (i_sw9) ? i_button3 : 1'b0;
  
  //button_counter
  button_counter counter_frequency_sel(
    .i_clk(i_clk),
	 .i_rst(i_rst),
    .i_button(i_button0),
    .o_counter_value(frequency)
  );  
  
  button_counter counter_amplitude_sel(
    .i_clk(i_clk),
	 .i_rst(i_rst),
    .i_button(i_button1),
    .o_counter_value(amplitude_sel)
  );  
  
  button_counter counter_noisefreq_sel(
    .i_clk(i_clk),
	 .i_rst(i_rst),
    .i_button(button_noise_freq),
    .o_counter_value(noise_freq_sel)
  );
  
  button_counter counter_noiseampl_sel(
    .i_clk(i_clk),
	 .i_rst(i_rst),
    .i_button(button_noise_ampl),
    .o_counter_value(noise_ampl_sel)
  );
  frequency_wave_sel change_frequency(
    .i_sel(frequency),
    .o_phase_step(phase_step_temp));
	 

 phase_accumulator #(
    .PHASE_WORD_WIDTH(PHASE_WORD_WIDTH)
  ) phase_acc (
    .i_clk(i_clk48),
    .i_rst(i_rst),
    .i_PhaseStep(phase_step_temp),
    .o_CurrentPhase(current_phase)
  );

  // Trích xuất 10-bit MSB từ pha 32-bit làm địa chỉ LUT
  assign wave_addr = current_phase[31:22];
  Sinewave sine_lut (
    .i_addr(wave_addr),
    .o_data(sine_wave)
  );
  
  Square_wave square_lut (
    .i_addr(wave_addr),
    .i_sel(duty_cycle),
    .o_data(square_wave)
  );
  
  Triangle_wave triangle_lut (
    .i_addr(wave_addr),
    .i_sel(duty_cycle),
    .o_data(triangle_wave)
  );

  Sawtooth_wave sawtooth_lut (
    .i_addr(wave_addr),
    .i_sel(duty_cycle),
    .o_data(sawtooth_wave)
  );
  LUT_ecg ecg_lut (
    .i_addr(wave_addr),
    .o_data(ecg_wave)
  );
// noise  
  always_comb begin
    case(noise_freq_sel)
	   2'b00: phase_step_noise_temp = 32'b100000000000000000000; //4096 sample
		2'b01: phase_step_noise_temp = 32'b1000000000000000000000;  //2048 sample
		2'b10: phase_step_noise_temp = 32'b100000000000000000000000; //512 sample
		2'b11: phase_step_noise_temp = 32'b1000000000000000000000000;//256  sample
		default: phase_step_noise_temp = 32'b100000000000000000000;//4096 sample
	 endcase
  end
  phase_accumulator #(
    .PHASE_WORD_WIDTH(PHASE_WORD_WIDTH)
  ) phase_noise (
    .i_clk(i_clk48),
    .i_rst(i_rst),
    .i_PhaseStep(phase_step_noise_temp),
    .o_CurrentPhase(current_phase_noise)
  );
  assign noise_addr = current_phase_noise[31:20];
 
  lfsr_noise noise_signal (
    .i_addr(noise_addr),
    .o_data(noise_wave)
  );
  
  amplitude_wave_sel ampli_noise(
    .i_wave(noise_wave),
    .i_sel(noise_ampl_sel),
    .o_wave_ampl(noise_wave_ampl));
  
  // combination
  always_comb begin
    case(wave_sel)
	   3'b000:  noiseless_wave = sine_wave;   //sine wave
		3'b001:  noiseless_wave = square_wave; //square wave
		3'b010:  noiseless_wave = triangle_wave;//triangle wave
		3'b011:  noiseless_wave = sawtooth_wave;//sawtooth wave
		3'b100:  noiseless_wave = noise_wave_ampl;
		3'b101:  noiseless_wave = ecg_wave;
		default: noiseless_wave = sine_wave;
	 endcase
  end
  assign noise_plus_wave = noiseless_wave + noise_wave_ampl;
  //output combination
  assign wave_out = (noise_enable) ? noise_plus_wave : noiseless_wave;
  //amplitude
  amplitude_wave_sel ampli_wave(
    .i_wave(wave_out),
    .i_sel(amplitude_sel),
    .o_wave_ampl(o_wave_out));
  
endmodule