`include "cpu_def.v"
`include "opcodes.v"

module control (
        opcode,
        func,
        pcmux,
        aluop,
        aluin1mux,
        aluin2mux,
        regwrite,
        regaddr3mux,
        regdata3mux,
        wwd
    );

    input [`OPCODE_SIZE - 1:0] opcode; // opcode of current instruction
    input [`FUNC_SIZE - 1:0] func;     // func of current R-format instruction

    output [1:0] pcmux;               // PC mux [0 = pc + 1|1 = aluout|2 = {PC[15:12], IR[11:0]}|3 = regdata1]
    output [`ALUOP_SIZE - 1:0] aluop; // ALU operation code
    output [1:0] aluin1mux;           // ALU input 1 [0 = regdata1|1 = extimm|2 = PC|3 = 0]
    output [1:0] aluin2mux;           // ALU input 2 [0 = regdata2|1 = extimm|2 = regdata1|3 = 0]
    output regwrite;                  // enable register write
    output [1:0] regaddr3mux;         // write register mux [0 = IR[9:8]|1 = IR[7:6]|2 = 2]
    output [1:0] regdata3mux;         // write data mux [0 = aluout|1 = memdata1|2 = PC|3 = input_port]
    output wwd;                       // if current instruction is WWD

    reg [`SIGSET_SIZE - 1:0] sigset;
    reg [`SIGSET_SIZE - 1:0] sigset_R;

    assign {pcmux, aluop, aluin1mux, aluin2mux, regwrite, regaddr3mux, regdata3mux, wwd} = sigset;

    always @(*) begin
        case (opcode)
            `OPCODE_BNE: sigset = {2'd1, `OP_ADD, 2'd2, 2'd1, 1'b0, 2'd0, 2'd0, 1'b0};
            `OPCODE_BEQ: sigset = {2'd1, `OP_ADD, 2'd2, 2'd1, 1'b0, 2'd0, 2'd0, 1'b0};
            `OPCODE_BGZ: sigset = {2'd1, `OP_ADD, 2'd2, 2'd1, 1'b0, 2'd0, 2'd0, 1'b0};
            `OPCODE_BLZ: sigset = {2'd1, `OP_ADD, 2'd2, 2'd1, 1'b0, 2'd0, 2'd0, 1'b0};
            `OPCODE_ADI: sigset = {2'd0, `OP_ADD, 2'd0, 2'd1, 1'b1, 2'd0, 2'd0, 1'b0};
            `OPCODE_ORI: sigset = {2'd0, `OP_OR , 2'd0, 2'd1, 1'b1, 2'd0, 2'd0, 1'b0};
            `OPCODE_LHI: sigset = {2'd0, `OP_ID , 2'd1, 2'd0, 1'b1, 2'd0, 2'd0, 1'b0};
            `OPCODE_LWD: sigset = {2'd0, `OP_ADD, 2'd0, 2'd1, 1'b1, 2'd0, 2'd1, 1'b0};
            `OPCODE_SWD: sigset = {2'd0, `OP_ADD, 2'd0, 2'd1, 1'b0, 2'd0, 2'd0, 1'b0};
            `OPCODE_JMP: sigset = {2'd2, `OP_ID , 2'd0, 2'd0, 1'b0, 2'd0, 2'd0, 1'b0};
            `OPCODE_JAL: sigset = {2'd2, `OP_ID , 2'd0, 2'd0, 1'b1, 2'd2, 2'd2, 1'b0};
            `OPCODE_NOP: sigset = {2'd0, `OP_ID , 2'd0, 2'd0, 1'b0, 2'd0, 2'd0, 1'b0};
            `OPCODE_R  : sigset = sigset_R;
            default    : sigset = {2'd0, `OP_ID , 2'd0, 2'd0, 1'b0, 2'd0, 2'd0, 1'b0};
        endcase
    end

    always @(*) begin
        case (func)
            `FUNC_ADD: sigset_R = {2'd0, `OP_ADD, 2'd0, 2'd0, 1'b1, 2'd1, 2'd0, 1'b0};
            `FUNC_SUB: sigset_R = {2'd0, `OP_SUB, 2'd0, 2'd0, 1'b1, 2'd1, 2'd0, 1'b0};
            `FUNC_AND: sigset_R = {2'd0, `OP_AND, 2'd0, 2'd0, 1'b1, 2'd1, 2'd0, 1'b0};
            `FUNC_ORR: sigset_R = {2'd0, `OP_OR , 2'd0, 2'd0, 1'b1, 2'd1, 2'd0, 1'b0};
            `FUNC_NOT: sigset_R = {2'd0, `OP_NOT, 2'd0, 2'd0, 1'b1, 2'd1, 2'd0, 1'b0};
            `FUNC_TCP: sigset_R = {2'd0, `OP_SUB, 2'd3, 2'd2, 1'b1, 2'd1, 2'd0, 1'b0};
            `FUNC_SHL: sigset_R = {2'd0, `OP_LLS, 2'd0, 2'd0, 1'b1, 2'd1, 2'd0, 1'b0};
            `FUNC_SHR: sigset_R = {2'd0, `OP_ARS, 2'd0, 2'd0, 1'b1, 2'd1, 2'd0, 1'b0};
            `FUNC_JPR: sigset_R = {2'd3, `OP_ID , 2'd0, 2'd0, 1'b0, 2'd0, 2'd0, 1'b0};
            `FUNC_JRL: sigset_R = {2'd3, `OP_ID , 2'd0, 2'd0, 1'b1, 2'd2, 2'd2, 1'b0};
            `FUNC_RWD: sigset_R = {2'd0, `OP_ID , 2'd0, 2'd0, 1'b1, 2'd1, 2'd3, 1'b0};
            `FUNC_WWD: sigset_R = {2'd0, `OP_ID , 2'd0, 2'd0, 1'b0, 2'd0, 2'd0, 1'b1};
            `FUNC_HLT: sigset_R = {2'd0, `OP_ID , 2'd0, 2'd0, 1'b0, 2'd0, 2'd0, 1'b0};
            `FUNC_ENI: sigset_R = {2'd0, `OP_ID , 2'd0, 2'd0, 1'b0, 2'd0, 2'd0, 1'b0};
            `FUNC_DSI: sigset_R = {2'd0, `OP_ID , 2'd0, 2'd0, 1'b0, 2'd0, 2'd0, 1'b0};
            default  : sigset_R = {2'd0, `OP_ID , 2'd0, 2'd0, 1'b0, 2'd0, 2'd0, 1'b0};
        endcase
    end
endmodule
