`timescale 1ns / 1ns

`include "constants.v"
`include "opcodes.v"

module control (
        opcode,
        func,
        nextpc_mux,
        use_regaddr1,
        use_regaddr2,
        regwrite,
        regaddr3_mux,
        regdata3_mux,
        aluop,
        aluin2_mux,
        memread,
        memwrite,
        branch,
        wwd,
        hlt
    );

    input [`OPCODE_SIZE - 1:0] opcode; // operation code of current instruction
    input [`FUNC_SIZE - 1:0] func;     // function of current R-format instruction

    output [1:0] nextpc_mux;          // next pc mux [0:pcplusone|1:{pc[15:12], target}|2:regdata1]
    output use_regaddr1;              // if current instruction uses regaddr1
    output use_regaddr2;              // if current instruction uses regaddr2
    output regwrite;                  // enable register write
    output [1:0] regaddr3_mux;        // register address 3 mux [0:ir[9:8]|1:ir[7:6]|2:`REG_ADDR'd2]
    output [1:0] regdata3_mux;        // register data 3 mux [0:aluout|1:mdr|2:pcplusone]
    output [`ALUOP_SIZE - 1:0] aluop; // alu operation
    output aluin2_mux;                // alu input 2 mux [0:regdata2|1:extimm]
    output memread;                   // enable data memory read
    output memwrite;                  // enable data memory write
    output branch;                    // if current instruction is branch
    output wwd;                       // if current instruction is WWD
    output hlt;                       // if current instruction is HLT

    reg [`CONTROL_SIGSET - 1:0] sigset;
    wire [`CONTROL_SIGSET - 1:0] sigset_default;

    assign sigset_default = {2'd0, 1'b0, 1'b0, 1'b0, 2'd0, 2'd0, `ALUOP_ADD, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0};

    always @(*) begin
        case (opcode)
            `OPCODE_BNE: sigset = {2'd0, 1'b1, 1'b1, 1'b0, 2'd0, 2'd0, `ALUOP_SNE, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0};
            `OPCODE_BEQ: sigset = {2'd0, 1'b1, 1'b1, 1'b0, 2'd0, 2'd0, `ALUOP_SEQ, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0};
            `OPCODE_BGZ: sigset = {2'd0, 1'b1, 1'b0, 1'b0, 2'd0, 2'd0, `ALUOP_SGZ, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0};
            `OPCODE_BLZ: sigset = {2'd0, 1'b1, 1'b0, 1'b0, 2'd0, 2'd0, `ALUOP_SLZ, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0};
            `OPCODE_ADI: sigset = {2'd0, 1'b1, 1'b0, 1'b1, 2'd0, 2'd0, `ALUOP_ADD, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0};
            `OPCODE_ORI: sigset = {2'd0, 1'b1, 1'b0, 1'b1, 2'd0, 2'd0, `ALUOP_OR , 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0};
            `OPCODE_LHI: sigset = {2'd0, 1'b0, 1'b0, 1'b1, 2'd0, 2'd0, `ALUOP_ID2, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0};
            `OPCODE_LWD: sigset = {2'd0, 1'b1, 1'b0, 1'b1, 2'd0, 2'd1, `ALUOP_ADD, 1'b1, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0};
            `OPCODE_SWD: sigset = {2'd0, 1'b1, 1'b1, 1'b0, 2'd0, 2'd0, `ALUOP_ADD, 1'b1, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0};
            `OPCODE_JMP: sigset = {2'd1, 1'b0, 1'b0, 1'b0, 2'd0, 2'd0, `ALUOP_ADD, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0};
            `OPCODE_JAL: sigset = {2'd1, 1'b0, 1'b0, 1'b1, 2'd2, 2'd2, `ALUOP_ADD, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0};
            `OPCODE_R:
            case (func)
                `FUNC_ADD: sigset = {2'd0, 1'b1, 1'b1, 1'b1, 2'd1, 2'd0, `ALUOP_ADD, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0};
                `FUNC_SUB: sigset = {2'd0, 1'b1, 1'b1, 1'b1, 2'd1, 2'd0, `ALUOP_SUB, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0};
                `FUNC_AND: sigset = {2'd0, 1'b1, 1'b1, 1'b1, 2'd1, 2'd0, `ALUOP_AND, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0};
                `FUNC_ORR: sigset = {2'd0, 1'b1, 1'b1, 1'b1, 2'd1, 2'd0, `ALUOP_OR , 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0};
                `FUNC_NOT: sigset = {2'd0, 1'b1, 1'b0, 1'b1, 2'd1, 2'd0, `ALUOP_NOT, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0};
                `FUNC_TCP: sigset = {2'd0, 1'b1, 1'b0, 1'b1, 2'd1, 2'd0, `ALUOP_TCP, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0};
                `FUNC_SHL: sigset = {2'd0, 1'b1, 1'b0, 1'b1, 2'd1, 2'd0, `ALUOP_LLS, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0};
                `FUNC_SHR: sigset = {2'd0, 1'b1, 1'b0, 1'b1, 2'd1, 2'd0, `ALUOP_ARS, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0};
                `FUNC_JPR: sigset = {2'd2, 1'b1, 1'b0, 1'b0, 2'd0, 2'd0, `ALUOP_ADD, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0};
                `FUNC_JRL: sigset = {2'd2, 1'b1, 1'b0, 1'b1, 2'd2, 2'd2, `ALUOP_ADD, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0};
                `FUNC_WWD: sigset = {2'd0, 1'b1, 1'b0, 1'b0, 2'd0, 2'd0, `ALUOP_ADD, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0};
                `FUNC_HLT: sigset = {2'd0, 1'b0, 1'b0, 1'b0, 2'd0, 2'd0, `ALUOP_ADD, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1};
                default: sigset = sigset_default;
            endcase
            default: sigset = sigset_default;
        endcase
    end

    assign {nextpc_mux, use_regaddr1, use_regaddr2, regwrite, regaddr3_mux, regdata3_mux, aluop, aluin2_mux, memread, memwrite, branch, wwd, hlt} = sigset;
endmodule
