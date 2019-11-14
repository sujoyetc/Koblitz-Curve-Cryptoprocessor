//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    15:36:01 10/06/2014 
// Design Name: 
// Module Name:    ram_verilog 
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
module ram_verilog
(
	input [15:0] dina,
	input [7:0] addra,
	input wea, clka,
	output reg [15:0] douta
);

	// Declare the RAM variable
	reg [15:0] ram[255:0];
	
	// Variable to hold the registered read address
		
	always @ (posedge clka)
	begin
	// Write
		if (wea)
		begin	ram[addra] <= dina; douta<=dina; end
		//	addr_reg <= addr;
		else 
		begin	ram[addra] <= ram[addra]; douta<=ram[addra]; end
	end
		
endmodule

