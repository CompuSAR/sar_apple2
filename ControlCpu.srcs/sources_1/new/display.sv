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

localparam BitsPerPixel = 24;

/************************************************************
 * Control registers
 ************************************************************/
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

task update_char(input [8:0] addr, input [31:0] data);
    charram_write_enable <= 1'b1;
    charram_write_addr <= addr;
    charram_write_data <= data;
endtask

always_ff@(posedge ctrl_clock_i) begin
    charram_write_enable <= 1'b0;
    ctrl_rsp_valid_o <= 1'b0;

    if( ctrl_req_valid_i && ctrl_req_ack_o ) begin
        if( ctrl_req_write_i ) begin
            casex( ctrl_req_addr_i )
                16'h0000: mode_register <= ctrl_req_addr_i;
                16'h0004: apple_base_addr1 <= ctrl_req_data_i;
                16'h8xxx: update_char(ctrl_req_addr_i[8:0], ctrl_req_data_i);
            endcase
        end else begin
            ctrl_rsp_valid_o <= 1'b1;
            ctrl_rsp_data_o <= 32'h0;
        end
    end
end

/************************************************************
 * Pixel generation
 ************************************************************/
localparam UnsetColor = 24'hff75df; // Light pinkish
localparam SOUTH_BUS_WIDTH_BYTES = SOUTH_BUS_WIDTH / 8;

logic [BitsPerPixel-1:0] pixels_ctrl[UpdateBlock];
logic [BitsPerPixel-1:0] pixels_hdmi[UpdateBlock];

localparam PixelsFillSize = $clog2(UpdateBlock+2);
logic pixels_buffer_valid = 1'b0;
logic [PixelsFillSize-1:0] pixels_fill = UpdateBlock;
logic [BitsPerPixel-1:0] pixels_gen_buf[UpdateBlock];

logic dma_fetch_in_progress = 1'b0;
logic [SOUTH_BUS_WIDTH-1:0] raw_apple_screen_1, raw_apple_screen_fetch;
wire [7:0] raw_apple_screen_1_bytes[SOUTH_BUS_WIDTH_BYTES];
logic fetch_buffer_valid = 1'b0;
logic [$clog2( SOUTH_BUS_WIDTH_BYTES + 1 )-1:0] work_buffer_1_consumed;

logic cdc_req_ctrl = 1'b0, cdc_ack_ctrl;

genvar i;

generate

for( i=0; i<SOUTH_BUS_WIDTH_BYTES; ++i ) begin
    assign raw_apple_screen_1_bytes[i] = raw_apple_screen_1[i*8+7 : i*8];
end

endgenerate

task advance_position();
    // XXX implement
endtask

always_ff@(posedge ctrl_clock_i) begin
    charram_read_enable <= 1'b0;

    if( cdc_req_ctrl && cdc_ack_ctrl )
        cdc_req_ctrl <= 1'b0;

    if( dma_req_valid_o && dma_req_ack_i ) begin
        dma_req_valid_o <= 1'b0;
    end

    if( dma_fetch_in_progress && dma_rsp_valid_i ) begin
        dma_fetch_in_progress <= 1'b0;
        raw_apple_screen_fetch <= dma_rsp_data_i;
        fetch_buffer_valid <= 1'b1;
    end

    if( reset_i ) begin
        work_buffer_1_consumed <= SOUTH_BUS_WIDTH_BYTES;
        dma_fetch_in_progress <= 1'b0;
        dma_req_valid_o <= 1'b0;

        pixels_fill <= UpdateBlock + 1;
        current_third <= 0;
        current_row <= 0;
        current_subrow <= 0;
        current_col <= 0;
        
        cdc_req_ctrl <= 1'b0;
    end else begin
        // Transfer pixels to HDMI clock component
        if( pixels_buffer_valid && !cdc_req_ctrl && !cdc_ack_ctrl ) begin
            pixels_ctrl <= pixels_gen_buf;
            cdc_req_ctrl <= 1'b1;
            pixels_fill <= 0;
            pixels_buffer_valid <= 1'b0;
        end

        // Fetch raw data from memory
        if( work_buffer_1_consumed == SOUTH_BUS_WIDTH_BYTES ) begin
            if( fetch_buffer_valid ) begin
                raw_apple_screen_1 <= raw_apple_screen_fetch;
                fetch_buffer_valid <= 1'b0;
                work_buffer_1_consumed <= 0;

                advance_position();
            end
        end

        if( !fetch_buffer_valid && !dma_fetch_in_progress ) begin
            dma_req_valid_o <= 1'b1;
            dma_req_addr_o <= apple_base_addr1 + current_offset;
            dma_fetch_in_progress <= 1'b1;
        end

        // Generate pixels
        if( work_buffer_1_consumed != SOUTH_BUS_WIDTH_BYTES ) begin
            // Still filling the buffer

            if( ! pixels_fill[PixelsFillSize-1] ) begin
                // The above condition is true for all pixels_fill < UpdateBlock
            end
                 //raw_apple_screen_1_bytes[ work_buffer_1_consumed ];
        end
    end
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

wire [UpdateBlock*BitsPerPixel - 1:0] cdc_data_ctrl, cdc_data_hdmi;

generate

for( i=0; i<UpdateBlock; ++i ) begin
    assign cdc_data_ctrl[(i+1)*BitsPerPixel-1 : i*BitsPerPixel] = pixels_ctrl[i];
end

endgenerate

xpm_cdc_handshake#(
    .WIDTH(UpdateBlock*BitsPerPixel)
) pixels_transfer(
    .src_clk(ctrl_clock_i),
    .src_in(cdc_data_ctrl),
    .src_rcv(cdc_ack_ctrl),
    .src_send(cdc_req_ctrl),

    .dest_clk(pixel_clk),
    .dest_req(cdc_req_hdmi),
    .dest_ack(cdc_ack_hdmi),
    .dest_out(cdc_data_hdmi)
);

/************************************************************
 * HDMI signal generation
 ************************************************************/
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

generate

for( i=0; i<=2; ++i ) begin
    OBUFDS buffer( .I(tmds_data[i]), .O(TMDS_data_p[i]), .OB(TMDS_data_n[i]));
end

OBUFDS ( .I(tmds_clk), .O(TMDS_clk_p), .OB(TMDS_clk_n) );

endgenerate

endmodule
