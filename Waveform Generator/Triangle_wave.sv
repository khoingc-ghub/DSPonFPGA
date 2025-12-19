module Triangle_wave(
input  logic [9:0] i_addr,  // 0..1023
  input  logic [3:0] i_sel,  // 0..10 => 0..100%
  output logic [23:0] o_data
);
  parameter MEM_SIZE = 1024;
  parameter MAX_VAL  = 24'h1FFFFF;
  integer peak;
  integer val;

  always_comb begin
    peak = (MEM_SIZE * i_sel) / 10;  // vị trí đỉnh theo duty

    if (i_sel == 0) begin
      val = 0;
    end 
	 else if (i_addr < peak) begin
      val = (i_addr * MAX_VAL) / peak;
    end 
			else begin
      val = MAX_VAL / (MEM_SIZE - peak) * (MEM_SIZE - i_addr);
    end

    o_data = val[23:0];
  end
endmodule
