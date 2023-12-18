#ifndef __UART_H__
#define __UART_H__

#include "main.h"

// in this case, pclk=hclk/4=sysclk/4=clk27m/16=1.6875mHz
// if baud rate is 9600, bauddiv should be around 1.6875m/9600=175
// bauddiv in range [175-5, 175+5] is also ok for this example
#define bauddiv 175

void uart_init();
unsigned char uart_putc(unsigned char c);
unsigned char uart_getc(void);
void println(const char *str);

#endif