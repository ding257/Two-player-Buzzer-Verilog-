# ============================================================
# EGO1 SPI Flash 固化脚本（最终版）
# 前提：JP2 拨到 JTAG 位置 + 断电重启（FPGA 处于未配置态）
#       这样 JTAG 才能接管配置引擎去操作 SPI Flash
# 用法：vivado.bat -mode batch -source program_flash_final.tcl
# 路径全部相对于本脚本所在目录，工程可整体移动
# ============================================================
set ROOT [file dirname [file normalize [info script]]]
set BIT  "$ROOT/vivado_proj/responder.runs/impl_1/top.bit"
set MCS  "$ROOT/top.mcs"

if {![file exists $BIT]} {
    puts "ERROR: 找不到位流 $BIT"
    puts "       请先运行：vivado.bat -mode batch -source build.tcl"
    exit 1
}

# 1. 生成 mcs（大小 8MB = 64Mbit，SPIx4 接口）
write_cfgmem -force -format mcs -interface SPIx4 -size 8 -loadbit "up 0x0 $BIT" -file $MCS
puts "===== MCS GENERATED ====="

# 2. 连接硬件
open_hw_manager
connect_hw_server -url localhost:3121
open_hw_target
set dev [lindex [get_hw_devices] 0]
current_hw_device $dev
puts "DEVICE=$dev"

refresh_hw_device -update_hw_probes false $dev
if {[catch {set isp [get_property PROGRAM.IS_PROGRAMMED $dev]} e]} {
    puts "PROGRAM_STATE=UNKNOWN"
} else {
    puts "PROGRAM_STATE=$isp"
}

# 3. 创建 Flash 器件对象
set cfgs [get_hw_cfgmems]
if {[llength $cfgs] > 0} { catch {delete_hw_cfgmem [lindex $cfgs 0]} }
create_hw_cfgmem -hw_device $dev [lindex [get_cfgmem_parts {n25q64-3.3v-spi-x1_x2_x4}] 0]
set cfg [current_hw_cfgmem]
puts "CFGMEM_PART=[get_property CFGMEM_PART $cfg]"

# 4. 设置烧录参数
set_property PROGRAM.FILES [list $MCS] $cfg
set_property PROGRAM.ADDRESS_RANGE {use_file} $cfg
set_property PROGRAM.BLANK_CHECK 0 $cfg
set_property PROGRAM.ERASE 1 $cfg
set_property PROGRAM.CFG_PROGRAM 1 $cfg
set_property PROGRAM.VERIFY 1 $cfg

# 5. 烧录
if {[catch {program_hw_cfgmem -hw_cfgmem $cfg} e]} {
    puts "===== FLASH_RESULT=FAIL ====="
    puts $e
} else {
    puts "===== FLASH_RESULT=OK ====="
}
