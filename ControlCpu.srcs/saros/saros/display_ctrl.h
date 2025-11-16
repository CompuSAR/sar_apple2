#pragma once

#include <stdint.h>

#include <array>

namespace Display {

struct CharBitmap {
    union {
        uint32_t raw[2];
        uint8_t  bits[8];
    };
};

enum class Page : uint8_t {
    Page0,
    Page1,
};

using CharSet = std::array< CharBitmap, 128 >;

void selectCharset( const CharSet *charset );

void selectTextMode( uint32_t textBase );                               // 40 Columns
void selectTextMode( uint32_t textBase1, uint32_t textBase2 );          // 80 Columns

} // namespace Display
