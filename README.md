# moonbit-cache-padded

A MoonBit library that provides cache-padded data structures to reduce false sharing in multi-threaded applications.

## Overview

False sharing occurs when multiple threads access different variables that happen to reside on the same cache line, causing unnecessary cache invalidation and performance degradation. This library provides cache-padded wrappers that ensure each value occupies its own cache line.

## Features

- **Cache-line padding**: Ensures data structures are aligned to cache line boundaries
- **Cross-platform**: Automatically detects and uses the correct cache line size
- **Memory efficient**: Only adds padding when necessary for performance
- **Thread-safe**: Reduces contention between threads accessing different padded values
- **FFI-based implementation**: Uses native C code for optimal performance

## Installation

Add this to your `moon.mod.json`:

```json
{
  "deps": {
    "justjavac/cache_padded": "*"
  }
}
```

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

## Performance Benefits

Cache padding is particularly useful in scenarios where:
- Multiple threads frequently access different variables
- Variables are used in tight loops or performance-critical code
- You want to avoid false sharing between CPU cores

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

## API Reference

### `CachePaddedInt`

A cache-padded wrapper for integer values.

#### Methods

- `CachePaddedInt::new(value: Int) -> CachePaddedInt` - Create a new padded integer
- `get(self: CachePaddedInt) -> Int` - Get the current value
- `set(self: CachePaddedInt, value: Int) -> Unit` - Set a new value
- `update(self: CachePaddedInt, f: (Int) -> Int) -> Unit` - Update using a function
- `destroy(self: CachePaddedInt) -> Unit` - Clean up memory

### Utility Functions

- `get_cache_line_size() -> Int` - Get the system cache line size in bytes

## Requirements

- MoonBit toolchain with native target support
- C compiler (GCC or compatible) for FFI compilation

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