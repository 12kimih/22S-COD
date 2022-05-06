`timescale 1ns / 1ns

`include "constants.v"

module BTB_v1 (
        clk,
        reset_n,
        pc,
        pcplusone,
        predpc,
        exmem_nop,
        exmem_pc,
        exmem_nextpc
    );

    input clk;
    input reset_n;

    input [`WORD_SIZE - 1:0] pc;
    input [`WORD_SIZE - 1:0] pcplusone;
    output [`WORD_SIZE - 1:0] predpc;

    input exmem_nop;
    input [`WORD_SIZE - 1:0] exmem_pc;
    input [`WORD_SIZE - 1:0] exmem_nextpc;

    integer i;

    reg [`BTB_ENTRY_BL - 1:0] btb [0:`BTB_SIZE - 1];

    wire [`BTB_ENTRY_BL - 1:0] entry;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            for (i = 0; i < `BTB_SIZE; i = i + 1) begin
                btb[i] <= `BTB_ENTRY_BL'b0;
            end
        end
        else begin
            if (!exmem_nop) begin
                btb[exmem_pc[`BTB_ADDR - 1:0]] <= {exmem_pc[`WORD_SIZE - 1-:`BTB_TAG], 1'b1, exmem_nextpc};
            end
        end
    end

    assign entry = btb[pc[`BTB_ADDR - 1:0]];

    assign predpc = (pc[`WORD_SIZE - 1-:`BTB_TAG] == entry[`BTB_ENTRY_BL - 1-:`BTB_TAG] && entry[`WORD_SIZE]) ? entry[`WORD_SIZE - 1:0] : pcplusone;
endmodule
