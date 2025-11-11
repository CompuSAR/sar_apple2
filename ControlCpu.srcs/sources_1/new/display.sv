`timescale 1ns / 1ps

module display# (
    SOUTH_BUS_WIDTH = 128
)(
    input raw_clock_i,
    input ctrl_clock_i,
    input reset_i,

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

wire [2:0] tmds_data, tmds_clk;
wire pixel_clk, pixel_clk_x5, pll_locked;

assign HDMI_OEN = 1'b1;

// SOURCE_DEVICE_INFORMATION = 0x08 (GAME)
hdmi#(
    .VIDEO_REFRESH_RATE(60),
    .VENDOR_NAME("CompuSAR"),
    .PRODUCT_DESCRIPTION({"Apple ][", 64'b0}),
    .SOURCE_DEVICE_INFORMATION(8'h08)
) hdmi(
    .reset(reset_i || !pll_locked),

    .clk_pixel(pixel_clk),
    .clk_pixel_x5(pixel_clk_x5),

    .tmds(tmds_data),
    .tmds_clock(tmds_clk),

    .rgb( { 8'h80, 8'hff, 8'h00 } )
); 

hdmi_clk(
    .clk_in1(raw_clock_i),
    .reset(1'b0),

    .locked(pll_locked),
    .pixel_clk(pixel_clk),
    .pixel_clk_x5(pixel_clk_x5)
);

genvar i;
generate

for( i=0; i<=2; ++i ) begin
    OBUFDS buffer( .I(tmds_data[i]), .O(TMDS_data_p[i]), .OB(TMDS_data_n[i]));
end

OBUFDS ( .I(tmds_clk), .O(TMDS_clk_p), .OB(TMDS_clk_n) );

endgenerate

endmodule
