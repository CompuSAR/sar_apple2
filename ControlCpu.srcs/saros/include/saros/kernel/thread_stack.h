#pragma once

#include <ds/pool.h>

#include <array>
#include <cstddef>
#include <cstdint>

namespace Saros::Kernel {

static constexpr size_t ThreadStackSize = 32*1024;
using ThreadStack = std::array<uint32_t, ThreadStackSize/sizeof(uint32_t)>;
using ThreadStackAllocator = DS::PoolAllocator<ThreadStack, 0>;

using Entrypoint = void(*)(void *) noexcept;

} // namespace Saros::Kernel
