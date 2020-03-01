`timescale 1ns/1ps
module  pulse_gen_sim (
);

logic   clk;
logic   rst;
logic   div_clk;

initial begin
    clk = 0;
    forever begin
        #1 clk = ~clk;
    end
end

initial begin
    rst = 1;
    # 40;
    rst = 0;
end

logic [1:0]     div_cnt = 0;
logic           done;

always_ff @(posedge clk) begin
    div_cnt = div_cnt + 1;
end

always_comb begin
    div_clk = div_cnt[1];
end

logic [10:0]    pulse_width;
logic [10:0]    pulse_num;
logic [15:0]    gap_us;
logic           start;
logic           trig;
integer     k,kk;
initial begin
    start = 0;
    pulse_width = 0;
    pulse_num = 0;
    gap_us = 0;

    #100

    for(k = 1; k < 16; k++) begin
        for (kk = 1; kk < 2; kk++) begin
            pulse_width = k;
            pulse_num = kk;
            gap_us = 1;

            @(posedge div_clk);
            start = 1;
            @(posedge div_clk);
            start = 0;
            wait (done);
        end
    end

    #200;
    $stop;
end

pulse_gen pulse_gen_inst (
    .clk(clk),
    .clk_div(div_clk),
    .rst(rst),
    .pulse_width_i(pulse_width),
    .pulse_num_i(pulse_num),
    .gap_us_i(gap_us),
    .start_i(start),
    .trig_o(trig),
    .done_o(done),
    .q(hp_gpio0)

);
    
endmodule