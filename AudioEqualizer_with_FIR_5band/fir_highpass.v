module fir_highpass(
    input  wire clk, rst_n,
    input  wire new_data,
    input  wire signed [15:0] x_in,
    output reg  signed [15:0] y_out
);

    //=======================
    // COEFF (0..300)
    //=======================
    localparam N_TAP  = 101;
    localparam N_MUL  = 20;
    localparam N_STAGE = 16;   // ceil(301/20) = 16 (15*20 = 300, stage 15 xử lý tap 300)

    reg signed [15:0] c [0:N_TAP-1];
    initial $readmemh("coeff_5.hex", c);

    //=======================
    // Shift Register Input
    //=======================
    reg signed [15:0] Areg [0:N_TAP-1];
    integer i;

    //=======================
    // MULTIPLIER (20 DSP)
    //=======================
    reg signed [15:0]  mult_a_reg [0:N_MUL-1];
    reg signed [15:0]  mult_b_reg [0:N_MUL-1];
    wire signed [31:0] mult_out    [0:N_MUL-1];

    generate
        genvar g;
        for (g=0; g<N_MUL; g=g+1) begin : GEN_MUL
            assign mult_out[g] = mult_a_reg[g] * mult_b_reg[g];
        end
    endgenerate

    //=======================
    // Mreg + Sum pipeline
    //=======================
    reg signed [31:0] Mreg [0:N_TAP-1];
    reg signed [31:0] P    [0:N_TAP-1];

    //=======================
    // FSM
    //=======================
    reg [4:0] stage_idx;
    reg [3:0] state;

    localparam IDLE     = 0;
    localparam LOAD     = 1;
    localparam MULT     = 2;
    localparam SUM_CALC = 3;
    localparam SUM_OUT  = 4;

    //=======================
    // MAIN FSM
    //=======================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            y_out <= 0;
            stage_idx <= 0;

            for (i=0;i<N_TAP;i=i+1) begin
                Areg[i] <= 0;
                Mreg[i] <= 0;
                P[i]    <= 0;
            end

            for (i=0;i<N_MUL;i=i+1) begin
                mult_a_reg[i] <= 0;
                mult_b_reg[i] <= 0;
            end
        end
        else begin
            case (state)

            //--------------------------------------------------
            // IDLE
            //--------------------------------------------------
            IDLE: begin
                if (new_data) begin
                    for (i=0;i<N_TAP;i=i+1)
                        Areg[i] <= x_in;

                    stage_idx <= 0;
                    state <= LOAD;
                end
            end

            //--------------------------------------------------
            // LOAD stage 0
            //--------------------------------------------------
            LOAD: begin
                for (i=0;i<N_MUL;i=i+1) begin
                    mult_a_reg[i] <= Areg[i];
                    mult_b_reg[i] <= c[i];
                end

                stage_idx <= 0;
                state <= MULT;
            end

            //--------------------------------------------------
            // MULT — chạy 16 stage
            //--------------------------------------------------
            MULT: begin
                // lưu stage hiện tại
                for (i=0;i<N_MUL;i=i+1) begin
                    if (stage_idx*N_MUL + i < N_TAP)
                        Mreg[stage_idx*N_MUL + i] <= mult_out[i];
                end

                if (stage_idx == N_STAGE-1) begin
                    state <= SUM_CALC;
                end
                else begin
                    stage_idx <= stage_idx + 1;

                    // nạp data stage tiếp
                    for (i=0;i<N_MUL;i=i+1) begin
                        if ((stage_idx+1)*N_MUL + i < N_TAP) begin
                            mult_a_reg[i] <= Areg[(stage_idx+1)*N_MUL + i];
                            mult_b_reg[i] <= c   [(stage_idx+1)*N_MUL + i];
                        end
                        else begin
                            mult_a_reg[i] <= 0;
                            mult_b_reg[i] <= 0;
                        end
                    end
                end
            end

            //--------------------------------------------------
            // SUM
            //--------------------------------------------------
            SUM_CALC: begin
                P[N_TAP-1] <= Mreg[N_TAP-1];
                for (i=N_TAP-2; i>=0; i=i-1)
                    P[i] <= P[i+1] + Mreg[i];

                state <= SUM_OUT;
            end

            //--------------------------------------------------
            // OUTPUT
            //--------------------------------------------------
            SUM_OUT: begin
                y_out <= P[0] >>> 15;
                state <= IDLE;
            end

            endcase
        end
    end

endmodule
