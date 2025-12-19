module button_counter(
  input  logic       i_clk, i_rst,
  input  logic       i_button,
  output logic [1:0] o_counter_value
);
  logic button_press;
  logic [1:0] counter_value_temp;
  button button_preventlongpress(
    .i_clk(i_clk),
	 .i_rst(i_rst),
    .i_button(i_button),
    .o_stable(button_press));
	 
  always_ff @(posedge i_clk) begin
    if(!i_rst) begin
	   counter_value_temp <= 2'b0;
	 end
	 else begin
	   if(button_press) begin
		  counter_value_temp = counter_value_temp + 2'b1;
		end
	 end
  end
  
  assign o_counter_value = counter_value_temp;
endmodule