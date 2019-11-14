//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    21:56:40 08/04/2014 
// Design Name: 
// Module Name:    inversion_rom 
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
module inversion_rom(address, dout);
input [3:0] address;
output reg [7:0] dout;

always @*
begin
	case(address)
	4'd0 : dout <= 8'd1;
	4'd1 : dout <= 8'd2;
	4'd2 : dout <= 8'd4;
	4'd3 : dout <= 8'd8;
	4'd4 : dout <= 8'd1;
	4'd5 : dout <= 8'd17;
	4'd6 : dout <= 8'd1;
	4'd7 : dout <= 8'd35;
	4'd8 : dout <= 8'd70;
	4'd9 : dout <= 8'd1;
	4'd10 : dout <= 8'd141;	
	default : dout <= 8'd1;
	endcase
end
	
endmodule
