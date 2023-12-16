#ifndef __UART_H__
#define __UART_H__

#include "main.h"

// in this case, pclk=hclk=sysclk=clk27m/4=6.75mHz
// if set baud rate to 9600, bauddiv=6.75m/9600=703.125
#define bauddiv 703

void uart_init();
unsigned char uart_putc(unsigned char c);
unsigned char uart_getc(void);
void println(const char *str);

#endif