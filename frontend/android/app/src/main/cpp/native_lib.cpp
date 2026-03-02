#include <stdint.h>

//Export function visibility for Android/Linux so Flutter can access it
#define FFI_EXPORT __attribute__((visibility("default"))) __attribute__((used))

extern "C" {
    //Simple test function to validate native library connection
    FFI_EXPORT int test_connection() {
        return 42;
    }
}