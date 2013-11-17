#ifndef _ARM_H_
#define _ARM_H_
#define ARM_MODE_USR 0x10
#define ARM_MODE_FIQ 0x11
#define ARM_MODE_IRQ 0x12
#define ARM_MODE_SVC 0x13
#define ARM_MODE_ABT 0x17
#define ARM_MODE_UND 0x1B
#define ARM_MODE_SYS 0x1F
#define SVC_STACK 0x100000
#define FIQ_STACK 0x2000
#define IRQ_STACK 0x4000
#define ARM_I_BIT 0x80
#define ARM_F_BIT 0x40
#endif
