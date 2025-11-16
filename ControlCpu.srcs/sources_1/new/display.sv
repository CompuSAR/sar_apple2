`timescale 1ns / 1ps

module display# (
    SOUTH_BUS_WIDTH = 64
)(
    input raw_clock_i,
    input ctrl_clock_i,
    input reset_i,

    input ctrl_req_valid_i,
    output ctrl_req_ack_o,
    input ctrl_req_write_i,
    input [15:0] ctrl_req_addr_i,
    input [31:0] ctrl_req_data_i,
    output logic ctrl_rsp_valid_o,
    output logic [31:0] ctrl_rsp_data_o = 32'h0,

    output logic dma_req_valid_o,
    output logic [31:0] dma_req_addr_o,
    input dma_req_ack_i,

    input dma_rsp_valid_i,
    input [SOUTH_BUS_WIDTH-1:0] dma_rsp_data_i,

    output wire TMDS_clk_n,
    output wire TMDS_clk_p,
    output wire[2:0] TMDS_data_n,
    output wire[2:0] TMDS_data_p,
    output wire[0:0] HDMI_OEN
);

// Number of pixels sent together
localparam UpdateBlock = 32;

logic [31:0]
    mode_register = 32'hX,
    apple_base_addr1 = 32'hX;

logic [1:0] current_third;
logic [2:0] current_row;
logic [2:0] current_subrow;
logic [4:0] current_col;

wire vsync_ctrl, vsync_hdmi;

logic [31:0] current_offset;

always_comb begin
    current_offset = 31'h0;

    current_offset[6:0] = current_col + current_third * 40;

    if( mode_register[1] )
        current_offset[12:10] = current_subrow;

    current_offset[9:7] = current_row;
end

assign ctrl_req_ack_o = 1'b1;

logic charram_write_enable;
logic [7:0] charram_write_addr;
logic [31:0] charram_write_data;

logic charram_read_enable = 1'b0;
logic [9:0] charram_read_addr;
logic [7:0] charram_read_data;

task update_char(input [7:0] addr, input [31:0] data);
    charram_write_enable <= 1'b1;
    charram_write_addr <= addr;
    charram_write_data <= data;
endtask

always_ff@(posedge ctrl_clock_i) begin
    charram_write_enable <= 1'b0;

    if( vsync_ctrl ) begin
        current_third <= 0;
        current_row <= 0;
        current_subrow <= 0;
        current_col <= 0;
    end else begin
        current_third ++;
        current_row ++;
        current_subrow ++;
        current_col ++;
    end

    ctrl_rsp_valid_o <= 1'b0;

    if( ctrl_req_valid_i && ctrl_req_ack_o ) begin
        if( ctrl_req_write_i ) begin
            casex( ctrl_req_addr_i )
                16'h0000: mode_register <= ctrl_req_addr_i;
                16'h0004: apple_base_addr1 <= ctrl_req_data_i;
                16'h10xx: update_char(ctrl_req_addr_i[7:0], ctrl_req_data_i);
            endcase
        end else begin
            ctrl_rsp_valid_o <= 1'b1;
            ctrl_rsp_data_o <= 32'h0;
        end
    end
end

always_ff@(posedge ctrl_clock_i) begin
    dma_req_valid_o <= 1'b0;
    dma_req_addr_o <= apple_base_addr1 + current_offset;
end

character_ram charram(
    .addra(charram_write_addr),
    .clka(ctrl_clock_i),
    .dina(charram_write_data),
    .ena(charram_write_enable),
    .wea(1'b1),

    .addrb(charram_read_addr),
    .clkb(ctrl_clock_i),
    .doutb(charram_read_data),
    .enb(charram_read_enable)
);

wire [2:0] tmds_data, tmds_clk;
wire pixel_clk, pixel_clk_x5, pll_locked;
wire [9:0] cx, cy;

assign HDMI_OEN = 1'b1;

always_ff@(posedge pixel_clk) begin
end

// SOURCE_DEVICE_INFORMATION = 0x08 (GAME)
hdmi_wrapper hdmi(
    .reset(!pll_locked),

    .clk_pixel(pixel_clk),
    .clk_pixel_x5(pixel_clk_x5),

    .cx(cx),
    .cy(cy),

    .tmds(tmds_data),
    .tmds_clock(tmds_clk)

    //.rgb( { 8'h80, 8'h00, 8'hff } )
);

assign vsync_hdmi = cx==0 && cy==0;
xpm_cdc_single(
    .src_in(vsync_hdmi),
    .src_clk(pixel_clk),

    .dest_clk(ctrl_clock_i),
    .dest_out(vsync_ctrl)
);

MMCME2_BASE#(
    .DIVCLK_DIVIDE(5),
    .CLKFBOUT_MULT_F(63.000),
    .CLKIN1_PERIOD(20.000),
    .CLKOUT0_DIVIDE_F(25.000),
    .CLKOUT1_DIVIDE(5)
) clocks(
    .CLKIN1(raw_clock_i),
    .RST(1'b0),
    .PWRDWN(1'b0),

    .LOCKED(pll_locked),

    .CLKOUT0(pixel_clk),
    .CLKOUT1(pixel_clk_x5)
);

genvar i;
generate

for( i=0; i<=2; ++i ) begin
    OBUFDS buffer( .I(tmds_data[i]), .O(TMDS_data_p[i]), .OB(TMDS_data_n[i]));
end

OBUFDS ( .I(tmds_clk), .O(TMDS_clk_p), .OB(TMDS_clk_n) );

endgenerate

endmodule
