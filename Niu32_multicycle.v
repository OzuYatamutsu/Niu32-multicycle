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
    parameter STATE_BITS = 5; // Number of bits for the state machine.
    
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
    parameter MEM_ADDR_BITS = 13; // Number of bits used for indexing into memory.
    parameter MEM_WORD_OFFSET = 2; // Number of bits used for selecting individual memory words.
    parameter PC_STARTLOC = 32'h0; // Starting value of PC.

    // Other
    parameter BUS_NOSIG = {WORD_SIZE {1'bZ}}; // Default block signal on bus
    
    // Control signals
    reg LdPC, DrPC, IncPC;
    reg WrMem, DrMem, LdMAR;
    reg WrReg, DrReg;
    reg LdIR;
    reg DrOff;
    reg LdA, LdB, DrALU;
    
    /// Opcodes
    // Primary
    parameter OP1_ALUI = 5'b00000;
    parameter OP1_ADDI = 5'b00001;
    parameter OP1_MLTI = 5'b00010;
    parameter OP1_DIVI = 5'b00011;
    parameter OP1_ANDI = 5'b00101;
    parameter OP1_ORI = 5'b00110;
    parameter OP1_XORI = 5'b00111;
    parameter OP1_SULI = 5'b01000;
    parameter OP1_SSLI = 5'b01001;
    parameter OP1_SURI = 5'b01010;
    parameter OP1_SSRI = 5'b01011;
    parameter OP1_LW = 5'b10000;
    parameter OP1_LB = 5'b10001;
    parameter OP1_SW = 5'b10011;
    parameter OP1_SB = 5'b10100;
    parameter OP1_LUI = 5'b10110;
    parameter OP1_BEQ = 5'b11000;
    parameter OP1_BNE = 5'b11001;
    parameter OP1_BLT = 5'b11010;
    parameter OP1_BLE = 5'b11011;
    parameter OP1_JAL = 5'b11111;
    
    // Secondary
    parameter OP2_SUB = 5'b00000;
    parameter OP2_ADD = 5'b00001;
    parameter OP2_MLT = 5'b00010;
    parameter OP2_DIV = 5'b00011;
    parameter OP2_NOT = 5'b00100;
    parameter OP2_AND = 5'b00101;
    parameter OP2_OR = 5'b00110;
    parameter OP2_XOR = 5'b00111;
    parameter OP2_SUL = 5'b01000;
    parameter OP2_SSL = 5'b01001;
    parameter OP2_SUR = 5'b01010;
    parameter OP2_SSR = 5'b01011;
    parameter OP2_EQ = 5'b10000;
    parameter OP2_NEQ = 5'b10001;
    parameter OP2_LT = 5'b10010;
    parameter OP2_LEQ = 5'b10011;
    
    // Init clock signal, lock signal
    wire clk, lock;
    Pll pll(.inclk0(CLOCK_50), .c0 (clk), .locked (lock)); // DEBUG: set to 50 MHz.
    wire reset = !lock;
    
    // Init seven-segment display - grab values from memory
    SevenSeg Hex0Out(.hexNumIn(ADDR_HEX[3:0]), .displayOut(HEX0));
    SevenSeg Hex1Out(.hexNumIn(ADDR_HEX[7:4]), .displayOut(HEX1));
    SevenSeg Hex2Out(.hexNumIn(ADDR_HEX[11:8]), .displayOut(HEX2));
    SevenSeg Hex3Out(.hexNumIn(ADDR_HEX[15:12]), .displayOut(HEX3));
    
    // Define I/O
    reg [(WORD_SIZE - 1):0] HEXout, LEDRout, LEDGout, KEYout, SWITCHout;
    assign LEDR = LEDRout;
    assign LEDG = LEDGout;
    
    // Create bus
    tri [(WORD_SIZE - 1):0] bus;
    
    // Create PC
    reg [(WORD_SIZE - 1):0] PC; // Program counter register.
    
    // PC logic
    always @(posedge clk or posedge reset) begin
    if (reset)
        // If we're given the reset signal, reset the PC to the start.
        PC <= PC_STARTLOC;
    else if (LdPC)
        // If LdPC, grab the PC value from the bus.
        PC <= bus;
    else if (IncPC)
        // Otherwise, increment the PC to the next instruction.
        PC <= PC + INSTR_SIZE;
    end
    
    // Hook up PC to bus
    assign bus = DrPC ? PC : BUS_NOSIG;
    
    // Register file
    reg [(NUM_REGS - 1):0] regFile;
    reg [(REG_BITS - 1):0] regSel; // Register selector
    
    always @(posedge clk) begin
        if (WrReg && lock)
            regFile[regSel] <= bus;
    end
    
    // Hook up register file to bus
    wire [(WORD_SIZE - 1):0] regOut = WrReg ? BUS_NOSIG : regFile[regSel];
    assign bus = DrReg ? regOut : BUS_NOSIG;
    
    // Instruction memory
    (* ram_init_file = INIT_MIF *)
    reg [(WORD_SIZE - 1):0] imem[(IMEM_WORDS - 1):0];
    reg [(WORD_SIZE - 1):0] IR; // Instruction register
    wire imemOutput = imem[PC[(MEM_ADDR_BITS - 1):MEM_WORD_OFFSET]];
    
    // Push instruction memory to IR
    always @(posedge clk) begin
        if (LdIR)
            IR <= imemOutput;
            
    end
    
    // Data memory
    (* ram_init_file = INIT_MIF *)
    
    reg [(WORD_SIZE - 1):0] dmem[(DMEM_WORDS - 1):0];
    reg [(WORD_SIZE - 1):0] MAR, MDR;
    wire [(WORD_SIZE - 1):0] dmemOutput = WrMem ? BUS_NOSIG : MDR;
    
  // Hook up MAR to MDR and update each clock
    always @(posedge clk) begin
        if (reset) begin
            MAR <= {WORD_SIZE{1'bX}};
            MDR <= {WORD_SIZE{1'bX}};
        end else begin 
            if (LdMAR)
                MAR <= bus;
            if (LdIR)
                IR <= imemOutput;
        if (WrMem && !reset) begin
            if (MAR == ADDR_HEX)
                HEXout <= bus;
            else if (MAR == ADDR_LEDG)
                //LEDGout <= bus; DEBUG
                HEXout <= bus;
            else if (MAR == ADDR_LEDR)
                //LEDRout <= bus; DEBUG
                HEXout <= bus;
            else 
                dmem[(MAR[(MEM_ADDR_BITS - 1):0] >> MEM_WORD_OFFSET)] <= bus;
            end if (MAR == ADDR_KEY)
                MDR <= {28'b0, KEY};
            else if (MAR == ADDR_SWITCH)
                MDR <= {12'b0, SWITCH}; 
            else
                MDR <= dmem[(MAR[(MEM_ADDR_BITS - 1):0] >> MEM_WORD_OFFSET)]; 
        end
    end

    // ALU
    reg signed [(MEM_ADDR_BITS - 1):0] A, B, ALUout;
    reg [(OP_BITS - 1):0] ALUfunc;
    
    // Actual ALU logic
    always @(posedge clk) begin
        if (LdA)
            A <= bus;
        else if (LdB)
            B <= bus;
        
        case (ALUfunc)
            OP2_SUB: ALUout <= (A - B);
            OP2_ADD: ALUout <= (A + B);
            OP2_MLT: ALUout <= (A * B);
            OP2_DIV: ALUout <= (A / B);
            OP2_NOT: ALUout <= ~A;
            OP2_AND: ALUout <= (A & B);
            OP2_OR: ALUout <= (A | B);
            OP2_XOR: ALUout <= (A ^ B);
            OP2_SUL: ALUout <= (A << B);
            OP2_SSL: ALUout <= (A <<< B);
            OP2_SUR: ALUout <= (A >> B);
            OP2_SSR: ALUout <= (A >>> B);
            OP2_EQ: ALUout <= (A == B);
            OP2_NEQ: ALUout <= (A != B);
            OP2_LT: ALUout <= (A < B);
            OP2_LEQ: ALUout <= (A <= B);
            default: ALUout <= BUS_NOSIG;
        endcase
    end
    
    // Hook up ALU to bus
    assign bus = DrALU ? ALUout : BUS_NOSIG;
    
    // Instruction parsing
    wire [(OP_BITS - 1):0] op1, op2;
    wire [(REG_BITS - 1):0] rx, ry, rz;
    wire [(IMM_SIZE - 1):0] imm;
    
    // Below is parameterized assuming 32-bit
    assign op1 = IR[31:27];
    assign rx = IR[26:22];
    assign ry = IR[21:17];
    assign rz = IR[16:12];
    assign imm = IR[16:0];
    assign op2 = IR[4:0];
    
    // State machine
    reg [(STATE_BITS - 1):0] state, nextState;
    
    parameter [(STATE_BITS - 1):0] 
        S_FETCH0 = {(STATE_BITS) {1'b0}},
        S_FETCH1 = S_FETCH0 + 1'b1,
        S_DECOD0 = S_FETCH1 + 1'b1,
        S_ERROR0 = 5'b11111;
        
    always @(state or op1 or op2 or rx or ry or rz) begin
        {LdPC, DrPC, IncPC} = {1'b0, 1'b0, 1'b0};
        {WrMem, DrMem, LdMAR} = {1'b0, 1'b0, 1'b0};
        {WrReg, DrReg, regSel} = {1'b0, 1'b0, {(REG_BITS) {1'b0}}};
        LdIR = 1'b0;
        DrOff = 1'b0;
        {LdA, LdB, DrALU, ALUfunc} = {1'b0, 1'b0, 1'b0, {(OP_BITS) {1'b0}}};
        nextState = (state + 1'b1);
        
        if (reset)
            state <= S_FETCH0;
        
        // State machine does debug test for now
        case (state)
            S_FETCH0: begin
                LEDGout <= 7'b11111111;
                LEDRout <= 7'b00000000;
                state <= nextState;
            end
            
            S_FETCH1: begin
                LEDGout <= 7'b00000000;
                LEDRout <= 7'b11111111;
                state <= nextState;
            end
            
            S_DECOD0: begin
                LEDGout <= 7'b11111111;
                LEDRout <= 7'b11111111;
                state <= nextState;
            end
            
            S_ERROR0: begin
                // Remain in error state
                LEDGout <= 7'b00000000;
                LEDRout <= 7'b00000000;
            end
        endcase
    end
endmodule
