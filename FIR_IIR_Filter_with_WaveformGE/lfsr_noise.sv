module lfsr_noise (
  input  logic [11:0] i_addr,
  output logic [11:0] o_data
);
  parameter MEM_SIZE = 4096;
  logic [11:0] LUT_noise [MEM_SIZE-1:0];
  
  always_comb begin : next_pc_ff
    o_data <= LUT_noise[i_addr[11:0]];
  end : next_pc_ff
  
  
  initial begin
    integer i;
	 for (i=0; i < MEM_SIZE; i++) begin
	   LUT_noise[i] = 12'b0;
	 end
	 $readmemh("LUT_noise1.dump",LUT_noise);
  end

endmodule