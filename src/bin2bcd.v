`timescale 1ns / 1ps
// 二进制 -> 4 位 BCD（double-dabble，输入范围 0~9999）
module bin2bcd (
    input  wire [15:0] bin,
    output reg  [15:0] bcd    // 每 4 bit 一位：千/百/十/个
);
    reg [31:0] sh;
    integer i;

    always @(*) begin
        sh = {16'b0, bin};
        for (i = 0; i < 16; i = i + 1) begin
            if (sh[19:16] >= 4'd5) sh[19:16] = sh[19:16] + 4'd3;
            if (sh[23:20] >= 4'd5) sh[23:20] = sh[23:20] + 4'd3;
            if (sh[27:24] >= 4'd5) sh[27:24] = sh[27:24] + 4'd3;
            if (sh[31:28] >= 4'd5) sh[31:28] = sh[31:28] + 4'd3;
            sh = sh << 1;
        end
        bcd = sh[31:16];
    end
endmodule
