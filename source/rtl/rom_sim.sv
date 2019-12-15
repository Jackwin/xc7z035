module rom_sim(

    );

logic sys_clk;
logic sys_rst;


initial begin
    sys_clk = 0;
    forever begin
        #5 sys_clk = ~sys_clk;
    end
end

initial begin
    sys_rst = 1;
    # 120 sys_rst = 0;
end

logic           rom_ena;
logic [23:0]    rom_data;
logic [6:0]     rom_addr;


initial begin
    rom_ena <= 0;
    sys_rst <= 1;
    #100;
    sys_rst <= 0;
    #45;
    for (int i = 0; i < 64; i++) begin
        @(posedge sys_clk);
        rom_ena <= 1;
    end

    @(posedge sys_clk);
    rom_ena <= 0;
    #500;
end

always @(posedge sys_clk) begin
    if (sys_rst) begin
        rom_addr <= 0;
    end
    else begin
        if (rom_ena) begin
            rom_addr <= rom_addr + 1;
        end
    end
end

spi_config_rom spi_9517_config_rom (
  .clka(sys_clk),    // input wire clka
  .ena(rom_ena),      // input wire ena
  .addra(rom_addr),  // input wire [6 : 0] addra
  .douta(rom_data)  // output wire [31 : 0] douta
);

endmodule








