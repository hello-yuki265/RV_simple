/*************************************************************************
 * @Copyright (c) 2026 by hello-yuki265, All Rights Reserved. 
 * @Author       : hello-yuki265
 * @Github       : 2658476808@qq.com
 * @Date         : 2026-04-22 15:26:59
 * @LastEditors  : hello-yuki265 2658476808@qq.com
 * @LastEditTime : 2026-04-22 16:20:33
 * @FilePath     : \RV_simple\rtl\pipreg_if2id.v
 * @Description  : 
 *************************************************************************/

`include "glb_define.v"
module pipreg_if2id(
    input clk,
    input rst_n,

    input [`PC_WIDTH-1:0] instr_d,
    output reg [`PC_WIDTH-1:0] instr_q,
    output reg [4:0] q_rs1,
    output reg [4:0] q_rs2,
    output reg [4:0] q_rd
);

    always @(posedge clk) begin
        if (!rst_n) begin
            instr_q <= `PC_WIDTH'b0;
        end else begin
            instr_q <= instr_d;
            q_rs1 <= instr_d[19:15];
            q_rs2 <= instr_d[24:20];
            q_rd  <= instr_d[11:7];
        end
        
    end
endmodule