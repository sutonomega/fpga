module uart_if #(
    parameter int P_WAIT_DIV = 868
)(
    input  logic CLK,
    input  logic RST,
    input  logic RXD,
    output logic TXD
);

    // logic
    logic       rx_valid;
    logic       tx_ready;
    logic [7:0] rx_data;

    // uart_tx
    uart_tx #(
        .P_WAIT_DIV(P_WAIT_DIV)
    ) u_uart_tx (
        .CLK      (CLK),
        .RST      (RST),
        .VALID    (rx_valid),
        .DATA_IN  (rx_data),
        .READY    (tx_ready),
        .DATA_OUT (TXD)
    );

    // uart_rx
    uart_rx #(
        .P_WAIT_DIV(P_WAIT_DIV)
    ) u_uart_rx (
        .CLK      (CLK),
        .RST      (RST),
        .READY    (tx_ready),
        .DATA_IN  (RXD),
        .VALID    (rx_valid),
        .DATA_OUT (rx_data)
    );

endmodule
