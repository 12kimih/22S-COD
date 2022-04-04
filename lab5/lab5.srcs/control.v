`timescale 1ns / 100ps

`include "constants.v"
`include "opcodes.v"

module control (
        clk,
        reset_n,
        opcode,
        func,
        pcwrite,
        pcmux,
        memread,
        memwrite,
        memaddrmux,
        irwrite,
        regwrite,
        regaddr3mux,
        regdata3mux,
        aluop,
        aluin1mux,
        aluin2mux,
        branch,
        wwd,
        hlt,
        num_inst
    );

    input clk;     // clock
    input reset_n; // active-low reset

    input [`OPCODE_SIZE - 1:0] opcode; // operation code of current instruction
    input [`FUNC_SIZE - 1:0] func;     // function of current R-format instruction

    output pcwrite;                   // PC write
    output [1:0] pcmux;               // PC mux [0:AOR|1:{PC[15:12], IR[11:0]}|2:regdata1]
    output memread;                   // enable memory read
    output memwrite;                  // enable memory write
    output memaddrmux;                // memory address mux [0:PC|1:AOR]
    output irwrite;                   // IR write
    output regwrite;                  // enable register write
    output [1:0] regaddr3mux;         // register address 3 mux [0:IR[9:8]|1:IR[7:6]|2:`REG_ADDR'd2]
    output regdata3mux;               // register data 3 mux [0:AOR|1:MDR]
    output [`ALUOP_SIZE - 1:0] aluop; // ALU operation
    output [1:0] aluin1mux;           // ALU input 1 [0:regdata1|1:PC|2:AOR]
    output [1:0] aluin2mux;           // ALU input 2 [0:regdata2|1:extimm|2:`WORD_SIZE'd1]
    output branch;                    // if current instruction is branch
    output wwd;                       // if current instruction is WWD
    output hlt;                       // if current instruction is HLT

    output reg [`WORD_SIZE - 1:0] num_inst; // number of instructions executed

    reg [`STATE_SIZE - 1:0] state;
    wire [`STATE_SIZE - 1:0] nstate;

    reg [`SIGSET_SIZE - 1:0] sigset;
    wire [`SIGSET_SIZE - 1:0] sigset_default;

    // >>> state >>>
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state <= `STATE_EX;
        end
        else begin
            state <= nstate;
        end
    end
    // <<< state <<<

    // >>> sigset >>>
    assign sigset_default = {`STATE_ERR, 1'b0, 2'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 2'd0, 1'b0, `ALUOP_ADD, 2'd0, 2'd0, 1'b0, 1'b0, 1'b0};

    always @(*) begin
        case (state)
            `STATE_IF: sigset = {`STATE_ID , 1'b0, 2'd0, 1'b1, 1'b0, 1'b0, 1'b1, 1'b0, 2'd0, 1'b0, `ALUOP_ADD, 2'd1, 2'd2, 1'b0, 1'b0, 1'b0};
            `STATE_ID:
            case (opcode)
                `OPCODE_BNE,
                `OPCODE_BEQ,
                `OPCODE_BGZ,
                `OPCODE_BLZ: sigset = {`STATE_EX , 1'b1, 2'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 2'd0, 1'b0, `ALUOP_ADD, 2'd2, 2'd1, 1'b0, 1'b0, 1'b0};
                `OPCODE_ADI,
                `OPCODE_ORI,
                `OPCODE_LHI: sigset = {`STATE_EX , 1'b1, 2'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 2'd0, 1'b0, `ALUOP_ADD, 2'd0, 2'd0, 1'b0, 1'b0, 1'b0};
                `OPCODE_LWD: sigset = {`STATE_EX , 1'b1, 2'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 2'd0, 1'b0, `ALUOP_ADD, 2'd0, 2'd0, 1'b0, 1'b0, 1'b0};
                `OPCODE_SWD: sigset = {`STATE_EX , 1'b1, 2'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 2'd0, 1'b0, `ALUOP_ADD, 2'd0, 2'd0, 1'b0, 1'b0, 1'b0};
                `OPCODE_JMP: sigset = {`STATE_IF , 1'b1, 2'd1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 2'd0, 1'b0, `ALUOP_ADD, 2'd0, 2'd0, 1'b0, 1'b0, 1'b0};
                `OPCODE_JAL: sigset = {`STATE_IF , 1'b1, 2'd1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 2'd2, 1'b0, `ALUOP_ADD, 2'd0, 2'd0, 1'b0, 1'b0, 1'b0};
                `OPCODE_R:
                case (func)
                    `FUNC_ADD,
                    `FUNC_SUB,
                    `FUNC_AND,
                    `FUNC_ORR,
                    `FUNC_NOT,
                    `FUNC_TCP,
                    `FUNC_SHL,
                    `FUNC_SHR: sigset = {`STATE_EX , 1'b1, 2'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 2'd0, 1'b0, `ALUOP_ADD, 2'd0, 2'd0, 1'b0, 1'b0, 1'b0};
                    `FUNC_JPR: sigset = {`STATE_IF , 1'b1, 2'd2, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 2'd0, 1'b0, `ALUOP_ADD, 2'd0, 2'd0, 1'b0, 1'b0, 1'b0};
                    `FUNC_JRL: sigset = {`STATE_IF , 1'b1, 2'd2, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 2'd2, 1'b0, `ALUOP_ADD, 2'd0, 2'd0, 1'b0, 1'b0, 1'b0};
                    `FUNC_WWD: sigset = {`STATE_IF , 1'b1, 2'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 2'd0, 1'b0, `ALUOP_ADD, 2'd0, 2'd0, 1'b0, 1'b1, 1'b0};
                    `FUNC_HLT: sigset = {`STATE_ID , 1'b0, 2'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 2'd0, 1'b0, `ALUOP_ADD, 2'd1, 2'd2, 1'b0, 1'b0, 1'b1};
                    default: sigset = sigset_default;
                endcase
                default: sigset = sigset_default;
            endcase
            `STATE_EX:
            case (opcode)
                `OPCODE_BNE: sigset = {`STATE_IF , 1'b0, 2'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 2'd0, 1'b0, `ALUOP_SNE, 2'd0, 2'd0, 1'b1, 1'b0, 1'b0};
                `OPCODE_BEQ: sigset = {`STATE_IF , 1'b0, 2'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 2'd0, 1'b0, `ALUOP_SEQ, 2'd0, 2'd0, 1'b1, 1'b0, 1'b0};
                `OPCODE_BGZ: sigset = {`STATE_IF , 1'b0, 2'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 2'd0, 1'b0, `ALUOP_SGZ, 2'd0, 2'd0, 1'b1, 1'b0, 1'b0};
                `OPCODE_BLZ: sigset = {`STATE_IF , 1'b0, 2'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 2'd0, 1'b0, `ALUOP_SLZ, 2'd0, 2'd0, 1'b1, 1'b0, 1'b0};
                `OPCODE_ADI: sigset = {`STATE_WB , 1'b0, 2'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 2'd0, 1'b0, `ALUOP_ADD, 2'd0, 2'd1, 1'b0, 1'b0, 1'b0};
                `OPCODE_ORI: sigset = {`STATE_WB , 1'b0, 2'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 2'd0, 1'b0, `ALUOP_OR , 2'd0, 2'd1, 1'b0, 1'b0, 1'b0};
                `OPCODE_LHI: sigset = {`STATE_WB , 1'b0, 2'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 2'd0, 1'b0, `ALUOP_ID2, 2'd0, 2'd1, 1'b0, 1'b0, 1'b0};
                `OPCODE_LWD: sigset = {`STATE_MEM, 1'b0, 2'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 2'd0, 1'b0, `ALUOP_ADD, 2'd0, 2'd1, 1'b0, 1'b0, 1'b0};
                `OPCODE_SWD: sigset = {`STATE_MEM, 1'b0, 2'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 2'd0, 1'b0, `ALUOP_ADD, 2'd0, 2'd1, 1'b0, 1'b0, 1'b0};
                `OPCODE_R:
                case (func)
                    `FUNC_ADD: sigset = {`STATE_WB , 1'b0, 2'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 2'd0, 1'b0, `ALUOP_ADD, 2'd0, 2'd0, 1'b0, 1'b0, 1'b0};
                    `FUNC_SUB: sigset = {`STATE_WB , 1'b0, 2'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 2'd0, 1'b0, `ALUOP_SUB, 2'd0, 2'd0, 1'b0, 1'b0, 1'b0};
                    `FUNC_AND: sigset = {`STATE_WB , 1'b0, 2'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 2'd0, 1'b0, `ALUOP_AND, 2'd0, 2'd0, 1'b0, 1'b0, 1'b0};
                    `FUNC_ORR: sigset = {`STATE_WB , 1'b0, 2'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 2'd0, 1'b0, `ALUOP_OR , 2'd0, 2'd0, 1'b0, 1'b0, 1'b0};
                    `FUNC_NOT: sigset = {`STATE_WB , 1'b0, 2'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 2'd0, 1'b0, `ALUOP_NOT, 2'd0, 2'd0, 1'b0, 1'b0, 1'b0};
                    `FUNC_TCP: sigset = {`STATE_WB , 1'b0, 2'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 2'd0, 1'b0, `ALUOP_TCP, 2'd0, 2'd0, 1'b0, 1'b0, 1'b0};
                    `FUNC_SHL: sigset = {`STATE_WB , 1'b0, 2'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 2'd0, 1'b0, `ALUOP_LLS, 2'd0, 2'd0, 1'b0, 1'b0, 1'b0};
                    `FUNC_SHR: sigset = {`STATE_WB , 1'b0, 2'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 2'd0, 1'b0, `ALUOP_ARS, 2'd0, 2'd0, 1'b0, 1'b0, 1'b0};
                    default: sigset = sigset_default;
                endcase
                default: sigset = sigset_default;
            endcase
            `STATE_MEM:
            case (opcode)
                `OPCODE_LWD: sigset = {`STATE_WB , 1'b0, 2'd0, 1'b1, 1'b0, 1'b1, 1'b0, 1'b0, 2'd0, 1'b0, `ALUOP_ADD, 2'd0, 2'd0, 1'b0, 1'b0, 1'b0};
                `OPCODE_SWD: sigset = {`STATE_IF , 1'b0, 2'd0, 1'b0, 1'b1, 1'b1, 1'b0, 1'b0, 2'd0, 1'b0, `ALUOP_ADD, 2'd0, 2'd0, 1'b0, 1'b0, 1'b0};
                default: sigset = sigset_default;
            endcase
            `STATE_WB:
            case (opcode)
                `OPCODE_ADI,
                `OPCODE_ORI,
                `OPCODE_LHI: sigset = {`STATE_IF , 1'b0, 2'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 2'd0, 1'b0, `ALUOP_ADD, 2'd0, 2'd0, 1'b0, 1'b0, 1'b0};
                `OPCODE_LWD: sigset = {`STATE_IF , 1'b0, 2'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 2'd0, 1'b1, `ALUOP_ADD, 2'd0, 2'd0, 1'b0, 1'b0, 1'b0};
                `OPCODE_R:
                case (func)
                    `FUNC_ADD,
                    `FUNC_SUB,
                    `FUNC_AND,
                    `FUNC_ORR,
                    `FUNC_NOT,
                    `FUNC_TCP,
                    `FUNC_SHL,
                    `FUNC_SHR: sigset = {`STATE_IF , 1'b0, 2'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 2'd1, 1'b0, `ALUOP_ADD, 2'd0, 2'd0, 1'b0, 1'b0, 1'b0};
                    default: sigset = sigset_default;
                endcase
                default: sigset = sigset_default;
            endcase
            default: sigset = sigset_default;
        endcase
    end
    // <<< sigset <<<

    // >>> output >>>
    assign {nstate, pcwrite, pcmux, memread, memwrite, memaddrmux, irwrite, regwrite, regaddr3mux, regdata3mux, aluop, aluin1mux, aluin2mux, branch, wwd, hlt} = sigset;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            num_inst <= -`WORD_SIZE'd1;
        end
        else if (state == `STATE_IF) begin
            num_inst <= num_inst + `WORD_SIZE'd1;
        end
    end
    // <<< output <<<
endmodule
