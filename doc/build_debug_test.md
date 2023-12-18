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
# 将ram后面的.bbs等段全部置0
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
# 正常结束，在0x6000fff8位置写入0xFFF
  .global __exit
__exit:
  fence.i
  fence
  li    x4, 0x6000fff8
  addi  x3, x0,0xFF
  slli  x3, x3,0x4
  addi  x3, x3, 0xf #0xFFF
  sw	x3, 0(x4)
# 异常，在0x6000fff8位置写入0xEEE
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
 # 发生同步异常
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
vector_table:	#totally 256 entries
	.rept   256
	.long   __dummy
	.endr
  .global __dummy
__dummy:  
  j __fail
  
  .data
  .long 0

```

完全没想明白如何判断程序是正常结束还是异常终止，在特定位置写的数据怎么才能用上？中断向量表是个什么原理，中断如何产生？
