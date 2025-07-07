///|
/// # Cache Padded Tests
/// 
/// This file contains comprehensive tests for the cache-padded module.
/// Tests cover basic functionality, edge cases, and proper memory management.

///| Test basic creation and value access.
/// 
/// This test verifies that cache-padded values can be created and accessed correctly.
test "basic_creation_and_access" {
  let padded_int = CachePaddedInt::new(42)
  let value = padded_int.get()
  assert_eq(value, 42)
  padded_int.destroy()
}

///| Test value updates.
/// 
/// This test verifies that values can be updated correctly in cache-padded structures.
test "value_updates" {
  let padded_int = CachePaddedInt::new(10)

  // Test initial value
  assert_eq(padded_int.get(), 10)

  // Test setting new value
  padded_int.set(20)
  assert_eq(padded_int.get(), 20)

  // Test setting negative value
  padded_int.set(-5)
  assert_eq(padded_int.get(), -5)

  // Test setting zero
  padded_int.set(0)
  assert_eq(padded_int.get(), 0)
  padded_int.destroy()
}

///| Test update function.
/// 
/// This test verifies that the update function works correctly for transforming values.
test "update_function" {
  let padded_int = CachePaddedInt::new(10)

  // Test doubling the value
  padded_int.update(fn(x) { x * 2 })
  assert_eq(padded_int.get(), 20)

  // Test adding to the value
  padded_int.update(fn(x) { x + 5 })
  assert_eq(padded_int.get(), 25)

  // Test complex transformation
  padded_int.update(fn(x) { x * 2 - 10 })
  assert_eq(padded_int.get(), 40)
  padded_int.destroy()
}

///| Test multiple instances.
/// 
/// This test verifies that multiple cache-padded instances work independently.
test "multiple_instances" {
  let padded_a = CachePaddedInt::new(100)
  let padded_b = CachePaddedInt::new(200)
  let padded_c = CachePaddedInt::new(300)

  // Verify initial values
  assert_eq(padded_a.get(), 100)
  assert_eq(padded_b.get(), 200)
  assert_eq(padded_c.get(), 300)

  // Modify one instance
  padded_b.set(250)

  // Verify others are unaffected
  assert_eq(padded_a.get(), 100)
  assert_eq(padded_b.get(), 250)
  assert_eq(padded_c.get(), 300)

  // Modify all instances
  padded_a.set(150)
  padded_c.set(350)

  // Verify all values
  assert_eq(padded_a.get(), 150)
  assert_eq(padded_b.get(), 250)
  assert_eq(padded_c.get(), 350)
  padded_a.destroy()
  padded_b.destroy()
  padded_c.destroy()
}

///| Test zero values.
/// 
/// This test verifies that zero values are handled correctly.
test "zero_values" {
  let padded_zero = CachePaddedInt::new(0)

  // Test zero initialization
  assert_eq(padded_zero.get(), 0)

  // Test setting to zero
  padded_zero.set(42)
  assert_eq(padded_zero.get(), 42)
  padded_zero.set(0)
  assert_eq(padded_zero.get(), 0)
  padded_zero.destroy()
}

///| Test negative values.
/// 
/// This test verifies that negative values are handled correctly.
test "negative_values" {
  let padded_neg = CachePaddedInt::new(-42)

  // Test negative initialization
  assert_eq(padded_neg.get(), -42)

  // Test setting various negative values
  padded_neg.set(-100)
  assert_eq(padded_neg.get(), -100)
  padded_neg.set(-1)
  assert_eq(padded_neg.get(), -1)

  // Test transition from negative to positive
  padded_neg.set(50)
  assert_eq(padded_neg.get(), 50)
  padded_neg.destroy()
}

///| Test cache line size.
/// 
/// This test verifies that the cache line size is reported correctly.
test "cache_line_size" {
  let cache_line_size = get_cache_line_size()

  // Cache line size should be positive and typically 64 bytes
  assert_eq(cache_line_size > 0, true)

  // On most modern systems, cache line size is 64 bytes
  // But we'll just check it's a reasonable power of 2
  assert_eq(cache_line_size >= 32, true)
  assert_eq(cache_line_size <= 128, true)

  // Check it's a power of 2
  assert_eq(cache_line_size & (cache_line_size - 1), 0)
}

///| Test large values.
/// 
/// This test verifies that large values are handled correctly.
test "large_values" {
  let padded_large = CachePaddedInt::new(1000000)

  // Test large positive value
  assert_eq(padded_large.get(), 1000000)

  // Test large negative value
  padded_large.set(-1000000)
  assert_eq(padded_large.get(), -1000000)

  // Test maximum reasonable integer values
  padded_large.set(2147483647) // Near max int32
  assert_eq(padded_large.get(), 2147483647)
  padded_large.set(-2147483648) // Near min int32
  assert_eq(padded_large.get(), -2147483648)
  padded_large.destroy()
}

///| Test sequential operations.
/// 
/// This test verifies that sequential operations work correctly.
test "sequential_operations" {
  let padded_seq = CachePaddedInt::new(1)

  // Perform a sequence of operations
  for i = 0; i < 10; i = i + 1 {
    let current = padded_seq.get()
    padded_seq.set(current + i)
  }

  // Final value should be 1 + 0 + 1 + 2 + ... + 9 = 1 + 45 = 46
  assert_eq(padded_seq.get(), 46)
  padded_seq.destroy()
}

///| Test memory management.
/// 
/// This test verifies that memory is properly managed by creating and destroying
/// many instances.
test "memory_management" {
  // Create and destroy many instances to test memory management
  for i = 0; i < 100; i = i + 1 {
    let padded = CachePaddedInt::new(i)
    assert_eq(padded.get(), i)
    padded.destroy()
  }

  // Test with different values
  let instances : Array[CachePaddedInt] = Array::new()
  for i = 0; i < 10; i = i + 1 {
    let padded = CachePaddedInt::new(i * 10)
    instances.push(padded)
  }

  // Verify all instances
  for i = 0; i < 10; i = i + 1 {
    assert_eq(instances[i].get(), i * 10)
  }

  // Clean up all instances
  for i = 0; i < 10; i = i + 1 {
    instances[i].destroy()
  }
}
