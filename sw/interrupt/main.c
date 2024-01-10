#include "main.h"
#include "itconfig.h"

uint8_t led_status = 255;
uint8_t timer_loop = 1; // 模拟中断嵌套，计时器中断里面的死循环
uint8_t txbuffer[128];
uint32_t txsize;
uint8_t *rxbuffer;

// ms delay base on systick
void delay(uint64_t ms)
{
    uint64_t target = getSystick() + ms * 10000;
    while (getSystick() < target)
        ;
}

// ms timer
void systickTimer(uint64_t delay)
{
    uint64_t target = getSystick() + delay * 10000; // 6.75mHz
    *(uint64_t *)MTIMECMP = target;
    enableInt(SYSTICK_TIMER_INT_ID, 0, PRIORITY_LOW);
}

// gpio init
void gpioInit(void)
{
    GPIOA->OE = 0b11111111; // 八个led
    GPIOA->DATAOUT = led_status;
    GPIOA->INTENABLE = 0; // 两个按钮

    GPIOB->OE = 0;
    GPIOB->INTENABLE = 0b00001111; // 四个按键
    GPIOB->INTTYPE = 0b00001111;
    GPIOB->INTPOLARITY = 0b00001111; // 下降沿触发
    GPIOB->INTSTATE = 0b11111111;

    enableInt(GPIOB_COMB_INT_ID, 1, PRIORITY_HIGH); // gpio发送给clint的中断信号为上升沿
}

void uartInit()
{
    UART0->BAUDDIV = 260; // 9600
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
    systickTimer(10000);
    while (1)
    {
        for (int i = 0; i < 8; i++)
        {
            GPIOA->DATAOUT = ~(1 << i);
            delay(1000);
        }
    }
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

    while (timer_loop == 1)
        ;
}

void GPIOB_IRQHandler(void)
{
    int i;
    uint8_t port = 0;
    delay(100); // 按键去抖
    for (i = 0; i < 8; i++)
    {
        if ((GPIOB->INTSTATE & (1 << i)) != 0)
        {
            GPIOB->INTSTATE = 0b11111111; // 重置中断状态，应该不太可能两个端口同时触发吧
            port = i;                     // 具体是哪个触发的
            break;
        }
    }
    for (i = 0; i < 4; i++)
    {
        led_status = ~led_status; // toggle led
        GPIOA->DATAOUT = led_status;
        delay(500);
    }
    timer_loop = 0;
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
