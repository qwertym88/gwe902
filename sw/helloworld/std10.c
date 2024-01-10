#include "std10.h"

void uart_init()
{
    // in this case, pclk=hclk/4=sysclk/4=clk50m/5/4=2.5mHz
    // if baud rate is 9600, bauddiv should be around 2.5m/9600=260
    // bauddiv in range [260-5, 260+5] is also ok for this example
    UART0->BAUDDIV = 260;
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
    while (*str != '\0')
    {
        uart_putc(*str);
        str++;
    }
    // 未解之谜，以下代码是可以的
    // int cnt = 0;
    // while (*(str + cnt) != '\0')
    // {
    //     uart_putc(*(str + (cnt++)));
    // }
    // 但这个就不行，不知道为啥
    // char c = *(str + cnt);
    // while (c != '\0')
    // {
    //     uart_putc(c);
    //     c = *(str + (++cnt));
    // }
}