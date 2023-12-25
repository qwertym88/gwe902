#include "main.h"
#include "itconfig.h"

// ms timer
void setSysticTimerInt(uint64_t delay)
{
    // disableInt(SYSTICK_TIMER_INT_ID);
    uint64_t target = getSystick() + delay * 6750; // 6.75mHz
    *(uint64_t *)MTIMECMP = target;
    enableInt(SYSTICK_TIMER_INT_ID, 0, PRIORITY_NORM);
}

int main()
{
    initInt();
    setSysticTimerInt(5000);
    while (1)
        ;
    return 0;
}

void CORET_IRQHandler()
{
    disableInt(SYSTICK_TIMER_INT_ID);
    *(uint64_t *)MTIMECMP = 0xffffffffffffffff; // 注意要重置MTIMECMP，否则一直触发中断
}
