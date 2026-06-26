module uart_tx_model #(
    parameter int P_VALID_DELAY = 60
)(
    input  logic       CLK,
    input  logic       READY,
    output logic       VALID,
    output logic [7:0] DATA
);

    logic [7:0] tx_queue[$];

    task automatic push_tx_data(input logic [7:0] data);
        tx_queue.push_back(data);
    endtask

    task automatic push_tx_string(input string str);
        for (int i = 0; i < str.len(); i++) begin
            push_tx_data(str.getc(i));
        end
    endtask

    initial begin
        VALID = 1'b0;
        DATA  = 8'h00;

        forever begin
            @(posedge CLK);

            if (tx_queue.size() != 0) begin
                repeat (P_VALID_DELAY) @(posedge CLK);

                // uart_tx が受け取れるまで待つ
                wait (READY === 1'b1);
                @(posedge CLK);

                DATA  = tx_queue.pop_front();
                VALID = 1'b1;

                // VALID && READY が成立するまで保持
                do begin
                    @(posedge CLK);
                end while (!(VALID && READY));

                VALID = 1'b0;
            end
        end
    end

endmodule
