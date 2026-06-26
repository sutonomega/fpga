module uart_master #(
    parameter int P_CLK_PERIOD  = 20,
    parameter int P_VALID_DELAY = 60,
    parameter int P_VALID_WIDTH = 20
)(
    input  logic CLK,
    output logic VALID,
    output logic [7:0] DATA_IN
);
    localparam int L_VALID_DELAY_CYCLES = P_VALID_DELAY / P_CLK_PERIOD;
    localparam int L_VALID_WIDTH_CYCLES = P_VALID_WIDTH / P_CLK_PERIOD;

    initial begin
        VALID   = 1'b0;
        DATA_IN = 8'hx;

        repeat (L_VALID_DELAY_CYCLES) @(posedge CLK);

        VALID   = 1'b1;
        DATA_IN = 8'h41;

        repeat (L_VALID_WIDTH_CYCLES) @(posedge CLK);

        VALID   = 1'b0;
        DATA_IN = 8'hx;
    end
endmodule
