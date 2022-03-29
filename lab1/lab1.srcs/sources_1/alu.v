// Arithmetic
`define OP_ADD 4'b0000
`define OP_SUB 4'b0001
//  Bitwise Boolean operation
`define OP_ID 4'b0010
`define OP_NAND 4'b0011
`define OP_NOR 4'b0100
`define OP_XNOR 4'b0101
`define OP_NOT 4'b0110
`define OP_AND 4'b0111
`define OP_OR 4'b1000
`define OP_XOR 4'b1001
// Shifting
`define OP_LRS 4'b1010
`define OP_ARS 4'b1011
`define OP_RR 4'b1100
`define OP_LLS 4'b1101
`define OP_ALS 4'b1110
`define OP_RL 4'b1111

module alu (
        A,
        B,
        Cin,
        OP,
        C,
        Cout
    );

    input [15:0] A;
    input [15:0] B;
    input Cin;
    input [3:0] OP;
    output reg [15:0] C;
    output reg Cout;

    always @(*) begin
        case (OP)4'b0000 : {Cout, C} = A + B + Cin;
            4'b0001 : {Cout, C} = A - (B + Cin);
            4'b0010 : {Cout, C} = {1'b0, A};
            4'b0011 : {Cout, C} = {1'b0, ~(A &B)};
            4'b0100 : {Cout, C} = {1'b0, ~(A | B)};
            4'b0101 : {Cout, C} = {1'b0, ~(A ^ B)};
            4'b0110 : {Cout, C} = {1'b0, ~A};
            4'b0111 : {Cout, C} = {1'b0, A &B};
            4'b1000 : {Cout, C} = {1'b0, A | B};
            4'b1001 : {Cout, C} = {1'b0, A ^ B};
            4'b1010 : {Cout, C} = {1'b0, 1'b0, A [15:1]};
            4'b1011 : {Cout, C} = {1'b0, A[15], A [15:1]};
            4'b1100 : {Cout, C} = {1'b0, A[0], A [15:1]};
            4'b1101 : {Cout, C} = {1'b0, A [14:0], 1'b0};
            4'b1110 : {Cout, C} = {1'b0, A [14:0], 1'b0};
            4'b1111 : {Cout, C} = {1'b0, A [14:0], A[15]};
        endcase
    end
endmodule
