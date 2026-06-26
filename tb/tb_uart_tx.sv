module tb_uart_tx ();
    // clock and reset parameters
    localparam int L_CLK_PERIOD = 20;
    localparam int L_RST_TIME   = 20;
    // Comparison delay parameter
    localparam int L_CMP_DELAY = L_CLK_PERIOD * 8 / 10;
    // UART divider parameter
    localparam int L_WAIT_DIV = 5;
    // UART timing parameters
    localparam int L_VALID_DELAY = 60;
    localparam int L_VALID_WIDTH = 20;
    localparam int L_BIT_TIME    = L_WAIT_DIV * L_CLK_PERIOD;
    // Simulation time
    localparam int L_MARGIN_CYCLES = 500;
    localparam int L_START_BITS    = 1;
    localparam int L_DATA_BITS     = 8;
    localparam int L_STOP_BITS     = 1;
    localparam int L_UART_BITS     = L_START_BITS + L_DATA_BITS + L_STOP_BITS;
    localparam int L_SIM_CYCLES    = L_UART_BITS * L_WAIT_DIV + L_MARGIN_CYCLES;

    // Signals
    logic       CLK, RST;
    logic       VALID;
    logic       READY;
    logic [7:0] DATA_IN;
    logic       DATA_OUT;

    //UUT
    uart_tx # (
        .P_WAIT_DIV(L_WAIT_DIV)
    )
    uart_tx (
        .CLK(CLK),
        .RST(RST),
        .VALID(VALID),
        .DATA_IN(DATA_IN),
        .READY(READY),
        .DATA_OUT(DATA_OUT)
    );

    //module
    uart_tx_model #(
        .P_CLK_PERIOD(L_CLK_PERIOD),
        .P_VALID_DELAY(L_VALID_DELAY),
        .P_VALID_WIDTH(L_VALID_WIDTH)
    ) uart_tx_model (
        .CLK(CLK),
        .VALID(VALID),
        .DATA(DATA_IN)
    );

    gen_clk #(
        .P_CLK_PERIOD(L_CLK_PERIOD)
    ) gen_clk (
        .CLK(CLK)
    );

    gen_rst #(
        .P_RST_TIME(L_RST_TIME)
    ) gen_rst (
        .RST(RST)
    );

    uart_line_rx_model #(
        .P_BIT_TIME(L_BIT_TIME)
    ) uart_line_rx_model (
        .RST(RST),
        .RXD(DATA_OUT)
    );

    initial begin
        uart_line_rx_model.push_exp_data(8'h41);

        // Wait for "READY" to drop when sending begins.
        wait (READY === 1'b0);

        // Wait for "READY" to be returned upon completion of transmission.
        wait (READY === 1'b1);

        repeat (L_SIM_CYCLES) wait_cmp();

        $finish;
    end

    task automatic wait_cmp();
        @(posedge CLK);
        #L_CMP_DELAY;
    endtask

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_uart_tx);
    end

endmodule




