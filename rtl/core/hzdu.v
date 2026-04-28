/*************************************************************************
 * @Copyright (c) 2026 by hello-yuki265, All Rights Reserved. 
 * @Author       : hello-yuki265
 * @Github       : 2658476808@qq.com
 * @Date         : 2026-04-23 11:49:30
 * @LastEditors  : hello-yuki265 2658476808@qq.com
 * @LastEditTime : 2026-04-25 16:23:14
 * @FilePath     : \RV_simple\rtl\hzdu.v
 * @Description  : 
 *************************************************************************/
`include "glb_define.v"
module hzdu(
    input clk,
    input rst_n,

    // IF stage signals
    input if_pc_redirect,

    // ID stage signals
    input id_is_store,
    input id_alu_src1,
    input [4:0] id_rs1,
    input [4:0] id_rs2,

    // EX stage signals
    input ex_is_branch,
    input ex_is_store,
    input ex_is_load,
    input [4:0] ex_rs1,
    input [4:0] ex_rs2,
    input [4:0] ex_rd,
    input       ex_reg_write,
    input       ex_branch_jump,
    input       ex_csr_wr_en,
    input       ex_csr_rd_en,
    input [11:0] ex_csr_idx,

    // MEM stage signals
    input mem_is_store,
    input mem_is_load,
    input [4:0] mem_rs2,
    input [4:0] mem_rd,
    input       mem_reg_write,
    input       mem_csr_wr_en,
    input       mem_csr_rd_en,
    input [11:0] mem_csr_idx,

    // WB stage signals
    input [4:0] wb_rd,
    input       wb_reg_write,

    // forwarding signals
    output [1:0] forward_rs1,
    output [1:0] forward_rs2,
    output       store_forward_rs2,
    output       csr_forward,

    // control signals for stall and flush
    output flush_if2id,
    output flush_id2ex,
    output stall_if2id,
    output stall_if
);

    assign forward_rs1 = (!mem_is_load & mem_reg_write & (mem_rd == ex_rs1) & (ex_rs1 != 0)) ? `EX_FROM_MEM : 
                            (wb_reg_write & (wb_rd == ex_rs1) & (ex_rs1 != 0)) ? `EX_FROM_WB :
                            `EX_FROM_EX;
    assign forward_rs2 = (!mem_is_load & mem_reg_write & (mem_rd == ex_rs2) & (ex_rs2 != 0)) ? `EX_FROM_MEM : 
                            (wb_reg_write & (wb_rd == ex_rs2) & (ex_rs2 != 0)) ? `EX_FROM_WB : 
                            `EX_FROM_EX;
    assign csr_forward = mem_csr_wr_en & ex_csr_rd_en & (mem_csr_idx == ex_csr_idx);
    // load -> store
    assign store_forward_rs2 = mem_is_store & wb_reg_write & (wb_rd == mem_rs2) & (mem_rs2 != 0);

    // flush and stall
    wire need_stall = ex_is_load & ex_reg_write
                            & ((ex_rd == id_rs1 & id_rs1 != 0) 
                                // 这里是确保当前指令需要用到rs2，不加这里的话会有一些不必要的冒险检测，导致性能下降
                                //这里排除load后接store,这时发生冒险不应该stall，应该直接在mem阶段使用dmem的结果
                                | (!id_is_store & id_alu_src1 == `ALU_MUX_SRC1_RS2 & ex_rd == id_rs2 & id_rs2 != 0));
    assign flush_if2id  = if_pc_redirect;
    assign flush_id2ex  = need_stall | if_pc_redirect;
    assign stall_if2id  = need_stall;
    assign stall_if     = need_stall;


endmodule