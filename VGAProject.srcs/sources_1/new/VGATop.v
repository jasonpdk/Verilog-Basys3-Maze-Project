`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Michelle Lynch
// 2018
//////////////////////////////////////////////////////////////////////////////////

module VGATop
(
    input wire clk, rst,
    output wire Hsync, Vsync,
    output wire [3:0] vgaRed, vgaGreen, vgaBlue,
    input wire button_left, button_right, button_top, button_bottom
);

wire clk25;
wire vid_on;
wire [3:0] red, green, blue;
wire [11:0] rgb;
wire [10:0] row, col;


clk_wiz_0 i_clock (
    .clk_out1(clk25), .reset(rst), .clk_in1(clk)
    );

VGASync i_vga_sync (
    .clk25(clk25), .rst(rst), 
    .hsync(Hsync), .vsync(Vsync), .vid_on(vid_on),
    .row(row), .col(col)
    );
    
Project i_vga_project (
    .clk(clk25), .rst(rst),
    .vid_on(vid_on),
    .row(row), .col(col), 
    .red(red), .green(green), .blue(blue),
    .button_left(button_left), .button_right(button_right), .button_top(button_top), .button_bottom(button_bottom) 
    );
   
   assign vgaRed   = (vid_on) ? red   : 4'b0;
   assign vgaGreen = (vid_on) ? green : 4'b0;
   assign vgaBlue  = (vid_on) ? blue  : 4'b0;
   
endmodule