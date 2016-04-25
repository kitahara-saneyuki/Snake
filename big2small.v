`timescale 1ns / 1ps
module big2small(bigbin, smallbin, AN, clk1khz);
	input [15:0] bigbin;
	output reg [3:0] smallbin;
	output reg [3:0] AN;
	input clk1khz; 
	reg [1:0] count; 
	
	initial begin
		AN = 0;
		smallbin = 0;
		count = 1'b0;
	end
	
	always @(posedge clk1khz) begin
		case (count)
		2'b00: begin 
			AN=4'b1110;
			smallbin = bigbin[3:0];
		end
		2'b01: begin 
			AN=4'b1101;
			smallbin=bigbin[7:4];
		end
		2'b10: begin 
			AN=4'b1011;
			smallbin=bigbin[11:8];
		end
		2'b11: begin 
			AN=4'b0111;
			smallbin=bigbin[15:12];
		end
		default: begin
			AN=4'b1111;
			smallbin=0;
		end
		endcase
		count= count+1'b1;
	end
endmodule