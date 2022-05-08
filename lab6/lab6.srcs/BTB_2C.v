`timescale 1ns / 1ns

`include "constants.v"

// branch predictor using 2-bit saturation counter
module BTB_2C (
        clk,
        reset_n,
        pc,
        pcplusone,
        predpc,
        update,
        update_pc,
        update_target,
        update_nextpc
    );

    input clk;
    input reset_n;

    input [`WORD_SIZE - 1:0] pc;
    input [`WORD_SIZE - 1:0] pcplusone;
    output [`WORD_SIZE - 1:0] predpc;

    input update;
    input [`WORD_SIZE - 1:0] update_pc;
    input [`WORD_SIZE - 1:0] update_target;
    input [`WORD_SIZE - 1:0] update_nextpc;

    integer i;

    reg [`BTB_2C_ENTRY - 1:0] btb [0:`BTB_SIZE - 1];

    wire [`BTB_2C_ENTRY - 1:0] entry;
    wire [`BTB_2C_ENTRY - 1:0] update_entry;

    wire [1:0] update_counter;
    wire [1:0] update_counter_plus;
    wire [1:0] update_counter_minus;

    assign entry = btb[pc[`BTB_ADDR - 1:0]];
    assign update_entry = btb[update_pc[`BTB_ADDR - 1:0]];

    assign update_counter = update_entry[`WORD_SIZE + 1+:2];
    assign update_counter_plus = (update_counter == 2'd0) ? 2'd1 : (update_counter == 2'd1) ? 2'd2 : 2'd3;
    assign update_counter_minus = (update_counter == 2'd3) ? 2'd2 : (update_counter == 2'd2) ? 2'd1 : 2'd0;

    assign predpc = (pc[`WORD_SIZE - 1-:`BTB_TAG] == entry[`BTB_2C_ENTRY - 1-:`BTB_TAG] && entry[`WORD_SIZE] && entry[`WORD_SIZE + 2]) ? entry[`WORD_SIZE - 1:0] : pcplusone;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            for (i = 0; i < `BTB_SIZE; i = i + 1) begin
                btb[i] <= `BTB_2C_ENTRY'b0;
            end
        end
        else begin
            if (update) begin
                if (update_pc[`WORD_SIZE - 1-:`BTB_TAG] == update_entry[`BTB_2C_ENTRY - 1-:`BTB_TAG] && update_entry[`WORD_SIZE] && update_target == update_entry[`WORD_SIZE - 1:0]) begin
                    if (update_nextpc == update_target) begin
                        btb[update_pc[`BTB_ADDR - 1:0]] <= {update_pc[`WORD_SIZE - 1-:`BTB_TAG], update_counter_plus, 1'b1, update_target};
                    end
                    else begin
                        btb[update_pc[`BTB_ADDR - 1:0]] <= {update_pc[`WORD_SIZE - 1-:`BTB_TAG], update_counter_minus, 1'b1, update_target};
                    end
                end
                else begin
                    if (update_nextpc == update_target) begin
                        btb[update_pc[`BTB_ADDR - 1:0]] <= {update_pc[`WORD_SIZE - 1-:`BTB_TAG], 2'd2, 1'b1, update_target};
                    end
                    else begin
                        btb[update_pc[`BTB_ADDR - 1:0]] <= {update_pc[`WORD_SIZE - 1-:`BTB_TAG], 2'd1, 1'b1, update_target};
                    end
                end
            end
        end
    end
endmodule
