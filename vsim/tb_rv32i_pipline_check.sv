module tb_rv32i_pipline_check;

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
    localparam [6:0] OPC_AUIPC  = 7'b0010111;
    localparam [6:0] OPC_STORE  = 7'b0100011;
    localparam [6:0] OPC_OP     = 7'b0110011;
    localparam [6:0] OPC_LUI    = 7'b0110111;
    localparam [6:0] OPC_BRANCH = 7'b1100011;
    localparam [6:0] OPC_JALR   = 7'b1100111;
    localparam [6:0] OPC_JAL    = 7'b1101111;
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
            dut.if_pc = 32'b0;
            for (idx = 0; idx < 512; idx = idx + 1) begin
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

    task automatic expect_reg(input int idx, input logic [31:0] expected, input string label);
        logic [31:0] actual;
        begin
            actual = dut.regfile_inst.register[idx];
            if (actual !== expected) begin
                $display("FAIL %-28s x%0d expected=0x%08h actual=0x%08h", label, idx, expected, actual);
                fail_count = fail_count + 1;
            end else begin
                $display("PASS %-28s x%0d = 0x%08h", label, idx, actual);
                pass_count = pass_count + 1;
            end
        end
    endtask

    task automatic expect_mem_byte(input int addr, input logic [7:0] expected, input string label);
        logic [7:0] actual;
        begin
            actual = dut.data_mem_inst.mem[addr];
            if (actual !== expected) begin
                $display("FAIL %-28s mem[%0d] expected=0x%02h actual=0x%02h", label, addr, expected, actual);
                fail_count = fail_count + 1;
            end else begin
                $display("PASS %-28s mem[%0d] = 0x%02h", label, addr, actual);
                pass_count = pass_count + 1;
            end
        end
    endtask

    task automatic expect_csr(input logic [31:0] actual, input logic [31:0] expected, input string label);
        begin
            if (actual !== expected) begin
                $display("FAIL %-28s expected=0x%08h actual=0x%08h", label, expected, actual);
                fail_count = fail_count + 1;
            end else begin
                $display("PASS %-28s = 0x%08h", label, actual);
                pass_count = pass_count + 1;
            end
        end
    endtask

    // --------------------------
    // Non-privileged isolated tests (hazard-free)
    // --------------------------
    task automatic test_nonpriv_isolated;
        begin
            $display("\n==== TEST: NON-PRIVILEGED isolated ====");

            // OP-IMM
            clear_state(); dut.inst_mem_inst.mem[64]=encode_i(5,5'd0,3'b000,5'd1,OPC_OP_IMM); apply_reset(); run_cycles(90); expect_reg(1,32'h00000005,"addi");
            clear_state(); dut.inst_mem_inst.mem[64]=encode_i(1,5'd1,3'b001,5'd2,OPC_OP_IMM); apply_reset(); dut.regfile_inst.register[1]=32'h00000005; run_cycles(90); expect_reg(2,32'h0000000a,"slli");
            clear_state(); dut.inst_mem_inst.mem[64]=encode_i(2,5'd1,3'b101,5'd3,OPC_OP_IMM); apply_reset(); dut.regfile_inst.register[1]=32'h00000014; run_cycles(90); expect_reg(3,32'h00000005,"srli");
            clear_state(); dut.inst_mem_inst.mem[64]=encode_i(12'h401,5'd1,3'b101,5'd4,OPC_OP_IMM); apply_reset(); dut.regfile_inst.register[1]=32'hfffffff0; run_cycles(90); expect_reg(4,32'hfffffff8,"srai");
            clear_state(); dut.inst_mem_inst.mem[64]=encode_i(8,5'd1,3'b110,5'd5,OPC_OP_IMM); apply_reset(); dut.regfile_inst.register[1]=32'h00000005; run_cycles(90); expect_reg(5,32'h0000000d,"ori");
            clear_state(); dut.inst_mem_inst.mem[64]=encode_i(8,5'd1,3'b111,5'd6,OPC_OP_IMM); apply_reset(); dut.regfile_inst.register[1]=32'h0000000c; run_cycles(90); expect_reg(6,32'h00000008,"andi");
            clear_state(); dut.inst_mem_inst.mem[64]=encode_i(3,5'd1,3'b100,5'd7,OPC_OP_IMM); apply_reset(); dut.regfile_inst.register[1]=32'h00000005; run_cycles(90); expect_reg(7,32'h00000006,"xori");
            clear_state(); dut.inst_mem_inst.mem[64]=encode_i(0,5'd1,3'b010,5'd8,OPC_OP_IMM); apply_reset(); dut.regfile_inst.register[1]=32'hfffffff8; run_cycles(90); expect_reg(8,32'h00000001,"slti");
            clear_state(); dut.inst_mem_inst.mem[64]=encode_i(8,5'd1,3'b011,5'd9,OPC_OP_IMM); apply_reset(); dut.regfile_inst.register[1]=32'hfffffff8; run_cycles(90); expect_reg(9,32'h00000000,"sltiu");

            // OP
            clear_state(); dut.inst_mem_inst.mem[64]=encode_r(7'b0000000,5'd2,5'd1,3'b000,5'd10,OPC_OP); apply_reset(); dut.regfile_inst.register[1]=32'h5; dut.regfile_inst.register[2]=32'hc; run_cycles(90); expect_reg(10,32'h00000011,"add");
            clear_state(); dut.inst_mem_inst.mem[64]=encode_r(7'b0100000,5'd1,5'd2,3'b000,5'd11,OPC_OP); apply_reset(); dut.regfile_inst.register[1]=32'h5; dut.regfile_inst.register[2]=32'hc; run_cycles(90); expect_reg(11,32'h00000007,"sub");
            clear_state(); dut.inst_mem_inst.mem[64]=encode_r(7'b0000000,5'd1,5'd2,3'b001,5'd12,OPC_OP); apply_reset(); dut.regfile_inst.register[1]=32'h2; dut.regfile_inst.register[2]=32'h3; run_cycles(90); expect_reg(12,32'h0000000c,"sll");
            clear_state(); dut.inst_mem_inst.mem[64]=encode_r(7'b0000000,5'd2,5'd1,3'b010,5'd13,OPC_OP); apply_reset(); dut.regfile_inst.register[1]=32'hfffffff8; dut.regfile_inst.register[2]=32'h1; run_cycles(90); expect_reg(13,32'h00000001,"slt");
            clear_state(); dut.inst_mem_inst.mem[64]=encode_r(7'b0000000,5'd2,5'd1,3'b011,5'd14,OPC_OP); apply_reset(); dut.regfile_inst.register[1]=32'hfffffff8; dut.regfile_inst.register[2]=32'h1; run_cycles(90); expect_reg(14,32'h00000000,"sltu");
            clear_state(); dut.inst_mem_inst.mem[64]=encode_r(7'b0000000,5'd2,5'd1,3'b100,5'd15,OPC_OP); apply_reset(); dut.regfile_inst.register[1]=32'h5; dut.regfile_inst.register[2]=32'hc; run_cycles(90); expect_reg(15,32'h00000009,"xor");
            clear_state(); dut.inst_mem_inst.mem[64]=encode_r(7'b0000000,5'd2,5'd1,3'b101,5'd16,OPC_OP); apply_reset(); dut.regfile_inst.register[1]=32'hc; dut.regfile_inst.register[2]=32'h1; run_cycles(90); expect_reg(16,32'h00000006,"srl");
            clear_state(); dut.inst_mem_inst.mem[64]=encode_r(7'b0100000,5'd2,5'd1,3'b101,5'd17,OPC_OP); apply_reset(); dut.regfile_inst.register[1]=32'hfffffff0; dut.regfile_inst.register[2]=32'h1; run_cycles(90); expect_reg(17,32'hfffffff8,"sra");
            clear_state(); dut.inst_mem_inst.mem[64]=encode_r(7'b0000000,5'd2,5'd1,3'b110,5'd18,OPC_OP); apply_reset(); dut.regfile_inst.register[1]=32'h5; dut.regfile_inst.register[2]=32'hc; run_cycles(90); expect_reg(18,32'h0000000d,"or");
            clear_state(); dut.inst_mem_inst.mem[64]=encode_r(7'b0000000,5'd2,5'd1,3'b111,5'd19,OPC_OP); apply_reset(); dut.regfile_inst.register[1]=32'hc; dut.regfile_inst.register[2]=32'ha; run_cycles(90); expect_reg(19,32'h00000008,"and");

            // U-type
            clear_state(); dut.inst_mem_inst.mem[64]=encode_u(20'h12345,5'd20,OPC_LUI); apply_reset(); run_cycles(90); expect_reg(20,32'h12345000,"lui");
            clear_state(); dut.inst_mem_inst.mem[64]=encode_u(20'h00001,5'd21,OPC_AUIPC); apply_reset(); run_cycles(90); expect_reg(21,32'h00001100,"auipc");

            // Load/Store
            clear_state(); dut.inst_mem_inst.mem[64]=encode_s(0,5'd2,5'd1,3'b000,OPC_STORE); apply_reset(); dut.regfile_inst.register[1]=32'd64; dut.regfile_inst.register[2]=32'h000000ff; run_cycles(90); expect_mem_byte(64,8'hff,"sb");
            clear_state(); dut.inst_mem_inst.mem[64]=encode_s(0,5'd2,5'd1,3'b001,OPC_STORE); apply_reset(); dut.regfile_inst.register[1]=32'd64; dut.regfile_inst.register[2]=32'h00008001; run_cycles(90); expect_mem_byte(64,8'h01,"sh low"); expect_mem_byte(65,8'h80,"sh high");
            clear_state(); dut.inst_mem_inst.mem[64]=encode_s(0,5'd2,5'd1,3'b010,OPC_STORE); apply_reset(); dut.regfile_inst.register[1]=32'd64; dut.regfile_inst.register[2]=32'h12345678; run_cycles(90); expect_mem_byte(64,8'h78,"sw b0"); expect_mem_byte(67,8'h12,"sw b3");

            clear_state(); dut.inst_mem_inst.mem[64]=encode_i(0,5'd1,3'b000,5'd22,OPC_LOAD); apply_reset(); dut.regfile_inst.register[1]=32'd64; dut.data_mem_inst.mem[64]=8'hff; run_cycles(90); expect_reg(22,32'hffffffff,"lb");
            clear_state(); dut.inst_mem_inst.mem[64]=encode_i(0,5'd1,3'b100,5'd23,OPC_LOAD); apply_reset(); dut.regfile_inst.register[1]=32'd64; dut.data_mem_inst.mem[64]=8'hff; run_cycles(90); expect_reg(23,32'h000000ff,"lbu");
            clear_state(); dut.inst_mem_inst.mem[64]=encode_i(0,5'd1,3'b001,5'd24,OPC_LOAD); apply_reset(); dut.regfile_inst.register[1]=32'd64; dut.data_mem_inst.mem[64]=8'h01; dut.data_mem_inst.mem[65]=8'h80; run_cycles(90); expect_reg(24,32'hffff8001,"lh");
            clear_state(); dut.inst_mem_inst.mem[64]=encode_i(0,5'd1,3'b101,5'd25,OPC_LOAD); apply_reset(); dut.regfile_inst.register[1]=32'd64; dut.data_mem_inst.mem[64]=8'h01; dut.data_mem_inst.mem[65]=8'h80; run_cycles(90); expect_reg(25,32'h00008001,"lhu");
            clear_state(); dut.inst_mem_inst.mem[64]=encode_i(0,5'd1,3'b010,5'd26,OPC_LOAD); apply_reset(); dut.regfile_inst.register[1]=32'd64; dut.data_mem_inst.mem[64]=8'h78; dut.data_mem_inst.mem[65]=8'h56; dut.data_mem_inst.mem[66]=8'h34; dut.data_mem_inst.mem[67]=8'h12; run_cycles(90); expect_reg(26,32'h12345678,"lw");

            // Branch / Jump (single control instruction with large spacing)
            clear_state();
            dut.inst_mem_inst.mem[64]=encode_b(8,5'd2,5'd1,3'b000,OPC_BRANCH); // beq taken
            dut.inst_mem_inst.mem[65]=encode_i(1,5'd0,3'b000,5'd27,OPC_OP_IMM); // skipped
            dut.inst_mem_inst.mem[66]=encode_i(2,5'd0,3'b000,5'd27,OPC_OP_IMM); // target
            apply_reset(); dut.regfile_inst.register[1]=32'd5; dut.regfile_inst.register[2]=32'd5; run_cycles(110); expect_reg(27,32'h00000002,"beq taken");

            clear_state();
            dut.inst_mem_inst.mem[64]=encode_b(8,5'd2,5'd1,3'b100,OPC_BRANCH); // blt taken
            dut.inst_mem_inst.mem[65]=encode_i(1,5'd0,3'b000,5'd28,OPC_OP_IMM);
            dut.inst_mem_inst.mem[66]=encode_i(2,5'd0,3'b000,5'd28,OPC_OP_IMM);
            apply_reset(); dut.regfile_inst.register[1]=32'hfffffff8; dut.regfile_inst.register[2]=32'd1; run_cycles(110); expect_reg(28,32'h00000002,"blt taken");

            clear_state();
            dut.inst_mem_inst.mem[64]=encode_j(8,5'd29,OPC_JAL);
            dut.inst_mem_inst.mem[65]=encode_i(1,5'd0,3'b000,5'd30,OPC_OP_IMM); // skipped
            dut.inst_mem_inst.mem[66]=encode_i(2,5'd0,3'b000,5'd30,OPC_OP_IMM); // target
            apply_reset(); run_cycles(110); expect_reg(29,32'h00000104,"jal link"); expect_reg(30,32'h00000002,"jal target");

            clear_state();
            dut.inst_mem_inst.mem[64]=encode_i(0,5'd21,3'b000,5'd31,OPC_JALR);
            dut.inst_mem_inst.mem[65]=encode_i(1,5'd0,3'b000,5'd3,OPC_OP_IMM); // skipped
            dut.inst_mem_inst.mem[68]=encode_i(2,5'd0,3'b000,5'd3,OPC_OP_IMM); // target @ 272
            apply_reset(); dut.regfile_inst.register[21]=32'd272; run_cycles(120); expect_reg(31,32'h00000104,"jalr link"); expect_reg(3,32'h00000002,"jalr target");
        end
    endtask

    // --------------------------
    // Isolated CSR single-instruction tests
    // --------------------------
    task automatic test_csrrw_isolated;
        begin
            $display("\n==== TEST: CSRRW isolated ====");
            clear_state();
            dut.inst_mem_inst.mem[64] = encode_csr(CSR_MTVEC, 5'd1, 3'b001, 5'd10);
            apply_reset();
            dut.regfile_inst.register[1] = 32'h12345067;
            run_cycles(90);
            expect_reg(10, 32'h00000000, "csrrw rd old");
            expect_csr(dut.csr_inst.csr_mtvec, 32'h12345067, "csrrw mtvec new");
        end
    endtask

    task automatic test_csrrs_isolated;
        begin
            $display("\n==== TEST: CSRRS isolated ====");
            clear_state();
            dut.inst_mem_inst.mem[64] = encode_csr(CSR_MSCRATCH, 5'd2, 3'b010, 5'd11);
            apply_reset();
            dut.regfile_inst.register[2] = 32'h0000000f;
            run_cycles(90);
            expect_reg(11, 32'h00000000, "csrrs rd old");
            expect_csr(dut.csr_inst.csr_mscratch, 32'h0000000f, "csrrs mscratch new");
        end
    endtask

    task automatic test_csrrc_isolated;
        begin
            $display("\n==== TEST: CSRRC isolated ====");
            clear_state();
            dut.inst_mem_inst.mem[64] = encode_csr(CSR_MSCRATCH, 5'd3, 3'b011, 5'd12);
            apply_reset();
            dut.regfile_inst.register[3] = 32'h0000000f;
            run_cycles(90);
            expect_reg(12, 32'h00000000, "csrrc rd old");
            expect_csr(dut.csr_inst.csr_mscratch, 32'h00000000, "csrrc mscratch new");
        end
    endtask

    task automatic test_csrrwi_isolated;
        begin
            $display("\n==== TEST: CSRRWI isolated ====");
            clear_state();
            dut.inst_mem_inst.mem[64] = encode_csr(CSR_MEPC, 5'd26, 3'b101, 5'd13);
            apply_reset();
            run_cycles(90);
            expect_reg(13, 32'h00000000, "csrrwi rd old");
            expect_csr(dut.csr_inst.csr_mepc, 32'h0000001a, "csrrwi mepc new");
        end
    endtask

    task automatic test_csrrsi_isolated;
        begin
            $display("\n==== TEST: CSRRSI isolated ====");
            clear_state();
            dut.inst_mem_inst.mem[64] = encode_csr(CSR_MCAUSE, 5'd3, 3'b110, 5'd14);
            apply_reset();
            run_cycles(90);
            expect_reg(14, 32'h00000000, "csrrsi rd old");
            expect_csr(dut.csr_inst.csr_mcause, 32'h00000003, "csrrsi mcause new");
        end
    endtask

    task automatic test_csrrci_isolated;
        begin
            $display("\n==== TEST: CSRRCI isolated ====");
            clear_state();
            dut.inst_mem_inst.mem[64] = encode_csr(CSR_MCAUSE, 5'd1, 3'b111, 5'd15);
            apply_reset();
            run_cycles(90);
            expect_reg(15, 32'h00000000, "csrrci rd old");
            expect_csr(dut.csr_inst.csr_mcause, 32'h00000000, "csrrci mcause new");
        end
    endtask

    task automatic test_ecall_isolated;
        begin
            $display("\n==== TEST: ECALL isolated ====");
            clear_state();
            dut.inst_mem_inst.mem[16]  = encode_i(800, 5'd0, 3'b000, 5'd1, OPC_OP_IMM);
            dut.inst_mem_inst.mem[64]  = encode_csr(CSR_MTVEC, 5'd1, 3'b001, 5'd0);
            dut.inst_mem_inst.mem[128] = INST_ECALL;
            dut.inst_mem_inst.mem[180] = encode_i(16'h0aa, 5'd0, 3'b000, 5'd24, OPC_OP_IMM);
            dut.inst_mem_inst.mem[200] = encode_i(16'h044, 5'd0, 3'b000, 5'd25, OPC_OP_IMM);
            apply_reset();
            run_cycles(320);
            expect_reg(24, 32'h00000000, "ecall sequential skipped");
            expect_reg(25, 32'h00000044, "ecall trap target run");
        end
    endtask

    task automatic test_mret_isolated;
        begin
            $display("\n==== TEST: MRET isolated ====");
            clear_state();
            dut.inst_mem_inst.mem[16]  = encode_i(960, 5'd0, 3'b000, 5'd2, OPC_OP_IMM);
            dut.inst_mem_inst.mem[64]  = encode_csr(CSR_MEPC, 5'd2, 3'b001, 5'd0);
            dut.inst_mem_inst.mem[128] = INST_MRET;
            dut.inst_mem_inst.mem[180] = encode_i(16'h0bb, 5'd0, 3'b000, 5'd27, OPC_OP_IMM);
            dut.inst_mem_inst.mem[240] = encode_i(16'h055, 5'd0, 3'b000, 5'd28, OPC_OP_IMM);
            apply_reset();
            run_cycles(360);
            expect_reg(27, 32'h00000000, "mret sequential skipped");
            expect_reg(28, 32'h00000055, "mret return target run");
        end
    endtask

    initial begin
        clk = 1'b0;
        rst_n = 1'b0;
        fail_count = 0;
        pass_count = 0;

        test_nonpriv_isolated();

        test_csrrw_isolated();
        test_csrrs_isolated();
        test_csrrc_isolated();
        test_csrrwi_isolated();
        test_csrrsi_isolated();
        test_csrrci_isolated();
        test_ecall_isolated();
        test_mret_isolated();

        $display("\n==== SUMMARY ====");
        $display("PASS COUNT = %0d", pass_count);
        $display("FAIL COUNT = %0d", fail_count);

        if (fail_count != 0) begin
            $fatal(1, "Isolated RV32I/CSR/Trap check failed");
        end else begin
            $display("All isolated RV32I/CSR/Trap checks passed.");
        end

        $finish;
    end

    always #5 clk = ~clk;

endmodule
