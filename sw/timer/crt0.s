/*Copyright 2018-2021 T-Head Semiconductor Co., Ltd.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/
.text
.global	__start
__start:



  la x3, __erodata
  la x4, __data_start__
  la x5, __data_end__

  sub x5, x5, x4
  beqz x5, L_loop0_done

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
#enable cache
#  li x3, 0x1
#  csrw mhcr, x3

#open theadisaee
#  la  x3, 0x400000
#  csrrs x0, mxstatus, x3

#open mie in mstatus
  csrsi mstatus, 0x8

  
__to_main:
  jal main


  .global __exit
__exit:
  fence.i
  fence
  li    x4, 0x6000fff8
  addi  x3, x0,0xFF
  slli  x3, x3,0x4
  addi  x3, x3, 0xf #0xFFF
  sw	x3, 0(x4)

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
vector_table:	#totally 256 entries
	.rept   256
	.long   IRQHandler_Wrap
	.endr

/**
 * wrap up IRQHandler functions. Unlike ARM architecture, in risc-v we need to
 * save and recover context manually. For details see fpga_program.md
 * taken from wujian100 vector.s
*/
  .global IRQHandler_Wrap
  .weak   IRQHandler_Wrap
IRQHandler_Wrap:
  addi    sp, sp, -48
  sw      t0, 4(sp)
  sw      t1, 8(sp)
  csrr    t0, mepc
  csrr    t1, mcause
  sw      t1, 40(sp)
  sw      t0, 44(sp)
  csrs    mstatus, 8

  sw      ra, 0(sp)
  sw      t2, 12(sp)
  sw      a0, 16(sp)
  sw      a1, 20(sp)
  sw      a2, 24(sp)
  sw      a3, 28(sp)
  sw      a4, 32(sp)
  sw      a5, 36(sp)

  andi    t1, t1, 0x3FF
  slli    t1, t1, 2
  la      t0, g_irqvector
  add     t0, t0, t1
  lw      t2, (t0)
  jalr    t2

  csrc    mstatus, 8

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
