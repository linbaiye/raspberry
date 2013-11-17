
#include <type.h>
#include <init.h>
#include <memory_barrier.h>

#define TIMER_BASE ((uint32_t)0x2000b400)

typedef struct BCM2835_ARM_TIMER_REGS {
    uint32_t load;
    uint32_t value;
    uint32_t cntl;
    uint32_t clear;
    uint32_t raw;
    uint32_t masked;
    uint32_t reload;
    uint32_t prescale;
    uint32_t cnt;
}ARM_TIMER_REGS;

static volatile ARM_TIMER_REGS * const tr = (ARM_TIMER_REGS *)(TIMER_BASE);

extern int printf(const char *,...);


/* Timer is running at speed of 1MHz. */
static void init_arm_timer()
{
    tr->cntl = 0x3e0000;
    tr->load = 1000-1;
    tr->reload = 1000-1;
    tr->prescale = 0xf9;
    tr->clear = 0;
    tr->cntl = 0x3e00a2;
    dmb();
}

static void __init init_sys_timer()
{
    ;
}


int init_timer()
{
    init_arm_timer();
//   init_sys_timer();
//
    return 0;
}
