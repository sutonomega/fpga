module gen_rst #(
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
