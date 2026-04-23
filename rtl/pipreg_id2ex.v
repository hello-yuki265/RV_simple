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
    input d_ctrlu_is_load,
    input d_ctrlu_is_imm,
    input d_ctrlu_is_store,
    input d_ctrlu_is_rtype,
    input d_ctrlu_is_btype,
    input d_ctrlu_is_jtype,
    input d_ctrlu_is_jalr,
    input d_ctrlu_is_lui,
    input d_ctrlu_is_auipc,
    input d_ctrlu_is_system,
    input d_ctrlu_is_trap,
    input d_ctrlu_is_ret,
    input d_ctrlu_is_csr,
    input [2:0] d_ctrlu_load_type,
    input [2:0] d_ctrlu_store_type,
    input [2:0] d_ctrlu_branch_type,
    input [`CSR_DEC_INFO_WIDTH-1:0] d_ctrlu_csr_dec_bus,
    input [`TRAP_DEC_INFO_WIDTH-1:0] d_ctrlu_trap_dec_bus,
    input [`WB_MUX_WIDTH-1:0] d_ctrlu_res_src,
    input d_ctrlu_mem_write,
    input [9:0] d_ctrlu_alu_ctrl,
    input d_ctrlu_alu0_src,
    input d_ctrlu_alu1_src,
    input d_ctrlu_reg_write,

    

    output reg q_ctrlu_is_load,
    output reg q_ctrlu_is_imm,
    output reg q_ctrlu_is_store,
    output reg q_ctrlu_is_rtype,
    output reg q_ctrlu_is_btype,
    output reg q_ctrlu_is_jtype,
    output reg q_ctrlu_is_jalr,
    output reg q_ctrlu_is_lui,
    output reg q_ctrlu_is_auipc,
    output reg q_ctrlu_is_system,
    output reg q_ctrlu_is_trap,
    output reg q_ctrlu_is_ret,
    output reg q_ctrlu_is_csr,
    output reg [2:0] q_ctrlu_load_type,
    output reg [2:0] q_ctrlu_store_type,
    output reg [2:0] q_ctrlu_branch_type,
    output reg [`CSR_DEC_INFO_WIDTH-1:0] q_ctrlu_csr_dec_bus,
    output reg [`TRAP_DEC_INFO_WIDTH-1:0] q_ctrlu_trap_dec_bus,
    output reg [`WB_MUX_WIDTH-1:0] q_ctrlu_res_src,
    output reg q_ctrlu_mem_write,
    output reg [9:0] q_ctrlu_alu_ctrl,
    output reg q_ctrlu_alu0_src,
    output reg q_ctrlu_alu1_src,
    output reg q_ctrlu_reg_write,

    // -------------------
    // imm extend
    // -------------------
    input [31:0] d_imm,
    output reg [31:0] q_imm,


    // -------------------------
    // regfile signals
    // -------------------------
    input [4:0] d_regf_rs1,
    input [4:0] d_regf_rs2,
    input [31:0] d_regf_rs1_data,
    input [31:0] d_regf_rs2_data,
    input [4:0]  d_regf_rd,
    input [31:0] d_regf_rd_data,
    input        d_regf_rd_write,

    output reg [4:0] q_regf_rs1,
    output reg [4:0] q_regf_rs2,
    output reg [31:0] q_regf_rs1_data,
    output reg [31:0] q_regf_rs2_data,
    output reg [4:0]  q_regf_rd,
    output reg [31:0] q_regf_rd_data, 
    output reg        q_regf_rd_write,

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
            q_ctrlu_is_load      <= 1'b0;
            q_ctrlu_is_imm       <= 1'b0;
            q_ctrlu_is_store     <= 1'b0;
            q_ctrlu_is_rtype     <= 1'b0;
            q_ctrlu_is_btype     <= 1'b0;
            q_ctrlu_is_jtype     <= 1'b0;
            q_ctrlu_is_jalr      <= 1'b0;
            q_ctrlu_is_lui       <= 1'b0;
            q_ctrlu_is_auipc     <= 1'b0;
            q_ctrlu_is_system    <= 1'b0;
            q_ctrlu_is_trap      <= 1'b0;
            q_ctrlu_is_ret       <= 1'b0;
            q_ctrlu_is_csr       <= 1'b0;
            q_ctrlu_load_type    <= 3'b0;
            q_ctrlu_store_type   <= 3'b0;
            q_ctrlu_branch_type  <= 3'b0;
            q_ctrlu_csr_dec_bus  <= `CSR_DEC_INFO_WIDTH'b0;
            q_ctrlu_trap_dec_bus <= `TRAP_DEC_INFO_WIDTH'b0;
            q_ctrlu_res_src      <= `WB_MUX_WIDTH'b0;
            q_ctrlu_mem_write    <= 1'b0;
            q_ctrlu_alu_ctrl     <= 10'b0;
            q_ctrlu_alu0_src     <= 1'b0;
            q_ctrlu_alu1_src     <= 1'b0;
            q_ctrlu_reg_write    <= 1'b0;
        end else if (flush) begin
            q_ctrlu_is_load      <= 1'b0;
            q_ctrlu_is_imm       <= 1'b0;
            q_ctrlu_is_store     <= 1'b0;
            q_ctrlu_is_rtype     <= 1'b0;
            q_ctrlu_is_btype     <= 1'b0;
            q_ctrlu_is_jtype     <= 1'b0;
            q_ctrlu_is_jalr      <= 1'b0;
            q_ctrlu_is_lui       <= 1'b0;
            q_ctrlu_is_auipc     <= 1'b0;
            q_ctrlu_is_system    <= 1'b0;
            q_ctrlu_is_trap      <= 1'b0;
            q_ctrlu_is_ret       <= 1'b0;
            q_ctrlu_is_csr       <= 1'b0;
            q_ctrlu_load_type    <= 3'b0;
            q_ctrlu_store_type   <= 3'b0;
            q_ctrlu_branch_type  <= 3'b0;
            q_ctrlu_csr_dec_bus  <= `CSR_DEC_INFO_WIDTH'b0;
            q_ctrlu_trap_dec_bus <= `TRAP_DEC_INFO_WIDTH'b0;
            q_ctrlu_res_src      <= `WB_MUX_WIDTH'b0;
            q_ctrlu_mem_write    <= 1'b0;
            q_ctrlu_alu_ctrl     <= 10'b0;
            q_ctrlu_alu0_src     <= 1'b0;
            q_ctrlu_alu1_src     <= 1'b0;
            q_ctrlu_reg_write    <= 1'b0;
        end else begin
        // --------------------
        // ctrlu signals
        // --------------------
        q_ctrlu_is_load      <= d_ctrlu_is_load;
        q_ctrlu_is_imm       <= d_ctrlu_is_imm;
        q_ctrlu_is_store     <= d_ctrlu_is_store;
        q_ctrlu_is_rtype     <= d_ctrlu_is_rtype;
        q_ctrlu_is_btype     <= d_ctrlu_is_btype;
        q_ctrlu_is_jtype     <= d_ctrlu_is_jtype;
        q_ctrlu_is_jalr      <= d_ctrlu_is_jalr;
        q_ctrlu_is_lui       <= d_ctrlu_is_lui;
        q_ctrlu_is_auipc     <= d_ctrlu_is_auipc;
        q_ctrlu_is_system    <= d_ctrlu_is_system;
        q_ctrlu_is_trap      <= d_ctrlu_is_trap;
        q_ctrlu_is_ret       <= d_ctrlu_is_ret;
        q_ctrlu_is_csr       <= d_ctrlu_is_csr;
        q_ctrlu_load_type    <= d_ctrlu_load_type;
        q_ctrlu_store_type   <= d_ctrlu_store_type;
        q_ctrlu_branch_type  <= d_ctrlu_branch_type;
        q_ctrlu_csr_dec_bus  <= d_ctrlu_csr_dec_bus;
        q_ctrlu_trap_dec_bus <= d_ctrlu_trap_dec_bus;
        q_ctrlu_res_src      <= d_ctrlu_res_src;
        q_ctrlu_mem_write    <= d_ctrlu_mem_write;
        q_ctrlu_alu_ctrl     <= d_ctrlu_alu_ctrl;
        q_ctrlu_alu0_src     <= d_ctrlu_alu0_src;
        q_ctrlu_alu1_src     <= d_ctrlu_alu1_src;
        q_ctrlu_reg_write    <= d_ctrlu_reg_write;
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
            q_regf_rs1      <= 5'b0;
            q_regf_rs2      <= 5'b0;
            q_regf_rs1_data <= 32'b0;
            q_regf_rs2_data <= 32'b0;
            q_regf_rd       <= 5'b0;
            q_regf_rd_data  <= 32'b0;
            q_regf_rd_write <= 1'b0;
        end else if (flush) begin
            q_regf_rs1      <= 5'b0;
            q_regf_rs2      <= 5'b0;
            q_regf_rs1_data <= 32'b0;
            q_regf_rs2_data <= 32'b0;
            q_regf_rd       <= 5'b0;
            q_regf_rd_data  <= 32'b0;
            q_regf_rd_write <= 1'b0;
        end else begin
            q_regf_rs1 <= d_regf_rs1;
            q_regf_rs2 <= d_regf_rs2;
            q_regf_rs1_data <= d_regf_rs1_data;
            q_regf_rs2_data <= d_regf_rs2_data;
            q_regf_rd       <= d_regf_rd;
            q_regf_rd_data  <= d_regf_rd_data;
            q_regf_rd_write <= d_regf_rd_write;
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
