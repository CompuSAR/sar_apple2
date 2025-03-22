#include <saros/kernel/scheduler.h>

namespace Saros::Kernel {

namespace {

extern "C"
void switchOutCoop();

extern "C"
void switchOutIrq();

// With no nested traps, we effectively don't use the MPIE bit in mstatus (will always be 0), and so switchIn is the same for the
// Cooporative and IRQ flows.
extern "C"
[[noreturn]] void switchIn(Thread *);

}

static constexpr size_t ThreadClassSizeInt = ( sizeof(Thread) + sizeof(uint32_t) - 1 ) / sizeof(uint32_t);

void Scheduler::init( std::span<ThreadStack> stackArea ) {
    assertWithMessage( ! _threadStackAllocator.has_value(), "Saros::Scheduler::init called twice" );
    _threadStackAllocator.emplace( stackArea );
}

Thread *Scheduler::createThread( Entrypoint function, void *param, bool highPriority ) {
    assertWithMessage( _threadStackAllocator.has_value(), "Saros::Scheduler::createThread called without init" );

    auto newStack = _threadStackAllocator->alloc();

    uint32_t *stackTop = &newStack->back() - ThreadClassSizeInt;
    Thread *thread = new (stackTop) Thread(this, stackTop, std::move(newStack), function, param);

    return thread;
}

void Scheduler::stopThread( Thread *thread ) {
    abortWithMessage("stopThread called, system halted");
}

void Scheduler::run( Thread *thread ) {
    switchIn( thread );
}

namespace {

extern "C"
[[noreturn]] void reschedule() {
    abortWithMessage("Reschedule called");
}

}

} // namespace Saros::Kernel
