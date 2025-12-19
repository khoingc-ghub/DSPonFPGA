module iir (
    input  logic               clk, rst_n,
    input  logic               new_data,       // 1 xung / mỗi sample
    input  logic signed [15:0] x_in,           // input sample Q1.15
    output logic signed [15:0] y_out           // output sample Q1.15
);

    // ============================
    // HỆ SỐ (Q1.15) — dạng rõ ràng
    // ============================
    parameter signed [15:0] b0 = 16'sd982;
    parameter signed [15:0] b1 = 16'sd1963;
    parameter signed [15:0] b2 = 16'sd982; 

    parameter signed [15:0] a1 = -16'sd47653;   
    parameter signed [15:0] a2 = 16'sd18811;   

    // ===============================================
    // d1 và d2: state registers (Q1.15 trên 32-bit)
    // ===============================================
    logic signed [31:0] x1, x2;
    logic signed [31:0] y1, y2;
	 logic signed [31:0] y_temp;

    always_ff @(posedge clk) begin
		  if (!rst_n) begin
        x2 <= 0;
        x1 <= 0;
		  y1 <= 0;
		  y2 <= 0;
        y_temp <= 0;
    end else if (new_data) begin

            y_temp <= (b0 * x_in + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2) >>> 15; // Scaling by 2^15
            // Shift registers for next input/output
            x2 <= x1;
            x1 <= x_in;
            y2 <= y1;
            y1 <= y_temp;
        end
    end
	 assign y_out = y_temp;
endmodule
