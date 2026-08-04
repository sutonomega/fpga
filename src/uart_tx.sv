module uart_tx #(
    parameter  int P_CLK_FRE = 27, 
    parameter  int P_BAUD_RATE = 115200
)(
    input  logic       CLK,
    input  logic       RST,
    input  logic       VALID,
    input  logic [7:0] DATA_IN,
    output logic       READY,
    output logic       DATA_OUT
);

//    localparam int L_CYCLE = P_CLK_FRE * 1000000 / P_BAUD_RATE;
    localparam int L_CYCLE = (P_CLK_FRE * 1000000 + P_BAUD_RATE / 2) / P_BAUD_RATE;
    localparam int L_WAIT_LEN  = $clog2((L_CYCLE < 2) ? 2 : L_CYCLE);
    localparam L_START_BIT = 1'b0;
    localparam L_STOP_BIT  = 1'b1;
    localparam L_DATA_LEN  = 10;
    localparam logic [L_WAIT_LEN-1:0] L_WAIT_MAX = L_WAIT_LEN'(L_CYCLE - 1);

    // state
    typedef enum logic[0:0]{
        S_IDLE,
        S_SEND
    } state_type;
    state_type state;

    // logic
    logic            [9:0] data_reg;
    logic [L_WAIT_LEN-1:0] wait_cnt;
    logic            [3:0] bit_cnt;
    logic                  tx_start;
    logic                  tx_end;

    // data out
//    assign DATA_OUT = data_reg[0];
    assign DATA_OUT = (state == S_SEND) ? data_reg[0] : 1'b1;

    // tx control signal
    assign tx_start = VALID && READY;
    assign tx_end   = (wait_cnt == L_WAIT_MAX) && (bit_cnt == L_DATA_LEN - 1);

    //data register
    always_ff @ (posedge CLK) begin
        if (RST) begin
            data_reg <= 10'h3ff;
        end else if (tx_start) begin
            data_reg <= {L_STOP_BIT, DATA_IN, L_START_BIT};
        end else if (state == S_SEND && wait_cnt == L_WAIT_MAX) begin
            data_reg <= {1'b1, data_reg[9:1]};
        end
    end

    // Sequential logic
    always_ff @ (posedge CLK) begin
        if (RST) begin
            state <= S_IDLE;
        end else begin
            case (state)
                S_IDLE: if (tx_start) state <= S_SEND;
                S_SEND: if (tx_end) state <= S_IDLE;
            endcase
        end
    end

    // Ready signal generation
    always_ff @ (posedge CLK) begin
        if (RST) begin
            READY <= 1'b0;
        end else begin
            READY <= (state == S_IDLE);
        end
    end

    //wait counter
    always_ff @ (posedge CLK) begin
        if (RST) begin
            wait_cnt <= 0;
        end else if (state == S_IDLE) begin
            wait_cnt <= 0;
        end else if (wait_cnt == L_WAIT_MAX) begin
            wait_cnt <= 0;
        end else begin
            wait_cnt <= wait_cnt + 1'b1;
        end
    end

    //bit counter
    always_ff @ (posedge CLK) begin
        if (RST) begin
            bit_cnt  <= 4'd0;
        end else if (state == S_IDLE) begin
            bit_cnt <= 4'd0;
        end else begin
            if (wait_cnt == L_WAIT_MAX) begin
                if (bit_cnt == L_DATA_LEN - 1) begin
                    bit_cnt <= 4'd0;
                end else begin
                    bit_cnt <= bit_cnt + 1'b1;
                end
            end
        end
    end

endmodule
