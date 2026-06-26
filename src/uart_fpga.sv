module uart_fpga (
    input  logic CLK,
    input  logic RST,
    output logic TXD
);

    localparam int L_LAST_BYTE = 11;

    typedef enum logic [1:0] {
        STATE_SEND,
        STATE_WAIT,
        STATE_FIN
    } state_type;

    state_type state;

    logic       valid;
    logic       ready;
    logic [7:0] data_in;
    logic [3:0] byte_cnt; // current byte index
    logic       ready_sf;
    logic       send_fin;

    uart_tx #(
        .P_WAIT_DIV(868)
    ) u_uart_tx (
        .CLK      (CLK),
        .RST      (RST),
        .VALID    (valid),
        .DATA_IN  (data_in),
        .READY    (ready),
        .DATA_OUT (TXD)
    );

    // set valid
    assign valid = (state == STATE_SEND);

    // set data_in
    always_comb begin
        case (byte_cnt)
            4'd0 : data_in = 8'h48; // H
            4'd1 : data_in = 8'h65; // e
            4'd2 : data_in = 8'h6c; // l
            4'd3 : data_in = 8'h6c; // l
            4'd4 : data_in = 8'h6f; // o
            4'd5 : data_in = 8'h2c; // ,
            4'd6 : data_in = 8'h20; // space
            4'd7 : data_in = 8'h46; // F
            4'd8 : data_in = 8'h50; // P
            4'd9 : data_in = 8'h47; // G
            4'd10: data_in = 8'h41; // A
            4'd11: data_in = 8'h0a; // \n
            default: data_in = 8'h00;
        endcase
    end

    // state
    always_ff @(posedge CLK) begin
        if (RST) begin
            state <= STATE_SEND;
        end else begin
            case (state)
                STATE_SEND: begin
                    if (ready) begin
                        state <= STATE_WAIT;
                    end
                end

                STATE_WAIT: begin
                    if (send_fin) begin
                        if (byte_cnt == 4'(L_LAST_BYTE)) begin
                            state <= STATE_FIN;
                        end else begin
                            state <= STATE_SEND;
                        end
                    end
                end

                STATE_FIN: begin
                    state <= STATE_FIN;
                end

                default: begin
                    state <= STATE_FIN;
                end
            endcase
        end
    end

    // ready rising edge detect
    always_ff @(posedge CLK) begin
        if (RST) begin
            ready_sf  <= 1'b0;
            send_fin  <= 1'b0;
        end else begin
            ready_sf <= ready;
            send_fin <= (state == STATE_WAIT) && ready && ~ready_sf;
        end
    end

    // byte counter
    always_ff @(posedge CLK) begin
        if (RST) begin
            byte_cnt <= 4'd0;
        end else if (send_fin && state == STATE_WAIT && byte_cnt != 4'd11) begin
            byte_cnt <= byte_cnt + 1'b1;
        end
    end

endmodule
