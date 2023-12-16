#include "std10.h"

void uart_init()
{
    GPIOA->INTENABLE = 0;
    GPIOB->INTENABLE = 0;
    *((uint32_t *)TIMER0_BASE) = 1;
    UART0->BAUDDIV = bauddiv;
    UART0->CTRL = 0b0001; // tx rx enable, interrupt disable
    GPIOA->OE = 1;
    GPIOA->DATAOUT = 0;
}

unsigned char uart_putc(unsigned char c)
{
    while (UART0->STATE & 1) // wait if TX FIFO full
        ;
    UART0->DATA = c;
    return c;
}

unsigned char uart_getc(void)
{
    while ((UART0->STATE & 2) == 0) // wait until RX FIFO full
        ;
    return (UART0->DATA);
}

void println(const char *str)
{
    int cnt = 0;
    char c = *(str + cnt);
    while (c != '\0')
    {
        uart_putc(c);
        cnt++;
        c = *(str + cnt);
    }
}