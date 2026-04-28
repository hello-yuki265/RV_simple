/*************************************************************************
 * @Copyright (c) 2026 by hello-yuki265, All Rights Reserved. 
 * @Author       : hello-yuki265
 * @Github       : 2658476808@qq.com
 * @Date         : 2026-04-22 15:26:59
 * @LastEditors  : hello-yuki265 2658476808@qq.com
 * @LastEditTime : 2026-04-22 19:33:55
 * @FilePath     : \RV_simple\rtl\pipreg_if2id.v
 * @Description  : 
 *************************************************************************/

`include "glb_define.v"
module pipreg_if2id(
    input clk,
    input rst_n,
    input flush,
    input stall,

    input [`PC_WIDTH-1:0] d_pc,
    input [31:0] d_instr,

    output reg [`PC_WIDTH-1:0] q_pc,
    output reg [31:0] q_instr,
    output reg [4:0] q_rs1,
    output reg [4:0] q_rs2,
    output reg [4:0] q_rd
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q_pc    <= `PC_WIDTH'b0;
            q_instr <= 32'b0;
            q_rs1   <= 5'b0;
            q_rs2   <= 5'b0;
            q_rd    <= 5'b0;
        end else if (flush) begin
            q_pc    <= `PC_WIDTH'b0;
            q_instr <= 32'b0;
            q_rs1   <= 5'b0;
            q_rs2   <= 5'b0;
            q_rd    <= 5'b0;
        end else if (!stall)begin
            q_pc <= d_pc;
            q_instr <= d_instr;
            q_rs1 <= d_instr[19:15];
            q_rs2 <= d_instr[24:20];
            q_rd  <= d_instr[11:7];
        end
        
    end
endmodule
