#include <stdlib.h>
#include <stdint.h>

#include <glib.h>

#define FEATURE_CHECK 0x80000000LU
#define SEQUENCE_START FEATURE_CHECK + 2LU
#define CONTINUE FEATURE_CHECK + 4LU

typedef union {
  uint32_t register_value;
  char bytes[4];
} CharRegister;

char* get_brand_string () {
  uint32_t check_result;

  asm (
    "movl %1, %%eax \n"
    "cpuid \n"
    "movl %%eax, %0 \n"
    : "=r" (check_result)
    : "i" (FEATURE_CHECK)
    : "eax"
  );

  if (check_result < CONTINUE)
    return NULL;

  char* ret = malloc (48);
  check_result = SEQUENCE_START;

  for (int i = 0; check_result <= CONTINUE; ({i += 4; check_result++;})) {
    CharRegister eax, ebx, ecx, edx;

    asm (
      "movl %4, %%eax \n"
      "cpuid \n"
      "movl %%eax, %0 \n"
      "movl %%ebx, %1 \n"
      "movl %%ecx, %2 \n"
      "movl %%edx, %3 \n"
      : "=r" (eax),
        "=r" (ebx),
        "=r" (ecx),
        "=r" (edx)
      : "r" (check_result)
      : "eax", "ebx", "ecx", "edx"
    );

    strncpy (&ret[i],      &eax.bytes, 4);
    strncpy (&ret[i += 4], &ebx.bytes, 4);
    strncpy (&ret[i += 4], &ecx.bytes, 4);
    strncpy (&ret[i += 4], &edx.bytes, 4);
  }

  char* real_ret = g_strdup (ret);
  g_strstrip (real_ret);
  free (ret);
  return real_ret;
}
