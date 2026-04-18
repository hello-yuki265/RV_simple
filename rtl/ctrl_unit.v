
module ctrl_unit (
    input clk,
    input rst_n,

    input [6:0] op_code,
    input [2:0] funct3,
    input [6:0] funct7,
    input [31:0] alu_res,

    // -----------------
    // 控制信号输出
    // -----------------
    output reg pc_src,
    output reg [1:0]res_src,
    output reg mem_write,
    output reg [3:0]alu_ctrl,
    output reg alu_src,
    output reg [1:0]imm_src,
    output reg reg_write
);
    `include "glb_define.v"

    // =======================
    // 指令opcode分类
    // =======================
    //I-type加载指令: 
    // --lw
    // TODO INSTR:
    // --lb
    // --lh
    // --lbu
    // --lhu
    localparam [6:0] OPC_LOAD   = 7'b0000011; 
    
    //I-type算术逻辑指令: 
    // --addi
    // --slli
    // --slti
    // --sltiu
    // --xori
    // --srli
    // --srai
    // --ori
    // --andi
    localparam [6:0] OPC_OP_IMM = 7'b0010011;  
    
    //Store指令 (S-type): 
    // --sw
    // TODO INSTR:
    // --sb
    // --sh
    localparam [6:0] OPC_STORE  = 7'b0100011;  
    
    //R-type指令: 
    // --add
    // --sub
    // --sll
    // --slt
    // --sltu
    // --xor
    // --srl
    // --sra
    // --or
    // --and
    localparam [6:0] OPC_REG    = 7'b0110011;   

    //Branch指令 (B-type)
    // --beq
    // --bne
    // --blt
    // --bge
    // --bltu
    // --bgeu
    localparam [6:0] OPC_BRANCH = 7'b1100011;   

    //JAL指令 (J-type)
    // --jal
    localparam [6:0] OPC_JAL    = 7'b1101111;   

    //JALR指令 (I-type)
    localparam [6:0] OPC_JALR   = 7'b1100111;   

    // =======================
    // 指令解析
    // 对于RV32I，只使用funct7[5]，结合funct3与op，决定控制信号输出
    // =======================
    reg [1:0] alu_op;
    reg jump;
    reg is_load;
    reg is_imm;
    reg is_store;
    reg is_rtype;
    reg is_btype;
    reg is_jtype;
    reg [2:0]branch_type;


    always @(*) begin: decode_opc_proc
        is_load = 0;
        is_imm = 0;
        is_store = 0;
        is_rtype = 0;
        is_btype = 0;
        is_jtype = 0;
        branch_type = 0;

        case (op_code)
            OPC_LOAD: begin
                // I-type指令 (Load)
                is_load = 1;
            end
            OPC_OP_IMM: begin
                // I-type算术逻辑指令
                is_imm = 1;
            end
            OPC_STORE: begin
                // Store指令 (S-type)
                is_store = 1; 
            end
            OPC_REG: begin
                // R-type指令
                is_rtype = 1;
            end
            OPC_BRANCH: begin
                // Branch指令 (B-type)
                is_btype = 1;
                branch_type = funct3;
            end
            OPC_JAL: begin
                // JAL指令 (J-type)
                is_jtype = 1;
            end
            // op_list[6]: begin
            //     // JALR指令 (I-type)
            // end
            // op_list[7]: begin
            //     // LUI指令 (U-type)
            // end
            // op_list[8]: begin
            //     // AUIPC指令 (U-type)
            // end
            default: begin
                // 默认情况
            end
        endcase
    end

    reg branch_jump;
    always @(*) begin: main_sig_proc
        res_src = 2'b00;
        mem_write = 0;
        alu_op = 0;
        alu_src = 0;
        imm_src = 2'b00;
        reg_write = 0;
        branch_jump = 0;
        jump = 0;

        if (is_load) begin
            // LOAD_TYPE
            // lw s0, -8(s1)
            alu_op = 2'b00;
            reg_write = 1;
            imm_src = `IMM_MUX_I;
            res_src = `RES_MUX_MEM;
            alu_src = `ALU_MUX_IMM;
        end else if (is_imm) begin
            alu_op = 2'b00;
            reg_write = 1;
            imm_src = `IMM_MUX_I;
            res_src = `RES_MUX_ALU;
            alu_src = `ALU_MUX_IMM;
        end else if (is_store) begin
            alu_op = 2'b00;
            reg_write = 0;
            imm_src = `IMM_MUX_S; //使用31:25，11:7共12位作为立即数
            alu_src = `ALU_MUX_IMM; //使用立即数进行计算
            mem_write = 1;
        end else if (is_rtype) begin 
            alu_op = 2'b10;
            reg_write = 1;
            // imm_src = `IMM_MUX_6;
            mem_write = 0;
            res_src = `RES_MUX_ALU;
        end else if (is_btype) begin
            alu_op = 2'b01;
            imm_src = `IMM_MUX_B;
            case (branch_type)
                3'b000: begin
                    // beq
                    branch_jump = alu_res == 0;
                end
                3'b001: begin
                    // bne
                    branch_jump = alu_res != 0;
                end
                3'b100: begin
                    // blt
                    branch_jump = $signed(alu_res) < 32'sb0;
                end
                3'b101: begin
                    // bge
                    branch_jump = $signed(alu_res) >= 32'sb0;
                end
                3'b110: begin
                    // bltu
                    branch_jump = alu_res < 32'b0;
                end
                3'b111: begin
                    // bgeu
                    branch_jump = alu_res >= 32'b0;
                end
                default: begin
                    branch_jump = 0;
                end
            endcase
        end else if (is_jtype) begin
            alu_op = 2'b01;
            imm_src = `IMM_MUX_J;
            reg_write = 1;
            res_src = 2'b10;
            jump = 1;
        end
    end

    always @(*) begin: alu_ctrl_proc
        case (alu_op)
            2'b00: begin
                if (is_imm) begin
                    // immediate
                    case (funct3)
                        3'b000: begin
                            // addi
                            alu_ctrl = `ALU_ADD;
                        end
                        3'b001: begin
                            // slli
                            alu_ctrl = `ALU_SLL;
                        end
                        3'b010: begin
                            // slti
                            alu_ctrl = `ALU_SLT;//有符号小于置位
                        end
                        3'b011: begin
                            // sltiu
                            alu_ctrl = `ALU_SLTU;//无符号小于置位
                        end
                        3'b100: begin
                            // xori
                            alu_ctrl = `ALU_XOR;
                        end
                        3'b101: begin
                            // srli、srai
                            alu_ctrl = funct7[5] ? `ALU_SRA : `ALU_SRL;
                        end
                        3'b110: begin
                            // ori
                            alu_ctrl = `ALU_OR;//或
                        end
                        3'b111: begin
                            // andi
                            alu_ctrl = `ALU_AND;//与
                        end
                    endcase
                end else begin
                    // load, store
                    alu_ctrl = `ALU_ADD;
                end
            end
            2'b01: begin
                alu_ctrl = `ALU_SUB;
            end
            2'b10: begin
                case (funct3)
                    3'b000: begin
                        alu_ctrl = funct7[5] ? `ALU_SUB : `ALU_ADD;
                    end
                    3'b001: begin
                        // sll
                        alu_ctrl = `ALU_SLL;
                    end
                    3'b010: begin
                        // slt
                        alu_ctrl = `ALU_SLT;//有符号小于置位
                    end
                    3'b011: begin
                        // sltu
                        alu_ctrl = `ALU_SLTU;//无符号小于置位
                    end
                    3'b100: begin
                        // xor
                        alu_ctrl = `ALU_XOR;
                    end
                    3'b101: begin
                        // srl、sra
                        alu_ctrl = funct7[5] ? `ALU_SRA : `ALU_SRL;
                    end
                    3'b110: begin
                        // or
                        alu_ctrl = `ALU_OR;//或
                    end
                    3'b111: begin
                        // and
                        alu_ctrl = `ALU_AND;//与
                    end
                endcase
            end
            default: begin
                alu_ctrl = `ALU_ADD;
            end
        endcase
    end

    always @(*) begin
        pc_src = branch_jump | jump;
    end


endmodule