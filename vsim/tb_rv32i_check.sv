module tb_rv32i_check;

    logic clk;
    logic rst_n;
    int fail_count;
    int pass_count;

    top_core dut (
        .clk(clk),
        .rst_n(rst_n)
    );

    localparam [6:0] OPC_LOAD   = 7'b0000011;
    localparam [6:0] OPC_OP_IMM = 7'b0010011;
    localparam [6:0] OPC_STORE  = 7'b0100011;
    localparam [6:0] OPC_OP     = 7'b0110011;
    localparam [6:0] OPC_LUI    = 7'b0110111;
    localparam [6:0] OPC_BRANCH = 7'b1100011;
    localparam [6:0] OPC_JALR   = 7'b1100111;
    localparam [6:0] OPC_JAL    = 7'b1101111;
    localparam [6:0] OPC_AUIPC  = 7'b0010111;
    localparam [6:0] OPC_SYSTEM = 7'b1110011;

    localparam [11:0] CSR_MSCRATCH = 12'h340;
    localparam [11:0] CSR_MEPC     = 12'h341;
    localparam [11:0] CSR_MCAUSE   = 12'h342;
    localparam [11:0] CSR_MTVEC    = 12'h305;

    localparam [31:0] NOP = 32'h00000013;
    localparam [31:0] INST_ECALL = 32'h00000073;
    localparam [31:0] INST_MRET  = 32'h30200073;

    function automatic [31:0] encode_r(
        input [6:0] funct7,
        input [4:0] rs2,
        input [4:0] rs1,
        input [2:0] funct3,
        input [4:0] rd,
        input [6:0] opcode
    );
        encode_r = {funct7, rs2, rs1, funct3, rd, opcode};
    endfunction

    function automatic [31:0] encode_i(
        input int imm,
        input [4:0] rs1,
        input [2:0] funct3,
        input [4:0] rd,
        input [6:0] opcode
    );
        logic [11:0] imm12;
        begin
            imm12 = imm[11:0];
            encode_i = {imm12, rs1, funct3, rd, opcode};
        end
    endfunction

    function automatic [31:0] encode_s(
        input int imm,
        input [4:0] rs2,
        input [4:0] rs1,
        input [2:0] funct3,
        input [6:0] opcode
    );
        logic [11:0] imm12;
        begin
            imm12 = imm[11:0];
            encode_s = {imm12[11:5], rs2, rs1, funct3, imm12[4:0], opcode};
        end
    endfunction

    function automatic [31:0] encode_b(
        input int imm,
        input [4:0] rs2,
        input [4:0] rs1,
        input [2:0] funct3,
        input [6:0] opcode
    );
        logic [12:0] imm13;
        begin
            imm13 = imm[12:0];
            encode_b = {imm13[12], imm13[10:5], rs2, rs1, funct3, imm13[4:1], imm13[11], opcode};
        end
    endfunction

    function automatic [31:0] encode_u(
        input int imm20,
        input [4:0] rd,
        input [6:0] opcode
    );
        logic [19:0] imm_u;
        begin
            imm_u = imm20[19:0];
            encode_u = {imm_u, rd, opcode};
        end
    endfunction

    function automatic [31:0] encode_j(
        input int imm,
        input [4:0] rd,
        input [6:0] opcode
    );
        logic [20:0] imm21;
        begin
            imm21 = imm[20:0];
            encode_j = {imm21[20], imm21[10:1], imm21[11], imm21[19:12], rd, opcode};
        end
    endfunction

    function automatic [31:0] encode_csr(
        input [11:0] csr,
        input [4:0] src,
        input [2:0] funct3,
        input [4:0] rd
    );
        begin
            encode_csr = {csr, src, funct3, rd, OPC_SYSTEM};
        end
    endfunction

    task automatic clear_state;
        int idx;
        begin
            rst_n = 1'b0;
            dut.core_pc = 32'b0;
            for (idx = 0; idx < 128; idx = idx + 1) begin
                dut.inst_mem_inst.mem[idx] = NOP;
            end
            for (idx = 0; idx < 32; idx = idx + 1) begin
                dut.regfile_inst.register[idx] = 32'b0;
            end
            for (idx = 0; idx < 512; idx = idx + 1) begin
                dut.data_mem_inst.mem[idx] = 8'b0;
            end
        end
    endtask

    task automatic apply_reset;
        begin
            rst_n = 1'b0;
            repeat (2) @(posedge clk);
            rst_n = 1'b1;
            #1;
        end
    endtask

    task automatic run_cycles(input int cycles);
        begin
            repeat (cycles) @(posedge clk);
            #1;
        end
    endtask

    task automatic expect_reg(
        input int idx,
        input logic [31:0] expected,
        input string label
    );
        logic [31:0] actual;
        begin
            actual = dut.regfile_inst.register[idx];
            if (actual !== expected) begin
                $display("FAIL %-24s x%0d expected=0x%08h actual=0x%08h", label, idx, expected, actual);
                fail_count = fail_count + 1;
            end else begin
                $display("PASS %-24s x%0d = 0x%08h", label, idx, actual);
                pass_count = pass_count + 1;
            end
        end
    endtask

    task automatic expect_mem_byte(
        input int addr,
        input logic [7:0] expected,
        input string label
    );
        logic [7:0] actual;
        begin
            actual = dut.data_mem_inst.mem[addr];
            if (actual !== expected) begin
                $display("FAIL %-24s mem[%0d] expected=0x%02h actual=0x%02h", label, addr, expected, actual);
                fail_count = fail_count + 1;
            end else begin
                $display("PASS %-24s mem[%0d] = 0x%02h", label, addr, actual);
                pass_count = pass_count + 1;
            end
        end
    endtask

    task automatic expect_csr(
        input logic [31:0] actual,
        input logic [31:0] expected,
        input string label
    );
        begin
            if (actual !== expected) begin
                $display("FAIL %-24s expected=0x%08h actual=0x%08h", label, expected, actual);
                fail_count = fail_count + 1;
            end else begin
                $display("PASS %-24s = 0x%08h", label, actual);
                pass_count = pass_count + 1;
            end
        end
    endtask

    task automatic expect_pc(
        input logic [31:0] expected,
        input string label
    );
        logic [31:0] actual;
        begin
            actual = dut.core_pc;
            if (actual !== expected) begin
                $display("FAIL %-24s core_pc expected=0x%08h actual=0x%08h", label, expected, actual);
                fail_count = fail_count + 1;
            end else begin
                $display("PASS %-24s core_pc = 0x%08h", label, actual);
                pass_count = pass_count + 1;
            end
        end
    endtask

    task automatic test_alu_ops;
        begin
            $display("\n==== TEST: ALU / OP-IMM / OP ====");
            clear_state();

            dut.inst_mem_inst.mem[0]  = encode_i(5,      5'd0, 3'b000, 5'd1,  OPC_OP_IMM);
            dut.inst_mem_inst.mem[1]  = encode_i(12,     5'd0, 3'b000, 5'd2,  OPC_OP_IMM);
            dut.inst_mem_inst.mem[2]  = encode_i(-8,     5'd0, 3'b000, 5'd3,  OPC_OP_IMM);
            dut.inst_mem_inst.mem[3]  = encode_r(7'b0000000, 5'd2,  5'd1, 3'b000, 5'd4,  OPC_OP);
            dut.inst_mem_inst.mem[4]  = encode_r(7'b0100000, 5'd1,  5'd2, 3'b000, 5'd5,  OPC_OP);
            dut.inst_mem_inst.mem[5]  = encode_r(7'b0000000, 5'd1,  5'd1, 3'b001, 5'd6,  OPC_OP);
            dut.inst_mem_inst.mem[6]  = encode_r(7'b0000000, 5'd1,  5'd3, 3'b010, 5'd7,  OPC_OP);
            dut.inst_mem_inst.mem[7]  = encode_r(7'b0000000, 5'd1,  5'd3, 3'b011, 5'd8,  OPC_OP);
            dut.inst_mem_inst.mem[8]  = encode_r(7'b0000000, 5'd2,  5'd1, 3'b100, 5'd9,  OPC_OP);
            dut.inst_mem_inst.mem[9]  = encode_i(1,      5'd0, 3'b000, 5'd10, OPC_OP_IMM);
            dut.inst_mem_inst.mem[10] = encode_r(7'b0000000, 5'd10, 5'd2, 3'b101, 5'd11, OPC_OP);
            dut.inst_mem_inst.mem[11] = encode_r(7'b0100000, 5'd10, 5'd3, 3'b101, 5'd12, OPC_OP);
            dut.inst_mem_inst.mem[12] = encode_r(7'b0000000, 5'd2,  5'd1, 3'b110, 5'd13, OPC_OP);
            dut.inst_mem_inst.mem[13] = encode_r(7'b0000000, 5'd2,  5'd1, 3'b111, 5'd14, OPC_OP);
            dut.inst_mem_inst.mem[14] = encode_i(2,      5'd1, 3'b001, 5'd15, OPC_OP_IMM);
            dut.inst_mem_inst.mem[15] = encode_i(0,      5'd3, 3'b010, 5'd16, OPC_OP_IMM);
            dut.inst_mem_inst.mem[16] = encode_i(8,      5'd3, 3'b011, 5'd17, OPC_OP_IMM);
            dut.inst_mem_inst.mem[17] = encode_i(3,      5'd1, 3'b100, 5'd18, OPC_OP_IMM);
            dut.inst_mem_inst.mem[18] = encode_i(2,      5'd2, 3'b101, 5'd19, OPC_OP_IMM);
            dut.inst_mem_inst.mem[19] = encode_i(12'h402,5'd3, 3'b101, 5'd20, OPC_OP_IMM);
            dut.inst_mem_inst.mem[20] = encode_i(8,      5'd1, 3'b110, 5'd21, OPC_OP_IMM);
            dut.inst_mem_inst.mem[21] = encode_i(8,      5'd2, 3'b111, 5'd22, OPC_OP_IMM);

            apply_reset();
            run_cycles(26);

            expect_reg(1,  32'h00000005, "addi x1");
            expect_reg(2,  32'h0000000c, "addi x2");
            expect_reg(3,  32'hfffffff8, "addi x3");
            expect_reg(4,  32'h00000011, "add");
            expect_reg(5,  32'h00000007, "sub");
            expect_reg(6,  32'h000000a0, "sll");
            expect_reg(7,  32'h00000001, "slt");
            expect_reg(8,  32'h00000000, "sltu");
            expect_reg(9,  32'h00000009, "xor");
            expect_reg(10, 32'h00000001, "addi shift amount");
            expect_reg(11, 32'h00000006, "srl");
            expect_reg(12, 32'hfffffffc, "sra");
            expect_reg(13, 32'h0000000d, "or");
            expect_reg(14, 32'h00000004, "and");
            expect_reg(15, 32'h00000014, "slli");
            expect_reg(16, 32'h00000001, "slti");
            expect_reg(17, 32'h00000000, "sltiu");
            expect_reg(18, 32'h00000006, "xori");
            expect_reg(19, 32'h00000003, "srli");
            expect_reg(20, 32'hfffffffe, "srai");
            expect_reg(21, 32'h0000000d, "ori");
            expect_reg(22, 32'h00000008, "andi");
        end
    endtask

    task automatic test_load_store;
        begin
            $display("\n==== TEST: LOAD / STORE ====");
            clear_state();

            dut.inst_mem_inst.mem[0]  = encode_i(64,     5'd0, 3'b000, 5'd1, OPC_OP_IMM);
            dut.inst_mem_inst.mem[1]  = encode_i(-1,     5'd0, 3'b000, 5'd2, OPC_OP_IMM);
            dut.inst_mem_inst.mem[2]  = encode_s(0,      5'd2, 5'd1, 3'b000, OPC_STORE);
            dut.inst_mem_inst.mem[3]  = encode_u(20'h00008, 5'd3, OPC_LUI);
            dut.inst_mem_inst.mem[4]  = encode_i(1,      5'd3, 3'b000, 5'd3, OPC_OP_IMM);
            dut.inst_mem_inst.mem[5]  = encode_s(2,      5'd3, 5'd1, 3'b001, OPC_STORE);
            dut.inst_mem_inst.mem[6]  = encode_u(20'h12345, 5'd4, OPC_LUI);
            dut.inst_mem_inst.mem[7]  = encode_i(16'h678, 5'd4, 3'b000, 5'd4, OPC_OP_IMM);
            dut.inst_mem_inst.mem[8]  = encode_s(4,      5'd4, 5'd1, 3'b010, OPC_STORE);
            dut.inst_mem_inst.mem[9]  = encode_i(0,      5'd1, 3'b000, 5'd5, OPC_LOAD);
            dut.inst_mem_inst.mem[10] = encode_i(0,      5'd1, 3'b100, 5'd6, OPC_LOAD);
            dut.inst_mem_inst.mem[11] = encode_i(2,      5'd1, 3'b001, 5'd7, OPC_LOAD);
            dut.inst_mem_inst.mem[12] = encode_i(2,      5'd1, 3'b101, 5'd8, OPC_LOAD);
            dut.inst_mem_inst.mem[13] = encode_i(4,      5'd1, 3'b010, 5'd9, OPC_LOAD);

            apply_reset();
            run_cycles(18);

            expect_reg(5, 32'hffffffff, "lb");
            expect_reg(6, 32'h000000ff, "lbu");
            expect_reg(7, 32'hffff8001, "lh");
            expect_reg(8, 32'h00008001, "lhu");
            expect_reg(9, 32'h12345678, "lw");

            expect_mem_byte(64, 8'hff, "sb byte");
            expect_mem_byte(66, 8'h01, "sh low byte");
            expect_mem_byte(67, 8'h80, "sh high byte");
            expect_mem_byte(68, 8'h78, "sw byte0");
            expect_mem_byte(69, 8'h56, "sw byte1");
            expect_mem_byte(70, 8'h34, "sw byte2");
            expect_mem_byte(71, 8'h12, "sw byte3");
        end
    endtask

    task automatic test_control_flow;
        begin
            $display("\n==== TEST: BRANCH / JUMP / U-TYPE ====");
            clear_state();

            dut.inst_mem_inst.mem[0]  = encode_u(20'h12345, 5'd1,  OPC_LUI);
            dut.inst_mem_inst.mem[1]  = encode_u(20'h00001, 5'd2,  OPC_AUIPC);
            dut.inst_mem_inst.mem[2]  = encode_i(5,       5'd0, 3'b000, 5'd3,  OPC_OP_IMM);
            dut.inst_mem_inst.mem[3]  = encode_i(5,       5'd0, 3'b000, 5'd4,  OPC_OP_IMM);
            dut.inst_mem_inst.mem[4]  = encode_b(8,       5'd4, 5'd3, 3'b000, OPC_BRANCH);
            dut.inst_mem_inst.mem[5]  = encode_i(1,       5'd0, 3'b000, 5'd10, OPC_OP_IMM);
            dut.inst_mem_inst.mem[6]  = encode_i(2,       5'd0, 3'b000, 5'd10, OPC_OP_IMM);
            dut.inst_mem_inst.mem[7]  = encode_i(7,       5'd0, 3'b000, 5'd4,  OPC_OP_IMM);
            dut.inst_mem_inst.mem[8]  = encode_b(8,       5'd4, 5'd3, 3'b001, OPC_BRANCH);
            dut.inst_mem_inst.mem[9]  = encode_i(1,       5'd0, 3'b000, 5'd11, OPC_OP_IMM);
            dut.inst_mem_inst.mem[10] = encode_i(2,       5'd0, 3'b000, 5'd11, OPC_OP_IMM);
            dut.inst_mem_inst.mem[11] = encode_i(-1,      5'd0, 3'b000, 5'd5,  OPC_OP_IMM);
            dut.inst_mem_inst.mem[12] = encode_i(1,       5'd0, 3'b000, 5'd6,  OPC_OP_IMM);
            dut.inst_mem_inst.mem[13] = encode_b(8,       5'd6, 5'd5, 3'b100, OPC_BRANCH);
            dut.inst_mem_inst.mem[14] = encode_i(1,       5'd0, 3'b000, 5'd12, OPC_OP_IMM);
            dut.inst_mem_inst.mem[15] = encode_i(2,       5'd0, 3'b000, 5'd12, OPC_OP_IMM);
            dut.inst_mem_inst.mem[16] = encode_b(8,       5'd5, 5'd6, 3'b101, OPC_BRANCH);
            dut.inst_mem_inst.mem[17] = encode_i(1,       5'd0, 3'b000, 5'd13, OPC_OP_IMM);
            dut.inst_mem_inst.mem[18] = encode_i(2,       5'd0, 3'b000, 5'd13, OPC_OP_IMM);
            dut.inst_mem_inst.mem[19] = encode_u(20'h80000, 5'd7,  OPC_LUI);
            dut.inst_mem_inst.mem[20] = encode_i(1,       5'd0, 3'b000, 5'd8,  OPC_OP_IMM);
            dut.inst_mem_inst.mem[21] = encode_b(8,       5'd7, 5'd8, 3'b110, OPC_BRANCH);
            dut.inst_mem_inst.mem[22] = encode_i(1,       5'd0, 3'b000, 5'd14, OPC_OP_IMM);
            dut.inst_mem_inst.mem[23] = encode_i(2,       5'd0, 3'b000, 5'd14, OPC_OP_IMM);
            dut.inst_mem_inst.mem[24] = encode_b(8,       5'd8, 5'd7, 3'b111, OPC_BRANCH);
            dut.inst_mem_inst.mem[25] = encode_i(1,       5'd0, 3'b000, 5'd15, OPC_OP_IMM);
            dut.inst_mem_inst.mem[26] = encode_i(2,       5'd0, 3'b000, 5'd15, OPC_OP_IMM);
            dut.inst_mem_inst.mem[27] = encode_j(8,       5'd16, OPC_JAL);
            dut.inst_mem_inst.mem[28] = encode_i(1,       5'd0, 3'b000, 5'd17, OPC_OP_IMM);
            dut.inst_mem_inst.mem[29] = encode_i(2,       5'd0, 3'b000, 5'd17, OPC_OP_IMM);
            dut.inst_mem_inst.mem[30] = encode_i(137,     5'd0, 3'b000, 5'd18, OPC_OP_IMM);
            dut.inst_mem_inst.mem[31] = encode_i(0,       5'd18,3'b000, 5'd19, OPC_JALR);
            dut.inst_mem_inst.mem[32] = encode_i(1,       5'd0, 3'b000, 5'd20, OPC_OP_IMM);
            dut.inst_mem_inst.mem[33] = encode_i(1,       5'd0, 3'b000, 5'd20, OPC_OP_IMM);
            dut.inst_mem_inst.mem[34] = encode_i(2,       5'd0, 3'b000, 5'd20, OPC_OP_IMM);
            dut.inst_mem_inst.mem[35] = encode_b(8,       5'd4, 5'd3, 3'b000, OPC_BRANCH);
            dut.inst_mem_inst.mem[36] = encode_i(3,       5'd0, 3'b000, 5'd21, OPC_OP_IMM);

            apply_reset();
            run_cycles(42);

            expect_reg(1,  32'h12345000, "lui");
            expect_reg(2,  32'h00001004, "auipc");
            expect_reg(10, 32'h00000002, "beq taken");
            expect_reg(11, 32'h00000002, "bne taken");
            expect_reg(12, 32'h00000002, "blt taken");
            expect_reg(13, 32'h00000002, "bge taken");
            expect_reg(14, 32'h00000002, "bltu taken");
            expect_reg(15, 32'h00000002, "bgeu taken");
            expect_reg(16, 32'h00000070, "jal link");
            expect_reg(17, 32'h00000002, "jal skip");
            expect_reg(19, 32'h00000080, "jalr link");
            expect_reg(20, 32'h00000002, "jalr target");
            expect_reg(21, 32'h00000003, "branch not taken");
        end
    endtask

    task automatic test_branch_signedness;
        begin
            $display("\n==== TEST: BRANCH SIGNED / UNSIGNED ====");
            clear_state();

            dut.inst_mem_inst.mem[0]  = encode_u(20'h80000, 5'd1,  OPC_LUI);
            dut.inst_mem_inst.mem[1]  = encode_i(1,       5'd0, 3'b000, 5'd2,  OPC_OP_IMM);
            dut.inst_mem_inst.mem[2]  = encode_i(-1,      5'd0, 3'b000, 5'd3,  OPC_OP_IMM);
            dut.inst_mem_inst.mem[3]  = encode_u(20'h80000, 5'd4,  OPC_LUI);
            dut.inst_mem_inst.mem[4]  = encode_i(-1,      5'd4, 3'b000, 5'd4,  OPC_OP_IMM);

            dut.inst_mem_inst.mem[5]  = encode_b(12,      5'd2, 5'd1, 3'b100, OPC_BRANCH);
            dut.inst_mem_inst.mem[6]  = encode_i(1,       5'd0, 3'b000, 5'd10, OPC_OP_IMM);
            dut.inst_mem_inst.mem[7]  = encode_j(8,       5'd0, OPC_JAL);
            dut.inst_mem_inst.mem[8]  = encode_i(2,       5'd0, 3'b000, 5'd10, OPC_OP_IMM);

            dut.inst_mem_inst.mem[9]  = encode_b(12,      5'd2, 5'd1, 3'b110, OPC_BRANCH);
            dut.inst_mem_inst.mem[10] = encode_i(1,       5'd0, 3'b000, 5'd11, OPC_OP_IMM);
            dut.inst_mem_inst.mem[11] = encode_j(8,       5'd0, OPC_JAL);
            dut.inst_mem_inst.mem[12] = encode_i(2,       5'd0, 3'b000, 5'd11, OPC_OP_IMM);

            dut.inst_mem_inst.mem[13] = encode_b(12,      5'd2, 5'd1, 3'b101, OPC_BRANCH);
            dut.inst_mem_inst.mem[14] = encode_i(1,       5'd0, 3'b000, 5'd12, OPC_OP_IMM);
            dut.inst_mem_inst.mem[15] = encode_j(8,       5'd0, OPC_JAL);
            dut.inst_mem_inst.mem[16] = encode_i(2,       5'd0, 3'b000, 5'd12, OPC_OP_IMM);

            dut.inst_mem_inst.mem[17] = encode_b(12,      5'd2, 5'd1, 3'b111, OPC_BRANCH);
            dut.inst_mem_inst.mem[18] = encode_i(1,       5'd0, 3'b000, 5'd13, OPC_OP_IMM);
            dut.inst_mem_inst.mem[19] = encode_j(8,       5'd0, OPC_JAL);
            dut.inst_mem_inst.mem[20] = encode_i(2,       5'd0, 3'b000, 5'd13, OPC_OP_IMM);

            dut.inst_mem_inst.mem[21] = encode_b(12,      5'd0, 5'd3, 3'b100, OPC_BRANCH);
            dut.inst_mem_inst.mem[22] = encode_i(1,       5'd0, 3'b000, 5'd14, OPC_OP_IMM);
            dut.inst_mem_inst.mem[23] = encode_j(8,       5'd0, OPC_JAL);
            dut.inst_mem_inst.mem[24] = encode_i(2,       5'd0, 3'b000, 5'd14, OPC_OP_IMM);

            dut.inst_mem_inst.mem[25] = encode_b(12,      5'd0, 5'd3, 3'b110, OPC_BRANCH);
            dut.inst_mem_inst.mem[26] = encode_i(1,       5'd0, 3'b000, 5'd15, OPC_OP_IMM);
            dut.inst_mem_inst.mem[27] = encode_j(8,       5'd0, OPC_JAL);
            dut.inst_mem_inst.mem[28] = encode_i(2,       5'd0, 3'b000, 5'd15, OPC_OP_IMM);

            dut.inst_mem_inst.mem[29] = encode_b(12,      5'd0, 5'd3, 3'b101, OPC_BRANCH);
            dut.inst_mem_inst.mem[30] = encode_i(1,       5'd0, 3'b000, 5'd16, OPC_OP_IMM);
            dut.inst_mem_inst.mem[31] = encode_j(8,       5'd0, OPC_JAL);
            dut.inst_mem_inst.mem[32] = encode_i(2,       5'd0, 3'b000, 5'd16, OPC_OP_IMM);

            dut.inst_mem_inst.mem[33] = encode_b(12,      5'd0, 5'd3, 3'b111, OPC_BRANCH);
            dut.inst_mem_inst.mem[34] = encode_i(1,       5'd0, 3'b000, 5'd17, OPC_OP_IMM);
            dut.inst_mem_inst.mem[35] = encode_j(8,       5'd0, OPC_JAL);
            dut.inst_mem_inst.mem[36] = encode_i(2,       5'd0, 3'b000, 5'd17, OPC_OP_IMM);

            dut.inst_mem_inst.mem[37] = encode_b(12,      5'd1, 5'd4, 3'b100, OPC_BRANCH);
            dut.inst_mem_inst.mem[38] = encode_i(1,       5'd0, 3'b000, 5'd18, OPC_OP_IMM);
            dut.inst_mem_inst.mem[39] = encode_j(8,       5'd0, OPC_JAL);
            dut.inst_mem_inst.mem[40] = encode_i(2,       5'd0, 3'b000, 5'd18, OPC_OP_IMM);

            dut.inst_mem_inst.mem[41] = encode_b(12,      5'd1, 5'd4, 3'b110, OPC_BRANCH);
            dut.inst_mem_inst.mem[42] = encode_i(1,       5'd0, 3'b000, 5'd19, OPC_OP_IMM);
            dut.inst_mem_inst.mem[43] = encode_j(8,       5'd0, OPC_JAL);
            dut.inst_mem_inst.mem[44] = encode_i(2,       5'd0, 3'b000, 5'd19, OPC_OP_IMM);

            dut.inst_mem_inst.mem[45] = encode_b(12,      5'd1, 5'd4, 3'b101, OPC_BRANCH);
            dut.inst_mem_inst.mem[46] = encode_i(1,       5'd0, 3'b000, 5'd20, OPC_OP_IMM);
            dut.inst_mem_inst.mem[47] = encode_j(8,       5'd0, OPC_JAL);
            dut.inst_mem_inst.mem[48] = encode_i(2,       5'd0, 3'b000, 5'd20, OPC_OP_IMM);

            dut.inst_mem_inst.mem[49] = encode_b(12,      5'd1, 5'd4, 3'b111, OPC_BRANCH);
            dut.inst_mem_inst.mem[50] = encode_i(1,       5'd0, 3'b000, 5'd21, OPC_OP_IMM);
            dut.inst_mem_inst.mem[51] = encode_j(8,       5'd0, OPC_JAL);
            dut.inst_mem_inst.mem[52] = encode_i(2,       5'd0, 3'b000, 5'd21, OPC_OP_IMM);

            apply_reset();
            run_cycles(60);

            expect_reg(1,  32'h80000000, "branch ref x1");
            expect_reg(2,  32'h00000001, "branch ref x2");
            expect_reg(3,  32'hffffffff, "branch ref x3");
            expect_reg(4,  32'h7fffffff, "branch ref x4");

            expect_reg(10, 32'h00000002, "blt 0x80000000 < 1");
            expect_reg(11, 32'h00000001, "bltu 0x80000000 < 1");
            expect_reg(12, 32'h00000001, "bge 0x80000000 >= 1");
            expect_reg(13, 32'h00000002, "bgeu 0x80000000 >= 1");
            expect_reg(14, 32'h00000002, "blt -1 < 0");
            expect_reg(15, 32'h00000001, "bltu 0xffffffff < 0");
            expect_reg(16, 32'h00000001, "bge -1 >= 0");
            expect_reg(17, 32'h00000002, "bgeu 0xffffffff >= 0");
            expect_reg(18, 32'h00000001, "blt 0x7fffffff < 0x80000000");
            expect_reg(19, 32'h00000002, "bltu 0x7fffffff < 0x80000000");
            expect_reg(20, 32'h00000002, "bge 0x7fffffff >= 0x80000000");
            expect_reg(21, 32'h00000001, "bgeu 0x7fffffff >= 0x80000000");
        end
    endtask

    task automatic test_csr_ops;
        begin
            $display("\n==== TEST: CSR ====");
            clear_state();

            dut.inst_mem_inst.mem[0]  = encode_u(20'h12345, 5'd1,  OPC_LUI);
            dut.inst_mem_inst.mem[1]  = encode_i(12'h067, 5'd1, 3'b000, 5'd1,  OPC_OP_IMM);
            dut.inst_mem_inst.mem[2]  = encode_i(12'h15a, 5'd0, 3'b000, 5'd2,  OPC_OP_IMM);
            dut.inst_mem_inst.mem[3]  = encode_i(12'h00f, 5'd0, 3'b000, 5'd3,  OPC_OP_IMM);

            dut.inst_mem_inst.mem[4]  = encode_csr(CSR_MTVEC,    5'd1,  3'b001, 5'd10);
            dut.inst_mem_inst.mem[5]  = encode_csr(CSR_MTVEC,    5'd0,  3'b010, 5'd11);

            dut.inst_mem_inst.mem[6]  = encode_csr(CSR_MSCRATCH, 5'd26, 3'b101, 5'd12);
            dut.inst_mem_inst.mem[7]  = encode_csr(CSR_MSCRATCH, 5'd3,  3'b011, 5'd13);
            dut.inst_mem_inst.mem[8]  = encode_csr(CSR_MSCRATCH, 5'd0,  3'b010, 5'd14);

            dut.inst_mem_inst.mem[9]  = encode_csr(CSR_MEPC,     5'd2,  3'b001, 5'd15);
            dut.inst_mem_inst.mem[10] = encode_csr(CSR_MEPC,     5'd0,  3'b010, 5'd16);

            dut.inst_mem_inst.mem[11] = encode_csr(CSR_MCAUSE,   5'd7,  3'b101, 5'd17);
            dut.inst_mem_inst.mem[12] = encode_csr(CSR_MCAUSE,   5'd8,  3'b110, 5'd18);
            dut.inst_mem_inst.mem[13] = encode_csr(CSR_MCAUSE,   5'd3,  3'b111, 5'd19);
            dut.inst_mem_inst.mem[14] = encode_csr(CSR_MCAUSE,   5'd0,  3'b010, 5'd20);

            apply_reset();
            run_cycles(20);

            expect_reg(1,  32'h12345067, "csr src x1");
            expect_reg(2,  32'h0000015a, "csr src x2");
            expect_reg(3,  32'h0000000f, "csr src x3");

            expect_reg(10, 32'h00000000, "csrrw mtvec old");
            expect_reg(11, 32'h12345067, "csrrs mtvec read");
            expect_csr(dut.csr_inst.csr_mtvec, 32'h12345067, "mtvec state");

            expect_reg(12, 32'h00000000, "csrrwi mscratch old");
            expect_reg(13, 32'h0000001a, "csrrc mscratch old");
            expect_reg(14, 32'h00000010, "csrrs mscratch read");
            expect_csr(dut.csr_inst.csr_mscratch, 32'h00000010, "mscratch state");

            expect_reg(15, 32'h00000000, "csrrw mepc old");
            expect_reg(16, 32'h0000015a, "csrrs mepc read");
            expect_csr(dut.csr_inst.csr_mepc, 32'h0000015a, "mepc state");

            expect_reg(17, 32'h00000000, "csrrwi mcause old");
            expect_reg(18, 32'h00000007, "csrrsi mcause old");
            expect_reg(19, 32'h0000000f, "csrrci mcause old");
            expect_reg(20, 32'h0000000c, "csrrs mcause read");
            expect_csr(dut.csr_inst.csr_mcause, 32'h0000000c, "mcause state");
        end
    endtask

    task automatic test_csr_rd_writeback;
        begin
            $display("\n==== TEST: CSR RD WRITEBACK ====");
            clear_state();

            dut.inst_mem_inst.mem[0]  = encode_i(12'h055, 5'd0, 3'b000, 5'd1,  OPC_OP_IMM);
            dut.inst_mem_inst.mem[1]  = encode_i(12'h0aa, 5'd0, 3'b000, 5'd2,  OPC_OP_IMM);
            dut.inst_mem_inst.mem[2]  = encode_i(12'h00f, 5'd0, 3'b000, 5'd3,  OPC_OP_IMM);
            dut.inst_mem_inst.mem[3]  = encode_i(12'h033, 5'd0, 3'b000, 5'd4,  OPC_OP_IMM);

            dut.inst_mem_inst.mem[4]  = encode_csr(CSR_MSCRATCH, 5'd1,  3'b001, 5'd10);
            dut.inst_mem_inst.mem[5]  = encode_r(7'b0000000, 5'd1,  5'd10, 3'b000, 5'd11, OPC_OP);
            dut.inst_mem_inst.mem[6]  = encode_csr(CSR_MSCRATCH, 5'd2,  3'b001, 5'd12);
            dut.inst_mem_inst.mem[7]  = encode_r(7'b0000000, 5'd1,  5'd12, 3'b000, 5'd13, OPC_OP);
            dut.inst_mem_inst.mem[8]  = encode_csr(CSR_MSCRATCH, 5'd3,  3'b010, 5'd14);
            dut.inst_mem_inst.mem[9]  = encode_r(7'b0000000, 5'd0,  5'd14, 3'b000, 5'd15, OPC_OP);
            dut.inst_mem_inst.mem[10] = encode_csr(CSR_MSCRATCH, 5'd4,  3'b011, 5'd16);
            dut.inst_mem_inst.mem[11] = encode_i(1,       5'd16, 3'b000, 5'd17, OPC_OP_IMM);

            dut.inst_mem_inst.mem[12] = encode_csr(CSR_MTVEC,    5'd26, 3'b101, 5'd18);
            dut.inst_mem_inst.mem[13] = encode_i(1,       5'd18, 3'b000, 5'd22, OPC_OP_IMM);
            dut.inst_mem_inst.mem[14] = encode_csr(CSR_MTVEC,    5'd7,  3'b101, 5'd19);
            dut.inst_mem_inst.mem[15] = encode_r(7'b0000000, 5'd0,  5'd19, 3'b000, 5'd23, OPC_OP);
            dut.inst_mem_inst.mem[16] = encode_csr(CSR_MTVEC,    5'd3,  3'b110, 5'd20);
            dut.inst_mem_inst.mem[17] = encode_i(-1,      5'd20, 3'b000, 5'd24, OPC_OP_IMM);
            dut.inst_mem_inst.mem[18] = encode_csr(CSR_MTVEC,    5'd1,  3'b111, 5'd21);
            dut.inst_mem_inst.mem[19] = encode_r(7'b0000000, 5'd1,  5'd21, 3'b000, 5'd25, OPC_OP);

            dut.inst_mem_inst.mem[20] = encode_csr(CSR_MEPC,     5'd2,  3'b001, 5'd0);
            dut.inst_mem_inst.mem[21] = encode_csr(CSR_MEPC,     5'd0,  3'b010, 5'd26);
            dut.inst_mem_inst.mem[22] = encode_r(7'b0000000, 5'd3,  5'd26, 3'b000, 5'd27, OPC_OP);

            apply_reset();
            run_cycles(30);

            expect_reg(0,  32'h00000000, "x0 hardwired after csr");
            expect_reg(10, 32'h00000000, "csrrw mscratch rd");
            expect_reg(11, 32'h00000055, "use csrrw rd in add");
            expect_reg(12, 32'h00000055, "csrrw mscratch old");
            expect_reg(13, 32'h000000aa, "use old mscratch rd");
            expect_reg(14, 32'h000000aa, "csrrs mscratch old");
            expect_reg(15, 32'h000000aa, "forward csrrs rd");
            expect_reg(16, 32'h000000af, "csrrc mscratch old");
            expect_reg(17, 32'h000000b0, "use csrrc rd in addi");

            expect_reg(18, 32'h00000000, "csrrwi mtvec old");
            expect_reg(22, 32'h00000001, "use csrrwi rd in addi");
            expect_reg(19, 32'h0000001a, "second csrrwi mtvec old");
            expect_reg(23, 32'h0000001a, "forward csrrwi old");
            expect_reg(20, 32'h00000007, "csrrsi mtvec old");
            expect_reg(24, 32'h00000006, "use csrrsi rd in addi");
            expect_reg(21, 32'h00000007, "csrrci mtvec old");
            expect_reg(25, 32'h0000005c, "use csrrci rd in add");

            expect_reg(26, 32'h000000aa, "csrrs mepc old");
            expect_reg(27, 32'h000000b9, "use mepc rd in add");

            expect_csr(dut.csr_inst.csr_mscratch, 32'h0000008c, "mscratch final");
            expect_csr(dut.csr_inst.csr_mtvec,    32'h00000006, "mtvec final");
            expect_csr(dut.csr_inst.csr_mepc,     32'h000000aa, "mepc final");
        end
    endtask

    task automatic test_ecall_trap_pc;
        begin
            $display("\n==== TEST: ECALL TRAP core_pc ====");
            clear_state();

            // x1 = 0x40, then mtvec <- x1
            dut.inst_mem_inst.mem[0]  = encode_i(64, 5'd0, 3'b000, 5'd1, OPC_OP_IMM);
            dut.inst_mem_inst.mem[1]  = encode_csr(CSR_MTVEC, 5'd1, 3'b001, 5'd0);

            // normal instruction before ecall
            dut.inst_mem_inst.mem[2]  = encode_i(16'h022, 5'd0, 3'b000, 5'd2, OPC_OP_IMM);

            // ecall at core_pc = 0x0000000c
            dut.inst_mem_inst.mem[3]  = INST_ECALL;

            // this instruction should be skipped if trap jump works
            dut.inst_mem_inst.mem[4]  = encode_i(16'h033, 5'd0, 3'b000, 5'd3, OPC_OP_IMM);

            // trap handler at mtvec = 0x40 (instruction index 16)
            dut.inst_mem_inst.mem[16] = encode_i(16'h044, 5'd0, 3'b000, 5'd4, OPC_OP_IMM);
            dut.inst_mem_inst.mem[17] = encode_i(16'h055, 5'd0, 3'b000, 5'd5, OPC_OP_IMM);

            apply_reset();

            // Execute up to and including ECALL; core_pc should jump to mtvec immediately after ECALL.
            run_cycles(4);
            expect_csr(dut.csr_inst.csr_mtvec, 32'h00000040, "mtvec setup");
            expect_pc(32'h00000040, "core_pc jump to trap");

            // Sanity check: instruction before ecall executed; instruction after ecall not executed.
            expect_reg(2, 32'h00000022, "before ecall");
            expect_reg(3, 32'h00000000, "after ecall skipped");

            // Execute trap handler instructions.
            run_cycles(2);
            expect_reg(4, 32'h00000044, "trap handler step0");
            expect_reg(5, 32'h00000055, "trap handler step1");
        end
    endtask

    task automatic test_mret_return_pc;
        begin
            $display("\n==== TEST: MRET RETURN core_pc ====");
            clear_state();

            // x1 = 0x40, then mtvec <- x1
            dut.inst_mem_inst.mem[0]  = encode_i(64, 5'd0, 3'b000, 5'd1, OPC_OP_IMM);
            dut.inst_mem_inst.mem[1]  = encode_csr(CSR_MTVEC, 5'd1, 3'b001, 5'd0);

            // x2 = 0x24, then mepc <- x2
            dut.inst_mem_inst.mem[2]  = encode_i(36, 5'd0, 3'b000, 5'd2, OPC_OP_IMM);
            dut.inst_mem_inst.mem[3]  = encode_csr(CSR_MEPC, 5'd2, 3'b001, 5'd0);

            // mret should jump to mepc (0x24)
            dut.inst_mem_inst.mem[4]  = INST_MRET;

            // should be skipped if mret return works
            dut.inst_mem_inst.mem[5]  = encode_i(16'h033, 5'd0, 3'b000, 5'd3, OPC_OP_IMM);

            // expected mret target @ core_pc=0x24 (index 9)
            dut.inst_mem_inst.mem[9]  = encode_i(16'h044, 5'd0, 3'b000, 5'd4, OPC_OP_IMM);

            // trap vector target @ core_pc=0x40 (index 16)
            dut.inst_mem_inst.mem[16] = encode_i(16'h055, 5'd0, 3'b000, 5'd5, OPC_OP_IMM);

            apply_reset();

            // Execute up to and including MRET.
            run_cycles(5);
            expect_csr(dut.csr_inst.csr_mepc, 32'h00000024, "mepc setup");
            expect_pc(32'h00000024, "core_pc jump by mret");

            // Execute one instruction at the return target.
            run_cycles(1);
            expect_reg(4, 32'h00000044, "mret target executed");
            expect_reg(5, 32'h00000000, "mtvec path not taken");
            expect_reg(3, 32'h00000000, "post-mret sequential skipped");
        end
    endtask

    initial begin
        clk = 1'b0;
        rst_n = 1'b0;
        fail_count = 0;
        pass_count = 0;

        test_ecall_trap_pc();
        test_mret_return_pc();

        $display("\n==== SUMMARY ====");
        $display("PASS COUNT = %0d", pass_count);
        $display("FAIL COUNT = %0d", fail_count);

        if (fail_count != 0) begin
            $fatal(1, "RV32I self-check failed");
        end else begin
            $display("All RV32I checks passed.");
        end

        $finish;
    end

    always #5 clk = ~clk;

endmodule
