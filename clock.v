module clk1khz(clk, oclk);
	input clk;
	output reg oclk;
	reg [15:0] count; // 65535

	initial 
		count=1'b0;
		
	always @ (posedge clk) begin
		count<=count+ 1'b1;
		if (count >= 16'b1100001101010000) //50k0
			oclk<=1'b1;
		else
			oclk<=1'b0;
	end
endmodule