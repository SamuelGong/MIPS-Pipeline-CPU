`include "define.vh"

module cp0 (
	input wire clk,  // main clock
	// debug
	`ifdef DEBUG
	input wire [4:0] debug_addr,  // debug address
	output wire [31:0] debug_data,  // debug data
	`endif
	// operations (read in ID stage and write in EXE stage)
	input wire [1:0] oper,  // CP0 operation type
	input wire [4:0] addr_r,  // read address
	output wire [31:0] data_r,  // read data
	input wire [4:0] addr_w,  // write address
	input wire [31:0] data_w,  // write data
	// exceptions (check exceptions in MEM stage)
	input wire rst,  // synchronous reset
	input wire ir_en,  // interrupt enable
	input wire ir_in,  // external interrupt input
	input wire [31:0] ret_addr,  // target instruction address to store when interrupt occurred
	output reg jump_en,  // force jump enable signal when interrupt authorised or ERET occurred
	output wire [31:0] jump_addr,  // target instruction address to jump to
	output reg eret
    );
    
    `include "mips_define.vh"
    
    // interrupt determination
    wire ir;
    reg ir_wait = 0, ir_valid = 1;
    
    always @(posedge clk) begin
        if (rst)
            ir_wait <= 0;
        else if (ir_in)
            ir_wait <= 1;
        else if (eret)
            ir_wait <= 0;
    end
    
    always @(posedge clk) begin
        if (rst)
            ir_valid <= 1;
        else if (eret)
            ir_valid <= 1;
        else if (ir)
            ir_valid <= 0;  // prevent exception reenter
    end
    
    assign ir = ir_en & ir_wait & ir_valid;
    
    // operations
    reg reg_en_w;
    always @(*) begin
        eret <= 0;
        reg_en_w <= 0;
        if (oper == EXE_CP0_ERET)
            eret <= 1;
        if (oper == EXE_CP_STORE || ir)
            reg_en_w <= 1;
    end
    
    // jump determination   
    always @(*) begin;
        jump_en <= 0;
        if (ir || eret)
            jump_en <= 1;
     end
     
     assign jump_addr = data_r;

    // cp0 register file
    regfile cP0_REGFILE (
		.clk(clk),
		`ifdef DEBUG
		.debug_addr(debug_addr),
		.debug_data(debug_data),
		`endif
		.addr_a(addr_r),
		.data_a(data_r),
		.en_w(reg_en_w),
		.addr_w(addr_w),
		.data_w(data_w)
	);
    
    
endmodule
