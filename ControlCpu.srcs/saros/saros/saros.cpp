#include <saros/saros.h>

#include <csr.h>
#include <irq.h>

#include <span>

Saros::Saros saros;

namespace Saros {

void Saros::init( std::span<Kernel::ThreadStack> stackArea ) {
    _scheduler.init( stackArea );
}

void Saros::run( Kernel::Entrypoint startupThreadFunction, void *threadParam ) {
    Kernel::Thread *thread = _scheduler.createThread( startupThreadFunction, threadParam );

    initIrq();

    _scheduler.run( thread );
}

namespace {

extern "C"
void switchOutIrq();

extern "C"
uint32_t __trap_stack_end;

}

void Saros::initIrq() {
    auto trap = reinterpret_cast<uintptr_t>(switchOutIrq);
    csr_write<CSR::mtvec>( trap );

    // IRQ stack pointer
    csr_write<CSR::mscratch>( reinterpret_cast<uint32_t>(&__trap_stack_end) );

    irq_external_mask(0xffffffff);

    csr_read_set_bits<CSR::mie>( MIE__MEIE_MASK );
    csr_read_set_bits<CSR::mstatus>( MSTATUS__MIE );
}

} // namespace Saros
