module tb_uart_rx ();
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
    // Simulation time
    localparam int L_MARGIN_CYCLES = 500;
    localparam int L_START_BITS    = 1;
    localparam int L_DATA_BITS     = 8;
    localparam int L_STOP_BITS     = 1;
    localparam int L_UART_BITS     = L_START_BITS + L_DATA_BITS + L_STOP_BITS;
    localparam int L_SIM_CYCLES    = L_UART_BITS * L_WAIT_DIV + L_MARGIN_CYCLES;

    // Signals
    logic       CLK;
    logic       RST;
    logic       TX_VALID;
    logic       TX_READY;
    logic [7:0] TX_DATA;
    logic       RX_VALID;
    logic       RX_READY;
    logic [7:0] RX_DATA;
    logic       UART_DATA;

    assign RX_READY = 1'b1;

    //UUT
    uart_rx # (
        .P_WAIT_DIV(L_WAIT_DIV)
    )
    u_uart_rx (
        .CLK(CLK),
        .RST(RST),
        .READY(RX_READY),
        .DATA_IN(UART_DATA),
        .VALID(RX_VALID),
        .DATA_OUT(RX_DATA)
    );

    uart_tx # (
        .P_WAIT_DIV(L_WAIT_DIV)
    )
    u_uart_tx (
        .CLK(CLK),
        .RST(RST),
        .VALID(TX_VALID),
        .DATA_IN(TX_DATA),
        .READY(TX_READY),
        .DATA_OUT(UART_DATA)
    );

    //module
    uart_tx_model #(
        .P_CLK_PERIOD(L_CLK_PERIOD),
        .P_VALID_DELAY(L_VALID_DELAY),
        .P_VALID_WIDTH(L_VALID_WIDTH)
    )
    u_uart_tx_model (
        .CLK(CLK),
        .VALID(TX_VALID),
        .DATA(TX_DATA)
    );

    //module
    uart_data_rx_model u_uart_data_rx_model (
        .RST(RST),
        .VALID(RX_VALID),
        .DATA(RX_DATA)
    );

    gen_clk #(
        .P_CLK_PERIOD(L_CLK_PERIOD)
    )
    u_gen_clk (
        .CLK(CLK)
    );

    gen_rst #(
        .P_RST_TIME(L_RST_TIME)
    )
    u_gen_rst (
        .RST(RST)
    );

    initial begin
        u_uart_data_rx_model.push_exp_data(8'h41);
        wait (TX_READY === 1'b0); // Start transmission
        wait (TX_READY === 1'b1); // Transmission completed
        repeat (L_SIM_CYCLES) wait_cmp();

        $finish;
    end

    task automatic wait_cmp();
        @(posedge CLK);
        #L_CMP_DELAY;
    endtask

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_uart_rx);
    end

endmodule




