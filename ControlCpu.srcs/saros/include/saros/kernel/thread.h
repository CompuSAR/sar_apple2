#pragma once

#include <ds/pool.h>

namespace saros::kernel {

static constexpr size_t MaxNumThreads = 256;

class Thread {
    static ds::PoolAllocator<Thread, MaxNumThreads> _threadPool;
    static constexpr size_t ContextSize = 29;

    std::array<uint32_t, ContextSize> _context; // Assembly code assumes this is the first element
public:
    using Ptr = std::unique_ptr<Thread, ds::PoolAllocator<Thread, MaxNumThreads>&>;
    using Entrypoint = void(*)() noexcept;

    [[nodiscard]] static Ptr alloc();
};
static_assert( std::is_standard_layout_v<Thread>, "Class Thread must be standard layout" );

}
