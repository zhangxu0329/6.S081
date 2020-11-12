#include "types.h"
#include "riscv.h"
#include "defs.h"
#include "date.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
  int n;
  if (argint(0, &n) < 0)
    return -1;
  exit(n);
  return 0; // not reached
}

uint64
sys_getpid(void)
{
  return myproc()->pid;
}

uint64
sys_fork(void)
{
  return fork();
}

uint64
sys_wait(void)
{
  uint64 p;
  if (argaddr(0, &p) < 0)
    return -1;
  return wait(p);
}

uint64
sys_sbrk(void)
{
  int addr;
  int n;

  if (argint(0, &n) < 0)
    return -1;
  addr = myproc()->sz;
  if (growproc(n) < 0)
    return -1;
  return addr;
}

uint64
sys_sleep(void)
{
  int n;
  uint ticks0;

  if (argint(0, &n) < 0)
    return -1;
  acquire(&tickslock);
  ticks0 = ticks;
  while (ticks - ticks0 < n)
  {
    if (myproc()->killed)
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
  backtrace();
  return 0;
}

uint64
sys_kill(void)
{
  int pid;

  if (argint(0, &pid) < 0)
    return -1;
  return kill(pid);
}

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
  uint xticks;

  acquire(&tickslock);
  xticks = ticks;
  release(&tickslock);
  return xticks;
}

// sys_sigreturn
uint64
sys_sigreturn(void)
{
  // save enough state in struct proc context when the timer goes off
  // that sigreturn can correctly return to the interrupted user code.
  struct proc *p = myproc();
  p->trapframe->epc = p->user_reg.epc;
  p->trapframe->ra = p->user_reg.ra;
  p->trapframe->sp = p->user_reg.sp;
  p->trapframe->gp = p->user_reg.gp;
  p->trapframe->tp = p->user_reg.tp;

  p->trapframe->s0 = p->user_reg.s0;
  p->trapframe->s1 = p->user_reg.s1;
  p->trapframe->s2 = p->user_reg.s2;
  p->trapframe->s3 = p->user_reg.s3;
  p->trapframe->s4 = p->user_reg.s4;
  p->trapframe->s5 = p->user_reg.s5;
  p->trapframe->s6 = p->user_reg.s6;
  p->trapframe->s7 = p->user_reg.s7;
  p->trapframe->s8 = p->user_reg.s8;
  p->trapframe->s9 = p->user_reg.s9;
  p->trapframe->s10 = p->user_reg.s10;
  p->trapframe->s11 = p->user_reg.s11;

  p->trapframe->t0 = p->user_reg.t0;
  p->trapframe->t1 = p->user_reg.t1;
  p->trapframe->t2 = p->user_reg.t2;
  p->trapframe->t3 = p->user_reg.t3;
  p->trapframe->t4 = p->user_reg.t4;
  p->trapframe->t5 = p->user_reg.t5;
  p->trapframe->t6 = p->user_reg.t6;

  p->trapframe->a0 = p->user_reg.a0;
  p->trapframe->a1 = p->user_reg.a1;
  p->trapframe->a2 = p->user_reg.a2;
  p->trapframe->a3 = p->user_reg.a3;
  p->trapframe->a4 = p->user_reg.a4;
  p->trapframe->a5 = p->user_reg.a5;
  p->trapframe->a6 = p->user_reg.a6;
  p->trapframe->a7 = p->user_reg.a7;
  p->handle = 0;
  // p->count_of_trick = 0;
  // p->alarm_interval = 0;
  // p->is_alarm = 0;
  p->in_alarm_handler = 0;
  // usertrapret();
  // p->is_alarm = 0;
  // p->in_alarm_handler = 0;
  return 0;
}

uint64
sys_sigalarm(void)
{
  struct proc *p = myproc();
  p->is_alarm = 1;
  int tracks = 0;
  if (argint(0, &tracks) < 0)
    return -1;
  p->alarm_interval = tracks;
  // printf("tracks: %d \n", p->alarm_interval);
  uint64 func = 0;
  if (argaddr(1, &func) < 0)
    return -1;
  p->handle = func;
  if(tracks == 0 && func == 0)
    p->is_alarm = 0;
  return 0;
}