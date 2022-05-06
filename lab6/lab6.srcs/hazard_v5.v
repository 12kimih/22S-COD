`timescale 1ns / 1ns

`include "constants.v"

module hazard_v5 (
        use_rs,
        use_rt,
        regaddr1,
        regaddr2,
        idex_regwrite,
        idex_memread,
        idex_regaddr3,
        idex_branch,
        jump,
        jmpr,
        ifid_predpc,
        ifid_nextpc,
        idex_predpc,
        idex_nextpc,
        exmem_hlt,
        memwb_hlt,
        is_halted,
        pc_stall,
        ifid_stall,
        pc_flush,
        ifid_flush,
        idex_flush,
        exmem_flush,
        memwb_flush
    );

    // data hazard conditions
    input use_rs;
    input use_rt;
    input [`REG_ADDR - 1:0] regaddr1;
    input [`REG_ADDR - 1:0] regaddr2;
    input idex_regwrite;
    input idex_memread;
    input [`REG_ADDR - 1:0] idex_regaddr3;

    // control hazard conditions
    input idex_branch;
    input jump;
    input jmpr;
    input [`WORD_SIZE - 1:0] ifid_predpc;
    input [`WORD_SIZE - 1:0] ifid_nextpc;
    input [`WORD_SIZE - 1:0] idex_predpc;
    input [`WORD_SIZE - 1:0] idex_nextpc;
    input exmem_hlt;
    input memwb_hlt;
    input is_halted;

    // hazard resolution
    output pc_stall;
    output ifid_stall;
    output [1:0] pc_flush;
    output ifid_flush;
    output idex_flush;
    output exmem_flush;
    output memwb_flush;

    reg [`HAZARD_SIGSET_IDEX - 1:0] sigset;

    assign {pc_stall, ifid_stall, pc_flush, ifid_flush, idex_flush, exmem_flush, memwb_flush} = sigset;

    always @(*) begin
        if (is_halted || memwb_hlt) begin
            sigset = {1'b1, 1'b0, 2'd0, 1'b1, 1'b1, 1'b1, 1'b1};
        end
        else if (exmem_hlt) begin
            sigset = {1'b0, 1'b0, 2'd3, 1'b1, 1'b1, 1'b1, 1'b0};
        end
        else if (idex_branch && idex_predpc != idex_nextpc) begin
            sigset = {1'b0, 1'b0, 2'd2, 1'b1, 1'b1, 1'b0, 1'b0};
        end
        else if (regaddr1 == idex_regaddr3 && use_rs && idex_regwrite && idex_memread) begin
            sigset = {1'b1, 1'b1, 2'd0, 1'b0, 1'b1, 1'b0, 1'b0};
        end
        else if (regaddr2 == idex_regaddr3 && use_rt && idex_regwrite && idex_memread) begin
            sigset = {1'b1, 1'b1, 2'd0, 1'b0, 1'b1, 1'b0, 1'b0};
        end
        else if ((jump || jmpr) && ifid_predpc != ifid_nextpc) begin
            sigset = {1'b0, 1'b0, 2'd1, 1'b1, 1'b0, 1'b0, 1'b0};
        end
        else begin
            sigset = {1'b0, 1'b0, 2'd0, 1'b0, 1'b0, 1'b0, 1'b0};
        end
    end
endmodule
