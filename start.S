

#include <arm.h>
#include <gpio.h>


.global panic
.global start
.global print_string
.global disable_cpu_irq
.global draw_char


.equ SCREEN_WIDTH, 1024
.equ SCREEN_HEIGHT, 768

.equ MAIL0_BASE,  0x2000b880
.equ MAIL0_READ,  MAIL0_BASE
.equ MAIL0_STATUS,(0x18 + MAIL0_BASE)
.equ MAIL0_PEAK,  (MAIL0_BASE + 0x10)
.equ MAIL0_WRITE, (MAIL0_BASE + 0x20)
.equ MAIL0_FULL, 0x80000000
.equ MAIL0_EMPTY, 0x40000000
.equ VC_MAPMEM_BASE, 0x40000000
.equ FB_CHANNEL, 1          //Framebuffer's channel number of mailbox.
.equ COLOR, 0x0000ffff     //White colour.

.section .text.init
start:
ldr pc,reset_handler        ;@  Processor Reset handler         -- we will have to force this on the raspi!
    ;@ Because this is the first instruction executed, of cause it causes an immediate branch into reset!
    
    ldr pc,undefined_handler    ;@  Undefined instruction handler   -- processors that don't have thumb can emulate thumb!
    ldr pc,swi_handler          ;@  Software interrupt / TRAP (SVC) -- system SVC handler for switching to kernel mode.
    ldr pc,prefetch_handler     ;@  Prefetch/abort handler.
    ldr pc,data_handler         ;@  Data abort handler/
    ldr pc,unused_handler       ;@  -- Historical from 26-bit addressing ARMs -- was invalid address handler.
    ldr pc,irq_handler          ;@  IRQ handler
    ldr pc,fiq_handler          ;@  Fast interrupt handler.

    ;@ Here we create an exception address table! This means that reset/hang/irq can be absolute addresses
reset_handler:      .word reset
undefined_handler:  .word panic
swi_handler:        .word panic
prefetch_handler:   .word panic
data_handler:       .word panic
unused_handler:     .word 0
irq_handler:        .word panic
fiq_handler:        .word panic

reset:
    
    ;@  In the reset handler, we need to copy our interrupt vector table to 0x0000, its currently at 0x8000

    ldr r0, =switch_addr            ;@Switch to ARM state if we entered with Thumb state.
    bx r0
    switch_addr:
    .int switch_to_arm
    switch_to_arm:

    mov r0,#0x8000                              ;@ Store the source pointer
    mov r1,#0x0000                              ;@ Store the destination pointer.


    ;@  Here we copy the branching instructions
    ldmia r0!,{r2,r3,r4,r5,r6,r7,r8,r9}         ;@ Load multiple values from indexed address.       ; Auto-increment R0                                                                                             
    stmia r1!,{r2,r3,r4,r5,r6,r7,r8,r9}         ;@ Store multiple values from the indexed address.  ; Auto-increment R1

    ;@  So the branches get the correct address we also need to copy our vector table!
    ldmia r0!,{r2,r3,r4,r5,r6,r7,r8,r9}         ;@ Load from 4*n of regs (8) as R0 is now incremented.
    stmia r1!,{r2,r3,r4,r5,r6,r7,r8,r9}         ;@ Store this extra set of data.


    ;@  Set up the various STACK pointers for different CPU modes
    ;@ (PSR_IRQ_MODE|PSR_FIQ_DIS|PSR_IRQ_DIS)


    cpsid aif, #ARM_MODE_IRQ
    mov sp,#IRQ_STACK

    cps #ARM_MODE_FIQ
    mov sp,#FIQ_STACK

    cps #ARM_MODE_SVC
    mov sp, #SVC_STACK
    bl init_timer
    bl init_ic
    bl blink_OK_LED
    bl enable_cpu_i
    1: b 1b


.section .text
panic:
bl disable_cpu_fia
bl blink_OK_LED
1: b 1b

enable_cpu_i:
cpsie i
mov pc, lr

disable_cpu_i:
cpsid i
mov pc, lr

disable_cpu_fia:
cpsid fia
mov pc, lr

enable_cpu_f:
cpsie f
mov pc, lr

disable_cpu_f:
cpsid f
mov pc, lr



//ldr r0, =cpu_fmt
//ldr pc, =8

//b change_mode


//mov 


get_arm_mem:
stmfd sp!, {r0-r2, lr}
ldr r1, =get_vcmem_msg
ldr r0, =8
bl send_mail
ldr r0, =8
bl recv_mail


and r2, r0, #0xf
teq r2, #8
bne panic 


ldr r1, =get_mem_msg
ldr r2, [r1, #20]
ldr r1, [r1, #24]
ldr r0, =mem_fmt
bl printf
ldmfd sp!, {r0-r2, lr}
mov pc, lr


get_vc_mem:
stmfd sp!, {r0-r2, lr}
ldr r1, =get_mem_msg
ldr r0, =8
bl send_mail
ldr r0, =8
bl recv_mail


and r2, r0, #0xf
teq r2, #8
bne panic 


ldr r1, =get_mem_msg
ldr r2, [r1, #20]
ldr r1, [r1, #24]
ldr r0, =mem_fmt
bl printf
ldmfd sp!, {r0-r2, lr}
mov pc, lr


get_board_model:
stmfd sp!, {r0-r2, lr}
ldr r1, =mb_buffer
ldr r0, =8

bl send_mail

ldr r0, =8
bl recv_mail


and r2, r0, #0xf
teq r2, #8
bne panic 


ldr r1, =mb_buffer
ldr r1, [r1, #4]
ldr r0, =mb_fmt
bl printf


ldr r1, =mb_buffer
ldr r1, [r1, #20]
ldr r0, =mb_fmt
bl printf

ldmfd sp!, {r0-r2, lr}
mov pc, lr




/* Initialize a frame buffer, ask GPU to alloc a frame buffer using mailbox so we can output things to screen. */

init_framebuffer:
stmfd sp!, {r0-r4, lr} 
ldr r1, =fb_info 
mov r0, #FB_CHANNEL
bl send_mail

mov r0, #FB_CHANNEL
bl recv_mail

and r2, r0, #0xf
teq r2, #FB_CHANNEL
bne panic 

/*and r0, #0xfffffff0
teq r0, #0
bne panic*/

ldr r1, =fb_pointor

ldr r3, =fb_info
ldr r4, [r3, #32]
str r4, [r1]

ldmfd sp!, {r0-r4, lr}
mov pc, lr




/* Receive a mail, we temproraly use only mailbox 0 which has ten channels from 0 to 9 and 7th is not used.
 * @r0: the mail chanel of mailbox 0.
 * @r0, the return value: the data from channel.
 * C signature: uint_32 receive_mail(uint_32 chanel)
 */
recv_mail:

stmfd sp!, {r3,r4, lr}

ldr r3, =MAIL0_STATUS

read_status2:
    ldr r4, [r3]
    tst r4, #MAIL0_EMPTY
    bne read_status2        //Repeat until the mailbox has something to read.
ldr r3, =MAIL0_READ

ldr r0, [r3]                //TODO:We may read data not from the expected channel, the low four bits of 
                            //the data incates the channel number which can be used to verify if we read correctly.
ldmfd sp!, {r3,r4, lr}
mov pc, lr





/* Send a mail, we temproraly use only mailbox 0 which has ten channels from 0 to 9 and 7th is not used.
 * @r0: the mail chanel of mailbox 0.
 * @r1: the data will be send.
 * C signature: void send_mail(uint_32 chanel, uint_32 data)
 */
send_mail:

stmfd sp!, {r0-r3, lr}

ldr r2, =MAIL0_STATUS

read_status1:
    ldr r3, [r2]
    tst r3, #MAIL0_FULL
    bne read_status1        /* The mailbox is full,retry again.*/

mov r2, r1
orr r2, r0                  //Combinate the data and channel into r5
ldr r3, =MAIL0_WRITE
str r2, [r3]
ldmfd sp!, {r0-r3, lr}
mov pc, lr


/* Draw a pixel at a specified coordinate.
 * @r1, x-coordinate.
 * @r2, y-coordinate.
 */
draw_pixel:
stmfd sp!, {r3,r4,r5,r6, lr}
ldr r3, =COLOR
ldr r4, =fb_pointor 
ldr r4, [r4]
ldr r5, =SCREEN_WIDTH
mla r6,r2,r5,r1
lsl r6, #1
strh r3, [r4, r6]
ldmfd sp!, {r3,r4,r5,r6, lr}
mov pc, lr

/* Draw a character starting with coordinates x,y.
 * @r0, character will be drawing
 * @r1, x-coordinate.
 * @r2, y-coordinate.
 */
draw_char:

stmfd sp!, {r0-r6,lr}

ldr r3, =font
add r3, r0, lsl #4                             //The address of monospace bitstream relates to the character.
mov r6, r1
ldrb r0, [r3]
ldr r5, =16
draw_col:
    mov r1, r6
    ldr r4, =8                                  //Each character occupies 16X8 pixels.
    ldrb r0, [r3]
    draw_row:
        tst r0, #1
        blne draw_pixel
        lsr r0, #1
        add r1, #1
        sub r4, #1
        teq r4, #0
        bne draw_row
    add r3, #1
    add r2, #1
    sub r5, #1
    teq r5, #0
    bne draw_col
ldmfd sp!, {r0-r6,lr}
mov pc, lr

/* Print a string,
 * @r0 address of the string is going to print.
 */
print_string:
stmfd sp!, {r0-r3,lr}
mov r3, r0
ldr r1, =coord_x
ldr r2, =coord_y

ldr r1, [r1]
ldr r2, [r2]

repeat_draw_char:
    ldrb r0, [r3]

    teq r0, #10
    beq line_feed

    teq r0, #0
    beq end 

    bl draw_char

    add r1, #8

    teq r1, #SCREEN_WIDTH
line_feed:
    moveq r1, #0
    addeq r2, #16       //Next line.
    teq r2, #SCREEN_HEIGHT
    moveq r2, #0        //Rotate to the first line.

    add r3, #1          //Move to next char.
    b repeat_draw_char

end:

ldr r3, =coord_x
str r1, [r3]
ldr r3, =coord_y
str r2, [r3]
ldmfd sp!, {r0-r3,lr}
mov pc, lr

.section .data
.align 5
msg:
.string "Loading......\n"

.align 2
fb_pointor:
.int 0
coord_x:
.int 0
coord_y:
.int 0

.align 4
font:
.incbin "font.bin"

.align 12
fb_info:
.int SCREEN_WIDTH
.int SCREEN_HEIGHT
.int 0
.int 0
.int 0                                  //Response:Number of bytes between each row of the frame buffer.
.int 16
.int 0
.int 0
.int 0                                  //Response:Address of buffer allocated by VC, Zero if request fails.
.int 0                                  //Response:Size of buffer.

.align 4
mb_buffer:
.int 7*4    //buffer size in bytes (including the header values, the end tag and padding)
.int 0      //Request code
.int 0x00000001    //Get firmware revision, tags start with.
.int 4      //value buffer size.
.int 0x0    //1bit indicator(0=req,1=res),31bits value length.
.int 0      //value buffer.
.int 0x0    //end tag

.align 4
get_mem_msg:
.int 8*4
.int 0
.int 0x00010005 //Get ARM memory.
.int 8          //buffer size.
.int 0x0        //
.int 0          //Base address.
.int 0          //Size in bytes.
.int 0x0        //end tag

.align 4
get_vcmem_msg:
.int 8*4
.int 0
.int 0x00010006 //Get VC memory.
.int 8          //buffer size.
.int 0x0        //
.int 0          //Base address.
.int 0          //Size in bytes.
.int 0x0        //end tag

mb_fmt:
.string "The response code is %x\n\0"
mb_fmtb:
.string "The response code is %b\n\0"
mem_fmt:
.string "The memory size is %d bytes, and start at %x\n\0"
vcmem_fmt:
.string "The VC memory size is %d bytes, and start at %x\n\0"
cpu_fmt:
.string "PSR's value is %x, PC's value is %x\n\0"
ch_fmt:
.string "address 0 :%x\n\0"
swi_msg:
.string "Return from swi!\n"

