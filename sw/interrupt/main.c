#include "main.h"
#include "itconfig.h"

uint8_t led_status = 0;
uint8_t txbuffer[128];
uint32_t txsize;
uint8_t *rxbuffer;

// ms delay base on systick
void delay(uint64_t ms)
{
    uint64_t target = getSystick() + ms * 6750;
    while (getSystick() < target)
        ;
}

// ms timer
void systickTimer(uint64_t delay)
{
    uint64_t target = getSystick() + delay * 6750; // 6.75mHz
    *(uint64_t *)MTIMECMP = target;
    enableInt(SYSTICK_TIMER_INT_ID, 0, PRIORITY_LOW);
}

// gpio init
void gpioInit(void)
{
    led_status = 0;
    GPIOA->OE = 0b00001111; // 四个led
    GPIOA->DATAOUT = 0;
    GPIOA->INTTYPE = 0b00110000;
    GPIOA->INTPOLARITY = 0b00110000; // 常态上拉，故下降沿触发gpio中断
    GPIOA->INTSTATE = 0b11111111;
    GPIOA->INTENABLE = 0b00110000; // 两个按钮

    enableInt(GPIOA_COMB_INT_ID, 1, PRIORITY_HIGH); // gpio发送给clint的中断信号为上升沿
}

void uartInit()
{
    UART0->BAUDDIV = 175; // 9600
    UART0->CTRL = 0b1111; // tx rx interrupt enable

    enableInt(UART0_RX_INT_ID, 1, PRIORITY_NORM); // clint的中断信号为上升沿
    enableInt(UART0_TX_INT_ID, 1, PRIORITY_NORM);
}

void uartTransmit_IT(const uint8_t *pdata, uint32_t size)
{
    int i;
    for (i = 0; i < size; i++)
    {
        txbuffer[i] = pdata[i];
    }
    txsize = size;
    UART0->TXD = txbuffer[0]; // send first char
}

// readline
void uartRecieve_IT(uint8_t *pdata)
{
    rxbuffer = pdata;
}

// 读取size个字节后调用cplt callback
void uartRxCpltCallback(uint8_t *pdata, uint32_t size)
{
    uartTransmit_IT(pdata, size);
}

int main()
{
    initInt();
    uartInit();
    gpioInit();
    systickTimer(5000);
    while (1)
        ;
    return 0;
}

/////////////////////////// irq handlers /////////////////////////////////
// 自定义的中断处理函数，对应irq_vectors_init函数里注册的中断函数入口
// 这些函数名均在crt0.s def_irq_handler宏中声明为weak并指向Default_IRQHandler
// 这样设计的初衷是不需要修改irq_vectors_init、只重写需要的函数就行，不过代码看着乱了点
// Default_IRQHandler在crt0.s中，定义成一个死循环

void CORET_IRQHandler(void)
{
    disableInt(SYSTICK_TIMER_INT_ID);
    *(uint64_t *)MTIMECMP = 0xffffffffffffffff; // 注意要重置MTIMECMP，否则一直触发中断

    led_status ^= 1; // toggle led 1
    GPIOA->DATAOUT = led_status;
    delay(10000);    // 模拟中断嵌套，十秒内按下按钮灯灭掉
    led_status ^= 1; // toggle led 1
    GPIOA->DATAOUT = led_status;
}

void GPIOA_IRQHandler(void)
{
    int i;
    uint8_t port = 0;
    delay(100); // 按键去抖
    for (i = 0; i < 8; i++)
    {
        if ((GPIOA->INTSTATE & (1 << i)) != 0)
        {
            GPIOA->INTSTATE = 0b11111111; // 重置中断状态，应该不太可能两个端口同时触发吧
            port = i;
            break;
        }
    }
    led_status ^= 1; // toggle led 1
    GPIOA->DATAOUT = led_status;
}

void UART0_RX_IRQHandler(void)
{
    static uint32_t cnt = 0;
    rxbuffer[cnt++] = UART0->RXD;
    if (rxbuffer[cnt - 1] == ';')
    {
        uartRxCpltCallback(rxbuffer, cnt);
        cnt = 0;
    }
    UART0->INTSTATE |= 1;
}

void UART0_TX_IRQHandler(void)
{
    static uint32_t cnt = 1;
    if (cnt == txsize)
    {
        // tx clpt callback
        cnt = 1;
        return;
    }
    UART0->TXD = txbuffer[cnt++];
    UART0->INTSTATE |= 2;
}
