.PHONY: lint-tx sim-tx lint-fpga sim-fpga clean

COMMON = \
	tb/common/gen_clk.sv \
	tb/common/gen_rst.sv \
	tb/common/uart_rx_model.sv

lint-tx:
	verilator --lint-only -Wall --timing -Wno-fatal \
		--top-module tb_uart_tx \
		src/uart_tx.sv \
		$(COMMON) \
		tb/common/uart_master.sv \
		tb/tb_uart_tx.sv

sim-tx:
	verilator -Wall --timing -Wno-fatal --binary --trace \
		--top-module tb_uart_tx \
		src/uart_tx.sv \
		$(COMMON) \
		tb/common/uart_master.sv \
		tb/tb_uart_tx.sv
	./obj_dir/Vtb_uart_tx

lint-fpga:
	verilator --lint-only -Wall --timing -Wno-fatal \
		--top-module tb_uart_fpga \
		src/uart_tx.sv \
		src/uart_fpga.sv \
		$(COMMON) \
		tb/tb_uart_fpga.sv

sim-fpga:
	verilator -Wall --timing -Wno-fatal --binary --trace \
		--top-module tb_uart_fpga \
		src/uart_tx.sv \
		src/uart_fpga.sv \
		$(COMMON) \
		tb/tb_uart_fpga.sv
	./obj_dir/Vtb_uart_fpga

clean:
	rm -rf obj_dir dump.vcd dump_uart_fpga.vcd
