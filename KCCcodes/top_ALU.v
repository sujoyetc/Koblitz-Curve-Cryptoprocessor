//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    17:16:31 09/09/2014 
// Design Name: 
// Module Name:    top_ALU 
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
module top_ALU(clk, rst, rst_d_carry, control_group1, control_group2, mode, sel4, sel5, ROM_sel, 
	       LSB_store, Tbit_no_sign, doutb, dina, b0_one, b1_zero, Tbit_pair, M4_out0, flag_adjustment,
		CL, R2, R1);
input clk, rst, rst_d_carry;
input [8:0] control_group1;
input [13:0] control_group2;
input sel4, sel5;
input [1:0] mode;
input [2:0] ROM_sel;

output LSB_store;				// This is required during the scalar-reduction to check if d0 is odd;
output Tbit_no_sign;
input [15:0] doutb;
output [15:0] dina;
output b0_one, b1_zero; 	// used to check terminal conditions during the tau-NAF generation
output [1:0] Tbit_pair;		// Tnaf bits are output as pairs starting from MSB.
output M4_out0;				// is used to decide the final_adjustment
output [1:0] flag_adjustment;	//	flag_adjustment = 0x ---> nothing
										//                 = 10 ---> add (\tau-1)*P
										//                 = 11 ---> sub (\tau+1)*P
output [15:0] CL, R2, R1;


wire en1, en2, clr1, clr2, R1set, lsb_en, lsb_en_mode;
wire [1:0] sel2, carry_en;
wire sel1, sel3, sel4, sel5, sel6, sel7, Tbit_sign, mask, mask_d_en, add_sub, Cen, Cshift, terminal_condition, enable_flag_adjustment;
wire [2:0] ROM_sel;

assign {en1, en2, clr1, clr2, sel3, sel6, mask, Cen, Cshift}= control_group1; 
									 
assign {sel1, sel2, sel7, Tbit_sign, mask_d_en, enable_flag_adjustment, add_sub, 
		  carry_en, lsb_en, lsb_en_mode, R1set, terminal_condition} = control_group2;


ACC		AL(clk, rst, rst_d_carry, en1, en2, clr1, clr2, R1set, lsb_en, lsb_en_mode, carry_en, mode, sel1, sel2, add_sub, 
			  sel3, sel4, sel5, sel6, sel7, Tbit_sign,  mask, mask_d_en, Cen, Cshift, 
			  terminal_condition, ROM_sel, enable_flag_adjustment,
			  LSB_store, Tbit_no_sign, doutb, dina, b0_one, b1_zero, Tbit_pair, M4_out0, flag_adjustment,
			  CL, R2, R1);

endmodule
