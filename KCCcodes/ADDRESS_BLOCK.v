//////////////////////////////////////////////////////////////////////////////////
// Company: COSIC KU Leuven
// Engineer: Sujoy Sinha Roy
// 
// Create Date:    12:22:24 07/23/2014 
// Design Name: 
// Module Name:    ADDRESS 
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
module addressb(clk, RdOffset, WtOffset, SCOffset, suspend,
					ROMBaseSel, BaseSel, OffsetSel, Baseen, address_carryin, 
					address);
input clk;
input [4:0] RdOffset;
input [5:0] WtOffset;

input [4:0] SCOffset;
input suspend;

input [3:0] ROMBaseSel;
input [2:0] BaseSel;
input OffsetSel;
input [1:0] Baseen;
input address_carryin;		// One bit carry input for address.


output [7:0] address;


reg [7:0] RdBase1, RdBase2;
wire [7:0] BasePointer, BaseAddress;
wire [5:0] Offset;

ROM2 BASEPOINTER(ROMBaseSel, BasePointer);

always @(posedge clk)
begin
	if(Baseen==2'd1)
		RdBase1 <= BasePointer;
	else 	
		RdBase1 <= RdBase1;
end
always @(posedge clk)
begin
	if(Baseen==2'd2)
		RdBase2 <= BasePointer;
	else 	
		RdBase2 <= RdBase2;
end

assign BaseAddress = (BaseSel==3'd0) ? RdBase1
                    :(BaseSel==3'd1) ? RdBase2
						  //:(BaseSel==3'd2) ? 8'd208
                    :(BaseSel==3'd2) ? 8'd234
						  :(BaseSel==3'd3) ? BasePointer
						//:(BaseSel==3'd4) ? 8'd45
						  //:(BaseSel==3'd4) ? 8'd217
                    :(BaseSel==3'd4) ? 8'd243
						  :(BaseSel==3'd5) ? 8'd63
						  :(BaseSel==3'd6) ? 8'd72
						  : 8'd81;						  
						  
assign Offset = (suspend==1'b0) ? {1'b0,SCOffset} 
					:(OffsetSel) ? WtOffset 
					: {1'b0,RdOffset};						  
assign address = BaseAddress + Offset + address_carryin; 

endmodule
