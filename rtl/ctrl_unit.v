/*************************************************************************
 * @Copyright (c) 2026 by hello-yuki265, All Rights Reserved. 
 * @Author       : hello-yuki265
 * @Github       : 2658476808@qq.com
 * @Date         : 2026-04-17 13:02:36
 * @LastEditors  : hello-yuki265 2658476808@qq.com
 * @LastEditTime : 2026-04-21 01:30:22
 * @FilePath     : \RV_simple\rtl\ctrl_unit.v
 * @Description  : 
 *************************************************************************/
`include "glb_define.v"
module ctrl_unit (
    input clk,
    input rst_n,

    input [31:0] rv32_instr,

    // -----------------
    // 控制信号输出
    // -----------------
    output is_load,
    output is_imm,
    output is_store,
    output is_rtype,
    output is_btype,
    output is_jtype,
    output is_jalr,
    output is_lui,
    output is_auipc,
    output is_system,
    output [2:0] load_type,
    output [2:0] store_type,
    output [2:0] branch_type,
    output [`CSR_DEC_INFO_WIDTH-1:0] csr_dec_bus,

    output [`WB_MUX_WIDTH-1:0]res_src,
    output mem_write,
    output [9:0]alu_ctrl,
    output alu0_src,
    output alu1_src,
    output [2:0]imm_src,
    output reg_write
);
    // =======================
    // 指令opcode分类
    // =======================
    //I-type加载指令: 
    // --lw
    // --lb
    // --lh
    // --lbu
    // --lhu
    localparam [6:0] OPC_LOAD   = 7'b0000011; 
    
    //I-type算术逻辑指令: 
    // --addi, slli, slti, sltiu, 
    // --xori, srli, srai, ori, andi
    localparam [6:0] OPC_OP_IMM = 7'b0010011;  
    
    //Store指令 (S-type): 
    // --sw
    // --sb
    // --sh
    localparam [6:0] OPC_STORE  = 7'b0100011;  
    
    //R-type指令: 
    // --add, sub, sll, slt, sltu,
    // --xor, srl, sra, or, and
    localparam [6:0] OPC_REG    = 7'b0110011;   

    //Branch指令 (B-type)
    // --beq, bne, blt, bge, bltu, bgeu
    localparam [6:0] OPC_BRANCH = 7'b1100011;   

    //JAL指令 (J-type)
    // --jal
    localparam [6:0] OPC_JAL    = 7'b1101111;   

    //JALR指令 (I-type)
    localparam [6:0] OPC_JALR   = 7'b1100111;   

    // LUI指令(U-type)
    localparam [6:0] OPC_LUI   = 7'b0110111;   

    // AUIPC指令(U-type)
    localparam [6:0] OPC_AUIPC   = 7'b0010111;  
    
    // system instructions
    localparam [6:0] OPC_SYSTEM = 7'b1110011;

    // =======================
    // 指令解析
    // 对于RV32I，只使用funct7[5]，结合funct3与op，决定控制信号输出
    // =======================
    wire [6:0] funct7   = rv32_instr[31:25];
    wire [4:0] rs2      = rv32_instr[24:20];
    wire [4:0] rs1      = rv32_instr[19:15];
    wire [2:0] funct3   = rv32_instr[14:12];
    wire [4:0] rd       = rv32_instr[11:7];
    wire [6:0] op_code  = rv32_instr[6:0];

    assign is_load      = op_code == OPC_LOAD;
    assign is_imm       = op_code == OPC_OP_IMM;
    assign is_store     = op_code == OPC_STORE;
    assign is_rtype     = op_code == OPC_REG;
    assign is_btype     = op_code == OPC_BRANCH;
    assign is_jtype     = op_code == OPC_JAL;
    assign is_jalr      = op_code == OPC_JALR;
    assign is_lui       = op_code == OPC_LUI;
    assign is_auipc     = op_code == OPC_AUIPC;
    assign is_system    = op_code == OPC_SYSTEM;

    wire funct3_000 = (funct3 == 3'b000);
    wire funct3_001 = (funct3 == 3'b001);
    wire funct3_010 = (funct3 == 3'b010);
    wire funct3_011 = (funct3 == 3'b011);
    wire funct3_100 = (funct3 == 3'b100);
    wire funct3_101 = (funct3 == 3'b101);
    wire funct3_110 = (funct3 == 3'b110);
    wire funct3_111 = (funct3 == 3'b111);

    wire funct7_0000000 = (funct7 == 7'b0000000);
    wire funct7_0100000 = (funct7 == 7'b0100000);
    wire funct7_0000001 = (funct7 == 7'b0000001);
    wire funct7_0000101 = (funct7 == 7'b0000101);
    wire funct7_0001001 = (funct7 == 7'b0001001);
    wire funct7_0001101 = (funct7 == 7'b0001101);
    wire funct7_0010101 = (funct7 == 7'b0010101);
    wire funct7_0100001 = (funct7 == 7'b0100001);
    wire funct7_0010001 = (funct7 == 7'b0010001);
    wire funct7_0101101 = (funct7 == 7'b0101101);
    wire funct7_1111111 = (funct7 == 7'b1111111);
    wire funct7_0000100 = (funct7 == 7'b0000100); 
    wire funct7_0001000 = (funct7 == 7'b0001000); 
    wire funct7_0001100 = (funct7 == 7'b0001100); 
    wire funct7_0101100 = (funct7 == 7'b0101100); 
    wire funct7_0010000 = (funct7 == 7'b0010000); 
    wire funct7_0010100 = (funct7 == 7'b0010100); 
    wire funct7_1100000 = (funct7 == 7'b1100000); 
    wire funct7_1110000 = (funct7 == 7'b1110000); 
    wire funct7_1010000 = (funct7 == 7'b1010000); 
    wire funct7_1101000 = (funct7 == 7'b1101000); 
    wire funct7_1111000 = (funct7 == 7'b1111000); 
    wire funct7_1010001 = (funct7 == 7'b1010001);  
    wire funct7_1110001 = (funct7 == 7'b1110001);  
    wire funct7_1100001 = (funct7 == 7'b1100001);  
    wire funct7_1101001 = (funct7 == 7'b1101001);  

    // ------------------------------------
    // load
    // ------------------------------------
    wire rv32_lb = is_load & funct3_000;
    wire rv32_lh = is_load & funct3_001;
    wire rv32_lw = is_load & funct3_010;
    wire rv32_lbu = is_load & funct3_100;
    wire rv32_lhu = is_load & funct3_101;

    // --------------------------------------
    // op_imm
    // --------------------------------------
    wire rv32_addi      = is_imm & funct3_000;
    wire rv32_slli      = is_imm & funct3_001 & funct7_0000000;
    wire rv32_slti      = is_imm & funct3_010;
    wire rv32_sltiu     = is_imm & funct3_011;
    wire rv32_xori      = is_imm & funct3_100;
    wire rv32_srli      = is_imm & funct3_101 & funct7_0000000;
    wire rv32_srai      = is_imm & funct3_101 & funct7_0100000;
    wire rv32_ori       = is_imm & funct3_110;
    wire rv32_andi      = is_imm & funct3_111;

    // --------------------------------------
    // auipc
    // --------------------------------------
    wire rv32_auipc = is_auipc;

    // --------------------------------------
    // store
    // --------------------------------------
    wire rv32_sb = is_store & funct3_000;
    wire rv32_sh = is_store & funct3_001;
    wire rv32_sw = is_store & funct3_010;

    // --------------------------------------
    // r-type
    // --------------------------------------
    wire rv32_add   = is_rtype & funct7_0000000 & funct3_000;
    wire rv32_sub   = is_rtype & funct7_0100000 & funct3_000;
    wire rv32_sll   = is_rtype & funct7_0000000 & funct3_001;
    wire rv32_slt   = is_rtype & funct7_0000000 & funct3_010;
    wire rv32_sltu  = is_rtype & funct7_0000000 & funct3_011;
    wire rv32_xor   = is_rtype & funct7_0000000 & funct3_100;
    wire rv32_srl   = is_rtype & funct7_0000000 & funct3_101;
    wire rv32_sra   = is_rtype & funct7_0100000 & funct3_101;
    wire rv32_or    = is_rtype & funct7_0000000 & funct3_110;
    wire rv32_and   = is_rtype & funct7_0000000 & funct3_111;
    
    // --------------------------------------
    // branch
    // --------------------------------------
    wire rv32_beq = is_btype & funct3_000;
    wire rv32_bne = is_btype & funct3_001;
    wire rv32_blt = is_btype & funct3_100;
    wire rv32_bge = is_btype & funct3_101;
    wire rv32_bltu = is_btype & funct3_110;
    wire rv32_bgeu = is_btype & funct3_111;

    // lui
    wire rv32_lui = is_lui;

    // jalr
    wire rv32_jalr = is_jalr;

    // jal
    wire rv32_jal = is_jtype;

    // system
    wire rv32_ecall  = is_system & funct3_000 & (rv32_instr[31:20] == 12'b0000_0000_0000);
    wire rv32_ebreak = is_system & funct3_000 & (rv32_instr[31:20] == 12'b0000_0000_0001);
    // wire uret = is_system & funct3_000 & (rv32_instr[31:20] == 12'b0000_0000_0010);
    // wire sret = is_system & funct3_000 & (rv32_instr[31:20] == 12'd258);
    // wire mret = is_system & funct3_000 & (rv32_instr[31:20] == 12'd770);
    wire rv32_csrrw    = is_system & funct3_001; 
    wire rv32_csrrs    = is_system & funct3_010; 
    wire rv32_csrrc    = is_system & funct3_011; 
    wire rv32_csrrwi   = is_system & funct3_101; 
    wire rv32_csrrsi   = is_system & funct3_110; 
    wire rv32_csrrci   = is_system & funct3_111; 


    // ---------------------------------------
    // ALU Contral logic
    // ---------------------------------------
    wire [9:0]alu_mask;
    assign alu_mask[`ALU_MASK_ADD] = rv32_add | rv32_addi 
                                | is_load | is_store | is_auipc 
                                | rv32_jal | rv32_jalr;
    assign alu_mask[`ALU_MASK_SUB] = rv32_sub;
    assign alu_mask[`ALU_MASK_SLL] = rv32_sll |rv32_slli;
    assign alu_mask[`ALU_MASK_SLT] = rv32_slt | rv32_slti;
    assign alu_mask[`ALU_MASK_SLTU] = rv32_sltu | rv32_sltiu;
    assign alu_mask[`ALU_MASK_XOR] = rv32_xor | rv32_xori;
    assign alu_mask[`ALU_MASK_SRL] = rv32_srl | rv32_srli;
    assign alu_mask[`ALU_MASK_SRA] = rv32_sra | rv32_srai;
    assign alu_mask[`ALU_MASK_OR ] = rv32_or | rv32_ori;
    assign alu_mask[`ALU_MASK_AND] = rv32_and | rv32_andi;

    // =================================================
    // Main Control Logic
    // =================================================
    // ----------------------------------------
    // main ctrl logic
    // ----------------------------------------
    assign mem_write = is_store;
    assign reg_write =  is_load | is_imm | is_rtype | is_jtype | is_jalr | is_lui | is_auipc | is_system;

    assign alu0_src = rv32_auipc ? `ALU_MUX_SRC0_PC : `ALU_MUX_SRC0_RS1;
    assign alu1_src = (is_imm | is_load | is_store | rv32_auipc) ? `ALU_MUX_SRC1_IMM : `ALU_MUX_SRC1_RS2;
    assign imm_src = is_load | is_imm | rv32_jalr ? `IMM_MUX_I :
                     is_store ? `IMM_MUX_S :
                     is_btype ? `IMM_MUX_B :
                     is_jtype ? `IMM_MUX_J :
                     is_lui | is_auipc ? `IMM_MUX_U :
                     `IMM_MUX_I; //默认I-type立即数
    assign res_src = is_load ? `WB_MUX_MEM :
                     rv32_lui ? `WB_MUX_IMM :
                     rv32_auipc ? `WB_MUX_ALU :
                     (rv32_jal | rv32_jalr) ? `WB_MUX_PCPLUS4 :
                     is_system ? `WB_MUX_CSR :
                     `WB_MUX_ALU; //默认ALU结果
    assign alu_ctrl = alu_mask;
    assign load_type = funct3;
    assign store_type = funct3;
    assign branch_type = funct3;


    // --------------------------------------
    // Private/CSR
    // --------------------------------------
    
    assign csr_dec_bus[`CSR_DEC_CSRRW] = rv32_csrrw;
    assign csr_dec_bus[`CSR_DEC_CSRRS] = rv32_csrrs;
    assign csr_dec_bus[`CSR_DEC_CSRRC] = rv32_csrrc;
    assign csr_dec_bus[`CSR_DEC_CSRRWI] = rv32_csrrwi;
    assign csr_dec_bus[`CSR_DEC_CSRRSI] = rv32_csrrsi;
    assign csr_dec_bus[`CSR_DEC_CSRRCI] = rv32_csrrci;
    assign csr_dec_bus[`CSR_DEC_RS1] = rs1;
    assign csr_dec_bus[`CSR_DEC_IDX] = rv32_instr[31:20];
    


endmodule