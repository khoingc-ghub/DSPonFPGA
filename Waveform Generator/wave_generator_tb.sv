`timescale 1ns / 1ns

module wave_generator_tb;
    parameter PHASE_WORD_WIDTH = 32;
    reg i_clk, i_rst;
    reg i_sw1, i_sw2, i_sw3, i_sw4, i_sw5, i_sw6, i_sw7, i_sw8, i_sw9;
    reg i_button0, i_button1, i_button3;
    
    wire [23:0] o_wave_out;
    wave_generator #(.PHASE_WORD_WIDTH(PHASE_WORD_WIDTH)) dut (
        .i_clk(i_clk), 
		  .i_rst(i_rst),
	.i_clk48(i_clk),
        .i_sw1(i_sw1), 
		  .i_sw2(i_sw2), 
		  .i_sw3(i_sw3), 
		  .i_sw4(i_sw4),
        .i_sw5(i_sw5), 
		  .i_sw6(i_sw6), 
		  .i_sw7(i_sw7), 
		  .i_sw8(i_sw8), 
		  .i_sw9(i_sw9),
        .i_button0(i_button0), 
		  .i_button1(i_button1),
	.i_button3(i_button3),
        .o_wave_out(o_wave_out)
    );
    always #5 i_clk = ~i_clk;
    
    initial begin
        i_clk = 0;
        i_rst = 0;
        i_sw1 = 0; 
		  i_sw2 = 0; 
		  i_sw3 = 0;
        i_sw4 = 0; 
		  i_sw5 = 0; 
		  i_sw6 = 0;
        i_sw7 = 0; 
		  i_sw8 = 0; 
		  i_sw9 = 0;
        i_button0 = 0; i_button1 = 0; i_button3 = 0;        
        #20 i_rst = 1;    //Sine wave
		  #20000 i_sw8 = 1;
        
        #20000 i_sw1 = 1; //Square wave 10%
		         i_sw4 = 1; 
					i_sw8 = 0;
		  #20000 i_sw8 = 1;
        #20000 i_sw1 = 0; //Triangle wave 50%
					i_sw2 = 1;
					i_sw4 = 1;
					i_sw6 = 1;
					i_sw7 = 0;
					i_sw8 = 0;
		  #20000 i_sw8 = 1;
        #20000 i_sw1 = 1; //Sawtooth wave 40%
					i_sw4 = 0;
					i_sw6 = 1;
					i_sw7 = 0;
					i_sw8 = 0;
		  #20000 i_sw8 = 1;
		  #20000 i_sw1 = 1; //ECG wave
					i_sw2 = 0;
					i_sw3 = 1;
					i_sw8 = 0;
		  #20000 i_sw8 = 1;
        #20000;
        
		  $stop;
    end
endmodule
