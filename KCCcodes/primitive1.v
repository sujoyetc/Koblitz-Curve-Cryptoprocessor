//////////////////////////////////////////////////////////////////////////////////
// Company: COSIC KU Leuven	
// Engineer: Sujoy Sinha Roy
// 
// Create Date:    20:21:21 07/26/2014 
// Design Name: 
// Module Name:    primitives 
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

module primitives(clk, rst, mode,
						en1, en2, clr1, clr2, sel3, sel6, mask, Cen, Cshift, wea, BaseSel,
					   sel4, sel5, OffsetSel, RdOffset, WtOffset, ROM_sel, done, state);

input clk, rst;
input [1:0] mode;		// mode= 0 for multiplication, 1 for squaring, 2 for addition

output reg en1, en2, clr1, clr2, sel3, sel4, sel5, sel6, mask, Cen, Cshift, wea;
output reg [2:0] ROM_sel;
output reg [1:0] BaseSel;
output reg OffsetSel;
output [4:0] RdOffset;
output [5:0] WtOffset;

output done;
output [5:0] state;




reg [5:0] C1;
reg [4:0] C2;
reg C1inc, C2inc, C2init, RdOffsetSel, C1sel;
reg [5:0] state, nextstate;
reg [3:0] C2initR;
reg C1rst, C2rst;
reg flag;

wire [5:0] C1_plus1, C1_wire;
wire [4:0] C1_sub_17, C1_sub_C2, C2_initial, C1_minus18;
wire carry, C1_half, C1_full, C2_full, C1_minus18_carry;

assign {carry, C1_sub_17} = C1_plus1 - 5'd17;
assign C2_initial = (carry) ? 5'd0 : C1_sub_17;
assign C1_wire = (C1sel) ? C1_plus1 : C1;
assign C1_sub_C2 = C1_wire - C2;
assign RdOffset = (RdOffsetSel) ? C1_sub_C2 : C2;
assign {C1_minus18_carry,C1_minus18} = C1 - 5'd18;
assign WtOffset = (C1_minus18_carry) ? C1 : C1_minus18;

assign C1_plus1 = C1 + 1'b1;
always @(posedge clk)
begin
	if(C2rst)
		C2 <= 5'd0;
	else if(C2init)
		C2 <= C2_initial;
	else if(C2inc)
		C2 <= C2 + 1'b1;
	else
		C2 <= C2;
end
always @(posedge clk)
begin
	if(C1rst)
		C1 <= 6'd0;
	else if(C1inc)
		C1 <= C1_plus1;
	else
		C1 <= C1;
end		
always @(posedge clk)
begin
	if(rst)
		C2initR <= 4'b0000;
	else
		C2initR <= {C2initR[2:0],C2init};
end		

always @(posedge clk)
begin
	if(rst || (state==6'd4))
		flag <= 1'b0;
	else if(state==6'd7 || state==6'd27 || state==6'd33)
		flag <= 1'b1;
	else
		flag <= flag;
end
/*
always @(posedge clk)
begin
	if(rst)
		C2_full_delayed <= 1'b0;
	else if((state==6'd7) & flag)
		C2_full_delayed <= C2_full;
	else
		C2_full_delayed <= C2_full_delayed;
end		
*/	
always @(posedge clk)
begin
	if(rst)
		state <= 6'd0;
	else
		state <= nextstate;
end		
assign C1_full = (C1==6'd34) ? 1'b1 : 1'b0;
assign C2_full = ((C2==5'd17) | (C2==C1)) ? 1'b1 : 1'b0;
assign C1_half = (C1==6'd17) ? 1'b1 : 1'b0;

always @(state or C1_half or C2_full or C2initR or C1_minus18_carry or flag or mode)
begin
	case(state)
	6'd0: begin  // RST
				C1inc<=1'b0; C2inc<=1'b0; C2init<=1'b0; C1rst<=1'b1; C2rst<=1'b1;
				RdOffsetSel<=1'b0; BaseSel<=2'd0; OffsetSel<=1'b0; C1sel<=1'b0;
				en1<=1'b0; en2<=1'b0; clr1<=1'b1; clr2<=1'b1; ROM_sel<=3'd0;
				sel3<=1'b1; sel4<=1'b1; sel5<=1'b0; sel6<=1'b0; mask<=1'b0; Cen<=1'b1; Cshift<=1'b0; wea<=1'b0;
			end

///// Start of Multiplication States //////
	6'd1: begin  // Fetch C2;
				C1inc<=1'b0; C2inc<=1'b0; C2init<=1'b0; C1rst<=1'b0; C2rst<=1'b0;
				RdOffsetSel<=1'b0; BaseSel<=2'd0; OffsetSel<=1'b0; C1sel<=1'b0;
				en1<=1'b0; clr1<=1'b0; clr2<=1'b0; ROM_sel<=3'd0;
				sel3<=1'b1; sel4<=1'b1; sel5<=1'b0; sel6<=1'b0; mask<=1'b0; Cen<=1'b0; Cshift<=1'b0; wea<=1'b0;
				if(C2initR[3]) en2<=1'b0; else en2<=1'b1;
			end
	6'd2: begin  // Fetch C1-C2; R1<--dout;
				C1inc<=1'b0;  C1rst<=1'b0; C2rst<=1'b0;
				RdOffsetSel<=1'b1; BaseSel<=2'd1; OffsetSel<=1'b0;
				en1<=1'b1; en2<=1'b0; clr1<=1'b0; clr2<=1'b0; ROM_sel<=3'd1;
				sel3<=1'b1; sel4<=1'b0; sel5<=1'b1; sel6<=1'b0; mask<=1'b0; Cen<=1'b1; Cshift<=1'b0; wea<=1'b0;
				if(C2_full && C2initR[1]==1'b0) begin C2inc<=1'b0; C2init<=1'b1; end
				else begin C2inc<=1'b1; C2init<=1'b0; end
				if(C2initR[1]) C1sel<=1'b1; else C1sel<=1'b0;
			end

	6'd3: begin  // Write in RAM;
				C1inc<=1'b1; C2inc<=1'b0; C2init<=1'b0;  C1rst<=1'b0; C2rst<=1'b0;
				RdOffsetSel<=1'b0; OffsetSel<=1'b1; C1sel<=1'b0;
				en1<=1'b0; en2<=1'b1; clr1<=1'b0; clr2<=1'b0; ROM_sel<=3'd0;
				sel3<=1'b1; sel4<=1'b1; sel5<=1'b0; Cen<=1'b0; Cshift<=1'b1; wea<=1'b1;
				if(C1_minus18_carry) begin BaseSel<=2'd2; sel6<=1'b0; end 
				else begin BaseSel<=2'd3; sel6<=1'b1; end 
				if(C1_half) mask<=1'b1; else mask<=1'b0; 
			end
	6'd4: begin  // Write final coefficient in RAM;
				C1inc<=1'b0; C2inc<=1'b0; C2init<=1'b0;  C1rst<=1'b0; C2rst<=1'b0;
				RdOffsetSel<=1'b1; BaseSel<=2'd3; OffsetSel<=1'b1; C1sel<=1'b0;
				en1<=1'b0; en2<=1'b0; clr1<=1'b0; clr2<=1'b0; ROM_sel<=3'd0;
				sel3<=1'b1; sel4<=1'b1; sel5<=1'b0; sel6<=1'b1; mask<=1'b0; Cen<=1'b0; Cshift<=1'b1; wea<=1'b1;
			end
///// End of Multiplication States //////			


///// Start of Reduction States //////
	6'd5: begin  // Clear C; Reset C1 and C2
				C1inc<=1'b0; C2inc<=1'b0; C2init<=1'b0;  C1rst<=1'b1; C2rst<=1'b1;
				RdOffsetSel<=1'b0; BaseSel<=2'd3; OffsetSel<=1'b0; C1sel<=1'b0;
				en1<=1'b0; en2<=1'b0; clr1<=1'b0; clr2<=1'b0; ROM_sel<=3'd0;
				sel3<=1'b1; sel4<=1'b1; sel5<=1'b0; sel6<=1'b0; mask<=1'b0; Cen<=1'b1; Cshift<=1'b0; wea<=1'b0;
			end
	6'd6: begin  // Fetch (i+B0)
				C1inc<=1'b0; C2inc<=1'b0; C2init<=1'b0;  C1rst<=1'b0; C2rst<=1'b0;
				RdOffsetSel<=1'b0; BaseSel<=2'd2; OffsetSel<=1'b0; C1sel<=1'b0;
				en1<=1'b0; en2<=1'b0; clr1<=1'b0; clr2<=1'b0; ROM_sel<=3'd0;
				sel3<=1'b1; sel4<=1'b1; sel5<=1'b1; sel6<=1'b0; mask<=1'b0; Cen<=1'b0; Cshift<=1'b0; wea<=1'b0;
			end			
	6'd7: begin  // Fetch (i+B1); R2<--[i+B0] if flag=1;
				C1inc<=1'b0; C2inc<=1'b0; C2init<=1'b0;  C1rst<=1'b0; C2rst<=1'b0;
				RdOffsetSel<=1'b0; BaseSel<=2'd3; OffsetSel<=1'b0; C1sel<=1'b0;
				en1<=1'b0; clr1<=1'b0; clr2<=1'b0; ROM_sel<=3'd0;
				sel3<=1'b1; sel4<=1'b1; sel5<=1'b1; sel6<=1'b0; mask<=1'b0; Cen<=1'b0; Cshift<=1'b0; wea<=1'b0;
				if(flag) en2<=1'b0; else en2<=1'b1; 
			end			
	6'd8: begin  // R2<--[i+B1]; C<--C+R2;
				C1inc<=1'b0; C2inc<=1'b0; C2init<=1'b0;  C1rst<=1'b0; C2rst<=1'b0;
				RdOffsetSel<=1'b0; BaseSel<=2'd3; OffsetSel<=1'b0; C1sel<=1'b0;
				en1<=1'b0; en2<=1'b1; clr1<=1'b0; clr2<=1'b0; ROM_sel<=3'd1;
				sel3<=1'b1; sel4<=1'b1; sel5<=1'b1; sel6<=1'b0; mask<=1'b0; Cen<=1'b1; Cshift<=1'b0; wea<=1'b0;
			end			
	6'd9: begin  // C<--C+R2;
				C1inc<=1'b0; C2inc<=1'b0; C2init<=1'b0;  C1rst<=1'b0; C2rst<=1'b0;
				RdOffsetSel<=1'b0; BaseSel<=2'd3; OffsetSel<=1'b0; C1sel<=1'b0;
				en1<=1'b0; en2<=1'b0; clr1<=1'b0; clr2<=1'b0; ROM_sel<=3'd1;
				sel3<=1'b1; sel4<=1'b1; sel5<=1'b1; sel6<=1'b0; mask<=1'b0; Cen<=1'b1; Cshift<=1'b0; wea<=1'b0;
			end
	6'd10: begin  // C<--C+R2*2^5;
				C1inc<=1'b0; C2inc<=1'b0; C2init<=1'b0;  C1rst<=1'b0; C2rst<=1'b0;
				RdOffsetSel<=1'b0; BaseSel<=2'd3; OffsetSel<=1'b0; C1sel<=1'b0;
				en1<=1'b0; en2<=1'b0; clr1<=1'b0; clr2<=1'b0; ROM_sel<=3'd2;
				sel3<=1'b1; sel4<=1'b1; sel5<=1'b1; sel6<=1'b0; mask<=1'b0; Cen<=1'b1; Cshift<=1'b0; wea<=1'b0;
			end
	6'd11: begin  // C<--C+R2*2^7; Inc C2;
				C1inc<=1'b0; C2inc<=1'b1; C2init<=1'b0;  C1rst<=1'b0; C2rst<=1'b0;
				RdOffsetSel<=1'b0; BaseSel<=2'd3; OffsetSel<=1'b0; C1sel<=1'b0;
				en1<=1'b0; en2<=1'b0; clr1<=1'b0; clr2<=1'b0; ROM_sel<=3'd3;
				sel3<=1'b1; sel4<=1'b1; sel5<=1'b1; sel6<=1'b0; mask<=1'b0; Cen<=1'b1; Cshift<=1'b0; wea<=1'b0;
			end			
	6'd12: begin  // C<--C+R2*2^12; Fetch (i+1+B0);
				C1inc<=1'b0; C2inc<=1'b0; C2init<=1'b0;  C1rst<=1'b0; C2rst<=1'b0;
				RdOffsetSel<=1'b0; BaseSel<=2'd2; OffsetSel<=1'b0; C1sel<=1'b0;
				en1<=1'b0; en2<=1'b0; clr1<=1'b0; clr2<=1'b0; ROM_sel<=3'd4;
				sel3<=1'b1; sel4<=1'b1; sel5<=1'b1; sel6<=1'b0; mask<=1'b0; Cen<=1'b1; Cshift<=1'b0; wea<=1'b0;
			end
	6'd13: begin  // RAM[i+B0]<--CL; Inc C1; R2<--[i+1+B0);
				C1inc<=1'b1; C2inc<=1'b0; C2init<=1'b0; 
				RdOffsetSel<=1'b0; BaseSel<=2'd3; OffsetSel<=1'b1; C1sel<=1'b0;	// CHANGED BaseSel<=2'd2; to BaseSel<=2'd3;
				en1<=1'b0; en2<=1'b1; clr1<=1'b0; clr2<=1'b0; ROM_sel<=3'd4;
				sel3<=1'b1; sel4<=1'b1; sel5<=1'b1; sel6<=1'b0; Cen<=1'b0; Cshift<=1'b1; wea<=1'b1;
				if(C1_half) begin mask<=1'b1; C1rst<=1'b1; C2rst<=1'b1; end
				else begin mask<=1'b0; C1rst<=1'b0; C2rst<=1'b0; end
			end
			
	6'd14: begin  // RAM[B1]<--highest word; Clear C;
				C1inc<=1'b0; C2inc<=1'b0; C2init<=1'b0; C1rst<=1'b0; C2rst<=1'b0;
				RdOffsetSel<=1'b0; BaseSel<=2'd2; OffsetSel<=1'b1; C1sel<=1'b0;	// CHANGED BaseSel<=2'd3; to BaseSel<=2'd2;
				en1<=1'b0; en2<=1'b0; clr1<=1'b0; clr2<=1'b0; ROM_sel<=3'd0;
				sel3<=1'b1; sel4<=1'b1; sel5<=1'b0; sel6<=1'b1; mask<=1'b0; Cen<=1'b1; Cshift<=1'b0; wea<=1'b1;
			end
	// final steps of reduction
	6'd15: begin  // Fetch [B0];
				C1inc<=1'b0; C2inc<=1'b0; C2init<=1'b0; C1rst<=1'b0; C2rst<=1'b0;
				RdOffsetSel<=1'b0; BaseSel<=2'd3; OffsetSel<=1'b0; C1sel<=1'b0;	// CHANGED BaseSel<=2'd2; to BaseSel<=2'd3;
				en1<=1'b0; en2<=1'b0; clr1<=1'b0; clr2<=1'b0; ROM_sel<=3'd0;
				sel3<=1'b1; sel4<=1'b1; sel5<=1'b1; sel6<=1'b0; mask<=1'b0; Cen<=1'b0; Cshift<=1'b0; wea<=1'b0;
			end
	6'd16: begin  // Fetch [B1]; R2<--[B0]; 
				C1inc<=1'b0; C2inc<=1'b0; C2init<=1'b0; C1rst<=1'b0; C2rst<=1'b0;
				RdOffsetSel<=1'b0; BaseSel<=2'd2; OffsetSel<=1'b0; C1sel<=1'b0;	// CHANGED BaseSel<=2'd3; to BaseSel<=2'd2;
				en1<=1'b0; en2<=1'b1; clr1<=1'b0; clr2<=1'b0; ROM_sel<=3'd0;
				sel3<=1'b1; sel4<=1'b1; sel5<=1'b1; sel6<=1'b0; mask<=1'b0; Cen<=1'b0; Cshift<=1'b0; wea<=1'b0;
			end
	6'd17: begin  // R2<--[B1]; C<--R2;
				C1inc<=1'b0; C2inc<=1'b0; C2init<=1'b0; C1rst<=1'b0; C2rst<=1'b0;
				RdOffsetSel<=1'b0; BaseSel<=2'd3; OffsetSel<=1'b0; C1sel<=1'b0;
				en1<=1'b0; en2<=1'b1; clr1<=1'b0; clr2<=1'b0; ROM_sel<=3'd1;
				sel3<=1'b1; sel4<=1'b1; sel5<=1'b1; sel6<=1'b0; mask<=1'b0; Cen<=1'b1; Cshift<=1'b0; wea<=1'b0;
			end
	6'd18: begin  // C<--C+R2;
				C1inc<=1'b0; C2inc<=1'b0; C2init<=1'b0; C1rst<=1'b0; C2rst<=1'b0;
				RdOffsetSel<=1'b0; BaseSel<=2'd3; OffsetSel<=1'b0; C1sel<=1'b0;
				en1<=1'b0; en2<=1'b0; clr1<=1'b0; clr2<=1'b0; ROM_sel<=3'd1;
				sel3<=1'b1; sel4<=1'b1; sel5<=1'b1; sel6<=1'b0; mask<=1'b0; Cen<=1'b1; Cshift<=1'b0; wea<=1'b0;
			end
	6'd19: begin  // C<--C+R2*2^5;
				C1inc<=1'b0; C2inc<=1'b0; C2init<=1'b0; C1rst<=1'b0; C2rst<=1'b0;
				RdOffsetSel<=1'b0; BaseSel<=2'd3; OffsetSel<=1'b0; C1sel<=1'b0;
				en1<=1'b0; en2<=1'b0; clr1<=1'b0; clr2<=1'b0; ROM_sel<=3'd2;
				sel3<=1'b1; sel4<=1'b1; sel5<=1'b1; sel6<=1'b0; mask<=1'b0; Cen<=1'b1; Cshift<=1'b0; wea<=1'b0;
			end
	6'd20: begin  // C<--C+R2*2^7; Inc C2;
				C1inc<=1'b0; C2inc<=1'b1; C2init<=1'b0; C1rst<=1'b0; C2rst<=1'b0;
				RdOffsetSel<=1'b0; BaseSel<=2'd3; OffsetSel<=1'b0; C1sel<=1'b0;
				en1<=1'b0; en2<=1'b0; clr1<=1'b0; clr2<=1'b0; ROM_sel<=3'd3;
				sel3<=1'b1; sel4<=1'b1; sel5<=1'b1; sel6<=1'b0; mask<=1'b0; Cen<=1'b1; Cshift<=1'b0; wea<=1'b0;
			end
	6'd21: begin  // C<--C+R2*2^12; Fetch [B0+1];
				C1inc<=1'b0; C2inc<=1'b0; C2init<=1'b0; C1rst<=1'b0; C2rst<=1'b0;
				RdOffsetSel<=1'b0; BaseSel<=2'd3; OffsetSel<=1'b0; C1sel<=1'b0;	// CHANGED BaseSel<=2'd2; to BaseSel<=2'd3;
				en1<=1'b0; en2<=1'b0; clr1<=1'b0; clr2<=1'b0; ROM_sel<=3'd4;
				sel3<=1'b1; sel4<=1'b1; sel5<=1'b1; sel6<=1'b0; mask<=1'b0; Cen<=1'b1; Cshift<=1'b0; wea<=1'b0;
			end
	6'd22: begin  // RAM[B0]<--CL; Inc C1; R2<--dout;
				C1inc<=1'b1; C2inc<=1'b0; C2init<=1'b0; C1rst<=1'b0; C2rst<=1'b0;
				RdOffsetSel<=1'b0; BaseSel<=2'd3; OffsetSel<=1'b1; C1sel<=1'b0;	// CHANGED BaseSel<=2'd2; to BaseSel<=2'd3;
				en1<=1'b0; en2<=1'b1; clr1<=1'b0; clr2<=1'b0; ROM_sel<=3'd4;
				sel3<=1'b1; sel4<=1'b1; sel5<=1'b1; sel6<=1'b0; mask<=1'b0; Cen<=1'b0; Cshift<=1'b1; wea<=1'b1;
			end			
	6'd23: begin  // C<--C+R2; 
				C1inc<=1'b0; C2inc<=1'b0; C2init<=1'b0; C1rst<=1'b0; C2rst<=1'b0;
				RdOffsetSel<=1'b0; BaseSel<=2'd3; OffsetSel<=1'b0; C1sel<=1'b0;
				en1<=1'b0; en2<=1'b0; clr1<=1'b0; clr2<=1'b0; ROM_sel<=3'd1;
				sel3<=1'b1; sel4<=1'b1; sel5<=1'b1; sel6<=1'b0; mask<=1'b0; Cen<=1'b1; Cshift<=1'b0; wea<=1'b0;
			end
	6'd24: begin  // RAM[B0+1]<--CL; Clear CL; Reset C1, C2;
				C1inc<=1'b0; C2inc<=1'b0; C2init<=1'b0; C1rst<=1'b1; C2rst<=1'b1;
				RdOffsetSel<=1'b0; BaseSel<=2'd3; OffsetSel<=1'b1; C1sel<=1'b0;	// CHANGED BaseSel<=2'd2; to BaseSel<=2'd3;
				en1<=1'b0; en2<=1'b1; clr1<=1'b0; clr2<=1'b0; ROM_sel<=3'd0;
				sel3<=1'b1; sel4<=1'b1; sel5<=1'b1; sel6<=1'b0; mask<=1'b0; Cen<=1'b1; Cshift<=1'b0; wea<=1'b1;
			end			
			
////////////////////////////////////////////////
////////			Squaring Starts		////////////
////////////////////////////////////////////////
	6'd25: begin  // Fetch C2;
 				C1inc<=1'b0; C2inc<=1'b0; C2init<=1'b0; C1rst<=1'b0; C2rst<=1'b0;
				RdOffsetSel<=1'b0; BaseSel<=2'd0; OffsetSel<=1'b0; C1sel<=1'b0;
				en1<=1'b0; en2<=1'b0; clr1<=1'b0; clr2<=1'b0; ROM_sel<=3'd0;
				sel3<=1'b1; sel4<=1'b0; sel5<=1'b0; sel6<=1'b1; mask<=1'b0; Cen<=1'b0; Cshift<=1'b0; wea<=1'b0;
			end
	6'd26: begin  // (R1,R2)<--dout; If flag=1 RAM[B2/3+C1]<--CL & C>>16 & Inc C1;
 				C2inc<=1'b0; C2init<=1'b0; C1rst<=1'b0; C2rst<=1'b0;
				RdOffsetSel<=1'b0; OffsetSel<=1'b1; C1sel<=1'b0;
				en1<=1'b1; en2<=1'b1; clr1<=1'b0; clr2<=1'b0; ROM_sel<=3'd0;
				sel3<=1'b1; sel4<=1'b0; sel5<=1'b0; Cen<=1'b0; 
				if(flag) begin wea<=1'b1; C1inc<=1'b1; Cshift<=1'b1; end 
				else begin wea<=1'b0; C1inc<=1'b0; Cshift<=1'b0; end		
				if(C1_minus18_carry) begin BaseSel<=2'd2; sel6<=1'b0; end 
				else begin BaseSel<=2'd3; sel6<=1'b1; end 
				if(C1_half) mask<=1'b1; else mask<=1'b0; 				
			end
	6'd27: begin  // C<--R1*R2; Inc C2; If flag=1 RAM[B2/3+C1]<--CL & C>>16 & Inc C1;
 				C2inc<=1'b1; C2init<=1'b0; C1rst<=1'b0; C2rst<=1'b0;
				RdOffsetSel<=1'b0; OffsetSel<=1'b1; C1sel<=1'b0;
				en1<=1'b0; en2<=1'b0; clr1<=1'b0; clr2<=1'b0; ROM_sel<=3'd0;
				sel3<=1'b1; sel4<=1'b0; sel5<=1'b0; Cen<=1'b1; Cshift<=1'b0;
				if(flag) begin wea<=1'b1; C1inc<=1'b1; end
				else begin wea<=1'b0; C1inc<=1'b0; end
				if(C1_minus18_carry) begin BaseSel<=2'd2; sel6<=1'b0; end 
				else begin BaseSel<=2'd3; sel6<=1'b1; end 
				if(C1_half) mask<=1'b1; else mask<=1'b0; 				
			end
////////////////////////////////////////////////
////////			Squaring Ends		////////////
////////////////////////////////////////////////


////////////////////////////////////////////////
////////			Addition Starts		////////////
////////////////////////////////////////////////
	6'd28: begin  // Fetch (B1+C2); C<--C+R2(#B2+C2+1);
 				C1inc<=1'b0; C2inc<=1'b0; C2init<=1'b0; C1rst<=1'b0; C2rst<=1'b0;
				RdOffsetSel<=1'b0; BaseSel<=2'd0; OffsetSel<=1'b0; C1sel<=1'b0;
				en1<=1'b0; en2<=1'b0; clr1<=1'b0; clr2<=1'b0; ROM_sel<=3'd1;
				sel3<=1'b1; sel4<=1'b1; sel5<=1'b1; sel6<=1'b0; mask<=1'b0; Cen<=1'b1; Cshift<=1'b0; wea<=1'b0;
			end
	6'd29: begin  // R2<--(B1+C2); If addition: if flag=1 then [B0+C1+1]<--CL & C1++;		
 				C2init<=1'b0; C1rst<=1'b0; C2rst<=1'b0;
				RdOffsetSel<=1'b0; BaseSel<=2'd3; OffsetSel<=1'b1; C1sel<=1'b0;	// *** BaseSel<=2'd2; changed to BaseSel<=2'd3;
				en1<=1'b0; en2<=1'b1; clr1<=1'b0; clr2<=1'b0; ROM_sel<=3'd1;
				sel3<=1'b1; sel4<=1'b1; sel5<=1'b0; sel6<=1'b0; mask<=1'b0; Cen<=1'b0; Cshift<=1'b0; 
				if(flag & (mode==2'd2)) begin wea<=1'b1; C1inc<=1'b1; end
				else begin wea<=1'b0; C1inc<=1'b0; end
				if(mode==2'd3) C2inc<=1'b1; else C2inc<=1'b0;  
			end
	6'd30: begin  // Fetch (B2+C2); Inc C2;
 				C1inc<=1'b0; C2inc<=1'b1; C2init<=1'b0; C1rst<=1'b0; C2rst<=1'b0;
				RdOffsetSel<=1'b0; BaseSel<=2'd1; OffsetSel<=1'b0; C1sel<=1'b0;
				en1<=1'b0; en2<=1'b0; clr1<=1'b0; clr2<=1'b0; ROM_sel<=3'd1;
				sel3<=1'b1; sel4<=1'b1; sel5<=1'b0; sel6<=1'b0; mask<=1'b0; Cen<=1'b0; Cshift<=1'b0; wea<=1'b0;
			end			
	6'd31: begin  // R2<--(B2+C2); C<--0+R2; Fetch (B1+C2+1);
 				C1inc<=1'b0; C2inc<=1'b0; C2init<=1'b0; C1rst<=1'b0; C2rst<=1'b0;
				RdOffsetSel<=1'b0; BaseSel<=2'd0; OffsetSel<=1'b0; C1sel<=1'b0;
				en1<=1'b0; en2<=1'b1; clr1<=1'b0; clr2<=1'b0; ROM_sel<=3'd1;
				sel3<=1'b1; sel4<=1'b1; sel5<=1'b0; sel6<=1'b0; mask<=1'b0; Cen<=1'b1; Cshift<=1'b0; wea<=1'b0;
			end
	6'd32: begin  // If addition C<--C+R2; If copy C<--0+R2; R2<--(B1+C2+1); Fetch (B2+C2+1); Inc C2
 				C1inc<=1'b0; C2init<=1'b0; C1rst<=1'b0; C2rst<=1'b0;
				RdOffsetSel<=1'b0; BaseSel<=2'd1; OffsetSel<=1'b0; C1sel<=1'b0;
				en1<=1'b0; en2<=1'b1; clr1<=1'b0; clr2<=1'b0; ROM_sel<=3'd1;
				sel3<=1'b1; sel4<=1'b1; sel6<=1'b0; mask<=1'b0; Cen<=1'b1; Cshift<=1'b0; wea<=1'b0;
				if(mode==2'd2) begin C2inc<=1'b1;  sel5<=1'b1; end
				else begin C2inc<=1'b0; sel5<=1'b0; end
			end
	6'd33: begin  // [B0+C1]<--CL; Inc C1; C<--0+R2; R2<--(B2+C2+1);
 				C1inc<=1'b1; C2inc<=1'b0; C2init<=1'b0; C1rst<=1'b0; C2rst<=1'b0;
				RdOffsetSel<=1'b0; BaseSel<=2'd3; OffsetSel<=1'b1; C1sel<=1'b0;	// *** BaseSel<=2'd2; changed to BaseSel<=2'd3;
				en1<=1'b0; en2<=1'b1; clr1<=1'b0; clr2<=1'b0; ROM_sel<=3'd1;
				sel3<=1'b1; sel4<=1'b1; sel5<=1'b0; sel6<=1'b0; mask<=1'b0; Cen<=1'b1; Cshift<=1'b0; wea<=1'b1;
			end			
	





	6'd63: begin  // End
				C1inc<=1'b0; C2inc<=1'b0; C2init<=1'b0;  C1rst<=1'b0; C2rst<=1'b0;
				RdOffsetSel<=1'b1; BaseSel<=2'd0; OffsetSel<=1'b0; C1sel<=1'b1; 
				en1<=1'b0; en2<=1'b0; clr1<=1'b0; clr2<=1'b0; ROM_sel<=3'd0;
				sel3<=1'b1; sel4<=1'b1; sel5<=1'b1; sel6<=1'b0; mask<=1'b0; Cen<=1'b0; Cshift<=1'b0; wea<=1'b0;
			end
			
			
	default: begin
				C1inc<=1'b0; C2inc<=1'b0; C2init<=1'b0; C1rst<=1'b0; C2rst<=1'b0;
				RdOffsetSel<=1'b1; BaseSel<=2'd0; OffsetSel<=1'b0; C1sel<=1'b1; 
				en1<=1'b0; en2<=1'b0; clr1<=1'b0; clr2<=1'b0; ROM_sel<=3'd0;
				sel3<=1'b1; sel4<=1'b1; sel5<=1'b1; sel6<=1'b0; mask<=1'b0; Cen<=1'b0; Cshift<=1'b0; wea<=1'b0;
			end
	endcase
end

always @(state or mode or C1_full or C2initR or C1_half or flag)
begin	
	case(state)
	6'd0 : begin 
				if(mode==2'd0) 
					nextstate <= 6'd1;
				else if(mode==2'd1)
					nextstate <= 6'd25;
				else	// addition and copy
					nextstate <= 6'd28;
			end		
	6'd1 : nextstate <= 6'd2;
	6'd2 : begin
				if(C2initR[1] | C1_full)
					nextstate <= 6'd3;
				else
					nextstate <= 6'd1;
			end
	6'd3 : begin
				if(C1_full)
					nextstate <= 6'd4;
				else
					nextstate <= 6'd1;
			end		
	6'd4: nextstate <= 6'd5;

	6'd5: nextstate <= 6'd6;
	6'd6: nextstate <= 6'd7;
	6'd7: nextstate <= 6'd8;
	6'd8: nextstate <= 6'd9;
	6'd9: nextstate <= 6'd10;
	6'd10: nextstate <= 6'd11;	
	6'd11: nextstate <= 6'd12;
	6'd12: nextstate <= 6'd13;

	6'd13 : begin
				if(C1_half)
					nextstate <= 6'd14;
				else
					nextstate <= 6'd7;
			end

	6'd14: nextstate <= 6'd15;	
	6'd15: nextstate <= 6'd16;	
	6'd16: nextstate <= 6'd17;	
	6'd17: nextstate <= 6'd18;	
	6'd18: nextstate <= 6'd19;	
	6'd19: nextstate <= 6'd20;		
	6'd20: nextstate <= 6'd21;	
	6'd21: nextstate <= 6'd22;	
	6'd22: nextstate <= 6'd23;
	6'd23: nextstate <= 6'd24;
	6'd24: nextstate <= 6'd63;
	
	6'd25: nextstate <= 6'd26;	
	6'd26: begin
				if(C1_full)
					nextstate <= 6'd4;	// Jump to write last word and then start modular reduction	
				else
					nextstate <= 6'd27;
			end	
	6'd27: nextstate <= 6'd25;

	// Addition states;
	6'd28: nextstate <= 6'd29;
	6'd29: begin
				if(C1_half & (mode==2'd2))
					nextstate <= 6'd63;
				else if(mode==2'd3)
					nextstate <= 6'd32;
				else
					nextstate <= 6'd30;
			end		
	6'd30: nextstate <= 6'd31;
	6'd31: nextstate <= 6'd32;
	6'd32: nextstate <= 6'd33;
	6'd33: begin
				if(C1_half & (mode==2'd3))
					nextstate <= 6'd63;
				else
					nextstate <= 6'd28;
			end
			
	6'd63: nextstate <= 6'd63;	
	default: nextstate <= 6'd63;
	endcase
end
	
assign done = (state==6'd63) ? 1'b1 : 1'b0;	
	
endmodule
