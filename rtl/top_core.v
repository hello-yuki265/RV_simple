/*************************************************************************
 * @Copyright (c) 2026 by hello-yuki265, All Rights Reserved. 
 * @Author       : hello-yuki265
 * @Github       : 2658476808@qq.com
 * @Date         : 2026-04-17 15:05:46
 * @LastEditors  : hello-yuki265 2658476808@qq.com
 * @LastEditTime : 2026-04-22 13:12:24
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
    // 变量定义
    // ================================
    // ------------------
    // PC指针
    // ------------------
    wire [1:0]pc_src;
    reg [31:0] pc;
    wire [31:0] pc_plus4;

    // --------------------------
    // 指令定义
    // --------------------------   
    wire [31:0] instr; //32位指令
    wire [6:0] funct7   = instr[31:25];
    wire [4:0] rs2      = instr[24:20];
    wire [4:0] rs1      = instr[19:15];
    wire [2:0] funct3   = instr[14:12];
    wire [4:0] rd       = instr[11:7];
    wire [6:0] op_code  = instr[6:0];

    wire [31:0] imm;
    

    // -----------------------
    // regfile接口
    // -----------------------
    reg [31:0] rd_data;
    wire rd_write;
    wire [31:0] rs1_data;
    wire [31:0] rs2_data;

    // -----------------------
    // csr接口
    // -----------------------
    wire [`MXLEN-1:0] csr_rd_dat;
    wire [`MXLEN-1:0] csr_stl_mtvec_val;
    wire [`MXLEN-1:0] csr_stl_mepc_val;



    // -----------------------
    // ctrl_unit接口
    // -----------------------
    wire is_load;
    wire is_imm;
    wire is_store;
    wire is_rtype;
    wire is_btype;
    wire is_jtype;
    wire is_jalr;
    wire is_lui;
    wire is_auipc;
    wire is_system;
    wire is_trap;
    wire is_ret;
    wire is_csr;
    wire [2:0] load_type;
    wire [2:0] store_type;
    wire [2:0] branch_type;
    wire [`CSR_DEC_INFO_WIDTH-1:0] csr_dec_bus;
    wire [`TRAP_DEC_INFO_WIDTH-1:0] trap_dec_bus;

    wire [`WB_MUX_WIDTH-1:0] res_src;
    wire mem_write;
    wire [9:0] alu_ctrl;
    wire alu0_src;
    wire alu1_src;
    wire [2:0]imm_src;
    wire reg_write;

    // ------------------------
    // EXU接口
    // ------------------------
    wire [31:0] alu_src0;
    wire [31:0] alu_src1;

    wire [31:0] exu_src0;
    wire [31:0] exu_src1;

    wire [31:0] alu_res;

    wire branch_jump;

    wire csr_wr_en;
    wire csr_rd_en;
    wire [11:0] csr_idx;
    wire [`MXLEN-1:0] csr_wb_dat;

    wire  trap_cause_en;
    wire  [`MXLEN-1:0] trap_cause_val;
    wire  trap_mepc_en;
    wire  [`MXLEN-1:0] trap_mepc_val;
    wire  trap_mstatus_en;
    wire  trap_mret_en;
    wire  trap_mscratch_en;
    wire  [`PC_WIDTH-1:0] trap_targ_pc;


    // -----------------------
    // data_mem接口
    // -----------------------
    wire [31:0] addr;
    wire w_en;
    wire [31:0] mem_w_data;
    wire [31:0] mem_r_data;


    // ===============================
    // 主逻辑
    // ===============================
    // --------------------------
    // 控制单元
    // --------------------------
    ctrl_unit  ctrl_unit_inst (
    .clk(clk),
    .rst_n(rst_n),
    .rv32_instr(instr),
    .is_load(is_load),
    .is_imm(is_imm),
    .is_store(is_store),
    .is_rtype(is_rtype),
    .is_btype(is_btype),
    .is_jtype(is_jtype),
    .is_jalr(is_jalr),
    .is_lui(is_lui),
    .is_auipc(is_auipc),
    .is_system(is_system),
    .is_trap(is_trap),
    .is_ret(is_ret),
    .is_csr(is_csr),
    .load_type(load_type),
    .store_type(store_type),
    .branch_type(branch_type),
    .csr_dec_bus(csr_dec_bus),
    .trap_dec_bus(trap_dec_bus),
    .res_src(res_src),
    .mem_write(mem_write),
    .alu_ctrl(alu_ctrl),
    .alu0_src(alu0_src),
    .alu1_src(alu1_src),
    .imm_src(imm_src),
    .reg_write(reg_write)
  );

    // -----------------------------
    // IF取指
    // -----------------------------
    inst_mem  inst_mem_inst (
    .pc(pc),
    .instr(instr)
    );

    // -----------------------------
    // 译码、写回
    // -----------------------------
    regfile  regfile_inst (
    .clk(clk),
    .rst_n(rst_n),
    .rs1(rs1),
    .rs2(rs2),
    .rd(rd),
    .rd_data(rd_data),
    .rd_write(reg_write),
    .rs1_data(rs1_data),
    .rs2_data(rs2_data)
    );

    csr  csr_inst (
    .clk(clk),
    .rst_n(rst_n),
    .csr_wr_en(csr_wr_en),
    .csr_wb_dat(csr_wb_dat),
    .csr_rd_en(csr_rd_en),
    .csr_rd_dat(csr_rd_dat),
    .csr_idx(csr_idx),
    .sgl_cause_en(trap_cause_en),
    .sgl_cause_val(trap_cause_val),
    .sgl_mepc_en(trap_mepc_en),
    .sgl_mepc_val(trap_mepc_val),
    .sgl_mscratch_en(trap_mscratch_en),
    .sgl_mstatus_en(trap_mstatus_en),
    .sgl_mret_en(trap_mret_en),
    .csr_stl_mtvec(csr_stl_mtvec_val),
    .csr_stl_mepc(csr_stl_mepc_val)
    );

    // -----------------------------
    // EX执行
    // -----------------------------
    exu  exu_inst (
    .clk(clk),
    .rst_n(rst_n),
    .exu_src0(exu_src0),
    .exu_src1(exu_src1),
    .alu_ctrl(alu_ctrl),
    .alu_res(alu_res),
    .branch_type(branch_type),
    .branch_jump(branch_jump),
    .csr_dec_bus(csr_dec_bus),
    .csr_wr_en(csr_wr_en),
    .csr_rd_en(csr_rd_en),
    .csr_rd_dat(csr_rd_dat),
    .csr_idx(csr_idx),
    .csr_wb_dat(csr_wb_dat),
    .trap_pc(pc),
    .is_trap(is_trap),
    .is_ret(is_ret),
    .trap_dec_bus(trap_dec_bus),
    .trap_i_mtvec_val(csr_stl_mtvec_val),
    .trap_i_mepc_val(csr_stl_mepc_val),
    .trap_cause_en(trap_cause_en),
    .trap_cause_val(trap_cause_val),
    .trap_mepc_en(trap_mepc_en),
    .trap_mepc_val(trap_mepc_val),
    .trap_mstatus_en(trap_mstatus_en),
    .trap_mret_en(trap_mret_en),
    .trap_mscratch_en(trap_mscratch_en),
    .trap_targ_pc(trap_targ_pc)
    );

    // -----------------------------
    // 访存
    // -----------------------------
    assign mem_w_data = rs2_data;
    assign w_en = mem_write;
    data_mem  data_mem_inst (
    .clk(clk),
    .rst_n(rst_n),
    .addr(alu_res),
    .w_en(w_en),
    .load_type(load_type),
    .store_type(store_type),
    .w_data(mem_w_data),
    .rd_data(mem_r_data)
    );

    // ===============================
    // data_path
    // ===============================
    // ------------------------
    // PC refresh
    // ------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc <= 0;
        end else begin
            case (pc_src)
                `PC_MUX_NORM: pc <= pc_plus4;
                `PC_MUX_PLUSIMM: pc <= pc + imm;
                `PC_MUX_ALU: pc <= alu_res & ~1; // jalr指令需要将最低位置0
                `PC_MUX_TRAP: pc <= trap_targ_pc;
                default: pc <= pc_plus4;
             endcase
            
        end
    end
    assign pc_plus4 = pc + 4;
    assign pc_src = (is_btype & branch_jump) | is_jtype ? `PC_MUX_PLUSIMM : 
                    is_jalr ? `PC_MUX_ALU : 
                    (is_trap | is_ret) ? `PC_MUX_TRAP : 
                    `PC_MUX_NORM;

    // ------------------------
    // Write Back
    // 之后可能需要考虑访存的速度问题，可能需要拓展等待
    // ------------------------               
    always @(*) begin
        case (res_src)
            `WB_MUX_MEM: rd_data = mem_r_data;
            `WB_MUX_ALU: rd_data = alu_res;
            `WB_MUX_PCPLUS4: rd_data = pc_plus4;
            `WB_MUX_IMM: rd_data = imm;
            `WB_MUX_CSR: rd_data = csr_rd_dat;
            default: rd_data = mem_r_data;
        endcase
    end

    // ------------------------
    // Extend
    // ------------------------
    assign imm = imm_src == `IMM_MUX_I ? {{20{instr[31]}}, instr[31:20]} : 
                 imm_src == `IMM_MUX_S ? {{20{instr[31]}}, instr[31:25], instr[11:7]} : 
                 imm_src == `IMM_MUX_B ? {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0} : 
                 imm_src == `IMM_MUX_J ? {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0} : 
                 imm_src == `IMM_MUX_U ? {instr[31:12], 12'b0} :
                 {instr[31:12], 12'b0};

    // ------------------------
    // ALU src mux
    // ------------------------
    assign alu_src0 = alu0_src == `ALU_MUX_SRC0_RS1 ? rs1_data : pc;
    assign alu_src1 = alu1_src == `ALU_MUX_SRC1_RS2 ? rs2_data : imm;
    assign exu_src0 = alu_src0;
    assign exu_src1 = alu_src1;

endmodule