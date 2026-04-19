/*************************************************************************
 * @Copyright (c) 2026 by hello-yuki265, All Rights Reserved. 
 * @Author       : hello-yuki265
 * @Github       : 2658476808@qq.com
 * @Date         : 2026-04-17 15:05:46
 * @LastEditors  : hello-yuki265 2658476808@qq.com
 * @LastEditTime : 2026-04-19 11:06:25
 * @FilePath     : \RV_simple\rtl\top_core.v
 * @Description  : 
 *************************************************************************/

module top_core(
    clk,
    rst_n
);
    
    input clk;
    input rst_n;

    `include "glb_define.v"

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
    wire [2:0] load_type;
    wire [2:0] store_type;
    wire [2:0] branch_type;
    wire branch_jump;

    wire [1:0] res_src;
    wire mem_write;
    wire [3:0] alu_ctrl;
    wire alu0_src;
    wire alu1_src;
    wire [2:0]imm_src;
    wire reg_write;

    // ------------------------
    // ALU接口
    // ------------------------
    wire [31:0] src0;
    wire [31:0] src1;
    wire [31:0] res;

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
    .op_code(op_code),
    .funct3(funct3),
    .funct7(funct7),
    .alu_res(res),

    .is_load(is_load),
    .is_imm(is_imm),
    .is_store(is_store),
    .is_rtype(is_rtype),
    .is_btype(is_btype),
    .is_jtype(is_jtype),
    .is_jalr(is_jalr),
    .is_lui(is_lui),
    .is_auipc(is_auipc),

    .load_type(load_type),
    .store_type(store_type),
    .branch_type(branch_type),

    .res_src(res_src),
    .mem_write(mem_write),
    .alu_ctrl(alu_ctrl),
    .alu0_src(alu0_src),
    .alu1_src(alu1_src),
    .imm_src(imm_src),
    .reg_write(reg_write)
    );

    // ------------------------
    // Extend
    // ------------------------
    assign imm = imm_src == `IMM_MUX_I ? {{20{instr[31]}}, instr[31:20]} : 
                 imm_src == `IMM_MUX_S ? {{20{instr[31]}}, instr[31:25], instr[11:7]} : 
                 imm_src == `IMM_MUX_B ? {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0} : 
                 imm_src == `IMM_MUX_J ? {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0} : 
                 {instr[31:12], 12'b0};
    
    // -----------------------------
    // IF取指
    // -----------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc <= 0;
        end else begin
            case (pc_src)
                `PC_MUX_NORM: pc <= pc_plus4;
                `PC_MUX_PLUSIMM: pc <= pc + imm;
                `PC_MUX_ALU: pc <= res & ~1; // jalr指令需要将最低位置0
                default: pc <= pc_plus4;
             endcase
            
        end
    end
    assign pc_plus4 = pc + 4;
    assign pc_src = (is_btype & branch_jump) | is_jtype ? `PC_MUX_PLUSIMM : 
                    is_jalr ? `PC_MUX_ALU : `PC_MUX_NORM;
    

    inst_mem  inst_mem_inst (
    .pc(pc),
    .instr(instr)
    );

    // -----------------------------
    // 译码、写回
    // -----------------------------
    always @(*) begin
        case (res_src)
            `WB_MUX_MEM: rd_data = mem_r_data;
            `WB_MUX_ALU: rd_data = res;
            `WB_MUX_PCPLUS4: rd_data = pc_plus4;
            `WB_MUX_IMM: rd_data = imm;
            default: rd_data = mem_r_data;
        endcase
    end
    
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

    // -----------------------------
    // EX执行
    // -----------------------------
    assign src0 = alu0_src == `ALU_MUX_SRC0_RS1 ? rs1_data : pc;
    assign src1 = alu1_src == `ALU_MUX_SRC1_RS2 ? rs2_data : imm;
    alu  alu_inst (
    .clk(clk),
    .rst_n(rst_n),
    .alu_ctrl(alu_ctrl),
    .src0(src0),
    .src1(src1),
    .branch_type(branch_type),
    .res(res),
    .branch_jump(branch_jump)
    );

    // -----------------------------
    // 访存
    // -----------------------------
    assign mem_w_data = rs2_data;
    assign w_en = mem_write;
    data_mem  data_mem_inst (
    .clk(clk),
    .rst_n(rst_n),
    .addr(res),
    .w_en(w_en),
    .load_type(load_type),
    .store_type(store_type),
    .w_data(mem_w_data),
    .rd_data(mem_r_data)
    );


endmodule