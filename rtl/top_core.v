/*************************************************************************
 * @Copyright (c) 2026 by hello-yuki265, All Rights Reserved.
 * @Author       : hello-yuki265
 * @Github       : 2658476808@qq.com
 * @Date         : 2026-04-17 15:05:46
 * @LastEditors  : hello-yuki265 2658476808@qq.com
 * @LastEditTime : 2026-04-22 20:28:00
 * @FilePath     : \RV_simple\rtl\top_core.v
 * @Description  :
 *************************************************************************/
`include "glb_define.v"
module top_core(
    clk,
    rst_n
);

    input clk;
    input rst_n;

    // ================================
    // stage op signals
    // ================================
    // IF
    reg [31:0] if_pc;
    wire [31:0] if_instr;
    wire [31:0] if_pc_plus4;
    wire [1:0] if_pc_src;

    // ID
    wire [31:0] id_pc;
    wire [31:0] id_instr;
    wire [4:0] id_rs1;
    wire [4:0] id_rs2;
    wire [4:0] id_rd;
    wire [31:0] id_imm;

    // EX
    wire [31:0] ex_pc;
    wire [31:0] ex_imm;
    wire [31:0] ex_pc_plus4;
    wire [31:0] ex_alu_src0;
    wire [31:0] ex_alu_src1;

    // MEM
    wire [31:0] mem_dmem_rd_data;

    // WB
    reg [31:0] wb_regf_rd_data;

    // ================================
    // inst_mem ports
    // ================================
    // pipeline-participating
    wire [31:0] if_imem_pc;
    wire [31:0] if_imem_instr;

    // ================================
    // ctrl_unit ports
    // ================================
    // pipeline-participating (ID)
    wire id_ctrlu_is_load;
    wire id_ctrlu_is_imm;
    wire id_ctrlu_is_store;
    wire id_ctrlu_is_rtype;
    wire id_ctrlu_is_btype;
    wire id_ctrlu_is_jtype;
    wire id_ctrlu_is_jalr;
    wire id_ctrlu_is_lui;
    wire id_ctrlu_is_auipc;
    wire id_ctrlu_is_system;
    wire id_ctrlu_is_trap;
    wire id_ctrlu_is_ret;
    wire id_ctrlu_is_csr;
    wire [2:0] id_ctrlu_load_type;
    wire [2:0] id_ctrlu_store_type;
    wire [2:0] id_ctrlu_branch_type;
    wire [`CSR_DEC_INFO_WIDTH-1:0] id_ctrlu_csr_dec_bus;
    wire [`TRAP_DEC_INFO_WIDTH-1:0] id_ctrlu_trap_dec_bus;
    wire [`WB_MUX_WIDTH-1:0] id_ctrlu_res_src;
    wire id_ctrlu_mem_write;
    wire [9:0] id_ctrlu_alu_ctrl;
    wire id_ctrlu_alu0_src;
    wire id_ctrlu_alu1_src;
    wire [2:0] id_ctrlu_imm_src;
    wire id_ctrlu_reg_write;

    // ================================
    // regfile ports
    // ================================
    // pipeline-participating (ID read / WB write)
    wire [4:0] id_regf_rs1;
    wire [4:0] id_regf_rs2;
    wire [31:0] id_regf_rs1_data;
    wire [31:0] id_regf_rs2_data;
    wire [4:0] wb_regf_rd;
    wire wb_regf_rd_write;

    // non-pipeline/global
    wire [31:0] wb_regf_rd_data_w;

    // ================================
    // csr ports
    // ================================
    // pipeline-participating (MEM commit side)
    wire mem_csr_wr_en;
    wire [11:0] mem_csr_wr_idx;
    wire [`MXLEN-1:0] mem_csr_wb_dat;
    wire mem_csr_sgl_cause_en;
    wire [`MXLEN-1:0] mem_csr_sgl_cause_val;
    wire mem_csr_sgl_mepc_en;
    wire [`MXLEN-1:0] mem_csr_sgl_mepc_val;
    wire mem_csr_sgl_mscratch_en;
    wire mem_csr_sgl_mstatus_en;
    wire mem_csr_sgl_mret_en;

    // non-pipeline (EX read side)
    wire ex_csr_rd_en;
    wire [11:0] ex_csr_rd_idx;
    wire [`MXLEN-1:0] ex_csr_rd_dat;

    // mixed-stage mux / csr outputs
    wire [11:0] exmem_csr_i_idx_mux;
    wire [`MXLEN-1:0] ex_csr_o_rd_dat;
    wire [`MXLEN-1:0] id_csr_o_stl_mtvec_raw;
    wire [`MXLEN-1:0] id_csr_o_stl_mepc_raw;

    // ================================
    // ID/EX pipreg ports
    // ================================
    // pipeline-participating outputs (EX)
    wire ex_ctrlu_is_load;
    wire ex_ctrlu_is_imm;
    wire ex_ctrlu_is_store;
    wire ex_ctrlu_is_rtype;
    wire ex_ctrlu_is_btype;
    wire ex_ctrlu_is_jtype;
    wire ex_ctrlu_is_jalr;
    wire ex_ctrlu_is_lui;
    wire ex_ctrlu_is_auipc;
    wire ex_ctrlu_is_system;
    wire ex_ctrlu_is_trap;
    wire ex_ctrlu_is_ret;
    wire ex_ctrlu_is_csr;
    wire [2:0] ex_ctrlu_load_type;
    wire [2:0] ex_ctrlu_store_type;
    wire [2:0] ex_ctrlu_branch_type;
    wire [`CSR_DEC_INFO_WIDTH-1:0] ex_ctrlu_csr_dec_bus;
    wire [`TRAP_DEC_INFO_WIDTH-1:0] ex_ctrlu_trap_dec_bus;
    wire [`WB_MUX_WIDTH-1:0] ex_ctrlu_res_src;
    wire ex_ctrlu_mem_write;
    wire [9:0] ex_ctrlu_alu_ctrl;
    wire ex_ctrlu_alu0_src;
    wire ex_ctrlu_alu1_src;
    wire ex_ctrlu_reg_write;
    wire [31:0] ex_regf_rs1_data;
    wire [31:0] ex_regf_rs2_data;
    wire [4:0] ex_regf_rd;
    wire [`MXLEN-1:0] ex_csr_stl_mtvec;
    wire [`MXLEN-1:0] ex_csr_stl_mepc;

    // non-pipeline/unused bundle (to match module ports)
    wire [31:0] id_regf_rd_data_unused;
    wire id_regf_rd_write_unused;
    wire [`MXLEN-1:0] id_csr_rd_dat_pipe_unused;
    wire [`MXLEN-1:0] id_csr_stl_mtvec;
    wire [`MXLEN-1:0] id_csr_stl_mepc;
    wire [31:0] ex_regf_rd_data_unused;
    wire ex_regf_rd_write_unused;
    wire [`MXLEN-1:0] ex_csr_rd_dat_pipe_unused;

    // ================================
    // exu ports
    // ================================
    // pipeline-participating (EX outputs)
    wire [31:0] ex_exu_alu_res;
    wire ex_exu_branch_jump;
    wire ex_exu_csr_wr_en;
    wire ex_exu_csr_rd_en;
    wire [11:0] ex_exu_csr_idx;
    wire [`MXLEN-1:0] ex_exu_csr_wb_dat;
    wire ex_exu_trap_cause_en;
    wire [`MXLEN-1:0] ex_exu_trap_cause_val;
    wire ex_exu_trap_mepc_en;
    wire [`MXLEN-1:0] ex_exu_trap_mepc_val;
    wire ex_exu_trap_mstatus_en;
    wire ex_exu_trap_mret_en;
    wire ex_exu_trap_mscratch_en;
    wire [`PC_WIDTH-1:0] ex_exu_trap_targ_pc;

    // ================================
    // EX/MEM pipreg ports
    // ================================
    // pipeline-participating outputs (MEM)
    wire mem_ctrlu_mem_write;
    wire [2:0] mem_ctrlu_load_type;
    wire [2:0] mem_ctrlu_store_type;
    wire [`WB_MUX_WIDTH-1:0] mem_ctrlu_res_src;
    wire mem_ctrlu_reg_write;
    wire [31:0] mem_exu_alu_res;
    wire mem_exu_branch_jump;
    wire [31:0] mem_regf_rs2_data;
    wire [4:0] mem_core_rd;
    wire [31:0] mem_core_pc_plus4;
    wire [31:0] mem_core_imm;
    wire [`MXLEN-1:0] mem_csr_rd_dat;
    wire mem_exu_csr_wr_en;
    wire mem_exu_csr_rd_en;
    wire [11:0] mem_exu_csr_idx;
    wire [`MXLEN-1:0] mem_exu_csr_wb_dat;
    wire mem_exu_trap_cause_en;
    wire [`MXLEN-1:0] mem_exu_trap_cause_val;
    wire mem_exu_trap_mepc_en;
    wire [`MXLEN-1:0] mem_exu_trap_mepc_val;
    wire mem_exu_trap_mstatus_en;
    wire mem_exu_trap_mret_en;
    wire mem_exu_trap_mscratch_en;
    wire [`PC_WIDTH-1:0] mem_exu_trap_targ_pc;

    // ================================
    // data_mem ports
    // ================================
    // pipeline-participating (MEM)
    wire [31:0] mem_dmem_addr;
    wire mem_dmem_w_en;
    wire [31:0] mem_dmem_w_data;
    wire [2:0] mem_dmem_load_type;
    wire [2:0] mem_dmem_store_type;

    // ================================
    // MEM/WB pipreg ports
    // ================================
    // pipeline-participating outputs (WB)
    wire wb_ctrlu_reg_write;
    wire [`WB_MUX_WIDTH-1:0] wb_ctrlu_res_src;
    wire [31:0] wb_mem_rd_data;
    wire [31:0] wb_exu_alu_res;
    wire [4:0] wb_core_rd;
    wire [31:0] wb_core_pc_plus4;
    wire [31:0] wb_core_imm;
    wire [`MXLEN-1:0] wb_csr_rd_dat;

    // ===============================
    // module instances
    // ===============================
    inst_mem inst_mem_inst (
    .pc(if_imem_pc),
    .instr(if_imem_instr)
    );

    pipreg_if2id pipreg_if2id_inst (
    .clk(clk),
    .rst_n(rst_n),
    .d_pc(if_pc),
    .d_instr(if_instr),
    .q_pc(id_pc),
    .q_instr(id_instr),
    .q_rs1(id_rs1),
    .q_rs2(id_rs2),
    .q_rd(id_rd)
    );

    ctrl_unit ctrl_unit_inst (
    .clk(clk),
    .rst_n(rst_n),
    .rv32_instr(id_instr),
    .is_load(id_ctrlu_is_load),
    .is_imm(id_ctrlu_is_imm),
    .is_store(id_ctrlu_is_store),
    .is_rtype(id_ctrlu_is_rtype),
    .is_btype(id_ctrlu_is_btype),
    .is_jtype(id_ctrlu_is_jtype),
    .is_jalr(id_ctrlu_is_jalr),
    .is_lui(id_ctrlu_is_lui),
    .is_auipc(id_ctrlu_is_auipc),
    .is_system(id_ctrlu_is_system),
    .is_trap(id_ctrlu_is_trap),
    .is_ret(id_ctrlu_is_ret),
    .is_csr(id_ctrlu_is_csr),
    .load_type(id_ctrlu_load_type),
    .store_type(id_ctrlu_store_type),
    .branch_type(id_ctrlu_branch_type),
    .csr_dec_bus(id_ctrlu_csr_dec_bus),
    .trap_dec_bus(id_ctrlu_trap_dec_bus),
    .res_src(id_ctrlu_res_src),
    .mem_write(id_ctrlu_mem_write),
    .alu_ctrl(id_ctrlu_alu_ctrl),
    .alu0_src(id_ctrlu_alu0_src),
    .alu1_src(id_ctrlu_alu1_src),
    .imm_src(id_ctrlu_imm_src),
    .reg_write(id_ctrlu_reg_write)
  );

    regfile regfile_inst (
    .clk(clk),
    .rst_n(rst_n),
    .rs1(id_regf_rs1),
    .rs2(id_regf_rs2),
    .rd(wb_regf_rd),
    .rd_data(wb_regf_rd_data_w),
    .rd_write(wb_regf_rd_write),
    .rs1_data(id_regf_rs1_data),
    .rs2_data(id_regf_rs2_data)
    );

    pipreg_id2ex pipreg_id2ex_inst (
    .clk(clk),
    .rst_n(rst_n),
    .d_pc(id_pc),
    .q_pc(ex_pc),

    .d_ctrlu_is_load(id_ctrlu_is_load),
    .d_ctrlu_is_imm(id_ctrlu_is_imm),
    .d_ctrlu_is_store(id_ctrlu_is_store),
    .d_ctrlu_is_rtype(id_ctrlu_is_rtype),
    .d_ctrlu_is_btype(id_ctrlu_is_btype),
    .d_ctrlu_is_jtype(id_ctrlu_is_jtype),
    .d_ctrlu_is_jalr(id_ctrlu_is_jalr),
    .d_ctrlu_is_lui(id_ctrlu_is_lui),
    .d_ctrlu_is_auipc(id_ctrlu_is_auipc),
    .d_ctrlu_is_system(id_ctrlu_is_system),
    .d_ctrlu_is_trap(id_ctrlu_is_trap),
    .d_ctrlu_is_ret(id_ctrlu_is_ret),
    .d_ctrlu_is_csr(id_ctrlu_is_csr),
    .d_ctrlu_load_type(id_ctrlu_load_type),
    .d_ctrlu_store_type(id_ctrlu_store_type),
    .d_ctrlu_branch_type(id_ctrlu_branch_type),
    .d_ctrlu_csr_dec_bus(id_ctrlu_csr_dec_bus),
    .d_ctrlu_trap_dec_bus(id_ctrlu_trap_dec_bus),
    .d_ctrlu_res_src(id_ctrlu_res_src),
    .d_ctrlu_mem_write(id_ctrlu_mem_write),
    .d_ctrlu_alu_ctrl(id_ctrlu_alu_ctrl),
    .d_ctrlu_alu0_src(id_ctrlu_alu0_src),
    .d_ctrlu_alu1_src(id_ctrlu_alu1_src),
    .d_ctrlu_reg_write(id_ctrlu_reg_write),

    .q_ctrlu_is_load(ex_ctrlu_is_load),
    .q_ctrlu_is_imm(ex_ctrlu_is_imm),
    .q_ctrlu_is_store(ex_ctrlu_is_store),
    .q_ctrlu_is_rtype(ex_ctrlu_is_rtype),
    .q_ctrlu_is_btype(ex_ctrlu_is_btype),
    .q_ctrlu_is_jtype(ex_ctrlu_is_jtype),
    .q_ctrlu_is_jalr(ex_ctrlu_is_jalr),
    .q_ctrlu_is_lui(ex_ctrlu_is_lui),
    .q_ctrlu_is_auipc(ex_ctrlu_is_auipc),
    .q_ctrlu_is_system(ex_ctrlu_is_system),
    .q_ctrlu_is_trap(ex_ctrlu_is_trap),
    .q_ctrlu_is_ret(ex_ctrlu_is_ret),
    .q_ctrlu_is_csr(ex_ctrlu_is_csr),
    .q_ctrlu_load_type(ex_ctrlu_load_type),
    .q_ctrlu_store_type(ex_ctrlu_store_type),
    .q_ctrlu_branch_type(ex_ctrlu_branch_type),
    .q_ctrlu_csr_dec_bus(ex_ctrlu_csr_dec_bus),
    .q_ctrlu_trap_dec_bus(ex_ctrlu_trap_dec_bus),
    .q_ctrlu_res_src(ex_ctrlu_res_src),
    .q_ctrlu_mem_write(ex_ctrlu_mem_write),
    .q_ctrlu_alu_ctrl(ex_ctrlu_alu_ctrl),
    .q_ctrlu_alu0_src(ex_ctrlu_alu0_src),
    .q_ctrlu_alu1_src(ex_ctrlu_alu1_src),
    .q_ctrlu_reg_write(ex_ctrlu_reg_write),

    .d_imm(id_imm),
    .q_imm(ex_imm),

    .d_regf_rs1_data(id_regf_rs1_data),
    .d_regf_rs2_data(id_regf_rs2_data),
    .d_regf_rd(id_rd),
    .d_regf_rd_data(id_regf_rd_data_unused),
    .d_regf_rd_write(id_regf_rd_write_unused),
    .q_regf_rs1_data(ex_regf_rs1_data),
    .q_regf_rs2_data(ex_regf_rs2_data),
    .q_regf_rd(ex_regf_rd),
    .q_regf_rd_data(ex_regf_rd_data_unused),
    .q_regf_rd_write(ex_regf_rd_write_unused),

    .d_csr_rd_dat(id_csr_rd_dat_pipe_unused),
    .d_csr_stl_mtvec(id_csr_stl_mtvec),
    .d_csr_stl_mepc(id_csr_stl_mepc),
    .q_csr_rd_dat(ex_csr_rd_dat_pipe_unused),
    .q_csr_stl_mtvec(ex_csr_stl_mtvec),
    .q_csr_stl_mepc(ex_csr_stl_mepc)
    );

    exu exu_inst (
    .clk(clk),
    .rst_n(rst_n),
    .exu_src0(ex_alu_src0),
    .exu_src1(ex_alu_src1),
    .alu_ctrl(ex_ctrlu_alu_ctrl),
    .alu_res(ex_exu_alu_res),
    .branch_type(ex_ctrlu_branch_type),
    .branch_jump(ex_exu_branch_jump),
    .csr_dec_bus(ex_ctrlu_csr_dec_bus),
    .csr_wr_en(ex_exu_csr_wr_en),
    .csr_rd_en(ex_exu_csr_rd_en),
    .csr_rd_dat(ex_csr_rd_dat),
    .csr_idx(ex_exu_csr_idx),
    .csr_wb_dat(ex_exu_csr_wb_dat),
    .trap_pc(ex_pc),
    .is_trap(ex_ctrlu_is_trap),
    .is_ret(ex_ctrlu_is_ret),
    .trap_dec_bus(ex_ctrlu_trap_dec_bus),
    .trap_i_mtvec_val(ex_csr_stl_mtvec),
    .trap_i_mepc_val(ex_csr_stl_mepc),
    .trap_cause_en(ex_exu_trap_cause_en),
    .trap_cause_val(ex_exu_trap_cause_val),
    .trap_mepc_en(ex_exu_trap_mepc_en),
    .trap_mepc_val(ex_exu_trap_mepc_val),
    .trap_mstatus_en(ex_exu_trap_mstatus_en),
    .trap_mret_en(ex_exu_trap_mret_en),
    .trap_mscratch_en(ex_exu_trap_mscratch_en),
    .trap_targ_pc(ex_exu_trap_targ_pc)
    );

    pipreg_ex2mem pipreg_ex2mem_inst (
    .clk(clk),
    .rst_n(rst_n),

    .d_ctrlu_mem_write(ex_ctrlu_mem_write),
    .d_ctrlu_load_type(ex_ctrlu_load_type),
    .d_ctrlu_store_type(ex_ctrlu_store_type),
    .q_ctrlu_mem_write(mem_ctrlu_mem_write),
    .q_ctrlu_load_type(mem_ctrlu_load_type),
    .q_ctrlu_store_type(mem_ctrlu_store_type),

    .d_ctrlu_res_src(ex_ctrlu_res_src),
    .d_ctrlu_reg_write(ex_ctrlu_reg_write),
    .q_ctrlu_res_src(mem_ctrlu_res_src),
    .q_ctrlu_reg_write(mem_ctrlu_reg_write),

    .d_exu_alu_res(ex_exu_alu_res),
    .d_exu_branch_jump(ex_exu_branch_jump),
    .d_regf_rs2_data(ex_regf_rs2_data),
    .q_exu_alu_res(mem_exu_alu_res),
    .q_exu_branch_jump(mem_exu_branch_jump),
    .q_regf_rs2_data(mem_regf_rs2_data),

    .d_core_rd(ex_regf_rd),
    .d_core_pc_plus4(ex_pc_plus4),
    .d_core_imm(ex_imm),
    .d_csr_rd_dat(ex_csr_rd_dat),
    .q_core_rd(mem_core_rd),
    .q_core_pc_plus4(mem_core_pc_plus4),
    .q_core_imm(mem_core_imm),
    .q_csr_rd_dat(mem_csr_rd_dat),

    .d_exu_csr_wr_en(ex_exu_csr_wr_en),
    .d_exu_csr_rd_en(ex_exu_csr_rd_en),
    .d_exu_csr_idx(ex_exu_csr_idx),
    .d_exu_csr_wb_dat(ex_exu_csr_wb_dat),
    .d_exu_trap_cause_en(ex_exu_trap_cause_en),
    .d_exu_trap_cause_val(ex_exu_trap_cause_val),
    .d_exu_trap_mepc_en(ex_exu_trap_mepc_en),
    .d_exu_trap_mepc_val(ex_exu_trap_mepc_val),
    .d_exu_trap_mstatus_en(ex_exu_trap_mstatus_en),
    .d_exu_trap_mret_en(ex_exu_trap_mret_en),
    .d_exu_trap_mscratch_en(ex_exu_trap_mscratch_en),
    .d_exu_trap_targ_pc(ex_exu_trap_targ_pc),
    .q_exu_csr_wr_en(mem_exu_csr_wr_en),
    .q_exu_csr_rd_en(mem_exu_csr_rd_en),
    .q_exu_csr_idx(mem_exu_csr_idx),
    .q_exu_csr_wb_dat(mem_exu_csr_wb_dat),
    .q_exu_trap_cause_en(mem_exu_trap_cause_en),
    .q_exu_trap_cause_val(mem_exu_trap_cause_val),
    .q_exu_trap_mepc_en(mem_exu_trap_mepc_en),
    .q_exu_trap_mepc_val(mem_exu_trap_mepc_val),
    .q_exu_trap_mstatus_en(mem_exu_trap_mstatus_en),
    .q_exu_trap_mret_en(mem_exu_trap_mret_en),
    .q_exu_trap_mscratch_en(mem_exu_trap_mscratch_en),
    .q_exu_trap_targ_pc(mem_exu_trap_targ_pc)
    );

    data_mem data_mem_inst (
    .clk(clk),
    .rst_n(rst_n),
    .addr(mem_dmem_addr),
    .w_en(mem_dmem_w_en),
    .load_type(mem_dmem_load_type),
    .store_type(mem_dmem_store_type),
    .w_data(mem_dmem_w_data),
    .rd_data(mem_dmem_rd_data)
    );

    pipreg_mem2wb pipreg_mem2wb_inst (
    .clk(clk),
    .rst_n(rst_n),

    .d_ctrlu_reg_write(mem_ctrlu_reg_write),
    .d_ctrlu_res_src(mem_ctrlu_res_src),
    .d_mem_rd_data(mem_dmem_rd_data),
    .d_exu_alu_res(mem_exu_alu_res),
    .q_ctrlu_reg_write(wb_ctrlu_reg_write),
    .q_ctrlu_res_src(wb_ctrlu_res_src),
    .q_mem_rd_data(wb_mem_rd_data),
    .q_exu_alu_res(wb_exu_alu_res),

    .d_core_rd(mem_core_rd),
    .d_core_pc_plus4(mem_core_pc_plus4),
    .d_core_imm(mem_core_imm),
    .d_csr_rd_dat(mem_csr_rd_dat),
    .q_core_rd(wb_core_rd),
    .q_core_pc_plus4(wb_core_pc_plus4),
    .q_core_imm(wb_core_imm),
    .q_csr_rd_dat(wb_csr_rd_dat)
    );

    csr csr_inst (
    .clk(clk),
    .rst_n(rst_n),
    .csr_wr_en(mem_csr_wr_en),
    .csr_wb_dat(mem_csr_wb_dat),
    .csr_rd_en(ex_csr_rd_en),
    .csr_rd_dat(ex_csr_o_rd_dat),
    .csr_idx(exmem_csr_i_idx_mux),
    .sgl_cause_en(mem_csr_sgl_cause_en),
    .sgl_cause_val(mem_csr_sgl_cause_val),
    .sgl_mepc_en(mem_csr_sgl_mepc_en),
    .sgl_mepc_val(mem_csr_sgl_mepc_val),
    .sgl_mscratch_en(mem_csr_sgl_mscratch_en),
    .sgl_mstatus_en(mem_csr_sgl_mstatus_en),
    .sgl_mret_en(mem_csr_sgl_mret_en),
    .csr_stl_mtvec(id_csr_o_stl_mtvec_raw),
    .csr_stl_mepc(id_csr_o_stl_mepc_raw)
    );

    // ===============================
    // data_path
    // ===============================
    // IF stage
    assign if_imem_pc = if_pc;
    assign if_instr = if_imem_instr;
    assign if_pc_plus4 = if_pc + 4;

    assign if_pc_src = ((ex_ctrlu_is_btype & ex_exu_branch_jump) | ex_ctrlu_is_jtype) ? `PC_MUX_PLUSIMM :
                       ex_ctrlu_is_jalr ? `PC_MUX_ALU :
                       (ex_ctrlu_is_trap | ex_ctrlu_is_ret) ? `PC_MUX_TRAP :
                       `PC_MUX_NORM;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            if_pc <= 32'b0;
        end else begin
            case (if_pc_src)
                `PC_MUX_NORM: if_pc <= if_pc_plus4;
                `PC_MUX_PLUSIMM: if_pc <= ex_pc + ex_imm;
                `PC_MUX_ALU: if_pc <= ex_exu_alu_res & ~32'b1;
                `PC_MUX_TRAP: if_pc <= ex_exu_trap_targ_pc;
                default: if_pc <= if_pc_plus4;
            endcase
        end
    end

    // ID stage
    assign id_regf_rs1 = id_rs1;
    assign id_regf_rs2 = id_rs2;

    assign id_imm = id_ctrlu_imm_src == `IMM_MUX_I ? {{20{id_instr[31]}}, id_instr[31:20]} :
                    id_ctrlu_imm_src == `IMM_MUX_S ? {{20{id_instr[31]}}, id_instr[31:25], id_instr[11:7]} :
                    id_ctrlu_imm_src == `IMM_MUX_B ? {{20{id_instr[31]}}, id_instr[7], id_instr[30:25], id_instr[11:8], 1'b0} :
                    id_ctrlu_imm_src == `IMM_MUX_J ? {{12{id_instr[31]}}, id_instr[19:12], id_instr[20], id_instr[30:21], 1'b0} :
                    id_ctrlu_imm_src == `IMM_MUX_U ? {id_instr[31:12], 12'b0} :
                    {id_instr[31:12], 12'b0};

    assign id_csr_stl_mtvec = id_csr_o_stl_mtvec_raw;
    assign id_csr_stl_mepc = id_csr_o_stl_mepc_raw;

    // EX stage
    assign ex_alu_src0 = ex_ctrlu_alu0_src == `ALU_MUX_SRC0_RS1 ? ex_regf_rs1_data : ex_pc;
    assign ex_alu_src1 = ex_ctrlu_alu1_src == `ALU_MUX_SRC1_RS2 ? ex_regf_rs2_data : ex_imm;
    assign ex_pc_plus4 = ex_pc + 4;

    assign ex_csr_rd_en = ex_exu_csr_rd_en;
    assign ex_csr_rd_idx = ex_exu_csr_idx;
    assign ex_csr_rd_dat = ex_csr_o_rd_dat;

    // MEM stage
    assign mem_dmem_addr = mem_exu_alu_res;
    assign mem_dmem_w_en = mem_ctrlu_mem_write;
    assign mem_dmem_w_data = mem_regf_rs2_data;
    assign mem_dmem_load_type = mem_ctrlu_load_type;
    assign mem_dmem_store_type = mem_ctrlu_store_type;

    assign mem_csr_wr_en = mem_exu_csr_wr_en;
    assign mem_csr_wr_idx = mem_exu_csr_idx;
    assign mem_csr_wb_dat = mem_exu_csr_wb_dat;

    assign mem_csr_sgl_cause_en = mem_exu_trap_cause_en;
    assign mem_csr_sgl_cause_val = mem_exu_trap_cause_val;
    assign mem_csr_sgl_mepc_en = mem_exu_trap_mepc_en;
    assign mem_csr_sgl_mepc_val = mem_exu_trap_mepc_val;
    assign mem_csr_sgl_mscratch_en = mem_exu_trap_mscratch_en;
    assign mem_csr_sgl_mstatus_en = mem_exu_trap_mstatus_en;
    assign mem_csr_sgl_mret_en = mem_exu_trap_mret_en;

    // WB stage
    assign wb_regf_rd = wb_core_rd;
    assign wb_regf_rd_write = wb_ctrlu_reg_write;
    assign wb_regf_rd_data_w = wb_regf_rd_data;

    always @(*) begin
        case (wb_ctrlu_res_src)
            `WB_MUX_MEM: wb_regf_rd_data = wb_mem_rd_data;
            `WB_MUX_ALU: wb_regf_rd_data = wb_exu_alu_res;
            `WB_MUX_PCPLUS4: wb_regf_rd_data = wb_core_pc_plus4;
            `WB_MUX_IMM: wb_regf_rd_data = wb_core_imm;
            `WB_MUX_CSR: wb_regf_rd_data = wb_csr_rd_dat;
            default: wb_regf_rd_data = wb_mem_rd_data;
        endcase
    end

    // CSR idx mux (EX read + MEM write share one index port)
    assign exmem_csr_i_idx_mux = ex_csr_rd_en ? ex_csr_rd_idx : mem_csr_wr_idx;

    // tie-off unused id2ex bundle ports
    assign id_regf_rd_data_unused = 32'b0;
    assign id_regf_rd_write_unused = 1'b0;
    assign id_csr_rd_dat_pipe_unused = `MXLEN'b0;

endmodule
