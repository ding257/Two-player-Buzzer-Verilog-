`timescale 1ns / 1ps
// 按键消抖：输入高有效（按下=1），稳定 N 个 1ms 周期后确认
module debounce #(
    parameter N = 10
)(
    input  wire clk,
    input  wire rst_n,
    input  wire tick_1ms,
    input  wire key_in,
    output reg  key_level,   // 消抖后稳定电平（按下=1）
    output reg  key_pulse    // 按下瞬间单周期脉冲
);
    reg [3:0] cnt;
    reg       key_prev;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt       <= 4'd0;
            key_level <= 1'b0;
            key_prev  <= 1'b0;
            key_pulse <= 1'b0;
        end else begin
            key_pulse <= 1'b0;
            if (tick_1ms) begin
                if (key_in == key_level) begin
                    cnt <= 4'd0;
                end else begin
                    cnt <= cnt + 4'd1;
                    if (cnt >= N - 1) begin
                        key_level <= key_in;
                        cnt       <= 4'd0;
                    end
                end
            end
            key_prev  <= key_level;
            key_pulse <= key_level & ~key_prev;
        end
    end
endmodule
