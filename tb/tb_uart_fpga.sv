module tb_uart_fpga ();

    // clock and reset parameters
    localparam int L_CLK_PERIOD = 20;
    localparam int L_RST_TIME   = 20;

    // uart_fpga uses P_WAIT_DIV = 868
    localparam int L_WAIT_DIV = 868;
    localparam int L_BIT_TIME = L_WAIT_DIV * L_CLK_PERIOD;

    // message parameters
    localparam int L_EXP_BYTES = 12;
    localparam int L_START_BITS    = 1;
    localparam int L_DATA_BITS     = 8;
    localparam int L_STOP_BITS     = 1;
    localparam int L_UART_BITS     = L_START_BITS + L_DATA_BITS + L_STOP_BITS;

    // simulation time
    localparam int L_MARGIN_CYCLES = 1000;
    localparam int L_SIM_CYCLES    = (L_EXP_BYTES * L_UART_BITS * L_WAIT_DIV) + L_MARGIN_CYCLES;

    // signals
    logic CLK;
    logic RST;
    logic TXD;

    // UUT
    uart_fpga uart_fpga (
        .CLK (CLK),
        .RST (RST),
        .TXD (TXD)
    );

    // clock generator
    gen_clk #(
        .P_CLK_PERIOD(L_CLK_PERIOD)
    ) gen_clk (
        .CLK(CLK)
    );

    // reset generator
    gen_rst #(
        .P_RST_TIME(L_RST_TIME)
    ) gen_rst (
        .RST(RST)
    );

    // UART RX model
    uart_line_rx_model #(
        .P_BIT_TIME (L_BIT_TIME)
    ) uart_line_rx_model (
        .RST(RST),
        .RXD(TXD)
    );

    initial begin
        push_exp_string("Hello, FPGA\n");

        repeat (L_SIM_CYCLES) begin
            @(posedge CLK);
        end

        $finish;
    end

    initial begin
        $dumpfile("dump_uart_fpga.vcd");
        $dumpvars(0, tb_uart_fpga);
    end

    task automatic push_exp_string(input string str);
        for (int i = 0; i < str.len(); i++) begin
            uart_line_rx_model.push_exp_data(str.getc(i));
        end
    endtask

endmodule
