`timescale 1ns / 1ps
// 顶层：双人反应时间抢答器 / 单人练习（S0 切换模式）
//   双人模式：S2 开始 -> 随机延迟 -> 两人同时起表 -> 各自按键锁存 -> 比较计分
//   单人模式：S2 开始 -> 随机延迟 -> 单人起表 -> 按键锁存本次成绩 -> 更新 PB
module top (
    input  wire        clk,          // P17 100MHz
    input  wire        rst_n,        // P15 低有效复位
    input  wire        start,        // S2 R15 主持人开始
    input  wire        show_score,   // S3 V1  按住显示分数（双人）
    input  wire        p1_key,       // S4 U4  选手1
    input  wire        p2_key,       // S1 R17 选手2
    input  wire        mode_key,     // S0 R11 模式切换
    output wire [7:0]  seg0,         // 组0段选（数码管0~3）
    output wire [7:0]  seg1,         // 组1段选（数码管4~7）
    output wire [7:0]  dig_sel,      // 位选
    output wire        led_p1,       // D0 F6 选手1
    output wire        led_p2,       // D1 G4 选手2
    output wire        led_foul,     // D2 G3 抢跑
    output wire        led_timeout,  // D5 J3 超时
    output wire        led_mode_2p,  // D6 J2 双人模式指示
    output wire        led_mode_1p   // D7 K2 单人模式指示
);
    wire tick_1ms;
    clk_div u_clk (
        .clk(clk), .rst_n(rst_n), .tick_1ms(tick_1ms)
    );

    // 按键消抖
    wire start_level, start_pulse;
    wire show_level,  show_pulse;
    wire p1_level,    p1_pulse;
    wire p2_level,    p2_pulse;
    wire mode_level,  mode_pulse;

    debounce u_d_start (.clk(clk), .rst_n(rst_n), .tick_1ms(tick_1ms),
                        .key_in(start), .key_level(start_level), .key_pulse(start_pulse));
    debounce u_d_show  (.clk(clk), .rst_n(rst_n), .tick_1ms(tick_1ms),
                        .key_in(show_score), .key_level(show_level), .key_pulse(show_pulse));
    debounce u_d_p1    (.clk(clk), .rst_n(rst_n), .tick_1ms(tick_1ms),
                        .key_in(p1_key), .key_level(p1_level), .key_pulse(p1_pulse));
    debounce u_d_p2    (.clk(clk), .rst_n(rst_n), .tick_1ms(tick_1ms),
                        .key_in(p2_key), .key_level(p2_level), .key_pulse(p2_pulse));
    debounce u_d_mode  (.clk(clk), .rst_n(rst_n), .tick_1ms(tick_1ms),
                        .key_in(mode_key), .key_level(mode_level), .key_pulse(mode_pulse));

    // 伪随机数
    wire [7:0] lfsr_val;
    wire       lfsr_en;
    lfsr u_lfsr (
        .clk(clk), .rst_n(rst_n), .en(lfsr_en), .tick(tick_1ms), .lfsr_val(lfsr_val)
    );

    // 核心状态机
    wire [1:0]  state;
    wire [15:0] p1_disp, p2_disp;
    wire [15:0] s_disp;
    wire [15:0] score1, score2;
    wire [15:0] pb;
    wire        pb_valid;
    wire        mode;

    fsm u_fsm (
        .clk(clk), .rst_n(rst_n),         .tick_1ms(tick_1ms),
        .lfsr_val(lfsr_val[4:0]),
        .start_pulse(start_pulse),
        .p1_pulse(p1_pulse),
        .p2_pulse(p2_pulse),
        .mode_sw_pulse(mode_pulse),
        .mode(mode),
        .state(state),
        .lfsr_en(lfsr_en),
        .p1_disp(p1_disp),
        .p2_disp(p2_disp),
        .s_disp(s_disp),
        .pb(pb),
        .pb_valid(pb_valid),
        .score1(score1),
        .score2(score2),
        .led_p1(led_p1),
        .led_p2(led_p2),
        .led_foul(led_foul),
        .led_timeout(led_timeout)
    );

    // 模式指示：双人亮 J2，单人亮 K2
    assign led_mode_2p = ~mode;
    assign led_mode_1p =  mode;

    // 显示
    display u_disp (
        .clk(clk), .rst_n(rst_n), .tick_1ms(tick_1ms),
        .state(state), .mode(mode), .show_level(show_level),
        .p1_disp(p1_disp), .p2_disp(p2_disp),
        .s_disp(s_disp), .pb(pb), .pb_valid(pb_valid),
        .score1(score1), .score2(score2),
        .seg0(seg0), .seg1(seg1), .dig_sel(dig_sel)
    );
endmodule
