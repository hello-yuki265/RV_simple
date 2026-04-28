/*************************************************************************
 * @Copyright (c) 2026 by hello-yuki265, All Rights Reserved.
 * @Author       : hello-yuki265
 * @Github       : 2658476808@qq.com
 * @Date         : 2026-04-22 15:27:34
 * @LastEditors  : hello-yuki265 2658476808@qq.com
 * @LastEditTime : 2026-04-22 17:18:00
 * @FilePath     : \RV_simple\rtl\pipreg_ex2mem.v
 * @Description  :
 *************************************************************************/
`include "glb_define.v"
module pipreg_ex2mem(
    input clk,
    input rst_n,
    input flush,

    // --------------------
    // MEM stage controls
    // --------------------
    input [`INSTR_TYPE_WIDTH-1:0] d_instr_type_bus,
    input d_mem_write,
    input [2:0] d_load_type,
    input [2:0] d_store_type,

    output reg [`INSTR_TYPE_WIDTH-1:0] q_instr_type_bus,
    output reg q_mem_write,
    output reg [2:0] q_load_type,
    output reg [2:0] q_store_type,

    // --------------------
    // WB stage controls
    // --------------------
    input [`WB_MUX_WIDTH-1:0] d_res_src,
    input d_reg_write,

    output reg [`WB_MUX_WIDTH-1:0] q_res_src,
    output reg q_reg_write,

    // --------------------
    // EX/MEM datapath
    // --------------------
    input [31:0] d_alu_res,
    input d_branch_jump,
    input [4:0] d_rs2,
    input [31:0] d_rs2_data,

    output reg [31:0] q_alu_res,
    output reg q_branch_jump,
    output reg [4:0] q_rs2,
    output reg [31:0] q_rs2_data,

    // --------------------
    // WB payload
    // --------------------
    input [4:0] d_rd,
    input [31:0] d_pc_plus4,
    input [31:0] d_imm,
    input [`MXLEN-1:0] d_csr_rd_dat,

    output reg [4:0] q_rd,
    output reg [31:0] q_pc_plus4,
    output reg [31:0] q_imm,
    output reg [`MXLEN-1:0] q_csr_rd_dat,

    // --------------------
    // CSR/Trap payload
    // --------------------
    input d_csr_wr_en,
    input d_csr_rd_en,
    input [11:0] d_csr_idx,
    input [`MXLEN-1:0] d_csr_wb_dat,

    input d_trap_cause_en,
    input [`MXLEN-1:0] d_trap_cause_val,
    input d_trap_mepc_en,
    input [`MXLEN-1:0] d_trap_mepc_val,
    input d_trap_mstatus_en,
    input d_trap_mret_en,
    input d_trap_mscratch_en,
    input [`PC_WIDTH-1:0] d_trap_targ_pc,

    output reg q_csr_wr_en,
    output reg q_csr_rd_en,
    output reg [11:0] q_csr_idx,
    output reg [`MXLEN-1:0] q_csr_wb_dat,

    output reg q_trap_cause_en,
    output reg [`MXLEN-1:0] q_trap_cause_val,
    output reg q_trap_mepc_en,
    output reg [`MXLEN-1:0] q_trap_mepc_val,
    output reg q_trap_mstatus_en,
    output reg q_trap_mret_en,
    output reg q_trap_mscratch_en,
    output reg [`PC_WIDTH-1:0] q_trap_targ_pc
);

    // --------------------
    // MEM stage controls
    // --------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q_instr_type_bus <= `INSTR_TYPE_WIDTH'b0;
            q_mem_write      <= 1'b0;
            q_load_type      <= 3'b0;
            q_store_type     <= 3'b0;
        end else if (flush) begin
            q_instr_type_bus <= `INSTR_TYPE_WIDTH'b0;
            q_mem_write      <= 1'b0;
            q_load_type      <= 3'b0;
            q_store_type     <= 3'b0;
        end else begin
            q_instr_type_bus <= d_instr_type_bus;
            q_mem_write      <= d_mem_write;
            q_load_type      <= d_load_type;
            q_store_type     <= d_store_type;
        end
    end

    // --------------------
    // WB stage controls
    // --------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q_res_src   <= `WB_MUX_WIDTH'b0;
            q_reg_write <= 1'b0;
        end else if (flush) begin
            q_res_src   <= `WB_MUX_WIDTH'b0;
            q_reg_write <= 1'b0;
        end else begin
            q_res_src   <= d_res_src;
            q_reg_write <= d_reg_write;
        end
    end

    // --------------------
    // EX/MEM datapath
    // --------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q_alu_res     <= 32'b0;
            q_branch_jump <= 1'b0;
            q_rs2         <= 5'b0;
            q_rs2_data    <= 32'b0;
        end else if (flush) begin
            q_alu_res     <= 32'b0;
            q_branch_jump <= 1'b0;
            q_rs2         <= 5'b0;
            q_rs2_data    <= 32'b0;
        end else begin
            q_alu_res     <= d_alu_res;
            q_branch_jump <= d_branch_jump;
            q_rs2         <= d_rs2;
            q_rs2_data    <= d_rs2_data;
        end
    end

    // --------------------
    // WB payload
    // --------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q_rd          <= 5'b0;
            q_pc_plus4    <= 32'b0;
            q_imm         <= 32'b0;
            q_csr_rd_dat    <= `MXLEN'b0;
        end else if (flush) begin
            q_rd          <= 5'b0;
            q_pc_plus4    <= 32'b0;
            q_imm         <= 32'b0;
            q_csr_rd_dat    <= `MXLEN'b0;
        end else begin
            q_rd          <= d_rd;
            q_pc_plus4    <= d_pc_plus4;
            q_imm         <= d_imm;
            q_csr_rd_dat    <= d_csr_rd_dat;
        end
    end

    // --------------------
    // CSR/Trap payload
    // --------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q_csr_wr_en        <= 1'b0;
            q_csr_rd_en        <= 1'b0;
            q_csr_idx          <= 12'b0;
            q_csr_wb_dat       <= `MXLEN'b0;

            q_trap_cause_en    <= 1'b0;
            q_trap_cause_val   <= `MXLEN'b0;
            q_trap_mepc_en     <= 1'b0;
            q_trap_mepc_val    <= `MXLEN'b0;
            q_trap_mstatus_en  <= 1'b0;
            q_trap_mret_en     <= 1'b0;
            q_trap_mscratch_en <= 1'b0;
            q_trap_targ_pc     <= `PC_WIDTH'b0;
        end else if (flush) begin
            q_csr_wr_en        <= 1'b0;
            q_csr_rd_en        <= 1'b0;
            q_csr_idx          <= 12'b0;
            q_csr_wb_dat       <= `MXLEN'b0;

            q_trap_cause_en    <= 1'b0;
            q_trap_cause_val   <= `MXLEN'b0;
            q_trap_mepc_en     <= 1'b0;
            q_trap_mepc_val    <= `MXLEN'b0;
            q_trap_mstatus_en  <= 1'b0;
            q_trap_mret_en     <= 1'b0;
            q_trap_mscratch_en <= 1'b0;
            q_trap_targ_pc     <= `PC_WIDTH'b0;
        end else begin
            q_csr_wr_en        <= d_csr_wr_en;
            q_csr_rd_en        <= d_csr_rd_en;
            q_csr_idx          <= d_csr_idx;
            q_csr_wb_dat       <= d_csr_wb_dat;

            q_trap_cause_en    <= d_trap_cause_en;
            q_trap_cause_val   <= d_trap_cause_val;
            q_trap_mepc_en     <= d_trap_mepc_en;
            q_trap_mepc_val    <= d_trap_mepc_val;
            q_trap_mstatus_en  <= d_trap_mstatus_en;
            q_trap_mret_en     <= d_trap_mret_en;
            q_trap_mscratch_en <= d_trap_mscratch_en;
            q_trap_targ_pc     <= d_trap_targ_pc;
        end
    end

endmodule
