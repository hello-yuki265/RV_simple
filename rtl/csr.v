
`include "glb_define.v"
module csr(
    clk,
    rst_n,

    csr_wr_en,
    csr_wb_dat,
    csr_rd_en,
    csr_rd_dat,
    csr_idx,

    // single enable
    // when trap or mret occured, this part will be used
    sgl_cause_en,
    sgl_cause_val,
    sgl_mepc_en,
    sgl_mepc_val,
    sgl_mscratch_en,
    sgl_mstatus_en,
    sgl_mret_en,


    // 固定输出CSR
    csr_stl_mtvec,
    csr_stl_mepc

);

    input clk;
    input rst_n;

    input csr_wr_en;
    input [`MXLEN-1:0] csr_wb_dat;
    input csr_rd_en;
    output [`MXLEN-1:0] csr_rd_dat;
    input [11:0] csr_idx;

    input sgl_cause_en;
    input [`MXLEN-1:0] sgl_cause_val;
    input sgl_mepc_en;
    input [`MXLEN-1:0] sgl_mepc_val;
    input sgl_mscratch_en;
    input sgl_mstatus_en;
    input sgl_mret_en;


    output [`MXLEN-1:0] csr_stl_mtvec;
    output [`MXLEN-1:0] csr_stl_mepc;


    


    // =====================================
    // mstatus 
    // =====================================
    wire sel_mstatus = csr_idx == 12'h300;
    wire mstatus_mie;
    wire mstatus_mpie;

    // --------------------
    // mie
    // --------------------
    wire mstatus_mie_en = (sel_mstatus & csr_wr_en) 
                            | sgl_mstatus_en | sgl_mret_en;

                            // when trap occured, mie set to 0
    wire mstatus_mie_nxt = sgl_mstatus_en ? 1'b0 : 
                            // when mret, mie recovery with mpie
                            sgl_mret_en ? mstatus_mpie :
                            // csr instruction modify
                            sel_mstatus ? csr_wb_dat[3] :
                            mstatus_mie; //not change
    dff_r #(1) dff_r_mstatus_mie (clk, rst_n, mstatus_mie_en, mstatus_mie_nxt, mstatus_mie);
    
    // --------------------
    // mpie
    // --------------------
    wire mstatus_mpie_en = (sel_mstatus & csr_wr_en) 
                            | sgl_mstatus_en | sgl_mret_en;

                            // when trap occured, mpie set to mie
    wire mstatus_mpie_nxt = sgl_mstatus_en ? mstatus_mie : 
                            // when mret, mpie set to 1
                            sgl_mret_en ? 1'b1 :
                            // csr instruction modify
                            sel_mstatus ? csr_wb_dat[7] :
                            mstatus_mpie; //not change
    dff_r #(1) dff_r_mstatus_mpie (clk, rst_n, mstatus_mpie_en, mstatus_mpie_nxt, mstatus_mpie);

    wire [`MXLEN-1:0] csr_mstatus;
    assign csr_mstatus[31]    = 1'b0;    //SD
    assign csr_mstatus[30:23] = 8'b0;           // Reserved
    assign csr_mstatus[22:17] = 6'b0;           // TSR--MPRV
    assign csr_mstatus[16:15] = 2'b0;    // XS
    assign csr_mstatus[14:13] = 2'b0;    // FS
    assign csr_mstatus[12:11] = 2'b11;          // MPP 
    assign csr_mstatus[10:9]  = 2'b0;           // Reserved
    assign csr_mstatus[8]     = 1'b0;           // SPP
    assign csr_mstatus[7]     = mstatus_mpie;  // MPIE
    assign csr_mstatus[6]     = 1'b0;           // Reserved
    assign csr_mstatus[5]     = 1'b0;           // SPIE 
    assign csr_mstatus[4]     = 1'b0;           // UPIE 
    assign csr_mstatus[3]     = mstatus_mie;   // MIE
    assign csr_mstatus[2]     = 1'b0;           // Reserved
    assign csr_mstatus[1]     = 1'b0;           // SIE 
    assign csr_mstatus[0]     = 1'b0;           // UIE 

    

    // =====================================
    // mcause
    // =====================================
    wire sel_mcause = csr_idx == 12'h342;
    wire wr_mcause = sel_mcause & csr_wr_en;
    wire rd_mcause = sel_mcause & csr_rd_en;
    wire cause_en = wr_mcause | sgl_cause_en;
    wire [`MXLEN-1:0] csr_mcause;
    wire [`MXLEN-1:0] csr_mcause_nxt = sgl_cause_en ? sgl_cause_val : csr_wb_dat; 
    dff_r #(`MXLEN) dff_r_mcause (clk, rst_n, cause_en, csr_mcause_nxt, csr_mcause);

    // ======================================
    // mepc
    // ======================================
    wire sel_mepc = csr_idx == 12'h341;
    wire wr_mepc = sel_mepc & csr_wr_en;
    wire rd_mepc = sel_mepc & csr_rd_en;
    wire mepc_en = wr_mepc | sgl_mepc_en;
    wire [`MXLEN-1:0] csr_mepc;
    wire [`MXLEN-1:0] csr_mepc_nxt = sgl_mepc_en ? sgl_mepc_val : csr_wb_dat; //TODO:暂时先不管其他输入
    dff_r #(`MXLEN) dff_r_mepc (clk, rst_n, mepc_en, csr_mepc_nxt, csr_mepc);
    assign csr_stl_mepc = csr_mepc;

    // ======================================
    // mtvec
    // ======================================
    wire sel_mtvec = csr_idx == 12'h305;
    wire wr_mtvec = sel_mtvec & csr_wr_en;
    wire rd_mtvec = sel_mtvec & csr_rd_en;
    wire [`MXLEN-1:0] csr_mtvec;
    wire [`MXLEN-1:0] csr_mtvec_nxt = csr_wb_dat;
    dff_r #(`MXLEN) dff_r_mtvec (clk, rst_n, wr_mtvec, csr_mtvec_nxt, csr_mtvec);
    assign csr_stl_mtvec = csr_mtvec;

    // ======================================
    // mscratch
    // ======================================
    wire sel_mscratch = csr_idx == 12'h340;
    wire wr_mscratch = sel_mscratch & csr_wr_en;
    wire rd_mscratch = sel_mscratch & csr_rd_en;
    wire [`MXLEN-1:0] csr_mscratch;
    wire [`MXLEN-1:0] csr_mscratch_nxt = csr_wb_dat;
    dff_r #(`MXLEN) dff_r_mscratch (clk, rst_n, wr_mscratch, csr_mscratch_nxt, csr_mscratch);


    // ======================================
    // csr rd data mux
    // ======================================
    assign csr_rd_dat = rd_mtvec ? csr_mtvec :
                        rd_mcause ? csr_mcause :
                        rd_mepc ? csr_mepc :
                        rd_mscratch ? csr_mscratch :
                        32'b0; //默认返回0
endmodule