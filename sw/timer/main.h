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
#define TIMER_BASE (PERIPH_BASE + 0x3000UL)

#define UART0 ((UART_TypeDef *)UART0_BASE)
#define GPIOA ((GPIO_TypeDef *)GPIOA_BASE)
#define GPIOB ((GPIO_TypeDef *)GPIOB_BASE)
#define TIMER ((TIMER_TypeDef *)TIMER_BASE)

/*
0x000 CTRL R/W 0x00 Control register (bit[3:0])
                    [3] Receive interrupt enable
                    [2] Transmit interrupt enable
                    [1] Receive enable
                    [0] Transmit enable
0x004 STAT R/W 0x00 Status register (bit[3:0])
                    [3] Receive overrun error, write 1 to clear
                    [2] Transmit overrun error, write 1 to clear
                    [1] Receive buffer full
                    [0] Transmit buffer full
0x008 TXD R/W 0x00  Write : Transmit data register
                    Read : Transmit buffer full (bit[0])
0x00C RXD RO 0x00   Received data register (bit[7:0])
0x010 BAUDDIV R/W 0x00  Baud rate divider (bit[19:0])
                        (Minimum value is 32)
0x014 INTSTATE R/Wc 0x00    Interrupt status
                            [1] – TX interrupt, write 1 to clear
                            [0] – RX interrupt, write 1 to clea
*/

typedef struct
{
    __IO uint32_t CTRL;
    __IO uint32_t STAT;
    __IO uint32_t TXD;
    __I uint32_t RXD;
    __IO uint32_t BAUDDIV;
    __IO uint32_t INTSTATE;
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

/*
0x000 CTRL R/W 0x00         Control register
                            [3] IntrEN – Interrupt output enable
                            [2] ExtCLKSel – External Clock Select
                            [1] ExtENSel – External Enable Select
                            [0] Enable – Counter Enable
0x004 CurrVal R/W 0x00      Current Value
0x008 Reload R/W 0x00       Reload value
0x00C INTSTATE R/Wc 0x00    Bit 0 – Interrupt status, write 1 to clear
*/

typedef struct
{
    __IO uint32_t CTRL;
    __IO uint32_t CURRVAL;
    __IO uint32_t RELOAD;
    __IO uint32_t INTSTATE;
} TIMER_TypeDef;

#endif