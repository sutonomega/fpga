lint:
	verilator --lint-only -Wall --timing -Wno-fatal src/*.sv tb/*.sv

sim:
	verilator --binary --timing --trace src/*.sv tb/*.sv
	./obj_dir/Vtb_uart_tx

clean:
	rm -rf obj_dir dump.vcd
