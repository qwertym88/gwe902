#ifndef __ITCONFIG_H__
#define __ITCONFIG_H__

#include "main.h"

#define CLINT_BASE 0xE0000000
#define CLIC_BASE 0xE0800000

/*
    clint（处理器核局部中断）主要职能是提供软件中断和计时器中断。
    软件中断：通过代码设置寄存器MSIP发起软件中断请求
    计时器中断：设置MTIMECMP的值，当值小于MTIME即systick的值时产生。sys_clk=27m/4=6.25mHz

    0x0000 MSIP R/W 0x00000000        机器模式软件中断配置寄存器：
                                        高位固定为 0，bit[0] 有效。
    Reserved - - - -
    0x4000 MTIMECMPLO R/W 0xFFFFFFFF  机器模式计时器：
                                        比较值寄存器 (低 32 位)
    0x4004 MTIMECMPHI R/W 0xFFFFFFFF  机器模式计时器：
                                        比较值寄存器 (高 32 位)。
    Reserved - - - -
    0xBFF8 MTIMELO R 0x00000000        机器模式计时器：
                                        当前值寄存器 (低 32 位)，该寄存器值为
                                        pad_cpu_sys_cnt[31:0] 信号的值。
    0xBFFC MTIMEHI R 0x00000000        机器模式计时器
                                        当前值寄存器 (高 32 位)，该寄存器值为
                                        pad_cpu_sys_cnt[63:32] 信号的值 *
*/
#define MSIP (CLINT_BASE + 0x0000UL)
#define MTIMECMP (CLINT_BASE + 0x4000UL)
#define MTIME (CLINT_BASE + 0xBFF8UL)

#define SOFT_RST_INT_ID 3
#define SYSTICK_TIMER_INT_ID 7

/*
    clic（核内局部中断控制器）职能为对中断源进行采样，优先级仲裁和分发。CLIC仲裁来源包括处理器各个模式下触发的中断。
    - opene902 提供64个外部中断源可配，支持电平中断，脉冲中断，同时兼容CLINT的至多16个中断
     （目前仅实现机器模式软件中断和机器模式计时器中断，对应CLINT3号和7号中断）
    - 中断优先级有效位 CLICINTCTLBITS 配为 3，支持 8 个级别的中断优先级；

    在 CLIC 中只有符合条件的中断源才会参与仲裁。需满足的条件如下：
    • 中断源处于等待状态（IP =1）；
    • 中断优先级大于 0；
    • CLIC 中该中断使能位为 1（IE=1）。

    当 CLIC 中有多个中断处于等待状态时，CLIC 仲裁出优先级最高的中断。CLIC 中中断优先级配置寄存器 (CLICINTCTL) 的值越大，
    优先级越高，优先级为 0 的中断无效；如多个中断拥有相同的优先级，则中断 ID 较大的优先处理。
    CLIC 会将仲裁结果包括中断 ID，优先级，特权态，是否为矢量中断的信息传递给 CPU 流水线核心。
    其中，中断 ID 作为中断号进行处理，CLINT 中断对应中断号为 0~15，CLIC 外接的中断源中断号为 16~79。

    当 CPU 收到有效中断请求，且优先级大于核内正在响应中断的优先级，根据不同的中断类型情况，CPU
    会向 CLIC 发送中断响应消息。中断响应机制如下：
    • 中断为电平中断时，无中断响应信号，需要中断服务程序里通过软件清除外部中断源；
    • 中断为矢量模式边缘中断时，CPU 响应中断后，会发出一个响应信号，CLIC 收到该信号后，清除对
      应中断的中断等待位；
    • 中断为非矢量模式边缘中断时，若中断服务程序中对 MNXTI 寄存器进行读操作，该读操作会从 CLIC
      获得一个 ID 并生成对应的中断服务程序入口地址，表示当前 CLIC 仲裁出的中断的服务程序入口地
      址。CPU 根据所获得的地址进行跳转操作。如果从 MNXTI 寄存器读取的值为 0，表示没有有效中断
      请求。当 CLIC 收到 CPU 对 MNXTI 寄存器有效的读操作后，根据相应 ID 清除对应的中断等待位。

    0xE0800000     CLICCFG RW 0x1               CLIC 配置寄存器
    0xE0800004     CLICINFO RO                  CLIC 信息寄存器
    0xE0800008     MINTTHRESH RW 0x0            中断阈值寄存器
    0xE0801000+4*i CLICINTIP[i] R or RW 0x0     中断源 i 等待寄存器
    0xE0801001+4*i CLICINTIE[i] RW 0x0          中断源 i 使能寄存器
    0xE0801002+4*i CLICINTATTR[i] RW 0x0        中断源 i 属性寄存器
    0xE0801003+4*i CLICINTCTRL[i] RW 0x0        中断源 i 控制寄存器

*/

/*
    CLICCFG CLIC配置寄存器  bit[0]: 绑定为1，支持矢量模式中断，无需专门设置
                            bit[4:1]: nlbits值，中断优先级位数，e902最大为3
    MINTTHRESH 中断阈值寄存器   bit[31:24]: 中断优先级阈值，大于该值才能向处理器发起中断
*/

#define CLICCFG (CLIC_BASE + 0x0000UL)
#define CLICINFO (CLIC_BASE + 0x0004UL)
#define MINTTHRESH (CLIC_BASE + 0x0008UL)
// 第i号中断的位置
#define CLICINT_I(i) ((INTCONFIG_TypeDef *)(0xE0801000 + 4 * i))

/*
    IP 中断等待寄存器   bit[0]: 中断源是否有中断等待响应。电平中断模式下只读。边缘中断模式下可读可写，自动置位，
                        当中断配置为硬件矢量模式时，CPU响应中断的同时会自动清除中断的该位。细节见e902用户手册p47
    IE 中断使能寄存器   bit[0]: 中断使能，1使能
    ATTR 中断属性寄存器 bit[0]: 矢量中断使能，1表示中断为硬件矢量中断，0不是
                        bit[2:1]: 中断触发方式，x0电平中断，01上升沿，11下降沿
    CTRL 中断属性寄存器 bit[7:5+nlbits]: 中断的优先级。其余位无论设何值最终都绑定为1
*/

typedef struct
{
    __IO uint8_t IP;
    __IO uint8_t IE;
    __IO uint8_t ATTR;
    __IO uint8_t CTRL;
} INTCONFIG_TypeDef;

// 高三位有效，相当于以 0 2 4 6 8 a c e 开头判断优先级，0永远不会执行
typedef enum
{
    PRIORITY_NONE = 0x0,
    PRIORITY_LOWLOW = 0x20,
    PRIORITY_LOW = 0x40,
    PRIORITY_NORMLOW = 0x60,
    PRIORITY_NORM = 0x80,
    PRIORITY_NORMHIGH = 0xa0,
    PRIORITY_HIGH = 0xc0,
    PRIORITY_HIGHHIGH = 0xe0
} INTPRIORITY;

void enableInt(uint8_t id, uint8_t trigger, INTPRIORITY pri);
void disableInt(uint8_t id);

void setSoftRst(uint32_t value);
void setSysticTimerIt(uint64_t time);

uint64_t getSystick(void);

void initInt(void);

#endif