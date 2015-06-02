module Niu32_multicycle(SW,KEY,LEDR,LEDG,HEX0,HEX1,HEX2,HEX3,CLOCK_50);
	 input  [9:0] SW;
    input  [3:0] KEY;
    input  CLOCK_50;
    output [9:0] LEDR;
    output [7:0] LEDG;
    output [6:0] HEX0,HEX1,HEX2,HEX3;
	 
	 assign HEX0 = 7'b1111111; // Debug
	 assign HEX1 = 7'b1111111; // Debug
	 assign HEX2 = 7'b0000000; // Debug
	 assign HEX3 = 7'b0000000; // Debug
	 assign LEDG = 8'b1010101; // Debug
	 assign LEDR = 10'b1010101010; // Debug
endmodule
