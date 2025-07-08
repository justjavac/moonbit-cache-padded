# moonbit-cache-padded

~~A MoonBit library that provides cache-padded data structures to reduce false sharing in multi-threaded applications.~~

**⚠ BUT: This library currently requires runtime overhead due to MoonBit's limitations in compile-time alignment and struct layout stability.**

---------------

## Overview

False sharing occurs when multiple threads access different variables that happen to reside on the same cache line, causing unnecessary cache invalidation and performance degradation. This library provides cache-padded wrappers that ensure each value occupies its own cache line.

## Usage

```moonbit
// Create cache-padded integer
let padded_counter = CachePaddedInt::new(42)

// Access the value
let value = padded_counter.get()  // Returns 42

// Update the value
padded_counter.set(100)
let new_value = padded_counter.get()  // Returns 100

// Update using a transformation function
padded_counter.update(fn(x) { x * 2 })

// Clean up (important!)
padded_counter.destroy()
```

## Why Not Zero-Cost Abstraction?

Unlike Rust's `CachePadded` which achieves true zero-cost abstraction through compile-time alignment, this MoonBit implementation currently requires runtime overhead. Here's why:

### Current MoonBit Limitations

1. **No Compile-Time Alignment Attributes**: MoonBit currently lacks compile-time alignment directives like Rust's `repr(align(N))` or C++'s `alignas`. There's no way to specify cache line alignment at the type level.

2. **Unstable Struct Layout**: According to MoonBit's FFI documentation, "The layout of `struct`/`enum` with payload is currently unstable." This means:
   - The compiler may reorder struct fields
   - Padding size and position are unpredictable
   - Memory layout cannot be guaranteed

3. **FFI Dependency**: To achieve proper cache alignment, we must use C FFI, which introduces:
   - Runtime heap allocation (`malloc`)
   - Function call overhead across language boundaries
   - Manual memory management requirements
   - Cross-language performance penalties

### Comparison with Rust's Zero-Cost Implementation

| Feature | Rust `CachePadded` | This MoonBit Implementation |
|---------|-------------------|----------------------------|
| **Memory Allocation** | Stack allocation | Heap allocation (`malloc`) |
| **Alignment Method** | Compile-time `repr(align)` | Runtime pointer calculation |
| **Access Overhead** | Zero-cost (`Deref` trait) | FFI function calls |
| **Memory Management** | Automatic cleanup | Manual `destroy()` required |
| **Space Overhead** | Exact padding calculation | Extra cache line allocation |

### Rust's Zero-Cost Example

```rust
// Rust achieves true zero-cost abstraction
#[repr(align(64))]
pub struct CachePadded<T> {
    value: T,
}

// Stack allocated, compile-time aligned, zero runtime overhead
let padded = CachePadded::new(42);  // No malloc!
let value = *padded;  // Direct memory access, no function call!
```

### Future Possibilities

MoonBit may eventually support zero-cost cache padding through:
- **Compiler intrinsics**: Built-in alignment functions
- **Attribute system**: Compile-time alignment directives like `#[repr(align = 64)]`
- **Generic specialization**: Compiler-optimized specialization for specific types

### When to Use This Library

Despite the runtime overhead, this implementation provides significant value when:
- **High contention scenarios**: Performance gains (5-20x) outweigh allocation costs
- **Long-lived objects**: Allocation cost amortized over object lifetime
- **Critical sections**: Preventing false sharing is more important than allocation overhead

The trade-off is justified in multi-threaded scenarios where false sharing elimination provides substantial performance benefits that exceed the FFI and allocation costs.

## Memory Layout

The library ensures that each padded value occupies its own cache line, preventing false sharing. On most modern systems, cache lines are 64 bytes.

```moonbit
// Without padding: two variables might share a cache line
let a = 1
let b = 2  // Might be on same cache line as 'a'

// With padding: each variable gets its own cache line
let padded_a = CachePaddedInt::new(1)
let padded_b = CachePaddedInt::new(2)  // Guaranteed on different cache line
```

### Verification of Cache Line Alignment

The implementation guarantees cache line alignment through:

1. **64-byte allocation**: Each `CachePaddedInt` occupies exactly one cache line (64 bytes)
2. **Pointer alignment**: Memory addresses are aligned to cache line boundaries using bitwise operations
3. **Padding calculation**: Automatic padding ensures no two instances share a cache line

You can verify the cache line size your system uses:
```moonbit
let cache_size = get_cache_line_size()  // Returns 64 on most modern systems
```

## Development

```bash
# Check code
moon check --target native

# Run tests
moon test --target native

# Format code
moon fmt
```

## License

MIT License