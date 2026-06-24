rm -f dump.vcd

verilator --binary --timing --trace \
  --top-module tb_uart_tx \
  src/uart_tx.sv \
  tb/tb_uart_tx.sv

./obj_dir/Vtb_uart_tx
