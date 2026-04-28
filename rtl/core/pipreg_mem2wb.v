/*************************************************************************
 * @Copyright (c) 2026 by hello-yuki265, All Rights Reserved. 
 * @Author       : hello-yuki265
 * @Github       : 2658476808@qq.com
 * @Date         : 2026-04-22 15:27:46
 * @LastEditors  : hello-yuki265 2658476808@qq.com
 * @LastEditTime : 2026-04-22 17:35:51
 * @FilePath     : \RV_simple\rtl\pipreg_mem2wb.v
 * @Description  :
 *************************************************************************/
`include "glb_define.v"
module pipreg_mem2wb(
    input clk,
    input rst_n,
    input flush,

    input [`INSTR_TYPE_WIDTH-1:0] d_instr_type_bus,
    input d_reg_write,
    input [`WB_MUX_WIDTH-1:0] d_res_src,
    input [31:0] d_mem_rd_data,
    input [31:0] d_alu_res,

    output reg [`INSTR_TYPE_WIDTH-1:0] q_instr_type_bus,
    output reg q_reg_write,
    output reg [`WB_MUX_WIDTH-1:0] q_res_src,
    output reg [31:0] q_mem_rd_data,
    output reg [31:0] q_alu_res,

    input [4:0] d_rd,
    input [31:0] d_pc_plus4,
    input [31:0] d_imm,
    input [`MXLEN-1:0] d_csr_rd_dat,

    output reg [4:0] q_rd,
    output reg [31:0] q_pc_plus4,
    output reg [31:0] q_imm,
    output reg [`MXLEN-1:0] q_csr_rd_dat
);


    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q_instr_type_bus <= `INSTR_TYPE_WIDTH'b0;
            q_reg_write      <= 1'b0;
            q_res_src        <= `WB_MUX_WIDTH'b0;
            q_mem_rd_data     <= 32'b0;
            q_alu_res         <= 32'b0;

            q_rd          <= 5'b0;
            q_pc_plus4    <= 32'b0;
            q_imm         <= 32'b0;
            q_csr_rd_dat    <= `MXLEN'b0;
        end else if (flush) begin
            q_instr_type_bus <= `INSTR_TYPE_WIDTH'b0;
            q_reg_write      <= 1'b0;
            q_res_src        <= `WB_MUX_WIDTH'b0;
            q_mem_rd_data     <= 32'b0;
            q_alu_res         <= 32'b0;

            q_rd          <= 5'b0;
            q_pc_plus4    <= 32'b0;
            q_imm         <= 32'b0;
            q_csr_rd_dat    <= `MXLEN'b0;
        end else begin
            q_instr_type_bus <= d_instr_type_bus;
            q_reg_write      <= d_reg_write;
            q_res_src        <= d_res_src;
            q_mem_rd_data     <= d_mem_rd_data;
            q_alu_res         <= d_alu_res;

            q_rd          <= d_rd;
            q_pc_plus4    <= d_pc_plus4;
            q_imm         <= d_imm;
            q_csr_rd_dat    <= d_csr_rd_dat;
        end
    end
endmodule
