#include "main.h"

const uint32_t delay = 675000;
uint32_t cnt;

void gpioInit()
{
    GPIOA->DATAOUT = 0;
    GPIOA->OE = 0b11111111;
    GPIOA->INTENABLE = 0;
    GPIOB->DATAOUT = 0;
    GPIOB->OE = 0;
    GPIOB->INTENABLE = 0;
}

int main()
{
    gpioInit();
    while (1)
    {
        for (int i = 0; i < 8; i++)
        {
            GPIOA->DATAOUT = ~(1 << i);
            cnt = delay;
            while (cnt--)
                ;
        }
    }
    return 0;
}
