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

    always @(*) begin
        case (opcode)
            `OPCODE_BNE: extimm = {{`EXT_SIZE{imm[`IMM_SIZE - 1]}}, imm};
            `OPCODE_BEQ: extimm = {{`EXT_SIZE{imm[`IMM_SIZE - 1]}}, imm};
            `OPCODE_BGZ: extimm = {{`EXT_SIZE{imm[`IMM_SIZE - 1]}}, imm};
            `OPCODE_BLZ: extimm = {{`EXT_SIZE{imm[`IMM_SIZE - 1]}}, imm};
            `OPCODE_ADI: extimm = {{`EXT_SIZE{imm[`IMM_SIZE - 1]}}, imm};
            `OPCODE_ORI: extimm = {`EXT_SIZE'b0, imm};
            `OPCODE_LHI: extimm = {imm, `EXT_SIZE'b0};
            `OPCODE_LWD: extimm = {{`EXT_SIZE{imm[`IMM_SIZE - 1]}}, imm};
            `OPCODE_SWD: extimm = {{`EXT_SIZE{imm[`IMM_SIZE - 1]}}, imm};
            default    : extimm = `WORD_SIZE'b0;
        endcase
    end
endmodule
