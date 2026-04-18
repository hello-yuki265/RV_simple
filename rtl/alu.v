/*
 * @file            rtl/alu.v
 * @description     
 * @author          hello-yuki265 <2658476808@qq.com>
 * @createTime      2026-04-17 17:55:38
 * @lastModified    2026-04-18 16:52:50
 * Copyright ©National Key Laboratory of Wireless Communication, UESTC, All rights reserved
*/

module alu(
    input clk,
    input rst_n,

    // ----------------
    // 输入
    // ----------------
    input [3:0]  alu_ctrl,   //计算模式选择,
                           //00: add

    input [31:0] src0,  //源0
    input [31:0] src1,  //源1

    output reg [31:0] res
);
    `include "glb_define.v"

    // -----------------
    // alu运算逻辑
    // -----------------
    always @(*) begin
        case(alu_ctrl)
            `ALU_ADD : res = src0 + src1;
            `ALU_SUB : res = src0 - src1;
            `ALU_SLL : res = src0 << src1;
            `ALU_SLT : res = $signed(src0) < $signed(src1);
            `ALU_SLTU: res = src0 < src1;
            `ALU_XOR : res = src0 ^ src1;
            `ALU_SRL : res = src0 >> src1;
            `ALU_SRA : res = $signed(src0) >>> src1;
            `ALU_OR  : res = src0 | src1;
            `ALU_AND : res = src0 & src1;
        endcase
    end


endmodule