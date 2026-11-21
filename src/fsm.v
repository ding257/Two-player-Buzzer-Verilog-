`timescale 1ns / 1ps
// 核心状态机：IDLE -> RANDOM(随机延迟) -> TIMING(计时) -> RESULT(结果)
// 两种模式：
//   mode=0 双人抢答（默认）：两人同时起表，各自锁存，快者 +10，抢跑 -5
//   mode=1 单人练习        ：单人起表，锁存本次成绩，并记录历史最佳 PB
// 模式切换按键 S0 仅在 IDLE / RESULT 态生效，比赛进行中按下无效
module fsm (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        tick_1ms,
    input  wire [4:0]  lfsr_val,
    input  wire        start_pulse,   // S2 主持人开始
    input  wire        p1_pulse,      // S4 选手1（单人模式下也作为停表键）
    input  wire        p2_pulse,      // S1 选手2（单人模式下也作为停表键）
    input  wire        mode_sw_pulse, // S0 模式切换
    output reg         mode,          // 0=双人 1=单人
    output reg  [1:0]  state,
    output reg         lfsr_en,
    output wire [15:0] p1_disp,       // 双人：选手1时间
    output wire [15:0] p2_disp,       // 双人：选手2时间
    output wire [15:0] s_disp,        // 单人：本次成绩
    output reg  [15:0] pb,            // 单人：历史最佳
    output reg         pb_valid,      // PB 是否已有记录
    output reg  [15:0] score1,
    output reg  [15:0] score2,
    output reg         led_p1,
    output reg         led_p2,
    output reg         led_foul,
    output reg         led_timeout
);
    localparam IDLE   = 2'd0;
    localparam RANDOM = 2'd1;
    localparam TIMING = 2'd2;
    localparam RESULT = 2'd3;

    reg [15:0] delay_cnt;      // 随机延迟剩余
    reg [15:0] p1_time, p2_time;
    reg [15:0] p1_lock, p2_lock;
    reg        p1_latched, p2_latched;
    reg        scored;
    reg [15:0] s_time;         // 单人：实时计时
    reg [15:0] s_lock;         // 单人：本次定格

    // 随机延迟：1000 + lfsr_val[4:0]*100 = 1000~4100ms（1~4.1 秒，32 档）
    wire [15:0] delay_sel = 16'd1000 + ({11'd0, lfsr_val[4:0]} * 16'd100);

    // 双人显示值
    assign p1_disp = (state == RESULT) ? p1_lock : p1_time;
    assign p2_disp = (state == RESULT) ? p2_lock : p2_time;
    // 单人显示值
    assign s_disp  = (state == RESULT) ? s_lock : s_time;

    wire mode_sw_ok = mode_sw_pulse && (state == IDLE || state == RESULT);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mode        <= 1'b0;        // 上电默认双人模式
            state       <= IDLE;
            lfsr_en     <= 1'b1;
            score1      <= 16'd0;
            score2      <= 16'd0;
            delay_cnt   <= 16'd0;
            p1_time     <= 16'd0;
            p2_time     <= 16'd0;
            p1_lock     <= 16'd0;
            p2_lock     <= 16'd0;
            p1_latched  <= 1'b0;
            p2_latched  <= 1'b0;
            scored      <= 1'b0;
            s_time      <= 16'd0;
            s_lock      <= 16'd0;
            pb          <= 16'd0;
            pb_valid    <= 1'b0;
            led_p1      <= 1'b0;
            led_p2      <= 1'b0;
            led_foul    <= 1'b0;
            led_timeout <= 1'b0;
        end else if (mode_sw_ok) begin
            // 切换模式：清本轮比赛状态，但保留双方分数与历史最佳 PB
            mode        <= ~mode;
            state       <= IDLE;
            lfsr_en     <= 1'b1;
            p1_latched  <= 1'b0;
            p2_latched  <= 1'b0;
            p1_time     <= 16'd0;
            p2_time     <= 16'd0;
            p1_lock     <= 16'd0;
            p2_lock     <= 16'd0;
            s_time      <= 16'd0;
            s_lock      <= 16'd0;
            scored      <= 1'b0;
            led_p1      <= 1'b0;
            led_p2      <= 1'b0;
            led_foul    <= 1'b0;
            led_timeout <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    lfsr_en <= 1'b1;   // 后台滚动，保证 start 时刻随机
                    if (start_pulse) begin
                        state       <= RANDOM;
                        delay_cnt   <= delay_sel;
                        p1_latched  <= 1'b0;
                        p2_latched  <= 1'b0;
                        p1_time     <= 16'd0;
                        p2_time     <= 16'd0;
                        s_time      <= 16'd0;
                        s_lock      <= 16'd0;
                        led_p1      <= 1'b0;
                        led_p2      <= 1'b0;
                        led_foul    <= 1'b0;
                        led_timeout <= 1'b0;
                    end
                end

                RANDOM: begin
                    lfsr_en <= 1'b1;
                    if (p1_pulse || p2_pulse) begin
                        // 抢跑：双人模式扣分，单人模式仅提示
                        if (!mode) begin
                            if (p1_pulse)
                                score1 <= (score1 >= 16'd5) ? (score1 - 16'd5) : 16'd0;
                            else
                                score2 <= (score2 >= 16'd5) ? (score2 - 16'd5) : 16'd0;
                        end
                        led_foul <= 1'b1;
                        state    <= IDLE;
                    end else if (tick_1ms) begin
                        if (delay_cnt > 16'd0)
                            delay_cnt <= delay_cnt - 16'd1;
                        else
                            state <= TIMING;
                    end
                end

                TIMING: begin
                    lfsr_en <= 1'b0;
                    if (mode) begin
                        // ---------- 单人练习 ----------
                        if (tick_1ms && s_time < 16'd9999)
                            s_time <= s_time + 16'd1;
                        if (p1_pulse || p2_pulse) begin
                            s_lock <= s_time;
                            // 只有更快才更新 PB
                            if (!pb_valid || s_time < pb) begin
                                pb       <= s_time;
                                pb_valid <= 1'b1;
                            end
                            state <= RESULT;
                        end else if (tick_1ms && s_time >= 16'd4999) begin
                            // 5 秒未按，作废
                            led_timeout <= 1'b1;
                            state       <= RESULT;
                        end
                    end else begin
                        // ---------- 双人抢答 ----------
                        if (tick_1ms) begin
                            if (!p1_latched) p1_time <= p1_time + 16'd1;
                            if (!p2_latched) p2_time <= p2_time + 16'd1;
                        end
                        if (p1_pulse && !p1_latched) begin
                            p1_lock    <= p1_time;
                            p1_latched <= 1'b1;
                        end
                        if (p2_pulse && !p2_latched) begin
                            p2_lock    <= p2_time;
                            p2_latched <= 1'b1;
                        end
                        if (p1_latched && p2_latched) begin
                            scored <= 1'b0;
                            state  <= RESULT;
                        end
                        if (tick_1ms &&
                            ((!p1_latched && p1_time >= 16'd4999) ||
                             (!p2_latched && p2_time >= 16'd4999))) begin
                            scored <= 1'b0;
                            state  <= RESULT;
                        end
                    end
                end

                RESULT: begin
                    lfsr_en <= 1'b0;
                    if (mode) begin
                        // 单人：按 S2 再来一轮
                        if (start_pulse) begin
                            state       <= RANDOM;
                            delay_cnt   <= delay_sel;
                            s_time      <= 16'd0;
                            s_lock      <= 16'd0;
                            led_foul    <= 1'b0;
                            led_timeout <= 1'b0;
                        end
                    end else begin
                        if (!scored) begin
                            scored <= 1'b1;
                            if (p1_latched && p2_latched) begin
                                if (p1_lock < p2_lock) begin
                                    score1 <= score1 + 16'd10;
                                    led_p1 <= 1'b1;
                                end else if (p2_lock < p1_lock) begin
                                    score2 <= score2 + 16'd10;
                                    led_p2 <= 1'b1;
                                end
                                // 相等：平局，都不加分
                            end else if (p1_latched && !p2_latched) begin
                                score1 <= score1 + 16'd10;
                                led_p1 <= 1'b1;
                            end else if (!p1_latched && p2_latched) begin
                                score2 <= score2 + 16'd10;
                                led_p2 <= 1'b1;
                            end else begin
                                led_timeout <= 1'b1;
                            end
                        end
                        if (start_pulse) begin
                            state       <= RANDOM;
                            delay_cnt   <= delay_sel;
                            p1_latched  <= 1'b0;
                            p2_latched  <= 1'b0;
                            p1_time     <= 16'd0;
                            p2_time     <= 16'd0;
                            p1_lock     <= 16'd0;
                            p2_lock     <= 16'd0;
                            scored      <= 1'b0;
                            led_p1      <= 1'b0;
                            led_p2      <= 1'b0;
                            led_timeout <= 1'b0;
                            led_foul    <= 1'b0;
                        end
                    end
                end
            endcase
        end
    end
endmodule
