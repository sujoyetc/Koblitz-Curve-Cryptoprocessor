//////////////////////////////////////////////////////////////////////////////////
// Company: COSIC KU Leuven
// Engineer: Sujoy Sinha Roy
// 
// Create Date:    19:29:17 08/22/2014 
// Design Name: 
// Module Name:    scalarconv_tnaf 
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
module scalarconv_tnaf(clk, rst, suspend, Tbit_no_sign, b0_one, b1_zero, M4_out0, flag_adjustment,
			rst_d_carry, en1, en2, clr1, clr2, sel1, sel2, sel3, sel6, sel7, Tbit_sign, mask, mask_d_en, enable_flag_adjustment,
			add_sub, carry_en, lsb_en, lsb_en_mode, address_carryin, R1set, Cen, Cshift, terminal_condition,
			BaseSel, SCOffset, wea, length_even, Tbit_ready, done, 
			state, length_counter);

						
input clk, rst;
input suspend;		// When this is high, the state-machine halts 
input Tbit_no_sign;	// used as a control for addition/subtraction during computation of b0
input b0_one, b1_zero; // used to check terminal conditions during tau-NAF generation
input M4_out0;				// used during the final adjustment after scalar multiplication.
input [1:0] flag_adjustment;

output reg rst_d_carry, en1, en2, clr1, clr2, sel1, sel7, R1set, Cen, Cshift;
output terminal_condition, enable_flag_adjustment;
output reg add_sub, lsb_en, address_carryin, wea, mask_d_en;
output reg [1:0] sel2, carry_en;
output reg [2:0] BaseSel; 
//output [3:0] ROMBaseSel;
output [4:0] SCOffset;
output sel3, sel6, Tbit_sign, mask, lsb_en_mode;
output reg length_even;	// This is 1 when the length of the TNAF generated is even.
output Tbit_ready;
output reg done;

output [5:0] state;
output [8:0] length_counter;

assign {sel3, sel6, mask} = 3'b000;
//assign ROMBaseSel = 4'd3;

reg [4:0] word_counter;
reg [8:0] length_counter;
reg [5:0] state, nextstate;
reg clr_wc, inc_wc, dec_length;

wire wc_full, wc_half, wc_zero, lc_full;
wire length_counter_large, terminal_condition_wire;	// used to check terminal conditions
reg terminal_condition;
wire done_wire;
wire rst_or_state_is30;

always @(posedge clk)
begin
	if(clr_wc)
		word_counter<=5'd0;
	else if(inc_wc)
		word_counter<=word_counter+1'b1;
	else
		word_counter<=word_counter;
end
	
always @(posedge clk)
begin
	if(rst_or_state_is30)
		length_counter <= 9'd0;
	else if(dec_length)
		length_counter <= length_counter - 1'b1;	
	else if((state==6'd22 || state==6'd35) & wc_half)
		length_counter <= length_counter + 1'b1;
	else
		length_counter <= length_counter;
end


assign wc_full = (word_counter==6'd17) ? 1'b1 : 1'b0;
assign wc_half = (word_counter==6'd8) ? 1'b1 : 1'b0;
assign wc_zero = (word_counter==6'd0) ? 1'b1 : 1'b0;
assign lc_full = (length_counter==9'd282) ? 1'b1 : 1'b0;
assign lsb_en_mode = (wc_full & (state==6'd13)) | (wc_half & (state==6'd32));
	
// check terminal conditions
assign length_counter_large = (length_counter>9'd280) ? 1'b1 : 1'b0;
assign terminal_condition_wire = wc_zero & length_counter_large & b0_one & b1_zero & (state==6'd35);
assign Tbit_sign = length_counter[0];
assign enable_flag_adjustment = (((state==6'd26 && M4_out0==1'b0)|(state==6'd28 && flag_adjustment[0]==1'b1)) & wc_zero)? 1'b1 : 1'b0;
assign rst_or_state_is30 = (rst | (state==6'd30)) ? 1'b1 : 1'b0;

always @(posedge clk)
rst_d_carry <= rst_or_state_is30;

always @(posedge clk)	// delayed by one cycle to enable checking in state 36;
begin
	if(rst_or_state_is30)
		terminal_condition<=1'b0;
	else if(terminal_condition_wire)
		terminal_condition<=1'b1;
	else 
		terminal_condition<=terminal_condition;
end
always @(posedge clk)
begin
	if(clr_wc)	// This is 1 for the last time in state42
		length_even<=length_counter[0];
	else	
		length_even<=length_even;
end
		
always @(posedge clk)
begin
	if(rst)
		state<=6'd0;
	else if(suspend)
		state<=state;
	else
		state<=nextstate;
end		


always @(state or wc_full or wc_half or wc_zero or M4_out0 or flag_adjustment[0] or Tbit_no_sign)
begin
	case(state)
	6'd0: begin		// RST state; CL<--0;
			en1<=1'b0; en2<=1'b0; clr1<=1'b1; clr2<=1'b1; clr_wc<=1'b1; inc_wc<=1'b0; dec_length<=1'b0;
			BaseSel<=3'd0; sel1<=1'b0; sel2<=2'd0; sel7<=1'b0; add_sub<=1'b0; carry_en<=2'd0; lsb_en<=1'b0;
			R1set<=1'b0; Cen<=1'b1; Cshift<=1'b0; address_carryin<=1'b0; wea<=1'b0; mask_d_en<=1'b0;
			end

	////////	 Start of Initial Loading		////////
	6'd1: begin		// Load 0 in d1 (address 18..);
			en1<=1'b0; en2<=1'b0; clr1<=1'b0; clr2<=1'b0; inc_wc<=1'b1; dec_length<=1'b0;
			BaseSel<=3'd1; sel1<=1'b0; sel2<=2'd0; sel7<=1'b0; add_sub<=1'b0; carry_en<=2'd0; lsb_en<=1'b0;
			R1set<=1'b0; Cen<=1'b0; Cshift<=1'b0; address_carryin<=1'b0; wea<=1'b1; mask_d_en<=1'b0;
			if(wc_full) clr_wc<=1'b1; else clr_wc<=1'b0;
			end

	6'd2: begin		// Load 0 in {b0, b1} (address 208..);
			en1<=1'b0; en2<=1'b0; clr1<=1'b0; clr2<=1'b0; inc_wc<=1'b1; dec_length<=1'b0;
			BaseSel<=3'd2; sel1<=1'b0; sel2<=2'd0; sel7<=1'b0; add_sub<=1'b0; carry_en<=2'd0; lsb_en<=1'b0;
			R1set<=1'b0; Cen<=1'b1; Cshift<=1'b0; address_carryin<=1'b0; wea<=1'b1; mask_d_en<=1'b0;
			if(wc_full) begin clr_wc<=1'b1; R1set<=1'b1; end
			else begin clr_wc<=1'b0; R1set<=1'b0; end
			end


	6'd3: begin		// Set a0[0]<--1 and rest of a0, a1=0 (address 54..);
			en1<=1'b0; en2<=1'b0; clr1<=1'b0; clr2<=1'b0; inc_wc<=1'b1; clr_wc<=1'b0; dec_length<=1'b0;
			BaseSel<=3'd3; sel1<=1'b0; sel2<=2'd0; sel7<=1'b0; add_sub<=1'b0; carry_en<=2'd0; lsb_en<=1'b0;
			R1set<=1'b0; Cen<=1'b1; Cshift<=1'b0; address_carryin<=1'b0; wea<=1'b1; mask_d_en<=1'b0;
			if(wc_full) clr_wc<=1'b1; else clr_wc<=1'b0;
			end

	////////	 END of Initial Loading		////////

	
	/////	Before starting computation, set the d0even flag when d0 (i.e the scalar is even)
	6'd4: begin		// Fetch d0[0];
			en1<=1'b0; en2<=1'b0; clr1<=1'b0; clr2<=1'b0; clr_wc<=1'b0; inc_wc<=1'b0; dec_length<=1'b0;
			BaseSel<=3'd0; sel1<=1'b0; sel2<=2'd0; sel7<=1'b0; add_sub<=1'b0; carry_en<=2'd0; lsb_en<=1'b0;
			R1set<=1'b0; Cen<=1'b0; Cshift<=1'b0; address_carryin<=1'b0; wea<=1'b0; mask_d_en<=1'b0;
			end
	6'd62: begin	// Update d0even flag (in ALU) using carry_en=3
			en1<=1'b0; en2<=1'b0; clr1<=1'b0; clr2<=1'b0; clr_wc<=1'b0; inc_wc<=1'b0; dec_length<=1'b0;
			BaseSel<=3'd0; sel1<=1'b0; sel2<=2'd0; sel7<=1'b0; add_sub<=1'b0; carry_en<=2'd3; lsb_en<=1'b0;
			R1set<=1'b0; Cen<=1'b0; Cshift<=1'b0; address_carryin<=1'b0; wea<=1'b0; mask_d_en<=1'b0;
			end


	//////// Computation of b0 and b1 starts  ////////
	6'd5: begin		// LSB<--d0_lsb; Fetch b0[i];
			en1<=1'b0; en2<=1'b0; clr1<=1'b0; clr2<=1'b0; clr_wc<=1'b0; inc_wc<=1'b0; dec_length<=1'b0;
			BaseSel<=3'd2; sel1<=1'b0; sel2<=2'd0; sel7<=1'b0; add_sub<=1'b0; carry_en<=2'd0; lsb_en<=1'b0;
			R1set<=1'b0; Cen<=1'b0; Cshift<=1'b0; address_carryin<=1'b0; wea<=1'b0; mask_d_en<=1'b0;
			//if(wc_zero) lsb_en<=1'b1; else lsb_en<=1'b0;
			end
	6'd6: begin		// R2<--b0[i]; Fetch a0[i];
			en1<=1'b0; en2<=1'b1; clr1<=1'b0; clr2<=1'b0; clr_wc<=1'b0; inc_wc<=1'b0; dec_length<=1'b0;
			BaseSel<=3'd3; sel1<=1'b0; sel2<=2'd0; sel7<=1'b0; add_sub<=1'b0; carry_en<=2'd0; lsb_en<=1'b0;
			R1set<=1'b0; Cen<=1'b0; Cshift<=1'b0; address_carryin<=1'b0; wea<=1'b0; mask_d_en<=1'b0;
			end
	6'd7: begin		// R1<--a0[i]; Fetch b1[i];
			en1<=1'b1; en2<=1'b0; clr1<=1'b0; clr2<=1'b0; clr_wc<=1'b0; inc_wc<=1'b0; dec_length<=1'b0;
			BaseSel<=3'd4; sel1<=1'b0; sel2<=2'd0; sel7<=1'b0; add_sub<=1'b0; carry_en<=2'd0; lsb_en<=1'b0;
			R1set<=1'b0; Cen<=1'b0; Cshift<=1'b0; address_carryin<=1'b0; wea<=1'b0; mask_d_en<=1'b0;
			end
	6'd8: begin		// CL<--b0[i]+/-a0[i]; R2<--b1[i]; Fetch a1[i];
			en1<=1'b0; en2<=1'b1; clr1<=1'b0; clr2<=1'b0; clr_wc<=1'b0; inc_wc<=1'b0; dec_length<=1'b0;
			BaseSel<=3'd5; sel1<=1'b0; sel7<=1'b0; carry_en<=2'd1; lsb_en<=1'b0;
			R1set<=1'b0; Cen<=1'b1; Cshift<=1'b0; address_carryin<=1'b0; wea<=1'b0; mask_d_en<=1'b0;
			if(wc_zero) sel2<=2'd0; else sel2<=2'd1;
			if(Tbit_no_sign) add_sub<=1'b0; else add_sub<=1'b1;
			end
	6'd9: begin		// R1<--a1[i]; RAM[b0+i]<--CL;
			en1<=1'b1; en2<=1'b0; clr1<=1'b0; clr2<=1'b0; clr_wc<=1'b0; inc_wc<=1'b0; dec_length<=1'b0;
			BaseSel<=3'd2; sel1<=1'b0; sel2<=2'd0; sel7<=1'b0; add_sub<=1'b0; carry_en<=2'd0; lsb_en<=1'b0;
			R1set<=1'b0; Cen<=1'b0; Cshift<=1'b0; address_carryin<=1'b0; wea<=1'b1; mask_d_en<=1'b0;
			//if(LSB_store) BaseSel<=3'd2; else BaseSel<=3'd6;
			end
	6'd10:begin		// CL<--b1[i]+/-a1[i]; 
			en1<=1'b0; en2<=1'b0; clr1<=1'b0; clr2<=1'b0; clr_wc<=1'b0; inc_wc<=1'b0; dec_length<=1'b0;
			BaseSel<=3'd5; sel1<=1'b0; sel7<=1'b0; carry_en<=2'd2; lsb_en<=1'b0;
			R1set<=1'b0; Cen<=1'b1; Cshift<=1'b0; address_carryin<=1'b0; wea<=1'b0; mask_d_en<=1'b0;
			if(wc_zero) sel2<=2'd0; else sel2<=2'd2;
			if(Tbit_no_sign) add_sub<=1'b0; else add_sub<=1'b1;
			end
	6'd11:begin		// RAM[b1+i]<--CL; Increment wc;
			en1<=1'b0; en2<=1'b0; clr1<=1'b0; clr2<=1'b0; inc_wc<=1'b1; dec_length<=1'b0;
			BaseSel<=3'd4; sel1<=1'b0; sel2<=2'd0; sel7<=1'b0; add_sub<=1'b0; carry_en<=2'd0; lsb_en<=1'b0;
			R1set<=1'b0; Cen<=1'b0; Cshift<=1'b0; address_carryin<=1'b0; wea<=1'b1; mask_d_en<=1'b0;
			if(wc_half) clr_wc<=1'b1; else clr_wc<=1'b0; 	
			//if(LSB_store) BaseSel<=3'd4; else BaseSel<=3'd6;			
			end
			
			
	//////// Computation of d0 and d1 starts  ////////
	6'd12: begin		// Fetch d0[i];
			en1<=1'b0; en2<=1'b0; clr1<=1'b0; clr2<=1'b0; clr_wc<=1'b0; inc_wc<=1'b0; dec_length<=1'b0;
			BaseSel<=3'd0; sel1<=1'b0; sel2<=2'd0; sel7<=1'b0; add_sub<=1'b0; carry_en<=2'd0; lsb_en<=1'b0;
			R1set<=1'b0; Cen<=1'b0; Cshift<=1'b0; address_carryin<=1'b0; wea<=1'b0; mask_d_en<=1'b0;
			end
	6'd13: begin		// Fetch d0[i+1]; R2<--d0[i];
			en1<=1'b0; en2<=1'b1; clr1<=1'b0; clr2<=1'b0; clr_wc<=1'b0; inc_wc<=1'b0; dec_length<=1'b0;
			BaseSel<=3'd0; sel1<=1'b0; sel2<=2'd0; sel7<=1'b0; add_sub<=1'b0; carry_en<=2'd0; lsb_en<=1'b0^wc_full;
			R1set<=1'b0; Cen<=1'b0; Cshift<=1'b0; address_carryin<=1'b1; wea<=1'b0; mask_d_en<=1'b0;
			end
	6'd14: begin		// LSB<--d0[i+1][0]; Fetch d1[i]; Clr R1;
			en1<=1'b0; en2<=1'b0; clr1<=1'b1; clr2<=1'b0; clr_wc<=1'b0; inc_wc<=1'b0; dec_length<=1'b0;
			BaseSel<=3'd1; sel1<=1'b0; sel2<=2'd0; sel7<=1'b0; add_sub<=1'b0; carry_en<=2'd0; lsb_en<=1'b1^wc_full;
			R1set<=1'b0; Cen<=1'b0; Cshift<=1'b0; address_carryin<=1'b0; wea<=1'b0; mask_d_en<=1'b0;
			end
	6'd15: begin		// CL<--d0/2; R1<--d1[i];
			en1<=1'b1; en2<=1'b0; clr1<=1'b0; clr2<=1'b0; clr_wc<=1'b0; inc_wc<=1'b0; dec_length<=1'b0;
			BaseSel<=3'd1; sel1<=1'b1; sel2<=2'd0; sel7<=1'b0; add_sub<=1'b0; carry_en<=2'd0; lsb_en<=1'b0;
			R1set<=1'b0; Cen<=1'b1; Cshift<=1'b0; address_carryin<=1'b0; wea<=1'b0;
				if(wc_zero) mask_d_en<=1'b1; else mask_d_en<=1'b0;
			end
	6'd16: begin		// RAM[d1+i]<--CL; CL<--d0/2-d1;
			en1<=1'b0; en2<=1'b0; clr1<=1'b0; clr2<=1'b0; clr_wc<=1'b0; inc_wc<=1'b0; dec_length<=1'b0;
			BaseSel<=3'd1; sel1<=1'b1; sel7<=1'b0; add_sub<=1'b1; carry_en<=2'd1; lsb_en<=1'b0;
			R1set<=1'b0; Cen<=1'b1; Cshift<=1'b0; address_carryin<=1'b0; wea<=1'b1;
			if(wc_zero) begin mask_d_en<=1'b1; sel2<=2'd3;	end
			else begin mask_d_en<=1'b0; sel2<=2'd1;	end
			end
	6'd17: begin		// RAM[d0+i]<--CL; Increment wc;
			en1<=1'b0; en2<=1'b0; clr1<=1'b0; clr2<=1'b0; inc_wc<=1'b1; dec_length<=1'b0;
			BaseSel<=3'd0; sel1<=1'b1; sel7<=1'b0; add_sub<=1'b1; carry_en<=2'd0; lsb_en<=1'b0;
			R1set<=1'b0; Cen<=1'b0; Cshift<=1'b0; address_carryin<=1'b0; wea<=1'b1; mask_d_en<=1'b0;
			if(wc_full) clr_wc<=1'b1; else clr_wc<=1'b0;
			if(wc_zero) sel2<=2'd0;	else sel2<=2'd1;
			end

	//////// End : d0 and d1  ////////
	
	//////////////////////////////////////////////////
	//////// Computation of a0 and a1 starts  ////////
	6'd18:begin		// Fetch a1[i];
			en1<=1'b0; en2<=1'b0; clr1<=1'b0; clr2<=1'b0; clr_wc<=1'b0; inc_wc<=1'b0; dec_length<=1'b0;
			BaseSel<=3'd5; sel1<=1'b0; sel2<=2'd0; sel7<=1'b0; add_sub<=1'b0; carry_en<=2'd0; lsb_en<=1'b0;
			R1set<=1'b0; Cen<=1'b0; Cshift<=1'b0; address_carryin<=1'b0; wea<=1'b0; mask_d_en<=1'b0;
			end
	6'd19:begin		// R1,R2<--a1[i]; Fetch a0[i];
			en1<=1'b1; en2<=1'b1; clr1<=1'b0; clr2<=1'b0; clr_wc<=1'b0; inc_wc<=1'b0; dec_length<=1'b0;
			BaseSel<=3'd3; sel1<=1'b0; sel2<=2'd0; sel7<=1'b0; add_sub<=1'b0; carry_en<=2'd0; lsb_en<=1'b0;
			R1set<=1'b0; Cen<=1'b0; Cshift<=1'b0; address_carryin<=1'b0; wea<=1'b0; mask_d_en<=1'b0;
			end
	6'd20:begin		// CL<--2a1; R1<--a0[i];
			en1<=1'b1; en2<=1'b0; clr1<=1'b0; clr2<=1'b0; clr_wc<=1'b0; inc_wc<=1'b0; dec_length<=1'b0;
			BaseSel<=3'd3; sel1<=1'b0; sel7<=1'b0; add_sub<=1'b0; carry_en<=2'd1; lsb_en<=1'b0;
			R1set<=1'b0; Cen<=1'b1; Cshift<=1'b0; address_carryin<=1'b0; wea<=1'b0; mask_d_en<=1'b0;
			if(wc_zero) sel2<=2'd0; else sel2<=2'd1;
			end
	6'd21:begin		// RAM[a0+i]<--CL; CL<--a1[i]-a0[i];
			en1<=1'b0; en2<=1'b0; clr1<=1'b0; clr2<=1'b0; clr_wc<=1'b0; inc_wc<=1'b0; dec_length<=1'b0;
			BaseSel<=3'd3; sel1<=1'b0; sel7<=1'b0; add_sub<=1'b1; carry_en<=2'd2; lsb_en<=1'b0;
			R1set<=1'b0; Cen<=1'b1; Cshift<=1'b0; address_carryin<=1'b0; wea<=1'b1; mask_d_en<=1'b0;
			if(wc_zero) sel2<=2'd0; else sel2<=2'd2;
			end
	6'd22:begin		// RAM[a1+i]<--CL; Increment wc;
			en1<=1'b0; en2<=1'b0; clr1<=1'b0; clr2<=1'b0; inc_wc<=1'b1; dec_length<=1'b0;
			BaseSel<=3'd5; sel1<=1'b0; sel2<=2'd0; sel7<=1'b0; add_sub<=1'b1; carry_en<=2'd0; lsb_en<=1'b0;
			R1set<=1'b0; Cen<=1'b0; Cshift<=1'b0; address_carryin<=1'b0; wea<=1'b1; mask_d_en<=1'b0;
			if(wc_half) clr_wc<=1'b1; else clr_wc<=1'b0;
			end			
	//////// Computation of a0 and a1 ENDS  ////////


			
	//////// final step : b0<--b0-d0; b1<--b1-d1 ////////		
	//////// FINAL ADDITION PENDING
	6'd23:begin		// Fetch b0[i];
			en1<=1'b0; en2<=1'b0; clr1<=1'b0; clr2<=1'b0; clr_wc<=1'b0; inc_wc<=1'b0; dec_length<=1'b0;
			BaseSel<=3'd2; sel1<=1'b0; sel2<=2'd0; sel7<=1'b0; add_sub<=1'b0; carry_en<=2'd0; lsb_en<=1'b0;
			R1set<=1'b0; Cen<=1'b0; Cshift<=1'b0; address_carryin<=1'b0; wea<=1'b0; mask_d_en<=1'b0;
			end
	6'd24:begin		// R2<--b0[i]; Fetch d0[i];
			en1<=1'b0; en2<=1'b1; clr1<=1'b0; clr2<=1'b0; clr_wc<=1'b0; inc_wc<=1'b0; dec_length<=1'b0;
			BaseSel<=3'd0; sel1<=1'b0; sel2<=2'd0; sel7<=1'b0; add_sub<=1'b0; carry_en<=2'd0; lsb_en<=1'b0;
			R1set<=1'b0; Cen<=1'b0; Cshift<=1'b0; address_carryin<=1'b0; wea<=1'b0; mask_d_en<=1'b0;
			end
	6'd25:begin		// R1<--d0[i]; Fetch b1[i];
			en1<=1'b1; en2<=1'b0; clr1<=1'b0; clr2<=1'b0; clr_wc<=1'b0; inc_wc<=1'b0; dec_length<=1'b0;
			BaseSel<=3'd4; sel1<=1'b0; sel2<=2'd0; sel7<=1'b0; add_sub<=1'b0; carry_en<=2'd0; lsb_en<=1'b0; 
			R1set<=1'b0; Cen<=1'b0; Cshift<=1'b0; address_carryin<=1'b0; wea<=1'b0; mask_d_en<=1'b0;
			end
	6'd26:begin		// CL<--b0[i]-d0[i]; R2<--b1[i]; Fetch d1[i];
			en1<=1'b0; en2<=1'b1; clr1<=1'b0; clr2<=1'b0; clr_wc<=1'b0; inc_wc<=1'b0; dec_length<=1'b0;
			BaseSel<=3'd1; sel1<=1'b0; sel7<=1'b1; add_sub<=1'b1; lsb_en<=1'b0;
			R1set<=1'b0; Cen<=1'b1; Cshift<=1'b0; address_carryin<=1'b0; wea<=1'b0; mask_d_en<=1'b0;
			if(wc_zero) begin sel2<=2'd3; carry_en<=2'd3; end
			else begin sel2<=2'd1; carry_en<=2'd1; end
			end
	6'd27:begin		// R1<--d1[i]; RAM[b0+i]<--CL;
			en1<=1'b1; en2<=1'b0; clr1<=1'b0; clr2<=1'b0; clr_wc<=1'b0; inc_wc<=1'b0; dec_length<=1'b0;
			BaseSel<=3'd2; sel1<=1'b0; sel2<=2'd0; sel7<=1'b0; add_sub<=1'b0; carry_en<=2'd0; lsb_en<=1'b0;
			R1set<=1'b0; Cen<=1'b0; Cshift<=1'b0; address_carryin<=1'b0; wea<=1'b1; mask_d_en<=1'b0;
			end
	6'd28:begin		// CL<--b1[i]-d1[i]; 
			en1<=1'b0; en2<=1'b0; clr1<=1'b0; clr2<=1'b0; clr_wc<=1'b0; inc_wc<=1'b0; dec_length<=1'b0;
			BaseSel<=3'd5; sel1<=1'b0; sel7<=1'b0; add_sub<=1'b1; carry_en<=2'd2; lsb_en<=1'b0;
			R1set<=1'b0; Cen<=1'b1; Cshift<=1'b0; address_carryin<=1'b0; wea<=1'b0; mask_d_en<=1'b0;
			if(wc_zero) sel2<=2'd0; else sel2<=2'd2;
			end
	6'd29:begin		// RAM[b1+i]<--CL; Increment wc;
			en1<=1'b0; en2<=1'b0; clr1<=1'b0; clr2<=1'b0; inc_wc<=1'b1; dec_length<=1'b0;
			BaseSel<=3'd4; sel1<=1'b0; sel2<=2'd0; sel7<=1'b0; add_sub<=1'b0; carry_en<=2'd0; lsb_en<=1'b0;
			R1set<=1'b0; Cen<=1'b0; Cshift<=1'b0; address_carryin<=1'b0; wea<=1'b1; mask_d_en<=1'b0;
			if(wc_half) clr_wc<=1'b1; else clr_wc<=1'b0; 	
			end
	//////// END of final step : b0<--b0-d0; b1<--b1-d1 ////////		


	////////////////////////////////////////////////////////////////
	////////////////////////////////////////////////////////////////
	/////		Start of zero-free TNAF generation from b0,b1	///////
	////////////////////////////////////////////////////////////////
	6'd30:begin		// GAP State
			en1<=1'b0; en2<=1'b0; clr1<=1'b1; clr2<=1'b1; clr_wc<=1'b1; inc_wc<=1'b0; dec_length<=1'b0;
			BaseSel<=3'd2; sel1<=1'b0; sel2<=2'd0; sel7<=1'b0; add_sub<=1'b0; carry_en<=2'd0; lsb_en<=1'b0;
			R1set<=1'b0; Cen<=1'b0; Cshift<=1'b1; address_carryin<=1'b0; wea<=1'b0; mask_d_en<=1'b0;
			end


	//////// Computation of b0 and b1 starts ////////
	6'd31:begin		// Fetch b0[i];
			en1<=1'b0; en2<=1'b0; clr1<=1'b0; clr2<=1'b0; clr_wc<=1'b0; inc_wc<=1'b0; dec_length<=1'b0;
			BaseSel<=3'd2; sel1<=1'b0; sel2<=2'd0; sel7<=1'b0; add_sub<=1'b0; carry_en<=2'd0; lsb_en<=1'b0;
			R1set<=1'b0; Cen<=1'b0; Cshift<=1'b0; address_carryin<=1'b0; wea<=1'b0; mask_d_en<=1'b0;
			end
	6'd32:begin		// Fetch b0[i+1]; R2<--b0[i];
			en1<=1'b0; en2<=1'b1; clr1<=1'b0; clr2<=1'b0; clr_wc<=1'b0; inc_wc<=1'b0; dec_length<=1'b0;
			BaseSel<=3'd2; sel1<=1'b0; sel2<=2'd0; sel7<=1'b0; add_sub<=1'b0; carry_en<=2'd0; lsb_en<=1'b0^wc_half;
			R1set<=1'b0; Cen<=1'b0; Cshift<=1'b0; address_carryin<=1'b1; wea<=1'b0; mask_d_en<=1'b0;
			end
	6'd33:begin		// LSB<--b0[i+1][0]; Fetch b1[i]; Clr R1;
			en1<=1'b0; en2<=1'b0; clr1<=1'b1; clr2<=1'b0; clr_wc<=1'b0; inc_wc<=1'b0; dec_length<=1'b0;
			BaseSel<=3'd4; sel1<=1'b0; sel2<=2'd0; sel7<=1'b0; add_sub<=1'b0; carry_en<=2'd0; lsb_en<=1'b1^wc_half;
			R1set<=1'b0; Cen<=1'b0; Cshift<=1'b0; address_carryin<=1'b0; wea<=1'b0; mask_d_en<=1'b0;
			end
	6'd34:begin		// CL<--b0/2; R1<--b1[i];
			en1<=1'b1; en2<=1'b0; clr1<=1'b0; clr2<=1'b0; clr_wc<=1'b0; inc_wc<=1'b0; dec_length<=1'b0;
			BaseSel<=3'd4; sel1<=1'b1; sel2<=2'd0; sel7<=1'b0; add_sub<=1'b0; carry_en<=2'd0; lsb_en<=1'b0;
			R1set<=1'b0; Cen<=1'b1; Cshift<=1'b0; address_carryin<=1'b0; wea<=1'b0;
				if(wc_zero) mask_d_en<=1'b1; else mask_d_en<=1'b0; 
			end
	6'd35:begin		// RAM[b1+i]<--CL; CL<--b0/2-b1;
			en1<=1'b0; en2<=1'b0; clr1<=1'b0; clr2<=1'b0; clr_wc<=1'b0; inc_wc<=1'b0; dec_length<=1'b0;
			BaseSel<=3'd4; sel1<=1'b1; sel7<=1'b0; add_sub<=1'b1; carry_en<=2'd1; lsb_en<=1'b0;
			R1set<=1'b0; Cen<=1'b1; Cshift<=1'b0; address_carryin<=1'b0; wea<=1'b1;
			//if(wc_zero) sel2<=2'd0; else sel2<=2'd1;
				if(wc_zero) begin mask_d_en<=1'b1; sel2<=2'd3; end
				else begin mask_d_en<=1'b0; sel2<=2'd1; end
			end
	6'd36:begin		// RAM[b0+i]<--CL; Increment wc;
			en1<=1'b0; en2<=1'b0; clr1<=1'b0; clr2<=1'b0; dec_length<=1'b0;
			BaseSel<=3'd2; sel1<=1'b1; sel7<=1'b0; add_sub<=1'b1; carry_en<=2'd0; lsb_en<=1'b0;
			R1set<=1'b0; Cen<=1'b0; Cshift<=1'b0; address_carryin<=1'b0; wea<=1'b1; mask_d_en<=1'b0;
			if(wc_half) clr_wc<=1'b1; else clr_wc<=1'b0;
			if(wc_zero) begin sel2<=2'd0; inc_wc<=1'b0; end 
			else begin sel2<=2'd1; inc_wc<=1'b1; end
			end
	//////// END : Computation of b0 and b1 	////////
	6'd37:begin		// Final tau-NAF bit;
			en1<=1'b0; en2<=1'b0; clr1<=1'b0; clr2<=1'b0; clr_wc<=1'b1; inc_wc<=1'b0; dec_length<=1'b0;
			BaseSel<=3'd2; sel1<=1'b1; sel2<=2'd0; sel7<=1'b0; add_sub<=1'b1; carry_en<=2'd0; lsb_en<=1'b0;
			R1set<=1'b0; Cen<=1'b0; Cshift<=1'b0; address_carryin<=1'b0; wea<=1'b0; mask_d_en<=1'b1;
			end


	//////// Start : Load the T-bit in the words of d0 (starting from d0[i] ///////
	6'd38: begin		// Fetch d0[i]; i<--index(length_counter)
			en1<=1'b0; en2<=1'b0; clr1<=1'b0; clr2<=1'b0; clr_wc<=1'b0; inc_wc<=1'b0; dec_length<=1'b0;
			BaseSel<=3'd0; sel1<=1'b0; sel2<=2'd0; sel7<=1'b0; add_sub<=1'b0; carry_en<=2'd0; lsb_en<=1'b0;
			R1set<=1'b0; Cen<=1'b0; Cshift<=1'b0; address_carryin<=1'b0; wea<=1'b0; mask_d_en<=1'b0;
			end
	6'd39: begin		// R2, R1<--d0[i]; 
			en1<=1'b1; en2<=1'b1; clr1<=1'b0; clr2<=1'b0; clr_wc<=1'b0; inc_wc<=1'b0; dec_length<=1'b0;
			BaseSel<=3'd0; sel1<=1'b0; sel2<=2'd0; sel7<=1'b0; add_sub<=1'b0; carry_en<=2'd0; lsb_en<=1'b0;
			R1set<=1'b0; Cen<=1'b0; Cshift<=1'b0; address_carryin<=1'b0; wea<=1'b0; mask_d_en<=1'b0;
			end
	6'd40: begin		// CL<--R2+R1+Tbit={d0[i],Tbit}; 
			en1<=1'b0; en2<=1'b0; clr1<=1'b0; clr2<=1'b0; clr_wc<=1'b0; inc_wc<=1'b0; dec_length<=1'b0;
			BaseSel<=3'd0; sel1<=1'b0; sel2<=2'd3; sel7<=1'b1; add_sub<=1'b0; carry_en<=2'd0; lsb_en<=1'b0;
			R1set<=1'b0; Cen<=1'b1; Cshift<=1'b0; address_carryin<=1'b0; wea<=1'b0; mask_d_en<=1'b0;
			end
	6'd41: begin		// RAM[&d0+i]<--CL; Increment wc
			en1<=1'b0; en2<=1'b0; clr1<=1'b0; clr2<=1'b0; clr_wc<=1'b0; inc_wc<=1'b1; dec_length<=1'b0;
			BaseSel<=3'd0; sel1<=1'b1; sel2<=2'd0; sel7<=1'b0; add_sub<=1'b0; carry_en<=2'd0; lsb_en<=1'b0;
			R1set<=1'b0; Cen<=1'b1; Cshift<=1'b0; address_carryin<=1'b0; wea<=1'b1; mask_d_en<=1'b0;
			end

//////////////////////////////////////////////////////////////////////
	//////// Start : Generate T-NAF from MSB to LSB ///////
	6'd42: begin		// Clear counter wc; This unique state is also used to store the length bit.
			en1<=1'b0; en2<=1'b0; clr1<=1'b0; clr2<=1'b0; clr_wc<=1'b1; inc_wc<=1'b0; dec_length<=1'b0;
			BaseSel<=3'd0; sel1<=1'b0; sel2<=2'd0; sel7<=1'b0; add_sub<=1'b0; carry_en<=2'd0; lsb_en<=1'b0;
			R1set<=1'b0; Cen<=1'b0; Cshift<=1'b0; address_carryin<=1'b0; wea<=1'b0; mask_d_en<=1'b0;
			end

	///// Start generating only one tnaf bit when the length is odd
	6'd47:begin		// Fetch d0[i]; i<--index(length_counter); Clear R1;  
			en1<=1'b0; en2<=1'b0; clr1<=1'b1; clr2<=1'b0; clr_wc<=1'b0; inc_wc<=1'b0; dec_length<=1'b0;
			BaseSel<=3'd0; sel1<=1'b0; sel2<=2'd0; sel7<=1'b0; add_sub<=1'b0; carry_en<=2'd0; lsb_en<=1'b0;
			R1set<=1'b0; Cen<=1'b0; Cshift<=1'b0; address_carryin<=1'b0; wea<=1'b0; mask_d_en<=1'b0;
			end
	6'd48:begin		// R2<--d0[i]; Store lsb;
			en1<=1'b0; en2<=1'b1; clr1<=1'b0; clr2<=1'b0; clr_wc<=1'b0; inc_wc<=1'b0; dec_length<=1'b0;
			BaseSel<=3'd0; sel1<=1'b0; sel2<=2'd0; sel7<=1'b0; add_sub<=1'b0; carry_en<=2'd0; lsb_en<=1'b1;
			R1set<=1'b0; Cen<=1'b0; Cshift<=1'b0; address_carryin<=1'b0; wea<=1'b0; mask_d_en<=1'b0;
			end
	6'd49:begin		// CL<--{x,d0/2};
			en1<=1'b0; en2<=1'b0; clr1<=1'b0; clr2<=1'b0; clr_wc<=1'b0; inc_wc<=1'b0; dec_length<=1'b0;
			BaseSel<=3'd0; sel1<=1'b1; sel2<=2'd0; sel7<=1'b1; add_sub<=1'b0; carry_en<=2'd0; lsb_en<=1'b0;
			R1set<=1'b0; Cen<=1'b1; Cshift<=1'b0; address_carryin<=1'b0; wea<=1'b0; mask_d_en<=1'b0;
			end
	6'd50:begin		// RAM[&d0+i]<--CL; Decrement length; 
			en1<=1'b0; en2<=1'b0; clr1<=1'b0; clr2<=1'b0; clr_wc<=1'b0; inc_wc<=1'b0; dec_length<=1'b1;
			BaseSel<=3'd0; sel1<=1'b1; sel2<=2'd0; sel7<=1'b0; add_sub<=1'b0; carry_en<=2'd0; lsb_en<=1'b0;
			R1set<=1'b0; Cen<=1'b1; Cshift<=1'b0; address_carryin<=1'b0; wea<=1'b1; mask_d_en<=1'b0;
			end	

	///// Start generating pair of tnaf bits 
	6'd51:begin		// Fetch d0[i]; i<--index(length_counter);  
			en1<=1'b0; en2<=1'b0; clr1<=1'b0; clr2<=1'b0; clr_wc<=1'b0; inc_wc<=1'b0; dec_length<=1'b0;
			BaseSel<=3'd0; sel1<=1'b0; sel2<=2'd0; sel7<=1'b0; add_sub<=1'b0; carry_en<=2'd0; lsb_en<=1'b0;
			R1set<=1'b0; Cen<=1'b0; Cshift<=1'b0; address_carryin<=1'b0; wea<=1'b0; mask_d_en<=1'b0;
			end
	6'd52:begin		// R2<--d0[i]; Store lsb;
			en1<=1'b0; en2<=1'b1; clr1<=1'b0; clr2<=1'b0; clr_wc<=1'b0; inc_wc<=1'b0; dec_length<=1'b0;
			BaseSel<=3'd0; sel1<=1'b0; sel2<=2'd0; sel7<=1'b0; add_sub<=1'b0; carry_en<=2'd0; lsb_en<=1'b1;
			R1set<=1'b0; Cen<=1'b0; Cshift<=1'b0; address_carryin<=1'b0; wea<=1'b0; mask_d_en<=1'b0;
			end
	6'd53:begin		// CL<--{x,d0/2}; 
			en1<=1'b0; en2<=1'b0; clr1<=1'b0; clr2<=1'b0; clr_wc<=1'b0; inc_wc<=1'b0; dec_length<=1'b0;
			BaseSel<=3'd0; sel1<=1'b1; sel2<=2'd0; sel7<=1'b1; add_sub<=1'b0; carry_en<=2'd0; lsb_en<=1'b0;
			R1set<=1'b0; Cen<=1'b1; Cshift<=1'b0; address_carryin<=1'b0; wea<=1'b0; mask_d_en<=1'b0;
			end
	6'd54:begin		// RAM[&d0+i]<--CL; Decrement length; 
			en1<=1'b0; en2<=1'b0; clr1<=1'b0; clr2<=1'b0; clr_wc<=1'b0; inc_wc<=1'b0; dec_length<=1'b1;
			BaseSel<=3'd0; sel1<=1'b1; sel2<=2'd0; sel7<=1'b0; add_sub<=1'b0; carry_en<=2'd0; lsb_en<=1'b0;
			R1set<=1'b0; Cen<=1'b1; Cshift<=1'b0; address_carryin<=1'b0; wea<=1'b1; mask_d_en<=1'b0;
			end
	6'd55:begin		// Check length; 
			en1<=1'b0; en2<=1'b0; clr1<=1'b0; clr2<=1'b0; clr_wc<=1'b0; inc_wc<=1'b0; dec_length<=1'b0;
			BaseSel<=3'd0; sel1<=1'b1; sel2<=2'd0; sel7<=1'b0; add_sub<=1'b0; carry_en<=2'd0; lsb_en<=1'b0;
			R1set<=1'b0; Cen<=1'b0; Cshift<=1'b0; address_carryin<=1'b0; wea<=1'b0; mask_d_en<=1'b0;
			end



//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////

	6'd63:begin		// END or Suspend
			en1<=1'b0; en2<=1'b0; clr1<=1'b0; clr2<=1'b0; clr_wc<=1'b0; inc_wc<=1'b0; dec_length<=1'b0;
			BaseSel<=3'd0; sel1<=1'b0; sel2<=2'd0; sel7<=1'b0; add_sub<=1'b0; carry_en<=2'd0; lsb_en<=1'b0;
			R1set<=1'b0; Cen<=1'b0; Cshift<=1'b0; address_carryin<=1'b0; wea<=1'b0; mask_d_en<=1'b0;
			end
	default: begin		// RST state
			en1<=1'b0; en2<=1'b0; clr1<=1'b0; clr2<=1'b0; clr_wc<=1'b0; inc_wc<=1'b0; dec_length<=1'b0;
			BaseSel<=3'd0; sel1<=1'b0; sel2<=2'd0; sel7<=1'b0; add_sub<=1'b0; carry_en<=2'd0; lsb_en<=1'b0;
			R1set<=1'b0; Cen<=1'b0; Cshift<=1'b0; address_carryin<=1'b0; wea<=1'b0; mask_d_en<=1'b0;
			end

	endcase
end	


always @(state or wc_zero or wc_full or wc_half or lc_full or terminal_condition
			or length_even or length_counter[0])
begin
	case(state)
	6'd0: nextstate<=6'd1;
	6'd1: begin	// Load d1
				if(wc_full)
					nextstate<=6'd2;
				else	
					nextstate<=6'd1;
			end	
	6'd2: begin // Load b0
				if(wc_full)
					nextstate<=6'd3;
				else
					nextstate<=6'd2;
			end
	6'd3: begin // Load a0, a1
				if(wc_full)
					nextstate<=6'd4;
				else
					nextstate<=6'd3;
			end	
	6'd4: nextstate<=6'd62;
	6'd62: nextstate<=6'd12;
	
	// states for b0, b1
	6'd5: nextstate<=6'd6;
	6'd6: nextstate<=6'd7;
	6'd7: nextstate<=6'd8;
	6'd8: nextstate<=6'd9;
	6'd9: nextstate<=6'd10;
	6'd10: nextstate<=6'd11;
	6'd11: begin
				if(wc_half)
					nextstate<=6'd18;
				else
					nextstate<=6'd5;
			end

	// states for d0, d1
	6'd12: nextstate<=6'd13;
	6'd13: nextstate<=6'd14;
	6'd14: nextstate<=6'd15;
	6'd15: nextstate<=6'd16;
	6'd16: nextstate<=6'd17;
	6'd17: begin
				if(wc_full)
					nextstate<=6'd5;
				else	
					nextstate<=6'd12;
			end	
		
	// states for a0, a1	
	6'd18: nextstate<=6'd19;
	6'd19: nextstate<=6'd20;
	6'd20: nextstate<=6'd21;
	6'd21: nextstate<=6'd22;	
	6'd22: begin
				if(lc_full & wc_half)
					nextstate<=6'd23;
				else if(wc_half)
					nextstate<=6'd12;
				else	
					nextstate<=6'd18;
			end

	// states for Final Addition	
	6'd23: nextstate<=6'd24;
	6'd24: nextstate<=6'd25;
	6'd25: nextstate<=6'd26;
	6'd26: nextstate<=6'd27;
	6'd27: nextstate<=6'd28;
	6'd28: nextstate<=6'd29;
	6'd29: begin
				if(wc_half)
					nextstate<=6'd30;
				else
					nextstate<=6'd23;
			end


	6'd30: nextstate<=6'd31;
	6'd31: nextstate<=6'd32;
	6'd32: nextstate<=6'd33;
	6'd33: nextstate<=6'd34;
	6'd34: nextstate<=6'd35;
	6'd35: nextstate<=6'd36;
	6'd36: begin
				if(terminal_condition)
					nextstate<=6'd37;
				else if(wc_zero)
					nextstate<=6'd38;
				else
					nextstate<=6'd31;
			end
	6'd37: nextstate<=6'd38;

	6'd38: nextstate<=6'd39;
	6'd39: nextstate<=6'd40;
	6'd40: nextstate<=6'd41;
	6'd41: begin
				if(terminal_condition)
					nextstate<=6'd42;
				else
					nextstate<=6'd31;
			end
			
			
//	6'd42: nextstate<=6'd43;			
	6'd42: nextstate<=6'd47;			
/*	6'd43: begin
				if(shifting_complete)
					nextstate<=6'd47;	
				else			
					nextstate<=6'd44;
			end
	6'd44: nextstate<=6'd45;
	6'd45: nextstate<=6'd46;
	6'd46: nextstate<=6'd43;	*/

	6'd47: begin
				if(length_even)
					nextstate<=6'd51;	
				else			
					nextstate<=6'd48;
			end			
	6'd48: nextstate<=6'd49;
	6'd49: nextstate<=6'd50;
	6'd50: nextstate<=6'd63;			// Go to ready state
	
	6'd51: nextstate<=6'd52;
	6'd52: nextstate<=6'd53;
	6'd53: nextstate<=6'd54;
	6'd54: nextstate<=6'd55;
	6'd55: begin
				if(length_counter[0])
					nextstate<=6'd63;		// Go to ready state
				else			
					nextstate<=6'd51;
			end

	6'd63: nextstate<=6'd51;

/*
	6'd63: begin
				if(suspend)
					nextstate<=6'd63;
				else
					nextstate<=6'd51;
			end
*/			
	default: nextstate<=6'd63;
	endcase
end
	
	
assign SCOffset = (state>6'd37) ? length_counter[8:4] : word_counter;
assign Tbit_ready = (state==6'd63) ? 1'b1 : 1'b0;
assign done_wire = (Tbit_ready & (length_counter==9'd511)) ? 1'b1 : 1'b0;

always @(posedge clk)
begin
	if(rst)
		done<=1'b0;
	else
		done<= done_wire | done;
end		

endmodule



