`include "define.vh"

module datapath (
	input wire clk,  // main clock
	// debug
	`ifdef DEBUG
	input wire [6:0] debug_addr,  // debug address
	output reg [31:0] debug_data,  // debug data
	`endif
	// control signals
	output reg [31:0] inst_data_id,  // instruction
	//output reg is_branch_exe,                                        // 
	output reg [4:0] regw_addr_exe,  // register write address from EXE stage
	output reg wb_wen_exe,  // register write enable signal feedback from EXE stage
	//output reg is_branch_mem,                                        // 
	output reg [4:0] regw_addr_mem,  // register write address from MEM stage
	output reg wb_wen_mem,  // register write enable signal feedback from MEM stage
	input wire [2:0] pc_src_ctrl,  // how would PC change to next
	input wire imm_ext_ctrl,  // whether using sign extended to immediate data
	input wire [1:0] exe_a_src_ctrl,  // data source of operand A for ALU
	input wire [1:0] exe_b_src_ctrl,  // data source of operand B for ALU
	input wire [3:0] exe_alu_oper_ctrl,  // ALU operation type
	input wire mem_ren_ctrl,  // memory read enable signal
	input wire mem_wen_ctrl,  // memory write enable signal
	input wire [1:0] wb_addr_src_ctrl,  // address source to write data back to registers
	input wire wb_data_src_ctrl,  // data source of data being written back to registers
	input wire wb_wen_ctrl,  // register write enable signal
	input wire is_load,      //
	input wire is_branch,    //
	input wire mem_fwd_m,    //
    output reg is_load_exe,  //
    input wire sign,        ///
    input wire interrupter, ////
    input wire cp0_ir_en,
    output wire cp0_jump_en,
    input wire [1:0] cp0_oper,
	// IF signals
	input wire if_rst,  // stage reset signal
	input wire if_en,  // stage enable signal
	output reg if_valid,  // working flag
	output reg inst_ren,  // instruction read enable signal
	output reg [31:0] inst_addr,  // address of instruction needed
	input wire [31:0] inst_data,  // instruction fetched
	// ID signals
	input wire id_rst,
	input wire id_en,
	output reg id_valid,
	// EXE signals
	input wire exe_rst,
	input wire exe_en,
	output reg exe_valid,
	// MEM signals
	input wire mem_rst,
	input wire mem_en,
	output reg mem_valid,
	output wire mem_ren,  // memory read enable signal
	output wire mem_wen,  // memory write enable signal
	output wire [31:0] mem_addr,  // address of memory
	output reg [31:0] mem_dout,  // data writing to memory    //
	input wire [31:0] mem_din,  // data read from memory
	// WB signals
	input wire wb_rst,
	input wire wb_en,
	output reg wb_valid
	);
	
	`include "mips_define.vh"
	
	// control signals
	reg [2:0] pc_src_exe, pc_src_mem;
	reg [1:0] exe_a_src_exe, exe_b_src_exe;
	reg [3:0] exe_alu_oper_exe;
	reg mem_ren_exe, mem_ren_mem, mem_ren_wb;
	reg mem_wen_exe, mem_wen_mem, mem_wen_wb;
	reg wb_data_src_exe, wb_data_src_mem, wb_data_src_wb;
	
	////
	reg is_branch_id;
	// CP0 signals
    wire [1:0] cp0_oper;
    wire [31:0] cp0_data_r;
    wire [31:0] cp0_jump_addr;
    reg [4:0] cp0_addr_r;
    reg [4:0] cp0_addr_w;
    reg [31:0] cp0_data_w;
    reg [31:0] cp0_data_r_exe;
    
    // interrupt
    wire interrupt;
    reg interrupt_prev;
    always @(posedge clk) begin
        interrupt_prev <= interrupter;
    end
    assign interrupt = ~interrupt_prev & interrupter;

	
	// IF signals
	wire [31:0] inst_addr_next;
	
	// ID signals
	reg [31:0] inst_addr_id;
	reg [31:0] inst_addr_next_id;
	reg [4:0] regw_addr_id;
	wire [4:0] addr_rs, addr_rt, addr_rd;
	wire [31:0] data_rs, data_rt, data_imm;
	wire rs_rt_equal_id;                       //
	reg [31:0] branch_target_id;               //
	wire [31:0] adc_out;                       //
	
	// EXE signals
	reg [31:0] inst_addr_exe;
	reg [31:0] inst_addr_next_exe;
	reg [31:0] inst_data_exe;
	reg [4:0] addr_rs_exe, addr_rt_exe;
	reg [31:0] data_rs_exe, data_rt_exe, data_imm_exe;
	reg [31:0] opa_exe, opb_exe;
	wire [31:0] alu_out_exe;
	reg rs_rt_equal_exe;
	reg mem_fwd_m_exe;                         //
	
	// MEM signals
	reg [31:0] inst_addr_mem;
	reg [31:0] inst_addr_next_mem;
	reg [31:0] inst_data_mem;
	reg [4:0] data_rs_mem;
	reg [31:0] data_rt_mem;
	reg [31:0] alu_out_mem;
	reg [31:0] regw_data_mem;
	reg mem_fwd_m_mem;                         //
	//reg [31:0] branch_target_mem;            //
	
	// WB signals
	reg wb_wen_wb;
	reg [31:0] alu_out_wb;
	reg [31:0] mem_din_wb;
	reg [4:0] regw_addr_wb;
	reg [31:0] regw_data_wb;
	
	// debug
	`ifdef DEBUG
	wire [31:0] debug_data_reg;
	reg [31:0] debug_data_signal;
	
	always @(*) begin
		case (debug_addr[4:0])
			0: debug_data_signal <= inst_addr;
			1: debug_data_signal <= inst_data;
			2: debug_data_signal <= inst_addr_id;
			3: debug_data_signal <= inst_data_id;
			4: debug_data_signal <= inst_addr_exe;
			5: debug_data_signal <= inst_data_exe;
			6: debug_data_signal <= inst_addr_mem;
			7: debug_data_signal <= inst_data_mem;
			8: debug_data_signal <= {27'b0, addr_rs};
			9: debug_data_signal <= data_rs;
			10: debug_data_signal <= {27'b0, addr_rt};
			11: debug_data_signal <= data_rt;
			12: debug_data_signal <= data_imm;
			13: debug_data_signal <= opa_exe;
			14: debug_data_signal <= opb_exe;
			15: debug_data_signal <= alu_out_exe;
			16: debug_data_signal <= 0;
			17: debug_data_signal <= 0;
			18: debug_data_signal <= {19'b0, inst_ren, 7'b0, mem_ren, 3'b0, mem_wen};
			19: debug_data_signal <= mem_addr;
			20: debug_data_signal <= mem_din;
			21: debug_data_signal <= mem_dout;
			22: debug_data_signal <= {27'b0, regw_addr_wb};
			23: debug_data_signal <= regw_data_wb;
			default: debug_data_signal <= 32'hFFFF_FFFF;
		endcase
	end
	
	////
	wire [31:0] debug_data_cp0_reg;
	always @(*) begin
	   case(debug_addr[6:5])
	       2'b00:  debug_data <= debug_data_reg;
	       2'b01:  debug_data <= debug_data_signal;
	       2'b10:  debug_data <= debug_data_cp0_reg;
	       2'b11:  debug_data <= 32'h50101149;
	   endcase
	end

	`endif
	
	// IF stage
	assign
		inst_addr_next = inst_addr + 4;
	
	always @(*) begin
		if_valid = ~if_rst & if_en;
		inst_ren = ~if_rst;
	end
	
	////
	reg [31:0] normal_inst_addr;
	
	always @(posedge clk) begin
		if (if_rst) begin
			normal_inst_addr <= 0;
		end
		else if (if_en) begin
			if (is_branch)                               //
				normal_inst_addr <= branch_target_id;
			else
				normal_inst_addr <= inst_addr_next;
		end
	end
	
	reg cp0_jump_en_id;
	reg [31:0] cp0_jump_addr_id;
	
	always @(posedge clk) begin
	   cp0_jump_en_id <= cp0_jump_en;
	   cp0_jump_addr_id <= cp0_jump_addr;
	end
	
	always @(*) begin
	   if(~cp0_jump_en_id)
	       inst_addr <= normal_inst_addr;
	   else
	       inst_addr <= cp0_jump_addr_id;
	end
	
	// ID stage
	always @(posedge clk) begin
		if (id_rst) begin
			id_valid <= 0;
			inst_addr_id <= 0;
			inst_data_id <= 0;
			inst_addr_next_id <= 0;
			is_branch_id <= 0;
		end
		else if (id_en) begin
			id_valid <= if_valid;
			inst_addr_id <= inst_addr;
			inst_data_id <= inst_data;
			inst_addr_next_id <= inst_addr_next;
			is_branch_id <= is_branch;
		end
	end
	
	assign
		addr_rs = inst_data_id[25:21],
		addr_rt = inst_data_id[20:16],
		addr_rd = inst_data_id[15:11],
		data_imm = imm_ext_ctrl ? {{16{inst_data_id[15]}}, inst_data_id[15:0]} : {16'b0, inst_data_id[15:0]};
	
	always @(*) begin
		regw_addr_id = inst_data_id[15:11];
		case (wb_addr_src_ctrl)
			WB_ADDR_RD: regw_addr_id = addr_rd;
			WB_ADDR_RT: regw_addr_id = addr_rt;
			WB_ADDR_LINK: regw_addr_id = GPR_RA;
		endcase
	end
	
	regfile REGFILE (
		.clk(clk),
		`ifdef DEBUG
		.debug_addr(debug_addr[4:0]),
		.debug_data(debug_data_reg),
		`endif
		.addr_a(addr_rs),
		.data_a(data_rs),
		.addr_b(addr_rt),
		.data_b(data_rt),
		.en_w(wb_wen_wb),
		.addr_w(regw_addr_wb),
		.data_w(regw_data_wb)
		);
		
	assign
	    rs_rt_equal_id = (data_rs_fwd == data_rt_fwd);      //
	   
    assign
        adc_out = inst_addr_next_id + ( data_imm << 2 );        //
    // PC + 4 + imme 
	
	always @(*) begin                          //
        case (pc_src_ctrl)
            PC_JUMP: branch_target_id <= {inst_addr_id[31:28],inst_data_id[25:0],2'b00};
            PC_JR: branch_target_id <= data_rs;
            PC_BEQ: begin
                        if (rs_rt_equal_id)
                            branch_target_id <= adc_out;
                        else
                            branch_target_id <= inst_addr_next_id + 4;
                    end
            PC_BNE: begin
                        if (!rs_rt_equal_id)
                            branch_target_id <= adc_out;
                        else
                            branch_target_id <= inst_addr_next_id + 4;
                    end
            default: branch_target_id <= inst_addr_next_id;  // will never used
        endcase
    end
	
	// EXE stage
	always @(posedge clk) begin
		if (exe_rst) begin
			exe_valid <= 0;
			inst_addr_exe <= 0;
			inst_data_exe <= 0;
			inst_addr_next_exe <= 0;
			regw_addr_exe <= 0;
			pc_src_exe <= 0;
			exe_a_src_exe <= 0;
			exe_b_src_exe <= 0;
			addr_rs_exe <= 0;
			addr_rt_exe <= 0;
			data_rs_exe <= 0;
			data_rt_exe <= 0;
			data_imm_exe <= 0;
			exe_alu_oper_exe <= 0;
			mem_ren_exe <= 0;
			mem_wen_exe <= 0;
			wb_data_src_exe <= 0;
			wb_wen_exe <= 0;
			is_load_exe <= 0;            //
			rs_rt_equal_exe <= 0;        //
			mem_fwd_m_exe <= 0;          //
			cp0_data_r_exe <= 0;
		end
		else if (exe_en) begin
			exe_valid <= id_valid;
			inst_addr_exe <= inst_addr_id;
			inst_data_exe <= inst_data_id;
			inst_addr_next_exe <= inst_addr_next_id;
			regw_addr_exe <= regw_addr_id;
			pc_src_exe <= pc_src_ctrl;
			exe_a_src_exe <= exe_a_src_ctrl;
			exe_b_src_exe <= exe_b_src_ctrl;
			addr_rs_exe <= addr_rs;
			addr_rt_exe <= addr_rt;
            data_rs_exe <= data_rs_fwd;
            data_rt_exe <= data_rt_fwd;
			data_imm_exe <= data_imm;
			exe_alu_oper_exe <= exe_alu_oper_ctrl;
			mem_ren_exe <= mem_ren_ctrl;
			mem_wen_exe <= mem_wen_ctrl;
			wb_data_src_exe <= wb_data_src_ctrl;
			wb_wen_exe <= wb_wen_ctrl;
			is_load_exe <= is_load;                  //
			rs_rt_equal_exe <= rs_rt_equal_id;       //
			mem_fwd_m_exe <= mem_fwd_m;              //
			cp0_data_r_exe <= cp0_data_r;
		end
	end
	
//	always @(*) begin                                //
//		is_branch_exe <= (pc_src_exe != PC_NEXT);
//	end
	
	always @(*) begin                                  //
		opa_exe = data_rs_exe;
		opb_exe = data_rt_exe;
		case (exe_a_src_exe)
			EXE_A_RS: opa_exe = data_rs_exe;
			EXE_A_SA: opa_exe = inst_data_exe;
			EXE_A_LINK: opa_exe = inst_addr_next_exe;
			EXE_A_EXC: opa_exe = cp0_data_r_exe;
			//EXE_A_BRANCH: opa_exe = inst_addr_next_exe;    //
		endcase
		case (exe_b_src_exe)
			EXE_B_RT: opb_exe = data_rt_exe;
			EXE_B_IMM: opb_exe = data_imm_exe;
			EXE_B_LINK: opb_exe = 4;
			EXE_B_EXC: opb_exe = 0;
			//EXE_B_BRANCH: opb_exe = data_imm_exe << 2;     //
		endcase
	end

	
	alu ALU (
		.a(opa_exe),
		.b(opb_exe),
		.oper(exe_alu_oper_exe),
		.result(alu_out_exe),
		.sign(sign)
		);
	
	// MEM stage
	always @(posedge clk) begin
		if (mem_rst) begin
			mem_valid <= 0;
			pc_src_mem <= 0;
			inst_addr_mem <= 0;
			inst_data_mem <= 0;
			//inst_addr_next_mem <= 0;                   //
			regw_addr_mem <= 0;
			//data_rs_mem <= 0;
			data_rt_mem <= 0;
			alu_out_mem <= 0;
			mem_ren_mem <= 0;
			mem_wen_mem <= 0;
			wb_data_src_mem <= 0;
			wb_wen_mem <= 0;
			mem_fwd_m_mem <= 0;                          //
		end
		else if (mem_en) begin
			mem_valid <= exe_valid;
			pc_src_mem <= pc_src_exe;
			inst_addr_mem <= inst_addr_exe;
			inst_data_mem <= inst_data_exe;
			//inst_addr_next_mem <= inst_addr_next_exe;      //
			regw_addr_mem <= regw_addr_exe;
			//data_rs_mem <= data_rs_fwd;
			data_rt_mem <= data_rt_exe;
			alu_out_mem <= alu_out_exe;
			mem_ren_mem <= mem_ren_exe;
			mem_wen_mem <= mem_wen_exe;
			wb_data_src_mem <= wb_data_src_exe;
			wb_wen_mem <= wb_wen_exe;
			mem_fwd_m_mem <= mem_fwd_m_exe;                  //
		end
	end
	
//	always @(*) begin                                //
//		is_branch_mem <= (pc_src_mem != PC_NEXT);
//	end
	
	assign
		mem_ren = mem_ren_mem,
		mem_wen = mem_wen_mem,
		mem_addr = alu_out_mem;
	
    always @(*) begin
        mem_dout <= data_rt_mem;
        if (mem_fwd_m_mem)
            mem_dout <= regw_data_wb;
    end
		
	always @(*) begin                              //
        regw_data_mem = alu_out_mem;
        case (wb_data_src_mem)
            WB_DATA_ALU: regw_data_mem = alu_out_mem;
            WB_DATA_MEM: regw_data_mem = mem_din;
        endcase
    end
	
	// WB stage
	always @(posedge clk) begin
		if (wb_rst) begin
			wb_valid <= 0;
			wb_wen_wb <= 0;
			//wb_data_src_wb <= 0;                   //
			regw_addr_wb <= 0;
			alu_out_wb <= 0;
			mem_din_wb <= 0;
			mem_ren_wb <= 0;
            mem_wen_wb <= 0;
            regw_data_wb <= 0;
		end
		else if (wb_en) begin
			wb_valid <= mem_valid;
			wb_wen_wb <= wb_wen_mem;
			//wb_data_src_wb <= wb_data_src_mem;     //
			regw_addr_wb <= regw_addr_mem;
			alu_out_wb <= alu_out_mem;
			mem_din_wb <= mem_din;
			mem_ren_wb <= mem_ren_mem;
            mem_wen_wb <= mem_wen_mem;
            regw_data_wb <= regw_data_mem;
		end
	end
	
//	always @(*) begin                    //
//		regw_data_wb = alu_out_wb;
//		case (wb_data_src_wb)
//			WB_DATA_ALU: regw_data_wb = alu_out_wb;
//			WB_DATA_MEM: regw_data_wb = mem_din_wb;
//		endcase
//	end
	
	// forwarding unit
	reg [1:0] forwardA, forwardB;
	reg [31:0] data_rs_fwd, data_rt_fwd;
	// forwardA/B = 00 : The ALU operand comes from the register file
	// forwardA/B = 10 : The ALU operand is forwarded from the prior ALU result
	// forwardA/B = 01 : The ALU operand is forwarded from an earlier ALU result
	// forwardA/B = 11 : The ALU operand is forwarded from data memory
	
	always @(*) begin                                          //
	    if ( addr_rs != 0 ) begin
	        if ( wb_wen_exe && regw_addr_exe == addr_rs ) begin
	            if ( mem_ren_exe == 0 )
	                forwardA <= 2'b10;
	            else
	                forwardA <= 2'b01;
	        end
	        else if ( wb_wen_mem && regw_addr_mem == addr_rs 
                      && regw_addr_exe != addr_rs )     
                forwardA <= 2'b11;
            else
                forwardA <= 2'b00;
        end      
        else
            forwardA <= 2'b00;
	    
	    if ( addr_rt != 0 ) begin   
	        if ( wb_wen_exe && regw_addr_exe == addr_rt ) begin
	            if ( mem_ren_exe == 0 )
	                forwardB <= 2'b10;
	            else
	                forwardB <= 2'b01;
	        end
            else if ( wb_wen_mem && regw_addr_mem == addr_rt
                      && regw_addr_exe != addr_rt)
                forwardB <= 2'b11;
            else
                forwardB <= 2'b00;
        end
        else
            forwardB <= 2'b00;          
	end

    always @(*) begin                               //
        case ( forwardA[1:0] )
            3: data_rs_fwd <= regw_data_mem;
            2: data_rs_fwd <= alu_out_exe;
            1: data_rs_fwd <= mem_din;
            0: data_rs_fwd <= data_rs;
        endcase
        case ( forwardB[1:0] )
            3: data_rt_fwd <= regw_data_mem;
            2: data_rt_fwd <= alu_out_exe;
            1: data_rt_fwd <= mem_din;
            0: data_rt_fwd <= data_rt;
        endcase
    end
    
    ////
    always @(*) begin
        cp0_addr_w <= addr_rd;
        cp0_data_w <= data_rt_fwd;
        if (cp0_jump_en)
            if (is_branch) begin
                cp0_addr_w <= CP0_EPCR;
                cp0_data_w <= inst_addr_id;
            end
            else begin
                cp0_addr_w <= CP0_EPCR;
                cp0_data_w <= inst_addr;
            end
    end
    
    always @(*) begin
        cp0_addr_r <= addr_rd;
        if (eret)
            cp0_addr_r <= CP0_EPCR;
        else if (cp0_jump_en)
            cp0_addr_r <= CP0_EHBR;
    end
    
    
    cp0 CP0 (
            .clk(clk),
            `ifdef DEBUG
            .debug_addr(debug_addr[4:0]),
            .debug_data(debug_data_cp0_reg),
            `endif
            .oper(cp0_oper),
            .data_r(cp0_data_r),
            .addr_r(cp0_addr_r),
            .data_w(cp0_data_w),
            .addr_w(cp0_addr_w),
            .rst(rst),
            .ir_en(cp0_ir_en),
            .ir_in(interrupt),
            .jump_en(cp0_jump_en),
            .jump_addr(cp0_jump_addr),
            .eret(eret)
        );
	
endmodule
