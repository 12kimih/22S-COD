`define OP_ADD 4'd0
`define OP_SUB 4'd1
`define OP_ID 4'd2
`define OP_NAND 4'd3
`define OP_NOR 4'd4
`define OP_XNOR 4'd5
`define OP_NOT 4'd6
`define OP_AND 4'd7
`define OP_OR 4'd8
`define OP_XOR 4'd9
`define OP_LRS 4'd10
`define OP_ARS 4'd11
`define OP_RR 4'd12
`define OP_LLS 4'd13
`define OP_ALS 4'd14
`define OP_RL 4'd15

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
