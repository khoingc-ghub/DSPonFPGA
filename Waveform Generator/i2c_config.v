module i2c_config (
    input wire clk, // 50 MHz system clock
    input wire rst_n,
    output reg i2c_sclk,
    inout wire i2c_sdat,
    output reg i2c_done // Tín hiệu báo hoàn tất cấu hình
);
    // ========================
    // I2C parameters
    // ========================
    localparam I2C_DEV_ADDR = 7'h1A; // WM8731
    // Config data: {reg[6:0], rsvd[1], data[8]}
    reg [15:0] commands [0:9];
    initial begin
        commands[0] = {7'h0F, 1'b0, 8'h00}; // Reset
        commands[1] = {7'h06, 1'b0, 8'h10}; // Power: DAC off
		  commands[2] = {7'h02, 1'b0, 8'h79}; // LHP volume
        commands[3] = {7'h03, 1'b0, 8'h79}; // RHP volume
        commands[4] = {7'h07, 1'b0, 8'h0A}; // Format: I2s, 24-bit, slave
        commands[5] = {7'h08, 1'b0, 8'h00}; // Sample Ctrl: 48 kHz, 256fs
		  commands[6] = {7'h04, 1'b0, 8'h12}; // Analog Path
		  commands[7] = {7'h05, 1'b0, 8'h00}; // Digital Path
		  commands[8] = {7'h09, 1'b0, 8'h01}; // Active 
		  commands[9] = {7'h06, 1'b0, 8'h67}; // Power: DAC on
    end
    // ========================
    // Clock divider (~100kHz)
    // ========================
    localparam DIV_MAX = 250; // 50MHz / (2*250) = 100 kHz
    reg [8:0] div_cnt;
    reg i2c_clk_en;
    always @(posedge clk) begin
        if (!rst_n) begin
            div_cnt <= 0;
            i2c_clk_en <= 0;
        end else begin
            if (div_cnt == DIV_MAX-1) begin
                div_cnt <= 0;
                i2c_clk_en <= 1;
            end else begin
                div_cnt <= div_cnt + 1;
		i2c_clk_en <= 0;
            end
        end
    end
    // ========================
    // FSM for I2C write
    // ========================
    reg [5:0] bit_cnt;
    reg [23:0] shift_reg;
    reg [3:0] reg_idx;
    reg [3:0] state;
    reg sdat_out;
    reg sdat_oe;
    assign i2c_sdat = sdat_oe ? sdat_out : 1'bz;

    always @(posedge clk) begin
        if (!rst_n) begin
            i2c_sclk <= 1;
            sdat_out <= 1;
            sdat_oe <= 0;
            state <= 0;
            bit_cnt <= 0;
            reg_idx <= 0;
            shift_reg <= 0;
            i2c_done <= 0;
        end else if (i2c_clk_en) begin
            case (state)
                0: begin
                    // Idle -> Start
                    sdat_out <= 1;
                    sdat_oe <= 1;
                    i2c_sclk <= 1;
                    i2c_done <= 0;
                    state <= 1;
                end
                1: begin
                    // START condition
                    sdat_out <= 0;
                    i2c_sclk <= 1;
                    shift_reg <= {I2C_DEV_ADDR, 1'b0, commands[reg_idx]}; // Load 24-bit frame
                    bit_cnt <= 23;
                    state <= 2;
                end
                2: begin
                    // Send bit (SCL low phase)
                    i2c_sclk <= 0;
						  sdat_oe <= 1;
                    sdat_out <= shift_reg[23];
                    shift_reg <= {shift_reg[22:0], 1'b0};
                    state <= 3;
                end
                3: begin
                    // SCL high phase
                    i2c_sclk <= 1;
                    if (bit_cnt == 16 || bit_cnt == 8 || bit_cnt == 0) begin
                        // Wait for ACK after 8th, 16th, and 24th bit
                        //sdat_oe <= 0; // Release SDAT for ACK
                        state <= 4;
                    end else begin
                        bit_cnt <= bit_cnt - 1;
                        state <= 2;
                    end
                end
                4: begin
                    // ACK phase (SCL low)
                    i2c_sclk <= 0;
						  sdat_oe <= 0; // Release SDAT for ACK
                    state <= 5;
                end
                5: begin
                    // ACK phase (SCL high)
                    i2c_sclk <= 1;
                    //sdat_oe <= 1; // Reclaim SDAT for next bits
                    if (bit_cnt == 16) begin
                        bit_cnt <= 15; // Continue after first ACK (address)
                        state <= 2;
                    end else if (bit_cnt == 8) begin
                        bit_cnt <= 7; // Continue after second ACK (data bits 15-8)
                        state <= 2;
                    end else if (bit_cnt == 0) begin
                        state <= 6; // Move to STOP after third ACK (data bits 7-0)
                    end
                end
                6: begin
                    // STOP condition (SCL low)
                    i2c_sclk <= 0;
                    sdat_out <= 0;
                    state <= 7;
                end
                7: begin
                    // STOP condition (SCL high)
                    i2c_sclk <= 1;
                    sdat_out <= 1;
                    if (reg_idx < 9) begin
                        reg_idx <= reg_idx + 1;
                        state <= 1; // Start next command
                    end else begin
                        i2c_done <= 1; // Set i2c_done when all commands are sent
                        state <= 8; // Done
                    end
                end
                8: begin
                    // DONE, hold bus idle
                    i2c_sclk <= 1;
                    sdat_out <= 1;
                    sdat_oe <= 0;
                    i2c_done <= 1;
                end
                default: begin
                    state <= 0;
                    i2c_done <= 0;
                end
            endcase
        end
    end
endmodule