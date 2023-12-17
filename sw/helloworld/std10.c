#include "std10.h"

void uart_init()
{
    UART0->BAUDDIV = bauddiv;
    UART0->CTRL = 0b0011; // tx rx enable, interrupt disable
}

unsigned char uart_putc(unsigned char c)
{
    while (UART0->STAT & 1) // wait if TX FIFO full
        ;
    UART0->TXD = c;
    return c;
}

unsigned char uart_getc(void)
{
    while ((UART0->STAT & 2) == 0) // wait until RX FIFO full
        ;
    return (UART0->RXD);
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