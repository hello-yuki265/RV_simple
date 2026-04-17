
module tb_top_core();

    logic clk;
    logic rst_n;

    top_core  top_core_inst (
    .clk(clk),
    .rst_n(rst_n)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        #100
        rst_n = 1;
        $monitor("%0t|current pc = %0d", $time, top_core_inst.pc);

        #1000
        $stop();
    end

    always #5 clk = !clk;
    
    
endmodule