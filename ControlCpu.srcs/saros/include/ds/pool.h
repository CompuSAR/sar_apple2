#pragma once

#include <abort.h>

#include <array>
#include <cstddef>
#include <memory>

namespace ds {

template <typename T, size_t NumElements>
class PoolAllocator {
    static constexpr size_t ElementSize = sizeof(T);
    static constexpr size_t ElementAlignment = alignof(T);
    
    union PoolElement {
        alignas(ElementAlignment) std::byte element[ElementSize];
        PoolElement *next;
    };
    static_assert( offsetof(PoolElement, element)==0 );

    std::array<PoolElement, NumElements> _pool;
    PoolElement *_firstFree;

public:
    using Ptr = std::unique_ptr<T, PoolAllocator&>;
    PoolAllocator() : _firstFree(&_pool[0]) {

        // Add all elements to the free list
        for( auto &element : _pool ) {
            element.next = (&element)+1;
        }

        _pool[NumElements-1].next = nullptr;
    }

    PoolAllocator(const PoolAllocator &) = delete;
    PoolAllocator &operator=(const PoolAllocator &) = delete;

    ~PoolAllocator() {
        abortWithMessage("PoolAllocator destructor called");
    }

    template <typename... Args>
    [[nodiscard]] Ptr alloc(Args&&... args) {
        checkWithMessage( _firstFree!=nullptr, "alloc called on empty pool" );

        std::byte *retVal = _firstFree->element;
        _firstFree = _firstFree->next;

        return Ptr( new (retVal) T(std::forward<Args>(args)...), *this );
    }

    void operator()(T *ptr) { // Deleter implmenetation
        free(ptr);
    }

    void free( T *element ) {
        PoolElement *poolElement = convert(element);
        assertWithMessage(
                poolElement >= &_pool[0] && poolElement <= &_pool[NumElements-1],
                "Attempt at freeing pointer from another pool");

        poolElement->next = _firstFree;
        _firstFree = poolElement;
    }

private:
    PoolElement *convert(void *ptr) {
        return reinterpret_cast<PoolElement *>( reinterpret_cast<std::byte *>(ptr) );
    }
};

} // namespace ds
