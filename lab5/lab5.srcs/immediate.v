`timescale 1ns / 100ps

`include "constants.v"
`include "opcodes.v"

module immediate (
        opcode,
        imm,
        extimm
    );

    input [`OPCODE_SIZE - 1:0] opcode;
    input [`IMM_SIZE - 1:0] imm;
    output reg [`WORD_SIZE - 1:0] extimm;

    wire [`WORD_SIZE - 1:0] sign;
    wire [`WORD_SIZE - 1:0] zero;
    wire [`WORD_SIZE - 1:0] upper;

    assign sign = {{`EXT_SIZE{imm[`IMM_SIZE - 1]}}, imm};
    assign zero = {`EXT_SIZE'b0, imm};
    assign upper = {imm, `EXT_SIZE'b0};

    always @(*) begin
        case (opcode)
            `OPCODE_BNE: extimm = sign;
            `OPCODE_BEQ: extimm = sign;
            `OPCODE_BGZ: extimm = sign;
            `OPCODE_BLZ: extimm = sign;
            `OPCODE_ADI: extimm = sign;
            `OPCODE_ORI: extimm = zero;
            `OPCODE_LHI: extimm = upper;
            `OPCODE_LWD: extimm = sign;
            `OPCODE_SWD: extimm = sign;
            default    : extimm = `WORD_SIZE'b0;
        endcase
    end
endmodule
