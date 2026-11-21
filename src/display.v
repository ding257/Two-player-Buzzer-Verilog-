`timescale 1ns / 1ps
// 数码管显示：动态扫描 + 段译码
// 组0段选 seg0 驱动数码管0~3，组1段选 seg1 驱动数码管4~7
// 共阴极：段选/位选高电平点亮
// 双人模式：左4位=选手1时间，右4位=选手2时间（按住 S3 显示双方分数）
// 单人模式：左4位=本次成绩，右4位=历史最佳 PB（无记录时显示横杠）
module display (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        tick_1ms,
    input  wire [1:0]  state,
    input  wire        mode,           // 0=双人 1=单人
    input  wire        show_level,     // S3 按住=显示分数（仅双人模式）
    input  wire [15:0] p1_disp,
    input  wire [15:0] p2_disp,
    input  wire [15:0] s_disp,         // 单人：本次成绩
    input  wire [15:0] pb,             // 单人：历史最佳
    input  wire        pb_valid,       // PB 是否已有记录
    input  wire [15:0] score1,
    input  wire [15:0] score2,
    output reg  [7:0]  seg0,
    output reg  [7:0]  seg1,
    output reg  [7:0]  dig_sel
);
    localparam RANDOM = 2'd1;
    localparam DASH   = 8'h40;   // 横杠（仅 g 段亮）

    // 双人模式按住 S3 才切分数；单人模式忽略 S3
    wire show_sc = show_level && !mode;

    // 显示数据选择
    wire [15:0] data0 = mode ? s_disp : (show_sc ? score1 : p1_disp);
    wire [15:0] data1 = mode ? pb     : (show_sc ? score2 : p2_disp);

    // 随机等待阶段两组都显示横杠（双人模式按住 S3 除外）
    wire dash_all = (state == RANDOM) && !show_sc;

    wire [15:0] bcd0, bcd1;
    bin2bcd u_b0 (.bin(data0), .bcd(bcd0));
    bin2bcd u_b1 (.bin(data1), .bcd(bcd1));

    // 扫描计数器（每 1ms 换一位，两组各 4 位同步扫描）
    reg [1:0] scan;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            scan <= 2'd0;
        else if (tick_1ms)
            scan <= scan + 2'd1;
    end

    reg [3:0] digit0, digit1;
    always @(*) begin
        digit0 = 4'd0;
        digit1 = 4'd0;
        // 数码管0(最左)=千位 ... 数码管3(最右)=个位（从右开始读数）
        case (scan)
            2'd0: begin digit0 = bcd0[15:12];  digit1 = bcd1[15:12];  end
            2'd1: begin digit0 = bcd0[11:8];   digit1 = bcd1[11:8];   end
            2'd2: begin digit0 = bcd0[7:4];    digit1 = bcd1[7:4];    end
            2'd3: begin digit0 = bcd0[3:0];    digit1 = bcd1[3:0];    end
        endcase
    end

    // 共阴七段码（bit0=a ... bit6=g, bit7=dp）
    function [7:0] seg_code;
        input [3:0] d;
        begin
            case (d)
                4'd0: seg_code = 8'h3F;
                4'd1: seg_code = 8'h06;
                4'd2: seg_code = 8'h5B;
                4'd3: seg_code = 8'h4F;
                4'd4: seg_code = 8'h66;
                4'd5: seg_code = 8'h6D;
                4'd6: seg_code = 8'h7D;
                4'd7: seg_code = 8'h07;
                4'd8: seg_code = 8'h7F;
                4'd9: seg_code = 8'h6F;
                default: seg_code = 8'h00;
            endcase
        end
    endfunction

    always @(*) begin
        if (dash_all) begin
            seg0 = DASH;   // 随机等待阶段全部横杠
            seg1 = DASH;
        end else begin
            seg0 = seg_code(digit0);
            // 单人模式下 PB 还没记录，右 4 位显示横杠
            seg1 = (mode && !pb_valid) ? DASH : seg_code(digit1);
        end
    end

    // 位选：共阴高电平点亮，两组同时各亮一位
    always @(*) begin
        dig_sel = 8'd0;
        case (scan)
            2'd0: dig_sel = 8'b00010001;   // 数码管0 + 数码管4
            2'd1: dig_sel = 8'b00100010;   // 数码管1 + 数码管5
            2'd2: dig_sel = 8'b01000100;   // 数码管2 + 数码管6
            2'd3: dig_sel = 8'b10001000;   // 数码管3 + 数码管7
        endcase
    end
endmodule
