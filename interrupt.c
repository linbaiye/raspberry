



#include <type.h>
#include <memory_barrier.h>

#define INT_BASE ((uint32_t )0x2000b200)

typedef struct interrupt_controllor {
    uint32_t basic_pend;
    uint32_t pend1;
    uint32_t pend2;
    uint32_t fiq;
    uint32_t enable1;
    uint32_t enable2;
    uint32_t basic_enable;
    uint32_t disable1;
    uint32_t disable2;
    uint32_t basic_disable;
}interrupt_controllor_t;

static volatile interrupt_controllor_t * const ic = (interrupt_controllor_t *)(INT_BASE);

#define CLOCK_IRQ 64
#define CLOCK_FIQ (0x80+64)

extern int printf(const char *, ...);
extern void panic(void);

static void enable_fiq(uint32_t fiq)
{
    ic->fiq = fiq;
    dmb();
}



static void enable_irq(int irq)
{
    if (irq < 32) {
        ;
    } else if (irq < 64) {
        ;
    } else if (irq < 96) {
        irq -= 64;
        ic->basic_enable = 1 << irq;
    }
    dmb();
}



int init_ic()
{
   enable_irq(CLOCK_IRQ);
//    enable_fiq(CLOCK_FIQ);
    return 0;
}




