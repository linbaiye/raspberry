#include <type.h>

#define va_start(v, f) __builtin_va_start(v, f);
#define va_end(v)       __builtin_va_end(v);
#define va_arg(v, a)   __builtin_va_arg(v, a);
typedef __builtin_va_list va_list;
extern void print_string(char *);
extern void panic(void);

#define __u32_div(dived, divor, result, remainder) __asm (\
    "clz r0, %2\n"\
    "lsl %3, r0\n"\
    "ldr r1, =0\n"\
    "ldr r2, =0\n"\
    "1:\n"\
    "cmp %3, %2\n"\
    "subls %2, %3\n"\
    "addls r1, #1\n"\
    "add r2, #1\n"\
    "cmp r2, r0\n"\
    "bgt 2f\n"\
    "lsl %2, #1\n"\
    "lsl r1, #1\n"\
    "b 1b\n"\
    "2:\n"\
    "mov %0, r1\n"\
    "lsr %2, r0\n"\
    "mov %1, %2\n"\
    : "=r"(result), "=r"(remainder)\
    : "r"(dived),"r"(divor)\
    : "r0", "r1", "r2", "memory"\
    )
    

#define ___u32_div(dived, divor, res, rem) __asm __volatile__(\
        "clz r2, %3\n"\
        "clz r3, %2\n"\
        "subs r2, r3\n"\
        "lsl r3, %3, r2\n"\
        "mov %3, %2\n"\
        "mov %2, #0\n"\
        "blt done\n"\
        "loop:\n"\
        "cmp %3, r3\n"\
        "blt repeat\n"\
        "add %2, %2, #1\n"\
        "subs %3, r3\n"\
        "lsleq %2, r2\n"\
        "beq done\n"\
        "repeat:\n"\
        "subs r2, #1\n"\
        "lsrge r3, #1\n"\
        "lslge %2, #1\n"\
        "bge loop\n"\
        "done:\n"\
        "mov %0, %2\n"\
        "mov %1, %3\n"\
        : "=r"(res), "=r"(rem)\
        : "r"(dived), "r"(divor)\
        : "r2", "r3"\
        )



int u32_div(u32_t dived, u32_t divor, u32_t *result, u32_t *remainder)
{
    u32_t _result, _remainder;
    if (divor == 0) {
        return 0xffffffff;
    }

    if (dived < divor) {
        *result = 0;
        *remainder = dived;
    } else {
        //*remainder = dived % divor;
        ___u32_div(dived, divor, _result, _remainder);
        *result = _result;
        *remainder = _remainder;
    }
    return 0;
}

#define fmt_digit(b, d, base) fmt_digit##base(b, d)

static int fmt_digit16(char **buf, unsigned int num)
{
    uint32_t i = 8, r = 0, mask = 0xf0000000, shift = 28;
    char **b = buf;
    while (i--) {
        r = (num & mask) >> shift;
        if (r < 10) {
            **b = r + '0';
        } else {
            **b = (r - 10) + 'a';
        }
        (*b)++;
        shift -= 4;
        mask >>= 4;
    }
    return 0;
}

static int fmt_digit2(char **buf, uint32_t num)
{
    uint32_t i = 32, mask = 0x80000000;
    char **b = buf;
    while (i--) {
        **b = '0' + (!!(num & mask));
        (*b)++;
        mask = (mask >> 1) & (~mask);
    }
    return 0;
}

static int fmt_digit10(char **buf, uint32_t num)
{
    uint32_t r = 0, c = num, t;
    int k = 0;
    char **b = buf, temp[30];
    if (c == 0) {
        temp[k++] = '0';
    } else {
        while (c > 0) {
            u32_div(c, 10, &t, &r);
            temp[k++] = r + '0';
            c = t;
        }
    }
    k--;
    while (k >= 0) {
        **b = temp[k--];
        (*b)++;
    }
    return 0;
}

static int fmt_string(char **d, const char *s)
{
    while (*s) {
        **d = *s++;
        (*d)++;
    }
    return 0;
}

int vsprintf(const char *fmt, va_list args, char *buffer)
{
    const char *p = fmt, *p_arg;
    char *b = buffer;
    uint32_t ui = 0;
    while (*p) {
        if (*p == '%') {
            switch (*(++p)) {
            case 'c':
            *(b++) =  (char)va_arg (args, int);
            break;
            case 'd':
            ui = va_arg (args, uint32_t);
            if (ui & 0x80000000) {
                ui = ~ui + 1;
                *(b++) = '-';
            }
            fmt_digit(&b, ui, 10);
            break;
            case 'x':
            case 'X':
            ui = va_arg (args, uint32_t);
            fmt_digit(&b, ui, 16);
            break;
            case 'u':
            ui = va_arg (args, uint32_t);
            fmt_digit(&b, ui, 10);
            break;
            case 'b':
            ui = va_arg (args, uint32_t);
            fmt_digit(&b, ui, 2);
            break;
            case 's':
            p_arg = va_arg (args, char *);
            fmt_string(&b, p_arg);
            break;
            case '%':
            *(b++) = '%';
            break;
            default:
            break;
            }
            p++;
        } else {
            *(b++) = *(p++);
        }
    }
    *b = 0;
    return 0;
}

int printf(const char *fmt, ...)
{
    va_list ap;
    char buf[1024];
    va_start(ap, fmt);
    vsprintf(fmt, ap, buf);
    print_string(buf);
    return 0;
}

int strcpy(char *dst, const char *src, int size)
{
    int i;
    for (i = 0; i < size; i++) {
        dst[i] = src[i];
        if (dst[i] == 0) {
            break;
        }
    }
    return i;
}

void test(void)
{
    uint32_t dd = 0x1c000000, dr = 10, res = 0, rem = 0;
    u32_div(dd, dr, &res, &rem);
//int u32_div(u32_t dived, u32_t divor, u32_t *result, u32_t *remainder)

    printf("res = %d, rem = %d\n", res, rem);
}


