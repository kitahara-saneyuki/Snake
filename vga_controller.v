`timescale 1ns / 1ps
module vga_controller (pixel_clk,HS,VS,hcounter,vcounter,blank);

	input pixel_clk;
	output reg HS, VS;
	output reg blank;
	output reg [10:0] hcounter, vcounter;

	parameter HMAX = 800;
	parameter VMAX = 525;
	parameter HLINES = 640;
	parameter HFP = 648;
	parameter HSP = 744;
	parameter VLINES = 480;
	parameter VFP = 482;
	parameter VSP = 484;
	parameter SPP = 0;

	wire video_enable;
	
	always@(posedge pixel_clk)begin
		blank <= ~video_enable; 
	end
	
	always@(posedge pixel_clk)begin
		if(hcounter == HMAX) hcounter <= 0;
		else hcounter <= hcounter + 1'b1;
	end
	
	always@(posedge pixel_clk)begin
		if(hcounter == HMAX) begin
			if(vcounter == VMAX) vcounter <= 0;
			else vcounter <= vcounter + 1'b1; 
		end
	end
	
	always@(posedge pixel_clk)begin
		if(hcounter >= HFP && hcounter < HSP) HS <= SPP;
		else HS <= ~SPP; 
	end

	always@(posedge pixel_clk)begin
		if(vcounter >= VFP && vcounter < VSP) VS <= SPP;
		else VS <= ~SPP; 
	end
	
	assign video_enable = (hcounter < HLINES && vcounter < VLINES) ? 1'b1 : 1'b0;
endmodule