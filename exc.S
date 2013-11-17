

.global init_exception_vector


.extern panic
.extern disable_cpu_irq
.extern c_fiq_handler


.section .text
vec_block:
ldr pc, reset_addr
ldr pc, ui_addr
ldr pc, swi_addr
ldr pc, pa_addr
ldr pc, da_addr
nop
ldr pc, irq_addr
ldr pc, fiq_addr


reset_addr: 
//.int reset_handler
.int hang
ui_addr:
.int hang
//.int ui_handler
swi_addr:
//.int swi_handler
.int hang
pa_addr:
.int hang
//.int pa_handler
da_addr: 
.int hang
//.int da_handler
.int 0
irq_addr:
.int hang
//.int irq_handler
fiq_addr:
.int hang
//.int fiq_handler



hang:
mov r0, #0xd3
msr cpsr_c, r0
mov sp, #0x8000
ldr r0, =0x20200000
mov r1, #1
lsl r1, #18
str r1, [r0, #4]
mov r1, #1
lsl r1, #16
str r1, [r0, #40]
1:
b 1b




reset_handler:
b panic
stmfd sp!,{r0-r3,lr}
ldr r0, [lr, #-4]
bic r0, r0, #0xff000000
mov r1, sp
mrs r2, spsr
stmfd sp!, {r2}


ldmfd sp!, {r2}
msr spsr, r2
ldmfd sp!, {r0-r3, pc}^

ui_handler:
b panic
stmfd sp!,{r0-r3,lr}
ldr r0, [lr, #-4]
bic r0, r0, #0xff000000
mov r1, sp
mrs r2, spsr
stmfd sp!, {r2}
ldr r0, =ui_msg
bl printf
ldmfd sp!, {r2}
msr spsr, r2
ldmfd sp!, {r0-r3, pc}^

swi_handler:
stmfd sp!,{r0-r3,lr}
//ldr r0, [lr, #-4]
//bic r0, r0, #0xff000000
//mov r1, sp
mrs r2, spsr
stmfd sp!, {r2}

ldr r1, =0x1
ldr r0, =swi_msg
bl printf

ldmfd sp!, {r2}
msr spsr, r2
ldmfd sp!, {r0-r3, pc}^


pa_handler:
b panic
stmfd sp!,{r0-r3,lr}
ldr r0, [lr, #-4]
bic r0, r0, #0xff000000
mov r1, sp
mrs r2, spsr
stmfd sp!, {r2}

ldr r0, =pa_msg
bl printf

ldmfd sp!, {r2}
msr spsr, r2
ldmfd sp!, {r0-r3, pc}^

da_handler:
b panic
stmfd sp!,{r0-r3,lr}
ldr r0, [lr, #-4]
bic r0, r0, #0xff000000
mov r1, sp
mrs r2, spsr
stmfd sp!, {r2}

ldr r0, =da_msg
bl printf

ldmfd sp!, {r2}
msr spsr, r2
ldmfd sp!, {r0-r3, pc}^

irq_handler:


b panic

stmfd sp!,{r0-r3,lr}
mrs r2, spsr
stmfd sp!, {r2}

ldr r0, =irq_msg
bl printf
b panic

ldmfd sp!, {r2}
msr spsr, r2
ldmfd sp!, {r0-r3, pc}^



fiq_handler:

b panic

stmfd sp!,{r0-r3,lr}
mrs r2, spsr
stmfd sp!, {r2}

ldr r0, =fiq_msg
bl printf

b panic
//bl c_fiq_handler


1:
b 1b

ldmfd sp!, {r2}
msr spsr, r2
ldmfd sp!, {r0-r3, pc}^


init_exception_vector:
stmfd sp!, {r0-r9,lr}
mov r8, #0
adr r9, vec_block
ldmia r9!, {r0-r7}
stmia r8!, {r0-r7}
ldmia r9!, {r0-r7}
stmia r8!, {r0-r7}
ldmfd sp!, {r0-r9,lr}
mov pc, lr

.section .rodata
.align 
reset_msg:
.string "Reset exception.\n"
fiq_msg:
.string "FIQ received\n"
swi_msg:
.string "SWI code is %x\n"
irq_msg:
.string "IRQ received\n"
ui_msg:
.string "Undefined instruction exception\n"
pa_msg:
.string "Prefetch Abort\n"
da_msg:
.string "Data Abort\n"
