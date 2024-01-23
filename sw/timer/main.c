#include "main.h"

#define CLIC_BASE 0xE0800000
#define CLICCFG (CLIC_BASE + 0x0000UL)
#define MINTTHRESH (CLIC_BASE + 0x0008UL)
#define CLICINT_I(i) ((INTCONFIG_TypeDef *)(0xE0801000 + 4 * i))

typedef struct
{
    __IO uint8_t IP; // R/Wc
    __IO uint8_t IE;
    __IO uint8_t ATTR;
    __IO uint8_t CTRL;
} INTCONFIG_TypeDef;

void (*g_irqvector[64])(void);

uint8_t led_status = 255;

void TIMER_IRQHandler(void)
{
    // clear interrupt
    TIMER->INTSTATE = 1;
    led_status = ~led_status;
    GPIOA->DATAOUT = led_status;
}

void initInt(void)
{
    *(uint32_t *)CLICCFG = 0x7;  // nlbits=3
    *(uint32_t *)MINTTHRESH = 0; // threshold=0
    g_irqvector[36] = TIMER_IRQHandler;
}

void initGPIO(void)
{
    GPIOA->OE = 0b11111111;
    GPIOA->DATAOUT = led_status;
}

void timer(uint64_t delay)
{
    INTCONFIG_TypeDef config;
    // timer
    TIMER->RELOAD = delay * 2500;
    TIMER->CURRVAL = delay * 2500;
    TIMER->CTRL = 0b1001;
    TIMER->INTSTATE = 1; // 注意要重置状态
    // clic
    config.IE = 1;
    config.ATTR = 3; // 上升沿
    config.CTRL = 0xc0;
    *(INTCONFIG_TypeDef *)CLICINT_I(36) = config;
}

int main()
{
    initInt();
    initGPIO();
    timer(1000); // 1s
    while (1)
        ;
    return 0;
}
