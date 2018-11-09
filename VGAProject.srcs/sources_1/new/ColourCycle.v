`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Michelle Lynch
// 2017
//////////////////////////////////////////////////////////////////////////////////

module VGAColourCycle(
    input clk, rst,
    input wire [10:0] row, col,
    output wire [3:0] red, green, blue
    );

reg [11:0] colour = 0;                      // 12-bit register for colour
reg [31:0] colour_change_count = 0;         // Counter to control colour change frequency
reg [3:0]  red_reg, green_reg, blue_reg; 
wire [3:0] red_next, green_next, blue_next;

// Always block to change the colour
always@(posedge clk, posedge rst)
    if(rst)
        begin
            // On reset, set colour to black & reset counter
            colour <= 12'd0;
            colour_change_count <= 32'd0;
        end
    else
        begin
            // Change the colour when the counter reaches the desired count
            // & reset the counter, otherwise just increment the counter
            if(colour_change_count == 32'b1 << 26)
                begin
                    colour <= colour + 1;
                    colour_change_count <= 32'd0;
                end
            else
                colour_change_count <= colour_change_count + 1;
            end
     
 // Assign the logic for red, green & blue colours
 assign red_next   = colour[11:8];
 assign green_next = colour[7:4];
 assign blue_next  = colour[3:0];
     
 // Register the red, green & blue colour values before output
always@(posedge clk, posedge rst)
   begin
       if(rst)
           begin
               red_reg   <= 4'd0;
               green_reg <= 4'd0;
               blue_reg  <= 4'd0;
           end
        else
           begin
               red_reg   <= red_next;
               green_reg <= green_next;
               blue_reg  <= blue_next;
           end
   end
        
// Assign outputs 
assign red   = red_reg;
assign green = green_reg;
assign blue  = blue_reg;
        
endmodule
