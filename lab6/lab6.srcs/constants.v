`ifndef CONSTANTS_V
`define CONSTANTS_V

`define PERIOD1     100

`define NUM_TEST    56
`define TESTID_SIZE 5

`define WORD_SIZE   16
`define MEMORY_SIZE 256
`define REG_SIZE    4
`define REG_ADDR    2

`define INST_SIZE   16
`define OPCODE_SIZE 4
`define FUNC_SIZE   6
`define IMM_SIZE    8
`define TARGET_SIZE 12
`define EXT_SIZE    8 // `WORD_SIZE - `IMM_SIZE

`define ALUOP_SIZE     4
`define CONTROL_SIGSET 17 // `ALUOP_SIZE + 13
`define HAZARD_SIGSET  7

`define BTB_SIZE     256
`define BTB_ADDR     8
`define BTB_TAG      8  // `WORD_SIZE - `BTB_ADDR
`define BTB_ENTRY_AT 25 // `BTB_TAG + 1 + `WORD_SIZE
`define BTB_ENTRY_2C 27 // `BTB_TAG + 3 + `WORD_SIZE

`endif
