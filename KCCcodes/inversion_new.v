//////////////////////////////////////////////////////////////////////////////////
// Company: COSIC KU Leuven	
// Engineer: Sujoy Sinha Roy
// 
// Create Date:    21:48:44 08/04/2014 
// Design Name: 
// Module Name:    inversion 
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
/*
module inversion(clk, rst, done_primitive, 
					  BasePtSel, Base_en, mode, en_primitive, 
					  done_inversion, state);
*/

module inversion_new(clk, rst, done_primitive, 
							control_group3, done_inversion, 
							state, inv_rom_dout, count);
					  
input clk, rst;
input done_primitive;	// This signal goes high after completion of a multiplication or squaring

output [8:0] control_group3;
output done_inversion;		

// tst
output [2:0] state;
output [7:0] inv_rom_dout;
output [7:0] count;


//assign control_group3 = {BasePtSel, Base_en, mode, en_primitive};

wire [3:0] BasePtSel;
reg [1:0] Base_en, mode;
reg en_primitive;

reg [3:0] inv_rom_address;
wire [7:0] inv_rom_dout;
reg [7:0] count;
wire count_one, chain_end, inv_rom_dout_one;
reg [2:0] BasePtSel1;
reg inc_rom_address, count_init, count_dec;
reg [2:0] state, nextstate;
reg first_run;

inversion_rom	inv_rom(inv_rom_address, inv_rom_dout);

assign BasePtSel = {1'b0, BasePtSel1};
assign control_group3 = {BasePtSel, Base_en, mode, en_primitive};

always @(posedge clk)
begin
	if(rst)
		inv_rom_address <= 4'd0;
	else if(inc_rom_address)
		inv_rom_address <= inv_rom_address + 1'b1;
	else
		inv_rom_address <= inv_rom_address;
end

always @(posedge clk)
begin
	if(count_init)
		count <= inv_rom_dout;
	else if(count_dec)
		count <= count - 1'b1;
	else
		count <= count;
end		

assign count_one = (count==8'd1) ? 1'b1 : 1'b0;
assign chain_end = (inv_rom_address==4'd11) ? 1'b1 : 1'b0;
assign inv_rom_dout_one = (inv_rom_dout==4'd1) ? 1'b1 : 1'b0;

always @(posedge clk)
begin
	if(rst)
		state<=3'd0;
	else
		state<=nextstate;
end		

always @(posedge clk)
begin
	if(rst)
		first_run<=1'b1;
	else if(state==3'd5)
		first_run<=1'b0;
	else
		first_run<=first_run;
end		

always @(state or first_run or inv_rom_dout_one)
begin
	case(state)
	3'd0: begin // Initial state
				BasePtSel1<=3'd0; Base_en<=2'd0; mode<=2'd0; en_primitive<=1'b0;
				inc_rom_address<=1'b0; count_init<=1'b0; count_dec<=1'b0;
			end

	3'd1: begin // Rd1<--6/7; Init Count; 
				Base_en<=2'd1; mode<=2'd0; en_primitive<=1'b0;
				inc_rom_address<=1'b0; count_init<=1'b1; count_dec<=1'b0;
				if(first_run) BasePtSel1<=3'd6; else BasePtSel1<=3'd7;  
			end
	3'd2: begin // Wt2<--1; Start Squaring;
				BasePtSel1<=3'd1; Base_en<=2'd0; mode<=2'd1; en_primitive<=1'b1;
				inc_rom_address<=1'b0; count_init<=1'b0; count_dec<=1'b0;
			end			
	3'd3: begin // Rd1<--1; Decrement Count; Check if squaring chain is over.
				BasePtSel1<=3'd1; Base_en<=2'd1; mode<=2'd1; en_primitive<=1'b0;
				inc_rom_address<=1'b0; count_init<=1'b0; count_dec<=1'b1;
			end			
///// repeated squaring is over ////			

	3'd4: begin // Rd2<--6/7;
				Base_en<=2'd2; mode<=2'd0; en_primitive<=1'b0;
				inc_rom_address<=1'b1; count_init<=1'b0; count_dec<=1'b0;
				if(inv_rom_dout_one) BasePtSel1<=3'd6; else BasePtSel1<=3'd7;
			end
	3'd5: begin // Wt2<--7; Start multiplication
				BasePtSel1<=3'd7; Base_en<=2'd0; mode<=2'd0; en_primitive<=1'b1;
				inc_rom_address<=1'b0; count_init<=1'b0; count_dec<=1'b0;
			end
			
////// Final squaring starts /////
	3'd6: begin // start final squaring 
				BasePtSel1<=3'd7; Base_en<=2'd0; mode<=2'd1; en_primitive<=1'b1;
				inc_rom_address<=1'b0; count_init<=1'b0; count_dec<=1'b0;
			end			
			
	3'd7: begin // End
				BasePtSel1<=3'd1; Base_en<=2'd0; mode<=2'd0; en_primitive<=1'b0;
				inc_rom_address<=1'b0; count_init<=1'b0; count_dec<=1'b0;
			end
	default: begin // End
				BasePtSel1<=3'd1; Base_en<=2'd0; mode<=2'd0; en_primitive<=1'b0;
				inc_rom_address<=1'b0; count_init<=1'b0; count_dec<=1'b0;
			end	
	endcase
end
	

always @(state or done_primitive or count_one or chain_end)
begin
	case(state)
	3'd0: nextstate<=3'd1;
	3'd1: begin
				if(chain_end & done_primitive)
					nextstate<=3'd6;
				else
					nextstate<=3'd2;
			end
	3'd2: begin
				if(done_primitive)
					nextstate<=3'd3;
				else
					nextstate<=3'd2;
			end		
	3'd3: begin
				if(count_one)
					nextstate<=3'd4;
				else
					nextstate<=3'd2;
			end		
///// repeated squaring is over ////			
		
			
	3'd4: nextstate<=3'd5;
	3'd5: begin
				if(done_primitive)
					nextstate<=3'd1;
				else
					nextstate<=3'd5;
			end
			
	3'd6: begin
				if(done_primitive)
					nextstate<=3'd7;
				else
					nextstate<=3'd6;			
			end
			
	3'd7: nextstate<=3'd7;
	default: nextstate<=3'd1;	
	endcase
end	

assign done_inversion = (state==3'd7) ? 1'b1 : 1'b0;

endmodule
