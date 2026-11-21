# 双人反应时间抢答器（Verilog / EGO1）

HIT 数字电路大作业。用 Verilog-2001 在 EGO1（Artix-7 `xc7a35tcsg324-1`）开发板上实现一个**双人反应时间抢答器**，并额外支持**单人练习**模式：主持人按键后经过一段随机延迟发出开始信号，选手按键停止计时，系统比较反应时间并计分，8 位数码管实时显示时间与成绩。

## 功能

**双人抢答模式（默认，D6 指示灯亮）**

- `S2` 由主持人发起一轮：先进入 1~4.1 秒的随机延迟（32 档，由 LFSR 产生），此时按键记为**抢跑**
- 延迟结束瞬间两人同时起表，各自按下 `S1` / `S4` 锁存自己的反应时间
- 反应更快的一方 **+10 分**，抢跑的一方 **-5 分**
- 按住 `S3` 显示双方累计分数

**单人练习模式（D7 指示灯亮）**

- `S0` 切换模式（仅在空闲或出结果时生效，比赛进行中按下无效）
- 单人起表，按键锁存本次成绩，并自动记录历史最佳成绩 **PB**

**公共部分**

- 5 个按键全部经过 20ms 消抖，同时输出稳定电平与单周期脉冲
- 8 位数码管动态扫描显示，两组段选 `seg0` / `seg1` 分别驱动数码管 0~3 与 4~7
- 超时、抢跑、双方得分均有独立 LED 指示

## 状态机

```
IDLE ──S2──▶ RANDOM ──随机延迟结束──▶ TIMING ──按键锁存──▶ RESULT
  ▲                                                          │
  └─────────────────────────S2 / S0──────────────────────────┘
```

| 状态 | 说明 |
| --- | --- |
| `IDLE` | 空闲，等待主持人开始；此时可切换模式 |
| `RANDOM` | 随机延迟倒计时（`1000 + lfsr_val[4:0] × 100` ms，即 1.0~4.1 s）；期间按键判负为抢跑 |
| `TIMING` | 计时中，数码管实时刷新；按键锁存成绩 |
| `RESULT` | 显示本轮结果，更新分数 / PB；可再次开始或切换模式 |

## 目录结构

```
.
├── src/                    Verilog 源码（顶层 top.v）
│   ├── top.v               顶层连线：按键 → 状态机 → 显示
│   ├── fsm.v               核心状态机：计时、判胜、计分、抢跑、超时、PB
│   ├── clk_div.v           100 MHz → 1 ms tick 分频
│   ├── debounce.v          按键消抖（输出电平 + 脉冲）
│   ├── lfsr.v              8 位线性反馈移位寄存器，产生伪随机延迟
│   ├── display.v           数码管动态扫描与多画面切换
│   └── bin2bcd.v           二进制转 BCD
├── constr/responder.xdc    引脚与时序约束
├── build.tcl               一键建工程 + 综合 + 实现 + 生成 bit
├── program.tcl             JTAG 在线下载 bit（断电丢失）
├── program_flash_ok.tcl    SPI Flash 固化（验证可用，推荐）
├── program_flash_final.tcl Flash 固化早期版本
└── program_flash.tcl       Flash 固化最早期尝试
```

## 模块说明

| 模块 | 端口要点 | 功能 |
| --- | --- | --- |
| `top` | 7 个输入、13 个输出 | 例化并连接全部子模块，模式指示灯直连 `mode` |
| `fsm` | `state[1:0]`、`pb[15:0]`、`score1/2[15:0]` | 四状态主控；负责随机延迟、毫秒计时、胜负判定与计分 |
| `clk_div` | `tick_1ms` | 100 MHz 计数分频，产生 1 ms 节拍 |
| `debounce` | `key_level`、`key_pulse` | 基于 `tick_1ms` 计数消抖 |
| `lfsr` | `lfsr_val[7:0]`、`en`、`tick` | 每毫秒移位一次，为延迟提供随机数 |
| `display` | `seg0/seg1[7:0]`、`dig_sel[7:0]` | 1 kHz 级动态扫描，按状态与模式切换显示内容 |
| `bin2bcd` | `bin[15:0]` → `bcd[15:0]` | 千 / 百 / 十 / 个四位 BCD |

## 引脚分配

| 信号 | 板载 | 引脚 | 说明 |
| --- | --- | --- | --- |
| `clk` | — | `P17` | 100 MHz 板载时钟 |
| `rst_n` | — | `P15` | 低有效复位 |
| `start` | `S2` | `R15` | 主持人开始 |
| `show_score` | `S3` | `V1` | 按住显示分数（双人模式） |
| `p1_key` | `S4` | `U4` | 选手 1 / 单人模式停表 |
| `p2_key` | `S1` | `R17` | 选手 2 / 单人模式停表 |
| `mode_key` | `S0` | `R11` | 模式切换 |
| `seg0[7:0]` | — | — | 组 0 段选（数码管 0~3） |
| `seg1[7:0]` | — | — | 组 1 段选（数码管 4~7） |
| `dig_sel[7:0]` | — | — | 位选 |
| `led_p1` | `D0` | `F6` | 选手 1 指示 |
| `led_p2` | `D1` | `G4` | 选手 2 指示 |
| `led_foul` | `D2` | `G3` | 抢跑指示 |
| `led_timeout` | `D5` | `J3` | 超时指示 |
| `led_mode_2p` | `D6` | `J2` | 双人模式指示 |
| `led_mode_1p` | `D7` | `K2` | 单人模式指示 |

## 构建与烧录

环境：Vivado 2024.2（其它版本一般也可）/ Windows。

```bash
# 1. 建工程 + 综合 + 实现 + 生成位流
vivado.bat -mode batch -source build.tcl

# 2a. JTAG 在线下载（断电丢失）
vivado.bat -mode batch -source program.tcl

# 2b. SPI Flash 固化（断电保持，推荐）
vivado.bat -mode batch -source program_flash_ok.tcl
```

`build.tcl` 以脚本自身所在目录为根目录，工程**自包含、可整体移动**，clone 到任何位置都能直接跑。

Flash 固化流程：生成 8 MB（64 Mbit）SPIx4 的 `.mcs` → 连接 `localhost:3121` → 给 FPGA 灌入桥接位流 `spi_xc7a35t_pullnone.bit` → 擦除、编程、校验 `n25q64-3.3v-spi-x1_x2_x4`。

## 注意事项

- `program.tcl`、`program_flash_ok.tcl`、`program_flash_final.tcl` 里写死了作者的绝对路径（`C:/Users/.../Recorder_Machine` 和 `D:/vivado/...`），换机器运行前需要改成自己的路径。
- 仓库只提交源码、约束与脚本。`vivado_proj/`、`*.bit`、`*.mcs`、`*.svf` 等中间产物和位流已写入 `.gitignore`：位流可由 `build.tcl` 重新生成，`top.svf` 单文件就有 50 MB，不适合进仓库。
- Flash 固化需要 `JP2` 拨到 JTAG 并断电重启，让 JTAG 能接管配置引擎操作 SPI Flash。
