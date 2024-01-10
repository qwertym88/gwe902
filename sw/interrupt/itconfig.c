#include "itconfig.h"

void (*g_irqvector[64])(void);

extern void Default_IRQHandler(void);
extern void CORET_IRQHandler(void);
extern void GPIOB_IRQHandler(void);
extern void UART0_RX_IRQHandler(void);
extern void UART0_TX_IRQHandler(void);

// 初始化中断向量表每个id对应的函数入口。
void irq_vectors_init(void)
{
    for (int i = 0; i < 64; i++)
    {
        g_irqvector[i] = Default_IRQHandler;
    }

    g_irqvector[SYSTICK_TIMER_INT_ID] = CORET_IRQHandler;
    g_irqvector[UART0_RX_INT_ID] = UART0_RX_IRQHandler;
    g_irqvector[UART0_TX_INT_ID] = UART0_TX_IRQHandler;
    g_irqvector[GPIOB_COMB_INT_ID] = GPIOB_IRQHandler;
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
    INTCONFIG_TypeDef config;
    // config.IP = 1; // 电平模式下实际只读，边缘中断能自动清除
    config.IE = 1;
    config.ATTR = (trigger << 1) + 1;
    config.CTRL = pri;
    *(INTCONFIG_TypeDef *)CLICINT_I(id) = config;
}

void disableInt(uint8_t id)
{
    INTCONFIG_TypeDef config;
    config.IP = 0;
    config.IE = 0;
    *(INTCONFIG_TypeDef *)CLICINT_I(id) = config;
}

void initInt(void)
{
    *(uint32_t *)CLICCFG = 0x7;  // nlbits=3
    *(uint32_t *)MINTTHRESH = 0; // threshold=0
    irq_vectors_init();
}