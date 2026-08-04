set tb $::env(TB)
set origin_dir [file dirname [info script]]

create_project sim $origin_dir/sim -part xc7a35tcsg324-1 -force

# 設計ファイル追加
add_files [glob $origin_dir/src/*.sv]
# シミュレーション用ファイルセット作成
if {[string equal [get_filesets -quiet sim_1] ""]}
  { create_fileset -simset sim_1 }

# テストベンチ追加
add_files -fileset sim_1 [glob $origin_dir/tb/common/*.sv]
add_files -fileset sim_1 $origin_dir/tb/${tb}.sv

# テストベンチをトップに設定
set_property top $tb [get_filesets sim_1]

launch_simulation
run all

quit
