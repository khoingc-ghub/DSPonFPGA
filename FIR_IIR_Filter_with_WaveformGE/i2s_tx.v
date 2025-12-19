module i2s_tx (
    input wire rst_n,
    input wire signed [15:0] sample_in, // 24-bit data
    input wire bclk, // bit clock (~3.072 MHz cho 48 kHz * 64)
    output reg lrclk, // left/right clock (~48 kHz)
    output reg dacdat // serial data
);

    // Clock divider/counter
    reg [5:0] bclk_counter; // 6-bit counter (0-63)
    reg [15:0] left_data;   // 24-bit shift register cho kênh trái
    reg [15:0] right_data;  // 24-bit shift register cho kênh phải
	 	
    always @(negedge bclk or negedge rst_n) begin
        if (!rst_n) begin
            bclk_counter <= 0;
            lrclk <= 0;
            dacdat <= 0;
            left_data <= 0;
            right_data <= 0;
        end else begin
            // Xử lý output và shift
            if (bclk_counter == 0) begin
                // BCLK trống đầu tiên của kênh trái
                dacdat <= 0;
                lrclk <= 0; // LRCLK = 1 cho kênh trái
                left_data <= sample_in; // Load dữ liệu mới cho kênh trái
                right_data <= sample_in; // Load dữ liệu mới cho kênh phải
            end else if (bclk_counter >= 1 && bclk_counter <= 16) begin
                // Truyền 24 bit dữ liệu kênh trái
                dacdat <= left_data[15]; // Output MSB first
                left_data <= {left_data[14:0], 1'b0}; // Shift right
                lrclk <= 0;
            end else if (bclk_counter >= 17 && bclk_counter <= 31) begin
                // 7 bit padding 0 cuối kênh trái
                dacdat <= 0;
                lrclk <= 0;
				end else if (bclk_counter == 32) begin
					 dacdat <= 0;
					 lrclk <= 1;
            /*end else if (bclk_counter == 32) begin
                // BCLK trống đầu tiên của kênh phải
                dacdat <= 0;
                lrclk <= 1; // LRCLK = 0 cho kênh phải*/
            end else if (bclk_counter >= 33 && bclk_counter <= 49) begin
                // Truyền 24 bit dữ liệu kênh phải
                dacdat <= right_data[15]; // Output MSB first
                right_data <= {right_data[14:0], 1'b0}; // Shift right
                lrclk <= 1;
            end else if (bclk_counter >= 50 && bclk_counter <= 64) begin
                // 7 bit padding 0 cuối kênh phải
                dacdat <= 0;
                lrclk <= 1;
            end

            // Cập nhật counter
            if (bclk_counter == 64) begin
                bclk_counter <= 0;
            end else begin
                bclk_counter <= bclk_counter + 1;
            end
        end
    end

endmodule