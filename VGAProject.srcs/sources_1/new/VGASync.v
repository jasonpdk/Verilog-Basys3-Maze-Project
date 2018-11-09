`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Michelle Lynch
// 2018
//////////////////////////////////////////////////////////////////////////////////

module VGASync
(
    input  wire clk25, rst,
    output reg  hsync, vsync, vid_on,
    output wire [10:0] row, col
);

localparam HDISP = 640;
localparam HFP = 16;
localparam HPW = 96;
localparam HLIM = 800;

localparam VDISP = 480;
localparam VFP = 10;
localparam VPW = 2;
localparam VLIM = 525;

reg [10:0] hcount = 0;
reg [10:0] vcount = 0;

always@(posedge clk25)
begin
    if(hcount < HLIM - 1)
        hcount <= hcount + 1;
    else
        begin
            hcount <= 0;
            if(vcount < VLIM - 1)
                vcount <= vcount + 1;
            else
                vcount <= 0;
        end
    
    if(hcount > (HDISP + HFP) && hcount <= (HDISP + HFP + HPW))
        hsync <= 0;
    else
        hsync <= 1;
                 
    if(vcount >= (VDISP + VFP) && vcount < (VDISP + VFP + VPW))
        vsync <= 0;
    else
        vsync <= 1;
    
    if (hcount < HDISP && vcount < VDISP)
        vid_on <= 1;
     else
        vid_on <= 0;        

end

assign row = vcount;
assign col = hcount;

endmodule
