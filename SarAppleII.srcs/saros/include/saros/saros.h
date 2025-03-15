#pragma once

#include <saros/kernel/thread.h>

namespace saros {

class Saros {
public:
    explicit Saros( kernel::Thread::Entrypoint startup_thread_function );

    void run();
};

} // namespace saros
