#include <saros/kernel/thread.h>

#include <ds/pool.h>

namespace saros::kernel {

ds::PoolAllocator<Thread, MaxNumThreads> Thread::_threadPool{};

Thread::Ptr Thread::alloc() {
    return _threadPool.alloc();
}

} // namespace saros::kernel
