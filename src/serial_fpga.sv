module serial_fpga (
    input  logic CLK, RST,
    output logic TXD);

    typedef enum {
        STATE_SEND,
        STATE_WAIT,
        STATE_FIN
    } state_type;
    state_type  state, n_state;
    logic       we;
    logic       busy;
    logic [7:0] data_in;
    logic [3:0] byte_cnt, n_byte_cnt;

    serial_send # (
            .WAIT_DIV(868))
        ser (
            .CLK(CLK),
            .RST(RST),
            .DATA_IN(data_in),
            .WE(we),
            .DATA_OUT(TXD),
            .BUSY(busy));
    
    always_comb begin
        case (byte_cnt)
            4'd0 : data_in = 8'h48; // H
            4'd1 : data_in = 8'h65; // e
            4'd2 : data_in = 8'h6c; // l
            4'd3 : data_in = 8'h6c; // l
            4'd4 : data_in = 8'h6f; // o
            4'd5 : data_in = 8'h2c; // ,
            4'd6 : data_in = 8'h20; //  
            4'd7 : data_in = 8'h46; // F
            4'd8 : data_in = 8'h50; // P
            4'd9 : data_in = 8'h47; // G
            4'd10: data_in = 8'h41; // A
            4'd11: data_in = 8'h0a; // \n
            default: data_in = 8'h00;
        endcase
    end

    always_comb begin
        n_state    = state;
        n_byte_cnt = byte_cnt;
        we         = 1'b0;
        if (state == STATE_SEND) begin
            n_state    = STATE_WAIT;
            we         = 1'b1;
        end else if (state == STATE_WAIT) begin
            if (~ busy) begin
                if (byte_cnt == 4'd11) begin
                    n_state    = STATE_FIN;
                end else begin
                    n_state    = STATE_SEND;
                    n_byte_cnt = byte_cnt + 1'b1;
                end
            end
        end
    end

    always_ff @ (posedge CLK) begin
        if (RST) begin
            state    <= STATE_SEND;
            byte_cnt <= 4'd0;
        end else begin
            state    <= n_state;
            byte_cnt <= n_byte_cnt;
        end
    end
endmodule
