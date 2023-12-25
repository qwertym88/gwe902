#include "itconfig.h"

void (*g_irqvector[64])(void);

extern void Default_IRQHandler(void);
extern void CORET_IRQHandler(void);
void irq_vectors_init(void)
{
    int i;

    for (i = 0; i < 64; i++)
    {
        g_irqvector[i] = Default_IRQHandler;
    }

    g_irqvector[SYSTICK_TIMER_INT_ID] = CORET_IRQHandler;
}

void trap_c(uint32_t *regs)
{
    // int i;
    // uint32_t vec = 0;
    // vec = __get_MCAUSE() & 0x3FF;
    // printf("CPU Exception: NO.%d", vec);
    // printf("\n");
    // for (i = 0; i < 15; i++) {
    //     printf("x%d: %08x\t", i + 1, regs[i]);
    //     if ((i % 4) == 3) {
    //         printf("\n");
    //     }
    // }
    // printf("\n");
    // printf("mepc   : %08x\n", regs[15]);
    // printf("mstatus: %08x\n", regs[16]);

    while (1)
        ;
}

void setSoftRst(uint32_t value)
{
    *(uint32_t *)MSIP = value;
}

uint64_t getSystick(void)
{
    return *(uint64_t *)MTIME;
}

void enableInt(uint8_t id, uint8_t trigger, INTPRIORITY pri)
{
    INTCONFIG_TypeDef *config = CLICINT_I(id);
    // config->IP = 1;
    config->IE = 1;
    config->ATTR = (trigger << 1) + 1;
    config->CTRL = pri;
}

void disableInt(uint8_t id)
{
    INTCONFIG_TypeDef *config = CLICINT_I(id);
    // config->IP = 0;
    config->IE = 0;
}

void initInt(void)
{
    *(uint32_t *)CLICCFG = 0x7;  // nlbits=3
    *(uint32_t *)MINTTHRESH = 0; // threshold=0
    irq_vectors_init();
}