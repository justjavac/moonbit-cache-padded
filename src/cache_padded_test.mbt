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
  if value != 42 {
    @test.fail("Expected 42, got " + value.to_string())
  }
  padded_int.destroy()
}

///| Test value updates.
/// 
/// This test verifies that values can be updated correctly in cache-padded structures.
test "value_updates" {
  let padded_int = CachePaddedInt::new(10)

  // Test initial value
  if padded_int.get() != 10 {
    @test.fail("Expected initial value 10, got " + padded_int.get().to_string())
  }

  // Test setting new value
  padded_int.set(20)
  if padded_int.get() != 20 {
    @test.fail(
      "Expected value 20 after set, got " + padded_int.get().to_string(),
    )
  }

  // Test setting negative value
  padded_int.set(-5)
  if padded_int.get() != -5 {
    @test.fail(
      "Expected value -5 after set, got " + padded_int.get().to_string(),
    )
  }

  // Test setting zero
  padded_int.set(0)
  if padded_int.get() != 0 {
    @test.fail(
      "Expected value 0 after set, got " + padded_int.get().to_string(),
    )
  }
  padded_int.destroy()
}

///| Test update function.
/// 
/// This test verifies that the update function works correctly for transforming values.
test "update_function" {
  let padded_int = CachePaddedInt::new(10)

  // Test doubling the value
  padded_int.update(fn(x) { x * 2 })
  if padded_int.get() != 20 {
    @test.fail(
      "Expected 20 after doubling, got " + padded_int.get().to_string(),
    )
  }

  // Test adding to the value
  padded_int.update(fn(x) { x + 5 })
  if padded_int.get() != 25 {
    @test.fail(
      "Expected 25 after adding 5, got " + padded_int.get().to_string(),
    )
  }

  // Test complex transformation
  padded_int.update(fn(x) { x * 2 - 10 })
  if padded_int.get() != 40 {
    @test.fail(
      "Expected 40 after complex transformation, got " +
      padded_int.get().to_string(),
    )
  }
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
  if padded_a.get() != 100 {
    @test.fail(
      "Expected padded_a initial value 100, got " + padded_a.get().to_string(),
    )
  }
  if padded_b.get() != 200 {
    @test.fail(
      "Expected padded_b initial value 200, got " + padded_b.get().to_string(),
    )
  }
  if padded_c.get() != 300 {
    @test.fail(
      "Expected padded_c initial value 300, got " + padded_c.get().to_string(),
    )
  }

  // Modify one instance
  padded_b.set(250)

  // Verify others are unaffected
  if padded_a.get() != 100 {
    @test.fail(
      "Expected padded_a unchanged 100, got " + padded_a.get().to_string(),
    )
  }
  if padded_b.get() != 250 {
    @test.fail(
      "Expected padded_b changed to 250, got " + padded_b.get().to_string(),
    )
  }
  if padded_c.get() != 300 {
    @test.fail(
      "Expected padded_c unchanged 300, got " + padded_c.get().to_string(),
    )
  }

  // Modify all instances
  padded_a.set(150)
  padded_c.set(350)

  // Verify all values
  if padded_a.get() != 150 {
    @test.fail(
      "Expected padded_a final value 150, got " + padded_a.get().to_string(),
    )
  }
  if padded_b.get() != 250 {
    @test.fail(
      "Expected padded_b final value 250, got " + padded_b.get().to_string(),
    )
  }
  if padded_c.get() != 350 {
    @test.fail(
      "Expected padded_c final value 350, got " + padded_c.get().to_string(),
    )
  }
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
  if padded_zero.get() != 0 {
    @test.fail(
      "Expected zero initialization, got " + padded_zero.get().to_string(),
    )
  }

  // Test setting to zero
  padded_zero.set(42)
  if padded_zero.get() != 42 {
    @test.fail("Expected 42 after set, got " + padded_zero.get().to_string())
  }
  padded_zero.set(0)
  if padded_zero.get() != 0 {
    @test.fail("Expected 0 after reset, got " + padded_zero.get().to_string())
  }
  padded_zero.destroy()
}

///| Test negative values.
/// 
/// This test verifies that negative values are handled correctly.
test "negative_values" {
  let padded_neg = CachePaddedInt::new(-42)

  // Test negative initialization
  if padded_neg.get() != -42 {
    @test.fail(
      "Expected -42 initialization, got " + padded_neg.get().to_string(),
    )
  }

  // Test setting various negative values
  padded_neg.set(-100)
  if padded_neg.get() != -100 {
    @test.fail("Expected -100 after set, got " + padded_neg.get().to_string())
  }
  padded_neg.set(-1)
  if padded_neg.get() != -1 {
    @test.fail("Expected -1 after set, got " + padded_neg.get().to_string())
  }

  // Test transition from negative to positive
  padded_neg.set(50)
  if padded_neg.get() != 50 {
    @test.fail(
      "Expected 50 after transition, got " + padded_neg.get().to_string(),
    )
  }
  padded_neg.destroy()
}

///| Test cache line size.
/// 
/// This test verifies that the cache line size is reported correctly.
test "cache_line_size" {
  let cache_line_size = get_cache_line_size()

  // Cache line size should be positive and typically 64 bytes
  if cache_line_size <= 0 {
    @test.fail(
      "Cache line size should be positive, got " + cache_line_size.to_string(),
    )
  }

  // On most modern systems, cache line size is 64 bytes
  // But we'll just check it's a reasonable power of 2
  if cache_line_size < 32 {
    @test.fail(
      "Cache line size should be at least 32, got " +
      cache_line_size.to_string(),
    )
  }
  if cache_line_size > 128 {
    @test.fail(
      "Cache line size should be at most 128, got " +
      cache_line_size.to_string(),
    )
  }

  // Check it's a power of 2
  if (cache_line_size & (cache_line_size - 1)) != 0 {
    @test.fail(
      "Cache line size should be power of 2, got " + cache_line_size.to_string(),
    )
  }
}

///| Test large values.
/// 
/// This test verifies that large values are handled correctly.
test "large_values" {
  let padded_large = CachePaddedInt::new(1000000)

  // Test large positive value
  if padded_large.get() != 1000000 {
    @test.fail("Expected 1000000, got " + padded_large.get().to_string())
  }

  // Test large negative value
  padded_large.set(-1000000)
  if padded_large.get() != -1000000 {
    @test.fail("Expected -1000000, got " + padded_large.get().to_string())
  }

  // Test maximum reasonable integer values
  padded_large.set(2147483647) // Near max int32
  if padded_large.get() != 2147483647 {
    @test.fail("Expected 2147483647, got " + padded_large.get().to_string())
  }
  padded_large.set(-2147483648) // Near min int32
  if padded_large.get() != -2147483648 {
    @test.fail("Expected -2147483648, got " + padded_large.get().to_string())
  }
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
  if padded_seq.get() != 46 {
    @test.fail(
      "Expected 46 after sequential operations, got " +
      padded_seq.get().to_string(),
    )
  }
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
    if padded.get() != i {
      @test.fail(
        "Expected " + i.to_string() + ", got " + padded.get().to_string(),
      )
    }
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
    if instances[i].get() != i * 10 {
      @test.fail(
        "Expected " +
        (i * 10).to_string() +
        ", got " +
        instances[i].get().to_string(),
      )
    }
  }

  // Clean up all instances
  for i = 0; i < 10; i = i + 1 {
    instances[i].destroy()
  }
}
