#include <saros/saros.h>

Saros::Saros saros;

namespace Saros {

void Saros::init( std::span<Kernel::ThreadStack> stackArea ) {
    _scheduler.init( stackArea );
}

void Saros::run( Kernel::Entrypoint startupThreadFunction, void *threadParam ) {
    Kernel::Thread *thread = _scheduler.createThread( startupThreadFunction, threadParam );

    _scheduler.run( thread );
}

} // namespace Saros
