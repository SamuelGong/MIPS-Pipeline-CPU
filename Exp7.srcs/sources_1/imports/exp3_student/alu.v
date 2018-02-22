`include "define.vh"


/**
 * Arithmetic and Logic Unit for MIPS CPU.
 * Author: Zhao, Hongyu  <power_zhy@foxmail.com>
 */
module alu (
	input wire [31:0] a, b,  // two operands
	input wire [3:0] oper,  // operation type
	input wire sign,        // signed or unsigned
	output reg [31:0] result  // calculation result
	);
	
	`include "mips_define.vh"
	
	always @(*) begin
		result = 0;
		case (oper)
			EXE_ALU_ADD: begin
                if (sign)
                    result = $signed(a) + $signed(b);
                else
                    result = $unsigned(a) + $unsigned(b);
            end
			EXE_ALU_SUB: begin
				if (sign)
                    result = $signed(a) - $signed(b);
                else
                    result = $unsigned(a) - $unsigned(b);
			end
			EXE_ALU_SLT: begin
			    if (sign)
				    result = $signed(a) < $signed(b);
				else
				    result = $unsigned(a) < $unsigned(b);
			end
			EXE_ALU_AND: begin
				result = a & b;
			end
			EXE_ALU_OR: begin
				result = a | b;
			end
			EXE_ALU_XOR: begin
			    result = a ^ b;
			end
			EXE_ALU_NOR: begin
                result = ~( a | b );
            end
            EXE_ALU_SLL: begin
                result = b << a[10:6];
            end
            EXE_ALU_SRL: begin
                result = b >> a[10:6];
            end
            EXE_ALU_SRA: begin
                result = ( {32{b[31]}} << ( 32 - a[10:6] ) ) | ( b >> a[10:6] );
            end
            EXE_ALU_SLLV: begin
                result = b << a;
            end
            EXE_ALU_SLLV: begin
                result = b >> a;
            end
            EXE_ALU_SRAV: begin
                result = a > 32 ? 0 : ( {32{b[31]}} << ( 32 - a ) ) | ( b >> a );
            end
            EXE_ALU_LUI: begin
                result = b << 16;
            end
		endcase
	end
	
endmodule
