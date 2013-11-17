# Makefile - build script */
#  
#  # build environment
PREFIX ?= /usr
ARMGNU ?= $(PREFIX)/bin/arm-none-eabi
 
# source files
SOURCES_ASM := $(wildcard *.S)
SOURCES_C   := $(wildcard *.c)
#  
#  # object files
OBJS        := $(patsubst %.S,%.o,$(SOURCES_ASM))
OBJS        += $(patsubst %.c,%.o,$(SOURCES_C))
 
# Build flags
DEPENDFLAGS := -MD -MP
INCLUDES    := -I include
BASEFLAGS   :=  -fpic -pedantic -pedantic-errors -nostdlib -nostdinc
BASEFLAGS   += -nostartfiles -ffreestanding -nodefaultlibs
BASEFLAGS   += -fno-builtin -mcpu=arm1176jzf-s -marm -Wall
BASEFLAGS += -O2

#WARNFLAGS   := -Wall -Wextra -Wshadow -Wcast-align -Wwrite-strings
#WARNFLAGS   += -Wredundant-decls -Winline
#WARNFLAGS   += -Wno-attributes -Wno-deprecated-declarations
#WARNFLAGS   += -Wno-div-by-zero -Wno-endif-labels -Wfloat-equal
#WARNFLAGS   += -Wformat=2 -Wno-format-extra-args -Winit-self
#WARNFLAGS   += -Winvalid-pch -Wmissing-format-attribute
#WARNFLAGS   += -Wmissing-include-dirs -Wno-multichar
#WARNFLAGS   += -Wredundant-decls -Wshadow
#WARNFLAGS   += -Wno-sign-compare -Wswitch -Wsystem-headers -Wundef
#WARNFLAGS   += -Wno-pragmas -Wno-unused-but-set-parameter
#WARNFLAGS   += -Wno-unused-but-set-variable -Wno-unused-result
#WARNFLAGS   += -Wwrite-strings -Wdisabled-optimization -Wpointer-arith
#WARNFLAGS   += -Werror
INCLUDE := -I include
#ASFLAG_PREFIX := -Wa,
#ASFLAGS       := $(addprefix $(ASFLAG_PREFIX),$(ASFLAGS))
#ASFLAGS       += $(INCLUDE) $(DEPENDFLAGS) -c
#ASFLAGS     := $(INCLUDES) $(DEPENDFLAGS) -D__ASSEMBLY__
ASFLAGS :=  -c -I ./include -D__ASSEMBLY__ -mcpu=arm1176jzf-s -nostdinc
CFLAGS      := $(INCLUDES) $(DEPENDFLAGS) $(BASEFLAGS) $(WARNFLAGS)
CFLAGS      += -std=gnu99
#  # build rules
all: kernel.img
 
include $(wildcard *.d)
 
kernel.elf: $(OBJS) link-arm-eabi.ld
	$(ARMGNU)-ld $(OBJS) -Map kernel.map -Tlink-arm-eabi.ld -o $@
 
kernel.img: kernel.elf
	$(ARMGNU)-objcopy kernel.elf -O binary kernel.img
 
clean:
	$(RM) -f $(OBJS) kernel.elf kernel.img kernel.map
 
dist-clean: clean
	$(RM) -f *.d
 
%.o: %.c Makefile
	$(ARMGNU)-gcc $(CFLAGS) -c $< -o $@
%.o: %.S Makefile
	$(ARMGNU)-gcc $(DEPENDFLAGS) $(ASFLAGS) -c $< -o $@
#	$(ARMGNU)-gcc $(DEPENDFLAGS) $(ASFLAGS) -c $< -o $@
