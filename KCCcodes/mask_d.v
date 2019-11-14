//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    22:23:36 08/28/2014 
// Design Name: 
// Module Name:    mask_d 
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
module mask_d(clk, rst, mask_d_en, R2_1, R1_0, dout_lsb, Tbit_sign, terminal_condition,
				  R2_1_masked, R1_0_masked, d_carry, Tbit, Tbit_no_sign);
input clk, rst;
input mask_d_en;
input R2_1, R1_0, dout_lsb, Tbit_sign, terminal_condition;

output R2_1_masked, R1_0_masked;
output reg d_carry;
output reg Tbit, Tbit_no_sign;

wire Tbit_wire;
wire d_carry_wire;
reg mask_d_en_delayed;

assign R2_1_masked = (mask_d_en & (!R2_1) & (!(dout_lsb^d_carry))) ? 1'b1 : R2_1;
assign d_carry_wire = (mask_d_en & R2_1 & (dout_lsb^d_carry));
assign R1_0_masked = (d_carry_wire) ? 1'b0 : R1_0;

//assign Tbit_wire = ((mask_d_en & (R2_1^dout_lsb^d_carry)) | terminal_condition) ? 1'b1 : 1'b0;
assign Tbit_wire = (mask_d_en & (R2_1^dout_lsb^d_carry)) ? 1'b1 : 1'b0;

always @(posedge clk)
begin
	if(rst)
		d_carry <= 1'b0;
	else if(mask_d_en & mask_d_en_delayed)	// Delayed version is used as there are two consecutive masking and the first one changes the value of the register
		d_carry <= d_carry_wire;
	else 
		d_carry <= d_carry;
end

always @(posedge clk)
begin
	if(rst)
		Tbit<=1'b0;
	else if((mask_d_en & mask_d_en_delayed) | (mask_d_en & terminal_condition))	
		Tbit<=Tbit_wire^Tbit_sign;
	else
		Tbit<=Tbit;
end

always @(posedge clk)
begin
	if(mask_d_en & mask_d_en_delayed)
		Tbit_no_sign <= Tbit_wire;
	else 	
		Tbit_no_sign <= Tbit_no_sign;
end
		
always @(posedge clk)	
mask_d_en_delayed <= mask_d_en;
	
endmodule





