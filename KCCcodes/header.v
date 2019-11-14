//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:00:11 07/17/2014 
// Design Name: 
// Module Name:    header 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////
module binary_adder(a, b, c);
input [15:0] a, b;
output [15:0] c;

assign c = a ^ b;
endmodule

///////////////////////////////////////////////////////////////////
module adder_subtracter(a, b, carry_in, add_sub, s, carry_out);
input [15:0] a, b;
input carry_in;
input add_sub; 			// This is high for subtraction

output [15:0] s;
output carry_out;

wire [15:0] w1;
wire [16:0] w2;

assign w1 = (add_sub==0) ? b : ~b;
assign w2 = a + w1 + (carry_in ^ add_sub);
assign carry_out = w2[16] ^ add_sub;
assign s = w2[15:0];
endmodule

///////////////////////////////////////////////////////////////////
module mux2(in1, in2, sel, out);
input [15:0] in1, in2;
input sel;
output [15:0] out;

assign out = (sel) ? in2 : in1;

endmodule
