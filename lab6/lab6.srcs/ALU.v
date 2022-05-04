`timescale 1ns / 1ns

`include "constants.v"
`include "opcodes.v"

module ALU (
        op,
        in1,
        in2,
        out
    );

    input [`ALUOP_SIZE - 1:0] op;
    input [`WORD_SIZE - 1:0] in1;
    input [`WORD_SIZE - 1:0] in2;
    output reg [`WORD_SIZE - 1:0] out;

    always @(*) begin
        case (op)
            `ALUOP_ADD: out = in1 + in2;
            `ALUOP_SUB: out = in1 - in2;
            `ALUOP_AND: out = in1 & in2;
            `ALUOP_OR : out = in1 | in2;
            `ALUOP_XOR: out = in1 ^ in2;
            `ALUOP_NOT: out = ~in1;
            `ALUOP_TCP: out = -in1;
            `ALUOP_LLS: out = {in1[`WORD_SIZE - 2:0], 1'b0};
            `ALUOP_LRS: out = {1'b0, in1[`WORD_SIZE - 1:1]};
            `ALUOP_ARS: out = {in1[`WORD_SIZE - 1], in1[`WORD_SIZE - 1:1]};
            `ALUOP_SNE: out = (in1 != in2) ? `WORD_SIZE'b1 : `WORD_SIZE'b0;
            `ALUOP_SEQ: out = (in1 == in2) ? `WORD_SIZE'b1 : `WORD_SIZE'b0;
            `ALUOP_SGZ: out = ($signed(in1) > `WORD_SIZE'sb0) ? `WORD_SIZE'b1 : `WORD_SIZE'b0;
            `ALUOP_SLZ: out = ($signed(in1) < `WORD_SIZE'sb0) ? `WORD_SIZE'b1 : `WORD_SIZE'b0;
            `ALUOP_ID1: out = in1;
            `ALUOP_ID2: out = in2;
        endcase
    end
endmodule
