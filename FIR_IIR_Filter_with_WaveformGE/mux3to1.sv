module mux3to1(
  input  logic signed [15:0] i_a, i_b, i_c,
  input  logic        [1:0]  i_sel,
  output logic signed [15:0] o_out
);
  always_comb begin
    case(i_sel)
      2'b00: o_out = i_a;
      2'b01: o_out = i_b;
      2'b10: o_out = i_c;
      default: o_out = i_a;
    endcase
  end
endmodule