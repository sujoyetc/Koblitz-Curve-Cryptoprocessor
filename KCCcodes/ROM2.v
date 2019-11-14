//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    12:35:13 07/23/2014 
// Design Name: 
// Module Name:    ROM2 
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
module ROM2(address, dout);
input [3:0] address;
output reg [7:0] dout;

always @*
begin
	case(address)
	4'd0 : dout <= 8'd00;
	4'd1 : dout <= 8'd18;
	4'd2 : dout <= 8'd36;
	4'd3 : dout <= 8'd54;
	4'd4 : dout <= 8'd72;
	4'd5 : dout <= 8'd90;
	4'd6 : dout <= 8'd108;
	4'd7 : dout <= 8'd126;
	4'd8 : dout <= 8'd144;
	4'd9 : dout <= 8'd162;	
	4'd10 : dout <= 8'd180;
	4'd11 : dout <= 8'd198;
	4'd12 : dout <= 8'd216;
	4'd13 : dout <= 8'd234;	
	default : dout <= 8'd0;
	endcase
end	
endmodule
