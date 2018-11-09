`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Basic Maze 
// A circle on the screen is controlled by the four buttons on the board. The circle stops moving when it hits the maze wall 
// or the edge of the screen. A square at the end changes colour when the circle is inside it.
// Jason Keane
// 2018
//////////////////////////////////////////////////////////////////////////////////

module Project
(
    input  wire clk, rst,
    input  wire vid_on,
    input  wire [10:0] row, col,
    output wire [3:0] red, green, blue,
    input wire button_left, button_right, button_top, button_bottom
);

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Constants
localparam SCREEN_MAX_X  = 640; // x, y coordinates of screen (0,0) to (639,480)
localparam SCREEN_MAX_Y  = 480; // (x is pixel column, y is pixel row)

// Maze Wall
localparam mazeWallWidth = 3;

//vertical component
localparam verticalMazeX_L = 100;
localparam verticalMazeY_T = 0;
localparam verticalMazeY_B = 380;

// horizontal component
localparam horizontalMazeX_L = 100;
localparam horizontalMazeX_R = 640;
localparam horizontalMazeY_T = 380;

// Square
localparam SQUARE_X_L  = 540;   // Square locaton left & right x coordinates
localparam SQUARE_X_R  = 640;
localparam SQUARE_Y_T  = 380;   // Square top & bottom y coordinates
localparam SQUARE_Y_B  = 480;
localparam SQUARE_SIZE = 100;   // Square size

// Circle data
localparam CIRCLE_SIZE = 12;    // Circle size
reg [9:0] circle_x_l_reg  = 44;   // Circle locaton left & right x coordinates
reg [9:0] circle_x_l_next  = 44;
wire [9:0] circle_x_l;

reg [9:0] circle_x_r_reg  = 55;
reg [9:0] circle_x_r_next  = 55;
wire [9:0] circle_x_r;

reg [9:0] circle_y_t_reg  = 30;   // Circle top & bottom y coordinates
reg [9:0] circle_y_t_next  = 30;
wire [9:0] circle_y_t;

reg [9:0] circle_y_b_reg  = 42;
reg [9:0] circle_y_b_next  = 42;
wire [9:0] circle_y_b;

// limits for collision detection
integer rightLimit = 640;
integer topLimit = 0;
integer leftLimit = 0;
integer bottomLimit = 480;

// Colours
localparam YELLOW    = 12'b111111110000;
localparam RED       = 12'b111100000000;
localparam BLUE      = 12'b000000001111;
localparam CYAN      = 12'b000011111111;
localparam MAGENTA   = 12'b111100001111;
localparam BLACK     = 12'b000000000000;
localparam WHITE     = 12'b111111111111;
localparam GREEN     = 12'b000011110000;

// Signals
reg [11:0] colour_reg;
reg [3:0] red_reg, green_reg, blue_reg;
wire [3:0] red_next, green_next, blue_next;
wire maze_wall__on, square_on, circle_on;          // On signals for shape objects
wire [2:0] rectangle_rgb, square_rgb, circle_rgb; // RGB values for shape objects
wire refresh_en;                                  // Signal synched with screen refresh rate (same as vsync)
wire [3:0] rom_addr, rom_col;                     // ROM for pixel map of a circle
reg  [11:0] rom_data;                             // Circle pixel map data
wire rom_bit;                                     // Bit read from ROM
localparam SPEED = 2;

// letters signals
wire [3:0] letter_rom_addr, letter_rom_col;                     // ROM for pixel map of a circle
reg  [17:0] letter_rom_data;                             // Circle pixel map data
wire letter_rom_bit;

// Store a 2D circle image in ROM, size 12 bits both directions
always @*
case (rom_addr)
   4'h0: rom_data = 12'b000011110000;
   4'h1: rom_data = 12'b000111111000;
   4'h2: rom_data = 12'b001111111100;
   4'h3: rom_data = 12'b011111111110;
   4'h4: rom_data = 12'b011111111110;
   4'h5: rom_data = 12'b111111111111;
   4'h6: rom_data = 12'b111111111111; // Middle
   4'h7: rom_data = 12'b111111111111;
   4'h8: rom_data = 12'b011111111110;
   4'h9: rom_data = 12'b011111111110;
   4'ha: rom_data = 12'b001111111100;
   4'hb: rom_data = 12'b000111111000;
   4'hc: rom_data = 12'b000011110000;
endcase

// letters data
always @*
case (letter_rom_addr)
   4'h0: letter_rom_data = 18'b000000000000000000;
   4'h1: letter_rom_data = 18'b000000000000000000;
   4'h2: letter_rom_data = 18'b011000011011111111;
   4'h3: letter_rom_data = 18'b001100011011111111;
   4'h4: letter_rom_data = 18'b000110011000011000;
   4'h5: letter_rom_data = 18'b000011011000011000;    
   4'h6: letter_rom_data = 18'b000001111000011000; // Middle
   4'h7: letter_rom_data = 18'b000001111000011000;
   4'h8: letter_rom_data = 18'b000011011000011000;
   4'h9: letter_rom_data = 18'b000110011000011000;
   4'ha: letter_rom_data = 18'b001100011000011111;
   4'hb: letter_rom_data = 18'b011000011000011111;
   4'hc: letter_rom_data = 18'b000000000000000000;
   4'hd: letter_rom_data = 18'b000000000000000000;
   4'he: letter_rom_data = 18'b000000000000000000;
   4'hf: letter_rom_data = 18'b000000000000000000;    
endcase

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Create refresh enable signal for screen refresh (every 480 y counts, alternatively could use vsync here)
assign refresh_en = (row == SCREEN_MAX_Y + 1) && (col == 0);

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Logic to output what is currently on a pixel: rectangle / square / circle, and assign a colour to each
// Rectangle is on if current pixel is within rectangle location
assign maze_wall_on = ((col >= verticalMazeX_L && col <= verticalMazeX_L+mazeWallWidth) && (row >= verticalMazeY_T && row <= verticalMazeY_B)) || ((col >= horizontalMazeX_L && col <= horizontalMazeX_R) && (row >= horizontalMazeY_T && row <= horizontalMazeY_T+mazeWallWidth));

// Circle is on if current pixel is within the circle's square location
assign circle_sq_on = (col >= circle_x_l_reg) && (col <= circle_x_r_reg) &&
                      (row >= circle_y_t_reg) && (row <= circle_y_b_reg);

// Square is on if current pixel is within square location
assign square_on = (col >= SQUARE_X_L) && (col <= SQUARE_X_R) &&
                 (row >= SQUARE_Y_T) && (row <= SQUARE_Y_B);
// The address (row) of the circle image, got by comparing LSBs of current and top y position
assign rom_addr = row[3:0] - circle_y_t_reg[3:0];
// The bit location (col) of the circle image, got by comparing LSBS of the current and top x position
assign rom_col  = col[3:0] - circle_x_l_reg[3:0];
// Store the individual bit
assign rom_bit = rom_data[rom_col];

// The round ball is on if the square is on AND the individual image bit at that location is 1
assign circle_on = circle_sq_on & rom_bit;


assign circle_x_l = circle_x_l_reg;
assign circle_x_r = circle_x_r_reg;
assign circle_y_b = circle_y_b_reg;
assign circle_y_t = circle_y_t_reg;


// letter rom 
reg [9:0] letter_x_l_reg  = 320;
reg [9:0] letter_y_t_reg  = 240;

// square around letters
assign letter_square_on = (col >= letter_x_l_reg) && (col <= letter_x_l_reg+17) &&
                          (row >= letter_y_t_reg) && (row <= letter_y_t_reg+16);
                          
assign letter_rom_addr = row[3:0] - letter_y_t_reg[3:0];
assign letter_rom_col  = col[3:0] - letter_x_l_reg[3:0];
assign letter_rom_bit = letter_rom_data[letter_rom_col];
assign letter_on = letter_square_on & letter_rom_bit;

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Always block to assign a pixel: either background, rectangle, square, circle, or off (black)
always @(posedge clk, posedge rst)
begin
    if(rst)
        colour_reg = BLACK;
    else
    begin
      if(maze_wall_on)
          colour_reg = BLACK;
	  else if(circle_on)
        colour_reg = RED;
      else if(square_on)
      begin
  			if (circle_x_l_reg > SQUARE_X_L)
  				colour_reg = GREEN;
  			else
  				colour_reg = CYAN;
      end
      else if (letter_on)
        colour_reg = BLACK;
      else
        colour_reg = WHITE;
    end
end

// update the position of the next value when the button is pressed
always @*
begin
  circle_x_l_next = circle_x_l_reg;
  circle_y_t_next = circle_y_t_reg;
  circle_y_b_next = circle_y_b_reg;
  circle_x_r_next = circle_x_r_reg;

  if (refresh_en)
    begin
    if (button_bottom == 1'b1 && circle_y_b_reg < bottomLimit)
    begin
      circle_y_t_next = circle_y_t_reg + SPEED;
      circle_y_b_next  = circle_y_t_reg + CIRCLE_SIZE+2;
    end
    
    if (button_top == 1'b1 && circle_y_t_reg > topLimit)
    begin
      circle_y_t_next = circle_y_t_reg - SPEED;
      circle_y_b_next  = circle_y_t_reg + CIRCLE_SIZE - 2;
    end
    
    if (button_left == 1'b1 && circle_x_l_reg > leftLimit)
    begin
      circle_x_l_next = circle_x_l_reg - SPEED;
      circle_x_r_next  = circle_x_l_reg + CIRCLE_SIZE - 3;
    end
    
    if (button_right == 1'b1 && circle_x_r_reg < rightLimit)
    begin
      circle_x_l_next = circle_x_l_reg + SPEED;
      circle_x_r_next  = circle_x_l_reg + CIRCLE_SIZE+1;
    end

	// collision detection
    if (circle_y_t_reg < horizontalMazeY_T+mazeWallWidth)
    begin
      rightLimit = horizontalMazeX_L;
      if (circle_x_r_reg > verticalMazeX_L)
      begin
        topLimit = horizontalMazeY_T+mazeWallWidth;
      end
      else
      begin
        topLimit = 0;
      end
    end
    else
    begin
      rightLimit = SCREEN_MAX_X;
      topLimit = 0;
    end
  end
end

// Assign logic for red, green & blue colours
assign red_next   = colour_reg[11:8];
assign green_next = colour_reg [7:4];
assign blue_next  = colour_reg [3:0];

// Register the red, green & blue colour values before output
always@(posedge clk, posedge rst)
   begin
       if(rst)
           begin
               red_reg   <= 4'd0;
               green_reg <= 4'd0;
               blue_reg  <= 4'd0;
               
               // reset ball to initial place
               circle_x_r_reg  <= 55;
               circle_x_l_reg  <= 44;
               circle_y_t_reg  <= 30;
               circle_y_b_reg  <= 42;
           end
        else
           begin
               red_reg   <= red_next;
               green_reg <= green_next;
               blue_reg  <= blue_next;

               // update the reg to the next
               circle_x_r_reg <= circle_x_r_next;
               circle_y_t_reg <= circle_y_t_next;
               circle_y_b_reg <= circle_y_b_next;
               circle_x_l_reg <= circle_x_l_next;                                 
           end
   end

// Assign outputs
assign red   = red_reg;
assign green = green_reg;
assign blue  = blue_reg;

endmodule
