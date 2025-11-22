#include "display_ctrl.h"
#include "reg.h"

namespace Display {

static constexpr uint32_t DeviceId = 7;

static constexpr uint32_t ModeRegister = 0x0000;
    static constexpr uint32_t ModeRegister_TextMode = 0;

    static constexpr uint32_t ModeRegister_40col = 0;
static constexpr uint32_t DmaAddr1 = 0x0004;
static constexpr uint32_t CharsetBase = 0x8000;

static constexpr RGB DefaultPallette[] = {
    { 0x00, 0x00, 0x00 },       // Black
    { 0x93, 0x0b, 0x7c },       // Purple
    { 0x1f, 0x35, 0xd3 },       // Blue
    { 0xbb, 0x36, 0xff },       // Pink
    { 0x00, 0x76, 0x0c },       // Green
    { 0x7e, 0x7e, 0x7e },       // Gray1
    { 0x07, 0xa8, 0xe0 },       // Cyan
    { 0x9d, 0xac, 0xff },       // Light blue
    { 0x62, 0x4c, 0x00 },       // Brown
    { 0xf9, 0x56, 0x1d },       // Orange
    { 0x7e, 0x7e, 0x7e },       // Gray2
    { 0xff, 0x81, 0xec },       // Light pink
    { 0x43, 0xc8, 0x00 },       // Light Green
    { 0xdc, 0xcd, 0x16 },       // Yellow
    { 0x5d, 0xf7, 0x84 },       // Lighter green
    { 0xff, 0xff, 0xff },       // White
};

void selectCharset( const CharSet *charset ) {
    for( uint32_t i = 0; i<charset->size(); ++i ) {
        reg_write_32( DeviceId, CharsetBase + 2*i, (*charset)[i].raw[0] );
        reg_write_32( DeviceId, CharsetBase + 2*i + 1, (*charset)[i].raw[1] );
    }
}

void selectTextMode( uint32_t textBase ) {
    reg_write_32( DeviceId, ModeRegister, ModeRegister_TextMode | ModeRegister_40col );
    reg_write_32( DeviceId, DmaAddr1, textBase );
}

} // namespace Display
