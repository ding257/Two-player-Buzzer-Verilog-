# 下载 top.bit 到 EGO1 板子（JTAG 在线烧录，断电丢失）
set BIT "C:/Users/86158/Desktop/Recorder_Machine/vivado_proj/responder.runs/impl_1/top.bit"

open_hw_manager
connect_hw_server -url localhost:3121
open_hw_target

set devs [get_hw_devices]
if {[llength $devs] == 0} {
    puts "ERROR: 未找到硬件设备（请确认板子已上电、USB 线已接）"
    exit 1
}

set dev [lindex $devs 0]
puts "Found device: $dev"

set_property PROGRAM.FILE $BIT $dev
program_hw_devices $dev
refresh_hw_device $dev

puts "===== PROGRAM DONE ====="
