# 双人反应计时器 Vivado 自动建工程 + 综合 + 实现 + 生成 bit 脚本
# 使用脚本所在目录作为根目录，工程自包含，可整体移动
set ROOT [file dirname [file normalize [info script]]]

create_project responder "${ROOT}/vivado_proj" -part xc7a35tcsg324-1 -force

add_files -norecurse [glob "${ROOT}/src/*.v"]
update_compile_order -fileset sources_1

add_files -fileset constrs_1 "${ROOT}/constr/responder.xdc"

set_property top top [current_fileset]

launch_runs synth_1 -jobs 8
wait_on_run synth_1

launch_runs impl_1 -to_step write_bitstream -jobs 8
wait_on_run impl_1

puts "===== ALL DONE ====="
