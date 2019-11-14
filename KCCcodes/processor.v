//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    15:07:54 09/09/2014 
// Design Name: 
// Module Name:    processor 
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
module 	processor(clk, rst, instruction_ready, instruction, op0, op1, op2,
			address, doutb, dina, wea, length_even, done_SC, Tbit_pair, flag_adjustment, instruction_executed,
			state_SC);
			
//			suspend, en_primitive, en_invert, mode, state_SC, state_PR, length_counter, SCOffset, CL, R2, R1, control_group1,
//			sel5, state_inv, inv_rom_dout, count, BasePtSel);
			
input clk, rst;
input instruction_ready;
input [2:0] instruction;
input [3:0] op0, op1, op2;

output [7:0] address;
input [15:0] doutb;
output [15:0] dina;
output wea;
output length_even, done_SC;
output [1:0] Tbit_pair, flag_adjustment;
output instruction_executed;
output [5:0] state_SC;

/*
// tst
output suspend, en_primitive, en_invert;
output [5:0] state_SC, state_PR;
output [8:0] length_counter;
output [4:0] SCOffset;
output [1:0] mode;
output [15:0] CL, R2, R1;
output [8:0] control_group1;
output sel5;
output [2:0]state_inv;
output [7:0] inv_rom_dout;
output [7:0] count;
output [3:0] BasePtSel;
*/

// tst
wire [5:0] state_SC, state_PR;
wire [8:0] length_counter;
wire [15:0] CL, R2, R1;
wire [2:0]state_inv;
wire [7:0] inv_rom_dout;
wire [7:0] count;


wire done_primitive, done_inversion;
wire [8:0] control_group3, control_group3_ins, control_group3_inv;

wire [3:0] BasePtSel;
wire [1:0] Base_en, mode;
wire en_primitive, en_invert, suspend;

wire sel4, sel5, OffsetSel;
wire [4:0] RdOffset, SCOffset;
wire [5:0] WtOffset;
wire [2:0] ROM_sel;
wire [2:0] BaseSel, BaseSel_SC, BaseSel_PR;

wire [8:0] control_group1, control_group1_SC, control_group1_PR;
wire [13:0] control_group2, control_group2_SC;
wire b0_one, b1_zero, M4_out0;				
wire [1:0] Tbit_pair, flag_adjustment;
wire wea, wea_SC, wea_PR, address_carryin;
wire Tbit_no_sign, rst_d_carry, LSB_store;


instruction_decoder  INS_DEC(clk, rst, instruction_ready, Tbit_ready,
									  instruction, op0, op1, op2, done_primitive, done_inversion,
							 		  control_group3_ins, en_invert, suspend,
									  instruction_executed);


scalarconv_top	 SC(clk, rst, suspend, Tbit_no_sign, b0_one, b1_zero, M4_out0, flag_adjustment,
	  	 rst_d_carry, control_group1_SC, control_group2_SC, wea_SC, address_carryin, BaseSel_SC, SCOffset,
		 length_even, Tbit_ready, done_SC,
		 state_SC, length_counter);

inversion_new	IN(clk, ~en_invert, done_primitive, 
							control_group3_inv, done_inversion, 
							state_inv, inv_rom_dout, count);

top_primitives	 PR(clk, ~en_primitive, mode,
							control_group1_PR, sel4, sel5, ROM_sel, wea_PR, BaseSel_PR,
							RdOffset, WtOffset, OffsetSel, done_primitive, state_PR);

top_ALU			ALU(clk, rst, rst_d_carry, control_group1, control_group2, mode, sel4, sel5, ROM_sel, 
			    LSB_store, Tbit_no_sign, doutb, dina, b0_one, b1_zero, Tbit_pair, M4_out0, flag_adjustment,
       			    CL, R2, R1);

addressb		ADDR(clk, RdOffset, WtOffset, SCOffset, suspend,
			     BasePtSel, BaseSel, OffsetSel, Base_en, address_carryin, address);					  

assign control_group1 = (suspend==1'b0) ? control_group1_SC : control_group1_PR;
assign control_group2 = control_group2_SC;
assign control_group3 = (en_invert) ? control_group3_inv : control_group3_ins;
assign wea = (suspend==1'b0) ? wea_SC: wea_PR;					  
assign BaseSel = (suspend==1'b0) ? BaseSel_SC : BaseSel_PR;
assign {BasePtSel, Base_en, mode, en_primitive} = control_group3;


endmodule
