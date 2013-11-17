.global dmb
.section .text
.func
dmb:
stmfd sp!, {r1}
mov r1, #0
mcr p15, 0, r1, c7, c10, 4
ldmfd sp!, {r1}
mov pc, lr
.endfunc

