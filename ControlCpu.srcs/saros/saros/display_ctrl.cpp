#include "display_ctrl.h"
#include "reg.h"

namespace Display {

static constexpr uint32_t DeviceId = 7;

static constexpr uint32_t ModeRegister = 0x0000;
    static constexpr uint32_t ModeRegister_TextMode = 0;

    static constexpr uint32_t ModeRegister_40col = 0;
static constexpr uint32_t DmaAddr1 = 0x0004;
static constexpr uint32_t CharsetBase = 0x1000;

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
