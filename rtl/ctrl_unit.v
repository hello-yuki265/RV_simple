
module ctrl_unit (
    input clk,
    input rst_n,

    input [6:0] op_code,
    input [2:0] funct3,
    input [6:0] funct7,
    input       zero,

    // -----------------
    // 控制信号输出
    // -----------------
    output reg pc_src,
    output reg [1:0]res_src,
    output reg mem_write,
    output reg [2:0]alu_ctrl,
    output reg alu_src,
    output reg [1:0]imm_src,
    output reg reg_write
);
    // =======================
    // 指令解析
    // 对于RV32I，只使用funct7[5]，结合funct3与op，决定控制信号输出
    // =======================
    reg [6:0] op_list[0:8];
    initial begin
        op_list[0] = 7'b0000011;  // I-type加载指令
        op_list[1] = 7'b0010011;  // I-type算术逻辑指令
        op_list[2] = 7'b0100011;  // Store指令 (S-type)
        op_list[3] = 7'b0110011;  // R-type指令
        op_list[4] = 7'b1100011;  // Branch指令 (B-type)
        op_list[5] = 7'b1101111;  // JAL指令 (J-type)
        op_list[6] = 7'b1100111;  // JALR指令 (I-type)
        op_list[7] = 7'b0110111;  // LUI指令 (U-type)
        op_list[8] = 7'b0010111;  // AUIPC指令 (U-type)
    end
    
    reg [1:0] alu_op;
    reg jump;
    always @(*) begin
        res_src = 2'b00;
        mem_write = 0;
        alu_op = 0;
        alu_src = 0;
        imm_src = 0;
        reg_write = 0;

        jump = 0;

        case (op_code)
            op_list[0]: begin
                // I-type指令 (Load)
                alu_op = 2'b00;
                reg_write = 1;
                imm_src = 0;
                res_src = 2'b00;
                alu_src = 1;
            end
            op_list[1]: begin
                // I-type算术逻辑指令
                alu_op = 2'b00;
                reg_write = 1;
                imm_src = 0;
                res_src = 2'b01;
                alu_src = 1;
            end
            op_list[2]: begin
                // Store指令 (S-type)
                alu_op = 2'b00;
                reg_write = 0;
                imm_src = 1; //使用31:25，11:7共12位作为立即数
                alu_src = 1; //使用立即数进行计算
                mem_write = 1;

            end
            op_list[3]: begin
                // R-type指令
                alu_op = 2'b10;
                reg_write = 1;
                imm_src = 0;
                mem_write = 0;
                res_src = 2'b01;
            end
            op_list[4]: begin
                // Branch指令 (B-type)
                alu_op = 2'b01;
                imm_src = 2'b10;
            end
            
            op_list[5]: begin
                // JAL指令 (J-type)
                alu_op = 2'b01;
                imm_src = 2'b11;
                reg_write = 1;
                res_src = 2'b10;
                jump = 1;
            end
            op_list[6]: begin
                // JALR指令 (I-type)
            end
            op_list[7]: begin
                // LUI指令 (U-type)
            end
            op_list[8]: begin
                // AUIPC指令 (U-type)
            end
            default: begin
                // 默认情况
            end
        endcase
    end

    always @(*) begin
        case (alu_op)
            2'b00: begin
                alu_ctrl = 3'b000;
            end
            2'b01: begin
                alu_ctrl = 3'b001;
            end
            2'b10: begin
                case (funct3)
                    3'b000: begin
                        alu_ctrl = funct7[5] ? 3'b001 : 3'b000;
                    end
                    3'b010: begin
                        alu_ctrl = 3'b101;//小于置位
                    end
                    3'b110: begin
                        alu_ctrl = 3'b011;//或
                    end
                    3'b111: begin
                        alu_ctrl = 3'b010;//与
                    end
                endcase
            end


        endcase
    end

    reg branch_jump;
    always @(*) begin
        branch_jump = 0;
        if (op_code == op_list[4]) begin
            case(funct3)
                3'b000: begin
                    // beq
                    branch_jump = zero;
                end
                3'b001: begin
                    // bne
                    branch_jump = !zero;
                end
                3'b100: begin
                    // blt
                end
                3'b101: begin
                    // bge
                end
                3'b110: begin
                    // bltu
                end
                3'b111: begin
                    // bgeu
                end

            endcase
        end
    end

    always @(*) begin
        pc_src = branch_jump | jump;
    end


endmodule