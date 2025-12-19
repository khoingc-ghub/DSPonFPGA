module i2s_rx (
    input  wire rst_n,
    input  wire bclk,     
    input  wire lrclk,    
    input  wire adcdat,
	 
	 output reg done_rx,
    output reg signed [15:0] sample_out
);

    reg [4:0] bit_cnt;         // đếm 0..16
    reg [15:0] shift_reg;

    always @(negedge bclk or negedge rst_n) begin
        if (!rst_n) begin
            bit_cnt    <= 0;
            shift_reg  <= 0;
            sample_out <= 0;
				done_rx    <= 0;
        end 
        else begin

            //--------------------------------------------------
            // Chỉ nhận kênh LEFT (lrclk = 0)
            //--------------------------------------------------
            if (lrclk == 0) begin

                // Nếu mới vào kênh LEFT → reset đếm
                if (bit_cnt == 0)
                    bit_cnt <= 1;
                else
                    bit_cnt <= bit_cnt + 1;

                //--------------------------------------------------
                // CHUẨN I2S: BCLK đầu tiên sau LRCLK → bỏ
                // Shift từ bit_cnt = 1..16
                //--------------------------------------------------
                if (bit_cnt >= 1 && bit_cnt <= 16) begin
                    shift_reg <= {shift_reg[14:0], adcdat};
                end

                //--------------------------------------------------
                // Đủ 16 bit → ghi sample ra ngoài
                //--------------------------------------------------
                if (bit_cnt == 17) begin
                    sample_out <= shift_reg;
						  done_rx <= 1;
                end
					 if (bit_cnt == 18) begin
						  done_rx <= 0;
					 end
            end

            //--------------------------------------------------
            // Khi sang RIGHT (lrclk = 1) → bỏ, reset counter
            //--------------------------------------------------
            else begin
                bit_cnt <= 0;
					 
            end

        end
    end

endmodule
