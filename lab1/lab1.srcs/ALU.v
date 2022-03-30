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
            4'b0000: {Cout, C} = A + B + Cin;
            4'b0001: {Cout, C} = A - (B + Cin);
            4'b0010: {Cout, C} = {1'b0, A};
            4'b0011: {Cout, C} = {1'b0, ~(A & B)};
            4'b0100: {Cout, C} = {1'b0, ~(A | B)};
            4'b0101: {Cout, C} = {1'b0, ~(A ^ B)};
            4'b0110: {Cout, C} = {1'b0, ~A};
            4'b0111: {Cout, C} = {1'b0, A & B};
            4'b1000: {Cout, C} = {1'b0, A | B};
            4'b1001: {Cout, C} = {1'b0, A ^ B};
            4'b1010: {Cout, C} = {1'b0, 1'b0, A[15:1]};
            4'b1011: {Cout, C} = {1'b0, A[15], A[15:1]};
            4'b1100: {Cout, C} = {1'b0, A[0], A[15:1]};
            4'b1101: {Cout, C} = {1'b0, A[14:0], 1'b0};
            4'b1110: {Cout, C} = {1'b0, A[14:0], 1'b0};
            4'b1111: {Cout, C} = {1'b0, A[14:0], A[15]};
        endcase
    end
endmodule
