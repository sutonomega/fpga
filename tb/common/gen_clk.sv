module gen_clk #(
    parameter int P_CLK_PERIOD = 10
)(
    output logic CLK
);

    initial begin
        CLK = 1'b0;
        forever #(P_CLK_PERIOD / 2) CLK = ~CLK;
    end

endmodule
