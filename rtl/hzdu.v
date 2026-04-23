/*************************************************************************
 * @Copyright (c) 2026 by hello-yuki265, All Rights Reserved. 
 * @Author       : hello-yuki265
 * @Github       : 2658476808@qq.com
 * @Date         : 2026-04-23 11:49:30
 * @LastEditors  : hello-yuki265 2658476808@qq.com
 * @LastEditTime : 2026-04-23 21:24:45
 * @FilePath     : \RV_simple\rtl\hzdu.v
 * @Description  : 
 *************************************************************************/
`include "glb_define.v"
module hzdu(
    input clk,
    input rst_n,

    input id_alu_src1,
    input [`WB_MUX_WIDTH-1:0]ex_res_src,
    input [`WB_MUX_WIDTH-1:0]mem_res_src,
    input [4:0] id_rs1,
    input [4:0] id_rs2,
    input [4:0] ex_rs1,
    input [4:0] ex_rs2,

    input [4:0] ex_rd,
    input       ex_reg_write,
    input [4:0] mem_rd,
    input       mem_reg_write,
    input [4:0] wb_rd,
    input       wb_reg_write,

    output [1:0] forward_rs1,
    output [1:0] forward_rs2,

    output flush_id2ex,
    output stall_if2id,
    output stall_if
);

    assign forward_rs1 = (mem_res_src != `WB_MUX_MEM & mem_reg_write & (mem_rd == ex_rs1) & (ex_rs1 != 0)) ? `EX_FROM_MEM : 
                            (wb_reg_write & (wb_rd == ex_rs1) & (ex_rs1 != 0)) ? `EX_FROM_WB :
                            `EX_FROM_EX;
    assign forward_rs2 = (mem_res_src != `WB_MUX_MEM & mem_reg_write & (mem_rd == ex_rs2) & (ex_rs2 != 0)) ? `EX_FROM_MEM : 
                            (wb_reg_write & (wb_rd == ex_rs2) & (ex_rs2 != 0)) ? `EX_FROM_WB : 
                            `EX_FROM_EX;

    // flush and stall
    assign need_stall = ex_res_src == `WB_MUX_MEM & ex_reg_write 
                            & ((ex_rd == id_rs1 & id_rs1 != 0) 
                                | (id_alu_src1 == `ALU_MUX_SRC1_RS2 & ex_rd == id_rs2 & id_rs2 != 0));
    assign flush_id2ex  = need_stall;
    assign stall_if2id  = need_stall;
    assign stall_if     = need_stall;


endmodule