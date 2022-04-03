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
    output aluin1mux;                 // ALU input 1 [0:regdata1|1:PC]
    output [1:0] aluin2mux;           // ALU input 2 [0:regdata|1:extimm|2:`WORD_SIZE'd1]
    output branch;                    // if current instruction is branch
    output wwd;                       // if current instruction is WWD
    output hlt;                       // if current instruction is HLT

    output reg [`WORD_SIZE - 1:0] num_inst; // number of instructions executed

    reg [`STATE_SIZE - 1:0] state;
    wire [`STATE_SIZE - 1:0] nstate;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            num_inst <= `WORD_SIZE'd0;
        end
        else if (state == `STATE_IF) begin
            num_inst <= num_inst + `WORD_SIZE'd1;
        end
    end

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state <= `STATE_INI;
        end
        else begin
            state <= nstate;
        end
    end

    reg [`ALUOP_SIZE - 1:0] aluop_ex;
    reg [`ALUOP_SIZE - 1:0] aluop_ex_r;

    always @(*) begin
        case (opcode)
            `OPCODE_BNE: aluop_ex = `ALUOP_SNE;
            `OPCODE_BEQ: aluop_ex = `ALUOP_SEQ;
            `OPCODE_BGZ: aluop_ex = `ALUOP_SGZ;
            `OPCODE_BLZ: aluop_ex = `ALUOP_SLZ;
            `OPCODE_ADI: aluop_ex = `ALUOP_ADD;
            `OPCODE_ORI: aluop_ex = `ALUOP_OR;
            `OPCODE_LHI: aluop_ex = `ALUOP_ID2;
            `OPCODE_LWD: aluop_ex = `ALUOP_ADD;
            `OPCODE_SWD: aluop_ex = `ALUOP_ADD;
            `OPCODE_R  : aluop_ex = aluop_ex_r;
            default    : aluop_ex = `ALUOP_ADD;
        endcase
    end

    always @(*) begin
        case (func)
            `FUNC_ADD: aluop_ex_r = `ALUOP_ADD;
            `FUNC_SUB: aluop_ex_r = `ALUOP_SUB;
            `FUNC_AND: aluop_ex_r = `ALUOP_AND;
            `FUNC_ORR: aluop_ex_r = `ALUOP_OR;
            `FUNC_NOT: aluop_ex_r = `ALUOP_NOT;
            `FUNC_TCP: aluop_ex_r = `ALUOP_TCP;
            `FUNC_SHL: aluop_ex_r = `ALUOP_LLS;
            `FUNC_SHR: aluop_ex_r = `ALUOP_ARS;
            default  : aluop_ex_r = `ALUOP_ADD;
        endcase
    end

    reg [`SIGSET_SIZE - 1:0] sigset;
    wire [`SIGSET_SIZE - 1:0] sigset_default;

    assign {nstate, pcwrite, pcmux, memread, memwrite, memaddrmux, irwrite, regwrite, regaddr3mux, regdata3mux, aluin1mux, aluin2mux, branch} = sigset;
    assign aluop = (state == `STATE_EX) ? aluop_ex : `ALUOP_ADD;
    assign wwd = (opcode == `OPCODE_R && func == `FUNC_WWD && state == `STATE_ID) ? 1'b1 : 1'b0;
    assign hlt = (opcode == `OPCODE_R && func == `FUNC_HLT && state == `STATE_ID) ? 1'b1 : 1'b0;

    assign sigset_default = {`STATE_IF , 1'b0, 2'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 2'd0, 1'b0, 1'b0, 2'd0, 1'b0};

    always @(*) begin
        case (state)
            `STATE_IF: sigset = {`STATE_ID , 1'b0, 2'd0, 1'b1, 1'b0, 1'b0, 1'b1, 1'b0, 2'd0, 1'b0, 1'b1, 2'd2, 1'b0};
            `STATE_ID:
            case (opcode)
                `OPCODE_BNE,
                `OPCODE_BEQ,
                `OPCODE_BGZ,
                `OPCODE_BLZ: sigset = {`STATE_EX , 1'b1, 2'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 2'd0, 1'b0, 1'b1, 2'd1, 1'b0};
                `OPCODE_ADI,
                `OPCODE_ORI,
                `OPCODE_LHI: sigset = {`STATE_EX , 1'b1, 2'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 2'd0, 1'b0, 1'b0, 2'd0, 1'b0};
                `OPCODE_LWD: sigset = {`STATE_EX , 1'b1, 2'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 2'd0, 1'b0, 1'b0, 2'd0, 1'b0};
                `OPCODE_SWD: sigset = {`STATE_EX , 1'b1, 2'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 2'd0, 1'b0, 1'b0, 2'd0, 1'b0};
                `OPCODE_JMP: sigset = {`STATE_IF , 1'b1, 2'd1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 2'd0, 1'b0, 1'b0, 2'd0, 1'b0};
                `OPCODE_JAL: sigset = {`STATE_IF , 1'b1, 2'd1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 2'd2, 1'b0, 1'b0, 2'd0, 1'b0};
                `OPCODE_R:
                case (func)
                    `FUNC_ADD,
                    `FUNC_SUB,
                    `FUNC_AND,
                    `FUNC_ORR,
                    `FUNC_NOT,
                    `FUNC_TCP,
                    `FUNC_SHL,
                    `FUNC_SHR: sigset = {`STATE_EX , 1'b1, 2'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 2'd0, 1'b0, 1'b0, 2'd0, 1'b0};
                    `FUNC_JPR: sigset = {`STATE_IF , 1'b1, 2'd2, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 2'd0, 1'b0, 1'b0, 2'd0, 1'b0};
                    `FUNC_JRL: sigset = {`STATE_IF , 1'b1, 2'd2, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 2'd2, 1'b0, 1'b0, 2'd0, 1'b0};
                    `FUNC_WWD: sigset = {`STATE_IF , 1'b1, 2'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 2'd0, 1'b0, 1'b0, 2'd0, 1'b0};
                    `FUNC_HLT: sigset = {`STATE_ID , 1'b0, 2'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 2'd0, 1'b0, 1'b1, 2'd2, 1'b0};
                    default: sigset = sigset_default;
                endcase
                default: sigset = sigset_default;
            endcase
            `STATE_EX:
            case (opcode)
                `OPCODE_BNE,
                `OPCODE_BEQ,
                `OPCODE_BGZ,
                `OPCODE_BLZ: sigset = {`STATE_IF , 1'b0, 2'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 2'd0, 1'b0, 1'b0, 2'd0, 1'b1};
                `OPCODE_ADI,
                `OPCODE_ORI,
                `OPCODE_LHI: sigset = {`STATE_WB , 1'b0, 2'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 2'd0, 1'b0, 1'b0, 2'd1, 1'b0};
                `OPCODE_LWD: sigset = {`STATE_MEM, 1'b0, 2'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 2'd0, 1'b0, 1'b0, 2'd1, 1'b0};
                `OPCODE_SWD: sigset = {`STATE_MEM, 1'b0, 2'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 2'd0, 1'b0, 1'b0, 2'd1, 1'b0};
                `OPCODE_R:
                case (func)
                    `FUNC_ADD,
                    `FUNC_SUB,
                    `FUNC_AND,
                    `FUNC_ORR,
                    `FUNC_NOT,
                    `FUNC_TCP,
                    `FUNC_SHL,
                    `FUNC_SHR: sigset = {`STATE_WB , 1'b0, 2'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 2'd0, 1'b0, 1'b0, 2'd0, 1'b0};
                    default: sigset = sigset_default;
                endcase
                default: sigset = sigset_default;
            endcase
            `STATE_MEM:
            case (opcode)
                `OPCODE_LWD: sigset = {`STATE_WB , 1'b0, 2'd0, 1'b1, 1'b0, 1'b1, 1'b0, 1'b0, 2'd0, 1'b0, 1'b0, 2'd0, 1'b0};
                `OPCODE_SWD: sigset = {`STATE_IF , 1'b0, 2'd0, 1'b0, 1'b1, 1'b1, 1'b0, 1'b0, 2'd0, 1'b0, 1'b0, 2'd0, 1'b0};
                default: sigset = sigset_default;
            endcase
            `STATE_WB:
            case (opcode)
                `OPCODE_ADI,
                `OPCODE_ORI,
                `OPCODE_LHI: sigset = {`STATE_IF , 1'b0, 2'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 2'd0, 1'b0, 1'b0, 2'd0, 1'b0};
                `OPCODE_LWD: sigset = {`STATE_IF , 1'b0, 2'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 2'd0, 1'b1, 1'b0, 2'd0, 1'b0};
                `OPCODE_R:
                case (func)
                    `FUNC_ADD,
                    `FUNC_SUB,
                    `FUNC_AND,
                    `FUNC_ORR,
                    `FUNC_NOT,
                    `FUNC_TCP,
                    `FUNC_SHL,
                    `FUNC_SHR: sigset = {`STATE_IF , 1'b0, 2'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 2'd1, 1'b0, 1'b0, 2'd0, 1'b0};
                    default: sigset = sigset_default;
                endcase
                default: sigset = sigset_default;
            endcase
            default: sigset = sigset_default;
        endcase
    end
endmodule
