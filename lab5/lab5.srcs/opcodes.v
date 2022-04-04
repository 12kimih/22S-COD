`ifndef OPCODES_V
`define OPCODES_V

`define OPCODE_BNE 4'd0
`define OPCODE_BEQ 4'd1
`define OPCODE_BGZ 4'd2
`define OPCODE_BLZ 4'd3
`define OPCODE_ADI 4'd4
`define OPCODE_ORI 4'd5
`define OPCODE_LHI 4'd6
`define OPCODE_LWD 4'd7
`define OPCODE_SWD 4'd8
`define OPCODE_JMP 4'd9
`define OPCODE_JAL 4'd10
`define OPCODE_R   4'd15

`define FUNC_ADD 6'd0
`define FUNC_SUB 6'd1
`define FUNC_AND 6'd2
`define FUNC_ORR 6'd3
`define FUNC_NOT 6'd4
`define FUNC_TCP 6'd5
`define FUNC_SHL 6'd6
`define FUNC_SHR 6'd7
`define FUNC_JPR 6'd25
`define FUNC_JRL 6'd26
`define FUNC_WWD 6'd28
`define FUNC_HLT 6'd29

`define ALUOP_ADD 4'd0
`define ALUOP_SUB 4'd1
`define ALUOP_AND 4'd2
`define ALUOP_OR  4'd3
`define ALUOP_XOR 4'd4
`define ALUOP_NOT 4'd5
`define ALUOP_TCP 4'd6
`define ALUOP_LLS 4'd7
`define ALUOP_LRS 4'd8
`define ALUOP_ARS 4'd9
`define ALUOP_SNE 4'd10
`define ALUOP_SEQ 4'd11
`define ALUOP_SGZ 4'd12
`define ALUOP_SLZ 4'd13
`define ALUOP_ID1 4'd14
`define ALUOP_ID2 4'd15

`define STATE_IF  3'd0
`define STATE_ID  3'd1
`define STATE_EX  3'd2
`define STATE_MEM 3'd3
`define STATE_WB  3'd4
`define STATE_ERR 3'd7

`endif
