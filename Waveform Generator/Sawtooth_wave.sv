module Sawtooth_wave(
  
  input  logic [9:0] i_addr,  // 0..1023
  input  logic [3:0] i_sel,   // 0..10 => 0..100%
  output logic [23:0] o_data
);

  integer peak;
  integer val;
  
  parameter MEM_SIZE = 1024;
  parameter MAX_VAL  = 24'h1FFFFF;

  always_comb begin
    peak = (MEM_SIZE * i_sel) / 10;  // vị trí đỉnh theo duty

    if (i_sel == 0) begin
      val = 0;  // duty=0% => luôn 0
    end else if (i_addr < peak) begin
      // đoạn tăng: 0 -> MAX_VAL
      val = (i_addr * MAX_VAL) / peak;
    end else begin
      // đoạn rơi: reset về 0
      val = 0;
    end

    o_data = val[23:0];
  end
endmodule
