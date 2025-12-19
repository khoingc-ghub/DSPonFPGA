module fir(
    input  wire clk, rst_n,
    input  wire new_data,
    input  wire signed [15:0] x_in,

    output reg signed [15:0] y_out
);

    //=====================================================
    // COEFF (hex file)
    //=====================================================
    reg signed [15:0] c [0:99];
    initial $readmemh("coeff.hex", c);

    //=====================================================
    // AREG
    //=====================================================
    reg signed [15:0] Areg [0:99];
    integer i;

    //=====================================================
    // MULTIPLIER INPUT REGISTER (25 DSP)
    //=====================================================
    reg signed [15:0] mult_a_reg [0:24];
    reg signed [15:0] mult_b_reg [0:24];
    wire signed [31:0] mult_out [0:24];

    generate
        genvar g;
        for (g=0; g<25; g=g+1) begin : GEN_MULT
            assign mult_out[g] = mult_a_reg[g] * mult_b_reg[g];
        end
    endgenerate

    //=====================================================
    // Mreg = 100 kết quả nhân
    //=====================================================
    reg signed [31:0] Mreg [0:99];

    //=====================================================
    // SUM PIPELINE
    //=====================================================
    reg signed [31:0] P [0:99];

    //=====================================================
    // FSM STATES
    //=====================================================
    reg [2:0] state;
    localparam IDLE     = 3'd0;
    localparam LOAD     = 3'd1;
    localparam MULT0    = 3'd2;
    localparam MULT1    = 3'd3;
    localparam MULT2    = 3'd4;
    localparam MULT3    = 3'd5;
    localparam SUM_CALC = 3'd6;
    localparam SUM_OUT  = 3'd7;

    //=====================================================
    // MAIN FSM
    //=====================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            y_out <= 0;

            for (i=0;i<100;i=i+1) begin
                Areg[i] <= 0;
                Mreg[i] <= 0;
                P[i]    <= 0;
            end
            for (i=0;i<25;i=i+1) begin
                mult_a_reg[i] <= 0;
                mult_b_reg[i] <= 0;
            end
        end 
        else begin
            case (state)

                //----------------------------------------
                // IDLE
                //----------------------------------------
                IDLE: begin
                    if (new_data) begin
                        for (i=0; i<100; i=i+1)
                            Areg[i] <= x_in;

                        state <= LOAD;
                    end
                end

                //----------------------------------------
                // LOAD phase 0 (tap 0..24)
                //----------------------------------------
                LOAD: begin
                    for (i=0; i<25; i=i+1) begin
                        mult_a_reg[i] <= Areg[i];
                        mult_b_reg[i] <= c[i];
                    end
                    state <= MULT0;
                end

                //----------------------------------------
                // MULT phase 0 -> save taps 0..24
                //----------------------------------------
                MULT0: begin
                    for (i=0;i<25;i=i+1)
                        Mreg[i] <= mult_out[i];

                    // Prepare next segment
                    for (i=0;i<25;i=i+1) begin
                        mult_a_reg[i] <= Areg[i+25];
                        mult_b_reg[i] <= c[i+25];
                    end

                    state <= MULT1;
                end

                //----------------------------------------
                // MULT phase 1 -> save taps 25..49
                //----------------------------------------
                MULT1: begin
                    for (i=0;i<25;i=i+1)
                        Mreg[i+25] <= mult_out[i];

                    // Prepare next segment
                    for (i=0;i<25;i=i+1) begin
                        mult_a_reg[i] <= Areg[i+50];
                        mult_b_reg[i] <= c[i+50];
                    end

                    state <= MULT2;
                end

                //----------------------------------------
                // MULT phase 2 -> save taps 50..74
                //----------------------------------------
                MULT2: begin
                    for (i=0;i<25;i=i+1)
                        Mreg[i+50] <= mult_out[i];

                    for (i=0;i<25;i=i+1) begin
                        mult_a_reg[i] <= Areg[i+75];
                        mult_b_reg[i] <= c[i+75];
                    end

                    state <= MULT3;
                end

                //----------------------------------------
                // MULT phase 3 -> save taps 75..99
                //----------------------------------------
                MULT3: begin
                    for (i=0;i<25;i=i+1)
                        Mreg[i+75] <= mult_out[i];

                    state <= SUM_CALC;
                end

                //----------------------------------------
                // SUM PHASE 1: tính toàn bộ P[i]
                //----------------------------------------
                SUM_CALC: begin
                    P[99] <= Mreg[99];
                    for (i=98;i>=0;i=i-1)
                        P[i] <= P[i+1] + Mreg[i];

                    state <= SUM_OUT;
                end

                //----------------------------------------
                // SUM PHASE 2: output
                //----------------------------------------
                SUM_OUT: begin
                    y_out <= P[0] >>> 15;
                    state <= IDLE;
                end

            endcase
        end
    end

endmodule
