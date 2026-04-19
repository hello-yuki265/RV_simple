/*************************************************************************
 * @Copyright (c) 2026 by hello-yuki265, All Rights Reserved. 
 * @Author       : hello-yuki265
 * @Github       : 2658476808@qq.com
 * @Date         : 2026-04-17 12:27:28
 * @LastEditors  : hello-yuki265 2658476808@qq.com
 * @LastEditTime : 2026-04-19 10:00:54
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
    input [2:0] branch_type, //分支类型

    output reg [31:0] res,
    output reg branch_jump
);
    `include "glb_define.v"

    // -----------------
    // alu常规运算逻辑
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

    // ----------------------
    // branch指令比较逻辑
    // ----------------------
    always @(*) begin
        case (branch_type)
            3'b000: begin
                // beq
                branch_jump = src0 == src1;
            end
            3'b001: begin
                // bne
                branch_jump = src0 != src1;
            end
            3'b100: begin
                // blt
                branch_jump = $signed(src0) < $signed(src1);
            end
            3'b101: begin
                // bge
                branch_jump = $signed(src0) >= $signed(src1);
            end
            3'b110: begin
                // bltu
                branch_jump = src0 < src1;
            end
            3'b111: begin
                // bgeu
                branch_jump = src0 >= src1;
            end
            default: begin
                branch_jump = 0;
            end

        endcase
    end


endmodule