`timescale 1ns / 1ns

`include "constants.v"
`include "opcodes.v"

module control (
        opcode,
        func,
        use_rs,
        use_rt,
        use_rd,
        use_imm,
        aluop,
        regwrite,
        memread,
        memwrite,
        branch,
        jump,
        jmpr,
        link,
        wwd,
        hlt
    );

    input [`OPCODE_SIZE - 1:0] opcode; // operation code of current instruction
    input [`FUNC_SIZE - 1:0] func;     // function of current R-type instruction

    output use_rs;                    // if current instruction uses rs
    output use_rt;                    // if current instruction uses rt
    output use_rd;                    // if current instruction writes rd
    output use_imm;                   // if current instruction puts immediate into alu
    output [`ALUOP_SIZE - 1:0] aluop; // alu operation
    output regwrite;                  // enable register write
    output memread;                   // enable data memory read
    output memwrite;                  // enable data memory write
    output branch;                    // if current instruction is branch (BNE, BEQ, BGZ, BLZ)
    output jump;                      // if current instruciton is jump (JMP, JAL)
    output jmpr;                      // if current instruciton is jump register (JPR, JRL)
    output link;                      // if current instruciton links register (JAL, JRL)
    output wwd;                       // if current instruction is WWD
    output hlt;                       // if current instruction is HLT

    reg [`CONTROL_SIGSET - 1:0] sigset;
    wire [`CONTROL_SIGSET - 1:0] sigset_default;

    assign {use_rs, use_rt, use_rd, use_imm, aluop, regwrite, memread, memwrite, branch, jump, jmpr, link, wwd, hlt} = sigset;

    assign sigset_default = {1'b0, 1'b0, 1'b0, 1'b0, `ALUOP_ADD, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0};

    always @(*) begin
        case (opcode)
            `OPCODE_BNE: sigset = {1'b1, 1'b1, 1'b0, 1'b0, `ALUOP_SNE, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0};
            `OPCODE_BEQ: sigset = {1'b1, 1'b1, 1'b0, 1'b0, `ALUOP_SEQ, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0};
            `OPCODE_BGZ: sigset = {1'b1, 1'b0, 1'b0, 1'b0, `ALUOP_SGZ, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0};
            `OPCODE_BLZ: sigset = {1'b1, 1'b0, 1'b0, 1'b0, `ALUOP_SLZ, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0};
            `OPCODE_ADI: sigset = {1'b1, 1'b0, 1'b0, 1'b1, `ALUOP_ADD, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0};
            `OPCODE_ORI: sigset = {1'b1, 1'b0, 1'b0, 1'b1, `ALUOP_OR , 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0};
            `OPCODE_LHI: sigset = {1'b0, 1'b0, 1'b0, 1'b1, `ALUOP_ID2, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0};
            `OPCODE_LWD: sigset = {1'b1, 1'b0, 1'b0, 1'b1, `ALUOP_ADD, 1'b1, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0};
            `OPCODE_SWD: sigset = {1'b1, 1'b1, 1'b0, 1'b1, `ALUOP_ADD, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0};
            `OPCODE_JMP: sigset = {1'b0, 1'b0, 1'b0, 1'b0, `ALUOP_ADD, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0};
            `OPCODE_JAL: sigset = {1'b0, 1'b0, 1'b0, 1'b0, `ALUOP_ADD, 1'b1, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b1, 1'b0, 1'b0};
            `OPCODE_R:
            case (func)
                `FUNC_ADD: sigset = {1'b1, 1'b1, 1'b1, 1'b0, `ALUOP_ADD, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0};
                `FUNC_SUB: sigset = {1'b1, 1'b1, 1'b1, 1'b0, `ALUOP_SUB, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0};
                `FUNC_AND: sigset = {1'b1, 1'b1, 1'b1, 1'b0, `ALUOP_AND, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0};
                `FUNC_ORR: sigset = {1'b1, 1'b1, 1'b1, 1'b0, `ALUOP_OR , 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0};
                `FUNC_NOT: sigset = {1'b1, 1'b0, 1'b1, 1'b0, `ALUOP_NOT, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0};
                `FUNC_TCP: sigset = {1'b1, 1'b0, 1'b1, 1'b0, `ALUOP_TCP, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0};
                `FUNC_SHL: sigset = {1'b1, 1'b0, 1'b1, 1'b0, `ALUOP_LLS, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0};
                `FUNC_SHR: sigset = {1'b1, 1'b0, 1'b1, 1'b0, `ALUOP_ARS, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0};
                `FUNC_JPR: sigset = {1'b1, 1'b0, 1'b0, 1'b0, `ALUOP_ADD, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0};
                `FUNC_JRL: sigset = {1'b1, 1'b0, 1'b0, 1'b0, `ALUOP_ADD, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b1, 1'b0, 1'b0};
                `FUNC_WWD: sigset = {1'b1, 1'b0, 1'b0, 1'b0, `ALUOP_ADD, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0};
                `FUNC_HLT: sigset = {1'b0, 1'b0, 1'b0, 1'b0, `ALUOP_ADD, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1};
                default: sigset = sigset_default;
            endcase
            default: sigset = sigset_default;
        endcase
    end
endmodule
