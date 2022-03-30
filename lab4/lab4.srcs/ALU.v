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
