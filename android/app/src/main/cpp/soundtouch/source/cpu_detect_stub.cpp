#include "cpu_detect.h"

uint detectCPUextensions(void)
{
    // Return 0 for non-x86 platforms to disable MMX/SSE/etc optimizations
    return 0;
}

void disableExtensions(uint wDisableMask)
{
    // No-op on non-x86
}
