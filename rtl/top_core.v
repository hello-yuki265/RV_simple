
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
    wire [7:0] pc;

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

    wire [24:0] imm;
    

    // -----------------------
    // regfile接口
    // -----------------------
    wire [31:0] rd_data;
    wire rd_write;
    wire [31:0] rs1_data;
    wire [31:0] rs2_data;

    // -----------------------
    // ctrl_unit接口
    // -----------------------
    wire pc_src;
    wire res_src;
    wire mem_write;
    wire [2:0] alu_ctrl;
    wire alu_src;
    wire imm_src;
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
    .pc_src(pc_src),
    .res_src(res_src),
    .mem_write(mem_write),
    .alu_ctrl(alu_ctrl),
    .alu_src(alu_src),
    .imm_src(imm_src),
    .reg_write(reg_write)
    );

    // ------------------------
    // Extend
    // ------------------------
    assign imm = imm_src == 2'b00 ? {{20{instr[31]}}, instr[31:20]} : 
                 imm_src == 2'b01 ? {{20{instr[31]}}, instr[31:25], instr[11:7]} : 
                 imm_src == 2'b10 ? {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0} : 
                 {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};
    
    // -----------------------------
    // IF取指
    // -----------------------------
    reg [7:0] pc_norm;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc_norm <= 0;
        end else begin
            // 这里加一，实际的是加了4个字节
            pc_norm <= pc_norm + 1;
        end
    end
    assign pc = !pc_src ? pc_norm : 0; //TODO: 这里跳转指令暂时没有写，先不考虑

    inst_mem  inst_mem_inst (
    .pc(pc),
    .instr(instr)
    );

    // -----------------------------
    // 译码、写回
    // -----------------------------
    assign rd_data = !res_src ? mem_r_data : res; //TODO，只考虑访存结果，还没有加其他指令
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
    assign src0 = rs1_data;
    assign src1 = !alu_src ? rs2_data : imm;
    alu  alu_inst (
    .clk(clk),
    .rst_n(rst_n),
    .alu_ctrl(alu_ctrl),
    .src0(src0),
    .src1(src1),
    .res(res)
    );

    // -----------------------------
    // 访存
    // -----------------------------
    assign mem_w_data = rs2_data;
    assign w_en = mem_write;
    data_mem  data_mem_inst (
    .clk(clk),
    .rst_n(rst_n),
    .addr(addr),
    .w_en(w_en),
    .w_data(mem_w_data),
    .rd_data(mem_r_data)
    );


endmodule