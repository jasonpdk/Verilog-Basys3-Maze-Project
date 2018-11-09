`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10.10.2018 14:30:32
// Design Name: 
// Module Name: VGASync_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module VGASync_tb();
   
    localparam T = 20;
    reg clk, rst;
    //wire Hsync, Vsync;
    
    VGATop uut(.clk(clk), .rst(rst));
    
    //Clock
    always 
    begin
        clk = 1'b1;
        #1;
        clk = 1'b0;
        #1;
    end
    
    // Reset
    initial
    begin
        rst = 1'b0;
        #(T);
        rst = 1'b1;
        #(T);
        rst = 1'b0;
    end
endmodule
