`include "opcodes.v"

module ALU (
        OP,
        A,
        B,
        Cin,
        C,
        Cout
    );

    input [3:0] OP;
    input [15:0] A;
    input [15:0] B;
    input Cin;
    output reg [15:0] C;
    output reg Cout;

    always @(*) begin
        case (OP)
            `OP_ADD: {Cout, C} = A + B + Cin;
            `OP_SUB: {Cout, C} = A - (B + Cin);
            `OP_ID: {Cout, C} = {1'b0, A};
            `OP_NAND: {Cout, C} = {1'b0, ~(A & B)};
            `OP_NOR: {Cout, C} = {1'b0, ~(A | B)};
            `OP_XNOR: {Cout, C} = {1'b0, ~(A ^ B)};
            `OP_NOT: {Cout, C} = {1'b0, ~A};
            `OP_AND: {Cout, C} = {1'b0, A & B};
            `OP_OR: {Cout, C} = {1'b0, A | B};
            `OP_XOR: {Cout, C} = {1'b0, A ^ B};
            `OP_LRS: {Cout, C} = {1'b0, 1'b0, A[15:1]};
            `OP_ARS: {Cout, C} = {1'b0, A[15], A[15:1]};
            `OP_RR: {Cout, C} = {1'b0, A[0], A[15:1]};
            `OP_LLS: {Cout, C} = {1'b0, A[14:0], 1'b0};
            `OP_ALS: {Cout, C} = {1'b0, A[14:0], 1'b0};
            `OP_RL: {Cout, C} = {1'b0, A[14:0], A[15]};
        endcase
    end
endmodule
