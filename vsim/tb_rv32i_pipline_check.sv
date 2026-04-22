module tb_rv32i_pipline_check;

    logic clk;
    logic rst_n;
    int fail_count;
    int pass_count;

    top_core dut (
        .clk(clk),
        .rst_n(rst_n)
    );

    localparam [6:0] OPC_OP_IMM = 7'b0010011;
    localparam [6:0] OPC_SYSTEM = 7'b1110011;

    localparam [11:0] CSR_MSCRATCH = 12'h340;
    localparam [11:0] CSR_MEPC     = 12'h341;
    localparam [11:0] CSR_MCAUSE   = 12'h342;
    localparam [11:0] CSR_MTVEC    = 12'h305;

    localparam [31:0] NOP = 32'h00000013;
    localparam [31:0] INST_ECALL = 32'h00000073;
    localparam [31:0] INST_MRET  = 32'h30200073;

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

    task automatic expect_reg(
        input int idx,
        input logic [31:0] expected,
        input string label
    );
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

    task automatic expect_csr(
        input logic [31:0] actual,
        input logic [31:0] expected,
        input string label
    );
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

    // --------------------------
    // ecall / mret with huge spacing
    // --------------------------
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
            $fatal(1, "Isolated CSR/Trap check failed");
        end else begin
            $display("All isolated CSR/Trap checks passed.");
        end

        $finish;
    end

    always #5 clk = ~clk;

endmodule
