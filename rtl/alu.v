/*************************************************************************
 * @Copyright (c) 2026 by hello-yuki265, All Rights Reserved. 
 * @Author       : hello-yuki265
 * @Github       : 2658476808@qq.com
 * @Date         : 2026-04-17 12:27:28
 * @LastEditors  : hello-yuki265 2658476808@qq.com
 * @LastEditTime : 2026-04-19 02:36:18
 * @FilePath     : \RV_simple\rtl\alu.v
 * @Description  : 
 *************************************************************************/
 
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
            `ALU_SLL : res = src0 << src1[4:0];
            `ALU_SLT : res = $signed(src0) < $signed(src1);
            `ALU_SLTU: res = src0 < src1;
            `ALU_XOR : res = src0 ^ src1;
            `ALU_SRL : res = src0 >> src1[4:0];
            `ALU_SRA : res = $signed(src0) >>> src1[4:0];
            `ALU_OR  : res = src0 | src1;
            `ALU_AND : res = src0 & src1;
        endcase
    end


endmodule