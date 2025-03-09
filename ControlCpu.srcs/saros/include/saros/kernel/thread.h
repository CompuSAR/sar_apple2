#pragma once

#include <ds/pool.h>

namespace saros::kernel {

static constexpr size_t MaxNumThreads = 256;

class Thread {
    static ds::PoolAllocator<Thread, MaxNumThreads> _threadPool;

public:
    using Ptr = std::unique_ptr<Thread, ds::PoolAllocator<Thread, MaxNumThreads>&>;

    [[nodiscard]] static Ptr alloc();
};

}
