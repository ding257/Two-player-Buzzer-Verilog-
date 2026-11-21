# 固化脚本：把 bit 转成 .mcs 并烧录到 EGO1 板载 SPI Flash N25Q64（断电不丢）
# 前提：bit 已带 SPI_BUSWIDTH=4（x4/QSPI）配置
# 用法：vivado.bat -mode batch -source program_flash.tcl
# 路径全部相对于本脚本所在目录，工程可整体移动
set ROOT [file dirname [file normalize [info script]]]
set BIT  "$ROOT/vivado_proj/responder.runs/impl_1/top.bit"
set MCS  "$ROOT/top.mcs"

if {![file exists $BIT]} {
    puts "ERROR: 找不到位流 $BIT"
    puts "       请先运行：vivado.bat -mode batch -source build.tcl"
    exit 1
}

# 1. 生成 mcs（x4 接口，N25Q64 = 64Mbit = 8MB，按 PPT 第59页：禁用位交换+校验和）
write_cfgmem -force -format mcs -interface SPIx4 -size 8 -checksum -disablebitswap -loadbit "up 0x0 $BIT" -file $MCS
puts "===== MCS GENERATED ====="

# 2. 连接硬件
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

# 3. 关联 Flash 器件（若还没关联则创建）
set cfgs [get_hw_cfgmems]
if {[llength $cfgs] == 0} {
    create_hw_cfgmem -hw_device $dev [lindex [get_cfgmem_parts {n25q64-3.3v-spi-x1_x2_x4}] 0]
    set cfgs [get_hw_cfgmems]
}
puts "CFGMEM: $cfgs"

# 4. 烧录
set_property PROGRAM.FILES [list $MCS] $cfgs
set_property PROGRAM.PRM_FILE [list "$ROOT/top.prm"] $cfgs
set_property PROGRAM.BLANK_CHECK 0 $cfgs
set_property PROGRAM.ERASE 1 $cfgs
set_property PROGRAM.CFG_PROGRAM 1 $cfgs
set_property PROGRAM.VERIFY 1 $cfgs
program_hw_cfgmem -hw_cfgmem $cfgs
refresh_hw_device $dev

puts "===== FLASH PROGRAM DONE ====="
