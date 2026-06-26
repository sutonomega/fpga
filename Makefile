.PHONY: lint-tx sim-tx lint-fpga sim-fpga clean

COMMON = \
	tb/common/gen_clk.sv \
	tb/common/gen_rst.sv \

lint-tx:
	verilator --lint-only -Wall --timing -Wno-fatal \
		--top-module tb_uart_tx \
		src/uart_tx.sv \
		$(COMMON) \
		tb/common/uart_tx_model.sv \
		tb/common/uart_line_rx_model.sv \
		tb/tb_uart_tx.sv

sim-tx:
	verilator -Wall --timing -Wno-fatal --binary --trace \
		--top-module tb_uart_tx \
		src/uart_tx.sv \
		$(COMMON) \
		tb/common/uart_tx_model.sv \
		tb/common/uart_line_rx_model.sv \
		tb/tb_uart_tx.sv
	./obj_dir/Vtb_uart_tx

lint-fpga:
	verilator --lint-only -Wall --timing -Wno-fatal \
		--top-module tb_uart_fpga \
		src/uart_tx.sv \
		src/uart_fpga.sv \
		$(COMMON) \
		tb/common/uart_line_rx_model.sv \
		tb/tb_uart_fpga.sv

sim-fpga:
	verilator -Wall --timing -Wno-fatal --binary --trace \
		--top-module tb_uart_fpga \
		src/uart_tx.sv \
		src/uart_fpga.sv \
		$(COMMON) \
		tb/common/uart_line_rx_model.sv \
		tb/tb_uart_fpga.sv
	./obj_dir/Vtb_uart_fpga

lint-rx:
	verilator --lint-only -Wall --timing -Wno-fatal \
	  --top-module tb_uart_rx \
	  src/uart_tx.sv \
	  src/uart_rx.sv \
		$(COMMON) \
		tb/common/uart_data_rx_model.sv \
	  tb/common/uart_tx_model.sv \
	  tb/tb_uart_rx.sv

sim-rx:
	verilator -Wall --timing -Wno-fatal --binary --trace \
	  --top-module tb_uart_rx \
	  src/uart_tx.sv \
	  src/uart_rx.sv \
		$(COMMON) \
		tb/common/uart_data_rx_model.sv \
	  tb/common/uart_tx_model.sv \
	  tb/tb_uart_rx.sv
	./obj_dir/Vtb_uart_rx

lint-if:
	verilator --lint-only -Wall --timing -Wno-fatal \
	  --top-module tb_uart_if \
	  src/uart_tx.sv \
	  src/uart_rx.sv \
		src/uart_if.sv \
		$(COMMON) \
		tb/common/uart_line_rx_model.sv \
	  tb/common/uart_tx_model.sv \
	  tb/tb_uart_if.sv

sim-if:
	verilator -Wall --timing -Wno-fatal --binary --trace \
	  --top-module tb_uart_if \
	  src/uart_tx.sv \
	  src/uart_rx.sv \
		src/uart_if.sv \
		$(COMMON) \
		tb/common/uart_line_rx_model.sv \
	  tb/common/uart_tx_model.sv \
	  tb/tb_uart_if.sv
	./obj_dir/Vtb_uart_if

check: lint-tx sim-tx lint-fpga sim-fpga lint-rx sim-rx lint-if sim-if

clean:
	rm -rf obj_dir dump.vcd dump_uart_fpga.vcd

view:
	gtkwave dump.vcd
