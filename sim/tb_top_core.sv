
module tb_top_core();

    logic clk;
    logic rst_n;
    logic [31:0] instr_wr;
    logic wr_en;
    logic [9:0] waddr;
    logic [31:0] prog_mem [0:127];
    integer i;

    soc_top soc_top_inst (
    .clk(clk),
    .rst_n(rst_n),
    .instr_wr(instr_wr),
    .wr_en(wr_en),
    .waddr(waddr)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        instr_wr = 32'b0;
        wr_en = 1'b0;
        waddr = 10'b0;

        // Read machine code in TB and load it into the instruction RAM in soc_top.
        $readmemh("test.hex", prog_mem);
        for (i = 0; i < 19; i = i + 1) begin
            if (prog_mem[i] !== 32'hxxxxxxxx) begin
                @(negedge clk);
                wr_en = 1'b1;
                waddr = i;
                instr_wr = prog_mem[i];
                @(negedge clk);
                wr_en = 1'b0;
                $display("%0t | load instr[%0d] = 0x%08h", $time, i, prog_mem[i]);
            end
        end

        #100
        rst_n = 1;
        $monitor("%0t|current pc = %0d", $time, soc_top_inst.pc);

        #1000
        $stop();
    end

    always #5 clk = !clk;
    
    
endmodule
