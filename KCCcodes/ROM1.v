//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    17:43:09 07/22/2014 
// Design Name: 
// Module Name:    ROM1 
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
module ROM1(address, dout);
input [2:0] address;
output reg [15:0] dout;

always @*
begin
	case(address)
	3'd0 : dout <= 16'd0;
	3'd1 : dout <= 16'd1;
	3'd2 : dout <= 16'd32;
	3'd3 : dout <= 16'd128;		
	3'd4 : dout <= 16'd4096;
	default : dout <= 16'd0;
	endcase
end	
endmodule
