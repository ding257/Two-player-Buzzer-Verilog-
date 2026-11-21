`timescale 1ns / 1ps
// 8-bit LFSR 伪随机数发生器，用于随机延迟和随机数显示
// 反馈多项式：x^8 + x^6 + x^5 + x^4 + 1
module lfsr (
    input  wire clk,
    input  wire rst_n,
    input  wire en,          // 滚动使能
    input  wire tick,        // 滚动节拍（1ms）
    output reg  [7:0] lfsr_val
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            lfsr_val <= 8'hA5;
        else if (en && tick)
            lfsr_val <= {lfsr_val[6:0],
                         lfsr_val[7] ^ lfsr_val[5] ^ lfsr_val[4] ^ lfsr_val[3]};
    end
endmodule
