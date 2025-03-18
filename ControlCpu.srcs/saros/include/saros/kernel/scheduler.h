#pragma once

#include <saros/kernel/thread.h>

#include <optional>

namespace Saros::Kernel {

class Thread;

class Scheduler {
    friend Thread;

    static constexpr size_t MaxNumThreads = 256;

    std::optional<ThreadStackAllocator> _threadStackAllocator;

public:
    void init( std::span<ThreadStack> stackArea );

    Thread *createThread( Entrypoint function, void *param, bool highPriority = false );

    void run( Thread *thread );

private:
    // Methods to be called by Thread
    [[noreturn]] void stopThread( Thread *thread );
};

} // namespace saros::kernel
