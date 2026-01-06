#ifndef SCENIC_KERNEL_H
#define SCENIC_KERNEL_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct sk_kernel sk_kernel;

enum sk_kernel_error {
    SK_KERNEL_OK = 0,
    SK_KERNEL_INVALID_ARGS = 1,
    SK_KERNEL_PAYLOAD_TOO_LARGE = 2,
    SK_KERNEL_CAPACITY_EXCEEDED = 3,
    SK_KERNEL_OUT_OF_MEMORY = 4
};

sk_kernel* sk_kernel_create(size_t max_bytes);
void sk_kernel_destroy(sk_kernel* kernel);

int sk_kernel_append_annotation(
    sk_kernel* kernel,
    const uint8_t* payload,
    size_t payload_len
);

const uint8_t* sk_kernel_event_bytes(
    const sk_kernel* kernel,
    size_t* out_len
);

#ifdef __cplusplus
}
#endif

#endif
