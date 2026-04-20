/*************************************************************************
 * @Copyright (c) 2026 by hello-yuki265, All Rights Reserved. 
 * @Author       : hello-yuki265
 * @Github       : 2658476808@qq.com
 * @Date         : 2026-04-20 11:13:57
 * @LastEditors  : hello-yuki265 2658476808@qq.com
 * @LastEditTime : 2026-04-21 01:36:55
 * @FilePath     : \RV_simple\rtl\exu.v
 * @Description  : 
 *************************************************************************/
`include "glb_define.v"
 module exu(
    input clk,
    input rst_n,

    // ----------------
    // exu input signals
    // ----------------
    input [31:0] exu_src0,  //源0
    input [31:0] exu_src1,  //源1

    // ----------------
    // ALU interface
    // ----------------
    input [9:0]  alu_ctrl,  //计算模式选择,
                            //00: add
    output [31:0] alu_res,

    // ----------------
    // Branch interface
    // ----------------
    input [2:0] branch_type, //分支类型
    output reg branch_jump,

    // ----------------
    // CSR interface
    // ----------------
    input [`CSR_DEC_INFO_WIDTH-1:0] csr_dec_bus,
    output csr_wr_en,
    output csr_rd_en,
    input [`MXLEN-1:0] csr_rd_dat,
    output [11:0] csr_idx,
    output [`MXLEN-1:0] csr_wb_dat,

    // ----------------
    // exp interface
    // ----------------
    output sgl_cause_en,
    output [`MXLEN-1:0] sgl_cause_val,
    output sgl_mepc_en,
    output [`MXLEN-1:0] sgl_mepc_val,
    output sgl_mscratch_en
);

    alu  alu_inst (
    .clk(clk),
    .rst_n(rst_n),
    .alu_ctrl(alu_ctrl),
    .src0(exu_src0),
    .src1(exu_src1),
    .res(alu_res)
    );

    // ----------------------
    // branch compare logic
    // ----------------------
    always @(*) begin
        case (branch_type)
            3'b000: begin
                // beq
                branch_jump = exu_src0 == exu_src1;
            end
            3'b001: begin
                // bne
                branch_jump = exu_src0 != exu_src1;
            end
            3'b100: begin
                // blt
                branch_jump = $signed(exu_src0) < $signed(exu_src1);
            end
            3'b101: begin
                // bge
                branch_jump = $signed(exu_src0) >= $signed(exu_src1);
            end
            3'b110: begin
                // bltu
                branch_jump = exu_src0 < exu_src1;
            end
            3'b111: begin
                // bgeu
                branch_jump = exu_src0 >= exu_src1;
            end
            default: begin
                branch_jump = 0;
            end

        endcase
    end


    csr_ctrl  csr_ctrl_inst (
    .clk(clk),
    .rst_n(rst_n),
    .csr_dec_bus(csr_dec_bus),
    .csr_wr_en(csr_wr_en),
    .csr_rd_en(csr_rd_en),
    .csr_idx(csr_idx),
    .csr_i_rs1_dat(exu_src0),
    .csr_rd_dat(csr_rd_dat),
    .csr_wb_dat(csr_wb_dat)
    );
endmodule