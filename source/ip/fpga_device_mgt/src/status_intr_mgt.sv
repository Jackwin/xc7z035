/*
This module implements the fpga device management involves the status register W/R and interrupt.

The status regs contain the temperature, version and so on.
*/
module status_intr_mgt #(
	parameter ADDR_WIDTH= 32,
	parameter DATA_WDITH= 32,
	parameter INTR_MSG_WIDTH = 7,
	parameter TMEPER_WIDTH = 12
)
	
(
	input 	logic						clk,
	input	logic						rstn,

	input	logic	[DATA_WDITH-1:0] 	i_reg_data,
	input	logic	[ADDR_WIDTH-1:0]	i_reg_wr_addr,
	input	logic		    			i_reg_wen,

	input	logic	[ADDR_WIDTH-1:0]	i_reg_rd_addr,
	input	logic		    			i_reg_ren,
	output	logic	[DATA_WDITH-1:0]	o_reg_data, 
	output	logic		    			o_reg_valid,

	output	logic		    			o_intr_ready,
	input	logic	[INTR_MSG_WIDTH-1:0]i_intr_msg,         

	input	logic						i_temper_valid,
	input	logic	[TMEPER_WIDTH-1:0]	i_temper,

	
	input   logic   [DATA_WDITH-1:0]  	i_version, 
	output	logic		    			soft_rst
);

localparam INTR_REG = 'h0;
localparam VERSION_REG = 'h4;
localparam TEMP_REG    = 'h8;
localparam SOFT_R_REG  = 'ha;

logic [INTR_MSG_WIDTH-1:0] intr_msg_r;

always_ff @(posedge clk) begin
	intr_msg_r <= i_intr_msg;
end

reg     reg_req_d1=1'b0;
wire	intr_reg_rd;

always_ff @(posedge clk) begin
	if (~rstn)
		reg_req_d1<=1'b0;
	else
		reg_req_d1<=i_reg_ren;
end
assign o_reg_valid = reg_req_d1;

logic soft_rst_reg;
logic [4:0] count; 
// soft reset logi(rstn)c. 256 clock cycle delay.
always_ff @(posedge clk) begin
	if (~rstn) begin
		soft_rst_reg <= 0;
	end else if (i_reg_wen && i_reg_wr_addr == SOFT_R_REG)
		soft_rst_reg <= 1'b1;		
	else if (count == 5'h1f)
		soft_rst_reg <= 1'b0;
end

always_ff @ (posedge clk) begin
	if (soft_rst_reg)
		count <= count - 1'd1;
	else
		count <= 5'h1e;
end

assign soft_rst = soft_rst_reg;

logic [1:0] intr_cs;
logic [1:0] intr_ns;
localparam 	IDLE_s=0, 
			RQ_s=1,
			WAIT_DONE_s=2,
			RD_REG_s=3;

logic intr_fifo_empty;
logic intr_fifo_ren;

logic [INTR_MSG_WIDTH-1:0] intr_fifo_dout;

logic interrpt_en;
logic [INTR_MSG_WIDTH-1:0] intr_reg;


always_ff @(posedge clk ) begin
	if (~rstn)
		intr_cs <= IDLE_s;
	else
		intr_cs <= intr_ns;
end

always_comb begin
	case (intr_cs)
		IDLE_s: begin
			if(~intr_fifo_empty )               
				intr_ns = RQ_s;
			else
				intr_ns = IDLE_s;
		end
		RQ_s:	intr_ns = WAIT_DONE_s;
		WAIT_DONE_s: begin
			intr_ns = RD_REG_s;
		end
		RD_REG_s: begin
			if (intr_reg_rd)
				intr_ns = IDLE_s;
			else 
				intr_ns = RD_REG_s;
		end
	endcase
end

xpm_fifo_async #(
	.CDC_SYNC_STAGES(2), 
	.DOUT_RESET_VALUE("0"),    
	.ECC_MODE("no_ecc"),       
	.FIFO_MEMORY_TYPE("distributed"), 
	.FIFO_READ_LATENCY(1),     
	.FIFO_WRITE_DEPTH(16),   
	.FULL_RESET_VALUE(0),      
	.PROG_EMPTY_THRESH(3),    
	.PROG_FULL_THRESH(13),     
	.RD_DATA_COUNT_WIDTH(5),   
	.READ_DATA_WIDTH(INTR_MSG_WIDTH),      
	.READ_MODE("std"),         
	.USE_ADV_FEATURES("0000"), //enable almost full
	.WAKEUP_TIME(0),           
	.WRITE_DATA_WIDTH(INTR_MSG_WIDTH),     
	.WR_DATA_COUNT_WIDTH(5)    
)
dist_fifo_16x16_async_std (
				
	.wr_clk (clk),
	.rd_clk (clk),
	.rst    (~rstn),
	.din    (i_intr_msg_r),
	.wr_en  (|i_intr_msg_r),
	.rd_en  (intr_fifo_ren),
	.dout   (intr_fifo_dout),
	.full   (),
	.empty  (intr_fifo_empty)          
);

always_comb begin
	intr_fifo_ren = (intr_cs == RQ_s) & (~intr_fifo_empty);
	
end

always_ff @(posedge clk) begin
	if (~rstn)
		interrpt_en <= 1'b0;
	else 
		interrpt_en <= (intr_ns==WAIT_DONE_s | intr_ns == RD_REG_s);   
end
// intr message is ready
assign o_intr_ready = interrpt_en;
	
logic intr_ren_d1;
always_ff @(posedge clk) begin
	if (~rstn)
		intr_ren_d1 <= 1'b0;
	else
		intr_ren_d1 <= intr_fifo_ren;
end


assign	intr_reg_rd = i_reg_rd_addr == 'd0 && i_reg_ren;

always_ff @(posedge clk) begin
	if (~rstn)
		intr_reg <= 'd0;
	else if(intr_ren_d1)
		intr_reg <= intr_fifo_dout; // Latch the intr message
	else if(intr_reg_rd)
		intr_reg <= 0; // clear the intr_reg
end

//------------------------- register read -------------------
	
logic [TMEPER_WIDTH-1:0]	temper_reg;
always_ff @(posedge clk) begin
	if (i_temper_valid == 1'b1)
		temper_reg <= i_temper;
end

logic [63:0]  rd_reg = 0;
always_ff @(posedge clk) begin
	if(intr_reg_rd)
		rd_reg <= {{{32-DATA_WDITH}{1'b0}}, intr_reg};
	else if (i_reg_ren) begin
		case(i_reg_rd_addr)
			VERSION_REG:rd_reg <= i_version;
			TEMP_REG:   rd_reg <= {{{DATA_WDITH-TMEPER_WIDTH}{1'b0}}, temper_reg}; //temper
			default: rd_reg <= rd_reg;
		endcase
	end
end

assign o_reg_data = rd_reg; 

endmodule
