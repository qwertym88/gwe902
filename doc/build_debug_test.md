# 编译调试指南

## 高云IDE

### 启动

下载商业版高云ide，注意ide和programmer路径不能包含中文，linux下programmer需要超级用户权限。虚拟机改mac地址和添加虚拟网卡的知识自行搜索。

linux下可能会出现所有文字无法正常显示的问题，解决办法之一是删除lib文件夹下libfreetype文件，用系统的字体。其他不得而知。

### 从0开始的项目创建

原理上直接双击这个.pgrj就行了？没在其他地方测过。观察到高云IDE新建项目时本质只是创建文件夹和空的.gprj，打开项目后才会生成其他的文件。想改项目名的话应该打开项目前改文件夹名，或修改生成的project_process_config.json。

将src目录下所有文件添加到项目中即可。

### 综合、布线和烧写

![](../img/Snipaste_2023-12-03_00-08-27.png)

如上手教程所示，均保持默认即可。

### 用户约束

待研究

### ip核

从各处搜刮来的ip核都可以拼在一起，因此不必强求统一出处。gowin ide自带了部分ip核，其他的也可以从cmsdk或其他地方掏。

## T-Head DebugServer

一般来讲，只要是对的就不会错，有问题看那个报错信息也很难看出来什么

![](../img/Snipaste_2023-11-08_19-24-47.png)

出现上图所示的情况还有有以下原因：

- fpga掉电后布线没了
- tck tms接错了
- 没用共地
- cpu_rst等复位信号生效中

### 调试器

貌似只用接 tck tms gnd 三条线，其他的线有什么用就不知道了

## Xuantie gcc 900 gnu toolchain

待研究

## VScode Cortex Debug

没啥需要深入研究的，本质gdb调试工具

``` json
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Cortex Debug",
            "cwd": "${workspaceFolder}",
            "executable": "./sw/fill_array/fill_array.elf", // elf/bin文件
            "request": "launch", // launch/attach
            "type": "cortex-debug",
            "runToEntryPoint": "main",
            "servertype": "external", // *
            "gdbTarget": "localhost:1025", // t-head debugserver上显示的ip和端口
            "gdbPath": "C:/Program/fpga/Xuantie-900-gcc-elf-newlib-mingw-V2.8.0/bin/riscv64-unknown-elf-gdb.exe", // gnu toolchain的路径
            "showDevDebugOutput": "raw" // 可选，Cortex Debug的详细输出
        }
    ]
}

```

## crt0.s/linker.lcf

### ld文件

待深入研究

``` c
// example
MEMORY
{
MEM1(RWX)  : ORIGIN = 0x00000000,  LENGTH = 64K
MEM2(RWX)  : ORIGIN = 0x20000000,  LENGTH = 32K
/* name */  /* 权限 */  /* 起始地址 */   /* 长度 */
}
__kernel_stack = 0x20007ff8;  /* 0x20000000 + 32k，必须是严格准确的内存地址 */

ENTRY(__start)

SECTIONS {
    .text : /* 代码 */
    {
        crt0.o (.text)    /* 包含crt0.o中的.text 部分 */
        *(.text*)         /* 包含.o中所有以.text 开头的段 */
        . = ALIGN(0x10);  /* 强制将当前位置对齐到 16 字节边界 */
    } >MEM1               /* 放置在 MEM1(flash) 区域 */
    .rodata : /* 只读数据 */
    {
      *(.rodata*)         /* 包含.o中所有以.rodata 开头的段 */
          . = ALIGN(0x4); /* 强制将当前位置对齐到 4 字节边界，也就是按字对齐 */
        __erodata = .;    /* 记录此时的位置为__erodata */
    } > MEM1
    .data : /* 初始化的数据 */
    {
      . = ALIGN(0x4);     /* 4字节对齐 */
      __data_start__ = .; /* 记录此时的位置为__data_start__ */
        *(.data*)         /* 包含.o中所有相关的段 */
        *(.sdata*)
        *(.eh_frame*)
          . = ALIGN(0x4); /* 4字节对齐 */
        __data_end__ = .; /* 记录此时的位置为__data_end__ */
    } >MEM2 AT> MEM1 /* 表示VMA是MEM2但LMA是MEM1，也就是存储在MEM1但会装载到MEM2执行 */
    .bss : /* 未初始的化数据 */
    {
      . = ALIGN(0x4);
      __bss_start__ = .;
        *(.bss)
         . = ALIGN(0x4);
        __bss_end__ = .;
          *.(COMMON)
    } >MEM2               /* 放置在 MEM2(ram) 区域 */
}
```

对于`>MEM2 AT> MEM1`部分，如上所示，iahb里的ram有读写执行权限，本来就可以在ram里运行，之所以要装载到sysahb的ram里呢，应该就是说“因为大家（如stm31f1）是这样设计的，所以也这样做”了。

__kernel_stack的值即自己设置的ram最大所到的地址值，不需要包括外设或者紧耦合ip的地址范围。

### 启动文件

待深入研究

``` s
# 指示接下来的是代码段
.text
.global	__start
__start:
  la x3, __erodata      # .data段在flash的起始地址
  la x4, __data_start__ # .data段在ram的起始地址
  la x5, __data_end__   # .data段在ram的结束地址
  sub x5, x5, x4
  beqz x5, L_loop0_done
# 将.data段加载到ram中
L_loop0:
   lw x6, 0(x3)
   sw x6, 0(x4)
   addi x3, x3, 0x4
   addi x4, x4, 0x4
   addi x5, x5, -4
   bnez x5, L_loop0
L_loop0_done:
   la x3, __data_end__
   la x4, __bss_end__
   li x5, 0
   sub x4, x4, x3
   beqz x4, L_loop1_done
# 将ram后面的.bbs等段全部置0。可以理解为malloc分配的地址等
L_loop1:
   sw x5, 0(x3)
   addi x3, x3, 0x4
   addi x4, x4, -4
   bnez x4, L_loop1  
L_loop1_done:
  la x3, trap_handler
  csrw mtvec, x3
  la x3, vector_table
  addi x3, x3, 64
  csrw mtvt, x3
  la  x2, __kernel_stack
  csrsi mstatus, 0x8
# 主程序
__to_main:
  jal main  # 入口函数
# 正常结束，在0x6000fff8位置写入0xFFF，实际没啥用，原来的代码就这样懒得改了
  .global __exit
__exit:
  fence.i
  fence
  li    x4, 0x6000fff8
  addi  x3, x0,0xFF
  slli  x3, x3,0x4
  addi  x3, x3, 0xf #0xFFF
  sw	x3, 0(x4)
# 异常，在0x6000fff8位置写入0xEEE，实际没啥用
  .global __fail
__fail:
  fence.i
  fence
  li    x4, 0x6000fff8
  addi  x3, x0,0xEE
  slli  x3, x3,0x4
  addi  x3, x3,0xe #0xEEE
  sw	x3, 0(x4)
  .align 6  
  .global trap_handler
trap_handler:
  j __synchronous_exception
  .align 2  
  j __fail
 # 发生同步异常，一般是系统时钟或者调试器时钟的问题，检查这两个就行
__synchronous_exception:
  sw   x13,-4(x2)
  sw   x14,-8(x2)
  sw   x15,-12(x2)
  csrr x14,mcause
  andi x15,x14,0xff  #cause
  srli x14,x14,0x1b   #int
  andi x14,x14,0x10   #mask bit
  add  x14,x14,x15    #{int,cause}
  slli x14,x14,0x2  #offset
  la   x15,vector_table
  add  x15,x14,x15  #target pc
  lw   x14, 0(x15)  #get exception addr
  lw   x13, -4(x2)  #recover x16
  lw   x15, -12(x2) #recover x15
#addi x14,x14,-4
  jr   x14
  .global vector_table
  .align  6
# 中断向量表
vector_table:	# 共256，实际只有64，前16为clint
	.rept   256
	.long   __dummy # 中断处理函数，直接跳转__fail
	.endr

  .global __dummy
__dummy:  
  j __fail
  .data
  .long 0

```

### 中断

代码相关的细节可以看interrupt/itconfig.h里面的注释，结合e902用户手册8 9章内容应该容易理解。这里主要讲一下总体构建思路。

e902核pad_clic_int_vld[64:0]与中断向量表自16号起一一对应，前0-15则是clint产生的中断，这也就是集成手册所说的bit[i]对应中断号为16+i。当中断号所对应的中断源产生中断信号时，会根据中断向量表调用号码对应的中断处理函数。该中断信号可以设置成电平、上升下降沿触发，可以设置响应方式为矢量或非矢量中断。需要注意，这里的触发方式指的是中断信号的行为，而不是该信号是如何产生的。样例程序中按键gpio中断检测下降沿，产生的中断信号是从0到1的上升沿，因此clic应该检测上升沿。

区别于ARM架构，riscv规定异常和中断机制并没有硬件自动保存和恢复上下文的操作，软件需要自主保存并恢复上下文。具体来讲，中断程序入口必须对通用寄存器压栈保存，结束时恢复。

> 目前这里有点小问题。当在中断处理函数中设置断点，并在到达该断点后直接退出调试程序，通用寄存器没有正常恢复，clic不知道哪里就有问题了，此后中断都无法正常触发。虽然实际调试过程中稍微注意一点就能避免，但终究还是好麻烦。不知道是原本就该这样还是哪里还需要改。

实际编程中可以按照无剑100里面翻出来的这份代码写，代码不是太懂，反正能用就行：

``` verilog
.global IRQHandler_Wrap
  .weak   IRQHandler_Wrap
IRQHandler_Wrap:
  /* 开辟栈空间保存mcause和mepc */
  addi    sp, sp, -48
  sw      t0, 4(sp)
  sw      t1, 8(sp)
  csrr    t0, mepc
  csrr    t1, mcause
  sw      t1, 40(sp)
  sw      t0, 44(sp)
  /* 开启全局中断，实现中断嵌套 */
  csrs    mstatus, 8
  sw      ra, 0(sp)
  sw      t2, 12(sp)
  sw      a0, 16(sp)
  sw      a1, 20(sp)
  sw      a2, 24(sp)
  sw      a3, 28(sp)
  sw      a4, 32(sp)
  sw      a5, 36(sp)
/* 获取中断号，跳转到g_irqvector[i]对应的函数 */
  andi    t1, t1, 0x3FF
  slli    t1, t1, 2
  la      t0, g_irqvector
  add     t0, t0, t1
  lw      t2, (t0)
  jalr    t2
  /* 关闭全局中断 */
  csrc    mstatus, 8
  /* 清除clic中断请求位，防止重复响应电平中断 */
  lw      a1, 40(sp)
  andi    a0, a1, 0x3FF
  /* clear pending */
  li      a2, 0xE000E100
  add     a2, a2, a0
  lb      a3, 0(a2)
  li      a4, 1
  not     a4, a4
  and     a5, a4, a3
  sb      a5, 0(a2)

  /* Enable interrupts when returning from the handler */
  li      t0, 0x1880
  csrs    mstatus, t0
  csrw    mcause, a1
  lw      t0, 44(sp)
  csrw    mepc, t0
  lw      ra, 0(sp)
  lw      t0, 4(sp)
  lw      t1, 8(sp)
  lw      t2, 12(sp)
  lw      a0, 16(sp)
  lw      a1, 20(sp)
  lw      a2, 24(sp)
  lw      a3, 28(sp)
  lw      a4, 32(sp)
  lw      a5, 36(sp)

  addi    sp, sp, 48
  mret
```

g_irqvector即向量表对应的中断函数入口，自己设成啥都行。Default_IRQHandler在crt0.s中，定义为一个死循环。为方便后续代码设计，CORET_IRQHandler等默认指向Default_IRQHandler。

``` C
// 初始化中断向量表每个id对应的函数入口。
void irq_vectors_init(void)
{
    for (int i = 0; i < 64; i++)
    {
        g_irqvector[i] = Default_IRQHandler;
    }

    g_irqvector[SYSTICK_TIMER_INT_ID] = CORET_IRQHandler;
    g_irqvector[UART0_RX_INT_ID] = UART0_RX_IRQHandler;
    g_irqvector[UART0_TX_INT_ID] = UART0_TX_IRQHandler;
    g_irqvector[GPIOA_COMB_INT_ID] = GPIOA_IRQHandler;
}
```
