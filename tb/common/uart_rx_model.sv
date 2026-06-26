module uart_rx_model #(
    parameter int P_BIT_TIME = 100
)(
    input logic RST,
    input logic RXD
);

    logic [7:0] data_reg;
    logic [7:0] exp_queue[$];
    logic [7:0] exp_data;
    int         error_count;

    task automatic push_exp_data(input logic [7:0] data);
        exp_queue.push_back(data);
    endtask

    initial begin
        data_reg    = 8'h00;
        error_count = 0;

        @(negedge RST);

        forever begin
            data_reg = 8'h00;

            @(negedge RXD);

            #(P_BIT_TIME / 2);

            if (RXD !== 1'b0) begin
                $display("Error: invalid start bit at time %0t", $time);
                error_count++;
            end

            for (int i = 0; i < 8; i++) begin
                #P_BIT_TIME;
                data_reg[i] = RXD;
            end

            #P_BIT_TIME;

            if (RXD !== 1'b1) begin
                $display("Error: invalid stop bit at time %0t", $time);
                error_count++;
            end

            if (exp_queue.size() == 0) begin
                $display(
                    "Error: unexpected extra UART byte %h at time %0t",
                    data_reg,
                    $time
                );
                error_count++;
            end else begin
                exp_data = exp_queue.pop_front();

                if (data_reg !== exp_data) begin
                    $display(
                        "Error: UART mismatch at time %0t, expected %h, value %h",
                        $time,
                        exp_data,
                        data_reg
                    );
                    error_count++;
                end else begin
                    $display(
                        "PASS: UART RX received %h at time %0t",
                        data_reg,
                        $time
                    );
                end

                if (exp_queue.size() == 0) begin
                    if (error_count == 0) begin
                        $display("PASS: received all expected bytes");
                    end else begin
                        $display(
                            "FAIL: received all expected bytes, error_count = %0d",
                            error_count
                        );
                    end
                end
            end
        end
    end

endmodule
