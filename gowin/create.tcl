set origin_dir [file normalize [file dirname [info script]]]

create_project -name fpga_project \
    -dir $origin_dir \
    -pn GW1NR-LV9QN88PC6/I5 \
    -device_version C \
    -force

# set_device -device_version C GW1NR-LV9QN88PC6/I5

# foreach file [glob $origin_dir/../src/*.sv] {
#     add_file $file
# }
add_file $origin_dir/../src/uart_fpga.sv
add_file $origin_dir/../src/uart_tx.sv
add_file $origin_dir/uart.cst

set_option -top_module uart_fpga 
set_option -verilog_std sysv2017
