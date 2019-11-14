//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    13:56:10 09/09/2014 
// Design Name: 
// Module Name:    instruction_decoder 
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
		  
module instruction_decoder(clk, rst, instruction_ready, Tbit_ready, 
									instruction, op0, op1, op2, done_primitive, done_inversion,
									control_group3, en_invert, suspend,
									instruction_executed);
input clk, rst;
input instruction_ready, Tbit_ready;
input [2:0] instruction;
input [3:0] op0, op1, op2;
input done_primitive, done_inversion;

output [8:0] control_group3;	//control_group3 = {BasePtSel, Base_en, mode, en_primitive};
output en_invert, suspend;
output instruction_executed;

wire [3:0] BasePtSel;
reg [1:0] base_en;
wire [1:0] mode;
wire en_primitive;
reg [1:0] op_sel;
reg decode_enable;
wire move_to_done_state;

assign control_group3 = {BasePtSel, base_en, mode, en_primitive};
assign BasePtSel = (op_sel==2'd0) ? op0 : (op_sel==2'd1) ? op1 : op2;
assign en_primitive = ((instruction==3'd1||instruction==3'd2||instruction==3'd3||instruction==3'd5)&decode_enable) ? 1'b1 : 1'b0; 
assign en_invert = (instruction==3'd4 && decode_enable==1'b1) ? 1'b1 : 1'b0;
assign move_to_done_state = (en_primitive & done_primitive) | (en_invert & done_inversion) | (Tbit_ready & suspend==1'b0);
assign mode =   (instruction==3'd1) ? 2'd2	// addition
					:(instruction==3'd2) ? 2'd0   // multiplication
					:(instruction==3'd3) ? 2'd1   // squaring
					: 2'd3;								// copy
assign suspend = ((instruction==3'd7) & decode_enable) ? 1'b0 : 1'b1;

					
reg [1:0] state, nextstate;

always @(posedge clk)
begin
	if(rst)
		state<=2'd0;
	else
		state<=nextstate;
end		

always @(state)
begin	
	case(state)
	2'd0: begin	op_sel<=2'd0; base_en<=2'd0; decode_enable<=1'b0; end
	2'd1: begin	op_sel<=2'd1; base_en<=2'd1; decode_enable<=1'b0; end	// load Rd1 with op1
	2'd2: begin	op_sel<=2'd2; base_en<=2'd2; decode_enable<=1'b0; end	// load Rd2 with op2
	2'd3: begin	op_sel<=2'd0; base_en<=2'd0; decode_enable<=1'b1; end	// Assign Wt2 <-- op0; and enable decoding
	
//	3'd7: begin	op_sel<=2'd0; base_en<=2'd0; decode_enable<=1'b0; end	// END
	default: begin	op_sel<=2'd0; base_en<=2'd0; decode_enable<=1'b0; end
	endcase
end

always @(state or instruction_ready or move_to_done_state)
begin
	case(state)
	2'd0: begin
				if(instruction_ready)
					nextstate <= 2'd1;
				else
					nextstate <= 2'd0;
			end			
	2'd1: nextstate <= 2'd2;
	2'd2: nextstate <= 2'd3;
	2'd3: begin
				if(move_to_done_state)
					nextstate <= 3'd0;
				else
					nextstate <= 2'd3;
			end	
//	3'd7: nextstate <= 3'd0;
	default: nextstate <= 2'd0;
	endcase
end

//assign instruction_executed = (state==3'd7) ? 1'b1 : 1'b0;
assign instruction_executed = move_to_done_state;
	
endmodule
