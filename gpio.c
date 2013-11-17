
#include <memory_barrier.h>
#include <type.h>
#include <gpio.h>


static volatile gpio_regs_t * const gr = (gpio_regs_t*)(GPIO_BASE);

#define GPIO_GPFSEL0    0
#define GPIO_GPFSEL1    1
#define GPIO_GPFSEL2    2
#define GPIO_GPFSEL3    3
#define GPIO_GPFSEL4    4
#define GPIO_GPFSEL5    5
#define GPIO_GPSET0     7
#define GPIO_GPSET1     8
#define GPIO_GPCLR0     10
#define GPIO_GPCLR1     11
#define GPIO_GPLEV0     13
#define GPIO_GPLEV1     14
#define GPIO_GPEDS0     16
#define GPIO_GPEDS1     17
#define GPIO_GPREN0     19
#define GPIO_GPREN1     20
#define GPIO_GPFEN0     22
#define GPIO_GPFEN1     23
#define GPIO_GPHEN0     25
#define GPIO_GPHEN1     26
#define GPIO_GPLEN0     28
#define GPIO_GPLEN1     29
#define GPIO_GPAREN0    31
#define GPIO_GPAREN1    32
#define GPIO_GPAFEN0    34
#define GPIO_GPAFEN1    35
#define GPIO_GPPUD      37
#define GPIO_GPPUDCLK0  38
#define GPIO_GPPUDCLK1  39


void turn_OK_LED()
{
    gr->gpfsel[1] |= (1<<18); 
    gr->gpclr[0] = (1<<16); 
    dmb();
}

#define delay() __asm__ __volatile__ (\
        "ldr r1, =2000000\n"\
        "1:\n"\
        "sub r1, #1\n"\
        "cmp r1, #0\n"\
        "bne 1b\n"\
        :::"r1"\
        )


void blink_OK_LED()
{
    gr->gpfsel[1] |= (1<<18); 
    while (1) {
        delay();
        gr->gpclr[0] = (1<<16); 
        delay();
        gr->gpset[0] = (1<<16);
    }
}

void set_gpio_fn(int pnr, int fnr)
{
    int offset;
    uint32_t val;  
    int item;
    offset = pnr / 10;
    item = pnr % 10;
    val = gr->gpfsel[offset];  // Read in the original register value.
    val &= ~(0x7 << (item ));
    val &= ~(0x7 << (item * 3));
    val |= ((fnr & 0x7) << (item * 3));
    val |= ((fnr & 0x7) << (item ));
    gr->gpfsel[offset] = val;
    dmb();
}
