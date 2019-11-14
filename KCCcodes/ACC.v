//////////////////////////////////////////////////////////////////////////////////
// Company: COSIC KU Leuven
// Engineer: Sujoy Sinha Roy
// 
// Create Date:    16:56:39 07/22/2014 
// Design Name: 
// Module Name:    ACC 
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
module ACC(clk, rst, rst_d_carry, en1, en2, clr1, clr2, R1set, lsb_en, lsb_en_mode, carry_en, mode, sel1, sel2, add, 
			  sel3, sel4, sel5, sel6, sel7, Tbit_sign,  mask, mask_d_en, Cen, Cshift, 
			  terminal_condition, ROM_sel, enable_flag_adjustment,
			  LSB_store, Tbit_no_sign, doutb, dina, b0_one, b1_zero, Tbit_pair, M4_out0, flag_adjustment,
			  CL, R2, R1);

input clk, rst, rst_d_carry;
input en1, en2, clr1, clr2, R1set, lsb_en, lsb_en_mode;
input [1:0] sel2, carry_en, mode;
input sel1, sel3, sel4, sel5, sel6, sel7, Tbit_sign, mask, mask_d_en, add, Cen, Cshift, terminal_condition, enable_flag_adjustment;
input [2:0] ROM_sel;

output LSB_store;				// This is required during the scalar-reduction to check if d0 is odd;
output Tbit_no_sign; 				// // used to perform add/sub during computation of b0
input [15:0] doutb;
output [15:0] dina;
output b0_one, b1_zero; 	// used to check terminal conditions during the tau-NAF generation
output [1:0] Tbit_pair;		// Tnaf bits are output as pairs starting from MSB.
output M4_out0;				// is used to decide the final_adjustment
output reg [1:0] flag_adjustment;	//	flag_adjustment = 0x ---> nothing
												//                 = 10 ---> add (\tau-1)*P
												//                 = 11 ---> sub (\tau+1)*P

// test signals
output [15:0] CL, R2, R1;

reg [15:0] R1, R2, CL, CU;
reg [4:0] T;
reg LSB_store, LSB_store_delayed, carryout1, carryout2;
reg d0_even;

wire [15:0] M1_out, M2_out, M3_out, M4_out, M5_out, sum_out, badd_out1, badd_out2, ROM_out;
wire [30:0] mult_out;
wire carry_in, carry_out, R1_lsb, R2_1_masked, R1_0_masked, R_carry, Tbit, Tbit_R_carry, Tbit_R_carry_d0_even, M4_out_lsb, en_T;
wire [4:0] masked_CL;

always @(posedge clk)
begin
	if(clr1) R1<=16'd0;
	else if(en1) R1<=doutb;
	else R1<=R1;
end	

always @(posedge clk)
begin
	if(clr2) R2<=16'd0;
	else if(en2) R2<=doutb;
	else R2<=R2;
end
always @(posedge clk)
begin
	if(lsb_en)
		LSB_store <= (lsb_en_mode) ? doutb[15] : doutb[0];
	else
		LSB_store <= LSB_store;
end

always @(posedge clk)
begin
	if(lsb_en)
		LSB_store_delayed <= LSB_store;
	else
		LSB_store_delayed <= LSB_store_delayed;
end

always @(posedge clk)
begin
	if(carry_en[0]==1'b1) carryout1<=carry_out;
	else carryout1<=carryout1;
end
always @(posedge clk)
begin
	if(carry_en==2'd2) carryout2<=carry_out;
	else carryout2<=carryout2;
end
always @(posedge clk)
begin
	if(carry_en==2'd3) d0_even <= ~doutb[0];
	else d0_even<=d0_even;
end


mask_d	mskd(clk, rst_d_carry, mask_d_en, R2[1], R1[0], doutb[0], Tbit_sign, terminal_condition,
				  R2_1_masked, R1_0_masked, R_carry, Tbit, Tbit_no_sign);


mux2 M1({R2[15:2],R2_1_masked,R2[0]}, {LSB_store,R2[15:2],R2_1_masked}, sel1, M1_out);
assign Tbit_R_carry = (sel7) ? Tbit : R_carry;
assign Tbit_R_carry_d0_even = ((sel7==1'b1) && (carry_en==2'd3)) ? d0_even : Tbit_R_carry;
assign carry_in = (sel2==2'd2) ? carryout2 
		 :(sel2==2'd1) ? carryout1
		 :(sel2==2'd0) ? 1'b0
		 :Tbit_R_carry_d0_even;
assign R1_lsb = (R1set) ? 1'b1 : R1_0_masked;
adder_subtracter	AS(M1_out, {R1[15:1],R1_lsb}, carry_in, add, sum_out, carry_out);

ROM1 RM(ROM_sel, ROM_out);
mux2 M2(R1, ROM_out, sel4, M2_out);
sb16 sb(R2, M2_out, mult_out);
mux2 M3(16'd0, CL, sel5, M3_out);
binary_adder badd1(mult_out[15:0], M3_out, badd_out1);
mux2 M4(sum_out, badd_out1, sel3, M4_out);

assign M4_out0 = M4_out[0];
assign M4_out_lsb = M4_out[0]^enable_flag_adjustment;


mux2 M5(16'd0, CU, sel5, M5_out);
binary_adder badd2({1'b0,mult_out[30:16]}, M5_out, badd_out2);

//// Previous b0_one and b1_zero before correction: Date 11th July, 2016 //
//assign b0_one = (R2[7:0]==8'd1) ? 1'b1 : 1'b0;

//// Now b0_one after correction: Date 11th July, 2016 //
assign b0_one = (R2[7:0]==8'd1 || R2[7:0]==8'd255) ? 1'b1 : 1'b0;
assign b1_zero = ((R1[7:0]==8'd0)&(R_carry==1'b0))||((R1[7:0]==8'd255)&(R_carry==1'b1)) ? 1'b1 : 1'b0;


always @(posedge clk)
begin
	if(Cshift)
		{CU, CL} <= {16'd0, CU};
	else if (Cen)	
		{CU, CL} <= {badd_out2, M4_out[15:1], M4_out_lsb};
	else
		{CU, CL} <= {CU, CL};
end	

assign en_T = ((mode==2'd1) & (Cshift|Cen)) | ((mode==2'd0) & (Cshift));
always @(posedge clk)
begin
//	if(Cshift)
	if(en_T)
		T <= CL[15:11];
	else
		T <= T;
end		

always @(posedge clk)
begin
	if(rst)
		flag_adjustment <= 2'd0;
	else if(enable_flag_adjustment)
		flag_adjustment <= {flag_adjustment[0],M4_out_lsb};
	else	
		flag_adjustment <= flag_adjustment;
end
		

						
assign masked_CL = (mask) ? 5'd0 : CL[15:11];
assign dina = (sel6) ? {CL[10:0],T} : {masked_CL,CL[10:0]};


assign Tbit_pair = {LSB_store, LSB_store_delayed};

endmodule
