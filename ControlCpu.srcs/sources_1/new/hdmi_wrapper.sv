`timescale 1ns / 1ps

module hdmi_wrapper(
    input clk_pixel_x5,
    input clk_pixel,
    input clk_audio,
    // synchronous reset back to 0,0
    input reset,
    input [23:0] rgb,
    input [15:0] audio_sample_word [1:0],

    // These outputs go to your HDMI port
    output [2:0] tmds,
    output tmds_clock,
    
    // All outputs below this line stay inside the FPGA
    // They are used (by you) to pick the color each pixel should have
    // i.e. always_ff @(posedge pixel_clk) rgb <= {8'd0, 8'(cx), 8'(cy)};
    output [9:0] cx,
    output [9:0] cy,

    // The screen is at the upper left corner of the frame.
    // 0,0 = 0,0 in video
    // the frame includes extra space for sending auxiliary data
    output [9:0] frame_width,
    output [9:0] frame_height,
    output [9:0] screen_width,
    output [9:0] screen_height
);

hdmi#(
    .VIDEO_REFRESH_RATE(60),
    .VENDOR_NAME("CompuSAR"),
    .PRODUCT_DESCRIPTION({"Apple ][", 64'b0}),
    .SOURCE_DEVICE_INFORMATION(8'h08)
) (
    .clk_pixel_x5(clk_pixel_x5),
    .clk_pixel(clk_pixel),
    .clk_audio(clk_audio),
    .reset(reset),
    .rgb(rgb),
    .audio_sample_word(audio_sample_word),

    .tmds(tmds),
    .tmds_clock(tmds_clock),

    .cx(cx),
    .cy(cy),

    .frame_width(frame_width),
    .frame_height(frame_height),
    .screen_width(screen_width),
    .screen_height(screen_height)
);

endmodule
