//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:07:00 09/09/2014 
// Design Name: 
// Module Name:    top_primitives 
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
module top_primitives(clk, rst, mode,
							ALU_control_group1, sel4, sel5, ROM_sel, wea, BaseSel,
							RdOffset, WtOffset, OffsetSel, done, state);
input clk, rst;
input [1:0] mode;		// mode= 0 for multiplication, 1 for squaring, 2 for addition

output [8:0] ALU_control_group1;
output sel4, sel5;
output [2:0] ROM_sel;
output wea; 
output [2:0] BaseSel;
output [4:0] RdOffset;
output [5:0] WtOffset;
output OffsetSel;
output done;

// tst
output [5:0] state;

wire en1, en2, clr1, clr2, sel3, sel6, mask, Cen, Cshift, wea;
wire [1:0] BaseSel1;
wire [2:0] BaseSel;
assign BaseSel = {1'b0, BaseSel1};

primitives	 prim(clk, rst, mode,
						en1, en2, clr1, clr2, sel3, sel6, mask, Cen, Cshift, wea, BaseSel1,
					   sel4, sel5, OffsetSel, RdOffset, WtOffset, ROM_sel, done, state);

assign ALU_control_group1 = {en1, en2, clr1, clr2, sel3, sel6, mask, Cen, Cshift};

endmodule
