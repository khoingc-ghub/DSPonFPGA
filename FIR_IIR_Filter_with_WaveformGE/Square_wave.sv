module Square_wave (
  input  logic [9:0] i_addr,   
  input  logic [3:0] i_sel,   
  output logic signed [15:0] o_data
);
  parameter MEM_SIZE = 1024;
  integer threshold;

  always_comb begin : next_pc
    case (i_sel)
      4'b0000: threshold = 0; 
      4'b0001: threshold = (10  * MEM_SIZE) / 100;  
      4'b0010: threshold = (20  * MEM_SIZE) / 100; 
      4'b0011: threshold = (30  * MEM_SIZE) / 100;  
      4'b0100: threshold = (40  * MEM_SIZE) / 100;  
      4'b0101: threshold = (50  * MEM_SIZE) / 100;  
      4'b0110: threshold = (60  * MEM_SIZE) / 100;  
      4'b0111: threshold = (70  * MEM_SIZE) / 100;  
      4'b1000: threshold = (80  * MEM_SIZE) / 100;  
      4'b1001: threshold = (90  * MEM_SIZE) / 100;  
      4'b1010: threshold = MEM_SIZE; 
      default: threshold = 0;
    endcase

    if (i_addr < threshold)
      o_data = 16'h1FFF; 
    else
      o_data = 16'h0000; 
  end : next_pc

endmodule
