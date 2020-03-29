`timescale 1ns/1ps

module ad9434_sim();


logic   adc_clk_p;
logic   adc_clk_n;

logic   clk_200m;

logic   rst;

logic   dm_clk;
logic   dm_rst;

logic            user_s2mm_wr_cmd_tready;
logic            user_s2mm_wr_cmd_tvalid;
logic [71:0]     user_s2mm_wr_cmd_tdata;
logic            user_s2mm_wr_tvalid;
logic [63:0]     user_s2mm_wr_tdata;
logic            user_s2mm_wr_tready;
logic [7:0]      user_s2mm_wr_tkeep;
logic            user_s2mm_wr_tlast;

logic            user_s2mm_sts_tvalid;
logic [7:0]      user_s2mm_sts_tdata;
logic            user_s2mm_sts_tkeep;
logic            user_s2mm_sts_tlast;

initial begin
    clk_200m = 0;
    forever begin
        # 2.5 clk_200m = ~clk_200m;
    end
end

initial begin
    adc_clk_p = 0;
    forever begin
        # 1.25 adc_clk_p = ~adc_clk_p;
    end
end

always_comb begin
    adc_clk_n = ~adc_clk_p;
end

initial begin
    rst = 1;
    #100;
    rst = 0;
end

initial begin
    dm_clk = 0;
    forever begin
        # 1.666 dm_clk = ~dm_clk;
    end
end

initial begin
    dm_rst = 1;
    #120;
    dm_rst = 0;
end

logic cap_done;
logic pulse_gen_trig;
initial begin
    user_s2mm_wr_cmd_tready <= 0;
    user_s2mm_wr_tready <= 0;
    pulse_gen_trig <= 0;
    #200;

    user_s2mm_wr_cmd_tready <= 1;
    user_s2mm_wr_tready <= 1;
    #30;
    @(posedge clk_200m);
    pulse_gen_trig <= 1;
    @(posedge clk_200m);
    pulse_gen_trig <= 0;

    #390;
    @(posedge dm_clk);
    user_s2mm_wr_cmd_tready <= 0;
    user_s2mm_wr_tready <= 0;
    @(posedge dm_clk);
    user_s2mm_wr_cmd_tready <= 1;
    user_s2mm_wr_tready <= 1;
    wait(cap_done);

    #100;

    user_s2mm_wr_cmd_tready <= 0;
    user_s2mm_wr_tready <= 0;
     @(posedge clk_200m);
    pulse_gen_trig <= 1;
    @(posedge clk_200m);
    pulse_gen_trig <= 0;
    
    #500;
    user_s2mm_wr_cmd_tready <= 1;
    user_s2mm_wr_tready <= 1;

    wait(cap_done);
    #100;

    $stop;

end

ad9434_data ad9434_data_1(
    .rst(rst),
    .clk_200m(clk_200m),
    .i_trig(pulse_gen_trig),
    .i_us_capture(10'd2),
    .o_cap_done(cap_done),
    .i_adc0_din_p(),
    .i_adc0_din_n(),
    .i_adc0_or_p(),
    .i_adc0_or_n(),
    .i_adc0_dco_p(adc_clk_p),
    .i_adc0_dco_n(adc_clk_n),

    .dm_clk(dm_clk),
    .dm_rst(dm_rst),

    .i_s2mm_wr_cmd_tready(user_s2mm_wr_cmd_tready),
    .o_s2mm_wr_cmd_tdata(user_s2mm_wr_cmd_tdata),
    .o_s2mm_wr_cmd_tvalid(user_s2mm_wr_cmd_tvalid),

    .o_s2mm_wr_tdata(user_s2mm_wr_tdata),
    .o_s2mm_wr_tkeep(user_s2mm_wr_tkeep),
    .o_s2mm_wr_tvalid(user_s2mm_wr_tvalid),
    .o_s2mm_wr_tlast(user_s2mm_wr_tlast),
    .i_s2mm_wr_tready(user_s2mm_wr_tready),

    .s2mm_sts_tdata(user_s2mm_sts_tdata),
    .s2mm_sts_tvalid(user_s2mm_sts_tvalid),
    .s2mm_sts_tkeep(user_s2mm_sts_tkeep),
    .s2mm_sts_tlast(user_s2mm_sts_tlast)


);

endmodule