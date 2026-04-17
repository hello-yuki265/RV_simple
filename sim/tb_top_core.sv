
module tb_top_core();

    logic clk;
    logic rst_n;
    logic [31:0] prog_mem [0:127];
    integer i;

    top_core  top_core_inst (
    .clk(clk),
    .rst_n(rst_n)
    );

    initial begin
        clk = 0;
        rst_n = 0;

        // Read machine code in TB and load it into DUT inst_mem one by one.
        $readmemh("test.hex", prog_mem);
        for (i = 0; i < 19; i = i + 1) begin
            if (prog_mem[i] !== 32'hxxxxxxxx) begin
                top_core_inst.inst_mem_inst.mem[i] = prog_mem[i];
                $display("%0t | load instr[%0d] = 0x%08h", $time, i, prog_mem[i]);
            end
        end

        #100
        rst_n = 1;
        $monitor("%0t|current pc = %0d", $time, top_core_inst.pc);

        #1000
        $stop();
    end

    always #5 clk = !clk;
    
    
endmodule
