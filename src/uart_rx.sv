module uart_rx #(
    parameter int P_WAIT_DIV = 5
)(
    input  logic       CLK,
    input  logic       RST,
    input  logic       READY,
    input  logic       DATA_IN,
    output logic       VALID,
    output logic [7:0] DATA_OUT
);

    localparam int L_WAIT_LEN  = $clog2((P_WAIT_DIV < 2) ? 2 : P_WAIT_DIV);
    localparam int L_DATA_LEN  = 10;
    localparam logic [L_WAIT_LEN-1:0] L_WAIT_MAX  = L_WAIT_LEN'(P_WAIT_DIV - 1);
    localparam logic [L_WAIT_LEN-1:0] L_WAIT_HALF = L_WAIT_LEN'((P_WAIT_DIV - 1) / 2);

    // state
    typedef enum logic[0:0] {
        S_IDLE,
        S_RECEIVE
    } state_type;
    state_type           state;

    // logic
    logic            [9:0] data_reg;
    logic [L_WAIT_LEN-1:0] wait_cnt;
    logic            [3:0] bit_cnt;
    logic                  rx_end;

    // data out
    assign DATA_OUT = data_reg[8:1];

    // rx control signal
    assign rx_end   = (wait_cnt == L_WAIT_MAX) && (bit_cnt == 4'(L_DATA_LEN - 1));

    //data register
    always_ff @ (posedge CLK) begin
        if (RST) begin
            data_reg <= 10'h3ff;
        end else if (state == S_RECEIVE && wait_cnt == L_WAIT_HALF) begin
            data_reg <= {DATA_IN, data_reg[9:1]};
        end
    end

    // Sequential logic
    always_ff @ (posedge CLK) begin
        if (RST) begin
            state <= S_IDLE;
        end else begin
            case (state)
                S_IDLE:    if (!VALID && ~DATA_IN) state <= S_RECEIVE;
                S_RECEIVE: if (rx_end)             state <= S_IDLE;
                default:                           state <= S_IDLE;
            endcase
        end
    end

    // Valid signal generation
    always_ff @(posedge CLK) begin
        if (RST) begin
            VALID <= 1'b0;
        end else if (VALID && READY) begin
            VALID <= 1'b0;
        end else if (rx_end && data_reg[9] && !data_reg[0]) begin
            VALID <= 1'b1;
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
                if (bit_cnt == 4'(L_DATA_LEN - 1)) begin
                    bit_cnt <= 4'd0;
                end else begin
                    bit_cnt <= bit_cnt + 1'b1;
                end
            end
        end
    end

endmodule
