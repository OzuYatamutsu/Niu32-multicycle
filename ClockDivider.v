module ClockDivider(input clkIn, output clkOut);
    parameter divider = 25000000; // 25000000 w/CLOCK_50 = 1 Hz (posedge, negedge)
    parameter counterSize = 32; // Must be at least ceil(log^2(divider))
    
    reg [(counterSize - 1):0] counter;
    reg onEdge = 0;

    always @(posedge clkIn) begin
        counter = (counter + 1);
        
        if (counter == divider) begin
            onEdge <= ~onEdge;
            counter <= 0;
        end
    end

    assign clkout = onEdge;
endmodule
