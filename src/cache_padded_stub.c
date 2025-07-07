#include <stdlib.h>
#include <stdint.h>
#include <stdbool.h>
#include <string.h>

// Cache line size constants
#define CACHE_LINE_SIZE 64
#define CACHE_LINE_MASK (CACHE_LINE_SIZE - 1)

// Structure for cache-padded integer
typedef struct {
    int value;
    char padding[CACHE_LINE_SIZE - sizeof(int)];
} cache_padded_int_t;

// Align pointer to cache line boundary
static void* align_to_cache_line(void* ptr) {
    uintptr_t addr = (uintptr_t)ptr;
    uintptr_t aligned = (addr + CACHE_LINE_MASK) & ~CACHE_LINE_MASK;
    return (void*)aligned;
}

// Create a new cache-padded integer
int64_t moonbit_cache_padded_new_int(int value) {
    // Allocate extra space to ensure we can align to cache line
    void* raw_ptr = malloc(sizeof(cache_padded_int_t) + CACHE_LINE_SIZE);
    if (!raw_ptr) {
        return 0; // Return null pointer on allocation failure
    }
    
    // Align to cache line boundary
    cache_padded_int_t* aligned_ptr = (cache_padded_int_t*)align_to_cache_line(raw_ptr);
    
    // Initialize the value
    aligned_ptr->value = value;
    
    // Store the original pointer in the padding area for later free()
    // This is a bit hacky but works for this simple implementation
    *((void**)&aligned_ptr->padding[0]) = raw_ptr;
    
    return (int64_t)aligned_ptr;
}

// Get value from cache-padded integer
int moonbit_cache_padded_get_int(int64_t ptr) {
    if (ptr == 0) {
        return 0; // Handle null pointer
    }
    
    cache_padded_int_t* cache_padded = (cache_padded_int_t*)ptr;
    return cache_padded->value;
}

// Set value in cache-padded integer
void moonbit_cache_padded_set_int(int64_t ptr, int value) {
    if (ptr == 0) {
        return; // Handle null pointer
    }
    
    cache_padded_int_t* cache_padded = (cache_padded_int_t*)ptr;
    cache_padded->value = value;
}

// Destroy cache-padded integer
void moonbit_cache_padded_destroy(int64_t ptr) {
    if (ptr == 0) {
        return; // Handle null pointer
    }
    
    cache_padded_int_t* cache_padded = (cache_padded_int_t*)ptr;
    
    // Retrieve the original pointer from the padding area
    void* raw_ptr = *((void**)&cache_padded->padding[0]);
    
    // Free the original allocated memory
    free(raw_ptr);
}

// Get cache line size
int moonbit_cache_padded_get_cache_line_size(void) {
    return CACHE_LINE_SIZE;
}