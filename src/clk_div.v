`timescale 1ns / 1ps
// 时钟分频：100MHz -> 1ms 脉冲（1kHz）
module clk_div (
    input  wire clk,
    input  wire rst_n,
    output reg  tick_1ms
);
    reg [16:0] cnt;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt      <= 17'd0;
            tick_1ms <= 1'b0;
        end else begin
            if (cnt >= 17'd99999) begin
                cnt      <= 17'd0;
                tick_1ms <= 1'b1;
            end else begin
                cnt      <= cnt + 17'd1;
                tick_1ms <= 1'b0;
            end
        end
    end
endmodule
