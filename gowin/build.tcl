set origin_dir [file dirname [info script]]

open_project $origin_dir/fpga_project/fpga_project.gprj

run all

exit
