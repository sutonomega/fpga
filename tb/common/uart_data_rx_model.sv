module uart_data_rx_model (
    input logic       RST,
    input logic       VALID,
    input logic [7:0] DATA
);

    logic [7:0] exp_queue[$];
    logic [7:0] exp_data;
    int         error_count;

    task automatic push_exp_data(input logic [7:0] data);
        exp_queue.push_back(data);
    endtask

    initial begin
        error_count = 0;

        @(negedge RST);

        forever begin

            @(posedge VALID);

            if (exp_queue.size() == 0) begin
                $display("Error: unexpected extra UART byte %h at time %0t",DATA,$time);
                error_count++;
            end else begin
                exp_data = exp_queue.pop_front();

                if (DATA !== exp_data) begin
                    $display("Error: UART mismatch at time %0t, expected %h, value %h",$time,exp_data,DATA);
                    error_count++;
                end else begin
                    $display("PASS: UART RX received %h at time %0t",DATA,$time);
                end

                if (exp_queue.size() == 0) begin
                    if (error_count == 0) begin
                        $display("PASS: received all expected bytes");
                    end else begin
                        $display("FAIL: received all expected bytes, error_count = %0d",error_count);
                    end
                end
            end
        end
    end

endmodule
