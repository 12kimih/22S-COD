`timescale 1ns / 1ns

`include "constants.v"

// branch predictor assuming always taken
module BTB_AT (
        clk,
        reset_n,
        pc,
        pcplusone,
        predpc,
        update_btb,
        update_pc,
        update_target
    );

    input clk;
    input reset_n;

    input [`WORD_SIZE - 1:0] pc;
    input [`WORD_SIZE - 1:0] pcplusone;
    output [`WORD_SIZE - 1:0] predpc;

    input update_btb;
    input [`WORD_SIZE - 1:0] update_pc;
    input [`WORD_SIZE - 1:0] update_target;

    integer i;

    reg [`BTB_ENTRY_AT - 1:0] btb [0:`BTB_SIZE - 1];

    wire [`BTB_ENTRY_AT - 1:0] entry;
    wire [`BTB_ENTRY_AT - 1:0] update_entry;

    assign entry = btb[pc[`BTB_ADDR - 1:0]];
    assign update_entry = btb[update_pc[`BTB_ADDR - 1:0]];

    assign predpc = (pc[`WORD_SIZE - 1-:`BTB_TAG] == entry[`BTB_ENTRY_AT - 1-:`BTB_TAG] && entry[`WORD_SIZE]) ? entry[`WORD_SIZE - 1:0] : pcplusone;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            for (i = 0; i < `BTB_SIZE; i = i + 1) begin
                btb[i] <= `BTB_ENTRY_AT'b0;
            end
        end
        else begin
            if (update_btb) begin
                btb[update_pc[`BTB_ADDR - 1:0]] <= {update_pc[`WORD_SIZE - 1-:`BTB_TAG], 1'b1, update_target};
            end
        end
    end
endmodule
