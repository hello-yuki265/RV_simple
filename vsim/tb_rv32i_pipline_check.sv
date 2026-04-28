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
    // Continuous pipeline program
    // --------------------------
    task automatic test_pipeline_sequential;
        int pc;
        begin
            $display("\n==== TEST: CONTINUOUS PIPELINE PROGRAM ====");
            clear_state();
            pc = 0;

            // Integer ALU/branch operands are intentionally chained to exercise forwarding.
            dut.inst_mem_inst.mem[pc]=encode_i(5,5'd0,3'b000,5'd1,OPC_OP_IMM); pc++;
            dut.inst_mem_inst.mem[pc]=encode_i(1,5'd1,3'b001,5'd2,OPC_OP_IMM); pc++;
            dut.inst_mem_inst.mem[pc]=encode_i(1,5'd2,3'b101,5'd3,OPC_OP_IMM); pc++;
            dut.inst_mem_inst.mem[pc]=encode_i(-16,5'd0,3'b000,5'd4,OPC_OP_IMM); pc++;
            dut.inst_mem_inst.mem[pc]=encode_i(12'h401,5'd4,3'b101,5'd4,OPC_OP_IMM); pc++;
            dut.inst_mem_inst.mem[pc]=encode_i(8,5'd1,3'b110,5'd5,OPC_OP_IMM); pc++;
            dut.inst_mem_inst.mem[pc]=encode_i(8,5'd5,3'b111,5'd6,OPC_OP_IMM); pc++;
            dut.inst_mem_inst.mem[pc]=encode_i(3,5'd5,3'b100,5'd7,OPC_OP_IMM); pc++;
            dut.inst_mem_inst.mem[pc]=encode_i(0,5'd4,3'b010,5'd8,OPC_OP_IMM); pc++;
            dut.inst_mem_inst.mem[pc]=encode_i(8,5'd4,3'b011,5'd9,OPC_OP_IMM); pc++;
            dut.inst_mem_inst.mem[pc]=encode_r(7'b0000000,5'd6,5'd5,3'b000,5'd10,OPC_OP); pc++;
            dut.inst_mem_inst.mem[pc]=encode_r(7'b0100000,5'd1,5'd10,3'b000,5'd11,OPC_OP); pc++;
            dut.inst_mem_inst.mem[pc]=encode_r(7'b0000000,5'd1,5'd1,3'b001,5'd12,OPC_OP); pc++;
            dut.inst_mem_inst.mem[pc]=encode_r(7'b0000000,5'd1,5'd4,3'b010,5'd13,OPC_OP); pc++;
            dut.inst_mem_inst.mem[pc]=encode_r(7'b0000000,5'd1,5'd4,3'b011,5'd14,OPC_OP); pc++;
            dut.inst_mem_inst.mem[pc]=encode_r(7'b0000000,5'd6,5'd5,3'b100,5'd15,OPC_OP); pc++;
            dut.inst_mem_inst.mem[pc]=encode_r(7'b0000000,5'd1,5'd12,3'b101,5'd16,OPC_OP); pc++;
            dut.inst_mem_inst.mem[pc]=encode_r(7'b0100000,5'd1,5'd4,3'b101,5'd17,OPC_OP); pc++;
            dut.inst_mem_inst.mem[pc]=encode_r(7'b0000000,5'd6,5'd5,3'b110,5'd18,OPC_OP); pc++;
            dut.inst_mem_inst.mem[pc]=encode_r(7'b0000000,5'd6,5'd5,3'b111,5'd19,OPC_OP); pc++;
            dut.inst_mem_inst.mem[pc]=encode_u(20'h12345,5'd20,OPC_LUI); pc++;
            dut.inst_mem_inst.mem[pc]=encode_u(20'h00001,5'd21,OPC_AUIPC); pc++;

            // Load/store and store-data hazards.
            dut.inst_mem_inst.mem[pc]=encode_i(128,5'd0,3'b000,5'd22,OPC_OP_IMM); pc++;
            dut.inst_mem_inst.mem[pc]=encode_i(127,5'd0,3'b000,5'd23,OPC_OP_IMM); pc++;
            dut.inst_mem_inst.mem[pc]=encode_s(0,5'd23,5'd22,3'b000,OPC_STORE); pc++;
            dut.inst_mem_inst.mem[pc]=encode_i(2033,5'd0,3'b000,5'd24,OPC_OP_IMM); pc++;
            dut.inst_mem_inst.mem[pc]=encode_s(2,5'd24,5'd22,3'b001,OPC_STORE); pc++;
            dut.inst_mem_inst.mem[pc]=encode_u(20'h12345,5'd25,OPC_LUI); pc++;
            dut.inst_mem_inst.mem[pc]=encode_i(12'h678,5'd25,3'b000,5'd25,OPC_OP_IMM); pc++;
            dut.inst_mem_inst.mem[pc]=encode_s(4,5'd25,5'd22,3'b010,OPC_STORE); pc++;
            dut.inst_mem_inst.mem[pc]=encode_i(0,5'd22,3'b000,5'd26,OPC_LOAD); pc++;
            dut.inst_mem_inst.mem[pc]=encode_i(0,5'd22,3'b100,5'd27,OPC_LOAD); pc++;
            dut.inst_mem_inst.mem[pc]=encode_i(2,5'd22,3'b001,5'd28,OPC_LOAD); pc++;
            dut.inst_mem_inst.mem[pc]=encode_i(2,5'd22,3'b101,5'd29,OPC_LOAD); pc++;
            dut.inst_mem_inst.mem[pc]=encode_i(4,5'd22,3'b010,5'd30,OPC_LOAD); pc++;
            dut.inst_mem_inst.mem[pc]=encode_r(7'b0000000,5'd1,5'd30,3'b000,5'd31,OPC_OP); pc++;
            dut.inst_mem_inst.mem[pc]=encode_i(4,5'd22,3'b010,5'd5,OPC_LOAD); pc++;
            dut.inst_mem_inst.mem[pc]=encode_s(8,5'd5,5'd22,3'b010,OPC_STORE); pc++;
            dut.inst_mem_inst.mem[pc]=encode_i(12,5'd22,3'b010,5'd6,OPC_LOAD); pc++;
            dut.inst_mem_inst.mem[pc]=encode_s(0,5'd1,5'd6,3'b010,OPC_STORE); pc++;

            // Control-flow hazards with useful skipped instructions in the stream.
            dut.inst_mem_inst.mem[pc]=encode_i(9,5'd0,3'b000,5'd2,OPC_OP_IMM); pc++;
            dut.inst_mem_inst.mem[pc]=encode_b(8,5'd2,5'd2,3'b000,OPC_BRANCH); pc++;
            dut.inst_mem_inst.mem[pc]=encode_i(1,5'd0,3'b000,5'd3,OPC_OP_IMM); pc++;
            dut.inst_mem_inst.mem[pc]=encode_i(2,5'd0,3'b000,5'd3,OPC_OP_IMM); pc++;
            dut.inst_mem_inst.mem[pc]=encode_i(-1,5'd0,3'b000,5'd4,OPC_OP_IMM); pc++;
            dut.inst_mem_inst.mem[pc]=encode_b(8,5'd3,5'd4,3'b100,OPC_BRANCH); pc++;
            dut.inst_mem_inst.mem[pc]=encode_i(1,5'd0,3'b000,5'd7,OPC_OP_IMM); pc++;
            dut.inst_mem_inst.mem[pc]=encode_i(2,5'd0,3'b000,5'd7,OPC_OP_IMM); pc++;
            dut.inst_mem_inst.mem[pc]=encode_j(8,5'd8,OPC_JAL); pc++;
            dut.inst_mem_inst.mem[pc]=encode_i(1,5'd0,3'b000,5'd9,OPC_OP_IMM); pc++;
            dut.inst_mem_inst.mem[pc]=encode_i(2,5'd0,3'b000,5'd9,OPC_OP_IMM); pc++;
            dut.inst_mem_inst.mem[pc]=encode_i(220,5'd0,3'b000,5'd10,OPC_OP_IMM); pc++;
            dut.inst_mem_inst.mem[pc]=encode_i(0,5'd10,3'b000,5'd11,OPC_JALR); pc++;
            dut.inst_mem_inst.mem[pc]=encode_i(1,5'd0,3'b000,5'd12,OPC_OP_IMM); pc++;
            dut.inst_mem_inst.mem[pc]=encode_i(2,5'd0,3'b000,5'd12,OPC_OP_IMM); pc++;
            dut.inst_mem_inst.mem[pc]=encode_i(3,5'd0,3'b000,5'd12,OPC_OP_IMM); pc++;

            // CSR and trap/return redirects in the same packed program.
            dut.inst_mem_inst.mem[pc]=encode_i(15,5'd0,3'b000,5'd13,OPC_OP_IMM); pc++;
            dut.inst_mem_inst.mem[pc]=encode_csr(CSR_MSCRATCH,5'd13,3'b001,5'd14); pc++;
            dut.inst_mem_inst.mem[pc]=encode_csr(CSR_MSCRATCH,5'd1,3'b010,5'd15); pc++;
            dut.inst_mem_inst.mem[pc]=encode_i(1,5'd15,3'b000,5'd16,OPC_OP_IMM); pc++;
            dut.inst_mem_inst.mem[pc]=encode_csr(CSR_MSCRATCH,5'd1,3'b011,5'd17); pc++;
            dut.inst_mem_inst.mem[pc]=encode_csr(CSR_MEPC,5'd26,3'b101,5'd18); pc++;
            dut.inst_mem_inst.mem[pc]=encode_csr(CSR_MCAUSE,5'd3,3'b110,5'd19); pc++;
            dut.inst_mem_inst.mem[pc]=encode_csr(CSR_MCAUSE,5'd1,3'b111,5'd20); pc++;
            dut.inst_mem_inst.mem[pc]=encode_i(288,5'd0,3'b000,5'd21,OPC_OP_IMM); pc++;
            dut.inst_mem_inst.mem[pc]=encode_csr(CSR_MTVEC,5'd21,3'b001,5'd0); pc++;
            dut.inst_mem_inst.mem[pc]=INST_ECALL; pc++;
            dut.inst_mem_inst.mem[pc]=encode_i(1,5'd0,3'b000,5'd22,OPC_OP_IMM); pc++;
            dut.inst_mem_inst.mem[pc]=encode_i(2,5'd0,3'b000,5'd22,OPC_OP_IMM); pc++;
            dut.inst_mem_inst.mem[pc]=encode_i(3,5'd0,3'b000,5'd22,OPC_OP_IMM); pc++;
            dut.inst_mem_inst.mem[pc]=encode_i(4,5'd0,3'b000,5'd22,OPC_OP_IMM); pc++;
            dut.inst_mem_inst.mem[pc]=encode_i(5,5'd0,3'b000,5'd22,OPC_OP_IMM); pc++;
            dut.inst_mem_inst.mem[pc]=encode_i(316,5'd0,3'b000,5'd23,OPC_OP_IMM); pc++;
            dut.inst_mem_inst.mem[pc]=encode_i(1,5'd25,3'b000,5'd25,OPC_OP_IMM); pc++;
            dut.inst_mem_inst.mem[pc]=encode_csr(CSR_MEPC,5'd23,3'b001,5'd0); pc++;
            dut.inst_mem_inst.mem[pc]=INST_MRET; pc++;
            dut.inst_mem_inst.mem[pc]=encode_i(1,5'd0,3'b000,5'd24,OPC_OP_IMM); pc++;
            dut.inst_mem_inst.mem[pc]=encode_i(2,5'd0,3'b000,5'd24,OPC_OP_IMM); pc++;
            dut.inst_mem_inst.mem[pc]=encode_i(6,5'd0,3'b000,5'd24,OPC_OP_IMM); pc++;
            dut.inst_mem_inst.mem[pc]=encode_i(3,5'd0,3'b000,5'd24,OPC_OP_IMM); pc++;

            dut.data_mem_inst.mem[140] = 8'd144;

            apply_reset();
            run_cycles(220);

            expect_reg(1, 32'h00000005, "seq addi");
            expect_reg(2, 32'h00000009, "seq branch src");
            expect_reg(3, 32'h00000002, "seq beq target");
            expect_reg(4, 32'hffffffff, "seq blt src");
            expect_reg(5, 32'h12345678, "seq load copy src");
            expect_reg(6, 32'h00000090, "seq load store addr");
            expect_reg(7, 32'h00000002, "seq blt target");
            expect_reg(8, 32'h000000c4, "seq jal link");
            expect_reg(9, 32'h00000002, "seq jal target");
            expect_reg(10, 32'h000000dc, "seq jalr base");
            expect_reg(11, 32'h000000d4, "seq jalr link");
            expect_reg(12, 32'h00000003, "seq jalr target");
            expect_reg(13, 32'h0000000f, "seq csr src");
            expect_reg(14, 32'h00000000, "seq csrrw old");
            expect_reg(15, 32'h0000000f, "seq csrrs old");
            expect_reg(16, 32'h00000010, "seq csr forward");
            expect_reg(17, 32'h0000000f, "seq csrrc old");
            expect_reg(18, 32'h00000000, "seq csrrwi old");
            expect_reg(19, 32'h00000000, "seq csrrsi old");
            expect_reg(20, 32'h00000003, "seq csrrci old");
            expect_reg(21, 32'h00000120, "seq mtvec src");
            expect_reg(22, 32'h00000080, "seq ecall flushed");
            expect_reg(23, 32'h0000013c, "seq mepc src");
            expect_reg(24, 32'h00000003, "seq mret target");
            expect_reg(25, 32'h12345679, "seq pre-mret exec");
            expect_reg(26, 32'h0000007f, "seq lb");
            expect_reg(27, 32'h0000007f, "seq lbu");
            expect_reg(28, 32'h000007f1, "seq lh");
            expect_reg(29, 32'h000007f1, "seq lhu");
            expect_reg(30, 32'h12345678, "seq lw");
            expect_reg(31, 32'h1234567d, "seq load-use add");

            expect_mem_byte(128, 8'h7f, "seq sb");
            expect_mem_byte(130, 8'hf1, "seq sh low");
            expect_mem_byte(131, 8'h07, "seq sh high");
            expect_mem_byte(132, 8'h78, "seq sw b0");
            expect_mem_byte(135, 8'h12, "seq sw b3");
            expect_mem_byte(136, 8'h78, "seq load-store b0");
            expect_mem_byte(139, 8'h12, "seq load-store b3");
            expect_mem_byte(144, 8'h05, "seq load-store addr");

            expect_csr(dut.csr_inst.csr_mscratch, 32'h0000000a, "seq mscratch final");
            expect_csr(dut.csr_inst.csr_mtvec, 32'h00000120, "seq mtvec final");
            expect_csr(dut.csr_inst.csr_mepc, 32'h0000013c, "seq mepc final");
        end
    endtask

    initial begin
        clk = 1'b0;
        rst_n = 1'b0;
        fail_count = 0;
        pass_count = 0;

        test_pipeline_sequential();

        $display("\n==== SUMMARY ====");
        $display("PASS COUNT = %0d", pass_count);
        $display("FAIL COUNT = %0d", fail_count);

        if (fail_count != 0) begin
            $fatal(1, "Sequential RV32I pipeline check failed");
        end else begin
            $display("Sequential RV32I pipeline check passed.");
        end

        $finish;
    end

    always #5 clk = ~clk;

endmodule
