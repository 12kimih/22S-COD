`timescale 1ns / 100ps

`include "constants.v"
`include "opcodes.v"

module control (
        clk,
        reset_n,
        opcode,
        func,
        nstate,
        pcwrite,
        irwrite,
        regwrite,
        imemread,
        dmemread,
        dmemwrite,
        use_rd,
        add_pc,
        use_aor,
        use_imm,
        aluop,
        load,
        branch,
        jump,
        jmpr,
        link,
        wwd,
        hlt
    );

    input clk;     // clock
    input reset_n; // active-low reset

    input [`OPCODE_SIZE - 1:0] opcode; // operation code of current instruction
    input [`FUNC_SIZE - 1:0] func;     // function of current R-format instruction

    output [`STATE_SIZE - 1:0] nstate; // next control state
    output pcwrite;                    // enable pc write
    output irwrite;                    // enable ir write
    output regwrite;                   // enable register write
    output imemread;                   // enable instruction memory read
    output dmemread;                   // enable data memory read
    output dmemwrite;                  // enable data memory write
    output use_rd;                     // if current instruction uses rd
    output add_pc;                     // advance pc to next address
    output use_aor;                    // if current instruction uses aor as alu in1
    output use_imm;                    // if current instruction uses immediate as alu in2
    output [`ALUOP_SIZE - 1:0] aluop;  // alu operation
    output load;                       // if current instruction is load (LWD)
    output branch;                     // if current instruction is branch (BNE, BEQ, BGZ, BLZ)
    output jump;                       // if current instruciton is jump (JMP, JAL)
    output jmpr;                       // if current instruciton is jump register (JPR, JRL)
    output link;                       // if current instruciton links register (JAL, JRL)
    output wwd;                        // if current instruction is WWD
    output hlt;                        // if current instruction is HLT

    reg [`STATE_SIZE - 1:0] state;

    reg [`CONTROL_SIGSET - 1:0] sigset;
    wire [`CONTROL_SIGSET - 1:0] sigset_default;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state <= `STATE_EX;
        end
        else begin
            state <= nstate;
        end
    end

    assign {nstate, pcwrite, irwrite, regwrite, imemread, dmemread, dmemwrite, use_rd, add_pc, use_aor, use_imm, aluop, load, branch, jump, jmpr, link, wwd, hlt} = sigset;

    assign sigset_default = {`STATE_ERR, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, `ALUOP_ADD, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0};

    always @(*) begin
        case (state)
            `STATE_IF: sigset = {`STATE_ID , 1'b0, 1'b1, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0, `ALUOP_ADD, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0};
            `STATE_ID:
            case (opcode)
                `OPCODE_BNE,
                `OPCODE_BEQ,
                `OPCODE_BGZ,
                `OPCODE_BLZ: sigset = {`STATE_EX , 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b1, `ALUOP_ADD, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0};
                `OPCODE_ADI,
                `OPCODE_ORI,
                `OPCODE_LHI: sigset = {`STATE_EX , 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, `ALUOP_ADD, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0};
                `OPCODE_LWD: sigset = {`STATE_EX , 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, `ALUOP_ADD, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0};
                `OPCODE_SWD: sigset = {`STATE_EX , 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, `ALUOP_ADD, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0};
                `OPCODE_JMP: sigset = {`STATE_IF , 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, `ALUOP_ADD, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0};
                `OPCODE_JAL: sigset = {`STATE_IF , 1'b1, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, `ALUOP_ADD, 1'b0, 1'b0, 1'b1, 1'b0, 1'b1, 1'b0, 1'b0};
                `OPCODE_R:
                case (func)
                    `FUNC_ADD,
                    `FUNC_SUB,
                    `FUNC_AND,
                    `FUNC_ORR,
                    `FUNC_NOT,
                    `FUNC_TCP,
                    `FUNC_SHL,
                    `FUNC_SHR: sigset = {`STATE_EX , 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, `ALUOP_ADD, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0};
                    `FUNC_JPR: sigset = {`STATE_IF , 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, `ALUOP_ADD, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0};
                    `FUNC_JRL: sigset = {`STATE_IF , 1'b1, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, `ALUOP_ADD, 1'b0, 1'b0, 1'b0, 1'b1, 1'b1, 1'b0, 1'b0};
                    `FUNC_WWD: sigset = {`STATE_IF , 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, `ALUOP_ADD, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0};
                    `FUNC_HLT: sigset = {`STATE_IF , 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, `ALUOP_ADD, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1};
                    default: sigset = sigset_default;
                endcase
                default: sigset = sigset_default;
            endcase
            `STATE_EX:
            case (opcode)
                `OPCODE_BNE: sigset = {`STATE_IF , 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, `ALUOP_SNE, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0};
                `OPCODE_BEQ: sigset = {`STATE_IF , 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, `ALUOP_SEQ, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0};
                `OPCODE_BGZ: sigset = {`STATE_IF , 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, `ALUOP_SGZ, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0};
                `OPCODE_BLZ: sigset = {`STATE_IF , 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, `ALUOP_SLZ, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0};
                `OPCODE_ADI: sigset = {`STATE_WB , 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, `ALUOP_ADD, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0};
                `OPCODE_ORI: sigset = {`STATE_WB , 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, `ALUOP_OR , 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0};
                `OPCODE_LHI: sigset = {`STATE_WB , 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, `ALUOP_ID2, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0};
                `OPCODE_LWD: sigset = {`STATE_MEM, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, `ALUOP_ADD, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0};
                `OPCODE_SWD: sigset = {`STATE_MEM, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, `ALUOP_ADD, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0};
                `OPCODE_R:
                case (func)
                    `FUNC_ADD: sigset = {`STATE_WB , 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, `ALUOP_ADD, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0};
                    `FUNC_SUB: sigset = {`STATE_WB , 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, `ALUOP_SUB, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0};
                    `FUNC_AND: sigset = {`STATE_WB , 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, `ALUOP_AND, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0};
                    `FUNC_ORR: sigset = {`STATE_WB , 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, `ALUOP_OR , 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0};
                    `FUNC_NOT: sigset = {`STATE_WB , 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, `ALUOP_NOT, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0};
                    `FUNC_TCP: sigset = {`STATE_WB , 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, `ALUOP_TCP, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0};
                    `FUNC_SHL: sigset = {`STATE_WB , 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, `ALUOP_LLS, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0};
                    `FUNC_SHR: sigset = {`STATE_WB , 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, `ALUOP_ARS, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0};
                    default: sigset = sigset_default;
                endcase
                default: sigset = sigset_default;
            endcase
            `STATE_MEM:
            case (opcode)
                `OPCODE_LWD: sigset = {`STATE_WB , 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, `ALUOP_ADD, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0};
                `OPCODE_SWD: sigset = {`STATE_IF , 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, `ALUOP_ADD, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0};
                default: sigset = sigset_default;
            endcase
            `STATE_WB:
            case (opcode)
                `OPCODE_ADI,
                `OPCODE_ORI,
                `OPCODE_LHI: sigset = {`STATE_IF , 1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, `ALUOP_ADD, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0};
                `OPCODE_LWD: sigset = {`STATE_IF , 1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, `ALUOP_ADD, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0};
                `OPCODE_R:
                case (func)
                    `FUNC_ADD,
                    `FUNC_SUB,
                    `FUNC_AND,
                    `FUNC_ORR,
                    `FUNC_NOT,
                    `FUNC_TCP,
                    `FUNC_SHL,
                    `FUNC_SHR: sigset = {`STATE_IF , 1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, `ALUOP_ADD, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0};
                    default: sigset = sigset_default;
                endcase
                default: sigset = sigset_default;
            endcase
            default: sigset = sigset_default;
        endcase
    end
endmodule
