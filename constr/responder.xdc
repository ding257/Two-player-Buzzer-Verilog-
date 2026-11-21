# 抢答器约束文件（EGO1 开发板，xc7a35tcsg324-1）
# 引脚来源：EGO1实验平台及Vivado开发流程.pptx

# 时钟（100MHz）
set_property PACKAGE_PIN P17 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -period 10.000 -name sys_clk [get_ports clk]

# 复位 RST(S6)，低有效
set_property PACKAGE_PIN P15 [get_ports rst_n]
set_property IOSTANDARD LVCMOS33 [get_ports rst_n]

# 按键 S2 主持人开始
set_property PACKAGE_PIN R15 [get_ports start]
set_property IOSTANDARD LVCMOS33 [get_ports start]

# 按键 S3 显示分数
set_property PACKAGE_PIN V1 [get_ports show_score]
set_property IOSTANDARD LVCMOS33 [get_ports show_score]

# 按键 S4 选手1
set_property PACKAGE_PIN U4 [get_ports p1_key]
set_property IOSTANDARD LVCMOS33 [get_ports p1_key]

# 按键 S1 选手2
set_property PACKAGE_PIN R17 [get_ports p2_key]
set_property IOSTANDARD LVCMOS33 [get_ports p2_key]

# 按键 S0 模式切换
set_property PACKAGE_PIN R11 [get_ports mode_key]
set_property IOSTANDARD LVCMOS33 [get_ports mode_key]

# LED D0 选手1
set_property PACKAGE_PIN F6 [get_ports led_p1]
set_property IOSTANDARD LVCMOS33 [get_ports led_p1]

# LED D1 选手2
set_property PACKAGE_PIN G4 [get_ports led_p2]
set_property IOSTANDARD LVCMOS33 [get_ports led_p2]

# LED D2 抢跑
set_property PACKAGE_PIN G3 [get_ports led_foul]
set_property IOSTANDARD LVCMOS33 [get_ports led_foul]

# LED D3 超时
set_property PACKAGE_PIN J3 [get_ports led_timeout]
set_property IOSTANDARD LVCMOS33 [get_ports led_timeout]

# LED D6 双人模式指示
set_property PACKAGE_PIN J2 [get_ports led_mode_2p]
set_property IOSTANDARD LVCMOS33 [get_ports led_mode_2p]

# LED D7 单人模式指示
set_property PACKAGE_PIN K2 [get_ports led_mode_1p]
set_property IOSTANDARD LVCMOS33 [get_ports led_mode_1p]

# 数码管 组0 段选（数码管0~3）
set_property PACKAGE_PIN B4 [get_ports {seg0[0]}]
set_property PACKAGE_PIN A4 [get_ports {seg0[1]}]
set_property PACKAGE_PIN A3 [get_ports {seg0[2]}]
set_property PACKAGE_PIN B1 [get_ports {seg0[3]}]
set_property PACKAGE_PIN A1 [get_ports {seg0[4]}]
set_property PACKAGE_PIN B3 [get_ports {seg0[5]}]
set_property PACKAGE_PIN B2 [get_ports {seg0[6]}]
set_property PACKAGE_PIN D5 [get_ports {seg0[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg0[*]}]

# 数码管 组1 段选（数码管4~7）
set_property PACKAGE_PIN D4 [get_ports {seg1[0]}]
set_property PACKAGE_PIN E3 [get_ports {seg1[1]}]
set_property PACKAGE_PIN D3 [get_ports {seg1[2]}]
set_property PACKAGE_PIN F4 [get_ports {seg1[3]}]
set_property PACKAGE_PIN F3 [get_ports {seg1[4]}]
set_property PACKAGE_PIN E2 [get_ports {seg1[5]}]
set_property PACKAGE_PIN D2 [get_ports {seg1[6]}]
set_property PACKAGE_PIN H2 [get_ports {seg1[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg1[*]}]

# 数码管 位选
set_property PACKAGE_PIN G2 [get_ports {dig_sel[0]}]
set_property PACKAGE_PIN C2 [get_ports {dig_sel[1]}]
set_property PACKAGE_PIN C1 [get_ports {dig_sel[2]}]
set_property PACKAGE_PIN H1 [get_ports {dig_sel[3]}]
set_property PACKAGE_PIN G1 [get_ports {dig_sel[4]}]
set_property PACKAGE_PIN F1 [get_ports {dig_sel[5]}]
set_property PACKAGE_PIN E1 [get_ports {dig_sel[6]}]
set_property PACKAGE_PIN G6 [get_ports {dig_sel[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {dig_sel[*]}]

# ==== SPI Flash 固化配置（EGO1 用 QSPI x4 从 N25Q64 启动） ====
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
