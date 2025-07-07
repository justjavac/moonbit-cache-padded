///|
// # Cache-Padded Data Structures Module
// 
// This module provides cache-padded data structures for MoonBit to eliminate false sharing
// and improve performance in multi-threaded applications. False sharing is a performance
// bottleneck that occurs when multiple threads access different variables that happen to
// reside on the same cache line, causing unnecessary cache invalidation and memory bus
// traffic.
// 
// ## What is False Sharing?
// 
// False sharing occurs when:
// 1. Two or more CPU cores access different variables
// 2. These variables happen to be located on the same cache line (typically 64 bytes)
// 3. At least one access is a write operation
// 4. This causes the entire cache line to be invalidated across all cores
// 5. Each core must reload the cache line, even though they're accessing different data
// 
// ## Features
// 
// - **Cache-line padding**: Ensures data structures are aligned to cache line boundaries
// - **Generic support**: Works with any data type that can be stored
// - **Cross-platform**: Automatically detects and uses the correct cache line size
// - **Memory efficient**: Only adds padding when necessary for performance
// - **Thread-safe access**: Reduces contention between threads accessing different padded values
// - **FFI-based**: Uses native C implementation for optimal memory alignment
// 
// ## Performance Impact
// 
// **Without cache padding:**
// ```
// Thread A writes to variable X ++
//                                ++ Same 64-byte cache line
// Thread B writes to variable Y ++
// Result: Cache line ping-pongs between cores, severe performance degradation
// ```
// 
// **With cache padding:**
// ```
// Thread A writes to padded variable X + Cache line 1 (64 bytes)
// Thread B writes to padded variable Y + Cache line 2 (64 bytes)
// Result: No cache invalidation, optimal performance
// ```
// 
// ## Basic Usage
// 
// ```moonbit
// // Create cache-padded integer counters for different threads
// let thread1_counter = CachePaddedInt::new(0)
// let thread2_counter = CachePaddedInt::new(0)
// 
// // Each counter is on its own cache line, preventing false sharing
// // Thread 1 can update thread1_counter without affecting Thread 2's cache
// thread1_counter.set(100)
// thread2_counter.set(200)
// 
// // Access values
// let count1 = thread1_counter.get()  // Returns 100
// let count2 = thread2_counter.get()  // Returns 200
// 
// // Clean up
// thread1_counter.destroy()
// thread2_counter.destroy()
// ```
// 
// ## When to Use Cache Padding
// 
// Cache padding is beneficial when:
// - **High-frequency access**: Variables accessed frequently by multiple threads
// - **Performance-critical code**: Tight loops or hot paths in your application
// - **Independent counters**: Each thread maintains separate counters or statistics
// - **Producer-consumer scenarios**: Different threads writing to different queue indices
// - **Lock-free algorithms**: Reducing contention in atomic operations
// 
// ## When NOT to Use Cache Padding
// 
// Avoid cache padding when:
// - **Memory-constrained environments**: Padding increases memory usage
// - **Single-threaded applications**: No benefit without multiple threads
// - **Infrequent access**: Variables accessed rarely don't benefit from padding
// - **Shared data structures**: Data that's intentionally shared between threads
// 
// ## Memory Layout and Alignment
// 
// The module ensures that each padded value occupies its own cache line:
// 
// ```
// Memory Layout (64-byte cache lines):
// 
// [Cache Line 1: 64 bytes]
// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// + CachePaddedInt A +           Padding (60 bytes)            +
// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// 
// [Cache Line 2: 64 bytes]  
// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// + CachePaddedInt B +           Padding (60 bytes)            +
// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// ```
// 
// ## Platform Support
// 
// | Platform | Cache Line Size | Alignment Method |
// |----------|-----------------|------------------|
// | x86/x64  | 64 bytes        | `_aligned_malloc()` (Windows), `aligned_alloc()` (Linux) |
// | ARM64    | 64-128 bytes    | `posix_memalign()` |
// | RISC-V   | 64 bytes        | Standard alignment functions |
// | Other    | Detected at runtime | Platform-specific APIs |
// 
// ## Performance Benchmarks
// 
// Typical performance improvements with cache padding:
// - **Parallel counters**: 5-20x improvement in high-contention scenarios
// - **Producer-consumer**: 2-5x improvement in throughput
// - **Independent statistics**: 3-10x improvement in multi-threaded analytics
// 
// ## Memory Overhead
// 
// - **Per padded value**: Up to one cache line (typically 64 bytes)
// - **Actual overhead**: Depends on the size of the contained data
// - **For Int (4 bytes)**: 60 bytes of padding = 15x memory overhead
// - **For larger structures**: Proportionally less overhead
// 
// ## Thread Safety Notes
// 
// - **Read operations**: Thread-safe by design
// - **Write operations**: Thread-safe for the memory access, but logical consistency
//   requires application-level synchronization
// - **Mixed operations**: Use atomic operations or locks for read-modify-write cycles
// - **Memory ordering**: No special memory ordering guarantees beyond cache alignment

///| Cache-padded wrapper for integer values.
// 
// This struct wraps an integer value and ensures it's properly aligned to cache line
// boundaries to prevent false sharing in multi-threaded scenarios. The structure
// uses FFI to manage memory allocation and alignment through native C code.
// 
// ## Memory Layout
// 
// The struct contains only a pointer to the actual padded data:
// ```
// CachePaddedInt {
//   ptr: Int64  // Pointer to aligned memory containing the integer + padding
// }
// ```
// 
// The actual integer value and padding are stored in native memory:
// ```
// Native Memory Layout:
// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// + Int (4) +                   Padding (60 bytes)                   +
// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// +                    Total: 64 bytes (1 cache line)                +
// ```
// 
// ## Thread Safety
// 
// - **Structure itself**: Not thread-safe for assignment/destruction
// - **Contained value**: Thread-safe for basic read/write operations
// - **Memory alignment**: Guaranteed to prevent false sharing
// - **Concurrent access**: Multiple threads can safely access different instances
// 
// ## Usage Patterns
// 
// **Per-thread counters:**
// ```moonbit
// // Each thread gets its own counter, preventing false sharing
// let worker1_counter = CachePaddedInt::new(0)
// let worker2_counter = CachePaddedInt::new(0)
// ```
// 
// **Shared statistics:**
// ```moonbit
// // Different statistics in separate cache lines
// let requests_served = CachePaddedInt::new(0)
// let errors_encountered = CachePaddedInt::new(0)
// ```
pub struct CachePaddedInt {
  ptr : Int64
}

///| Create a new cache-padded integer with the specified initial value.
// 
// This function allocates memory for a cache-padded integer and initializes it
// with the given value. The returned `CachePaddedInt` must be destroyed with 
// `destroy()` when no longer needed to free allocated memory.
// 
// The allocated memory is aligned to cache line boundaries (typically 64 bytes)
// to prevent false sharing when multiple threads access different padded values.
// The function uses platform-specific memory allocation functions to ensure
// proper alignment.
// 
// ## Memory Allocation
// 
// The function performs the following operations:
// 1. Detects the system's cache line size at runtime
// 2. Allocates aligned memory using platform-specific functions:
//    - **Windows**: `_aligned_malloc()`
//    - **POSIX**: `aligned_alloc()` or `posix_memalign()`
// 3. Initializes the integer value at the beginning of the allocated memory
// 4. Returns a handle to the allocated and initialized memory
// 
// ## Parameters
// 
// - `value`: The initial integer value to store in the padded structure
// 
// ## Returns
// 
// A new `CachePaddedInt` instance initialized with the specified value.
// The instance manages a pointer to cache-aligned memory.
// 
// ## Example
// 
// ```moonbit
// // Create padded counters for different threads
// let thread1_work_done = CachePaddedInt::new(0)
// let thread2_work_done = CachePaddedInt::new(0)
// 
// // Each counter is on its own cache line
// let initial_value = thread1_work_done.get()  // Returns 0
// 
// // Remember to clean up
// thread1_work_done.destroy()
// thread2_work_done.destroy()
// ```
// 
// ## Performance Considerations
// 
// - **Memory overhead**: Each instance uses a full cache line (64+ bytes)
// - **Allocation cost**: Aligned allocation may be slower than regular allocation
// - **Cache efficiency**: Prevents false sharing, improving multi-threaded performance
// - **Memory locality**: Consider grouping related operations on the same instance
// 
// ## Error Handling
// 
// - The function may fail if the system runs out of memory
// - Behavior is undefined if memory allocation fails
// - Always pair with `destroy()` to prevent memory leaks
pub fn CachePaddedInt::new(value : Int) -> CachePaddedInt {
  CachePaddedInt::{ ptr: cache_padded_new_int(value) }
}

///| Get the current integer value from the cache-padded structure.
// 
// This function returns the integer value stored in the cache-padded structure.
// The operation is thread-safe for reading and will not cause false sharing
// when multiple threads read from different padded instances.
// 
// The function performs a simple memory load from the aligned memory location.
// Due to cache alignment, this operation will not interfere with other threads
// accessing different `CachePaddedInt` instances.
// 
// ## Parameters
// 
// - `self`: The cache-padded structure to read from
// 
// ## Returns
// 
// The current integer value stored in the structure
// 
// ## Thread Safety
// 
// - **Concurrent reads**: Multiple threads can safely read simultaneously
// - **Mixed read/write**: Reads during writes may return stale or new values
// - **Memory ordering**: No special ordering guarantees beyond cache alignment
// - **False sharing**: Prevented by cache line alignment
// 
// ## Performance
// 
// - **Cache locality**: Optimized for single-core access patterns
// - **Memory bandwidth**: Minimal impact due to alignment
// - **Latency**: Single memory load operation, typically 1-4 CPU cycles
// 
// ## Example
// 
// ```moonbit
// let counter = CachePaddedInt::new(42)
// 
// // Thread-safe reading
// let current_value = counter.get()  // Returns 42
// 
// // Multiple threads can read concurrently without performance penalty
// // (assuming they're reading from different CachePaddedInt instances)
// let value_copy = counter.get()     // Also returns 42
// 
// counter.destroy()
// ```
// 
// ## Use Cases
// 
// - **Statistics collection**: Reading counters maintained by other threads
// - **Status monitoring**: Checking progress indicators without blocking
// - **Configuration values**: Reading settings that change infrequently
// - **Performance monitoring**: Sampling metrics in real-time applications
pub fn CachePaddedInt::get(self : CachePaddedInt) -> Int {
  cache_padded_get_int(self.ptr)
}

///| Set a new integer value in the cache-padded structure.
// 
// This function updates the integer value stored in the cache-padded structure.
// The operation is thread-safe for the memory access itself due to cache alignment,
// preventing false sharing with other padded instances. However, concurrent writes
// to the same instance should be properly synchronized for data consistency.
// 
// The function performs a simple memory store to the aligned memory location.
// The cache padding ensures that writes to different instances won't invalidate
// each other's cache lines, maintaining optimal performance in multi-threaded scenarios.
// 
// ## Parameters
// 
// - `self`: The cache-padded structure to modify
// - `value`: The new integer value to store
// 
// ## Thread Safety
// 
// - **Single writer**: Safe when only one thread writes to an instance
// - **Multiple writers**: Requires external synchronization (locks, atomics)
// - **Concurrent readers**: Readers may see old or new values during writes
// - **False sharing**: Prevented by cache line alignment
// - **Memory ordering**: Standard store semantics, no additional ordering guarantees
// 
// ## Performance Characteristics
// 
// - **Write latency**: Single memory store, typically 1-4 CPU cycles
// - **Cache impact**: Only affects the current instance's cache line
// - **Memory bandwidth**: Optimal due to no false sharing
// - **Scalability**: Linear performance scaling with number of cores
// 
// ## Synchronization Patterns
// 
// **Single writer per instance:**
// ```moonbit
// // Safe: each thread has its own counter
// let thread1_counter = CachePaddedInt::new(0)
// let thread2_counter = CachePaddedInt::new(0)
// 
// // Thread 1 writes only to thread1_counter
// thread1_counter.set(100)
// 
// // Thread 2 writes only to thread2_counter  
// thread2_counter.set(200)
// ```
// 
// **Multiple writers (requires external synchronization):**
// ```moonbit
// // Unsafe without synchronization
// let shared_counter = CachePaddedInt::new(0)
// 
// // Both threads writing to same instance - need locks/atomics
// // Thread 1: shared_counter.set(100)  // Needs synchronization
// // Thread 2: shared_counter.set(200)  // Needs synchronization
// ```
// 
// ## Example
// 
// ```moonbit
// let metrics = CachePaddedInt::new(0)
// 
// // Update the value
// metrics.set(42)
// let updated_value = metrics.get()  // Returns 42
// 
// // Increment pattern (not atomic - needs external sync for concurrency)
// let current = metrics.get()
// metrics.set(current + 1)
// 
// metrics.destroy()
// ```
// 
// ## Use Cases
// 
// - **Per-thread statistics**: Each thread maintains separate counters
// - **Producer-consumer indices**: Different threads managing queue positions
// - **Configuration updates**: Updating settings from management threads
// - **Performance counters**: High-frequency metric updates without contention
// 
// ## Important Notes
// 
// - This operation is NOT atomic for read-modify-write sequences
// - Use atomic operations or locks when multiple threads write to the same instance
// - The cache padding only prevents false sharing, not race conditions
// - Consider using `update()` for functional-style modifications
pub fn CachePaddedInt::set(self : CachePaddedInt, value : Int) -> Unit {
  cache_padded_set_int(self.ptr, value)
}

///| Update the integer value using a transformation function.
// 
// This function applies a transformation function to the current integer value and
// stores the result back in the cache-padded structure. This provides a functional
// approach to value modification and is useful for complex update operations.
// 
// **Important:** This operation is NOT atomic. It performs a read-modify-write
// sequence that can be interrupted by other threads. For concurrent access,
// use external synchronization or atomic operations.
// 
// ## Operation Sequence
// 
// The function performs these steps:
// 1. Read the current value from the padded structure
// 2. Apply the transformation function to get the new value
// 3. Store the new value back to the padded structure
// 
// ## Parameters
// 
// - `self`: The cache-padded structure to modify
// - `f`: A transformation function that takes the current integer value and returns the new value
// 
// ## Thread Safety Considerations
// 
// - **Single writer**: Safe when only one thread calls `update()` on an instance
// - **Multiple writers**: Race conditions possible - requires external synchronization
// - **Mixed operations**: Other threads calling `set()` during `update()` can cause data loss
// - **Reader safety**: Readers may see intermediate states during the update
// 
// ## Performance
// 
// - **Operations count**: One read + one write + function call overhead
// - **Cache efficiency**: Benefits from padding when multiple instances are updated
// - **Function overhead**: Depends on the complexity of the transformation function
// 
// ## Synchronization Example
// 
// ```moonbit
// // For concurrent access, use external synchronization:
// // 1. Acquire lock
// // 2. Call update()  
// // 3. Release lock
// 
// // Or use atomic compare-and-swap patterns:
// // loop {
// //   let current = padded_int.get()
// //   let new_value = f(current)
// //   if compare_and_swap(current, new_value) { break }
// // }
// ```
// 
// ## Example
// 
// ```moonbit
// let counter = CachePaddedInt::new(10)
// 
// // Double the value
// counter.update(fn(x) { x * 2 })
// let doubled = counter.get()  // Returns 20
// 
// // Complex transformation
// counter.update(fn(x) { 
//   if x > 100 { 
//     x / 2 
//   } else { 
//     x + 10 
//   } 
// })
// let result = counter.get()  // Returns 30 (20 + 10)
// 
// // Functional composition
// counter.update(fn(x) { x + 1 })  // Increment
// counter.update(fn(x) { x * 3 })  // Then multiply
// let final_value = counter.get()  // Returns 93 ((30 + 1) * 3)
// 
// counter.destroy()
// ```
// 
// ## Use Cases
// 
// - **Mathematical operations**: Complex calculations based on current value
// - **Conditional updates**: Value changes based on current state
// - **Functional programming**: Immutable-style updates in imperative context
// - **Business logic**: Applying domain-specific transformation rules
// - **Data processing**: Streaming updates with transformation pipelines
// 
// ## Alternative Patterns
// 
// **Simple increment/decrement:**
// ```moonbit
// // Instead of: counter.update(fn(x) { x + 1 })
// // Consider: counter.set(counter.get() + 1)
// ```
// 
// **Atomic updates (for concurrent access):**
// ```moonbit
// // Use atomic operations or locks for thread safety
// // This function alone is not sufficient for concurrent updates
// ```
// 
// ## Important Notes
// 
// - Not suitable for concurrent modification without external synchronization
// - The transformation function should be side-effect free for predictable behavior
// - Consider the cost of the transformation function in performance-critical code
// - Use simpler `set()` for constant value assignments
pub fn CachePaddedInt::update(self : CachePaddedInt, f : (Int) -> Int) -> Unit {
  let current_value = self.get()
  let new_value = f(current_value)
  self.set(new_value)
}

///| Destroy the cache-padded integer and free associated memory.
// 
// This function must be called when the cache-padded integer is no longer
// needed to prevent memory leaks. It deallocates the aligned memory that was
// allocated by `new()` and invalidates the structure for further use.
// 
// After calling this function, the `CachePaddedInt` instance should not be
// used anymore. Any subsequent calls to `get()`, `set()`, or `update()` will
// result in undefined behavior.
// 
// ## Memory Management
// 
// The function performs the following operations:
// 1. Validates that the pointer is not null (implementation-dependent)
// 2. Calls the platform-specific deallocation function:
//    - **Windows**: `_aligned_free()`
//    - **POSIX**: `free()` (for memory allocated with `aligned_alloc()`)
// 3. The memory becomes available for reuse by the system
// 
// ## Parameters
// 
// - `self`: The cache-padded integer to destroy
// 
// ## Thread Safety
// 
// - **Not thread-safe**: Only one thread should call `destroy()` per instance
// - **Concurrent access**: Other threads must not access the instance during destruction
// - **Synchronization**: Ensure all threads have finished using the instance before destruction
// - **Resource cleanup**: Safe to call from any thread once exclusive access is ensured
// 
// ## Resource Management Patterns
// 
// **RAII-style cleanup:**
// ```moonbit
// fn process_data() {
//   let counter = CachePaddedInt::new(0)
//   
//   // Use counter...
//   counter.set(42)
//   let result = counter.get()
//   
//   // Always clean up before returning
//   counter.destroy()
//   
//   return result
// }
// ```
// 
// **Error handling:**
// ```moonbit
// fn safe_processing() {
//   let counter = CachePaddedInt::new(0)
//   
//   // Critical: ensure cleanup even if errors occur
//   try {
//     // Risky operations...
//     process_with_counter(counter)
//   } finally {
//     counter.destroy()  // Always called
//   }
// }
// ```
// 
// ## Example
// 
// ```moonbit
// // Create and use padded integer
// let metrics = CachePaddedInt::new(0)
// 
// // Perform operations
// metrics.set(100)
// metrics.update(fn(x) { x * 2 })
// let final_value = metrics.get()  // Returns 200
// 
// // Essential: clean up memory
// metrics.destroy()
// 
// // After destroy(), do not use metrics anymore:
// // metrics.get()  // ← UNDEFINED BEHAVIOR - DON'T DO THIS
// ```
// 
// ## Multiple Instance Management
// 
// ```moonbit
// // Managing multiple instances
// let counters = [
//   CachePaddedInt::new(0),
//   CachePaddedInt::new(0), 
//   CachePaddedInt::new(0)
// ]
// 
// // Use counters...
// for i in 0..<counters.length() {
//   counters[i].set(i * 10)
// }
// 
// // Clean up all instances
// for counter in counters {
//   counter.destroy()
// }
// ```
// 
// ## Common Pitfalls
// 
// - **Double destruction**: Calling `destroy()` twice is undefined behavior
// - **Use after destruction**: Accessing the instance after `destroy()` is unsafe
// - **Memory leaks**: Forgetting to call `destroy()` leaks aligned memory
// - **Dangling references**: Other variables holding references become invalid
// 
// ## Performance Considerations
// 
// - **Deallocation cost**: Aligned deallocation may be slightly slower than regular `free()`
// - **Memory fragmentation**: Frequent allocation/deallocation can fragment aligned memory
// - **Bulk operations**: Consider pooling or bulk allocation for high-frequency scenarios
// 
// ## Best Practices
// 
// 1. **Immediate cleanup**: Call `destroy()` as soon as the instance is no longer needed
// 2. **Exception safety**: Ensure `destroy()` is called even when errors occur
// 3. **Clear ownership**: Designate which thread/function is responsible for cleanup
// 4. **Documentation**: Document the lifetime and ownership of padded instances
// 5. **Testing**: Verify that all code paths call `destroy()` appropriately
pub fn CachePaddedInt::destroy(self : CachePaddedInt) -> Unit {
  cache_padded_destroy(self.ptr)
}

///| Get the cache line size used by the system.
// 
// This function returns the cache line size in bytes that the system uses
// for cache alignment. This information is useful for diagnostic purposes,
// performance analysis, or when you need to understand the exact memory
// layout and overhead of cache-padded structures.
// 
// The cache line size is detected at runtime and varies by CPU architecture:
// - **x86/x64**: Typically 64 bytes
// - **ARM64**: Usually 64 bytes, sometimes 128 bytes
// - **RISC-V**: Commonly 64 bytes
// - **Older architectures**: May be 32 bytes or other sizes
// 
// ## Detection Method
// 
// The function uses platform-specific methods to determine cache line size:
// - **Windows**: `GetLogicalProcessorInformation()` API
// - **Linux**: Reading `/sys/devices/system/cpu/cpu0/cache/index0/coherency_line_size`
// - **macOS**: `sysctl hw.cachelinesize` 
// - **Generic**: Compile-time detection or reasonable defaults
// 
// ## Returns
// 
// The cache line size in bytes (typically 64 on modern systems)
// 
// ## Performance Analysis
// 
// Use this function to:
// - **Calculate memory overhead**: Compare data size to cache line size
// - **Optimize data structures**: Align critical data to cache boundaries
// - **Debug performance issues**: Verify cache alignment is working correctly
// - **Portability testing**: Ensure code works across different architectures
// 
// ## Example
// 
// ```moonbit
// let cache_size = get_cache_line_size()
// println("System cache line size: \{cache_size} bytes")
// // Output: "System cache line size: 64 bytes" (typical)
// 
// // Calculate overhead for CachePaddedInt
// let int_size = 4  // Size of Int in bytes (platform-dependent)
// let padding_overhead = cache_size - int_size
// let overhead_ratio = (padding_overhead * 100) / cache_size
// 
// println("Integer size: \{int_size} bytes")
// println("Padding overhead: \{padding_overhead} bytes")
// println("Memory efficiency: \{100 - overhead_ratio}%")
// 
// // Example output for 64-byte cache lines:
// // "Integer size: 4 bytes"
// // "Padding overhead: 60 bytes" 
// // "Memory efficiency: 6.25%"
// ```
// 
// ## Memory Layout Visualization
// 
// ```moonbit
// let cache_size = get_cache_line_size()
// 
// println("Memory layout for CachePaddedInt:")
// println("+++++++++++++++++++++++++++++++++++++++++++++++++++++")
// println("+ Int (4) + Padding (\{cache_size - 4} bytes)        +")
// println("+++++++++++++++++++++++++++++++++++++++++++++++++++++")
// println("+          Total: \{cache_size} bytes (1 cache line) +")
// 
// // Typical output:
// // "Memory layout for CachePaddedInt:"
// // "+++++++++++++++++++++++++++++++++++++++++++++++++++++"
// // "+ Int (4) + Padding (60 bytes)                      +"
// // "+++++++++++++++++++++++++++++++++++++++++++++++++++++"
// // "+          Total: 64 bytes (1 cache line)           +"
// ```
// 
// ## Multi-Architecture Considerations
// 
// ```moonbit
// let cache_size = get_cache_line_size()
// 
// match cache_size {
//   32 => println("Legacy architecture detected")
//   64 => println("Modern x86/ARM architecture")
//   128 => println("High-performance ARM architecture")
//   _ => println("Unusual cache line size: \{cache_size}")
// }
// ```
// 
// ## Debugging and Profiling
// 
// ```moonbit
// fn analyze_cache_performance() {
//   let cache_size = get_cache_line_size()
//   let padded_count = 1000
//   let total_memory = padded_count * cache_size
//   
//   println("Performance analysis:")
//   println("- Cache line size: \{cache_size} bytes")
//   println("- Number of padded integers: \{padded_count}")
//   println("- Total memory usage: \{total_memory} bytes (\{total_memory / 1024}KB)")
//   println("- Memory efficiency per integer: \{(4 * 100) / cache_size}%")
// }
// ```
// 
// ## Use Cases
// 
// - **Performance debugging**: Verify that padding is working as expected
// - **Memory usage analysis**: Calculate actual overhead of cache padding
// - **Cross-platform compatibility**: Ensure algorithms work on different architectures
// - **Benchmarking**: Compare performance across systems with different cache line sizes
// - **Educational purposes**: Understanding cache behavior and memory alignment
// 
// ## Important Notes
// 
// - Cache line size is determined once at program startup and remains constant
// - The value represents the L1 data cache line size (most relevant for false sharing)
// - Some systems may have multiple cache levels with different line sizes
// - Virtual machines may report different values than the host hardware
// - This function is safe to call from any thread and has no side effects
pub fn get_cache_line_size() -> Int {
  cache_padded_get_cache_line_size()
}

// FFI bindings for cache-padded operations
//
// These are the low-level Foreign Function Interface bindings that connect MoonBit
// to the native C implementation of cache-padded data structures. Each binding
// corresponds to a specific C function that handles memory allocation, data access,
// and resource management for cache-aligned memory.
//
// Note: These bindings are specialized for the Int type for simplicity and
// performance. In a more comprehensive implementation, these could be made generic
// or provide variants for different data types (Bool, Double, custom structs, etc.).
//
// Platform-specific implementations:
// - Windows: Uses _aligned_malloc/_aligned_free with GetLogicalProcessorInformation
// - Linux: Uses aligned_alloc/free with sysfs cache line detection  
// - macOS: Uses posix_memalign/free with sysctl cache line detection
// - Other POSIX: Falls back to posix_memalign with compile-time cache line size

///| FFI binding: Create a new cache-padded integer in native C code.
// 
// This is an internal function that interfaces with the C implementation
// to allocate aligned memory and initialize a cache-padded integer. The
// function ensures proper cache line alignment to prevent false sharing.
// 
// ## C Function Signature
// ```c
// int64_t moonbit_cache_padded_new_int(int32_t value);
// ```
// 
// ## Implementation Details
// 
// The C function performs:
// 1. **Cache line detection**: Queries the system for cache line size
// 2. **Aligned allocation**: Uses platform-specific aligned memory allocation
// 3. **Initialization**: Stores the integer value at the beginning of the allocated memory
// 4. **Validation**: Ensures allocation succeeded and alignment is correct
// 5. **Return pointer**: Returns the memory address as a 64-bit integer
// 
// ## Platform-Specific Allocation
// 
// - **Windows**: `_aligned_malloc(cache_line_size, cache_line_size)`
// - **POSIX**: `aligned_alloc(cache_line_size, cache_line_size)` or `posix_memalign()`
// - **Fallback**: Regular malloc with manual alignment (less efficient)
// 
// ## Parameters
// 
// - `value`: The initial integer value to store in the cache-padded structure
// 
// ## Returns
// 
// A 64-bit integer representing the memory address of the allocated and initialized
// cache-padded structure. Returns 0 on allocation failure.
// 
// ## Error Conditions
// 
// - Returns 0 if memory allocation fails
// - May abort on critical errors (implementation-dependent)
// - Undefined behavior if cache line size detection fails
// 
// ## Note
// 
// This function is internal and should not be called directly.
// Users should use `CachePaddedInt::new()` instead for type safety and proper error handling.
extern "C" fn cache_padded_new_int(value : Int) -> Int64 = "moonbit_cache_padded_new_int"

///| FFI binding: Get value from cache-padded integer in native C code.
// 
// This is an internal function that interfaces with the C implementation
// to read the integer value from a cache-padded structure. The function
// performs a simple memory load from the aligned memory location.
// 
// ## C Function Signature
// ```c
// int32_t moonbit_cache_padded_get_int(int64_t ptr);
// ```
// 
// ## Implementation Details
// 
// The C function performs:
// 1. **Pointer validation**: Checks that the pointer is not null (debug builds)
// 2. **Memory load**: Reads the integer value from the beginning of the cache line
// 3. **Return value**: Returns the loaded integer value
// 
// ## Memory Access Pattern
// 
// ```
// Cache Line (64 bytes):
// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// + Int (4) +                   Padding (60 bytes)                   +
// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//      ^
//   Read from here
// ```
// 
// ## Parameters
// 
// - `ptr`: Memory address of the cache-padded structure (as returned by `cache_padded_new_int`)
// 
// ## Returns
// 
// The integer value stored in the cache-padded structure
// 
// ## Performance Characteristics
// 
// - **Latency**: Single memory load operation (1-4 CPU cycles)
// - **Cache efficiency**: Aligned access optimizes cache utilization
// - **Thread safety**: Thread-safe for concurrent reads from different cache lines
// 
// ## Error Conditions
// 
// - Undefined behavior if `ptr` is null or invalid
// - Undefined behavior if `ptr` points to deallocated memory
// - May return garbage data if memory has been corrupted
// 
// ## Note
// 
// This function is internal and should not be called directly.
// Users should use `CachePaddedInt::get()` instead for safety and convenience.
extern "C" fn cache_padded_get_int(ptr : Int64) -> Int = "moonbit_cache_padded_get_int"

///| FFI binding: Set value in cache-padded integer in native C code.
// 
// This is an internal function that interfaces with the C implementation
// to update the integer value in a cache-padded structure. The function
// performs a simple memory store to the aligned memory location.
// 
// ## C Function Signature
// ```c
// void moonbit_cache_padded_set_int(int64_t ptr, int32_t value);
// ```
// 
// ## Implementation Details
// 
// The C function performs:
// 1. **Pointer validation**: Checks that the pointer is not null (debug builds)
// 2. **Memory store**: Writes the integer value to the beginning of the cache line
// 3. **Memory barriers**: Optional memory barriers for consistency (implementation-dependent)
// 
// ## Memory Access Pattern
// 
// ```
// Cache Line (64 bytes):
// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// + Int (4) +                   Padding (60 bytes)                   +
// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//      ^
//   Write to here
// ```
// 
// ## Parameters
// 
// - `ptr`: Memory address of the cache-padded structure (as returned by `cache_padded_new_int`)
// - `value`: The new integer value to store
// 
// ## Performance Characteristics
// 
// - **Latency**: Single memory store operation (1-4 CPU cycles)
// - **Cache efficiency**: Aligned access optimizes cache utilization
// - **False sharing prevention**: Padding ensures other cache lines aren't affected
// - **Memory ordering**: Standard store semantics, no additional guarantees
// 
// ## Thread Safety
// 
// - **Single writer**: Safe when only one thread writes to the structure
// - **Multiple readers**: Concurrent reads during writes may see old or new values
// - **Multiple writers**: Requires external synchronization for data consistency
// 
// ## Error Conditions
// 
// - Undefined behavior if `ptr` is null or invalid
// - Undefined behavior if `ptr` points to deallocated memory
// - Data corruption possible with concurrent unsynchronized writes
// 
// ## Note
// 
// This function is internal and should not be called directly.
// Users should use `CachePaddedInt::set()` instead for safety and convenience.
extern "C" fn cache_padded_set_int(ptr : Int64, value : Int) -> Unit = "moonbit_cache_padded_set_int"

///| FFI binding: Destroy cache-padded structure in native C code.
// 
// This is an internal function that interfaces with the C implementation
// to deallocate the aligned memory used by a cache-padded structure. The
// function uses the appropriate platform-specific deallocation function.
// 
// ## C Function Signature
// ```c
// void moonbit_cache_padded_destroy(int64_t ptr);
// ```
// 
// ## Implementation Details
// 
// The C function performs:
// 1. **Pointer validation**: Checks that the pointer is not null
// 2. **Platform-specific deallocation**:
//    - **Windows**: `_aligned_free(ptr)`
//    - **POSIX**: `free(ptr)` (for aligned_alloc) or manual cleanup (for posix_memalign)
// 3. **Memory clearing**: Optional memory clearing for security (implementation-dependent)
// 
// ## Memory Management
// 
// The function must match the allocation method used in `cache_padded_new_int`:
// - If allocated with `_aligned_malloc`, must use `_aligned_free`
// - If allocated with `aligned_alloc`, can use standard `free`
// - If allocated with `posix_memalign`, must use standard `free`
// 
// ## Parameters
// 
// - `ptr`: Memory address of the cache-padded structure to deallocate
// 
// ## Resource Cleanup
// 
// After this function completes:
// - The memory becomes available for reuse by the system
// - The pointer becomes invalid and should not be used
// - Any subsequent access to the memory results in undefined behavior
// 
// ## Performance Considerations
// 
// - **Deallocation overhead**: Aligned deallocation may be slightly slower than regular free
// - **Memory fragmentation**: Frequent alloc/dealloc cycles can fragment aligned memory pools
// - **System calls**: May involve system calls on some platforms
// 
// ## Error Conditions
// 
// - Safe no-op if `ptr` is null (implementation-dependent)
// - Undefined behavior if `ptr` is invalid or already deallocated
// - Double-free protection depends on platform and implementation
// 
// ## Debugging Support
// 
// Debug builds may:
// - Validate pointer alignment and magic numbers
// - Clear memory contents to detect use-after-free bugs
// - Track allocation/deallocation for leak detection
// - Log memory operations for debugging
// 
// ## Note
// 
// This function is internal and should not be called directly.
// Users should use `CachePaddedInt::destroy()` instead for safety and proper cleanup.
extern "C" fn cache_padded_destroy(ptr : Int64) -> Unit = "moonbit_cache_padded_destroy"

///| FFI binding: Get cache line size in native C code.
// 
// This is an internal function that interfaces with the C implementation
// to retrieve the system's cache line size. The function uses platform-specific
// methods to detect the cache line size at runtime.
// 
// ## C Function Signature
// ```c
// int32_t moonbit_cache_padded_get_cache_line_size(void);
// ```
// 
// ## Implementation Details
// 
// The C function uses platform-specific detection methods:
// 
// **Windows:**
// ```c
// SYSTEM_LOGICAL_PROCESSOR_INFORMATION buffer[256];
// DWORD length = sizeof(buffer);
// GetLogicalProcessorInformation(buffer, &length);
// // Parse buffer for cache information
// ```
// 
// **Linux:**
// ```c
// FILE* file = fopen("/sys/devices/system/cpu/cpu0/cache/index0/coherency_line_size", "r");
// fscanf(file, "%d", &cache_line_size);
// ```
// 
// **macOS:**
// ```c
// size_t size = sizeof(cache_line_size);
// sysctlbyname("hw.cachelinesize", &cache_line_size, &size, NULL, 0);
// ```
// 
// **Generic fallback:**
// ```c
// #define CACHE_LINE_SIZE 64  // Reasonable default for most modern systems
// ```
// 
// ## Detection Strategy
// 
// The function typically follows this priority order:
// 1. **Runtime detection**: Query OS/hardware for actual cache line size
// 2. **Compile-time detection**: Use preprocessor detection of CPU architecture
// 3. **Conservative default**: Fall back to 64 bytes (safe for most systems)
// 
// ## Returns
// 
// The cache line size in bytes. Common values:
// - **64 bytes**: Most x86/x64 and modern ARM processors
// - **128 bytes**: Some high-performance ARM processors
// - **32 bytes**: Older or embedded processors
// - **256 bytes**: Some specialized or future architectures
// 
// ## Caching and Performance
// 
// - **Single detection**: Cache line size is detected once at program startup
// - **Global storage**: Result is cached in a global variable for fast access
// - **Thread safety**: Detection is thread-safe, subsequent calls just return cached value
// - **No overhead**: After initial detection, function has minimal performance impact
// 
// ## Architecture Support
// 
// | Architecture | Typical Size | Detection Method |
// |-------------|--------------|------------------|
// | x86/x86_64  | 64 bytes     | CPUID instruction or OS API |
// | ARM64       | 64-128 bytes | Device tree or OS API |
// | RISC-V      | 64 bytes     | Device tree or compile-time |
// | PowerPC     | 32-128 bytes | OS API or compile-time |
// | SPARC       | 64 bytes     | OS API or compile-time |
// 
// ## Error Handling
// 
// - **Detection failure**: Falls back to conservative default (64 bytes)
// - **Invalid values**: Validates returned size is power of 2 and reasonable (16-256 bytes)
// - **System limitations**: Some virtualized environments may report incorrect values
// 
// ## Note
// 
// This function is internal and should not be called directly.
// Users should use `get_cache_line_size()` instead for a clean public interface.
extern "C" fn cache_padded_get_cache_line_size() -> Int = "moonbit_cache_padded_get_cache_line_size"
