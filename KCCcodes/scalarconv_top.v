//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    11:54:25 09/09/2014 
// Design Name: 
// Module Name:    scalarconv_top 
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
module scalarconv_top(clk, rst, suspend, Tbit_no_sign, b0_one, b1_zero, M4_out0, flag_adjustment,
         		rst_d_carry, control_group1, control_group2, wea, address_carryin, BaseSel, SCOffset,
			length_even, Tbit_ready, done,
			state, length_counter);
input clk, rst;
input suspend;		// When this is high, the state-machine halts 
input Tbit_no_sign;
input b0_one, b1_zero; // used to check terminal conditions during tau-NAF generation
input M4_out0;				// used during the final adjustment after scalar multiplication.
input [1:0] flag_adjustment;

output rst_d_carry;
output [8:0] control_group1;
output [13:0] control_group2;
output wea, address_carryin;
output [2:0] BaseSel;
output [4:0] SCOffset;
output length_even;
output Tbit_ready, done;

//tst
output [5:0] state;
output [8:0] length_counter;

wire en1, en2, clr1, clr2, sel1, sel7, R1set, Cen, Cshift;
wire terminal_condition, enable_flag_adjustment;
wire add_sub, lsb_en, address_carryin, wea, mask_d_en;
wire [1:0] sel2, carry_en;
wire [2:0] BaseSel; 
wire sel3, sel6, Tbit_sign, mask, lsb_en_mode;
wire length_even;	// This is 1 when the length of the TNAF generated is even.
wire Tbit_ready, done;

scalarconv_tnaf	SC(clk, rst, suspend, Tbit_no_sign, b0_one, b1_zero, M4_out0, flag_adjustment,
			rst_d_carry, en1, en2, clr1, clr2, sel1, sel2, sel3, sel6, sel7, Tbit_sign, mask, mask_d_en, enable_flag_adjustment,
			add_sub, carry_en, lsb_en, lsb_en_mode, address_carryin, R1set, Cen, Cshift, terminal_condition,
			BaseSel, SCOffset, wea, length_even, Tbit_ready, done,
			state, length_counter);




assign control_group1 = {en1, en2, clr1, clr2, sel3, sel6, mask, Cen, Cshift}; 
									 
assign control_group2 = {sel1, sel2, sel7, Tbit_sign, mask_d_en, enable_flag_adjustment, add_sub, 
									  carry_en, lsb_en, lsb_en_mode, R1set, terminal_condition};

endmodule
