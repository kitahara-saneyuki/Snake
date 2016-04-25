`timescale 1ns / 1ps
module BCD (input [15:0] binary, output reg [15:0] BCDcode);
	
	reg [3:0] Thousands;
	reg [3:0] Hundreds;
	reg [3:0] Tens;
	reg [3:0] Ones;
		
	integer i;
	
	always @ (binary)
	begin

		Thousands = 4'd0;
		Hundreds = 4'd0;
		Tens = 4'd0;
		Ones = 4'd0;
	
		for (i=10; i>=0; i = i-1)
		begin
			if (Thousands >= 5)
				Thousands = Thousands +3;
			if (Hundreds >= 5)
				Hundreds = Hundreds + 3;
			if (Tens >= 5)
				Tens = Tens + 3;
			if (Ones >= 5)
				Ones = Ones + 3;
			Thousands = Thousands << 1;
			Thousands[0] = Hundreds[3];
			Hundreds = Hundreds << 1;
			Hundreds[0] = Tens[3];
			Tens = Tens << 1;
			Tens[0] = Ones[3];
			Ones = Ones << 1;
			Ones[0] = binary[i];
		end
		BCDcode = {Thousands, Hundreds, Tens, Ones};
	end
endmodule