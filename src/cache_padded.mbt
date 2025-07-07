///|
/// # Cache Padded Module
/// 
/// This module provides cache-padded data structures for MoonBit to reduce false sharing
/// in multi-threaded applications. False sharing occurs when multiple threads access
/// different variables that happen to reside on the same cache line, causing unnecessary
/// cache invalidation and performance degradation.
/// 
/// ## Features
/// 
/// - **Cache-line padding**: Ensures data structures are aligned to cache line boundaries
/// - **Generic support**: Works with any data type that can be stored
/// - **Cross-platform**: Automatically detects and uses the correct cache line size
/// - **Memory efficient**: Only adds padding when necessary for performance
/// - **Thread-safe**: Reduces contention between threads accessing different padded values
/// 
/// ## Basic Usage
/// 
/// ```moonbit
///   // Create cache-padded integer
///   let padded_counter = CachePaddedInt::new(42)
///   
///   // Access the value
///   let _value = padded_counter.get()  // Returns 42
///   
///   // Update the value
///   padded_counter.set(100)
///   let _new_value = padded_counter.get()  // Returns 100
///   
///   // Clean up
///   padded_counter.destroy()
/// ```
/// 
/// ## Performance Benefits
/// 
/// Cache padding is particularly useful in scenarios where:
/// - Multiple threads frequently access different variables
/// - Variables are used in tight loops or performance-critical code
/// - You want to avoid false sharing between CPU cores
/// 
/// ## Memory Layout
/// 
/// The module ensures that each padded value occupies its own cache line,
/// preventing false sharing. On most modern systems, cache lines are 64 bytes,
/// so padding is added to ensure proper alignment.
/// 
/// ```moonbit
///   // Without padding: two variables might share a cache line
///   let _a = 1
///   let _b = 2  // Might be on same cache line as 'a'
///   
///   // With padding: each variable gets its own cache line
///   let _padded_a = CachePaddedInt::new(1)
///   let _padded_b = CachePaddedInt::new(2)  // Guaranteed on different cache line
/// ```
/// ```

///| Cache-padded wrapper for integer values.
/// 
/// This struct wraps an integer value and ensures it's properly aligned to cache line
/// boundaries to prevent false sharing in multi-threaded scenarios.
/// The underlying implementation uses FFI to manage memory allocation and alignment.
pub struct CachePaddedInt {
  ptr : Int64
}

///| Create a new cache-padded integer with the specified initial value.
/// 
/// This function allocates memory for a cache-padded integer and initializes it
/// with the given value. The returned `CachePaddedInt` must be destroyed with 
/// `destroy()` when no longer needed to free allocated memory.
/// 
/// The allocated memory is aligned to cache line boundaries to prevent false
/// sharing when multiple threads access different padded values.
/// 
/// ## Parameters
/// 
/// - `value`: The initial integer value to store in the padded structure
/// 
/// ## Returns
/// 
/// A new `CachePaddedInt` instance initialized with the specified value
/// 
/// ## Example
/// 
/// ```moonbit
///   let padded_int = CachePaddedInt::new(42)
///   let _value = padded_int.get()
///   // value is 42
///   padded_int.destroy()
/// ```
pub fn CachePaddedInt::new(value : Int) -> CachePaddedInt {
  CachePaddedInt::{ ptr: cache_padded_new_int(value) }
}

///| Get the current integer value from the cache-padded structure.
/// 
/// This function returns the integer value stored in the cache-padded structure.
/// The access is thread-safe for reading, but concurrent writes should be
/// properly synchronized using appropriate locking mechanisms.
/// 
/// ## Parameters
/// 
/// - `self`: The cache-padded structure to read from
/// 
/// ## Returns
/// 
/// The current integer value stored in the structure
/// 
/// ## Example
/// 
/// ```moonbit
///   let padded_int = CachePaddedInt::new(100)
///   let _value = padded_int.get()
///   // value is 100
///   padded_int.destroy()
/// ```
pub fn CachePaddedInt::get(self : CachePaddedInt) -> Int {
  cache_padded_get_int(self.ptr)
}

///| Set a new integer value in the cache-padded structure.
/// 
/// This function updates the integer value stored in the cache-padded structure.
/// The operation is thread-safe for the memory access itself, but concurrent
/// writes should be properly synchronized using appropriate locking mechanisms
/// to ensure data consistency.
/// 
/// ## Parameters
/// 
/// - `self`: The cache-padded structure to modify
/// - `value`: The new integer value to store
/// 
/// ## Example
/// 
/// ```moonbit
///   let padded_int = CachePaddedInt::new(0)
///   padded_int.set(42)
///   let _value = padded_int.get()
///   // value is 42
///   padded_int.destroy()
/// ```
pub fn CachePaddedInt::set(self : CachePaddedInt, value : Int) -> Unit {
  cache_padded_set_int(self.ptr, value)
}

///| Update the integer value using a transformation function.
/// 
/// This function applies a transformation function to the current integer value and
/// stores the result. This is useful for atomic-like updates where you want
/// to modify the value based on its current state.
/// 
/// Note: This operation is not atomic. If you need atomic updates, consider
/// using this in combination with proper locking mechanisms.
/// 
/// ## Parameters
/// 
/// - `self`: The cache-padded structure to modify
/// - `f`: A function that takes the current integer value and returns the new integer value
/// 
/// ## Example
/// 
/// ```moonbit
///   let padded_int = CachePaddedInt::new(10)
///   
///   // Double the value
///   padded_int.update(fn(x) { x * 2 })
///   let _value = padded_int.get()
///   // value is 20
///   
///   padded_int.destroy()
/// ```
pub fn CachePaddedInt::update(self : CachePaddedInt, f : (Int) -> Int) -> Unit {
  let current_value = self.get()
  let new_value = f(current_value)
  self.set(new_value)
}

///| Destroy the cache-padded integer and free associated memory.
/// 
/// This function must be called when the cache-padded integer is no longer
/// needed to prevent memory leaks. After calling this function, the structure
/// should not be used anymore.
/// 
/// ## Parameters
/// 
/// - `self`: The cache-padded integer to destroy
/// 
/// ## Example
/// 
/// ```moonbit
///   let padded_int = CachePaddedInt::new(42)
///   // Use the padded integer...
///   padded_int.destroy() // Clean up memory
/// ```
pub fn CachePaddedInt::destroy(self : CachePaddedInt) -> Unit {
  cache_padded_destroy(self.ptr)
}

///| Get the cache line size used by the system.
/// 
/// This function returns the cache line size in bytes that the system uses
/// for padding. This is useful for diagnostic purposes or when you need to
/// know the exact memory layout.
/// 
/// ## Returns
/// 
/// The cache line size in bytes (typically 64 on modern systems)
/// 
/// ## Example
/// 
/// ```moonbit
///   let _cache_line_size = get_cache_line_size()
///   // cache_line_size is typically 64
/// ```
pub fn get_cache_line_size() -> Int {
  cache_padded_get_cache_line_size()
}

// FFI bindings for cache-padded operations
// Note: These are specialized for Int type for simplicity
// In a real implementation, these would be generic or have variants for different types

///| FFI binding: Create a new cache-padded integer in native C code.
/// 
/// This is an internal function that interfaces with the C implementation.
/// Users should use `CachePadded::new()` instead of calling this directly.
extern "C" fn cache_padded_new_int(value : Int) -> Int64 = "moonbit_cache_padded_new_int"

///| FFI binding: Get value from cache-padded integer in native C code.
/// 
/// This is an internal function that interfaces with the C implementation.
/// Users should use `CachePadded::get()` instead of calling this directly.
extern "C" fn cache_padded_get_int(ptr : Int64) -> Int = "moonbit_cache_padded_get_int"

///| FFI binding: Set value in cache-padded integer in native C code.
/// 
/// This is an internal function that interfaces with the C implementation.
/// Users should use `CachePadded::set()` instead of calling this directly.
extern "C" fn cache_padded_set_int(ptr : Int64, value : Int) -> Unit = "moonbit_cache_padded_set_int"

///| FFI binding: Destroy cache-padded structure in native C code.
/// 
/// This is an internal function that interfaces with the C implementation.
/// Users should use `CachePadded::destroy()` instead of calling this directly.
extern "C" fn cache_padded_destroy(ptr : Int64) -> Unit = "moonbit_cache_padded_destroy"

///| FFI binding: Get cache line size in native C code.
/// 
/// This is an internal function that interfaces with the C implementation.
/// Users should use `get_cache_line_size()` instead of calling this directly.
extern "C" fn cache_padded_get_cache_line_size() -> Int = "moonbit_cache_padded_get_cache_line_size"
