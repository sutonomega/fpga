module tb_uart_if ();
    // clock and reset parameters
    localparam int L_CLK_PERIOD = 20;
    localparam int L_RST_TIME   = 20;

    // UART divider parameter
    localparam int L_WAIT_DIV = 868;
    localparam int L_BIT_TIME = L_WAIT_DIV * L_CLK_PERIOD;

    // UART timing parameters
    localparam int L_VALID_DELAY = 120;

    // Simulation time
    localparam int L_MARGIN_CYCLES = 1000;
    localparam int L_START_BITS    = 1;
    localparam int L_DATA_BITS     = 8;
    localparam int L_STOP_BITS     = 1;
    localparam int L_UART_BITS     = L_START_BITS + L_DATA_BITS + L_STOP_BITS;
    localparam int L_TEST_BYTES    = 12; // "Hello, FPGA\n"

    // Since `uart_if` transmits after receiving, you need to wait about twice as long.
    localparam int L_SIM_CYCLES = L_TEST_BYTES * L_UART_BITS * L_WAIT_DIV * 2 + L_MARGIN_CYCLES;

    // Signals
    logic       CLK;
    logic       RST;

    logic       TX_VALID;
    /* verilator lint_off UNUSEDSIGNAL */
    logic       TX_READY;
    /* verilator lint_on UNUSEDSIGNAL */
    logic [7:0] TX_DATA;

    logic       UART_IF_RXD;
    logic       UART_IF_TXD;

    // UUT: UART echo back
    uart_if #(
        .P_WAIT_DIV(L_WAIT_DIV)
    ) u_uart_if (
        .CLK (CLK),
        .RST (RST),
        .RXD (UART_IF_RXD),
        .TXD (UART_IF_TXD)
    );

    // A model that generates the byte sequence to be transmitted.
    uart_tx_model #(
        .P_VALID_DELAY(L_VALID_DELAY)
    ) u_uart_tx_model (
        .CLK   (CLK),
        .READY    (TX_READY),
        .VALID (TX_VALID),
        .DATA  (TX_DATA)
    );

    // Convert input data into a UART waveform.
    uart_tx #(
        .P_WAIT_DIV(L_WAIT_DIV)
    ) u_uart_tx_sim (
        .CLK      (CLK),
        .RST      (RST),
        .VALID    (TX_VALID),
        .DATA_IN  (TX_DATA),
        .READY    (TX_READY),
        .DATA_OUT (UART_IF_RXD)
    );

    // Read the 1-bit TXD line of the uart_if and compare it against the expected value.
    uart_line_rx_model #(
        .P_BIT_TIME(L_BIT_TIME)
    ) u_uart_line_rx_model (
        .RST (RST),
        .RXD (UART_IF_TXD)
    );

    gen_clk #(
        .P_CLK_PERIOD(L_CLK_PERIOD)
    ) u_gen_clk (
        .CLK(CLK)
    );

    gen_rst #(
        .P_RST_TIME(L_RST_TIME)
    ) u_gen_rst (
        .RST(RST)
    );

    initial begin
        u_uart_tx_model.push_tx_string("Hello, FPGA\n");
        t_push_exp_string("Hello, FPGA\n");

        repeat (L_SIM_CYCLES) begin
            @(posedge CLK);
        end

        $finish;
    end

    task automatic t_push_exp_string(input string str);
        for (int i = 0; i < str.len(); i++) begin
            u_uart_line_rx_model.push_exp_data(str.getc(i));
        end
    endtask

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_uart_if);
    end

endmodule
