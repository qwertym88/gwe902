#ifndef __UART_H__
#define __UART_H__

#include "main.h"

void uart_init();
unsigned char uart_putc(unsigned char c);
unsigned char uart_getc(void);
void println(const char *str);

#endif