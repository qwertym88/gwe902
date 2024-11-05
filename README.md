# e902/gowin学习笔记

基于平头哥opene902内核的简易mcu，包含

- [x] gpio
- [x] 串口
- [x] 中断处理、中断嵌套
- [ ] 计时器（无pwm输出）
- [ ] 其他总线设备

垃圾优化，主频才10MHz；代码完全抄书，没有任何创新。

使用设备sipeed tang primer 25k。如果当真想入fpga的天坑，建议加价直接上zynq，这个更可玩性更高。如果只是ee专业拿来当“可编程电子元器件”玩，用来模拟点老红白机啥的，这个价格倒是非常香。

# 简明入门指引

1. 忘掉计组、数电、数字逻辑、操作系统课上所讲，过时的知识只会浪费时间。
2. 多参考[cortex-M soc design](https://github.com/arm-university/System-on-Chip-Design-with-Arm-Cortex-M-Processors)，至少我几乎是完全抄袭的。
3. opene902的手册有点乱，突出一个要多方参考、尽信不如无，不过本项目涉及到的都没啥太大问题，有我也排干净了。（不过相较于其他国产厂已经是手册最全最有用的了，说多了都是泪）
4. 建议做c906，这个设计好、文档全、功能多、成就感强，只把本项目作为参考源。
5. 本人完全不会汇编、零fpga基础也能做，完全不用学“汇编入门”、“fpga入门”，浪费时间。

## 建议学习顺序

1. 正确启动gowin工程，用gen_e902脚本把opene902源码处理一下，加入工程文件无报错。
2. 草读[cortex-M soc design](https://github.com/arm-university/System-on-Chip-Design-with-Arm-Cortex-M-Processors)和e902手册，阅读[soc设计](./doc/fpga_program.md#综述)综述和e902核章节。初期懵逼没关系，越到后面越明白。
3. 阅读cpu_mem.v和sysahb_periphs.v源码，阅读cortex-M soc design对应章节，了解这两个文件在干什么。试着在这上面分别挂一个AHBBlockRam。
4. 阅读[soc设计](./doc/fpga_program.md#jtag支持) jtag和复位部分，阅读[编译调试指南](./doc/build_debug_test.md#调试器) T-Head DebugServer、VScode Cortex Debug、crt0.s/linker.lcf章节，了解点基本概念。烧录bitstream后，用调试器链接你设计的调试端口，电脑开启T-Head DebugServer启动gdb调试，用配置好的VScode Cortex Debug链接gdb，运行sw/loop、sw/fill_array示例。
5. 添加apb设备，添加gpio后运行sw/led_flow，添加uart后运行sw/helloworld，添加timer后运行sw/timer，体验中断sw/interrupt。建议按照这个顺序来看代码和其中的注释，连贯些。

进行到4时应该就能体会到其本质上就是搭积木，要想增加一个功能，只需找到有对应接口的ip，挂上去就能跑起来。如果使用过xilinx的开发工具应该更熟悉，完全不用关注ip核本身是怎么实现的，只需要把你想要的ip核串起来就行，在vivado里甚至可以图形化操作，只不过这里我们是手动串起来罢了。

如果只是想体验运行，只需参考[e902 getting start guide](./doc/getting_start.md)即可。