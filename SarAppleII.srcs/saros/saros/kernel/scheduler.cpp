#include <saros/kernel/scheduler.h>

#include <saros/saros.h>
#include <irq.h>

namespace Saros::Kernel {

namespace {

extern "C"
void switchOutCoop();

// With no nested traps, we effectively don't use the MPIE bit in mstatus (will always be 0), and so switchIn is the same for the
// Cooporative and IRQ flows.
extern "C"
[[noreturn]] void switchIn(Thread *);

}

static constexpr size_t ThreadClassSizeInt = ( sizeof(Thread) + sizeof(uint32_t) - 1 ) / sizeof(uint32_t);

[[noreturn]] static void idleLoop(void *) noexcept {
    while(true)
        wfi();
}

void Scheduler::init( std::span<ThreadStack> stackArea ) {
    assertWithMessage( ! _threadStackAllocator.has_value(), "Saros::Scheduler::init called twice" );
    _threadStackAllocator.emplace( stackArea );

    Thread *idleThread = createThread( idleLoop, nullptr, false );

    idleThread->_listHook.unlink();
    idleThread->priority = 2;   // The only thread with priority 2
    _readyThreads[idleThread->priority].push_back(*idleThread);
}

Thread *Scheduler::createThread( Entrypoint function, void *param, bool highPriority ) {
    assertWithMessage( _threadStackAllocator.has_value(), "Saros::Scheduler::createThread called without init" );

    auto newStack = _threadStackAllocator->alloc();

    uint32_t *stackTop = &newStack->back() - ThreadClassSizeInt;
    Thread *thread = new (stackTop) Thread(this, stackTop, std::move(newStack), function, param);

    if( highPriority )
        thread->priority = 0;
    else
        thread->priority = 1;

    thread->setState(Thread::State::Ready);
    _readyThreads[thread->priority].push_back(*thread);

    return thread;
}

void Scheduler::stopThread( Thread *thread ) {
    abortWithMessage("stopThread called, system halted");
}

void Scheduler::run( Thread *thread ) {
    switchIn( thread );
}

Thread *getCurrentThread() {
    Thread *current;

    asm ("mv %0, tp": "=r"(current));

    return current;
}

[[noreturn]] void Scheduler::reschedule() {
    saros._scheduler.rescheduleImpl();
}

[[noreturn]] void Scheduler::rescheduleImpl() {
    Thread *current = getCurrentThread();

    if( current->getState() == Thread::State::Ready ) {
        for( unsigned i = 0; i < current->priority; ++i ) {
            if( !_readyThreads[i].empty() ) {
                switchIn( &_readyThreads[i].front() );
            }
        }

        // Currently running thread is our best candidate
        switchIn( current );
    } else {
        for( unsigned i = 0; i < NumPriorities; ++i ) {
            if( !_readyThreads[i].empty() ) {
                switchIn( &_readyThreads[i].front() );
            }
        }

        abortWithMessage("Ready queue is completely empty");
    }
}

} // namespace Saros::Kernel
