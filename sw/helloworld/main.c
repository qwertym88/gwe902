#include "std10.h"

int main()
{
    uart_init();
    println("hello world");
    while (1)
        ;
    return 0;
}
