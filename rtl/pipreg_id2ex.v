/*************************************************************************
 * @Copyright (c) 2026 by hello-yuki265, All Rights Reserved. 
 * @Author       : hello-yuki265
 * @Github       : 2658476808@qq.com
 * @Date         : 2026-04-22 15:27:21
 * @LastEditors  : hello-yuki265 2658476808@qq.com
 * @LastEditTime : 2026-04-23 13:48:43
 * @FilePath     : \RV_simple\rtl\pipreg_id2ex.v
 * @Description  : 
 *************************************************************************/
`include "glb_define.v"
 module pipreg_id2ex(
    input clk,
    input rst_n,
    input flush,

    input [31:0] d_pc,
    output reg [31:0] q_pc,
    // --------------------
    // ctrlu signals
    // --------------------
    input [`INSTR_TYPE_WIDTH-1:0] d_instr_type_bus,
    input [2:0] d_load_type,
    input [2:0] d_store_type,
    input [2:0] d_branch_type,
    input [`CSR_DEC_INFO_WIDTH-1:0] d_csr_dec_bus,
    input [`TRAP_DEC_INFO_WIDTH-1:0] d_trap_dec_bus,
    input [`WB_MUX_WIDTH-1:0] d_res_src,
    input d_mem_write,
    input [9:0] d_alu_ctrl,
    input d_alu0_src,
    input d_alu1_src,
    input d_reg_write,

    

    output reg [`INSTR_TYPE_WIDTH-1:0] q_instr_type_bus,
    output reg [2:0] q_load_type,
    output reg [2:0] q_store_type,
    output reg [2:0] q_branch_type,
    output reg [`CSR_DEC_INFO_WIDTH-1:0] q_csr_dec_bus,
    output reg [`TRAP_DEC_INFO_WIDTH-1:0] q_trap_dec_bus,
    output reg [`WB_MUX_WIDTH-1:0] q_res_src,
    output reg q_mem_write,
    output reg [9:0] q_alu_ctrl,
    output reg q_alu0_src,
    output reg q_alu1_src,
    output reg q_reg_write,

    // -------------------
    // imm extend
    // -------------------
    input [31:0] d_imm,
    output reg [31:0] q_imm,


    // -------------------------
    // regfile signals
    // -------------------------
    input [4:0] d_rs1,
    input [4:0] d_rs2,
    input [31:0] d_rs1_data,
    input [31:0] d_rs2_data,
    input [4:0]  d_rd,
    input [31:0] d_rd_data,
    input        d_rd_write,

    output reg [4:0] q_rs1,
    output reg [4:0] q_rs2,
    output reg [31:0] q_rs1_data,
    output reg [31:0] q_rs2_data,
    output reg [4:0]  q_rd,
    output reg [31:0] q_rd_data,
    output reg        q_rd_write,

    // -------------------------
    // CSR signals
    // -------------------------
    input [`MXLEN-1:0]  d_csr_rd_dat,
    input [`MXLEN-1:0]  d_csr_stl_mtvec,
    input [`MXLEN-1:0]  d_csr_stl_mepc,

    output reg [`MXLEN-1:0]  q_csr_rd_dat,
    output reg [`MXLEN-1:0]  q_csr_stl_mtvec,
    output reg [`MXLEN-1:0]  q_csr_stl_mepc
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q_pc <= 32'b0;
        end else if (flush) begin
            q_pc <= 32'b0;
        end else begin
            q_pc <= d_pc;
        end
    end
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q_instr_type_bus <= `INSTR_TYPE_WIDTH'b0;
            q_load_type      <= 3'b0;
            q_store_type     <= 3'b0;
            q_branch_type    <= 3'b0;
            q_csr_dec_bus    <= `CSR_DEC_INFO_WIDTH'b0;
            q_trap_dec_bus   <= `TRAP_DEC_INFO_WIDTH'b0;
            q_res_src        <= `WB_MUX_WIDTH'b0;
            q_mem_write      <= 1'b0;
            q_alu_ctrl       <= 10'b0;
            q_alu0_src       <= 1'b0;
            q_alu1_src       <= 1'b0;
            q_reg_write      <= 1'b0;
        end else if (flush) begin
            q_instr_type_bus <= `INSTR_TYPE_WIDTH'b0;
            q_load_type      <= 3'b0;
            q_store_type     <= 3'b0;
            q_branch_type    <= 3'b0;
            q_csr_dec_bus    <= `CSR_DEC_INFO_WIDTH'b0;
            q_trap_dec_bus   <= `TRAP_DEC_INFO_WIDTH'b0;
            q_res_src        <= `WB_MUX_WIDTH'b0;
            q_mem_write      <= 1'b0;
            q_alu_ctrl       <= 10'b0;
            q_alu0_src       <= 1'b0;
            q_alu1_src       <= 1'b0;
            q_reg_write      <= 1'b0;
        end else begin
        // --------------------
        // ctrlu signals
        // --------------------
        q_instr_type_bus <= d_instr_type_bus;
        q_load_type      <= d_load_type;
        q_store_type     <= d_store_type;
        q_branch_type    <= d_branch_type;
        q_csr_dec_bus    <= d_csr_dec_bus;
        q_trap_dec_bus   <= d_trap_dec_bus;
        q_res_src        <= d_res_src;
        q_mem_write      <= d_mem_write;
        q_alu_ctrl       <= d_alu_ctrl;
        q_alu0_src       <= d_alu0_src;
        q_alu1_src       <= d_alu1_src;
        q_reg_write      <= d_reg_write;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q_imm <= 32'b0;
        end else if (flush) begin
            q_imm <= 32'b0;
        end else begin
            q_imm <= d_imm;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q_rs1      <= 5'b0;
            q_rs2      <= 5'b0;
            q_rs1_data <= 32'b0;
            q_rs2_data <= 32'b0;
            q_rd       <= 5'b0;
            q_rd_data  <= 32'b0;
            q_rd_write <= 1'b0;
        end else if (flush) begin
            q_rs1      <= 5'b0;
            q_rs2      <= 5'b0;
            q_rs1_data <= 32'b0;
            q_rs2_data <= 32'b0;
            q_rd       <= 5'b0;
            q_rd_data  <= 32'b0;
            q_rd_write <= 1'b0;
        end else begin
            q_rs1      <= d_rs1;
            q_rs2      <= d_rs2;
            q_rs1_data <= d_rs1_data;
            q_rs2_data <= d_rs2_data;
            q_rd       <= d_rd;
            q_rd_data  <= d_rd_data;
            q_rd_write <= d_rd_write;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q_csr_rd_dat    <= `MXLEN'b0;
            q_csr_stl_mtvec <= `MXLEN'b0;
            q_csr_stl_mepc  <= `MXLEN'b0;
        end else if (flush) begin
            q_csr_rd_dat    <= `MXLEN'b0;
            q_csr_stl_mtvec <= `MXLEN'b0;
            q_csr_stl_mepc  <= `MXLEN'b0;
        end else begin
            q_csr_rd_dat    <= d_csr_rd_dat;
            q_csr_stl_mtvec <= d_csr_stl_mtvec;
            q_csr_stl_mepc  <= d_csr_stl_mepc;
        end
    end
endmodule
