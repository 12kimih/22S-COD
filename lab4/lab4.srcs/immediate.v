`include "cpu_def.v"
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
            `OPCODE_BNE: extimm = {{8{imm[`IMM_SIZE - 1]}}, imm};
            `OPCODE_BEQ: extimm = {{8{imm[`IMM_SIZE - 1]}}, imm};
            `OPCODE_BGZ: extimm = {{8{imm[`IMM_SIZE - 1]}}, imm};
            `OPCODE_BLZ: extimm = {{8{imm[`IMM_SIZE - 1]}}, imm};
            `OPCODE_ADI: extimm = {{8{imm[`IMM_SIZE - 1]}}, imm};
            `OPCODE_ORI: extimm = {8'b0, imm};
            `OPCODE_LHI: extimm = {imm, 8'b0};
            `OPCODE_LWD: extimm = {{8{imm[`IMM_SIZE - 1]}}, imm};
            `OPCODE_SWD: extimm = {{8{imm[`IMM_SIZE - 1]}}, imm};
            default: extimm = `WORD_SIZE'b0;
        endcase
    end
endmodule
