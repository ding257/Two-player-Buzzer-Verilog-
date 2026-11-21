# ============================================================
# EGO1 SPI Flash 固化脚本（已验证可用）
#
# 关键：Vivado 2024.2 的间接编程需要先给 FPGA 灌一个"桥接位流"
#       (spi_xc7a35t_pullnone.bit)，否则 program_hw_cfgmem 会报
#       "Failure to set flash parameters"。
#       本脚本手动灌入该位流，绕过 Vivado 自动查找失败的问题。
#
# 用法：vivado.bat -mode batch -source program_flash_ok.tcl
# ============================================================
set ROOT   "C:/Users/86158/Desktop/Recorder_Machine"
set BIT    "$ROOT/vivado_proj/responder.runs/impl_1/top.bit"
set MCS    "$ROOT/top.mcs"
set BRIDGE "D:/vivado/Vivado/2024.2/data/xicom/cfgmem/bitfile/spi_xc7a35t_pullnone.bit"

# 1. 由 bit 生成 mcs（8MB = 64Mbit，SPIx4）
write_cfgmem -force -format mcs -interface SPIx4 -size 8 -loadbit "up 0x0 $BIT" -file $MCS
puts "===== MCS GENERATED ====="

# 2. 连接硬件
open_hw_manager
connect_hw_server -url localhost:3121
open_hw_target
set dev [lindex [get_hw_devices] 0]
current_hw_device $dev
puts "DEVICE=$dev"

# 3. 【关键】灌入桥接位流，让 FPGA 成为 JTAG->SPI 桥
set_property PROGRAM.FILE $BRIDGE $dev
program_hw_devices $dev
refresh_hw_device -update_hw_probes false $dev
puts "===== BRIDGE LOADED ====="

# 4. 创建 Flash 器件对象
set cfgs [get_hw_cfgmems]
if {[llength $cfgs] > 0} { catch {delete_hw_cfgmem [lindex $cfgs 0]} }
create_hw_cfgmem -hw_device $dev [lindex [get_cfgmem_parts {n25q64-3.3v-spi-x1_x2_x4}] 0]
set cfg [current_hw_cfgmem]

# 5. 擦除 + 编程 + 校验
set_property PROGRAM.FILES [list $MCS] $cfg
set_property PROGRAM.ERASE 1 $cfg
set_property PROGRAM.CFG_PROGRAM 1 $cfg
set_property PROGRAM.VERIFY 1 $cfg

if {[catch {program_hw_cfgmem -hw_cfgmem $cfg} e]} {
    puts "===== FLASH_RESULT=FAIL ====="
    puts $e
} else {
    puts "===== FLASH_RESULT=OK ====="
}
