module Niu32_multicycle(SWITCH, KEY, LEDR, LEDG, HEX0, HEX1, HEX2, HEX3, CLOCK_50);
    input  [9:0] SWITCH;
    input  [3:0] KEY;
    input  CLOCK_50;
    output [9:0] LEDR;
    output [7:0] LEDG;
    output [6:0] HEX0, HEX1, HEX2, HEX3;
    
    // 32-bit initialization
    parameter WORD_SIZE = 32; // In bits.
    parameter INSTR_SIZE = 4; // In bytes. Used to increment PC.
    parameter IMM_SIZE = 17; // Size of immediate value, in bits.
    parameter NUM_REGS = 32; // Number of registers.
    parameter REG_BITS = 5; // Number of selector bits for register file.
    parameter OP_BITS = 5; // Number of selector bits for the opcode.
    
    // I/O memory locations
    parameter ADDR_HEX = 32'hFFFF0000; // Memory location of hex lights on board.
    parameter ADDR_LEDR = 32'hFFFF0020; // Memory location of red LED lights on board.
    parameter ADDR_LEDG = 32'hFFFF0040; // Memory location of green LED lights on board.
    parameter ADDR_KEY = 32'hFFFF0100; // Memory location to access key states on board.
    parameter ADDR_SWITCH = 32'hFFFF0120; // Memory location to access switch states on board.
    
    // Init
    parameter INIT_MIF = ""; // IMPORTANT! Point this to assembled Niu32 MIF!
    parameter IMEM_WORDS = 2048; // Max number of words in instruction memory.
    parameter DMEM_WORDS = 2048; // Max number of words in data memory.
    parameter PC_STARTLOC = 32'h0; // Starting value of PC.
    
    // Other
    parameter BUS_NOSIG = {WORD_SIZE{1'bZ}}; // Default block signal on bus
    
    // Control signals
    reg LdPC, DrPC, IncPC;
    reg WrMem, DrMem, LdMAR;
    reg WeReg, DrReg;
    reg LdIR;
    reg DrOff;
    reg LdA, LdB, DrALU;
    reg [(OP_BITS - 1):0] ALUfunc;
    
    // Init clock signal, lock signal
    wire clk, lock;
    Pll pll(.inclk0(CLOCK_50), .c0 (clk), .locked(lock));
    wire reset = !lock;
    
    // Create bus
    tri [(WORD_SIZE - 1):0] bus;
    
    // Create PC
    reg [(WORD_SIZE - 1):0] PC; // Program counter register.
    
    always @(posedge clk or posedge reset) begin
    if (reset)
        PC <= PC_STARTLOC;
    else if (LdPC)
        PC <= bus;
    else if (IncPC)
        PC <= PC + INSTR_SIZE;
    end
endmodule
