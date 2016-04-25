`timescale 1ns / 1ps
module Snake(
	input up, 
	input down, 
	input left, 
	input right, 
	input reset, 
	input clk,
	
	output reg B, 
	output reg R, 
	output reg G,
	output VS, 
	output HS,  
	output [3:0] AN, 
	
	output [6:0] seven,
	input speed);
	
	wire [10:0] hcount, vcount;
	wire blank;
	wire snakehead;
	reg [4:0] wall;
	wire [15:0] BCDcode;
	wire [3:0] smallbin;
	wire [15:0] scorewire;
	wire clk1khz;
	reg [5:0] i;
	
	reg [25:0] snakeseg;
	reg [15:0] score;
	reg [10:0] foodx, foody; 
	
	reg [15:0] foodxcount, foodycount;
	reg [10:0] x, y;
	reg [10:0] x1 [0:25];
	reg [10:0] y1 [0:25];

	reg slow_clk;
	reg [4:0] state, next_state;
	reg d_up, d_down, d_left, d_right;
	reg lose; 
	reg eaten;
	reg dead;
	reg is_seg;
	reg is_wall;

	parameter S_IDLE = 0;
	parameter S_UP = 1;
	parameter S_DOWN = 2;
	parameter S_LEFT = 4;
	parameter S_RIGHT = 8;

	// fast clk, for VGA
	parameter N = 2;
	reg clk_25Mhz;
	reg [N-1:0] count;
	always @ (posedge clk) begin
		count <= count + 1'b1;
		clk_25Mhz <= count[N-1];
	end

	assign scorewire = score;
	
	// g) score display
	clk1khz 		clock(clk, clk1khz);
	BCD 			bcd(scorewire, BCDcode);
	big2small 	long2short(BCDcode, smallbin, AN, clk1khz);
	bin27 		bin2seven(smallbin, seven);

	initial begin
		eaten = 0;
		dead = 0;
		is_seg = 0;
		is_wall = 0;
		lose = 1'b0;
		score = 16'b0;
		foodx = 9'd400;
		foody = 8'd400;
		foodxcount = 9'd400;
		foodycount = 8'd400;
		x = 11'd100; 
		y = 11'd100;
		d_up = 0; d_down = 0; d_left = 0; d_right = 0;
	end

	// position update clock, a.k.a "speed" of the snake.
	reg [25:0] slow_count;
	always @ (posedge clk) begin
		slow_count = slow_count + 1'b1;

		if (speed == 1'd0) begin
			slow_clk = slow_count[24];
		end
		else if (speed == 1'd1) begin
			slow_clk = slow_count[23];
		end
	end
	
	always @ (posedge clk)begin
		// b) reset button
		if (reset == 1'b1) begin
			d_up =0; d_down=0; d_left=0; d_right =0;
			foodx = foodxcount;
			foody = foodycount;
			score = 0;
			lose = 0;
			dead = 0;
			state = next_state;
		end
		// f) as losing, it should never move again.
		else if (lose==1'b1) begin
			d_up =0; d_down=0; d_left=0; d_right =0;
			x = x;
			y = y;
			state=next_state;
		end
		// a) update the snake direction according to the button
		else begin
			foodxcount = (foodxcount + 5'd20) % 10'd600;
			foodycount = (foodycount + 5'd20) % 9'd420;
			// you cannot move 180 degrees...
			if (up==1'b1 && d_down == 1'b0) begin
				d_up =1; d_down=0; d_left=0; d_right =0; 
				state = next_state;
			end
			else if (down==1'b1 && d_up== 1'b0) begin
				d_up =0; d_down=1; d_left=0; d_right =0; 
				state = next_state;
			end
			else if (left==1'b1 && d_right==1'b0) begin
				d_up =0; d_down=0; d_left=1; d_right =0; 
				state = next_state;
			end
			else if (right==1'b1 && d_left==1'b0) begin
				d_up =0; d_down=0; d_left=0; d_right =1; 
				state = next_state;
			end
			else
				state=state;
		end

		// judgement of each pixel -- whether it is in a segment of snake.
		for (i = 1; i<=25; i = i+1)
			if (score >= i)
				snakeseg[i] = ~blank & (hcount >=x1[i]+1 & hcount <= x1[i] + 19 &vcount >= y1[i]+1 & vcount <= y1[i]+19);

		// f) placement of walls
		wall[1]= ~blank & (hcount >= 1 & hcount <= 639 & vcount >= 1 & vcount <= 19);
		wall[2]= ~blank & (hcount >= 1 & hcount <= 639 & vcount >= 461 & vcount <= 479);
		wall[3]= ~blank & (hcount >= 1 & hcount <= 19 & vcount >= 1 & vcount <= 479);
		wall[4]= ~blank & (hcount >= 621 & hcount <= 639 & vcount >= 1 & vcount <= 479);

		// f) judgement of death
		for (i = 1; i<=25; i = i+1)
			if (snakehead && snakeseg[i])
				lose=1'b1;
		for (i = 1; i<=4; i = i+1)
			if (snakehead && wall[i])
				lose=1'b1;

		// e) increment of snake length as food eaten
		// c) semi-random placement of food
		if (snakehead && food) begin
			score = score+1'd1;
			foodx = foodxcount;
			foody = foodycount;
		end
		
		// handle exception: 
		// what if the food appears at the position of snake itself || walls?
		for (i = 1; i<=25; i = i+1)
			if (food && snakeseg[i])
				eaten = 1;
		for (i = 1; i<=4; i = i+1)
			if (food && wall[i])
				eaten = 1;
		if(eaten) begin
			foodx = foodxcount;
			foody = foodycount;
			eaten = 0;
		end

		// coloring
		for (i = 1; i<=25; i = i+1)
			if (snakeseg[i])
				is_seg = 1;
		for (i = 1; i<=4; i = i+1)
			if (wall[i])
				is_wall = 1;

		if (is_wall||food||((snakehead || is_seg)&&~lose))
			B = 1'b1;
		else
			B = 0;
		if (is_wall||food||((snakehead || is_seg)&&~lose))
			G = 1'b1;
		else
			G = 0;
		if (is_wall||food||(snakehead || is_seg))
			R = 1'b1;
		else
			R = 0;
		is_seg = 0;
		is_wall = 0;
	end
	
	// d) time update
	always @(posedge slow_clk) begin
		if (reset == 1'b1) begin
			x = 11'd100; y = 11'd100;
		end
		
		// move the snake by 1 unit length
		if (state == S_UP || state == S_DOWN || state == S_LEFT || state == S_RIGHT) begin
			for (i = 25; i>1; i = i-1) begin
				x1[i] = x1[i-1];
				y1[i] = y1[i-1];
			end
			x1[1] = x; y1[1] = y;
		end
		
		// update the position of the snake by its direction
		case (state)
			S_UP:
				y = y - 11'd20;
			S_DOWN:
				y = y + 11'd20;
			S_LEFT:
				x = x - 11'd20;
			S_RIGHT:
				x = x + 11'd20;
		endcase
		next_state = {d_right , d_left, d_down, d_up};
	end

	vga_controller vc(.pixel_clk(clk_25Mhz), 
							.HS(HS), 
							.VS(VS), 
							.hcounter(hcount), 
							.vcounter(vcount), 
							.blank(blank));
	assign snakehead = ~blank & (hcount >= x & hcount <= x+20 & vcount >= y & vcount <= y+20);
	assign food= ~blank & (hcount >=foodx & hcount <= foodx + 20 &vcount >= foody & vcount <= foody + 20);
endmodule