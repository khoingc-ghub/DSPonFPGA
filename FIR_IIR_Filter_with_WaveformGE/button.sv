module button(
  //input
  input  logic i_clk,i_rst,
  input  logic i_button,
  //output
  output logic o_stable
);
  // local deslaration
  typedef enum logic [1:0] {
    IDLE,
	 PRESS,
	 HOLD
  } state_e;
  
state_e state_d;
state_e state_q;

//next_stage combinational logic
always_comb begin
  case (state_q)
    IDLE :  state_d = i_button ? PRESS : IDLE;
    PRESS:  state_d = i_button ? HOLD  : IDLE;
    HOLD :  state_d = i_button ? HOLD  : IDLE;
	 default:state_d = IDLE;
	endcase
end
//flip flop
always_ff @(posedge i_clk) begin
  if(!i_rst)
    state_q <= IDLE;
  else
    state_q <= state_d;
end
//output combinational logic

  assign o_stable = (state_q == PRESS) ? 1'b1 : 1'b0;
endmodule