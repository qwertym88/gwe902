#ifndef __MAIN_H__
#define __MAIN_H__

#include <stdint.h>

#define __I volatile const /*!< defines 'read only' permissions      */
#define __O volatile       /*!< defines 'write only' permissions     */
#define __IO volatile      /*!< defines 'read / write' permissions   */

#define PERIPH_BASE (0x40000000UL)

#define UART0_BASE (PERIPH_BASE + 0x0000UL)
#define GPIOA_BASE (PERIPH_BASE + 0x1000UL)
#define GPIOB_BASE (PERIPH_BASE + 0x2000UL)

#define UART0 ((UART_TypeDef *)UART0_BASE)
#define GPIOA ((GPIO_TypeDef *)GPIOA_BASE)
#define GPIOB ((GPIO_TypeDef *)GPIOB_BASE)

/*
DATA 0x000 R/W 8 0x--   [7:0] Data value.
                        Read Received data.
                        Write Transmit data.
STATE 0x004 R/W 4 0x0   [3] RX buffer overrun, write 1 to clear.
                        [2] TX buffer overrun, write 1 to clear.
                        [1] RX buffer full, read-only.
                        [0] TX buffer full, read-only.
CTRL 0x008 R/W 7 0x00   [6] High-speed test mode for TX only.
                        [5] RX overrun interrupt enable.
                        [4] TX overrun interrupt enable.
                        [3] RX interrupt enable.
                        [2] TX interrupt enable.
                        [1] RX enable.
                        [0] TX enable.
INTSTATUS 0x00C R/W 4 0x0   [3] RX overrun interrupt. Write 1 to clear.
INTCLEAR                    [2] TX overrun interrupt. Write 1 to clear.
                            [1] RX interrupt. Write 1 to clear.
                            [0] TX interrupt. Write 1 to clear.
BAUDDIV 0x010 R/W 20 0x00000 [19:0] Baud rate divider. The minimum number is 16.
*/

typedef struct
{
    __IO uint32_t DATA;
    __IO uint32_t STATE;
    __IO uint32_t CTRL;
    __IO uint32_t INTSTATE;
    __IO uint32_t BAUDDIV;
} UART_TypeDef;

/*
0x000 DataIn RO -               Read back value of the IO port
0x004 DataOut R/W 0x00          Output data value
0x008 OutEnable R/W 0x00        Output Enable (Tri-state buffer enable)
0x00C IntEnable R/W 0x00        Interrupt Enable (for each bit, set to 1 to enable
                                  interrupt generation, or clear to 0 to disable the
                                  interrupt)
0x010 IntType R/W 0x00          Interrupt Type (for each bit, set to 1 for edge trigger
                                  interrupt, and clear to 0 for level trigger interrupt)
0x014 IntPolarity R/W 0x00      Interrupt Polarity (for each bit, clear to 0 for rising
                                  edge trigger or high-level trigger, and set to 1 for
                                  falling edge trigger or low-level trigger)
0x018 INTSTATE R/Wc 0x00        Bit[7:0] – Interrupt status, write 1 to clear
*/

typedef struct
{
    __I uint32_t DATAIN;
    __IO uint32_t DATAOUT;
    __IO uint32_t OE;
    __IO uint32_t INTENABLE;
    __IO uint32_t INTTYPE;
    __IO uint32_t INTPOLARITY;
    __IO uint32_t INTSTATE;
} GPIO_TypeDef;

#endif