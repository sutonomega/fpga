module tb_uart_tx ();
    // clock and reset parameters
    localparam int L_CLK_PERIOD = 20;
    localparam int L_RST_TIME   = 20;
    // Comparison delay parameter
    localparam int L_CMP_DELAY = L_CLK_PERIOD * 8 / 10;
    // UART divider parameter
    localparam int L_WAIT_DIV = 5;
    // UART timing parameters
    localparam int L_VALID_DELAY = 20;
    localparam int L_VALID_WIDTH = 20;
    localparam int L_ACCEPT_TIME = L_VALID_DELAY + L_VALID_WIDTH;
    localparam int L_BIT_TIME    = L_WAIT_DIV * L_CLK_PERIOD;
    // Simulation time
    localparam int L_MARGIN_CYCLES = 100;
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

    // Expected values
    logic       exp_ready;
    logic       exp_data_out;

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
    master #(
        .P_VALID_DELAY(L_VALID_DELAY),
        .P_VALID_WIDTH(L_VALID_WIDTH)
    ) master (
        .CLK(CLK),
        .VALID(VALID),
        .DATA_IN(DATA_IN)
    );

    gen_clk #(
        .P_CLK_PERIOD(L_CLK_PERIOD)
    ) gen_clk (
            .CLK(CLK)
    );

    gen_ret #(
        .P_RST_TIME(L_RST_TIME)
    ) gen_ret (
            .RST(RST)
    );

    gen_exp #(
        .P_ACCEPT_TIME(L_ACCEPT_TIME),
        .P_BIT_TIME(L_BIT_TIME),
        .P_RST_TIME(L_RST_TIME)
    ) gen_exp (
            .CLK(CLK),
            .exp_ready(exp_ready),
            .exp_data_out(exp_data_out)
    );

    initial begin
        repeat (L_SIM_CYCLES) begin
            wait_cmp();
            if (READY !== exp_ready) begin
                $display("Error: READY mismatch at time %0t, expected %b, value %b", $time, exp_ready, READY);
            end
            if (DATA_OUT !== exp_data_out) begin
                $display("Error: DATA_OUT mismatch at time %0t, expected %b, value %b", $time, exp_data_out, DATA_OUT);
            end
        end

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

module gen_exp #(
    parameter int P_ACCEPT_TIME = 80,
    parameter int P_BIT_TIME    = 100,
    parameter int P_RST_TIME = 20
)(
    input  logic  CLK,
    output logic  exp_ready,
    output logic  exp_data_out
);
    initial begin
        exp_ready    = 1'b0;
        #P_RST_TIME;
        @(posedge CLK);
        exp_ready    = 1'b1;
        #P_ACCEPT_TIME;
        exp_ready    = 1'b0;
        repeat(10) #P_BIT_TIME;
        exp_ready    = 1'b1;
    end
    initial begin
        exp_data_out = 1'b1;
        #P_RST_TIME;
        repeat (2) @(posedge CLK);
        exp_data_out = 1'b0;
        #P_BIT_TIME;
        exp_data_out = 1'b1;
        #P_BIT_TIME;
        exp_data_out = 1'b0;
        #P_BIT_TIME;
        exp_data_out = 1'b0;
        #P_BIT_TIME;
        exp_data_out = 1'b0;
        #P_BIT_TIME;
        exp_data_out = 1'b0;
        #P_BIT_TIME;
        exp_data_out = 1'b0;
        #P_BIT_TIME;
        exp_data_out = 1'b1;
        #P_BIT_TIME;
        exp_data_out = 1'b0;
        #P_BIT_TIME;
        exp_data_out = 1'b1;
        #P_BIT_TIME;
        exp_data_out = 1'b1;
    end
endmodule

module master #(
    parameter int P_VALID_DELAY = 60,
    parameter int P_VALID_WIDTH = 20
)(
    input  logic CLK,
    output logic VALID,
    output logic [7:0] DATA_IN
);
    initial begin
        VALID = 1'b0;
        DATA_IN = 8'hx;
        repeat (3) @(posedge CLK);
        VALID = 1'b1;
        DATA_IN = 8'h41;
        #P_VALID_WIDTH;
        VALID = 1'b0;
        DATA_IN = 8'hx;
    end
endmodule

module gen_clk #(
    parameter int P_CLK_PERIOD = 10
)(
    output logic CLK
);
    initial begin
        CLK = 0;
        forever #( P_CLK_PERIOD / 2 ) CLK = ~CLK;
    end
endmodule

module gen_ret #(
    parameter int P_RST_TIME = 20
)(
    output logic RST
);
    initial begin
        RST = 1'b1;
        #P_RST_TIME;
        RST = 1'b0;
    end
endmodule


