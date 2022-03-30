`include "cpu_def.v"
`include "opcodes.v"

module control (
        opcode,
        func,
        regdst,  // register destination, mux for write register
        jump,    // if current instruction is jump
        aluop,   // alu operation
        alusrc,  // alu source, mux for second input of alu
        regwrite // enable register write
    );

    input [`OPCODE_SIZE - 1:0] opcode;
    input [`FUNC_SIZE - 1:0] func;
    output reg regdst;
    output reg jump;
    output reg [`ALUOP_SIZE - 1:0] aluop;
    output reg alusrc;
    output reg regwrite;

    reg [`ALUOP_SIZE + 4 - 1:0] rcontrol;

    always @(*) begin
        case (opcode)
            `OPCODE_BNE: {regdst, jump, aluop, alusrc, regwrite} = {1'b0, 1'b0, `OP_ADD, 1'b1, 1'b0};
            `OPCODE_BEQ: {regdst, jump, aluop, alusrc, regwrite} = {1'b0, 1'b0, `OP_ADD, 1'b1, 1'b0};
            `OPCODE_BGZ: {regdst, jump, aluop, alusrc, regwrite} = {1'b0, 1'b0, `OP_ADD, 1'b1, 1'b0};
            `OPCODE_BLZ: {regdst, jump, aluop, alusrc, regwrite} = {1'b0, 1'b0, `OP_ADD, 1'b1, 1'b0};
            `OPCODE_ADI: {regdst, jump, aluop, alusrc, regwrite} = {1'b0, 1'b0, `OP_ADD, 1'b1, 1'b1};
            `OPCODE_ORI: {regdst, jump, aluop, alusrc, regwrite} = {1'b0, 1'b0, `OP_OR, 1'b1, 1'b1};
            `OPCODE_LHI: {regdst, jump, aluop, alusrc, regwrite} = {1'b0, 1'b0, `OP_ADD, 1'b1, 1'b1};
            `OPCODE_LWD: {regdst, jump, aluop, alusrc, regwrite} = {1'b0, 1'b0, `OP_ADD, 1'b1, 1'b1};
            `OPCODE_SWD: {regdst, jump, aluop, alusrc, regwrite} = {1'b0, 1'b0, `OP_ADD, 1'b1, 1'b0};
            `OPCODE_JMP: {regdst, jump, aluop, alusrc, regwrite} = {1'b0, 1'b1, `OP_ADD, 1'b0, 1'b0};
            `OPCODE_JAL: {regdst, jump, aluop, alusrc, regwrite} = {1'b0, 1'b1, `OP_ADD, 1'b0, 1'b1};
            `OPCODE_R: {regdst, jump, aluop, alusrc, regwrite} = rcontrol;
            default: {regdst, jump, aluop, alusrc, regwrite} = {1'b0, 1'b0, `OP_ADD, 1'b0, 1'b0};
        endcase
    end

    always @(*) begin
        case (func)
            `FUNC_ADD: rcontrol = {1'b1, 1'b0, `OP_ADD, 1'b0, 1'b1};
            `FUNC_SUB: rcontrol = {1'b1, 1'b0, `OP_SUB, 1'b0, 1'b1};
            `FUNC_AND: rcontrol = {1'b1, 1'b0, `OP_AND, 1'b0, 1'b1};
            `FUNC_ORR: rcontrol = {1'b1, 1'b0, `OP_OR, 1'b0, 1'b1};
            `FUNC_NOT: rcontrol = {1'b1, 1'b0, `OP_NOT, 1'b0, 1'b1};
            `FUNC_TCP: rcontrol = {1'b1, 1'b0, `OP_SUB, 1'b0, 1'b1};
            `FUNC_SHL: rcontrol = {1'b1, 1'b0, `OP_LLS, 1'b0, 1'b1};
            `FUNC_SHR: rcontrol = {1'b1, 1'b0, `OP_ARS, 1'b0, 1'b1};
            `FUNC_JPR: rcontrol = {1'b0, 1'b1, `OP_ID, 1'b0, 1'b0};
            `FUNC_JRL: rcontrol = {1'b0, 1'b1, `OP_ID, 1'b0, 1'b1};
            `FUNC_RWD: rcontrol = {1'b1, 1'b0, `OP_ADD, 1'b0, 1'b1};
            `FUNC_WWD: rcontrol = {1'b0, 1'b0, `OP_ID, 1'b0, 1'b0};
            `FUNC_HLT: rcontrol = {1'b0, 1'b0, `OP_ADD, 1'b0, 1'b0};
            `FUNC_ENI: rcontrol = {1'b0, 1'b0, `OP_ADD, 1'b0, 1'b0};
            `FUNC_DSI: rcontrol = {1'b0, 1'b0, `OP_ADD, 1'b0, 1'b0};
            default: rcontrol = {1'b0, 1'b0, `OP_ADD, 1'b0, 1'b0};
        endcase
    end
endmodule
