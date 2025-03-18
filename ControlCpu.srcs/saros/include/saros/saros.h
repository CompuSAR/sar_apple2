#pragma once

#include <saros/kernel/scheduler.h>
#include <saros/kernel/thread.h>

namespace Saros {

class Saros {
    Kernel::Scheduler _scheduler;

public:
    Saros() = default;

    Saros(const Saros &) = delete;
    Saros &operator=(const Saros &) = delete;

    void init( std::span<Kernel::ThreadStack> stackArea );
    void run( Kernel::Entrypoint startupThreadFunction, void *param );
};

} // namespace saros

extern Saros::Saros saros;
