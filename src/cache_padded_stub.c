#include "moonbit.h"
#include <stdlib.h>
#include <stdint.h>
#include <stdbool.h>
#include <string.h>

// Cache line size constants
#define CACHE_LINE_SIZE 64
#define CACHE_LINE_MASK (CACHE_LINE_SIZE - 1)

// Structure for cache-padded integer
typedef struct {
    int32_t value;
    char padding[CACHE_LINE_SIZE - sizeof(int32_t)];
} cache_padded_int_t;

// Align pointer to cache line boundary
static void* align_to_cache_line(void* ptr) {
    uintptr_t addr = (uintptr_t)ptr;
    uintptr_t aligned = (addr + CACHE_LINE_MASK) & ~CACHE_LINE_MASK;
    return (void*)aligned;
}

// Create a new cache-padded integer
MOONBIT_FFI_EXPORT int64_t moonbit_cache_padded_new_int(int32_t value) {
    // Allocate extra space to ensure we can align to cache line
    void* raw_ptr = malloc(sizeof(cache_padded_int_t) + CACHE_LINE_SIZE);
    if (!raw_ptr) {
        return 0; // Return null pointer on allocation failure
    }
    
    // Align to cache line boundary
    cache_padded_int_t* aligned_ptr = (cache_padded_int_t*)align_to_cache_line(raw_ptr);
    
    // Initialize the value
    aligned_ptr->value = value;
    
    // Clear padding to ensure clean memory
    memset(aligned_ptr->padding, 0, sizeof(aligned_ptr->padding));
    
    // Store the original pointer in the first sizeof(void*) bytes of padding for later free()
    // We ensure we have enough padding space since cache lines are at least 64 bytes
    // and we only use 4 bytes for the int32_t value
    memcpy(aligned_ptr->padding, &raw_ptr, sizeof(void*));
    
    return (int64_t)aligned_ptr;
}

// Get value from cache-padded integer
MOONBIT_FFI_EXPORT int32_t moonbit_cache_padded_get_int(int64_t ptr) {
    if (ptr == 0) {
        return 0; // Handle null pointer
    }
    
    cache_padded_int_t* cache_padded = (cache_padded_int_t*)ptr;
    return cache_padded->value;
}

// Set value in cache-padded integer
MOONBIT_FFI_EXPORT void moonbit_cache_padded_set_int(int64_t ptr, int32_t value) {
    if (ptr == 0) {
        return; // Handle null pointer
    }
    
    cache_padded_int_t* cache_padded = (cache_padded_int_t*)ptr;
    cache_padded->value = value;
}

// Destroy cache-padded integer
MOONBIT_FFI_EXPORT void moonbit_cache_padded_destroy(int64_t ptr) {
    if (ptr == 0) {
        return; // Handle null pointer
    }
    
    cache_padded_int_t* cache_padded = (cache_padded_int_t*)ptr;
    
    // Retrieve the original pointer from the padding area
    void* raw_ptr;
    memcpy(&raw_ptr, cache_padded->padding, sizeof(void*));
    
    // Free the original allocated memory
    free(raw_ptr);
}

// Get cache line size
MOONBIT_FFI_EXPORT int32_t moonbit_cache_padded_get_cache_line_size(void) {
    return CACHE_LINE_SIZE;
}