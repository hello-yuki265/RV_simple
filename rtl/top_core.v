/*************************************************************************
 * @Copyright (c) 2026 by hello-yuki265, All Rights Reserved.
 * @Author       : hello-yuki265
 * @Github       : 2658476808@qq.com
 * @Date         : 2026-04-17 15:05:46
 * @LastEditors  : hello-yuki265 2658476808@qq.com
 * @LastEditTime : 2026-04-22 17:56:50
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
    // signal plan
    // ================================
    // -------------------------
    // core datapath signals
    // -------------------------
    wire [1:0] core_pc_src;
    reg [31:0] core_pc;
    wire [31:0] core_pc_plus4;
    wire [31:0] core_instr;
    wire [4:0] core_rs1;
    wire [4:0] core_rs2;
    wire [4:0] core_rd;
    wire [31:0] core_imm;
    wire [31:0] core_alu_src0;
    wire [31:0] core_alu_src1;
    reg [31:0] core_wb_rd_data;

    // -------------------------
    // inst_mem signals
    // -------------------------
    wire [31:0] imem_pc;
    wire [31:0] imem_instr;

    // -------------------------
    // ctrl_unit signals
    // -------------------------
    wire [31:0] ctrlu_rv32_instr;
    wire ctrlu_is_load;
    wire ctrlu_is_imm;
    wire ctrlu_is_store;
    wire ctrlu_is_rtype;
    wire ctrlu_is_btype;
    wire ctrlu_is_jtype;
    wire ctrlu_is_jalr;
    wire ctrlu_is_lui;
    wire ctrlu_is_auipc;
    wire ctrlu_is_system;
    wire ctrlu_is_trap;
    wire ctrlu_is_ret;
    wire ctrlu_is_csr;
    wire [2:0] ctrlu_load_type;
    wire [2:0] ctrlu_store_type;
    wire [2:0] ctrlu_branch_type;
    wire [`CSR_DEC_INFO_WIDTH-1:0] ctrlu_csr_dec_bus;
    wire [`TRAP_DEC_INFO_WIDTH-1:0] ctrlu_trap_dec_bus;
    wire [`WB_MUX_WIDTH-1:0] ctrlu_res_src;
    wire ctrlu_mem_write;
    wire [9:0] ctrlu_alu_ctrl;
    wire ctrlu_alu0_src;
    wire ctrlu_alu1_src;
    wire [2:0] ctrlu_imm_src;
    wire ctrlu_reg_write;

    // -------------------------
    // regfile signals
    // -------------------------
    wire [4:0] regf_rs1;
    wire [4:0] regf_rs2;
    wire [4:0] regf_rd;
    wire [31:0] regf_rd_data;
    wire regf_rd_write;
    wire [31:0] regf_rs1_data;
    wire [31:0] regf_rs2_data;

    // -------------------------
    // exu signals
    // -------------------------
    wire [31:0] exu_src0;
    wire [31:0] exu_src1;
    wire [9:0] exu_alu_ctrl;
    wire [31:0] exu_alu_res;
    wire [2:0] exu_branch_type;
    wire exu_branch_jump;
    wire [`CSR_DEC_INFO_WIDTH-1:0] exu_csr_dec_bus;
    wire exu_csr_wr_en;
    wire exu_csr_rd_en;
    wire [11:0] exu_csr_idx;
    wire [`MXLEN-1:0] exu_csr_rd_dat;
    wire [`MXLEN-1:0] exu_csr_wb_dat;
    wire [`PC_WIDTH-1:0] exu_trap_pc;
    wire exu_is_trap;
    wire exu_is_ret;
    wire [`TRAP_DEC_INFO_WIDTH-1:0] exu_trap_dec_bus;
    wire [`MXLEN-1:0] exu_trap_i_mtvec_val;
    wire [`MXLEN-1:0] exu_trap_i_mepc_val;
    wire exu_trap_cause_en;
    wire [`MXLEN-1:0] exu_trap_cause_val;
    wire exu_trap_mepc_en;
    wire [`MXLEN-1:0] exu_trap_mepc_val;
    wire exu_trap_mstatus_en;
    wire exu_trap_mret_en;
    wire exu_trap_mscratch_en;
    wire [`PC_WIDTH-1:0] exu_trap_targ_pc;

    // -------------------------
    // csr signals
    // -------------------------
    wire csr_wr_en;
    wire [`MXLEN-1:0] csr_wb_dat;
    wire csr_rd_en;
    wire [`MXLEN-1:0] csr_rd_dat;
    wire [11:0] csr_idx;
    wire csr_sgl_cause_en;
    wire [`MXLEN-1:0] csr_sgl_cause_val;
    wire csr_sgl_mepc_en;
    wire [`MXLEN-1:0] csr_sgl_mepc_val;
    wire csr_sgl_mscratch_en;
    wire csr_sgl_mstatus_en;
    wire csr_sgl_mret_en;
    wire [`MXLEN-1:0] csr_stl_mtvec;
    wire [`MXLEN-1:0] csr_stl_mepc;

    // -------------------------
    // data_mem signals
    // -------------------------
    wire [31:0] dmem_addr;
    wire dmem_w_en;
    wire [31:0] dmem_w_data;
    wire [2:0] dmem_load_type;
    wire [2:0] dmem_store_type;
    wire [31:0] dmem_rd_data;

    // ===============================
    // main logic
    // ===============================
    // --------------------------
    // ctrl unit
    // --------------------------
    ctrl_unit ctrl_unit_inst (
    .clk(clk),
    .rst_n(rst_n),
    .rv32_instr(ctrlu_rv32_instr),
    .is_load(ctrlu_is_load),
    .is_imm(ctrlu_is_imm),
    .is_store(ctrlu_is_store),
    .is_rtype(ctrlu_is_rtype),
    .is_btype(ctrlu_is_btype),
    .is_jtype(ctrlu_is_jtype),
    .is_jalr(ctrlu_is_jalr),
    .is_lui(ctrlu_is_lui),
    .is_auipc(ctrlu_is_auipc),
    .is_system(ctrlu_is_system),
    .is_trap(ctrlu_is_trap),
    .is_ret(ctrlu_is_ret),
    .is_csr(ctrlu_is_csr),
    .load_type(ctrlu_load_type),
    .store_type(ctrlu_store_type),
    .branch_type(ctrlu_branch_type),
    .csr_dec_bus(ctrlu_csr_dec_bus),
    .trap_dec_bus(ctrlu_trap_dec_bus),
    .res_src(ctrlu_res_src),
    .mem_write(ctrlu_mem_write),
    .alu_ctrl(ctrlu_alu_ctrl),
    .alu0_src(ctrlu_alu0_src),
    .alu1_src(ctrlu_alu1_src),
    .imm_src(ctrlu_imm_src),
    .reg_write(ctrlu_reg_write)
  );

    // -----------------------------
    // IF fetch
    // -----------------------------
    inst_mem inst_mem_inst (
    .pc(imem_pc),
    .instr(imem_instr)
    );

    // -----------------------------
    // ID decode / WB write
    // -----------------------------
    regfile regfile_inst (
    .clk(clk),
    .rst_n(rst_n),
    .rs1(regf_rs1),
    .rs2(regf_rs2),
    .rd(regf_rd),
    .rd_data(regf_rd_data),
    .rd_write(regf_rd_write),
    .rs1_data(regf_rs1_data),
    .rs2_data(regf_rs2_data)
    );

    csr csr_inst (
    .clk(clk),
    .rst_n(rst_n),
    .csr_wr_en(csr_wr_en),
    .csr_wb_dat(csr_wb_dat),
    .csr_rd_en(csr_rd_en),
    .csr_rd_dat(csr_rd_dat),
    .csr_idx(csr_idx),
    .sgl_cause_en(csr_sgl_cause_en),
    .sgl_cause_val(csr_sgl_cause_val),
    .sgl_mepc_en(csr_sgl_mepc_en),
    .sgl_mepc_val(csr_sgl_mepc_val),
    .sgl_mscratch_en(csr_sgl_mscratch_en),
    .sgl_mstatus_en(csr_sgl_mstatus_en),
    .sgl_mret_en(csr_sgl_mret_en),
    .csr_stl_mtvec(csr_stl_mtvec),
    .csr_stl_mepc(csr_stl_mepc)
    );

    // -----------------------------
    // EX execute
    // -----------------------------
    exu exu_inst (
    .clk(clk),
    .rst_n(rst_n),
    .exu_src0(exu_src0),
    .exu_src1(exu_src1),
    .alu_ctrl(exu_alu_ctrl),
    .alu_res(exu_alu_res),
    .branch_type(exu_branch_type),
    .branch_jump(exu_branch_jump),
    .csr_dec_bus(exu_csr_dec_bus),
    .csr_wr_en(exu_csr_wr_en),
    .csr_rd_en(exu_csr_rd_en),
    .csr_rd_dat(exu_csr_rd_dat),
    .csr_idx(exu_csr_idx),
    .csr_wb_dat(exu_csr_wb_dat),
    .trap_pc(exu_trap_pc),
    .is_trap(exu_is_trap),
    .is_ret(exu_is_ret),
    .trap_dec_bus(exu_trap_dec_bus),
    .trap_i_mtvec_val(exu_trap_i_mtvec_val),
    .trap_i_mepc_val(exu_trap_i_mepc_val),
    .trap_cause_en(exu_trap_cause_en),
    .trap_cause_val(exu_trap_cause_val),
    .trap_mepc_en(exu_trap_mepc_en),
    .trap_mepc_val(exu_trap_mepc_val),
    .trap_mstatus_en(exu_trap_mstatus_en),
    .trap_mret_en(exu_trap_mret_en),
    .trap_mscratch_en(exu_trap_mscratch_en),
    .trap_targ_pc(exu_trap_targ_pc)
    );

    // -----------------------------
    // MEM access
    // -----------------------------
    data_mem data_mem_inst (
    .clk(clk),
    .rst_n(rst_n),
    .addr(dmem_addr),
    .w_en(dmem_w_en),
    .load_type(dmem_load_type),
    .store_type(dmem_store_type),
    .w_data(dmem_w_data),
    .rd_data(dmem_rd_data)
    );

    // ===============================
    // data_path
    // ===============================
    // ------------------------
    // module wiring
    // ------------------------
    assign core_instr = imem_instr;
    assign imem_pc = core_pc;

    // pipreg_if2id  pipreg_if2id_inst (
    // .clk(clk),
    // .rst_n(rst_n),
    // .instr_d(core_instr),
    // .instr_q(ctrlu_rv32_instr),
    // .q_rs1(regf_rs1),
    // .q_rs2(regf_rs2),
    // .q_rd(regf_rd)
    // );

    assign core_rs1 = core_instr[19:15];
    assign core_rs2 = core_instr[24:20];
    assign core_rd = core_instr[11:7];

    assign ctrlu_rv32_instr = core_instr;

    assign regf_rs1 = core_rs1;
    assign regf_rs2 = core_rs2;
    assign regf_rd = core_rd;
    assign regf_rd_data = core_wb_rd_data;
    assign regf_rd_write = ctrlu_reg_write;

    assign exu_src0 = core_alu_src0;
    assign exu_src1 = core_alu_src1;
    assign exu_alu_ctrl = ctrlu_alu_ctrl;
    assign exu_branch_type = ctrlu_branch_type;
    assign exu_csr_dec_bus = ctrlu_csr_dec_bus;
    assign exu_csr_rd_dat = csr_rd_dat;
    assign exu_trap_pc = core_pc;
    assign exu_is_trap = ctrlu_is_trap;
    assign exu_is_ret = ctrlu_is_ret;
    assign exu_trap_dec_bus = ctrlu_trap_dec_bus;
    assign exu_trap_i_mtvec_val = csr_stl_mtvec;
    assign exu_trap_i_mepc_val = csr_stl_mepc;

    assign csr_wr_en = exu_csr_wr_en;
    assign csr_wb_dat = exu_csr_wb_dat;
    assign csr_rd_en = exu_csr_rd_en;
    assign csr_idx = exu_csr_idx;
    assign csr_sgl_cause_en = exu_trap_cause_en;
    assign csr_sgl_cause_val = exu_trap_cause_val;
    assign csr_sgl_mepc_en = exu_trap_mepc_en;
    assign csr_sgl_mepc_val = exu_trap_mepc_val;
    assign csr_sgl_mscratch_en = exu_trap_mscratch_en;
    assign csr_sgl_mstatus_en = exu_trap_mstatus_en;
    assign csr_sgl_mret_en = exu_trap_mret_en;

    assign dmem_addr = exu_alu_res;
    assign dmem_w_en = ctrlu_mem_write;
    assign dmem_w_data = regf_rs2_data;
    assign dmem_load_type = ctrlu_load_type;
    assign dmem_store_type = ctrlu_store_type;

    // ------------------------
    // PC refresh
    // ------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            core_pc <= 0;
        end else begin
            case (core_pc_src)
                `PC_MUX_NORM: core_pc <= core_pc_plus4;
                `PC_MUX_PLUSIMM: core_pc <= core_pc + core_imm;
                `PC_MUX_ALU: core_pc <= exu_alu_res & ~1;
                `PC_MUX_TRAP: core_pc <= exu_trap_targ_pc;
                default: core_pc <= core_pc_plus4;
             endcase
        end
    end

    assign core_pc_plus4 = core_pc + 4;
    assign core_pc_src = (ctrlu_is_btype & exu_branch_jump) | ctrlu_is_jtype ? `PC_MUX_PLUSIMM :
                         ctrlu_is_jalr ? `PC_MUX_ALU :
                         (ctrlu_is_trap | ctrlu_is_ret) ? `PC_MUX_TRAP :
                         `PC_MUX_NORM;

    // ------------------------
    // write back mux
    // ------------------------
    always @(*) begin
        case (ctrlu_res_src)
            `WB_MUX_MEM: core_wb_rd_data = dmem_rd_data;
            `WB_MUX_ALU: core_wb_rd_data = exu_alu_res;
            `WB_MUX_PCPLUS4: core_wb_rd_data = core_pc_plus4;
            `WB_MUX_IMM: core_wb_rd_data = core_imm;
            `WB_MUX_CSR: core_wb_rd_data = csr_rd_dat;
            default: core_wb_rd_data = dmem_rd_data;
        endcase
    end

    // ------------------------
    // immediate extension
    // ------------------------
    assign core_imm = ctrlu_imm_src == `IMM_MUX_I ? {{20{core_instr[31]}}, core_instr[31:20]} :
                      ctrlu_imm_src == `IMM_MUX_S ? {{20{core_instr[31]}}, core_instr[31:25], core_instr[11:7]} :
                      ctrlu_imm_src == `IMM_MUX_B ? {{20{core_instr[31]}}, core_instr[7], core_instr[30:25], core_instr[11:8], 1'b0} :
                      ctrlu_imm_src == `IMM_MUX_J ? {{12{core_instr[31]}}, core_instr[19:12], core_instr[20], core_instr[30:21], 1'b0} :
                      ctrlu_imm_src == `IMM_MUX_U ? {core_instr[31:12], 12'b0} :
                      {core_instr[31:12], 12'b0};

    // ------------------------
    // ALU src mux
    // ------------------------
    assign core_alu_src0 = ctrlu_alu0_src == `ALU_MUX_SRC0_RS1 ? regf_rs1_data : core_pc;
    assign core_alu_src1 = ctrlu_alu1_src == `ALU_MUX_SRC1_RS2 ? regf_rs2_data : core_imm;

    // ------------------------
    // pipline register
    // ------------------------

    

    // pipreg_id2ex  pipreg_id2ex_inst (
    // .clk(clk),
    // .rst_n(rst_n),
    // .d_ctrlu_is_load(d_ctrlu_is_load),
    // .d_ctrlu_is_imm(d_ctrlu_is_imm),
    // .d_ctrlu_is_store(d_ctrlu_is_store),
    // .d_ctrlu_is_rtype(d_ctrlu_is_rtype),
    // .d_ctrlu_is_btype(d_ctrlu_is_btype),
    // .d_ctrlu_is_jtype(d_ctrlu_is_jtype),
    // .d_ctrlu_is_jalr(d_ctrlu_is_jalr),
    // .d_ctrlu_is_lui(d_ctrlu_is_lui),
    // .d_ctrlu_is_auipc(d_ctrlu_is_auipc),
    // .d_ctrlu_is_system(d_ctrlu_is_system),
    // .d_ctrlu_is_trap(d_ctrlu_is_trap),
    // .d_ctrlu_is_ret(d_ctrlu_is_ret),
    // .d_ctrlu_is_csr(d_ctrlu_is_csr),
    // .d_ctrlu_load_type(d_ctrlu_load_type),
    // .d_ctrlu_store_type(d_ctrlu_store_type),
    // .d_ctrlu_branch_type(d_ctrlu_branch_type),
    // .d_ctrlu_csr_dec_bus(d_ctrlu_csr_dec_bus),
    // .d_ctrlu_trap_dec_bus(d_ctrlu_trap_dec_bus),
    // .d_ctrlu_res_src(d_ctrlu_res_src),
    // .d_ctrlu_mem_write(d_ctrlu_mem_write),
    // .d_ctrlu_alu_ctrl(d_ctrlu_alu_ctrl),
    // .d_ctrlu_alu0_src(d_ctrlu_alu0_src),
    // .d_ctrlu_alu1_src(d_ctrlu_alu1_src),
    // .d_ctrlu_imm_src(d_ctrlu_imm_src),
    // .d_ctrlu_reg_write(d_ctrlu_reg_write),
    // .q_ctrlu_is_load(q_ctrlu_is_load),
    // .q_ctrlu_is_imm(q_ctrlu_is_imm),
    // .q_ctrlu_is_store(q_ctrlu_is_store),
    // .q_ctrlu_is_rtype(q_ctrlu_is_rtype),
    // .q_ctrlu_is_btype(q_ctrlu_is_btype),
    // .q_ctrlu_is_jtype(q_ctrlu_is_jtype),
    // .q_ctrlu_is_jalr(q_ctrlu_is_jalr),
    // .q_ctrlu_is_lui(q_ctrlu_is_lui),
    // .q_ctrlu_is_auipc(q_ctrlu_is_auipc),
    // .q_ctrlu_is_system(q_ctrlu_is_system),
    // .q_ctrlu_is_trap(q_ctrlu_is_trap),
    // .q_ctrlu_is_ret(q_ctrlu_is_ret),
    // .q_ctrlu_is_csr(q_ctrlu_is_csr),
    // .q_ctrlu_load_type(q_ctrlu_load_type),
    // .q_ctrlu_store_type(q_ctrlu_store_type),
    // .q_ctrlu_branch_type(q_ctrlu_branch_type),
    // .q_ctrlu_csr_dec_bus(q_ctrlu_csr_dec_bus),
    // .q_ctrlu_trap_dec_bus(q_ctrlu_trap_dec_bus),
    // .q_ctrlu_res_src(q_ctrlu_res_src),
    // .q_ctrlu_mem_write(q_ctrlu_mem_write),
    // .q_ctrlu_alu_ctrl(q_ctrlu_alu_ctrl),
    // .q_ctrlu_alu0_src(q_ctrlu_alu0_src),
    // .q_ctrlu_alu1_src(q_ctrlu_alu1_src),
    // .q_ctrlu_imm_src(q_ctrlu_imm_src),
    // .q_ctrlu_reg_write(q_ctrlu_reg_write),
    // .d_regf_rs1_data(d_regf_rs1_data),
    // .d_regf_rs2_data(d_regf_rs2_data),
    // .q_regf_rs1_data(q_regf_rs1_data),
    // .q_regf_rs2_data(q_regf_rs2_data),
    // .d_csr_rd_dat(d_csr_rd_dat),
    // .d_csr_stl_mtvec(d_csr_stl_mtvec),
    // .d_csr_stl_mepc(d_csr_stl_mepc),
    // .q_csr_rd_dat(q_csr_rd_dat),
    // .q_csr_stl_mtvec(q_csr_stl_mtvec),
    // .q_csr_stl_mepc(q_csr_stl_mepc)
    // );

    // pipreg_ex2mem  pipreg_ex2mem_inst (
    // .clk(clk),
    // .rst_n(rst_n),
    // .d_ctrlu_mem_write(d_ctrlu_mem_write),
    // .d_ctrlu_load_type(d_ctrlu_load_type),
    // .d_ctrlu_store_type(d_ctrlu_store_type),
    // .q_ctrlu_mem_write(q_ctrlu_mem_write),
    // .q_ctrlu_load_type(q_ctrlu_load_type),
    // .q_ctrlu_store_type(q_ctrlu_store_type),
    // .d_ctrlu_res_src(d_ctrlu_res_src),
    // .d_ctrlu_reg_write(d_ctrlu_reg_write),
    // .q_ctrlu_res_src(q_ctrlu_res_src),
    // .q_ctrlu_reg_write(q_ctrlu_reg_write),
    // .d_exu_alu_res(d_exu_alu_res),
    // .d_exu_branch_jump(d_exu_branch_jump),
    // .d_regf_rs2_data(d_regf_rs2_data),
    // .q_exu_alu_res(q_exu_alu_res),
    // .q_exu_branch_jump(q_exu_branch_jump),
    // .q_regf_rs2_data(q_regf_rs2_data),
    // .d_core_rd(d_core_rd),
    // .d_core_pc_plus4(d_core_pc_plus4),
    // .d_core_imm(d_core_imm),
    // .d_csr_rd_dat(d_csr_rd_dat),
    // .q_core_rd(q_core_rd),
    // .q_core_pc_plus4(q_core_pc_plus4),
    // .q_core_imm(q_core_imm),
    // .q_csr_rd_dat(q_csr_rd_dat),
    // .d_exu_csr_wr_en(d_exu_csr_wr_en),
    // .d_exu_csr_rd_en(d_exu_csr_rd_en),
    // .d_exu_csr_idx(d_exu_csr_idx),
    // .d_exu_csr_wb_dat(d_exu_csr_wb_dat),
    // .d_exu_trap_cause_en(d_exu_trap_cause_en),
    // .d_exu_trap_cause_val(d_exu_trap_cause_val),
    // .d_exu_trap_mepc_en(d_exu_trap_mepc_en),
    // .d_exu_trap_mepc_val(d_exu_trap_mepc_val),
    // .d_exu_trap_mstatus_en(d_exu_trap_mstatus_en),
    // .d_exu_trap_mret_en(d_exu_trap_mret_en),
    // .d_exu_trap_mscratch_en(d_exu_trap_mscratch_en),
    // .d_exu_trap_targ_pc(d_exu_trap_targ_pc),
    // .q_exu_csr_wr_en(q_exu_csr_wr_en),
    // .q_exu_csr_rd_en(q_exu_csr_rd_en),
    // .q_exu_csr_idx(q_exu_csr_idx),
    // .q_exu_csr_wb_dat(q_exu_csr_wb_dat),
    // .q_exu_trap_cause_en(q_exu_trap_cause_en),
    // .q_exu_trap_cause_val(q_exu_trap_cause_val),
    // .q_exu_trap_mepc_en(q_exu_trap_mepc_en),
    // .q_exu_trap_mepc_val(q_exu_trap_mepc_val),
    // .q_exu_trap_mstatus_en(q_exu_trap_mstatus_en),
    // .q_exu_trap_mret_en(q_exu_trap_mret_en),
    // .q_exu_trap_mscratch_en(q_exu_trap_mscratch_en),
    // .q_exu_trap_targ_pc(q_exu_trap_targ_pc)
    // );

    // pipreg_mem2wb  pipreg_mem2wb_inst (
    // .clk(clk),
    // .rst_n(rst_n),
    // .d_core_rd(d_core_rd),
    // .d_core_pc_plus4(d_core_pc_plus4),
    // .d_core_imm(d_core_imm),
    // .d_csr_rd_dat(d_csr_rd_dat),
    // .q_core_rd(q_core_rd),
    // .q_core_pc_plus4(q_core_pc_plus4),
    // .q_core_imm(q_core_imm),
    // .q_csr_rd_dat(q_csr_rd_dat)
    // );
endmodule
