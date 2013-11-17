#ifndef _GPIO_H_
#define _GPIO_H_
#ifndef __ASSEMBLY__
void set_gpio_fn(int pnr, int fnr);
typedef struct gpio_regs {
    uint32_t gpfsel[6];
    uint32_t reserved0;
    uint32_t gpset[2];
    uint32_t reserved1;
    uint32_t gpclr[2];
    uint32_t reserved2;
    uint32_t gplev[2];
    uint32_t reserved3;
    uint32_t gpeds[2];
    uint32_t reserved4;
    uint32_t gpren[2];
    uint32_t reserved5;
    uint32_t gpfen[2];
    uint32_t reserved6;
    uint32_t gphin[2];
    uint32_t reserved7;
    uint32_t gplen[2];
    uint32_t reserved8;
    uint32_t gparen[2];
    uint32_t reserved9;
    uint32_t gpafen[2];
    uint32_t reserveda;
    uint32_t gppud;
    uint32_t gppudclk[2];
}gpio_regs_t;
#endif
#define GPIO_BASE ((uint32_t)0x20200000)
#endif
