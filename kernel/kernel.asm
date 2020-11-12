
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	0000a117          	auipc	sp,0xa
    80000004:	83010113          	addi	sp,sp,-2000 # 80009830 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	070000ef          	jal	ra,80000086 <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    80000026:	0037969b          	slliw	a3,a5,0x3
    8000002a:	02004737          	lui	a4,0x2004
    8000002e:	96ba                	add	a3,a3,a4
    80000030:	0200c737          	lui	a4,0x200c
    80000034:	ff873603          	ld	a2,-8(a4) # 200bff8 <_entry-0x7dff4008>
    80000038:	000f4737          	lui	a4,0xf4
    8000003c:	24070713          	addi	a4,a4,576 # f4240 <_entry-0x7ff0bdc0>
    80000040:	963a                	add	a2,a2,a4
    80000042:	e290                	sd	a2,0(a3)

  // prepare information in scratch[] for timervec.
  // scratch[0..3] : space for timervec to save registers.
  // scratch[4] : address of CLINT MTIMECMP register.
  // scratch[5] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &mscratch0[32 * id];
    80000044:	0057979b          	slliw	a5,a5,0x5
    80000048:	078e                	slli	a5,a5,0x3
    8000004a:	00009617          	auipc	a2,0x9
    8000004e:	fe660613          	addi	a2,a2,-26 # 80009030 <mscratch0>
    80000052:	97b2                	add	a5,a5,a2
  scratch[4] = CLINT_MTIMECMP(id);
    80000054:	f394                	sd	a3,32(a5)
  scratch[5] = interval;
    80000056:	f798                	sd	a4,40(a5)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000058:	34079073          	csrw	mscratch,a5
  asm volatile("csrw mtvec, %0" : : "r" (x));
    8000005c:	00006797          	auipc	a5,0x6
    80000060:	e5478793          	addi	a5,a5,-428 # 80005eb0 <timervec>
    80000064:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000068:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    8000006c:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000070:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    80000074:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000078:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    8000007c:	30479073          	csrw	mie,a5
}
    80000080:	6422                	ld	s0,8(sp)
    80000082:	0141                	addi	sp,sp,16
    80000084:	8082                	ret

0000000080000086 <start>:
{
    80000086:	1141                	addi	sp,sp,-16
    80000088:	e406                	sd	ra,8(sp)
    8000008a:	e022                	sd	s0,0(sp)
    8000008c:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000008e:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000092:	7779                	lui	a4,0xffffe
    80000094:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd37ff>
    80000098:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    8000009a:	6705                	lui	a4,0x1
    8000009c:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a0:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a2:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000a6:	00001797          	auipc	a5,0x1
    800000aa:	e6678793          	addi	a5,a5,-410 # 80000f0c <main>
    800000ae:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b2:	4781                	li	a5,0
    800000b4:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000b8:	67c1                	lui	a5,0x10
    800000ba:	17fd                	addi	a5,a5,-1
    800000bc:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c0:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000c4:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000c8:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000cc:	10479073          	csrw	sie,a5
  timerinit();
    800000d0:	00000097          	auipc	ra,0x0
    800000d4:	f4c080e7          	jalr	-180(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000d8:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000dc:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000de:	823e                	mv	tp,a5
  asm volatile("mret");
    800000e0:	30200073          	mret
}
    800000e4:	60a2                	ld	ra,8(sp)
    800000e6:	6402                	ld	s0,0(sp)
    800000e8:	0141                	addi	sp,sp,16
    800000ea:	8082                	ret

00000000800000ec <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    800000ec:	715d                	addi	sp,sp,-80
    800000ee:	e486                	sd	ra,72(sp)
    800000f0:	e0a2                	sd	s0,64(sp)
    800000f2:	fc26                	sd	s1,56(sp)
    800000f4:	f84a                	sd	s2,48(sp)
    800000f6:	f44e                	sd	s3,40(sp)
    800000f8:	f052                	sd	s4,32(sp)
    800000fa:	ec56                	sd	s5,24(sp)
    800000fc:	0880                	addi	s0,sp,80
    800000fe:	8a2a                	mv	s4,a0
    80000100:	84ae                	mv	s1,a1
    80000102:	89b2                	mv	s3,a2
  int i;

  acquire(&cons.lock);
    80000104:	00011517          	auipc	a0,0x11
    80000108:	72c50513          	addi	a0,a0,1836 # 80011830 <cons>
    8000010c:	00001097          	auipc	ra,0x1
    80000110:	b56080e7          	jalr	-1194(ra) # 80000c62 <acquire>
  for(i = 0; i < n; i++){
    80000114:	05305b63          	blez	s3,8000016a <consolewrite+0x7e>
    80000118:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011a:	5afd                	li	s5,-1
    8000011c:	4685                	li	a3,1
    8000011e:	8626                	mv	a2,s1
    80000120:	85d2                	mv	a1,s4
    80000122:	fbf40513          	addi	a0,s0,-65
    80000126:	00002097          	auipc	ra,0x2
    8000012a:	3dc080e7          	jalr	988(ra) # 80002502 <either_copyin>
    8000012e:	01550c63          	beq	a0,s5,80000146 <consolewrite+0x5a>
      break;
    uartputc(c);
    80000132:	fbf44503          	lbu	a0,-65(s0)
    80000136:	00000097          	auipc	ra,0x0
    8000013a:	7fa080e7          	jalr	2042(ra) # 80000930 <uartputc>
  for(i = 0; i < n; i++){
    8000013e:	2905                	addiw	s2,s2,1
    80000140:	0485                	addi	s1,s1,1
    80000142:	fd299de3          	bne	s3,s2,8000011c <consolewrite+0x30>
  }
  release(&cons.lock);
    80000146:	00011517          	auipc	a0,0x11
    8000014a:	6ea50513          	addi	a0,a0,1770 # 80011830 <cons>
    8000014e:	00001097          	auipc	ra,0x1
    80000152:	bc8080e7          	jalr	-1080(ra) # 80000d16 <release>

  return i;
}
    80000156:	854a                	mv	a0,s2
    80000158:	60a6                	ld	ra,72(sp)
    8000015a:	6406                	ld	s0,64(sp)
    8000015c:	74e2                	ld	s1,56(sp)
    8000015e:	7942                	ld	s2,48(sp)
    80000160:	79a2                	ld	s3,40(sp)
    80000162:	7a02                	ld	s4,32(sp)
    80000164:	6ae2                	ld	s5,24(sp)
    80000166:	6161                	addi	sp,sp,80
    80000168:	8082                	ret
  for(i = 0; i < n; i++){
    8000016a:	4901                	li	s2,0
    8000016c:	bfe9                	j	80000146 <consolewrite+0x5a>

000000008000016e <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    8000016e:	7159                	addi	sp,sp,-112
    80000170:	f486                	sd	ra,104(sp)
    80000172:	f0a2                	sd	s0,96(sp)
    80000174:	eca6                	sd	s1,88(sp)
    80000176:	e8ca                	sd	s2,80(sp)
    80000178:	e4ce                	sd	s3,72(sp)
    8000017a:	e0d2                	sd	s4,64(sp)
    8000017c:	fc56                	sd	s5,56(sp)
    8000017e:	f85a                	sd	s6,48(sp)
    80000180:	f45e                	sd	s7,40(sp)
    80000182:	f062                	sd	s8,32(sp)
    80000184:	ec66                	sd	s9,24(sp)
    80000186:	e86a                	sd	s10,16(sp)
    80000188:	1880                	addi	s0,sp,112
    8000018a:	8aaa                	mv	s5,a0
    8000018c:	8a2e                	mv	s4,a1
    8000018e:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000190:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    80000194:	00011517          	auipc	a0,0x11
    80000198:	69c50513          	addi	a0,a0,1692 # 80011830 <cons>
    8000019c:	00001097          	auipc	ra,0x1
    800001a0:	ac6080e7          	jalr	-1338(ra) # 80000c62 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    800001a4:	00011497          	auipc	s1,0x11
    800001a8:	68c48493          	addi	s1,s1,1676 # 80011830 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001ac:	00011917          	auipc	s2,0x11
    800001b0:	71c90913          	addi	s2,s2,1820 # 800118c8 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001b4:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001b6:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001b8:	4ca9                	li	s9,10
  while(n > 0){
    800001ba:	07305863          	blez	s3,8000022a <consoleread+0xbc>
    while(cons.r == cons.w){
    800001be:	0984a783          	lw	a5,152(s1)
    800001c2:	09c4a703          	lw	a4,156(s1)
    800001c6:	02f71463          	bne	a4,a5,800001ee <consoleread+0x80>
      if(myproc()->killed){
    800001ca:	00002097          	auipc	ra,0x2
    800001ce:	864080e7          	jalr	-1948(ra) # 80001a2e <myproc>
    800001d2:	591c                	lw	a5,48(a0)
    800001d4:	e7b5                	bnez	a5,80000240 <consoleread+0xd2>
      sleep(&cons.r, &cons.lock);
    800001d6:	85a6                	mv	a1,s1
    800001d8:	854a                	mv	a0,s2
    800001da:	00002097          	auipc	ra,0x2
    800001de:	078080e7          	jalr	120(ra) # 80002252 <sleep>
    while(cons.r == cons.w){
    800001e2:	0984a783          	lw	a5,152(s1)
    800001e6:	09c4a703          	lw	a4,156(s1)
    800001ea:	fef700e3          	beq	a4,a5,800001ca <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001ee:	0017871b          	addiw	a4,a5,1
    800001f2:	08e4ac23          	sw	a4,152(s1)
    800001f6:	07f7f713          	andi	a4,a5,127
    800001fa:	9726                	add	a4,a4,s1
    800001fc:	01874703          	lbu	a4,24(a4)
    80000200:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    80000204:	077d0563          	beq	s10,s7,8000026e <consoleread+0x100>
    cbuf = c;
    80000208:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    8000020c:	4685                	li	a3,1
    8000020e:	f9f40613          	addi	a2,s0,-97
    80000212:	85d2                	mv	a1,s4
    80000214:	8556                	mv	a0,s5
    80000216:	00002097          	auipc	ra,0x2
    8000021a:	296080e7          	jalr	662(ra) # 800024ac <either_copyout>
    8000021e:	01850663          	beq	a0,s8,8000022a <consoleread+0xbc>
    dst++;
    80000222:	0a05                	addi	s4,s4,1
    --n;
    80000224:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    80000226:	f99d1ae3          	bne	s10,s9,800001ba <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    8000022a:	00011517          	auipc	a0,0x11
    8000022e:	60650513          	addi	a0,a0,1542 # 80011830 <cons>
    80000232:	00001097          	auipc	ra,0x1
    80000236:	ae4080e7          	jalr	-1308(ra) # 80000d16 <release>

  return target - n;
    8000023a:	413b053b          	subw	a0,s6,s3
    8000023e:	a811                	j	80000252 <consoleread+0xe4>
        release(&cons.lock);
    80000240:	00011517          	auipc	a0,0x11
    80000244:	5f050513          	addi	a0,a0,1520 # 80011830 <cons>
    80000248:	00001097          	auipc	ra,0x1
    8000024c:	ace080e7          	jalr	-1330(ra) # 80000d16 <release>
        return -1;
    80000250:	557d                	li	a0,-1
}
    80000252:	70a6                	ld	ra,104(sp)
    80000254:	7406                	ld	s0,96(sp)
    80000256:	64e6                	ld	s1,88(sp)
    80000258:	6946                	ld	s2,80(sp)
    8000025a:	69a6                	ld	s3,72(sp)
    8000025c:	6a06                	ld	s4,64(sp)
    8000025e:	7ae2                	ld	s5,56(sp)
    80000260:	7b42                	ld	s6,48(sp)
    80000262:	7ba2                	ld	s7,40(sp)
    80000264:	7c02                	ld	s8,32(sp)
    80000266:	6ce2                	ld	s9,24(sp)
    80000268:	6d42                	ld	s10,16(sp)
    8000026a:	6165                	addi	sp,sp,112
    8000026c:	8082                	ret
      if(n < target){
    8000026e:	0009871b          	sext.w	a4,s3
    80000272:	fb677ce3          	bgeu	a4,s6,8000022a <consoleread+0xbc>
        cons.r--;
    80000276:	00011717          	auipc	a4,0x11
    8000027a:	64f72923          	sw	a5,1618(a4) # 800118c8 <cons+0x98>
    8000027e:	b775                	j	8000022a <consoleread+0xbc>

0000000080000280 <consputc>:
{
    80000280:	1141                	addi	sp,sp,-16
    80000282:	e406                	sd	ra,8(sp)
    80000284:	e022                	sd	s0,0(sp)
    80000286:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000288:	10000793          	li	a5,256
    8000028c:	00f50a63          	beq	a0,a5,800002a0 <consputc+0x20>
    uartputc_sync(c);
    80000290:	00000097          	auipc	ra,0x0
    80000294:	5c2080e7          	jalr	1474(ra) # 80000852 <uartputc_sync>
}
    80000298:	60a2                	ld	ra,8(sp)
    8000029a:	6402                	ld	s0,0(sp)
    8000029c:	0141                	addi	sp,sp,16
    8000029e:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    800002a0:	4521                	li	a0,8
    800002a2:	00000097          	auipc	ra,0x0
    800002a6:	5b0080e7          	jalr	1456(ra) # 80000852 <uartputc_sync>
    800002aa:	02000513          	li	a0,32
    800002ae:	00000097          	auipc	ra,0x0
    800002b2:	5a4080e7          	jalr	1444(ra) # 80000852 <uartputc_sync>
    800002b6:	4521                	li	a0,8
    800002b8:	00000097          	auipc	ra,0x0
    800002bc:	59a080e7          	jalr	1434(ra) # 80000852 <uartputc_sync>
    800002c0:	bfe1                	j	80000298 <consputc+0x18>

00000000800002c2 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002c2:	1101                	addi	sp,sp,-32
    800002c4:	ec06                	sd	ra,24(sp)
    800002c6:	e822                	sd	s0,16(sp)
    800002c8:	e426                	sd	s1,8(sp)
    800002ca:	e04a                	sd	s2,0(sp)
    800002cc:	1000                	addi	s0,sp,32
    800002ce:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002d0:	00011517          	auipc	a0,0x11
    800002d4:	56050513          	addi	a0,a0,1376 # 80011830 <cons>
    800002d8:	00001097          	auipc	ra,0x1
    800002dc:	98a080e7          	jalr	-1654(ra) # 80000c62 <acquire>

  switch(c){
    800002e0:	47d5                	li	a5,21
    800002e2:	0af48663          	beq	s1,a5,8000038e <consoleintr+0xcc>
    800002e6:	0297ca63          	blt	a5,s1,8000031a <consoleintr+0x58>
    800002ea:	47a1                	li	a5,8
    800002ec:	0ef48763          	beq	s1,a5,800003da <consoleintr+0x118>
    800002f0:	47c1                	li	a5,16
    800002f2:	10f49a63          	bne	s1,a5,80000406 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f6:	00002097          	auipc	ra,0x2
    800002fa:	262080e7          	jalr	610(ra) # 80002558 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fe:	00011517          	auipc	a0,0x11
    80000302:	53250513          	addi	a0,a0,1330 # 80011830 <cons>
    80000306:	00001097          	auipc	ra,0x1
    8000030a:	a10080e7          	jalr	-1520(ra) # 80000d16 <release>
}
    8000030e:	60e2                	ld	ra,24(sp)
    80000310:	6442                	ld	s0,16(sp)
    80000312:	64a2                	ld	s1,8(sp)
    80000314:	6902                	ld	s2,0(sp)
    80000316:	6105                	addi	sp,sp,32
    80000318:	8082                	ret
  switch(c){
    8000031a:	07f00793          	li	a5,127
    8000031e:	0af48e63          	beq	s1,a5,800003da <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000322:	00011717          	auipc	a4,0x11
    80000326:	50e70713          	addi	a4,a4,1294 # 80011830 <cons>
    8000032a:	0a072783          	lw	a5,160(a4)
    8000032e:	09872703          	lw	a4,152(a4)
    80000332:	9f99                	subw	a5,a5,a4
    80000334:	07f00713          	li	a4,127
    80000338:	fcf763e3          	bltu	a4,a5,800002fe <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    8000033c:	47b5                	li	a5,13
    8000033e:	0cf48763          	beq	s1,a5,8000040c <consoleintr+0x14a>
      consputc(c);
    80000342:	8526                	mv	a0,s1
    80000344:	00000097          	auipc	ra,0x0
    80000348:	f3c080e7          	jalr	-196(ra) # 80000280 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    8000034c:	00011797          	auipc	a5,0x11
    80000350:	4e478793          	addi	a5,a5,1252 # 80011830 <cons>
    80000354:	0a07a703          	lw	a4,160(a5)
    80000358:	0017069b          	addiw	a3,a4,1
    8000035c:	0006861b          	sext.w	a2,a3
    80000360:	0ad7a023          	sw	a3,160(a5)
    80000364:	07f77713          	andi	a4,a4,127
    80000368:	97ba                	add	a5,a5,a4
    8000036a:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    8000036e:	47a9                	li	a5,10
    80000370:	0cf48563          	beq	s1,a5,8000043a <consoleintr+0x178>
    80000374:	4791                	li	a5,4
    80000376:	0cf48263          	beq	s1,a5,8000043a <consoleintr+0x178>
    8000037a:	00011797          	auipc	a5,0x11
    8000037e:	54e7a783          	lw	a5,1358(a5) # 800118c8 <cons+0x98>
    80000382:	0807879b          	addiw	a5,a5,128
    80000386:	f6f61ce3          	bne	a2,a5,800002fe <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    8000038a:	863e                	mv	a2,a5
    8000038c:	a07d                	j	8000043a <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038e:	00011717          	auipc	a4,0x11
    80000392:	4a270713          	addi	a4,a4,1186 # 80011830 <cons>
    80000396:	0a072783          	lw	a5,160(a4)
    8000039a:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039e:	00011497          	auipc	s1,0x11
    800003a2:	49248493          	addi	s1,s1,1170 # 80011830 <cons>
    while(cons.e != cons.w &&
    800003a6:	4929                	li	s2,10
    800003a8:	f4f70be3          	beq	a4,a5,800002fe <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003ac:	37fd                	addiw	a5,a5,-1
    800003ae:	07f7f713          	andi	a4,a5,127
    800003b2:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b4:	01874703          	lbu	a4,24(a4)
    800003b8:	f52703e3          	beq	a4,s2,800002fe <consoleintr+0x3c>
      cons.e--;
    800003bc:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003c0:	10000513          	li	a0,256
    800003c4:	00000097          	auipc	ra,0x0
    800003c8:	ebc080e7          	jalr	-324(ra) # 80000280 <consputc>
    while(cons.e != cons.w &&
    800003cc:	0a04a783          	lw	a5,160(s1)
    800003d0:	09c4a703          	lw	a4,156(s1)
    800003d4:	fcf71ce3          	bne	a4,a5,800003ac <consoleintr+0xea>
    800003d8:	b71d                	j	800002fe <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003da:	00011717          	auipc	a4,0x11
    800003de:	45670713          	addi	a4,a4,1110 # 80011830 <cons>
    800003e2:	0a072783          	lw	a5,160(a4)
    800003e6:	09c72703          	lw	a4,156(a4)
    800003ea:	f0f70ae3          	beq	a4,a5,800002fe <consoleintr+0x3c>
      cons.e--;
    800003ee:	37fd                	addiw	a5,a5,-1
    800003f0:	00011717          	auipc	a4,0x11
    800003f4:	4ef72023          	sw	a5,1248(a4) # 800118d0 <cons+0xa0>
      consputc(BACKSPACE);
    800003f8:	10000513          	li	a0,256
    800003fc:	00000097          	auipc	ra,0x0
    80000400:	e84080e7          	jalr	-380(ra) # 80000280 <consputc>
    80000404:	bded                	j	800002fe <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000406:	ee048ce3          	beqz	s1,800002fe <consoleintr+0x3c>
    8000040a:	bf21                	j	80000322 <consoleintr+0x60>
      consputc(c);
    8000040c:	4529                	li	a0,10
    8000040e:	00000097          	auipc	ra,0x0
    80000412:	e72080e7          	jalr	-398(ra) # 80000280 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000416:	00011797          	auipc	a5,0x11
    8000041a:	41a78793          	addi	a5,a5,1050 # 80011830 <cons>
    8000041e:	0a07a703          	lw	a4,160(a5)
    80000422:	0017069b          	addiw	a3,a4,1
    80000426:	0006861b          	sext.w	a2,a3
    8000042a:	0ad7a023          	sw	a3,160(a5)
    8000042e:	07f77713          	andi	a4,a4,127
    80000432:	97ba                	add	a5,a5,a4
    80000434:	4729                	li	a4,10
    80000436:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    8000043a:	00011797          	auipc	a5,0x11
    8000043e:	48c7a923          	sw	a2,1170(a5) # 800118cc <cons+0x9c>
        wakeup(&cons.r);
    80000442:	00011517          	auipc	a0,0x11
    80000446:	48650513          	addi	a0,a0,1158 # 800118c8 <cons+0x98>
    8000044a:	00002097          	auipc	ra,0x2
    8000044e:	f88080e7          	jalr	-120(ra) # 800023d2 <wakeup>
    80000452:	b575                	j	800002fe <consoleintr+0x3c>

0000000080000454 <consoleinit>:

void
consoleinit(void)
{
    80000454:	1141                	addi	sp,sp,-16
    80000456:	e406                	sd	ra,8(sp)
    80000458:	e022                	sd	s0,0(sp)
    8000045a:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    8000045c:	00008597          	auipc	a1,0x8
    80000460:	bb458593          	addi	a1,a1,-1100 # 80008010 <etext+0x10>
    80000464:	00011517          	auipc	a0,0x11
    80000468:	3cc50513          	addi	a0,a0,972 # 80011830 <cons>
    8000046c:	00000097          	auipc	ra,0x0
    80000470:	766080e7          	jalr	1894(ra) # 80000bd2 <initlock>

  uartinit();
    80000474:	00000097          	auipc	ra,0x0
    80000478:	38e080e7          	jalr	910(ra) # 80000802 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    8000047c:	00026797          	auipc	a5,0x26
    80000480:	d3478793          	addi	a5,a5,-716 # 800261b0 <devsw>
    80000484:	00000717          	auipc	a4,0x0
    80000488:	cea70713          	addi	a4,a4,-790 # 8000016e <consoleread>
    8000048c:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048e:	00000717          	auipc	a4,0x0
    80000492:	c5e70713          	addi	a4,a4,-930 # 800000ec <consolewrite>
    80000496:	ef98                	sd	a4,24(a5)
}
    80000498:	60a2                	ld	ra,8(sp)
    8000049a:	6402                	ld	s0,0(sp)
    8000049c:	0141                	addi	sp,sp,16
    8000049e:	8082                	ret

00000000800004a0 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    800004a0:	7179                	addi	sp,sp,-48
    800004a2:	f406                	sd	ra,40(sp)
    800004a4:	f022                	sd	s0,32(sp)
    800004a6:	ec26                	sd	s1,24(sp)
    800004a8:	e84a                	sd	s2,16(sp)
    800004aa:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004ac:	c219                	beqz	a2,800004b2 <printint+0x12>
    800004ae:	08054663          	bltz	a0,8000053a <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004b2:	2501                	sext.w	a0,a0
    800004b4:	4881                	li	a7,0
    800004b6:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004ba:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004bc:	2581                	sext.w	a1,a1
    800004be:	00008617          	auipc	a2,0x8
    800004c2:	b9a60613          	addi	a2,a2,-1126 # 80008058 <digits>
    800004c6:	883a                	mv	a6,a4
    800004c8:	2705                	addiw	a4,a4,1
    800004ca:	02b577bb          	remuw	a5,a0,a1
    800004ce:	1782                	slli	a5,a5,0x20
    800004d0:	9381                	srli	a5,a5,0x20
    800004d2:	97b2                	add	a5,a5,a2
    800004d4:	0007c783          	lbu	a5,0(a5)
    800004d8:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004dc:	0005079b          	sext.w	a5,a0
    800004e0:	02b5553b          	divuw	a0,a0,a1
    800004e4:	0685                	addi	a3,a3,1
    800004e6:	feb7f0e3          	bgeu	a5,a1,800004c6 <printint+0x26>

  if(sign)
    800004ea:	00088b63          	beqz	a7,80000500 <printint+0x60>
    buf[i++] = '-';
    800004ee:	fe040793          	addi	a5,s0,-32
    800004f2:	973e                	add	a4,a4,a5
    800004f4:	02d00793          	li	a5,45
    800004f8:	fef70823          	sb	a5,-16(a4)
    800004fc:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    80000500:	02e05763          	blez	a4,8000052e <printint+0x8e>
    80000504:	fd040793          	addi	a5,s0,-48
    80000508:	00e784b3          	add	s1,a5,a4
    8000050c:	fff78913          	addi	s2,a5,-1
    80000510:	993a                	add	s2,s2,a4
    80000512:	377d                	addiw	a4,a4,-1
    80000514:	1702                	slli	a4,a4,0x20
    80000516:	9301                	srli	a4,a4,0x20
    80000518:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000051c:	fff4c503          	lbu	a0,-1(s1)
    80000520:	00000097          	auipc	ra,0x0
    80000524:	d60080e7          	jalr	-672(ra) # 80000280 <consputc>
  while(--i >= 0)
    80000528:	14fd                	addi	s1,s1,-1
    8000052a:	ff2499e3          	bne	s1,s2,8000051c <printint+0x7c>
}
    8000052e:	70a2                	ld	ra,40(sp)
    80000530:	7402                	ld	s0,32(sp)
    80000532:	64e2                	ld	s1,24(sp)
    80000534:	6942                	ld	s2,16(sp)
    80000536:	6145                	addi	sp,sp,48
    80000538:	8082                	ret
    x = -xx;
    8000053a:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053e:	4885                	li	a7,1
    x = -xx;
    80000540:	bf9d                	j	800004b6 <printint+0x16>

0000000080000542 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000542:	1101                	addi	sp,sp,-32
    80000544:	ec06                	sd	ra,24(sp)
    80000546:	e822                	sd	s0,16(sp)
    80000548:	e426                	sd	s1,8(sp)
    8000054a:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    8000054c:	00011497          	auipc	s1,0x11
    80000550:	38c48493          	addi	s1,s1,908 # 800118d8 <pr>
    80000554:	00008597          	auipc	a1,0x8
    80000558:	ac458593          	addi	a1,a1,-1340 # 80008018 <etext+0x18>
    8000055c:	8526                	mv	a0,s1
    8000055e:	00000097          	auipc	ra,0x0
    80000562:	674080e7          	jalr	1652(ra) # 80000bd2 <initlock>
  pr.locking = 1;
    80000566:	4785                	li	a5,1
    80000568:	cc9c                	sw	a5,24(s1)
}
    8000056a:	60e2                	ld	ra,24(sp)
    8000056c:	6442                	ld	s0,16(sp)
    8000056e:	64a2                	ld	s1,8(sp)
    80000570:	6105                	addi	sp,sp,32
    80000572:	8082                	ret

0000000080000574 <backtrace>:

void
backtrace(void)
{
    80000574:	7179                	addi	sp,sp,-48
    80000576:	f406                	sd	ra,40(sp)
    80000578:	f022                	sd	s0,32(sp)
    8000057a:	ec26                	sd	s1,24(sp)
    8000057c:	e84a                	sd	s2,16(sp)
    8000057e:	e44e                	sd	s3,8(sp)
    80000580:	1800                	addi	s0,sp,48
  asm volatile("mv %0, s0" : "=r" (x) );
    80000582:	84a2                	mv	s1,s0
  uint64 fp = r_fp();
  printf("backtrace:\n");
    80000584:	00008517          	auipc	a0,0x8
    80000588:	a9c50513          	addi	a0,a0,-1380 # 80008020 <etext+0x20>
    8000058c:	00000097          	auipc	ra,0x0
    80000590:	096080e7          	jalr	150(ra) # 80000622 <printf>
  uint64 maxvar = PGROUNDUP(fp);
    80000594:	6905                	lui	s2,0x1
    80000596:	197d                	addi	s2,s2,-1
    80000598:	9926                	add	s2,s2,s1
    8000059a:	77fd                	lui	a5,0xfffff
    8000059c:	00f97933          	and	s2,s2,a5
  while(fp < maxvar) {
    800005a0:	0324f163          	bgeu	s1,s2,800005c2 <backtrace+0x4e>
    printf("%p\n", *(uint64*)(fp - 8));
    800005a4:	00008997          	auipc	s3,0x8
    800005a8:	a8c98993          	addi	s3,s3,-1396 # 80008030 <etext+0x30>
    800005ac:	ff84b583          	ld	a1,-8(s1)
    800005b0:	854e                	mv	a0,s3
    800005b2:	00000097          	auipc	ra,0x0
    800005b6:	070080e7          	jalr	112(ra) # 80000622 <printf>
    
    fp = *(uint64*)(fp - 16);
    800005ba:	ff04b483          	ld	s1,-16(s1)
  while(fp < maxvar) {
    800005be:	ff24e7e3          	bltu	s1,s2,800005ac <backtrace+0x38>
  }
}
    800005c2:	70a2                	ld	ra,40(sp)
    800005c4:	7402                	ld	s0,32(sp)
    800005c6:	64e2                	ld	s1,24(sp)
    800005c8:	6942                	ld	s2,16(sp)
    800005ca:	69a2                	ld	s3,8(sp)
    800005cc:	6145                	addi	sp,sp,48
    800005ce:	8082                	ret

00000000800005d0 <panic>:
{
    800005d0:	1101                	addi	sp,sp,-32
    800005d2:	ec06                	sd	ra,24(sp)
    800005d4:	e822                	sd	s0,16(sp)
    800005d6:	e426                	sd	s1,8(sp)
    800005d8:	1000                	addi	s0,sp,32
    800005da:	84aa                	mv	s1,a0
  pr.locking = 0;
    800005dc:	00011797          	auipc	a5,0x11
    800005e0:	3007aa23          	sw	zero,788(a5) # 800118f0 <pr+0x18>
  printf("panic: ");
    800005e4:	00008517          	auipc	a0,0x8
    800005e8:	a5450513          	addi	a0,a0,-1452 # 80008038 <etext+0x38>
    800005ec:	00000097          	auipc	ra,0x0
    800005f0:	036080e7          	jalr	54(ra) # 80000622 <printf>
  printf(s);
    800005f4:	8526                	mv	a0,s1
    800005f6:	00000097          	auipc	ra,0x0
    800005fa:	02c080e7          	jalr	44(ra) # 80000622 <printf>
  printf("\n");
    800005fe:	00008517          	auipc	a0,0x8
    80000602:	ae250513          	addi	a0,a0,-1310 # 800080e0 <digits+0x88>
    80000606:	00000097          	auipc	ra,0x0
    8000060a:	01c080e7          	jalr	28(ra) # 80000622 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000060e:	4785                	li	a5,1
    80000610:	00009717          	auipc	a4,0x9
    80000614:	9ef72823          	sw	a5,-1552(a4) # 80009000 <panicked>
  backtrace();
    80000618:	00000097          	auipc	ra,0x0
    8000061c:	f5c080e7          	jalr	-164(ra) # 80000574 <backtrace>
  for(;;)
    80000620:	a001                	j	80000620 <panic+0x50>

0000000080000622 <printf>:
{
    80000622:	7131                	addi	sp,sp,-192
    80000624:	fc86                	sd	ra,120(sp)
    80000626:	f8a2                	sd	s0,112(sp)
    80000628:	f4a6                	sd	s1,104(sp)
    8000062a:	f0ca                	sd	s2,96(sp)
    8000062c:	ecce                	sd	s3,88(sp)
    8000062e:	e8d2                	sd	s4,80(sp)
    80000630:	e4d6                	sd	s5,72(sp)
    80000632:	e0da                	sd	s6,64(sp)
    80000634:	fc5e                	sd	s7,56(sp)
    80000636:	f862                	sd	s8,48(sp)
    80000638:	f466                	sd	s9,40(sp)
    8000063a:	f06a                	sd	s10,32(sp)
    8000063c:	ec6e                	sd	s11,24(sp)
    8000063e:	0100                	addi	s0,sp,128
    80000640:	8a2a                	mv	s4,a0
    80000642:	e40c                	sd	a1,8(s0)
    80000644:	e810                	sd	a2,16(s0)
    80000646:	ec14                	sd	a3,24(s0)
    80000648:	f018                	sd	a4,32(s0)
    8000064a:	f41c                	sd	a5,40(s0)
    8000064c:	03043823          	sd	a6,48(s0)
    80000650:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    80000654:	00011d97          	auipc	s11,0x11
    80000658:	29cdad83          	lw	s11,668(s11) # 800118f0 <pr+0x18>
  if(locking)
    8000065c:	020d9b63          	bnez	s11,80000692 <printf+0x70>
  if (fmt == 0)
    80000660:	040a0263          	beqz	s4,800006a4 <printf+0x82>
  va_start(ap, fmt);
    80000664:	00840793          	addi	a5,s0,8
    80000668:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    8000066c:	000a4503          	lbu	a0,0(s4)
    80000670:	14050f63          	beqz	a0,800007ce <printf+0x1ac>
    80000674:	4981                	li	s3,0
    if(c != '%'){
    80000676:	02500a93          	li	s5,37
    switch(c){
    8000067a:	07000b93          	li	s7,112
  consputc('x');
    8000067e:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    80000680:	00008b17          	auipc	s6,0x8
    80000684:	9d8b0b13          	addi	s6,s6,-1576 # 80008058 <digits>
    switch(c){
    80000688:	07300c93          	li	s9,115
    8000068c:	06400c13          	li	s8,100
    80000690:	a82d                	j	800006ca <printf+0xa8>
    acquire(&pr.lock);
    80000692:	00011517          	auipc	a0,0x11
    80000696:	24650513          	addi	a0,a0,582 # 800118d8 <pr>
    8000069a:	00000097          	auipc	ra,0x0
    8000069e:	5c8080e7          	jalr	1480(ra) # 80000c62 <acquire>
    800006a2:	bf7d                	j	80000660 <printf+0x3e>
    panic("null fmt");
    800006a4:	00008517          	auipc	a0,0x8
    800006a8:	9a450513          	addi	a0,a0,-1628 # 80008048 <etext+0x48>
    800006ac:	00000097          	auipc	ra,0x0
    800006b0:	f24080e7          	jalr	-220(ra) # 800005d0 <panic>
      consputc(c);
    800006b4:	00000097          	auipc	ra,0x0
    800006b8:	bcc080e7          	jalr	-1076(ra) # 80000280 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800006bc:	2985                	addiw	s3,s3,1
    800006be:	013a07b3          	add	a5,s4,s3
    800006c2:	0007c503          	lbu	a0,0(a5)
    800006c6:	10050463          	beqz	a0,800007ce <printf+0x1ac>
    if(c != '%'){
    800006ca:	ff5515e3          	bne	a0,s5,800006b4 <printf+0x92>
    c = fmt[++i] & 0xff;
    800006ce:	2985                	addiw	s3,s3,1
    800006d0:	013a07b3          	add	a5,s4,s3
    800006d4:	0007c783          	lbu	a5,0(a5)
    800006d8:	0007849b          	sext.w	s1,a5
    if(c == 0)
    800006dc:	cbed                	beqz	a5,800007ce <printf+0x1ac>
    switch(c){
    800006de:	05778a63          	beq	a5,s7,80000732 <printf+0x110>
    800006e2:	02fbf663          	bgeu	s7,a5,8000070e <printf+0xec>
    800006e6:	09978863          	beq	a5,s9,80000776 <printf+0x154>
    800006ea:	07800713          	li	a4,120
    800006ee:	0ce79563          	bne	a5,a4,800007b8 <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    800006f2:	f8843783          	ld	a5,-120(s0)
    800006f6:	00878713          	addi	a4,a5,8
    800006fa:	f8e43423          	sd	a4,-120(s0)
    800006fe:	4605                	li	a2,1
    80000700:	85ea                	mv	a1,s10
    80000702:	4388                	lw	a0,0(a5)
    80000704:	00000097          	auipc	ra,0x0
    80000708:	d9c080e7          	jalr	-612(ra) # 800004a0 <printint>
      break;
    8000070c:	bf45                	j	800006bc <printf+0x9a>
    switch(c){
    8000070e:	09578f63          	beq	a5,s5,800007ac <printf+0x18a>
    80000712:	0b879363          	bne	a5,s8,800007b8 <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    80000716:	f8843783          	ld	a5,-120(s0)
    8000071a:	00878713          	addi	a4,a5,8
    8000071e:	f8e43423          	sd	a4,-120(s0)
    80000722:	4605                	li	a2,1
    80000724:	45a9                	li	a1,10
    80000726:	4388                	lw	a0,0(a5)
    80000728:	00000097          	auipc	ra,0x0
    8000072c:	d78080e7          	jalr	-648(ra) # 800004a0 <printint>
      break;
    80000730:	b771                	j	800006bc <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000732:	f8843783          	ld	a5,-120(s0)
    80000736:	00878713          	addi	a4,a5,8
    8000073a:	f8e43423          	sd	a4,-120(s0)
    8000073e:	0007b903          	ld	s2,0(a5)
  consputc('0');
    80000742:	03000513          	li	a0,48
    80000746:	00000097          	auipc	ra,0x0
    8000074a:	b3a080e7          	jalr	-1222(ra) # 80000280 <consputc>
  consputc('x');
    8000074e:	07800513          	li	a0,120
    80000752:	00000097          	auipc	ra,0x0
    80000756:	b2e080e7          	jalr	-1234(ra) # 80000280 <consputc>
    8000075a:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    8000075c:	03c95793          	srli	a5,s2,0x3c
    80000760:	97da                	add	a5,a5,s6
    80000762:	0007c503          	lbu	a0,0(a5)
    80000766:	00000097          	auipc	ra,0x0
    8000076a:	b1a080e7          	jalr	-1254(ra) # 80000280 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    8000076e:	0912                	slli	s2,s2,0x4
    80000770:	34fd                	addiw	s1,s1,-1
    80000772:	f4ed                	bnez	s1,8000075c <printf+0x13a>
    80000774:	b7a1                	j	800006bc <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    80000776:	f8843783          	ld	a5,-120(s0)
    8000077a:	00878713          	addi	a4,a5,8
    8000077e:	f8e43423          	sd	a4,-120(s0)
    80000782:	6384                	ld	s1,0(a5)
    80000784:	cc89                	beqz	s1,8000079e <printf+0x17c>
      for(; *s; s++)
    80000786:	0004c503          	lbu	a0,0(s1)
    8000078a:	d90d                	beqz	a0,800006bc <printf+0x9a>
        consputc(*s);
    8000078c:	00000097          	auipc	ra,0x0
    80000790:	af4080e7          	jalr	-1292(ra) # 80000280 <consputc>
      for(; *s; s++)
    80000794:	0485                	addi	s1,s1,1
    80000796:	0004c503          	lbu	a0,0(s1)
    8000079a:	f96d                	bnez	a0,8000078c <printf+0x16a>
    8000079c:	b705                	j	800006bc <printf+0x9a>
        s = "(null)";
    8000079e:	00008497          	auipc	s1,0x8
    800007a2:	8a248493          	addi	s1,s1,-1886 # 80008040 <etext+0x40>
      for(; *s; s++)
    800007a6:	02800513          	li	a0,40
    800007aa:	b7cd                	j	8000078c <printf+0x16a>
      consputc('%');
    800007ac:	8556                	mv	a0,s5
    800007ae:	00000097          	auipc	ra,0x0
    800007b2:	ad2080e7          	jalr	-1326(ra) # 80000280 <consputc>
      break;
    800007b6:	b719                	j	800006bc <printf+0x9a>
      consputc('%');
    800007b8:	8556                	mv	a0,s5
    800007ba:	00000097          	auipc	ra,0x0
    800007be:	ac6080e7          	jalr	-1338(ra) # 80000280 <consputc>
      consputc(c);
    800007c2:	8526                	mv	a0,s1
    800007c4:	00000097          	auipc	ra,0x0
    800007c8:	abc080e7          	jalr	-1348(ra) # 80000280 <consputc>
      break;
    800007cc:	bdc5                	j	800006bc <printf+0x9a>
  if(locking)
    800007ce:	020d9163          	bnez	s11,800007f0 <printf+0x1ce>
}
    800007d2:	70e6                	ld	ra,120(sp)
    800007d4:	7446                	ld	s0,112(sp)
    800007d6:	74a6                	ld	s1,104(sp)
    800007d8:	7906                	ld	s2,96(sp)
    800007da:	69e6                	ld	s3,88(sp)
    800007dc:	6a46                	ld	s4,80(sp)
    800007de:	6aa6                	ld	s5,72(sp)
    800007e0:	6b06                	ld	s6,64(sp)
    800007e2:	7be2                	ld	s7,56(sp)
    800007e4:	7c42                	ld	s8,48(sp)
    800007e6:	7ca2                	ld	s9,40(sp)
    800007e8:	7d02                	ld	s10,32(sp)
    800007ea:	6de2                	ld	s11,24(sp)
    800007ec:	6129                	addi	sp,sp,192
    800007ee:	8082                	ret
    release(&pr.lock);
    800007f0:	00011517          	auipc	a0,0x11
    800007f4:	0e850513          	addi	a0,a0,232 # 800118d8 <pr>
    800007f8:	00000097          	auipc	ra,0x0
    800007fc:	51e080e7          	jalr	1310(ra) # 80000d16 <release>
}
    80000800:	bfc9                	j	800007d2 <printf+0x1b0>

0000000080000802 <uartinit>:

void uartstart();

void
uartinit(void)
{
    80000802:	1141                	addi	sp,sp,-16
    80000804:	e406                	sd	ra,8(sp)
    80000806:	e022                	sd	s0,0(sp)
    80000808:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    8000080a:	100007b7          	lui	a5,0x10000
    8000080e:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    80000812:	f8000713          	li	a4,-128
    80000816:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    8000081a:	470d                	li	a4,3
    8000081c:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    80000820:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    80000824:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    80000828:	469d                	li	a3,7
    8000082a:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    8000082e:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    80000832:	00008597          	auipc	a1,0x8
    80000836:	83e58593          	addi	a1,a1,-1986 # 80008070 <digits+0x18>
    8000083a:	00011517          	auipc	a0,0x11
    8000083e:	0be50513          	addi	a0,a0,190 # 800118f8 <uart_tx_lock>
    80000842:	00000097          	auipc	ra,0x0
    80000846:	390080e7          	jalr	912(ra) # 80000bd2 <initlock>
}
    8000084a:	60a2                	ld	ra,8(sp)
    8000084c:	6402                	ld	s0,0(sp)
    8000084e:	0141                	addi	sp,sp,16
    80000850:	8082                	ret

0000000080000852 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    80000852:	1101                	addi	sp,sp,-32
    80000854:	ec06                	sd	ra,24(sp)
    80000856:	e822                	sd	s0,16(sp)
    80000858:	e426                	sd	s1,8(sp)
    8000085a:	1000                	addi	s0,sp,32
    8000085c:	84aa                	mv	s1,a0
  push_off();
    8000085e:	00000097          	auipc	ra,0x0
    80000862:	3b8080e7          	jalr	952(ra) # 80000c16 <push_off>

  if(panicked){
    80000866:	00008797          	auipc	a5,0x8
    8000086a:	79a7a783          	lw	a5,1946(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000086e:	10000737          	lui	a4,0x10000
  if(panicked){
    80000872:	c391                	beqz	a5,80000876 <uartputc_sync+0x24>
    for(;;)
    80000874:	a001                	j	80000874 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000876:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    8000087a:	0207f793          	andi	a5,a5,32
    8000087e:	dfe5                	beqz	a5,80000876 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000880:	0ff4f513          	andi	a0,s1,255
    80000884:	100007b7          	lui	a5,0x10000
    80000888:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    8000088c:	00000097          	auipc	ra,0x0
    80000890:	42a080e7          	jalr	1066(ra) # 80000cb6 <pop_off>
}
    80000894:	60e2                	ld	ra,24(sp)
    80000896:	6442                	ld	s0,16(sp)
    80000898:	64a2                	ld	s1,8(sp)
    8000089a:	6105                	addi	sp,sp,32
    8000089c:	8082                	ret

000000008000089e <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    8000089e:	00008797          	auipc	a5,0x8
    800008a2:	7667a783          	lw	a5,1894(a5) # 80009004 <uart_tx_r>
    800008a6:	00008717          	auipc	a4,0x8
    800008aa:	76272703          	lw	a4,1890(a4) # 80009008 <uart_tx_w>
    800008ae:	08f70063          	beq	a4,a5,8000092e <uartstart+0x90>
{
    800008b2:	7139                	addi	sp,sp,-64
    800008b4:	fc06                	sd	ra,56(sp)
    800008b6:	f822                	sd	s0,48(sp)
    800008b8:	f426                	sd	s1,40(sp)
    800008ba:	f04a                	sd	s2,32(sp)
    800008bc:	ec4e                	sd	s3,24(sp)
    800008be:	e852                	sd	s4,16(sp)
    800008c0:	e456                	sd	s5,8(sp)
    800008c2:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    800008c4:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r];
    800008c8:	00011a97          	auipc	s5,0x11
    800008cc:	030a8a93          	addi	s5,s5,48 # 800118f8 <uart_tx_lock>
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    800008d0:	00008497          	auipc	s1,0x8
    800008d4:	73448493          	addi	s1,s1,1844 # 80009004 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    800008d8:	00008a17          	auipc	s4,0x8
    800008dc:	730a0a13          	addi	s4,s4,1840 # 80009008 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    800008e0:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    800008e4:	02077713          	andi	a4,a4,32
    800008e8:	cb15                	beqz	a4,8000091c <uartstart+0x7e>
    int c = uart_tx_buf[uart_tx_r];
    800008ea:	00fa8733          	add	a4,s5,a5
    800008ee:	01874983          	lbu	s3,24(a4)
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    800008f2:	2785                	addiw	a5,a5,1
    800008f4:	41f7d71b          	sraiw	a4,a5,0x1f
    800008f8:	01b7571b          	srliw	a4,a4,0x1b
    800008fc:	9fb9                	addw	a5,a5,a4
    800008fe:	8bfd                	andi	a5,a5,31
    80000900:	9f99                	subw	a5,a5,a4
    80000902:	c09c                	sw	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    80000904:	8526                	mv	a0,s1
    80000906:	00002097          	auipc	ra,0x2
    8000090a:	acc080e7          	jalr	-1332(ra) # 800023d2 <wakeup>
    
    WriteReg(THR, c);
    8000090e:	01390023          	sb	s3,0(s2)
    if(uart_tx_w == uart_tx_r){
    80000912:	409c                	lw	a5,0(s1)
    80000914:	000a2703          	lw	a4,0(s4)
    80000918:	fcf714e3          	bne	a4,a5,800008e0 <uartstart+0x42>
  }
}
    8000091c:	70e2                	ld	ra,56(sp)
    8000091e:	7442                	ld	s0,48(sp)
    80000920:	74a2                	ld	s1,40(sp)
    80000922:	7902                	ld	s2,32(sp)
    80000924:	69e2                	ld	s3,24(sp)
    80000926:	6a42                	ld	s4,16(sp)
    80000928:	6aa2                	ld	s5,8(sp)
    8000092a:	6121                	addi	sp,sp,64
    8000092c:	8082                	ret
    8000092e:	8082                	ret

0000000080000930 <uartputc>:
{
    80000930:	7179                	addi	sp,sp,-48
    80000932:	f406                	sd	ra,40(sp)
    80000934:	f022                	sd	s0,32(sp)
    80000936:	ec26                	sd	s1,24(sp)
    80000938:	e84a                	sd	s2,16(sp)
    8000093a:	e44e                	sd	s3,8(sp)
    8000093c:	e052                	sd	s4,0(sp)
    8000093e:	1800                	addi	s0,sp,48
    80000940:	84aa                	mv	s1,a0
  acquire(&uart_tx_lock);
    80000942:	00011517          	auipc	a0,0x11
    80000946:	fb650513          	addi	a0,a0,-74 # 800118f8 <uart_tx_lock>
    8000094a:	00000097          	auipc	ra,0x0
    8000094e:	318080e7          	jalr	792(ra) # 80000c62 <acquire>
  if(panicked){
    80000952:	00008797          	auipc	a5,0x8
    80000956:	6ae7a783          	lw	a5,1710(a5) # 80009000 <panicked>
    8000095a:	c391                	beqz	a5,8000095e <uartputc+0x2e>
    for(;;)
    8000095c:	a001                	j	8000095c <uartputc+0x2c>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    8000095e:	00008697          	auipc	a3,0x8
    80000962:	6aa6a683          	lw	a3,1706(a3) # 80009008 <uart_tx_w>
    80000966:	0016879b          	addiw	a5,a3,1
    8000096a:	41f7d71b          	sraiw	a4,a5,0x1f
    8000096e:	01b7571b          	srliw	a4,a4,0x1b
    80000972:	9fb9                	addw	a5,a5,a4
    80000974:	8bfd                	andi	a5,a5,31
    80000976:	9f99                	subw	a5,a5,a4
    80000978:	00008717          	auipc	a4,0x8
    8000097c:	68c72703          	lw	a4,1676(a4) # 80009004 <uart_tx_r>
    80000980:	04f71363          	bne	a4,a5,800009c6 <uartputc+0x96>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000984:	00011a17          	auipc	s4,0x11
    80000988:	f74a0a13          	addi	s4,s4,-140 # 800118f8 <uart_tx_lock>
    8000098c:	00008917          	auipc	s2,0x8
    80000990:	67890913          	addi	s2,s2,1656 # 80009004 <uart_tx_r>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000994:	00008997          	auipc	s3,0x8
    80000998:	67498993          	addi	s3,s3,1652 # 80009008 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    8000099c:	85d2                	mv	a1,s4
    8000099e:	854a                	mv	a0,s2
    800009a0:	00002097          	auipc	ra,0x2
    800009a4:	8b2080e7          	jalr	-1870(ra) # 80002252 <sleep>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    800009a8:	0009a683          	lw	a3,0(s3)
    800009ac:	0016879b          	addiw	a5,a3,1
    800009b0:	41f7d71b          	sraiw	a4,a5,0x1f
    800009b4:	01b7571b          	srliw	a4,a4,0x1b
    800009b8:	9fb9                	addw	a5,a5,a4
    800009ba:	8bfd                	andi	a5,a5,31
    800009bc:	9f99                	subw	a5,a5,a4
    800009be:	00092703          	lw	a4,0(s2)
    800009c2:	fcf70de3          	beq	a4,a5,8000099c <uartputc+0x6c>
      uart_tx_buf[uart_tx_w] = c;
    800009c6:	00011917          	auipc	s2,0x11
    800009ca:	f3290913          	addi	s2,s2,-206 # 800118f8 <uart_tx_lock>
    800009ce:	96ca                	add	a3,a3,s2
    800009d0:	00968c23          	sb	s1,24(a3)
      uart_tx_w = (uart_tx_w + 1) % UART_TX_BUF_SIZE;
    800009d4:	00008717          	auipc	a4,0x8
    800009d8:	62f72a23          	sw	a5,1588(a4) # 80009008 <uart_tx_w>
      uartstart();
    800009dc:	00000097          	auipc	ra,0x0
    800009e0:	ec2080e7          	jalr	-318(ra) # 8000089e <uartstart>
      release(&uart_tx_lock);
    800009e4:	854a                	mv	a0,s2
    800009e6:	00000097          	auipc	ra,0x0
    800009ea:	330080e7          	jalr	816(ra) # 80000d16 <release>
}
    800009ee:	70a2                	ld	ra,40(sp)
    800009f0:	7402                	ld	s0,32(sp)
    800009f2:	64e2                	ld	s1,24(sp)
    800009f4:	6942                	ld	s2,16(sp)
    800009f6:	69a2                	ld	s3,8(sp)
    800009f8:	6a02                	ld	s4,0(sp)
    800009fa:	6145                	addi	sp,sp,48
    800009fc:	8082                	ret

00000000800009fe <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    800009fe:	1141                	addi	sp,sp,-16
    80000a00:	e422                	sd	s0,8(sp)
    80000a02:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000a04:	100007b7          	lui	a5,0x10000
    80000a08:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000a0c:	8b85                	andi	a5,a5,1
    80000a0e:	cb91                	beqz	a5,80000a22 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000a10:	100007b7          	lui	a5,0x10000
    80000a14:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    80000a18:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    80000a1c:	6422                	ld	s0,8(sp)
    80000a1e:	0141                	addi	sp,sp,16
    80000a20:	8082                	ret
    return -1;
    80000a22:	557d                	li	a0,-1
    80000a24:	bfe5                	j	80000a1c <uartgetc+0x1e>

0000000080000a26 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    80000a26:	1101                	addi	sp,sp,-32
    80000a28:	ec06                	sd	ra,24(sp)
    80000a2a:	e822                	sd	s0,16(sp)
    80000a2c:	e426                	sd	s1,8(sp)
    80000a2e:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    80000a30:	54fd                	li	s1,-1
    80000a32:	a029                	j	80000a3c <uartintr+0x16>
      break;
    consoleintr(c);
    80000a34:	00000097          	auipc	ra,0x0
    80000a38:	88e080e7          	jalr	-1906(ra) # 800002c2 <consoleintr>
    int c = uartgetc();
    80000a3c:	00000097          	auipc	ra,0x0
    80000a40:	fc2080e7          	jalr	-62(ra) # 800009fe <uartgetc>
    if(c == -1)
    80000a44:	fe9518e3          	bne	a0,s1,80000a34 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    80000a48:	00011497          	auipc	s1,0x11
    80000a4c:	eb048493          	addi	s1,s1,-336 # 800118f8 <uart_tx_lock>
    80000a50:	8526                	mv	a0,s1
    80000a52:	00000097          	auipc	ra,0x0
    80000a56:	210080e7          	jalr	528(ra) # 80000c62 <acquire>
  uartstart();
    80000a5a:	00000097          	auipc	ra,0x0
    80000a5e:	e44080e7          	jalr	-444(ra) # 8000089e <uartstart>
  release(&uart_tx_lock);
    80000a62:	8526                	mv	a0,s1
    80000a64:	00000097          	auipc	ra,0x0
    80000a68:	2b2080e7          	jalr	690(ra) # 80000d16 <release>
}
    80000a6c:	60e2                	ld	ra,24(sp)
    80000a6e:	6442                	ld	s0,16(sp)
    80000a70:	64a2                	ld	s1,8(sp)
    80000a72:	6105                	addi	sp,sp,32
    80000a74:	8082                	ret

0000000080000a76 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000a76:	1101                	addi	sp,sp,-32
    80000a78:	ec06                	sd	ra,24(sp)
    80000a7a:	e822                	sd	s0,16(sp)
    80000a7c:	e426                	sd	s1,8(sp)
    80000a7e:	e04a                	sd	s2,0(sp)
    80000a80:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a82:	03451793          	slli	a5,a0,0x34
    80000a86:	ebb9                	bnez	a5,80000adc <kfree+0x66>
    80000a88:	84aa                	mv	s1,a0
    80000a8a:	0002a797          	auipc	a5,0x2a
    80000a8e:	57678793          	addi	a5,a5,1398 # 8002b000 <end>
    80000a92:	04f56563          	bltu	a0,a5,80000adc <kfree+0x66>
    80000a96:	47c5                	li	a5,17
    80000a98:	07ee                	slli	a5,a5,0x1b
    80000a9a:	04f57163          	bgeu	a0,a5,80000adc <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a9e:	6605                	lui	a2,0x1
    80000aa0:	4585                	li	a1,1
    80000aa2:	00000097          	auipc	ra,0x0
    80000aa6:	2bc080e7          	jalr	700(ra) # 80000d5e <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000aaa:	00011917          	auipc	s2,0x11
    80000aae:	e8690913          	addi	s2,s2,-378 # 80011930 <kmem>
    80000ab2:	854a                	mv	a0,s2
    80000ab4:	00000097          	auipc	ra,0x0
    80000ab8:	1ae080e7          	jalr	430(ra) # 80000c62 <acquire>
  r->next = kmem.freelist;
    80000abc:	01893783          	ld	a5,24(s2)
    80000ac0:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000ac2:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000ac6:	854a                	mv	a0,s2
    80000ac8:	00000097          	auipc	ra,0x0
    80000acc:	24e080e7          	jalr	590(ra) # 80000d16 <release>
}
    80000ad0:	60e2                	ld	ra,24(sp)
    80000ad2:	6442                	ld	s0,16(sp)
    80000ad4:	64a2                	ld	s1,8(sp)
    80000ad6:	6902                	ld	s2,0(sp)
    80000ad8:	6105                	addi	sp,sp,32
    80000ada:	8082                	ret
    panic("kfree");
    80000adc:	00007517          	auipc	a0,0x7
    80000ae0:	59c50513          	addi	a0,a0,1436 # 80008078 <digits+0x20>
    80000ae4:	00000097          	auipc	ra,0x0
    80000ae8:	aec080e7          	jalr	-1300(ra) # 800005d0 <panic>

0000000080000aec <freerange>:
{
    80000aec:	7179                	addi	sp,sp,-48
    80000aee:	f406                	sd	ra,40(sp)
    80000af0:	f022                	sd	s0,32(sp)
    80000af2:	ec26                	sd	s1,24(sp)
    80000af4:	e84a                	sd	s2,16(sp)
    80000af6:	e44e                	sd	s3,8(sp)
    80000af8:	e052                	sd	s4,0(sp)
    80000afa:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000afc:	6785                	lui	a5,0x1
    80000afe:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000b02:	94aa                	add	s1,s1,a0
    80000b04:	757d                	lui	a0,0xfffff
    80000b06:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000b08:	94be                	add	s1,s1,a5
    80000b0a:	0095ee63          	bltu	a1,s1,80000b26 <freerange+0x3a>
    80000b0e:	892e                	mv	s2,a1
    kfree(p);
    80000b10:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000b12:	6985                	lui	s3,0x1
    kfree(p);
    80000b14:	01448533          	add	a0,s1,s4
    80000b18:	00000097          	auipc	ra,0x0
    80000b1c:	f5e080e7          	jalr	-162(ra) # 80000a76 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000b20:	94ce                	add	s1,s1,s3
    80000b22:	fe9979e3          	bgeu	s2,s1,80000b14 <freerange+0x28>
}
    80000b26:	70a2                	ld	ra,40(sp)
    80000b28:	7402                	ld	s0,32(sp)
    80000b2a:	64e2                	ld	s1,24(sp)
    80000b2c:	6942                	ld	s2,16(sp)
    80000b2e:	69a2                	ld	s3,8(sp)
    80000b30:	6a02                	ld	s4,0(sp)
    80000b32:	6145                	addi	sp,sp,48
    80000b34:	8082                	ret

0000000080000b36 <kinit>:
{
    80000b36:	1141                	addi	sp,sp,-16
    80000b38:	e406                	sd	ra,8(sp)
    80000b3a:	e022                	sd	s0,0(sp)
    80000b3c:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000b3e:	00007597          	auipc	a1,0x7
    80000b42:	54258593          	addi	a1,a1,1346 # 80008080 <digits+0x28>
    80000b46:	00011517          	auipc	a0,0x11
    80000b4a:	dea50513          	addi	a0,a0,-534 # 80011930 <kmem>
    80000b4e:	00000097          	auipc	ra,0x0
    80000b52:	084080e7          	jalr	132(ra) # 80000bd2 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000b56:	45c5                	li	a1,17
    80000b58:	05ee                	slli	a1,a1,0x1b
    80000b5a:	0002a517          	auipc	a0,0x2a
    80000b5e:	4a650513          	addi	a0,a0,1190 # 8002b000 <end>
    80000b62:	00000097          	auipc	ra,0x0
    80000b66:	f8a080e7          	jalr	-118(ra) # 80000aec <freerange>
}
    80000b6a:	60a2                	ld	ra,8(sp)
    80000b6c:	6402                	ld	s0,0(sp)
    80000b6e:	0141                	addi	sp,sp,16
    80000b70:	8082                	ret

0000000080000b72 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000b72:	1101                	addi	sp,sp,-32
    80000b74:	ec06                	sd	ra,24(sp)
    80000b76:	e822                	sd	s0,16(sp)
    80000b78:	e426                	sd	s1,8(sp)
    80000b7a:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b7c:	00011497          	auipc	s1,0x11
    80000b80:	db448493          	addi	s1,s1,-588 # 80011930 <kmem>
    80000b84:	8526                	mv	a0,s1
    80000b86:	00000097          	auipc	ra,0x0
    80000b8a:	0dc080e7          	jalr	220(ra) # 80000c62 <acquire>
  r = kmem.freelist;
    80000b8e:	6c84                	ld	s1,24(s1)
  if(r)
    80000b90:	c885                	beqz	s1,80000bc0 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b92:	609c                	ld	a5,0(s1)
    80000b94:	00011517          	auipc	a0,0x11
    80000b98:	d9c50513          	addi	a0,a0,-612 # 80011930 <kmem>
    80000b9c:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b9e:	00000097          	auipc	ra,0x0
    80000ba2:	178080e7          	jalr	376(ra) # 80000d16 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000ba6:	6605                	lui	a2,0x1
    80000ba8:	4595                	li	a1,5
    80000baa:	8526                	mv	a0,s1
    80000bac:	00000097          	auipc	ra,0x0
    80000bb0:	1b2080e7          	jalr	434(ra) # 80000d5e <memset>
  return (void*)r;
}
    80000bb4:	8526                	mv	a0,s1
    80000bb6:	60e2                	ld	ra,24(sp)
    80000bb8:	6442                	ld	s0,16(sp)
    80000bba:	64a2                	ld	s1,8(sp)
    80000bbc:	6105                	addi	sp,sp,32
    80000bbe:	8082                	ret
  release(&kmem.lock);
    80000bc0:	00011517          	auipc	a0,0x11
    80000bc4:	d7050513          	addi	a0,a0,-656 # 80011930 <kmem>
    80000bc8:	00000097          	auipc	ra,0x0
    80000bcc:	14e080e7          	jalr	334(ra) # 80000d16 <release>
  if(r)
    80000bd0:	b7d5                	j	80000bb4 <kalloc+0x42>

0000000080000bd2 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000bd2:	1141                	addi	sp,sp,-16
    80000bd4:	e422                	sd	s0,8(sp)
    80000bd6:	0800                	addi	s0,sp,16
  lk->name = name;
    80000bd8:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000bda:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000bde:	00053823          	sd	zero,16(a0)
}
    80000be2:	6422                	ld	s0,8(sp)
    80000be4:	0141                	addi	sp,sp,16
    80000be6:	8082                	ret

0000000080000be8 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000be8:	411c                	lw	a5,0(a0)
    80000bea:	e399                	bnez	a5,80000bf0 <holding+0x8>
    80000bec:	4501                	li	a0,0
  return r;
}
    80000bee:	8082                	ret
{
    80000bf0:	1101                	addi	sp,sp,-32
    80000bf2:	ec06                	sd	ra,24(sp)
    80000bf4:	e822                	sd	s0,16(sp)
    80000bf6:	e426                	sd	s1,8(sp)
    80000bf8:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000bfa:	6904                	ld	s1,16(a0)
    80000bfc:	00001097          	auipc	ra,0x1
    80000c00:	e16080e7          	jalr	-490(ra) # 80001a12 <mycpu>
    80000c04:	40a48533          	sub	a0,s1,a0
    80000c08:	00153513          	seqz	a0,a0
}
    80000c0c:	60e2                	ld	ra,24(sp)
    80000c0e:	6442                	ld	s0,16(sp)
    80000c10:	64a2                	ld	s1,8(sp)
    80000c12:	6105                	addi	sp,sp,32
    80000c14:	8082                	ret

0000000080000c16 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000c16:	1101                	addi	sp,sp,-32
    80000c18:	ec06                	sd	ra,24(sp)
    80000c1a:	e822                	sd	s0,16(sp)
    80000c1c:	e426                	sd	s1,8(sp)
    80000c1e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c20:	100024f3          	csrr	s1,sstatus
    80000c24:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000c28:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c2a:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000c2e:	00001097          	auipc	ra,0x1
    80000c32:	de4080e7          	jalr	-540(ra) # 80001a12 <mycpu>
    80000c36:	5d3c                	lw	a5,120(a0)
    80000c38:	cf89                	beqz	a5,80000c52 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000c3a:	00001097          	auipc	ra,0x1
    80000c3e:	dd8080e7          	jalr	-552(ra) # 80001a12 <mycpu>
    80000c42:	5d3c                	lw	a5,120(a0)
    80000c44:	2785                	addiw	a5,a5,1
    80000c46:	dd3c                	sw	a5,120(a0)
}
    80000c48:	60e2                	ld	ra,24(sp)
    80000c4a:	6442                	ld	s0,16(sp)
    80000c4c:	64a2                	ld	s1,8(sp)
    80000c4e:	6105                	addi	sp,sp,32
    80000c50:	8082                	ret
    mycpu()->intena = old;
    80000c52:	00001097          	auipc	ra,0x1
    80000c56:	dc0080e7          	jalr	-576(ra) # 80001a12 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000c5a:	8085                	srli	s1,s1,0x1
    80000c5c:	8885                	andi	s1,s1,1
    80000c5e:	dd64                	sw	s1,124(a0)
    80000c60:	bfe9                	j	80000c3a <push_off+0x24>

0000000080000c62 <acquire>:
{
    80000c62:	1101                	addi	sp,sp,-32
    80000c64:	ec06                	sd	ra,24(sp)
    80000c66:	e822                	sd	s0,16(sp)
    80000c68:	e426                	sd	s1,8(sp)
    80000c6a:	1000                	addi	s0,sp,32
    80000c6c:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000c6e:	00000097          	auipc	ra,0x0
    80000c72:	fa8080e7          	jalr	-88(ra) # 80000c16 <push_off>
  if(holding(lk))
    80000c76:	8526                	mv	a0,s1
    80000c78:	00000097          	auipc	ra,0x0
    80000c7c:	f70080e7          	jalr	-144(ra) # 80000be8 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c80:	4705                	li	a4,1
  if(holding(lk))
    80000c82:	e115                	bnez	a0,80000ca6 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c84:	87ba                	mv	a5,a4
    80000c86:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c8a:	2781                	sext.w	a5,a5
    80000c8c:	ffe5                	bnez	a5,80000c84 <acquire+0x22>
  __sync_synchronize();
    80000c8e:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c92:	00001097          	auipc	ra,0x1
    80000c96:	d80080e7          	jalr	-640(ra) # 80001a12 <mycpu>
    80000c9a:	e888                	sd	a0,16(s1)
}
    80000c9c:	60e2                	ld	ra,24(sp)
    80000c9e:	6442                	ld	s0,16(sp)
    80000ca0:	64a2                	ld	s1,8(sp)
    80000ca2:	6105                	addi	sp,sp,32
    80000ca4:	8082                	ret
    panic("acquire");
    80000ca6:	00007517          	auipc	a0,0x7
    80000caa:	3e250513          	addi	a0,a0,994 # 80008088 <digits+0x30>
    80000cae:	00000097          	auipc	ra,0x0
    80000cb2:	922080e7          	jalr	-1758(ra) # 800005d0 <panic>

0000000080000cb6 <pop_off>:

void
pop_off(void)
{
    80000cb6:	1141                	addi	sp,sp,-16
    80000cb8:	e406                	sd	ra,8(sp)
    80000cba:	e022                	sd	s0,0(sp)
    80000cbc:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000cbe:	00001097          	auipc	ra,0x1
    80000cc2:	d54080e7          	jalr	-684(ra) # 80001a12 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000cc6:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000cca:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000ccc:	e78d                	bnez	a5,80000cf6 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000cce:	5d3c                	lw	a5,120(a0)
    80000cd0:	02f05b63          	blez	a5,80000d06 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000cd4:	37fd                	addiw	a5,a5,-1
    80000cd6:	0007871b          	sext.w	a4,a5
    80000cda:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000cdc:	eb09                	bnez	a4,80000cee <pop_off+0x38>
    80000cde:	5d7c                	lw	a5,124(a0)
    80000ce0:	c799                	beqz	a5,80000cee <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000ce2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000ce6:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000cea:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000cee:	60a2                	ld	ra,8(sp)
    80000cf0:	6402                	ld	s0,0(sp)
    80000cf2:	0141                	addi	sp,sp,16
    80000cf4:	8082                	ret
    panic("pop_off - interruptible");
    80000cf6:	00007517          	auipc	a0,0x7
    80000cfa:	39a50513          	addi	a0,a0,922 # 80008090 <digits+0x38>
    80000cfe:	00000097          	auipc	ra,0x0
    80000d02:	8d2080e7          	jalr	-1838(ra) # 800005d0 <panic>
    panic("pop_off");
    80000d06:	00007517          	auipc	a0,0x7
    80000d0a:	3a250513          	addi	a0,a0,930 # 800080a8 <digits+0x50>
    80000d0e:	00000097          	auipc	ra,0x0
    80000d12:	8c2080e7          	jalr	-1854(ra) # 800005d0 <panic>

0000000080000d16 <release>:
{
    80000d16:	1101                	addi	sp,sp,-32
    80000d18:	ec06                	sd	ra,24(sp)
    80000d1a:	e822                	sd	s0,16(sp)
    80000d1c:	e426                	sd	s1,8(sp)
    80000d1e:	1000                	addi	s0,sp,32
    80000d20:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000d22:	00000097          	auipc	ra,0x0
    80000d26:	ec6080e7          	jalr	-314(ra) # 80000be8 <holding>
    80000d2a:	c115                	beqz	a0,80000d4e <release+0x38>
  lk->cpu = 0;
    80000d2c:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000d30:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000d34:	0f50000f          	fence	iorw,ow
    80000d38:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000d3c:	00000097          	auipc	ra,0x0
    80000d40:	f7a080e7          	jalr	-134(ra) # 80000cb6 <pop_off>
}
    80000d44:	60e2                	ld	ra,24(sp)
    80000d46:	6442                	ld	s0,16(sp)
    80000d48:	64a2                	ld	s1,8(sp)
    80000d4a:	6105                	addi	sp,sp,32
    80000d4c:	8082                	ret
    panic("release");
    80000d4e:	00007517          	auipc	a0,0x7
    80000d52:	36250513          	addi	a0,a0,866 # 800080b0 <digits+0x58>
    80000d56:	00000097          	auipc	ra,0x0
    80000d5a:	87a080e7          	jalr	-1926(ra) # 800005d0 <panic>

0000000080000d5e <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000d5e:	1141                	addi	sp,sp,-16
    80000d60:	e422                	sd	s0,8(sp)
    80000d62:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000d64:	ca19                	beqz	a2,80000d7a <memset+0x1c>
    80000d66:	87aa                	mv	a5,a0
    80000d68:	1602                	slli	a2,a2,0x20
    80000d6a:	9201                	srli	a2,a2,0x20
    80000d6c:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000d70:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d74:	0785                	addi	a5,a5,1
    80000d76:	fee79de3          	bne	a5,a4,80000d70 <memset+0x12>
  }
  return dst;
}
    80000d7a:	6422                	ld	s0,8(sp)
    80000d7c:	0141                	addi	sp,sp,16
    80000d7e:	8082                	ret

0000000080000d80 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d80:	1141                	addi	sp,sp,-16
    80000d82:	e422                	sd	s0,8(sp)
    80000d84:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d86:	ca05                	beqz	a2,80000db6 <memcmp+0x36>
    80000d88:	fff6069b          	addiw	a3,a2,-1
    80000d8c:	1682                	slli	a3,a3,0x20
    80000d8e:	9281                	srli	a3,a3,0x20
    80000d90:	0685                	addi	a3,a3,1
    80000d92:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d94:	00054783          	lbu	a5,0(a0)
    80000d98:	0005c703          	lbu	a4,0(a1)
    80000d9c:	00e79863          	bne	a5,a4,80000dac <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000da0:	0505                	addi	a0,a0,1
    80000da2:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000da4:	fed518e3          	bne	a0,a3,80000d94 <memcmp+0x14>
  }

  return 0;
    80000da8:	4501                	li	a0,0
    80000daa:	a019                	j	80000db0 <memcmp+0x30>
      return *s1 - *s2;
    80000dac:	40e7853b          	subw	a0,a5,a4
}
    80000db0:	6422                	ld	s0,8(sp)
    80000db2:	0141                	addi	sp,sp,16
    80000db4:	8082                	ret
  return 0;
    80000db6:	4501                	li	a0,0
    80000db8:	bfe5                	j	80000db0 <memcmp+0x30>

0000000080000dba <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000dba:	1141                	addi	sp,sp,-16
    80000dbc:	e422                	sd	s0,8(sp)
    80000dbe:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000dc0:	02a5e563          	bltu	a1,a0,80000dea <memmove+0x30>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000dc4:	fff6069b          	addiw	a3,a2,-1
    80000dc8:	ce11                	beqz	a2,80000de4 <memmove+0x2a>
    80000dca:	1682                	slli	a3,a3,0x20
    80000dcc:	9281                	srli	a3,a3,0x20
    80000dce:	0685                	addi	a3,a3,1
    80000dd0:	96ae                	add	a3,a3,a1
    80000dd2:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000dd4:	0585                	addi	a1,a1,1
    80000dd6:	0785                	addi	a5,a5,1
    80000dd8:	fff5c703          	lbu	a4,-1(a1)
    80000ddc:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000de0:	fed59ae3          	bne	a1,a3,80000dd4 <memmove+0x1a>

  return dst;
}
    80000de4:	6422                	ld	s0,8(sp)
    80000de6:	0141                	addi	sp,sp,16
    80000de8:	8082                	ret
  if(s < d && s + n > d){
    80000dea:	02061713          	slli	a4,a2,0x20
    80000dee:	9301                	srli	a4,a4,0x20
    80000df0:	00e587b3          	add	a5,a1,a4
    80000df4:	fcf578e3          	bgeu	a0,a5,80000dc4 <memmove+0xa>
    d += n;
    80000df8:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000dfa:	fff6069b          	addiw	a3,a2,-1
    80000dfe:	d27d                	beqz	a2,80000de4 <memmove+0x2a>
    80000e00:	02069613          	slli	a2,a3,0x20
    80000e04:	9201                	srli	a2,a2,0x20
    80000e06:	fff64613          	not	a2,a2
    80000e0a:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000e0c:	17fd                	addi	a5,a5,-1
    80000e0e:	177d                	addi	a4,a4,-1
    80000e10:	0007c683          	lbu	a3,0(a5)
    80000e14:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80000e18:	fef61ae3          	bne	a2,a5,80000e0c <memmove+0x52>
    80000e1c:	b7e1                	j	80000de4 <memmove+0x2a>

0000000080000e1e <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000e1e:	1141                	addi	sp,sp,-16
    80000e20:	e406                	sd	ra,8(sp)
    80000e22:	e022                	sd	s0,0(sp)
    80000e24:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000e26:	00000097          	auipc	ra,0x0
    80000e2a:	f94080e7          	jalr	-108(ra) # 80000dba <memmove>
}
    80000e2e:	60a2                	ld	ra,8(sp)
    80000e30:	6402                	ld	s0,0(sp)
    80000e32:	0141                	addi	sp,sp,16
    80000e34:	8082                	ret

0000000080000e36 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000e36:	1141                	addi	sp,sp,-16
    80000e38:	e422                	sd	s0,8(sp)
    80000e3a:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000e3c:	ce11                	beqz	a2,80000e58 <strncmp+0x22>
    80000e3e:	00054783          	lbu	a5,0(a0)
    80000e42:	cf89                	beqz	a5,80000e5c <strncmp+0x26>
    80000e44:	0005c703          	lbu	a4,0(a1)
    80000e48:	00f71a63          	bne	a4,a5,80000e5c <strncmp+0x26>
    n--, p++, q++;
    80000e4c:	367d                	addiw	a2,a2,-1
    80000e4e:	0505                	addi	a0,a0,1
    80000e50:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000e52:	f675                	bnez	a2,80000e3e <strncmp+0x8>
  if(n == 0)
    return 0;
    80000e54:	4501                	li	a0,0
    80000e56:	a809                	j	80000e68 <strncmp+0x32>
    80000e58:	4501                	li	a0,0
    80000e5a:	a039                	j	80000e68 <strncmp+0x32>
  if(n == 0)
    80000e5c:	ca09                	beqz	a2,80000e6e <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000e5e:	00054503          	lbu	a0,0(a0)
    80000e62:	0005c783          	lbu	a5,0(a1)
    80000e66:	9d1d                	subw	a0,a0,a5
}
    80000e68:	6422                	ld	s0,8(sp)
    80000e6a:	0141                	addi	sp,sp,16
    80000e6c:	8082                	ret
    return 0;
    80000e6e:	4501                	li	a0,0
    80000e70:	bfe5                	j	80000e68 <strncmp+0x32>

0000000080000e72 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000e72:	1141                	addi	sp,sp,-16
    80000e74:	e422                	sd	s0,8(sp)
    80000e76:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e78:	872a                	mv	a4,a0
    80000e7a:	8832                	mv	a6,a2
    80000e7c:	367d                	addiw	a2,a2,-1
    80000e7e:	01005963          	blez	a6,80000e90 <strncpy+0x1e>
    80000e82:	0705                	addi	a4,a4,1
    80000e84:	0005c783          	lbu	a5,0(a1)
    80000e88:	fef70fa3          	sb	a5,-1(a4)
    80000e8c:	0585                	addi	a1,a1,1
    80000e8e:	f7f5                	bnez	a5,80000e7a <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e90:	86ba                	mv	a3,a4
    80000e92:	00c05c63          	blez	a2,80000eaa <strncpy+0x38>
    *s++ = 0;
    80000e96:	0685                	addi	a3,a3,1
    80000e98:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e9c:	fff6c793          	not	a5,a3
    80000ea0:	9fb9                	addw	a5,a5,a4
    80000ea2:	010787bb          	addw	a5,a5,a6
    80000ea6:	fef048e3          	bgtz	a5,80000e96 <strncpy+0x24>
  return os;
}
    80000eaa:	6422                	ld	s0,8(sp)
    80000eac:	0141                	addi	sp,sp,16
    80000eae:	8082                	ret

0000000080000eb0 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000eb0:	1141                	addi	sp,sp,-16
    80000eb2:	e422                	sd	s0,8(sp)
    80000eb4:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000eb6:	02c05363          	blez	a2,80000edc <safestrcpy+0x2c>
    80000eba:	fff6069b          	addiw	a3,a2,-1
    80000ebe:	1682                	slli	a3,a3,0x20
    80000ec0:	9281                	srli	a3,a3,0x20
    80000ec2:	96ae                	add	a3,a3,a1
    80000ec4:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000ec6:	00d58963          	beq	a1,a3,80000ed8 <safestrcpy+0x28>
    80000eca:	0585                	addi	a1,a1,1
    80000ecc:	0785                	addi	a5,a5,1
    80000ece:	fff5c703          	lbu	a4,-1(a1)
    80000ed2:	fee78fa3          	sb	a4,-1(a5)
    80000ed6:	fb65                	bnez	a4,80000ec6 <safestrcpy+0x16>
    ;
  *s = 0;
    80000ed8:	00078023          	sb	zero,0(a5)
  return os;
}
    80000edc:	6422                	ld	s0,8(sp)
    80000ede:	0141                	addi	sp,sp,16
    80000ee0:	8082                	ret

0000000080000ee2 <strlen>:

int
strlen(const char *s)
{
    80000ee2:	1141                	addi	sp,sp,-16
    80000ee4:	e422                	sd	s0,8(sp)
    80000ee6:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000ee8:	00054783          	lbu	a5,0(a0)
    80000eec:	cf91                	beqz	a5,80000f08 <strlen+0x26>
    80000eee:	0505                	addi	a0,a0,1
    80000ef0:	87aa                	mv	a5,a0
    80000ef2:	4685                	li	a3,1
    80000ef4:	9e89                	subw	a3,a3,a0
    80000ef6:	00f6853b          	addw	a0,a3,a5
    80000efa:	0785                	addi	a5,a5,1
    80000efc:	fff7c703          	lbu	a4,-1(a5)
    80000f00:	fb7d                	bnez	a4,80000ef6 <strlen+0x14>
    ;
  return n;
}
    80000f02:	6422                	ld	s0,8(sp)
    80000f04:	0141                	addi	sp,sp,16
    80000f06:	8082                	ret
  for(n = 0; s[n]; n++)
    80000f08:	4501                	li	a0,0
    80000f0a:	bfe5                	j	80000f02 <strlen+0x20>

0000000080000f0c <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000f0c:	1141                	addi	sp,sp,-16
    80000f0e:	e406                	sd	ra,8(sp)
    80000f10:	e022                	sd	s0,0(sp)
    80000f12:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000f14:	00001097          	auipc	ra,0x1
    80000f18:	aee080e7          	jalr	-1298(ra) # 80001a02 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000f1c:	00008717          	auipc	a4,0x8
    80000f20:	0f070713          	addi	a4,a4,240 # 8000900c <started>
  if(cpuid() == 0){
    80000f24:	c139                	beqz	a0,80000f6a <main+0x5e>
    while(started == 0)
    80000f26:	431c                	lw	a5,0(a4)
    80000f28:	2781                	sext.w	a5,a5
    80000f2a:	dff5                	beqz	a5,80000f26 <main+0x1a>
      ;
    __sync_synchronize();
    80000f2c:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000f30:	00001097          	auipc	ra,0x1
    80000f34:	ad2080e7          	jalr	-1326(ra) # 80001a02 <cpuid>
    80000f38:	85aa                	mv	a1,a0
    80000f3a:	00007517          	auipc	a0,0x7
    80000f3e:	19650513          	addi	a0,a0,406 # 800080d0 <digits+0x78>
    80000f42:	fffff097          	auipc	ra,0xfffff
    80000f46:	6e0080e7          	jalr	1760(ra) # 80000622 <printf>
    kvminithart();    // turn on paging
    80000f4a:	00000097          	auipc	ra,0x0
    80000f4e:	0d8080e7          	jalr	216(ra) # 80001022 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000f52:	00001097          	auipc	ra,0x1
    80000f56:	748080e7          	jalr	1864(ra) # 8000269a <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f5a:	00005097          	auipc	ra,0x5
    80000f5e:	f96080e7          	jalr	-106(ra) # 80005ef0 <plicinithart>
  }

  scheduler();        
    80000f62:	00001097          	auipc	ra,0x1
    80000f66:	014080e7          	jalr	20(ra) # 80001f76 <scheduler>
    consoleinit();
    80000f6a:	fffff097          	auipc	ra,0xfffff
    80000f6e:	4ea080e7          	jalr	1258(ra) # 80000454 <consoleinit>
    printfinit();
    80000f72:	fffff097          	auipc	ra,0xfffff
    80000f76:	5d0080e7          	jalr	1488(ra) # 80000542 <printfinit>
    printf("\n");
    80000f7a:	00007517          	auipc	a0,0x7
    80000f7e:	16650513          	addi	a0,a0,358 # 800080e0 <digits+0x88>
    80000f82:	fffff097          	auipc	ra,0xfffff
    80000f86:	6a0080e7          	jalr	1696(ra) # 80000622 <printf>
    printf("xv6 kernel is booting\n");
    80000f8a:	00007517          	auipc	a0,0x7
    80000f8e:	12e50513          	addi	a0,a0,302 # 800080b8 <digits+0x60>
    80000f92:	fffff097          	auipc	ra,0xfffff
    80000f96:	690080e7          	jalr	1680(ra) # 80000622 <printf>
    printf("\n");
    80000f9a:	00007517          	auipc	a0,0x7
    80000f9e:	14650513          	addi	a0,a0,326 # 800080e0 <digits+0x88>
    80000fa2:	fffff097          	auipc	ra,0xfffff
    80000fa6:	680080e7          	jalr	1664(ra) # 80000622 <printf>
    kinit();         // physical page allocator
    80000faa:	00000097          	auipc	ra,0x0
    80000fae:	b8c080e7          	jalr	-1140(ra) # 80000b36 <kinit>
    kvminit();       // create kernel page table
    80000fb2:	00000097          	auipc	ra,0x0
    80000fb6:	2a0080e7          	jalr	672(ra) # 80001252 <kvminit>
    kvminithart();   // turn on paging
    80000fba:	00000097          	auipc	ra,0x0
    80000fbe:	068080e7          	jalr	104(ra) # 80001022 <kvminithart>
    procinit();      // process table
    80000fc2:	00001097          	auipc	ra,0x1
    80000fc6:	970080e7          	jalr	-1680(ra) # 80001932 <procinit>
    trapinit();      // trap vectors
    80000fca:	00001097          	auipc	ra,0x1
    80000fce:	6a8080e7          	jalr	1704(ra) # 80002672 <trapinit>
    trapinithart();  // install kernel trap vector
    80000fd2:	00001097          	auipc	ra,0x1
    80000fd6:	6c8080e7          	jalr	1736(ra) # 8000269a <trapinithart>
    plicinit();      // set up interrupt controller
    80000fda:	00005097          	auipc	ra,0x5
    80000fde:	f00080e7          	jalr	-256(ra) # 80005eda <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000fe2:	00005097          	auipc	ra,0x5
    80000fe6:	f0e080e7          	jalr	-242(ra) # 80005ef0 <plicinithart>
    binit();         // buffer cache
    80000fea:	00002097          	auipc	ra,0x2
    80000fee:	0b6080e7          	jalr	182(ra) # 800030a0 <binit>
    iinit();         // inode cache
    80000ff2:	00002097          	auipc	ra,0x2
    80000ff6:	748080e7          	jalr	1864(ra) # 8000373a <iinit>
    fileinit();      // file table
    80000ffa:	00003097          	auipc	ra,0x3
    80000ffe:	6e6080e7          	jalr	1766(ra) # 800046e0 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80001002:	00005097          	auipc	ra,0x5
    80001006:	ff6080e7          	jalr	-10(ra) # 80005ff8 <virtio_disk_init>
    userinit();      // first user process
    8000100a:	00001097          	auipc	ra,0x1
    8000100e:	d02080e7          	jalr	-766(ra) # 80001d0c <userinit>
    __sync_synchronize();
    80001012:	0ff0000f          	fence
    started = 1;
    80001016:	4785                	li	a5,1
    80001018:	00008717          	auipc	a4,0x8
    8000101c:	fef72a23          	sw	a5,-12(a4) # 8000900c <started>
    80001020:	b789                	j	80000f62 <main+0x56>

0000000080001022 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80001022:	1141                	addi	sp,sp,-16
    80001024:	e422                	sd	s0,8(sp)
    80001026:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80001028:	00008797          	auipc	a5,0x8
    8000102c:	fe87b783          	ld	a5,-24(a5) # 80009010 <kernel_pagetable>
    80001030:	83b1                	srli	a5,a5,0xc
    80001032:	577d                	li	a4,-1
    80001034:	177e                	slli	a4,a4,0x3f
    80001036:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80001038:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    8000103c:	12000073          	sfence.vma
  sfence_vma();
}
    80001040:	6422                	ld	s0,8(sp)
    80001042:	0141                	addi	sp,sp,16
    80001044:	8082                	ret

0000000080001046 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80001046:	7139                	addi	sp,sp,-64
    80001048:	fc06                	sd	ra,56(sp)
    8000104a:	f822                	sd	s0,48(sp)
    8000104c:	f426                	sd	s1,40(sp)
    8000104e:	f04a                	sd	s2,32(sp)
    80001050:	ec4e                	sd	s3,24(sp)
    80001052:	e852                	sd	s4,16(sp)
    80001054:	e456                	sd	s5,8(sp)
    80001056:	e05a                	sd	s6,0(sp)
    80001058:	0080                	addi	s0,sp,64
    8000105a:	84aa                	mv	s1,a0
    8000105c:	89ae                	mv	s3,a1
    8000105e:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80001060:	57fd                	li	a5,-1
    80001062:	83e9                	srli	a5,a5,0x1a
    80001064:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80001066:	4b31                	li	s6,12
  if(va >= MAXVA)
    80001068:	04b7f263          	bgeu	a5,a1,800010ac <walk+0x66>
    panic("walk");
    8000106c:	00007517          	auipc	a0,0x7
    80001070:	07c50513          	addi	a0,a0,124 # 800080e8 <digits+0x90>
    80001074:	fffff097          	auipc	ra,0xfffff
    80001078:	55c080e7          	jalr	1372(ra) # 800005d0 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    8000107c:	060a8663          	beqz	s5,800010e8 <walk+0xa2>
    80001080:	00000097          	auipc	ra,0x0
    80001084:	af2080e7          	jalr	-1294(ra) # 80000b72 <kalloc>
    80001088:	84aa                	mv	s1,a0
    8000108a:	c529                	beqz	a0,800010d4 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    8000108c:	6605                	lui	a2,0x1
    8000108e:	4581                	li	a1,0
    80001090:	00000097          	auipc	ra,0x0
    80001094:	cce080e7          	jalr	-818(ra) # 80000d5e <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001098:	00c4d793          	srli	a5,s1,0xc
    8000109c:	07aa                	slli	a5,a5,0xa
    8000109e:	0017e793          	ori	a5,a5,1
    800010a2:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    800010a6:	3a5d                	addiw	s4,s4,-9
    800010a8:	036a0063          	beq	s4,s6,800010c8 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    800010ac:	0149d933          	srl	s2,s3,s4
    800010b0:	1ff97913          	andi	s2,s2,511
    800010b4:	090e                	slli	s2,s2,0x3
    800010b6:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    800010b8:	00093483          	ld	s1,0(s2)
    800010bc:	0014f793          	andi	a5,s1,1
    800010c0:	dfd5                	beqz	a5,8000107c <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    800010c2:	80a9                	srli	s1,s1,0xa
    800010c4:	04b2                	slli	s1,s1,0xc
    800010c6:	b7c5                	j	800010a6 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    800010c8:	00c9d513          	srli	a0,s3,0xc
    800010cc:	1ff57513          	andi	a0,a0,511
    800010d0:	050e                	slli	a0,a0,0x3
    800010d2:	9526                	add	a0,a0,s1
}
    800010d4:	70e2                	ld	ra,56(sp)
    800010d6:	7442                	ld	s0,48(sp)
    800010d8:	74a2                	ld	s1,40(sp)
    800010da:	7902                	ld	s2,32(sp)
    800010dc:	69e2                	ld	s3,24(sp)
    800010de:	6a42                	ld	s4,16(sp)
    800010e0:	6aa2                	ld	s5,8(sp)
    800010e2:	6b02                	ld	s6,0(sp)
    800010e4:	6121                	addi	sp,sp,64
    800010e6:	8082                	ret
        return 0;
    800010e8:	4501                	li	a0,0
    800010ea:	b7ed                	j	800010d4 <walk+0x8e>

00000000800010ec <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    800010ec:	57fd                	li	a5,-1
    800010ee:	83e9                	srli	a5,a5,0x1a
    800010f0:	00b7f463          	bgeu	a5,a1,800010f8 <walkaddr+0xc>
    return 0;
    800010f4:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    800010f6:	8082                	ret
{
    800010f8:	1141                	addi	sp,sp,-16
    800010fa:	e406                	sd	ra,8(sp)
    800010fc:	e022                	sd	s0,0(sp)
    800010fe:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001100:	4601                	li	a2,0
    80001102:	00000097          	auipc	ra,0x0
    80001106:	f44080e7          	jalr	-188(ra) # 80001046 <walk>
  if(pte == 0)
    8000110a:	c105                	beqz	a0,8000112a <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000110c:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000110e:	0117f693          	andi	a3,a5,17
    80001112:	4745                	li	a4,17
    return 0;
    80001114:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001116:	00e68663          	beq	a3,a4,80001122 <walkaddr+0x36>
}
    8000111a:	60a2                	ld	ra,8(sp)
    8000111c:	6402                	ld	s0,0(sp)
    8000111e:	0141                	addi	sp,sp,16
    80001120:	8082                	ret
  pa = PTE2PA(*pte);
    80001122:	00a7d513          	srli	a0,a5,0xa
    80001126:	0532                	slli	a0,a0,0xc
  return pa;
    80001128:	bfcd                	j	8000111a <walkaddr+0x2e>
    return 0;
    8000112a:	4501                	li	a0,0
    8000112c:	b7fd                	j	8000111a <walkaddr+0x2e>

000000008000112e <kvmpa>:
// a physical address. only needed for
// addresses on the stack.
// assumes va is page aligned.
uint64
kvmpa(uint64 va)
{
    8000112e:	1101                	addi	sp,sp,-32
    80001130:	ec06                	sd	ra,24(sp)
    80001132:	e822                	sd	s0,16(sp)
    80001134:	e426                	sd	s1,8(sp)
    80001136:	1000                	addi	s0,sp,32
    80001138:	85aa                	mv	a1,a0
  uint64 off = va % PGSIZE;
    8000113a:	1552                	slli	a0,a0,0x34
    8000113c:	03455493          	srli	s1,a0,0x34
  pte_t *pte;
  uint64 pa;
  
  pte = walk(kernel_pagetable, va, 0);
    80001140:	4601                	li	a2,0
    80001142:	00008517          	auipc	a0,0x8
    80001146:	ece53503          	ld	a0,-306(a0) # 80009010 <kernel_pagetable>
    8000114a:	00000097          	auipc	ra,0x0
    8000114e:	efc080e7          	jalr	-260(ra) # 80001046 <walk>
  if(pte == 0)
    80001152:	cd09                	beqz	a0,8000116c <kvmpa+0x3e>
    panic("kvmpa");
  if((*pte & PTE_V) == 0)
    80001154:	6108                	ld	a0,0(a0)
    80001156:	00157793          	andi	a5,a0,1
    8000115a:	c38d                	beqz	a5,8000117c <kvmpa+0x4e>
    panic("kvmpa");
  pa = PTE2PA(*pte);
    8000115c:	8129                	srli	a0,a0,0xa
    8000115e:	0532                	slli	a0,a0,0xc
  return pa+off;
}
    80001160:	9526                	add	a0,a0,s1
    80001162:	60e2                	ld	ra,24(sp)
    80001164:	6442                	ld	s0,16(sp)
    80001166:	64a2                	ld	s1,8(sp)
    80001168:	6105                	addi	sp,sp,32
    8000116a:	8082                	ret
    panic("kvmpa");
    8000116c:	00007517          	auipc	a0,0x7
    80001170:	f8450513          	addi	a0,a0,-124 # 800080f0 <digits+0x98>
    80001174:	fffff097          	auipc	ra,0xfffff
    80001178:	45c080e7          	jalr	1116(ra) # 800005d0 <panic>
    panic("kvmpa");
    8000117c:	00007517          	auipc	a0,0x7
    80001180:	f7450513          	addi	a0,a0,-140 # 800080f0 <digits+0x98>
    80001184:	fffff097          	auipc	ra,0xfffff
    80001188:	44c080e7          	jalr	1100(ra) # 800005d0 <panic>

000000008000118c <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000118c:	715d                	addi	sp,sp,-80
    8000118e:	e486                	sd	ra,72(sp)
    80001190:	e0a2                	sd	s0,64(sp)
    80001192:	fc26                	sd	s1,56(sp)
    80001194:	f84a                	sd	s2,48(sp)
    80001196:	f44e                	sd	s3,40(sp)
    80001198:	f052                	sd	s4,32(sp)
    8000119a:	ec56                	sd	s5,24(sp)
    8000119c:	e85a                	sd	s6,16(sp)
    8000119e:	e45e                	sd	s7,8(sp)
    800011a0:	0880                	addi	s0,sp,80
    800011a2:	8aaa                	mv	s5,a0
    800011a4:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    800011a6:	777d                	lui	a4,0xfffff
    800011a8:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800011ac:	167d                	addi	a2,a2,-1
    800011ae:	00b609b3          	add	s3,a2,a1
    800011b2:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800011b6:	893e                	mv	s2,a5
    800011b8:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800011bc:	6b85                	lui	s7,0x1
    800011be:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800011c2:	4605                	li	a2,1
    800011c4:	85ca                	mv	a1,s2
    800011c6:	8556                	mv	a0,s5
    800011c8:	00000097          	auipc	ra,0x0
    800011cc:	e7e080e7          	jalr	-386(ra) # 80001046 <walk>
    800011d0:	c51d                	beqz	a0,800011fe <mappages+0x72>
    if(*pte & PTE_V)
    800011d2:	611c                	ld	a5,0(a0)
    800011d4:	8b85                	andi	a5,a5,1
    800011d6:	ef81                	bnez	a5,800011ee <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800011d8:	80b1                	srli	s1,s1,0xc
    800011da:	04aa                	slli	s1,s1,0xa
    800011dc:	0164e4b3          	or	s1,s1,s6
    800011e0:	0014e493          	ori	s1,s1,1
    800011e4:	e104                	sd	s1,0(a0)
    if(a == last)
    800011e6:	03390863          	beq	s2,s3,80001216 <mappages+0x8a>
    a += PGSIZE;
    800011ea:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    800011ec:	bfc9                	j	800011be <mappages+0x32>
      panic("remap");
    800011ee:	00007517          	auipc	a0,0x7
    800011f2:	f0a50513          	addi	a0,a0,-246 # 800080f8 <digits+0xa0>
    800011f6:	fffff097          	auipc	ra,0xfffff
    800011fa:	3da080e7          	jalr	986(ra) # 800005d0 <panic>
      return -1;
    800011fe:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001200:	60a6                	ld	ra,72(sp)
    80001202:	6406                	ld	s0,64(sp)
    80001204:	74e2                	ld	s1,56(sp)
    80001206:	7942                	ld	s2,48(sp)
    80001208:	79a2                	ld	s3,40(sp)
    8000120a:	7a02                	ld	s4,32(sp)
    8000120c:	6ae2                	ld	s5,24(sp)
    8000120e:	6b42                	ld	s6,16(sp)
    80001210:	6ba2                	ld	s7,8(sp)
    80001212:	6161                	addi	sp,sp,80
    80001214:	8082                	ret
  return 0;
    80001216:	4501                	li	a0,0
    80001218:	b7e5                	j	80001200 <mappages+0x74>

000000008000121a <kvmmap>:
{
    8000121a:	1141                	addi	sp,sp,-16
    8000121c:	e406                	sd	ra,8(sp)
    8000121e:	e022                	sd	s0,0(sp)
    80001220:	0800                	addi	s0,sp,16
    80001222:	8736                	mv	a4,a3
  if(mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    80001224:	86ae                	mv	a3,a1
    80001226:	85aa                	mv	a1,a0
    80001228:	00008517          	auipc	a0,0x8
    8000122c:	de853503          	ld	a0,-536(a0) # 80009010 <kernel_pagetable>
    80001230:	00000097          	auipc	ra,0x0
    80001234:	f5c080e7          	jalr	-164(ra) # 8000118c <mappages>
    80001238:	e509                	bnez	a0,80001242 <kvmmap+0x28>
}
    8000123a:	60a2                	ld	ra,8(sp)
    8000123c:	6402                	ld	s0,0(sp)
    8000123e:	0141                	addi	sp,sp,16
    80001240:	8082                	ret
    panic("kvmmap");
    80001242:	00007517          	auipc	a0,0x7
    80001246:	ebe50513          	addi	a0,a0,-322 # 80008100 <digits+0xa8>
    8000124a:	fffff097          	auipc	ra,0xfffff
    8000124e:	386080e7          	jalr	902(ra) # 800005d0 <panic>

0000000080001252 <kvminit>:
{
    80001252:	1101                	addi	sp,sp,-32
    80001254:	ec06                	sd	ra,24(sp)
    80001256:	e822                	sd	s0,16(sp)
    80001258:	e426                	sd	s1,8(sp)
    8000125a:	1000                	addi	s0,sp,32
  kernel_pagetable = (pagetable_t) kalloc();
    8000125c:	00000097          	auipc	ra,0x0
    80001260:	916080e7          	jalr	-1770(ra) # 80000b72 <kalloc>
    80001264:	00008797          	auipc	a5,0x8
    80001268:	daa7b623          	sd	a0,-596(a5) # 80009010 <kernel_pagetable>
  memset(kernel_pagetable, 0, PGSIZE);
    8000126c:	6605                	lui	a2,0x1
    8000126e:	4581                	li	a1,0
    80001270:	00000097          	auipc	ra,0x0
    80001274:	aee080e7          	jalr	-1298(ra) # 80000d5e <memset>
  kvmmap(UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001278:	4699                	li	a3,6
    8000127a:	6605                	lui	a2,0x1
    8000127c:	100005b7          	lui	a1,0x10000
    80001280:	10000537          	lui	a0,0x10000
    80001284:	00000097          	auipc	ra,0x0
    80001288:	f96080e7          	jalr	-106(ra) # 8000121a <kvmmap>
  kvmmap(VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    8000128c:	4699                	li	a3,6
    8000128e:	6605                	lui	a2,0x1
    80001290:	100015b7          	lui	a1,0x10001
    80001294:	10001537          	lui	a0,0x10001
    80001298:	00000097          	auipc	ra,0x0
    8000129c:	f82080e7          	jalr	-126(ra) # 8000121a <kvmmap>
  kvmmap(CLINT, CLINT, 0x10000, PTE_R | PTE_W);
    800012a0:	4699                	li	a3,6
    800012a2:	6641                	lui	a2,0x10
    800012a4:	020005b7          	lui	a1,0x2000
    800012a8:	02000537          	lui	a0,0x2000
    800012ac:	00000097          	auipc	ra,0x0
    800012b0:	f6e080e7          	jalr	-146(ra) # 8000121a <kvmmap>
  kvmmap(PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800012b4:	4699                	li	a3,6
    800012b6:	00400637          	lui	a2,0x400
    800012ba:	0c0005b7          	lui	a1,0xc000
    800012be:	0c000537          	lui	a0,0xc000
    800012c2:	00000097          	auipc	ra,0x0
    800012c6:	f58080e7          	jalr	-168(ra) # 8000121a <kvmmap>
  kvmmap(KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800012ca:	00007497          	auipc	s1,0x7
    800012ce:	d3648493          	addi	s1,s1,-714 # 80008000 <etext>
    800012d2:	46a9                	li	a3,10
    800012d4:	80007617          	auipc	a2,0x80007
    800012d8:	d2c60613          	addi	a2,a2,-724 # 8000 <_entry-0x7fff8000>
    800012dc:	4585                	li	a1,1
    800012de:	05fe                	slli	a1,a1,0x1f
    800012e0:	852e                	mv	a0,a1
    800012e2:	00000097          	auipc	ra,0x0
    800012e6:	f38080e7          	jalr	-200(ra) # 8000121a <kvmmap>
  kvmmap((uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800012ea:	4699                	li	a3,6
    800012ec:	4645                	li	a2,17
    800012ee:	066e                	slli	a2,a2,0x1b
    800012f0:	8e05                	sub	a2,a2,s1
    800012f2:	85a6                	mv	a1,s1
    800012f4:	8526                	mv	a0,s1
    800012f6:	00000097          	auipc	ra,0x0
    800012fa:	f24080e7          	jalr	-220(ra) # 8000121a <kvmmap>
  kvmmap(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    800012fe:	46a9                	li	a3,10
    80001300:	6605                	lui	a2,0x1
    80001302:	00006597          	auipc	a1,0x6
    80001306:	cfe58593          	addi	a1,a1,-770 # 80007000 <_trampoline>
    8000130a:	04000537          	lui	a0,0x4000
    8000130e:	157d                	addi	a0,a0,-1
    80001310:	0532                	slli	a0,a0,0xc
    80001312:	00000097          	auipc	ra,0x0
    80001316:	f08080e7          	jalr	-248(ra) # 8000121a <kvmmap>
}
    8000131a:	60e2                	ld	ra,24(sp)
    8000131c:	6442                	ld	s0,16(sp)
    8000131e:	64a2                	ld	s1,8(sp)
    80001320:	6105                	addi	sp,sp,32
    80001322:	8082                	ret

0000000080001324 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001324:	715d                	addi	sp,sp,-80
    80001326:	e486                	sd	ra,72(sp)
    80001328:	e0a2                	sd	s0,64(sp)
    8000132a:	fc26                	sd	s1,56(sp)
    8000132c:	f84a                	sd	s2,48(sp)
    8000132e:	f44e                	sd	s3,40(sp)
    80001330:	f052                	sd	s4,32(sp)
    80001332:	ec56                	sd	s5,24(sp)
    80001334:	e85a                	sd	s6,16(sp)
    80001336:	e45e                	sd	s7,8(sp)
    80001338:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000133a:	03459793          	slli	a5,a1,0x34
    8000133e:	e795                	bnez	a5,8000136a <uvmunmap+0x46>
    80001340:	8a2a                	mv	s4,a0
    80001342:	892e                	mv	s2,a1
    80001344:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001346:	0632                	slli	a2,a2,0xc
    80001348:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000134c:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000134e:	6b05                	lui	s6,0x1
    80001350:	0735e263          	bltu	a1,s3,800013b4 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001354:	60a6                	ld	ra,72(sp)
    80001356:	6406                	ld	s0,64(sp)
    80001358:	74e2                	ld	s1,56(sp)
    8000135a:	7942                	ld	s2,48(sp)
    8000135c:	79a2                	ld	s3,40(sp)
    8000135e:	7a02                	ld	s4,32(sp)
    80001360:	6ae2                	ld	s5,24(sp)
    80001362:	6b42                	ld	s6,16(sp)
    80001364:	6ba2                	ld	s7,8(sp)
    80001366:	6161                	addi	sp,sp,80
    80001368:	8082                	ret
    panic("uvmunmap: not aligned");
    8000136a:	00007517          	auipc	a0,0x7
    8000136e:	d9e50513          	addi	a0,a0,-610 # 80008108 <digits+0xb0>
    80001372:	fffff097          	auipc	ra,0xfffff
    80001376:	25e080e7          	jalr	606(ra) # 800005d0 <panic>
      panic("uvmunmap: walk");
    8000137a:	00007517          	auipc	a0,0x7
    8000137e:	da650513          	addi	a0,a0,-602 # 80008120 <digits+0xc8>
    80001382:	fffff097          	auipc	ra,0xfffff
    80001386:	24e080e7          	jalr	590(ra) # 800005d0 <panic>
      panic("uvmunmap: not mapped");
    8000138a:	00007517          	auipc	a0,0x7
    8000138e:	da650513          	addi	a0,a0,-602 # 80008130 <digits+0xd8>
    80001392:	fffff097          	auipc	ra,0xfffff
    80001396:	23e080e7          	jalr	574(ra) # 800005d0 <panic>
      panic("uvmunmap: not a leaf");
    8000139a:	00007517          	auipc	a0,0x7
    8000139e:	dae50513          	addi	a0,a0,-594 # 80008148 <digits+0xf0>
    800013a2:	fffff097          	auipc	ra,0xfffff
    800013a6:	22e080e7          	jalr	558(ra) # 800005d0 <panic>
    *pte = 0;
    800013aa:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800013ae:	995a                	add	s2,s2,s6
    800013b0:	fb3972e3          	bgeu	s2,s3,80001354 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800013b4:	4601                	li	a2,0
    800013b6:	85ca                	mv	a1,s2
    800013b8:	8552                	mv	a0,s4
    800013ba:	00000097          	auipc	ra,0x0
    800013be:	c8c080e7          	jalr	-884(ra) # 80001046 <walk>
    800013c2:	84aa                	mv	s1,a0
    800013c4:	d95d                	beqz	a0,8000137a <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    800013c6:	6108                	ld	a0,0(a0)
    800013c8:	00157793          	andi	a5,a0,1
    800013cc:	dfdd                	beqz	a5,8000138a <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    800013ce:	3ff57793          	andi	a5,a0,1023
    800013d2:	fd7784e3          	beq	a5,s7,8000139a <uvmunmap+0x76>
    if(do_free){
    800013d6:	fc0a8ae3          	beqz	s5,800013aa <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    800013da:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800013dc:	0532                	slli	a0,a0,0xc
    800013de:	fffff097          	auipc	ra,0xfffff
    800013e2:	698080e7          	jalr	1688(ra) # 80000a76 <kfree>
    800013e6:	b7d1                	j	800013aa <uvmunmap+0x86>

00000000800013e8 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    800013e8:	1101                	addi	sp,sp,-32
    800013ea:	ec06                	sd	ra,24(sp)
    800013ec:	e822                	sd	s0,16(sp)
    800013ee:	e426                	sd	s1,8(sp)
    800013f0:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    800013f2:	fffff097          	auipc	ra,0xfffff
    800013f6:	780080e7          	jalr	1920(ra) # 80000b72 <kalloc>
    800013fa:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800013fc:	c519                	beqz	a0,8000140a <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    800013fe:	6605                	lui	a2,0x1
    80001400:	4581                	li	a1,0
    80001402:	00000097          	auipc	ra,0x0
    80001406:	95c080e7          	jalr	-1700(ra) # 80000d5e <memset>
  return pagetable;
}
    8000140a:	8526                	mv	a0,s1
    8000140c:	60e2                	ld	ra,24(sp)
    8000140e:	6442                	ld	s0,16(sp)
    80001410:	64a2                	ld	s1,8(sp)
    80001412:	6105                	addi	sp,sp,32
    80001414:	8082                	ret

0000000080001416 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001416:	7179                	addi	sp,sp,-48
    80001418:	f406                	sd	ra,40(sp)
    8000141a:	f022                	sd	s0,32(sp)
    8000141c:	ec26                	sd	s1,24(sp)
    8000141e:	e84a                	sd	s2,16(sp)
    80001420:	e44e                	sd	s3,8(sp)
    80001422:	e052                	sd	s4,0(sp)
    80001424:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001426:	6785                	lui	a5,0x1
    80001428:	04f67863          	bgeu	a2,a5,80001478 <uvminit+0x62>
    8000142c:	8a2a                	mv	s4,a0
    8000142e:	89ae                	mv	s3,a1
    80001430:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001432:	fffff097          	auipc	ra,0xfffff
    80001436:	740080e7          	jalr	1856(ra) # 80000b72 <kalloc>
    8000143a:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000143c:	6605                	lui	a2,0x1
    8000143e:	4581                	li	a1,0
    80001440:	00000097          	auipc	ra,0x0
    80001444:	91e080e7          	jalr	-1762(ra) # 80000d5e <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001448:	4779                	li	a4,30
    8000144a:	86ca                	mv	a3,s2
    8000144c:	6605                	lui	a2,0x1
    8000144e:	4581                	li	a1,0
    80001450:	8552                	mv	a0,s4
    80001452:	00000097          	auipc	ra,0x0
    80001456:	d3a080e7          	jalr	-710(ra) # 8000118c <mappages>
  memmove(mem, src, sz);
    8000145a:	8626                	mv	a2,s1
    8000145c:	85ce                	mv	a1,s3
    8000145e:	854a                	mv	a0,s2
    80001460:	00000097          	auipc	ra,0x0
    80001464:	95a080e7          	jalr	-1702(ra) # 80000dba <memmove>
}
    80001468:	70a2                	ld	ra,40(sp)
    8000146a:	7402                	ld	s0,32(sp)
    8000146c:	64e2                	ld	s1,24(sp)
    8000146e:	6942                	ld	s2,16(sp)
    80001470:	69a2                	ld	s3,8(sp)
    80001472:	6a02                	ld	s4,0(sp)
    80001474:	6145                	addi	sp,sp,48
    80001476:	8082                	ret
    panic("inituvm: more than a page");
    80001478:	00007517          	auipc	a0,0x7
    8000147c:	ce850513          	addi	a0,a0,-792 # 80008160 <digits+0x108>
    80001480:	fffff097          	auipc	ra,0xfffff
    80001484:	150080e7          	jalr	336(ra) # 800005d0 <panic>

0000000080001488 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001488:	1101                	addi	sp,sp,-32
    8000148a:	ec06                	sd	ra,24(sp)
    8000148c:	e822                	sd	s0,16(sp)
    8000148e:	e426                	sd	s1,8(sp)
    80001490:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    80001492:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    80001494:	00b67d63          	bgeu	a2,a1,800014ae <uvmdealloc+0x26>
    80001498:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    8000149a:	6785                	lui	a5,0x1
    8000149c:	17fd                	addi	a5,a5,-1
    8000149e:	00f60733          	add	a4,a2,a5
    800014a2:	767d                	lui	a2,0xfffff
    800014a4:	8f71                	and	a4,a4,a2
    800014a6:	97ae                	add	a5,a5,a1
    800014a8:	8ff1                	and	a5,a5,a2
    800014aa:	00f76863          	bltu	a4,a5,800014ba <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800014ae:	8526                	mv	a0,s1
    800014b0:	60e2                	ld	ra,24(sp)
    800014b2:	6442                	ld	s0,16(sp)
    800014b4:	64a2                	ld	s1,8(sp)
    800014b6:	6105                	addi	sp,sp,32
    800014b8:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800014ba:	8f99                	sub	a5,a5,a4
    800014bc:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800014be:	4685                	li	a3,1
    800014c0:	0007861b          	sext.w	a2,a5
    800014c4:	85ba                	mv	a1,a4
    800014c6:	00000097          	auipc	ra,0x0
    800014ca:	e5e080e7          	jalr	-418(ra) # 80001324 <uvmunmap>
    800014ce:	b7c5                	j	800014ae <uvmdealloc+0x26>

00000000800014d0 <uvmalloc>:
  if(newsz < oldsz)
    800014d0:	0ab66163          	bltu	a2,a1,80001572 <uvmalloc+0xa2>
{
    800014d4:	7139                	addi	sp,sp,-64
    800014d6:	fc06                	sd	ra,56(sp)
    800014d8:	f822                	sd	s0,48(sp)
    800014da:	f426                	sd	s1,40(sp)
    800014dc:	f04a                	sd	s2,32(sp)
    800014de:	ec4e                	sd	s3,24(sp)
    800014e0:	e852                	sd	s4,16(sp)
    800014e2:	e456                	sd	s5,8(sp)
    800014e4:	0080                	addi	s0,sp,64
    800014e6:	8aaa                	mv	s5,a0
    800014e8:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    800014ea:	6985                	lui	s3,0x1
    800014ec:	19fd                	addi	s3,s3,-1
    800014ee:	95ce                	add	a1,a1,s3
    800014f0:	79fd                	lui	s3,0xfffff
    800014f2:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014f6:	08c9f063          	bgeu	s3,a2,80001576 <uvmalloc+0xa6>
    800014fa:	894e                	mv	s2,s3
    mem = kalloc();
    800014fc:	fffff097          	auipc	ra,0xfffff
    80001500:	676080e7          	jalr	1654(ra) # 80000b72 <kalloc>
    80001504:	84aa                	mv	s1,a0
    if(mem == 0){
    80001506:	c51d                	beqz	a0,80001534 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    80001508:	6605                	lui	a2,0x1
    8000150a:	4581                	li	a1,0
    8000150c:	00000097          	auipc	ra,0x0
    80001510:	852080e7          	jalr	-1966(ra) # 80000d5e <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001514:	4779                	li	a4,30
    80001516:	86a6                	mv	a3,s1
    80001518:	6605                	lui	a2,0x1
    8000151a:	85ca                	mv	a1,s2
    8000151c:	8556                	mv	a0,s5
    8000151e:	00000097          	auipc	ra,0x0
    80001522:	c6e080e7          	jalr	-914(ra) # 8000118c <mappages>
    80001526:	e905                	bnez	a0,80001556 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001528:	6785                	lui	a5,0x1
    8000152a:	993e                	add	s2,s2,a5
    8000152c:	fd4968e3          	bltu	s2,s4,800014fc <uvmalloc+0x2c>
  return newsz;
    80001530:	8552                	mv	a0,s4
    80001532:	a809                	j	80001544 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    80001534:	864e                	mv	a2,s3
    80001536:	85ca                	mv	a1,s2
    80001538:	8556                	mv	a0,s5
    8000153a:	00000097          	auipc	ra,0x0
    8000153e:	f4e080e7          	jalr	-178(ra) # 80001488 <uvmdealloc>
      return 0;
    80001542:	4501                	li	a0,0
}
    80001544:	70e2                	ld	ra,56(sp)
    80001546:	7442                	ld	s0,48(sp)
    80001548:	74a2                	ld	s1,40(sp)
    8000154a:	7902                	ld	s2,32(sp)
    8000154c:	69e2                	ld	s3,24(sp)
    8000154e:	6a42                	ld	s4,16(sp)
    80001550:	6aa2                	ld	s5,8(sp)
    80001552:	6121                	addi	sp,sp,64
    80001554:	8082                	ret
      kfree(mem);
    80001556:	8526                	mv	a0,s1
    80001558:	fffff097          	auipc	ra,0xfffff
    8000155c:	51e080e7          	jalr	1310(ra) # 80000a76 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001560:	864e                	mv	a2,s3
    80001562:	85ca                	mv	a1,s2
    80001564:	8556                	mv	a0,s5
    80001566:	00000097          	auipc	ra,0x0
    8000156a:	f22080e7          	jalr	-222(ra) # 80001488 <uvmdealloc>
      return 0;
    8000156e:	4501                	li	a0,0
    80001570:	bfd1                	j	80001544 <uvmalloc+0x74>
    return oldsz;
    80001572:	852e                	mv	a0,a1
}
    80001574:	8082                	ret
  return newsz;
    80001576:	8532                	mv	a0,a2
    80001578:	b7f1                	j	80001544 <uvmalloc+0x74>

000000008000157a <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    8000157a:	7179                	addi	sp,sp,-48
    8000157c:	f406                	sd	ra,40(sp)
    8000157e:	f022                	sd	s0,32(sp)
    80001580:	ec26                	sd	s1,24(sp)
    80001582:	e84a                	sd	s2,16(sp)
    80001584:	e44e                	sd	s3,8(sp)
    80001586:	e052                	sd	s4,0(sp)
    80001588:	1800                	addi	s0,sp,48
    8000158a:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    8000158c:	84aa                	mv	s1,a0
    8000158e:	6905                	lui	s2,0x1
    80001590:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001592:	4985                	li	s3,1
    80001594:	a821                	j	800015ac <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001596:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    80001598:	0532                	slli	a0,a0,0xc
    8000159a:	00000097          	auipc	ra,0x0
    8000159e:	fe0080e7          	jalr	-32(ra) # 8000157a <freewalk>
      pagetable[i] = 0;
    800015a2:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800015a6:	04a1                	addi	s1,s1,8
    800015a8:	03248163          	beq	s1,s2,800015ca <freewalk+0x50>
    pte_t pte = pagetable[i];
    800015ac:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800015ae:	00f57793          	andi	a5,a0,15
    800015b2:	ff3782e3          	beq	a5,s3,80001596 <freewalk+0x1c>
    } else if(pte & PTE_V){
    800015b6:	8905                	andi	a0,a0,1
    800015b8:	d57d                	beqz	a0,800015a6 <freewalk+0x2c>
      panic("freewalk: leaf");
    800015ba:	00007517          	auipc	a0,0x7
    800015be:	bc650513          	addi	a0,a0,-1082 # 80008180 <digits+0x128>
    800015c2:	fffff097          	auipc	ra,0xfffff
    800015c6:	00e080e7          	jalr	14(ra) # 800005d0 <panic>
    }
  }
  kfree((void*)pagetable);
    800015ca:	8552                	mv	a0,s4
    800015cc:	fffff097          	auipc	ra,0xfffff
    800015d0:	4aa080e7          	jalr	1194(ra) # 80000a76 <kfree>
}
    800015d4:	70a2                	ld	ra,40(sp)
    800015d6:	7402                	ld	s0,32(sp)
    800015d8:	64e2                	ld	s1,24(sp)
    800015da:	6942                	ld	s2,16(sp)
    800015dc:	69a2                	ld	s3,8(sp)
    800015de:	6a02                	ld	s4,0(sp)
    800015e0:	6145                	addi	sp,sp,48
    800015e2:	8082                	ret

00000000800015e4 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    800015e4:	1101                	addi	sp,sp,-32
    800015e6:	ec06                	sd	ra,24(sp)
    800015e8:	e822                	sd	s0,16(sp)
    800015ea:	e426                	sd	s1,8(sp)
    800015ec:	1000                	addi	s0,sp,32
    800015ee:	84aa                	mv	s1,a0
  if(sz > 0)
    800015f0:	e999                	bnez	a1,80001606 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    800015f2:	8526                	mv	a0,s1
    800015f4:	00000097          	auipc	ra,0x0
    800015f8:	f86080e7          	jalr	-122(ra) # 8000157a <freewalk>
}
    800015fc:	60e2                	ld	ra,24(sp)
    800015fe:	6442                	ld	s0,16(sp)
    80001600:	64a2                	ld	s1,8(sp)
    80001602:	6105                	addi	sp,sp,32
    80001604:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001606:	6605                	lui	a2,0x1
    80001608:	167d                	addi	a2,a2,-1
    8000160a:	962e                	add	a2,a2,a1
    8000160c:	4685                	li	a3,1
    8000160e:	8231                	srli	a2,a2,0xc
    80001610:	4581                	li	a1,0
    80001612:	00000097          	auipc	ra,0x0
    80001616:	d12080e7          	jalr	-750(ra) # 80001324 <uvmunmap>
    8000161a:	bfe1                	j	800015f2 <uvmfree+0xe>

000000008000161c <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000161c:	c679                	beqz	a2,800016ea <uvmcopy+0xce>
{
    8000161e:	715d                	addi	sp,sp,-80
    80001620:	e486                	sd	ra,72(sp)
    80001622:	e0a2                	sd	s0,64(sp)
    80001624:	fc26                	sd	s1,56(sp)
    80001626:	f84a                	sd	s2,48(sp)
    80001628:	f44e                	sd	s3,40(sp)
    8000162a:	f052                	sd	s4,32(sp)
    8000162c:	ec56                	sd	s5,24(sp)
    8000162e:	e85a                	sd	s6,16(sp)
    80001630:	e45e                	sd	s7,8(sp)
    80001632:	0880                	addi	s0,sp,80
    80001634:	8b2a                	mv	s6,a0
    80001636:	8aae                	mv	s5,a1
    80001638:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000163a:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    8000163c:	4601                	li	a2,0
    8000163e:	85ce                	mv	a1,s3
    80001640:	855a                	mv	a0,s6
    80001642:	00000097          	auipc	ra,0x0
    80001646:	a04080e7          	jalr	-1532(ra) # 80001046 <walk>
    8000164a:	c531                	beqz	a0,80001696 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    8000164c:	6118                	ld	a4,0(a0)
    8000164e:	00177793          	andi	a5,a4,1
    80001652:	cbb1                	beqz	a5,800016a6 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    80001654:	00a75593          	srli	a1,a4,0xa
    80001658:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    8000165c:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    80001660:	fffff097          	auipc	ra,0xfffff
    80001664:	512080e7          	jalr	1298(ra) # 80000b72 <kalloc>
    80001668:	892a                	mv	s2,a0
    8000166a:	c939                	beqz	a0,800016c0 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    8000166c:	6605                	lui	a2,0x1
    8000166e:	85de                	mv	a1,s7
    80001670:	fffff097          	auipc	ra,0xfffff
    80001674:	74a080e7          	jalr	1866(ra) # 80000dba <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    80001678:	8726                	mv	a4,s1
    8000167a:	86ca                	mv	a3,s2
    8000167c:	6605                	lui	a2,0x1
    8000167e:	85ce                	mv	a1,s3
    80001680:	8556                	mv	a0,s5
    80001682:	00000097          	auipc	ra,0x0
    80001686:	b0a080e7          	jalr	-1270(ra) # 8000118c <mappages>
    8000168a:	e515                	bnez	a0,800016b6 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    8000168c:	6785                	lui	a5,0x1
    8000168e:	99be                	add	s3,s3,a5
    80001690:	fb49e6e3          	bltu	s3,s4,8000163c <uvmcopy+0x20>
    80001694:	a081                	j	800016d4 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    80001696:	00007517          	auipc	a0,0x7
    8000169a:	afa50513          	addi	a0,a0,-1286 # 80008190 <digits+0x138>
    8000169e:	fffff097          	auipc	ra,0xfffff
    800016a2:	f32080e7          	jalr	-206(ra) # 800005d0 <panic>
      panic("uvmcopy: page not present");
    800016a6:	00007517          	auipc	a0,0x7
    800016aa:	b0a50513          	addi	a0,a0,-1270 # 800081b0 <digits+0x158>
    800016ae:	fffff097          	auipc	ra,0xfffff
    800016b2:	f22080e7          	jalr	-222(ra) # 800005d0 <panic>
      kfree(mem);
    800016b6:	854a                	mv	a0,s2
    800016b8:	fffff097          	auipc	ra,0xfffff
    800016bc:	3be080e7          	jalr	958(ra) # 80000a76 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800016c0:	4685                	li	a3,1
    800016c2:	00c9d613          	srli	a2,s3,0xc
    800016c6:	4581                	li	a1,0
    800016c8:	8556                	mv	a0,s5
    800016ca:	00000097          	auipc	ra,0x0
    800016ce:	c5a080e7          	jalr	-934(ra) # 80001324 <uvmunmap>
  return -1;
    800016d2:	557d                	li	a0,-1
}
    800016d4:	60a6                	ld	ra,72(sp)
    800016d6:	6406                	ld	s0,64(sp)
    800016d8:	74e2                	ld	s1,56(sp)
    800016da:	7942                	ld	s2,48(sp)
    800016dc:	79a2                	ld	s3,40(sp)
    800016de:	7a02                	ld	s4,32(sp)
    800016e0:	6ae2                	ld	s5,24(sp)
    800016e2:	6b42                	ld	s6,16(sp)
    800016e4:	6ba2                	ld	s7,8(sp)
    800016e6:	6161                	addi	sp,sp,80
    800016e8:	8082                	ret
  return 0;
    800016ea:	4501                	li	a0,0
}
    800016ec:	8082                	ret

00000000800016ee <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    800016ee:	1141                	addi	sp,sp,-16
    800016f0:	e406                	sd	ra,8(sp)
    800016f2:	e022                	sd	s0,0(sp)
    800016f4:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    800016f6:	4601                	li	a2,0
    800016f8:	00000097          	auipc	ra,0x0
    800016fc:	94e080e7          	jalr	-1714(ra) # 80001046 <walk>
  if(pte == 0)
    80001700:	c901                	beqz	a0,80001710 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001702:	611c                	ld	a5,0(a0)
    80001704:	9bbd                	andi	a5,a5,-17
    80001706:	e11c                	sd	a5,0(a0)
}
    80001708:	60a2                	ld	ra,8(sp)
    8000170a:	6402                	ld	s0,0(sp)
    8000170c:	0141                	addi	sp,sp,16
    8000170e:	8082                	ret
    panic("uvmclear");
    80001710:	00007517          	auipc	a0,0x7
    80001714:	ac050513          	addi	a0,a0,-1344 # 800081d0 <digits+0x178>
    80001718:	fffff097          	auipc	ra,0xfffff
    8000171c:	eb8080e7          	jalr	-328(ra) # 800005d0 <panic>

0000000080001720 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001720:	c6bd                	beqz	a3,8000178e <copyout+0x6e>
{
    80001722:	715d                	addi	sp,sp,-80
    80001724:	e486                	sd	ra,72(sp)
    80001726:	e0a2                	sd	s0,64(sp)
    80001728:	fc26                	sd	s1,56(sp)
    8000172a:	f84a                	sd	s2,48(sp)
    8000172c:	f44e                	sd	s3,40(sp)
    8000172e:	f052                	sd	s4,32(sp)
    80001730:	ec56                	sd	s5,24(sp)
    80001732:	e85a                	sd	s6,16(sp)
    80001734:	e45e                	sd	s7,8(sp)
    80001736:	e062                	sd	s8,0(sp)
    80001738:	0880                	addi	s0,sp,80
    8000173a:	8b2a                	mv	s6,a0
    8000173c:	8c2e                	mv	s8,a1
    8000173e:	8a32                	mv	s4,a2
    80001740:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001742:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001744:	6a85                	lui	s5,0x1
    80001746:	a015                	j	8000176a <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001748:	9562                	add	a0,a0,s8
    8000174a:	0004861b          	sext.w	a2,s1
    8000174e:	85d2                	mv	a1,s4
    80001750:	41250533          	sub	a0,a0,s2
    80001754:	fffff097          	auipc	ra,0xfffff
    80001758:	666080e7          	jalr	1638(ra) # 80000dba <memmove>

    len -= n;
    8000175c:	409989b3          	sub	s3,s3,s1
    src += n;
    80001760:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001762:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001766:	02098263          	beqz	s3,8000178a <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    8000176a:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000176e:	85ca                	mv	a1,s2
    80001770:	855a                	mv	a0,s6
    80001772:	00000097          	auipc	ra,0x0
    80001776:	97a080e7          	jalr	-1670(ra) # 800010ec <walkaddr>
    if(pa0 == 0)
    8000177a:	cd01                	beqz	a0,80001792 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    8000177c:	418904b3          	sub	s1,s2,s8
    80001780:	94d6                	add	s1,s1,s5
    if(n > len)
    80001782:	fc99f3e3          	bgeu	s3,s1,80001748 <copyout+0x28>
    80001786:	84ce                	mv	s1,s3
    80001788:	b7c1                	j	80001748 <copyout+0x28>
  }
  return 0;
    8000178a:	4501                	li	a0,0
    8000178c:	a021                	j	80001794 <copyout+0x74>
    8000178e:	4501                	li	a0,0
}
    80001790:	8082                	ret
      return -1;
    80001792:	557d                	li	a0,-1
}
    80001794:	60a6                	ld	ra,72(sp)
    80001796:	6406                	ld	s0,64(sp)
    80001798:	74e2                	ld	s1,56(sp)
    8000179a:	7942                	ld	s2,48(sp)
    8000179c:	79a2                	ld	s3,40(sp)
    8000179e:	7a02                	ld	s4,32(sp)
    800017a0:	6ae2                	ld	s5,24(sp)
    800017a2:	6b42                	ld	s6,16(sp)
    800017a4:	6ba2                	ld	s7,8(sp)
    800017a6:	6c02                	ld	s8,0(sp)
    800017a8:	6161                	addi	sp,sp,80
    800017aa:	8082                	ret

00000000800017ac <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800017ac:	caa5                	beqz	a3,8000181c <copyin+0x70>
{
    800017ae:	715d                	addi	sp,sp,-80
    800017b0:	e486                	sd	ra,72(sp)
    800017b2:	e0a2                	sd	s0,64(sp)
    800017b4:	fc26                	sd	s1,56(sp)
    800017b6:	f84a                	sd	s2,48(sp)
    800017b8:	f44e                	sd	s3,40(sp)
    800017ba:	f052                	sd	s4,32(sp)
    800017bc:	ec56                	sd	s5,24(sp)
    800017be:	e85a                	sd	s6,16(sp)
    800017c0:	e45e                	sd	s7,8(sp)
    800017c2:	e062                	sd	s8,0(sp)
    800017c4:	0880                	addi	s0,sp,80
    800017c6:	8b2a                	mv	s6,a0
    800017c8:	8a2e                	mv	s4,a1
    800017ca:	8c32                	mv	s8,a2
    800017cc:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    800017ce:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017d0:	6a85                	lui	s5,0x1
    800017d2:	a01d                	j	800017f8 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    800017d4:	018505b3          	add	a1,a0,s8
    800017d8:	0004861b          	sext.w	a2,s1
    800017dc:	412585b3          	sub	a1,a1,s2
    800017e0:	8552                	mv	a0,s4
    800017e2:	fffff097          	auipc	ra,0xfffff
    800017e6:	5d8080e7          	jalr	1496(ra) # 80000dba <memmove>

    len -= n;
    800017ea:	409989b3          	sub	s3,s3,s1
    dst += n;
    800017ee:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    800017f0:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800017f4:	02098263          	beqz	s3,80001818 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    800017f8:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800017fc:	85ca                	mv	a1,s2
    800017fe:	855a                	mv	a0,s6
    80001800:	00000097          	auipc	ra,0x0
    80001804:	8ec080e7          	jalr	-1812(ra) # 800010ec <walkaddr>
    if(pa0 == 0)
    80001808:	cd01                	beqz	a0,80001820 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    8000180a:	418904b3          	sub	s1,s2,s8
    8000180e:	94d6                	add	s1,s1,s5
    if(n > len)
    80001810:	fc99f2e3          	bgeu	s3,s1,800017d4 <copyin+0x28>
    80001814:	84ce                	mv	s1,s3
    80001816:	bf7d                	j	800017d4 <copyin+0x28>
  }
  return 0;
    80001818:	4501                	li	a0,0
    8000181a:	a021                	j	80001822 <copyin+0x76>
    8000181c:	4501                	li	a0,0
}
    8000181e:	8082                	ret
      return -1;
    80001820:	557d                	li	a0,-1
}
    80001822:	60a6                	ld	ra,72(sp)
    80001824:	6406                	ld	s0,64(sp)
    80001826:	74e2                	ld	s1,56(sp)
    80001828:	7942                	ld	s2,48(sp)
    8000182a:	79a2                	ld	s3,40(sp)
    8000182c:	7a02                	ld	s4,32(sp)
    8000182e:	6ae2                	ld	s5,24(sp)
    80001830:	6b42                	ld	s6,16(sp)
    80001832:	6ba2                	ld	s7,8(sp)
    80001834:	6c02                	ld	s8,0(sp)
    80001836:	6161                	addi	sp,sp,80
    80001838:	8082                	ret

000000008000183a <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000183a:	c6c5                	beqz	a3,800018e2 <copyinstr+0xa8>
{
    8000183c:	715d                	addi	sp,sp,-80
    8000183e:	e486                	sd	ra,72(sp)
    80001840:	e0a2                	sd	s0,64(sp)
    80001842:	fc26                	sd	s1,56(sp)
    80001844:	f84a                	sd	s2,48(sp)
    80001846:	f44e                	sd	s3,40(sp)
    80001848:	f052                	sd	s4,32(sp)
    8000184a:	ec56                	sd	s5,24(sp)
    8000184c:	e85a                	sd	s6,16(sp)
    8000184e:	e45e                	sd	s7,8(sp)
    80001850:	0880                	addi	s0,sp,80
    80001852:	8a2a                	mv	s4,a0
    80001854:	8b2e                	mv	s6,a1
    80001856:	8bb2                	mv	s7,a2
    80001858:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    8000185a:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000185c:	6985                	lui	s3,0x1
    8000185e:	a035                	j	8000188a <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    80001860:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001864:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001866:	0017b793          	seqz	a5,a5
    8000186a:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    8000186e:	60a6                	ld	ra,72(sp)
    80001870:	6406                	ld	s0,64(sp)
    80001872:	74e2                	ld	s1,56(sp)
    80001874:	7942                	ld	s2,48(sp)
    80001876:	79a2                	ld	s3,40(sp)
    80001878:	7a02                	ld	s4,32(sp)
    8000187a:	6ae2                	ld	s5,24(sp)
    8000187c:	6b42                	ld	s6,16(sp)
    8000187e:	6ba2                	ld	s7,8(sp)
    80001880:	6161                	addi	sp,sp,80
    80001882:	8082                	ret
    srcva = va0 + PGSIZE;
    80001884:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    80001888:	c8a9                	beqz	s1,800018da <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    8000188a:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    8000188e:	85ca                	mv	a1,s2
    80001890:	8552                	mv	a0,s4
    80001892:	00000097          	auipc	ra,0x0
    80001896:	85a080e7          	jalr	-1958(ra) # 800010ec <walkaddr>
    if(pa0 == 0)
    8000189a:	c131                	beqz	a0,800018de <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    8000189c:	41790833          	sub	a6,s2,s7
    800018a0:	984e                	add	a6,a6,s3
    if(n > max)
    800018a2:	0104f363          	bgeu	s1,a6,800018a8 <copyinstr+0x6e>
    800018a6:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800018a8:	955e                	add	a0,a0,s7
    800018aa:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800018ae:	fc080be3          	beqz	a6,80001884 <copyinstr+0x4a>
    800018b2:	985a                	add	a6,a6,s6
    800018b4:	87da                	mv	a5,s6
      if(*p == '\0'){
    800018b6:	41650633          	sub	a2,a0,s6
    800018ba:	14fd                	addi	s1,s1,-1
    800018bc:	9b26                	add	s6,s6,s1
    800018be:	00f60733          	add	a4,a2,a5
    800018c2:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd4000>
    800018c6:	df49                	beqz	a4,80001860 <copyinstr+0x26>
        *dst = *p;
    800018c8:	00e78023          	sb	a4,0(a5)
      --max;
    800018cc:	40fb04b3          	sub	s1,s6,a5
      dst++;
    800018d0:	0785                	addi	a5,a5,1
    while(n > 0){
    800018d2:	ff0796e3          	bne	a5,a6,800018be <copyinstr+0x84>
      dst++;
    800018d6:	8b42                	mv	s6,a6
    800018d8:	b775                	j	80001884 <copyinstr+0x4a>
    800018da:	4781                	li	a5,0
    800018dc:	b769                	j	80001866 <copyinstr+0x2c>
      return -1;
    800018de:	557d                	li	a0,-1
    800018e0:	b779                	j	8000186e <copyinstr+0x34>
  int got_null = 0;
    800018e2:	4781                	li	a5,0
  if(got_null){
    800018e4:	0017b793          	seqz	a5,a5
    800018e8:	40f00533          	neg	a0,a5
}
    800018ec:	8082                	ret

00000000800018ee <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    800018ee:	1101                	addi	sp,sp,-32
    800018f0:	ec06                	sd	ra,24(sp)
    800018f2:	e822                	sd	s0,16(sp)
    800018f4:	e426                	sd	s1,8(sp)
    800018f6:	1000                	addi	s0,sp,32
    800018f8:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    800018fa:	fffff097          	auipc	ra,0xfffff
    800018fe:	2ee080e7          	jalr	750(ra) # 80000be8 <holding>
    80001902:	c909                	beqz	a0,80001914 <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    80001904:	749c                	ld	a5,40(s1)
    80001906:	00978f63          	beq	a5,s1,80001924 <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    8000190a:	60e2                	ld	ra,24(sp)
    8000190c:	6442                	ld	s0,16(sp)
    8000190e:	64a2                	ld	s1,8(sp)
    80001910:	6105                	addi	sp,sp,32
    80001912:	8082                	ret
    panic("wakeup1");
    80001914:	00007517          	auipc	a0,0x7
    80001918:	8cc50513          	addi	a0,a0,-1844 # 800081e0 <digits+0x188>
    8000191c:	fffff097          	auipc	ra,0xfffff
    80001920:	cb4080e7          	jalr	-844(ra) # 800005d0 <panic>
  if(p->chan == p && p->state == SLEEPING) {
    80001924:	4c98                	lw	a4,24(s1)
    80001926:	4785                	li	a5,1
    80001928:	fef711e3          	bne	a4,a5,8000190a <wakeup1+0x1c>
    p->state = RUNNABLE;
    8000192c:	4789                	li	a5,2
    8000192e:	cc9c                	sw	a5,24(s1)
}
    80001930:	bfe9                	j	8000190a <wakeup1+0x1c>

0000000080001932 <procinit>:
{
    80001932:	715d                	addi	sp,sp,-80
    80001934:	e486                	sd	ra,72(sp)
    80001936:	e0a2                	sd	s0,64(sp)
    80001938:	fc26                	sd	s1,56(sp)
    8000193a:	f84a                	sd	s2,48(sp)
    8000193c:	f44e                	sd	s3,40(sp)
    8000193e:	f052                	sd	s4,32(sp)
    80001940:	ec56                	sd	s5,24(sp)
    80001942:	e85a                	sd	s6,16(sp)
    80001944:	e45e                	sd	s7,8(sp)
    80001946:	0880                	addi	s0,sp,80
  initlock(&pid_lock, "nextpid");
    80001948:	00007597          	auipc	a1,0x7
    8000194c:	8a058593          	addi	a1,a1,-1888 # 800081e8 <digits+0x190>
    80001950:	00010517          	auipc	a0,0x10
    80001954:	00050513          	mv	a0,a0
    80001958:	fffff097          	auipc	ra,0xfffff
    8000195c:	27a080e7          	jalr	634(ra) # 80000bd2 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001960:	00010917          	auipc	s2,0x10
    80001964:	40890913          	addi	s2,s2,1032 # 80011d68 <proc>
      initlock(&p->lock, "proc");
    80001968:	00007b97          	auipc	s7,0x7
    8000196c:	888b8b93          	addi	s7,s7,-1912 # 800081f0 <digits+0x198>
      uint64 va = KSTACK((int) (p - proc));
    80001970:	8b4a                	mv	s6,s2
    80001972:	00006a97          	auipc	s5,0x6
    80001976:	68ea8a93          	addi	s5,s5,1678 # 80008000 <etext>
    8000197a:	040009b7          	lui	s3,0x4000
    8000197e:	19fd                	addi	s3,s3,-1
    80001980:	09b2                	slli	s3,s3,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001982:	0001aa17          	auipc	s4,0x1a
    80001986:	5e6a0a13          	addi	s4,s4,1510 # 8001bf68 <tickslock>
      initlock(&p->lock, "proc");
    8000198a:	85de                	mv	a1,s7
    8000198c:	854a                	mv	a0,s2
    8000198e:	fffff097          	auipc	ra,0xfffff
    80001992:	244080e7          	jalr	580(ra) # 80000bd2 <initlock>
      char *pa = kalloc();
    80001996:	fffff097          	auipc	ra,0xfffff
    8000199a:	1dc080e7          	jalr	476(ra) # 80000b72 <kalloc>
    8000199e:	85aa                	mv	a1,a0
      if(pa == 0)
    800019a0:	c929                	beqz	a0,800019f2 <procinit+0xc0>
      uint64 va = KSTACK((int) (p - proc));
    800019a2:	416904b3          	sub	s1,s2,s6
    800019a6:	848d                	srai	s1,s1,0x3
    800019a8:	000ab783          	ld	a5,0(s5)
    800019ac:	02f484b3          	mul	s1,s1,a5
    800019b0:	2485                	addiw	s1,s1,1
    800019b2:	00d4949b          	slliw	s1,s1,0xd
    800019b6:	409984b3          	sub	s1,s3,s1
      kvmmap(va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800019ba:	4699                	li	a3,6
    800019bc:	6605                	lui	a2,0x1
    800019be:	8526                	mv	a0,s1
    800019c0:	00000097          	auipc	ra,0x0
    800019c4:	85a080e7          	jalr	-1958(ra) # 8000121a <kvmmap>
      p->kstack = va;
    800019c8:	04993023          	sd	s1,64(s2)
  for(p = proc; p < &proc[NPROC]; p++) {
    800019cc:	28890913          	addi	s2,s2,648
    800019d0:	fb491de3          	bne	s2,s4,8000198a <procinit+0x58>
  kvminithart();
    800019d4:	fffff097          	auipc	ra,0xfffff
    800019d8:	64e080e7          	jalr	1614(ra) # 80001022 <kvminithart>
}
    800019dc:	60a6                	ld	ra,72(sp)
    800019de:	6406                	ld	s0,64(sp)
    800019e0:	74e2                	ld	s1,56(sp)
    800019e2:	7942                	ld	s2,48(sp)
    800019e4:	79a2                	ld	s3,40(sp)
    800019e6:	7a02                	ld	s4,32(sp)
    800019e8:	6ae2                	ld	s5,24(sp)
    800019ea:	6b42                	ld	s6,16(sp)
    800019ec:	6ba2                	ld	s7,8(sp)
    800019ee:	6161                	addi	sp,sp,80
    800019f0:	8082                	ret
        panic("kalloc");
    800019f2:	00007517          	auipc	a0,0x7
    800019f6:	80650513          	addi	a0,a0,-2042 # 800081f8 <digits+0x1a0>
    800019fa:	fffff097          	auipc	ra,0xfffff
    800019fe:	bd6080e7          	jalr	-1066(ra) # 800005d0 <panic>

0000000080001a02 <cpuid>:
{
    80001a02:	1141                	addi	sp,sp,-16
    80001a04:	e422                	sd	s0,8(sp)
    80001a06:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001a08:	8512                	mv	a0,tp
}
    80001a0a:	2501                	sext.w	a0,a0
    80001a0c:	6422                	ld	s0,8(sp)
    80001a0e:	0141                	addi	sp,sp,16
    80001a10:	8082                	ret

0000000080001a12 <mycpu>:
mycpu(void) {
    80001a12:	1141                	addi	sp,sp,-16
    80001a14:	e422                	sd	s0,8(sp)
    80001a16:	0800                	addi	s0,sp,16
    80001a18:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    80001a1a:	2781                	sext.w	a5,a5
    80001a1c:	079e                	slli	a5,a5,0x7
}
    80001a1e:	00010517          	auipc	a0,0x10
    80001a22:	f4a50513          	addi	a0,a0,-182 # 80011968 <cpus>
    80001a26:	953e                	add	a0,a0,a5
    80001a28:	6422                	ld	s0,8(sp)
    80001a2a:	0141                	addi	sp,sp,16
    80001a2c:	8082                	ret

0000000080001a2e <myproc>:
myproc(void) {
    80001a2e:	1101                	addi	sp,sp,-32
    80001a30:	ec06                	sd	ra,24(sp)
    80001a32:	e822                	sd	s0,16(sp)
    80001a34:	e426                	sd	s1,8(sp)
    80001a36:	1000                	addi	s0,sp,32
  push_off();
    80001a38:	fffff097          	auipc	ra,0xfffff
    80001a3c:	1de080e7          	jalr	478(ra) # 80000c16 <push_off>
    80001a40:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    80001a42:	2781                	sext.w	a5,a5
    80001a44:	079e                	slli	a5,a5,0x7
    80001a46:	00010717          	auipc	a4,0x10
    80001a4a:	f0a70713          	addi	a4,a4,-246 # 80011950 <pid_lock>
    80001a4e:	97ba                	add	a5,a5,a4
    80001a50:	6f84                	ld	s1,24(a5)
  pop_off();
    80001a52:	fffff097          	auipc	ra,0xfffff
    80001a56:	264080e7          	jalr	612(ra) # 80000cb6 <pop_off>
}
    80001a5a:	8526                	mv	a0,s1
    80001a5c:	60e2                	ld	ra,24(sp)
    80001a5e:	6442                	ld	s0,16(sp)
    80001a60:	64a2                	ld	s1,8(sp)
    80001a62:	6105                	addi	sp,sp,32
    80001a64:	8082                	ret

0000000080001a66 <forkret>:
{
    80001a66:	1141                	addi	sp,sp,-16
    80001a68:	e406                	sd	ra,8(sp)
    80001a6a:	e022                	sd	s0,0(sp)
    80001a6c:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80001a6e:	00000097          	auipc	ra,0x0
    80001a72:	fc0080e7          	jalr	-64(ra) # 80001a2e <myproc>
    80001a76:	fffff097          	auipc	ra,0xfffff
    80001a7a:	2a0080e7          	jalr	672(ra) # 80000d16 <release>
  if (first) {
    80001a7e:	00007797          	auipc	a5,0x7
    80001a82:	dd27a783          	lw	a5,-558(a5) # 80008850 <first.1>
    80001a86:	eb89                	bnez	a5,80001a98 <forkret+0x32>
  usertrapret();
    80001a88:	00001097          	auipc	ra,0x1
    80001a8c:	c2a080e7          	jalr	-982(ra) # 800026b2 <usertrapret>
}
    80001a90:	60a2                	ld	ra,8(sp)
    80001a92:	6402                	ld	s0,0(sp)
    80001a94:	0141                	addi	sp,sp,16
    80001a96:	8082                	ret
    first = 0;
    80001a98:	00007797          	auipc	a5,0x7
    80001a9c:	da07ac23          	sw	zero,-584(a5) # 80008850 <first.1>
    fsinit(ROOTDEV);
    80001aa0:	4505                	li	a0,1
    80001aa2:	00002097          	auipc	ra,0x2
    80001aa6:	c18080e7          	jalr	-1000(ra) # 800036ba <fsinit>
    80001aaa:	bff9                	j	80001a88 <forkret+0x22>

0000000080001aac <allocpid>:
allocpid() {
    80001aac:	1101                	addi	sp,sp,-32
    80001aae:	ec06                	sd	ra,24(sp)
    80001ab0:	e822                	sd	s0,16(sp)
    80001ab2:	e426                	sd	s1,8(sp)
    80001ab4:	e04a                	sd	s2,0(sp)
    80001ab6:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001ab8:	00010917          	auipc	s2,0x10
    80001abc:	e9890913          	addi	s2,s2,-360 # 80011950 <pid_lock>
    80001ac0:	854a                	mv	a0,s2
    80001ac2:	fffff097          	auipc	ra,0xfffff
    80001ac6:	1a0080e7          	jalr	416(ra) # 80000c62 <acquire>
  pid = nextpid;
    80001aca:	00007797          	auipc	a5,0x7
    80001ace:	d8a78793          	addi	a5,a5,-630 # 80008854 <nextpid>
    80001ad2:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001ad4:	0014871b          	addiw	a4,s1,1
    80001ad8:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001ada:	854a                	mv	a0,s2
    80001adc:	fffff097          	auipc	ra,0xfffff
    80001ae0:	23a080e7          	jalr	570(ra) # 80000d16 <release>
}
    80001ae4:	8526                	mv	a0,s1
    80001ae6:	60e2                	ld	ra,24(sp)
    80001ae8:	6442                	ld	s0,16(sp)
    80001aea:	64a2                	ld	s1,8(sp)
    80001aec:	6902                	ld	s2,0(sp)
    80001aee:	6105                	addi	sp,sp,32
    80001af0:	8082                	ret

0000000080001af2 <proc_pagetable>:
{
    80001af2:	1101                	addi	sp,sp,-32
    80001af4:	ec06                	sd	ra,24(sp)
    80001af6:	e822                	sd	s0,16(sp)
    80001af8:	e426                	sd	s1,8(sp)
    80001afa:	e04a                	sd	s2,0(sp)
    80001afc:	1000                	addi	s0,sp,32
    80001afe:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001b00:	00000097          	auipc	ra,0x0
    80001b04:	8e8080e7          	jalr	-1816(ra) # 800013e8 <uvmcreate>
    80001b08:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001b0a:	c121                	beqz	a0,80001b4a <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001b0c:	4729                	li	a4,10
    80001b0e:	00005697          	auipc	a3,0x5
    80001b12:	4f268693          	addi	a3,a3,1266 # 80007000 <_trampoline>
    80001b16:	6605                	lui	a2,0x1
    80001b18:	040005b7          	lui	a1,0x4000
    80001b1c:	15fd                	addi	a1,a1,-1
    80001b1e:	05b2                	slli	a1,a1,0xc
    80001b20:	fffff097          	auipc	ra,0xfffff
    80001b24:	66c080e7          	jalr	1644(ra) # 8000118c <mappages>
    80001b28:	02054863          	bltz	a0,80001b58 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001b2c:	4719                	li	a4,6
    80001b2e:	05893683          	ld	a3,88(s2)
    80001b32:	6605                	lui	a2,0x1
    80001b34:	020005b7          	lui	a1,0x2000
    80001b38:	15fd                	addi	a1,a1,-1
    80001b3a:	05b6                	slli	a1,a1,0xd
    80001b3c:	8526                	mv	a0,s1
    80001b3e:	fffff097          	auipc	ra,0xfffff
    80001b42:	64e080e7          	jalr	1614(ra) # 8000118c <mappages>
    80001b46:	02054163          	bltz	a0,80001b68 <proc_pagetable+0x76>
}
    80001b4a:	8526                	mv	a0,s1
    80001b4c:	60e2                	ld	ra,24(sp)
    80001b4e:	6442                	ld	s0,16(sp)
    80001b50:	64a2                	ld	s1,8(sp)
    80001b52:	6902                	ld	s2,0(sp)
    80001b54:	6105                	addi	sp,sp,32
    80001b56:	8082                	ret
    uvmfree(pagetable, 0);
    80001b58:	4581                	li	a1,0
    80001b5a:	8526                	mv	a0,s1
    80001b5c:	00000097          	auipc	ra,0x0
    80001b60:	a88080e7          	jalr	-1400(ra) # 800015e4 <uvmfree>
    return 0;
    80001b64:	4481                	li	s1,0
    80001b66:	b7d5                	j	80001b4a <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b68:	4681                	li	a3,0
    80001b6a:	4605                	li	a2,1
    80001b6c:	040005b7          	lui	a1,0x4000
    80001b70:	15fd                	addi	a1,a1,-1
    80001b72:	05b2                	slli	a1,a1,0xc
    80001b74:	8526                	mv	a0,s1
    80001b76:	fffff097          	auipc	ra,0xfffff
    80001b7a:	7ae080e7          	jalr	1966(ra) # 80001324 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b7e:	4581                	li	a1,0
    80001b80:	8526                	mv	a0,s1
    80001b82:	00000097          	auipc	ra,0x0
    80001b86:	a62080e7          	jalr	-1438(ra) # 800015e4 <uvmfree>
    return 0;
    80001b8a:	4481                	li	s1,0
    80001b8c:	bf7d                	j	80001b4a <proc_pagetable+0x58>

0000000080001b8e <proc_freepagetable>:
{
    80001b8e:	1101                	addi	sp,sp,-32
    80001b90:	ec06                	sd	ra,24(sp)
    80001b92:	e822                	sd	s0,16(sp)
    80001b94:	e426                	sd	s1,8(sp)
    80001b96:	e04a                	sd	s2,0(sp)
    80001b98:	1000                	addi	s0,sp,32
    80001b9a:	84aa                	mv	s1,a0
    80001b9c:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b9e:	4681                	li	a3,0
    80001ba0:	4605                	li	a2,1
    80001ba2:	040005b7          	lui	a1,0x4000
    80001ba6:	15fd                	addi	a1,a1,-1
    80001ba8:	05b2                	slli	a1,a1,0xc
    80001baa:	fffff097          	auipc	ra,0xfffff
    80001bae:	77a080e7          	jalr	1914(ra) # 80001324 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001bb2:	4681                	li	a3,0
    80001bb4:	4605                	li	a2,1
    80001bb6:	020005b7          	lui	a1,0x2000
    80001bba:	15fd                	addi	a1,a1,-1
    80001bbc:	05b6                	slli	a1,a1,0xd
    80001bbe:	8526                	mv	a0,s1
    80001bc0:	fffff097          	auipc	ra,0xfffff
    80001bc4:	764080e7          	jalr	1892(ra) # 80001324 <uvmunmap>
  uvmfree(pagetable, sz);
    80001bc8:	85ca                	mv	a1,s2
    80001bca:	8526                	mv	a0,s1
    80001bcc:	00000097          	auipc	ra,0x0
    80001bd0:	a18080e7          	jalr	-1512(ra) # 800015e4 <uvmfree>
}
    80001bd4:	60e2                	ld	ra,24(sp)
    80001bd6:	6442                	ld	s0,16(sp)
    80001bd8:	64a2                	ld	s1,8(sp)
    80001bda:	6902                	ld	s2,0(sp)
    80001bdc:	6105                	addi	sp,sp,32
    80001bde:	8082                	ret

0000000080001be0 <freeproc>:
{
    80001be0:	1101                	addi	sp,sp,-32
    80001be2:	ec06                	sd	ra,24(sp)
    80001be4:	e822                	sd	s0,16(sp)
    80001be6:	e426                	sd	s1,8(sp)
    80001be8:	1000                	addi	s0,sp,32
    80001bea:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001bec:	6d28                	ld	a0,88(a0)
    80001bee:	c509                	beqz	a0,80001bf8 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001bf0:	fffff097          	auipc	ra,0xfffff
    80001bf4:	e86080e7          	jalr	-378(ra) # 80000a76 <kfree>
  p->trapframe = 0;
    80001bf8:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001bfc:	68a8                	ld	a0,80(s1)
    80001bfe:	c511                	beqz	a0,80001c0a <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001c00:	64ac                	ld	a1,72(s1)
    80001c02:	00000097          	auipc	ra,0x0
    80001c06:	f8c080e7          	jalr	-116(ra) # 80001b8e <proc_freepagetable>
  p->pagetable = 0;
    80001c0a:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001c0e:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001c12:	0204ac23          	sw	zero,56(s1)
  p->parent = 0;
    80001c16:	0204b023          	sd	zero,32(s1)
  p->name[0] = 0;
    80001c1a:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001c1e:	0204b423          	sd	zero,40(s1)
  p->killed = 0;
    80001c22:	0204a823          	sw	zero,48(s1)
  p->xstate = 0;
    80001c26:	0204aa23          	sw	zero,52(s1)
  p->state = UNUSED;
    80001c2a:	0004ac23          	sw	zero,24(s1)
}
    80001c2e:	60e2                	ld	ra,24(sp)
    80001c30:	6442                	ld	s0,16(sp)
    80001c32:	64a2                	ld	s1,8(sp)
    80001c34:	6105                	addi	sp,sp,32
    80001c36:	8082                	ret

0000000080001c38 <allocproc>:
{
    80001c38:	1101                	addi	sp,sp,-32
    80001c3a:	ec06                	sd	ra,24(sp)
    80001c3c:	e822                	sd	s0,16(sp)
    80001c3e:	e426                	sd	s1,8(sp)
    80001c40:	e04a                	sd	s2,0(sp)
    80001c42:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c44:	00010497          	auipc	s1,0x10
    80001c48:	12448493          	addi	s1,s1,292 # 80011d68 <proc>
    80001c4c:	0001a917          	auipc	s2,0x1a
    80001c50:	31c90913          	addi	s2,s2,796 # 8001bf68 <tickslock>
    acquire(&p->lock);
    80001c54:	8526                	mv	a0,s1
    80001c56:	fffff097          	auipc	ra,0xfffff
    80001c5a:	00c080e7          	jalr	12(ra) # 80000c62 <acquire>
    if(p->state == UNUSED) {
    80001c5e:	4c9c                	lw	a5,24(s1)
    80001c60:	cf81                	beqz	a5,80001c78 <allocproc+0x40>
      release(&p->lock);
    80001c62:	8526                	mv	a0,s1
    80001c64:	fffff097          	auipc	ra,0xfffff
    80001c68:	0b2080e7          	jalr	178(ra) # 80000d16 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c6c:	28848493          	addi	s1,s1,648
    80001c70:	ff2492e3          	bne	s1,s2,80001c54 <allocproc+0x1c>
  return 0;
    80001c74:	4481                	li	s1,0
    80001c76:	a08d                	j	80001cd8 <allocproc+0xa0>
  p->handle = 0;
    80001c78:	1604b423          	sd	zero,360(s1)
  p->count_of_trick = 0;
    80001c7c:	1604aa23          	sw	zero,372(s1)
  p->alarm_interval = 0;
    80001c80:	1604a823          	sw	zero,368(s1)
  p->is_alarm = 0;
    80001c84:	1604ac23          	sw	zero,376(s1)
  p->in_alarm_handler = 0;
    80001c88:	2804a023          	sw	zero,640(s1)
  p->pid = allocpid();
    80001c8c:	00000097          	auipc	ra,0x0
    80001c90:	e20080e7          	jalr	-480(ra) # 80001aac <allocpid>
    80001c94:	dc88                	sw	a0,56(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c96:	fffff097          	auipc	ra,0xfffff
    80001c9a:	edc080e7          	jalr	-292(ra) # 80000b72 <kalloc>
    80001c9e:	892a                	mv	s2,a0
    80001ca0:	eca8                	sd	a0,88(s1)
    80001ca2:	c131                	beqz	a0,80001ce6 <allocproc+0xae>
  p->pagetable = proc_pagetable(p);
    80001ca4:	8526                	mv	a0,s1
    80001ca6:	00000097          	auipc	ra,0x0
    80001caa:	e4c080e7          	jalr	-436(ra) # 80001af2 <proc_pagetable>
    80001cae:	892a                	mv	s2,a0
    80001cb0:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001cb2:	c129                	beqz	a0,80001cf4 <allocproc+0xbc>
  memset(&p->context, 0, sizeof(p->context));
    80001cb4:	07000613          	li	a2,112
    80001cb8:	4581                	li	a1,0
    80001cba:	06048513          	addi	a0,s1,96
    80001cbe:	fffff097          	auipc	ra,0xfffff
    80001cc2:	0a0080e7          	jalr	160(ra) # 80000d5e <memset>
  p->context.ra = (uint64)forkret;
    80001cc6:	00000797          	auipc	a5,0x0
    80001cca:	da078793          	addi	a5,a5,-608 # 80001a66 <forkret>
    80001cce:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001cd0:	60bc                	ld	a5,64(s1)
    80001cd2:	6705                	lui	a4,0x1
    80001cd4:	97ba                	add	a5,a5,a4
    80001cd6:	f4bc                	sd	a5,104(s1)
}
    80001cd8:	8526                	mv	a0,s1
    80001cda:	60e2                	ld	ra,24(sp)
    80001cdc:	6442                	ld	s0,16(sp)
    80001cde:	64a2                	ld	s1,8(sp)
    80001ce0:	6902                	ld	s2,0(sp)
    80001ce2:	6105                	addi	sp,sp,32
    80001ce4:	8082                	ret
    release(&p->lock);
    80001ce6:	8526                	mv	a0,s1
    80001ce8:	fffff097          	auipc	ra,0xfffff
    80001cec:	02e080e7          	jalr	46(ra) # 80000d16 <release>
    return 0;
    80001cf0:	84ca                	mv	s1,s2
    80001cf2:	b7dd                	j	80001cd8 <allocproc+0xa0>
    freeproc(p);
    80001cf4:	8526                	mv	a0,s1
    80001cf6:	00000097          	auipc	ra,0x0
    80001cfa:	eea080e7          	jalr	-278(ra) # 80001be0 <freeproc>
    release(&p->lock);
    80001cfe:	8526                	mv	a0,s1
    80001d00:	fffff097          	auipc	ra,0xfffff
    80001d04:	016080e7          	jalr	22(ra) # 80000d16 <release>
    return 0;
    80001d08:	84ca                	mv	s1,s2
    80001d0a:	b7f9                	j	80001cd8 <allocproc+0xa0>

0000000080001d0c <userinit>:
{
    80001d0c:	1101                	addi	sp,sp,-32
    80001d0e:	ec06                	sd	ra,24(sp)
    80001d10:	e822                	sd	s0,16(sp)
    80001d12:	e426                	sd	s1,8(sp)
    80001d14:	1000                	addi	s0,sp,32
  p = allocproc();
    80001d16:	00000097          	auipc	ra,0x0
    80001d1a:	f22080e7          	jalr	-222(ra) # 80001c38 <allocproc>
    80001d1e:	84aa                	mv	s1,a0
  initproc = p;
    80001d20:	00007797          	auipc	a5,0x7
    80001d24:	2ea7bc23          	sd	a0,760(a5) # 80009018 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001d28:	03400613          	li	a2,52
    80001d2c:	00007597          	auipc	a1,0x7
    80001d30:	b3458593          	addi	a1,a1,-1228 # 80008860 <initcode>
    80001d34:	6928                	ld	a0,80(a0)
    80001d36:	fffff097          	auipc	ra,0xfffff
    80001d3a:	6e0080e7          	jalr	1760(ra) # 80001416 <uvminit>
  p->sz = PGSIZE;
    80001d3e:	6785                	lui	a5,0x1
    80001d40:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001d42:	6cb8                	ld	a4,88(s1)
    80001d44:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001d48:	6cb8                	ld	a4,88(s1)
    80001d4a:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d4c:	4641                	li	a2,16
    80001d4e:	00006597          	auipc	a1,0x6
    80001d52:	4b258593          	addi	a1,a1,1202 # 80008200 <digits+0x1a8>
    80001d56:	15848513          	addi	a0,s1,344
    80001d5a:	fffff097          	auipc	ra,0xfffff
    80001d5e:	156080e7          	jalr	342(ra) # 80000eb0 <safestrcpy>
  p->cwd = namei("/");
    80001d62:	00006517          	auipc	a0,0x6
    80001d66:	4ae50513          	addi	a0,a0,1198 # 80008210 <digits+0x1b8>
    80001d6a:	00002097          	auipc	ra,0x2
    80001d6e:	378080e7          	jalr	888(ra) # 800040e2 <namei>
    80001d72:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d76:	4789                	li	a5,2
    80001d78:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d7a:	8526                	mv	a0,s1
    80001d7c:	fffff097          	auipc	ra,0xfffff
    80001d80:	f9a080e7          	jalr	-102(ra) # 80000d16 <release>
}
    80001d84:	60e2                	ld	ra,24(sp)
    80001d86:	6442                	ld	s0,16(sp)
    80001d88:	64a2                	ld	s1,8(sp)
    80001d8a:	6105                	addi	sp,sp,32
    80001d8c:	8082                	ret

0000000080001d8e <growproc>:
{
    80001d8e:	1101                	addi	sp,sp,-32
    80001d90:	ec06                	sd	ra,24(sp)
    80001d92:	e822                	sd	s0,16(sp)
    80001d94:	e426                	sd	s1,8(sp)
    80001d96:	e04a                	sd	s2,0(sp)
    80001d98:	1000                	addi	s0,sp,32
    80001d9a:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d9c:	00000097          	auipc	ra,0x0
    80001da0:	c92080e7          	jalr	-878(ra) # 80001a2e <myproc>
    80001da4:	892a                	mv	s2,a0
  sz = p->sz;
    80001da6:	652c                	ld	a1,72(a0)
    80001da8:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001dac:	00904f63          	bgtz	s1,80001dca <growproc+0x3c>
  } else if(n < 0){
    80001db0:	0204cc63          	bltz	s1,80001de8 <growproc+0x5a>
  p->sz = sz;
    80001db4:	1602                	slli	a2,a2,0x20
    80001db6:	9201                	srli	a2,a2,0x20
    80001db8:	04c93423          	sd	a2,72(s2)
  return 0;
    80001dbc:	4501                	li	a0,0
}
    80001dbe:	60e2                	ld	ra,24(sp)
    80001dc0:	6442                	ld	s0,16(sp)
    80001dc2:	64a2                	ld	s1,8(sp)
    80001dc4:	6902                	ld	s2,0(sp)
    80001dc6:	6105                	addi	sp,sp,32
    80001dc8:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001dca:	9e25                	addw	a2,a2,s1
    80001dcc:	1602                	slli	a2,a2,0x20
    80001dce:	9201                	srli	a2,a2,0x20
    80001dd0:	1582                	slli	a1,a1,0x20
    80001dd2:	9181                	srli	a1,a1,0x20
    80001dd4:	6928                	ld	a0,80(a0)
    80001dd6:	fffff097          	auipc	ra,0xfffff
    80001dda:	6fa080e7          	jalr	1786(ra) # 800014d0 <uvmalloc>
    80001dde:	0005061b          	sext.w	a2,a0
    80001de2:	fa69                	bnez	a2,80001db4 <growproc+0x26>
      return -1;
    80001de4:	557d                	li	a0,-1
    80001de6:	bfe1                	j	80001dbe <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001de8:	9e25                	addw	a2,a2,s1
    80001dea:	1602                	slli	a2,a2,0x20
    80001dec:	9201                	srli	a2,a2,0x20
    80001dee:	1582                	slli	a1,a1,0x20
    80001df0:	9181                	srli	a1,a1,0x20
    80001df2:	6928                	ld	a0,80(a0)
    80001df4:	fffff097          	auipc	ra,0xfffff
    80001df8:	694080e7          	jalr	1684(ra) # 80001488 <uvmdealloc>
    80001dfc:	0005061b          	sext.w	a2,a0
    80001e00:	bf55                	j	80001db4 <growproc+0x26>

0000000080001e02 <fork>:
{
    80001e02:	7139                	addi	sp,sp,-64
    80001e04:	fc06                	sd	ra,56(sp)
    80001e06:	f822                	sd	s0,48(sp)
    80001e08:	f426                	sd	s1,40(sp)
    80001e0a:	f04a                	sd	s2,32(sp)
    80001e0c:	ec4e                	sd	s3,24(sp)
    80001e0e:	e852                	sd	s4,16(sp)
    80001e10:	e456                	sd	s5,8(sp)
    80001e12:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001e14:	00000097          	auipc	ra,0x0
    80001e18:	c1a080e7          	jalr	-998(ra) # 80001a2e <myproc>
    80001e1c:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001e1e:	00000097          	auipc	ra,0x0
    80001e22:	e1a080e7          	jalr	-486(ra) # 80001c38 <allocproc>
    80001e26:	c17d                	beqz	a0,80001f0c <fork+0x10a>
    80001e28:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001e2a:	048ab603          	ld	a2,72(s5)
    80001e2e:	692c                	ld	a1,80(a0)
    80001e30:	050ab503          	ld	a0,80(s5)
    80001e34:	fffff097          	auipc	ra,0xfffff
    80001e38:	7e8080e7          	jalr	2024(ra) # 8000161c <uvmcopy>
    80001e3c:	04054a63          	bltz	a0,80001e90 <fork+0x8e>
  np->sz = p->sz;
    80001e40:	048ab783          	ld	a5,72(s5)
    80001e44:	04fa3423          	sd	a5,72(s4)
  np->parent = p;
    80001e48:	035a3023          	sd	s5,32(s4)
  *(np->trapframe) = *(p->trapframe);
    80001e4c:	058ab683          	ld	a3,88(s5)
    80001e50:	87b6                	mv	a5,a3
    80001e52:	058a3703          	ld	a4,88(s4)
    80001e56:	12068693          	addi	a3,a3,288
    80001e5a:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001e5e:	6788                	ld	a0,8(a5)
    80001e60:	6b8c                	ld	a1,16(a5)
    80001e62:	6f90                	ld	a2,24(a5)
    80001e64:	01073023          	sd	a6,0(a4)
    80001e68:	e708                	sd	a0,8(a4)
    80001e6a:	eb0c                	sd	a1,16(a4)
    80001e6c:	ef10                	sd	a2,24(a4)
    80001e6e:	02078793          	addi	a5,a5,32
    80001e72:	02070713          	addi	a4,a4,32
    80001e76:	fed792e3          	bne	a5,a3,80001e5a <fork+0x58>
  np->trapframe->a0 = 0;
    80001e7a:	058a3783          	ld	a5,88(s4)
    80001e7e:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001e82:	0d0a8493          	addi	s1,s5,208
    80001e86:	0d0a0913          	addi	s2,s4,208
    80001e8a:	150a8993          	addi	s3,s5,336
    80001e8e:	a00d                	j	80001eb0 <fork+0xae>
    freeproc(np);
    80001e90:	8552                	mv	a0,s4
    80001e92:	00000097          	auipc	ra,0x0
    80001e96:	d4e080e7          	jalr	-690(ra) # 80001be0 <freeproc>
    release(&np->lock);
    80001e9a:	8552                	mv	a0,s4
    80001e9c:	fffff097          	auipc	ra,0xfffff
    80001ea0:	e7a080e7          	jalr	-390(ra) # 80000d16 <release>
    return -1;
    80001ea4:	54fd                	li	s1,-1
    80001ea6:	a889                	j	80001ef8 <fork+0xf6>
  for(i = 0; i < NOFILE; i++)
    80001ea8:	04a1                	addi	s1,s1,8
    80001eaa:	0921                	addi	s2,s2,8
    80001eac:	01348b63          	beq	s1,s3,80001ec2 <fork+0xc0>
    if(p->ofile[i])
    80001eb0:	6088                	ld	a0,0(s1)
    80001eb2:	d97d                	beqz	a0,80001ea8 <fork+0xa6>
      np->ofile[i] = filedup(p->ofile[i]);
    80001eb4:	00003097          	auipc	ra,0x3
    80001eb8:	8be080e7          	jalr	-1858(ra) # 80004772 <filedup>
    80001ebc:	00a93023          	sd	a0,0(s2)
    80001ec0:	b7e5                	j	80001ea8 <fork+0xa6>
  np->cwd = idup(p->cwd);
    80001ec2:	150ab503          	ld	a0,336(s5)
    80001ec6:	00002097          	auipc	ra,0x2
    80001eca:	a2e080e7          	jalr	-1490(ra) # 800038f4 <idup>
    80001ece:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001ed2:	4641                	li	a2,16
    80001ed4:	158a8593          	addi	a1,s5,344
    80001ed8:	158a0513          	addi	a0,s4,344
    80001edc:	fffff097          	auipc	ra,0xfffff
    80001ee0:	fd4080e7          	jalr	-44(ra) # 80000eb0 <safestrcpy>
  pid = np->pid;
    80001ee4:	038a2483          	lw	s1,56(s4)
  np->state = RUNNABLE;
    80001ee8:	4789                	li	a5,2
    80001eea:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001eee:	8552                	mv	a0,s4
    80001ef0:	fffff097          	auipc	ra,0xfffff
    80001ef4:	e26080e7          	jalr	-474(ra) # 80000d16 <release>
}
    80001ef8:	8526                	mv	a0,s1
    80001efa:	70e2                	ld	ra,56(sp)
    80001efc:	7442                	ld	s0,48(sp)
    80001efe:	74a2                	ld	s1,40(sp)
    80001f00:	7902                	ld	s2,32(sp)
    80001f02:	69e2                	ld	s3,24(sp)
    80001f04:	6a42                	ld	s4,16(sp)
    80001f06:	6aa2                	ld	s5,8(sp)
    80001f08:	6121                	addi	sp,sp,64
    80001f0a:	8082                	ret
    return -1;
    80001f0c:	54fd                	li	s1,-1
    80001f0e:	b7ed                	j	80001ef8 <fork+0xf6>

0000000080001f10 <reparent>:
{
    80001f10:	7179                	addi	sp,sp,-48
    80001f12:	f406                	sd	ra,40(sp)
    80001f14:	f022                	sd	s0,32(sp)
    80001f16:	ec26                	sd	s1,24(sp)
    80001f18:	e84a                	sd	s2,16(sp)
    80001f1a:	e44e                	sd	s3,8(sp)
    80001f1c:	e052                	sd	s4,0(sp)
    80001f1e:	1800                	addi	s0,sp,48
    80001f20:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001f22:	00010497          	auipc	s1,0x10
    80001f26:	e4648493          	addi	s1,s1,-442 # 80011d68 <proc>
      pp->parent = initproc;
    80001f2a:	00007a17          	auipc	s4,0x7
    80001f2e:	0eea0a13          	addi	s4,s4,238 # 80009018 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001f32:	0001a997          	auipc	s3,0x1a
    80001f36:	03698993          	addi	s3,s3,54 # 8001bf68 <tickslock>
    80001f3a:	a029                	j	80001f44 <reparent+0x34>
    80001f3c:	28848493          	addi	s1,s1,648
    80001f40:	03348363          	beq	s1,s3,80001f66 <reparent+0x56>
    if(pp->parent == p){
    80001f44:	709c                	ld	a5,32(s1)
    80001f46:	ff279be3          	bne	a5,s2,80001f3c <reparent+0x2c>
      acquire(&pp->lock);
    80001f4a:	8526                	mv	a0,s1
    80001f4c:	fffff097          	auipc	ra,0xfffff
    80001f50:	d16080e7          	jalr	-746(ra) # 80000c62 <acquire>
      pp->parent = initproc;
    80001f54:	000a3783          	ld	a5,0(s4)
    80001f58:	f09c                	sd	a5,32(s1)
      release(&pp->lock);
    80001f5a:	8526                	mv	a0,s1
    80001f5c:	fffff097          	auipc	ra,0xfffff
    80001f60:	dba080e7          	jalr	-582(ra) # 80000d16 <release>
    80001f64:	bfe1                	j	80001f3c <reparent+0x2c>
}
    80001f66:	70a2                	ld	ra,40(sp)
    80001f68:	7402                	ld	s0,32(sp)
    80001f6a:	64e2                	ld	s1,24(sp)
    80001f6c:	6942                	ld	s2,16(sp)
    80001f6e:	69a2                	ld	s3,8(sp)
    80001f70:	6a02                	ld	s4,0(sp)
    80001f72:	6145                	addi	sp,sp,48
    80001f74:	8082                	ret

0000000080001f76 <scheduler>:
{
    80001f76:	715d                	addi	sp,sp,-80
    80001f78:	e486                	sd	ra,72(sp)
    80001f7a:	e0a2                	sd	s0,64(sp)
    80001f7c:	fc26                	sd	s1,56(sp)
    80001f7e:	f84a                	sd	s2,48(sp)
    80001f80:	f44e                	sd	s3,40(sp)
    80001f82:	f052                	sd	s4,32(sp)
    80001f84:	ec56                	sd	s5,24(sp)
    80001f86:	e85a                	sd	s6,16(sp)
    80001f88:	e45e                	sd	s7,8(sp)
    80001f8a:	e062                	sd	s8,0(sp)
    80001f8c:	0880                	addi	s0,sp,80
    80001f8e:	8792                	mv	a5,tp
  int id = r_tp();
    80001f90:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f92:	00779b13          	slli	s6,a5,0x7
    80001f96:	00010717          	auipc	a4,0x10
    80001f9a:	9ba70713          	addi	a4,a4,-1606 # 80011950 <pid_lock>
    80001f9e:	975a                	add	a4,a4,s6
    80001fa0:	00073c23          	sd	zero,24(a4)
        swtch(&c->context, &p->context);
    80001fa4:	00010717          	auipc	a4,0x10
    80001fa8:	9cc70713          	addi	a4,a4,-1588 # 80011970 <cpus+0x8>
    80001fac:	9b3a                	add	s6,s6,a4
        p->state = RUNNING;
    80001fae:	4c0d                	li	s8,3
        c->proc = p;
    80001fb0:	079e                	slli	a5,a5,0x7
    80001fb2:	00010a17          	auipc	s4,0x10
    80001fb6:	99ea0a13          	addi	s4,s4,-1634 # 80011950 <pid_lock>
    80001fba:	9a3e                	add	s4,s4,a5
        found = 1;
    80001fbc:	4b85                	li	s7,1
    for(p = proc; p < &proc[NPROC]; p++) {
    80001fbe:	0001a997          	auipc	s3,0x1a
    80001fc2:	faa98993          	addi	s3,s3,-86 # 8001bf68 <tickslock>
    80001fc6:	a899                	j	8000201c <scheduler+0xa6>
      release(&p->lock);
    80001fc8:	8526                	mv	a0,s1
    80001fca:	fffff097          	auipc	ra,0xfffff
    80001fce:	d4c080e7          	jalr	-692(ra) # 80000d16 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001fd2:	28848493          	addi	s1,s1,648
    80001fd6:	03348963          	beq	s1,s3,80002008 <scheduler+0x92>
      acquire(&p->lock);
    80001fda:	8526                	mv	a0,s1
    80001fdc:	fffff097          	auipc	ra,0xfffff
    80001fe0:	c86080e7          	jalr	-890(ra) # 80000c62 <acquire>
      if(p->state == RUNNABLE) {
    80001fe4:	4c9c                	lw	a5,24(s1)
    80001fe6:	ff2791e3          	bne	a5,s2,80001fc8 <scheduler+0x52>
        p->state = RUNNING;
    80001fea:	0184ac23          	sw	s8,24(s1)
        c->proc = p;
    80001fee:	009a3c23          	sd	s1,24(s4)
        swtch(&c->context, &p->context);
    80001ff2:	06048593          	addi	a1,s1,96
    80001ff6:	855a                	mv	a0,s6
    80001ff8:	00000097          	auipc	ra,0x0
    80001ffc:	610080e7          	jalr	1552(ra) # 80002608 <swtch>
        c->proc = 0;
    80002000:	000a3c23          	sd	zero,24(s4)
        found = 1;
    80002004:	8ade                	mv	s5,s7
    80002006:	b7c9                	j	80001fc8 <scheduler+0x52>
    if(found == 0) {
    80002008:	000a9a63          	bnez	s5,8000201c <scheduler+0xa6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000200c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002010:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002014:	10079073          	csrw	sstatus,a5
      asm volatile("wfi");
    80002018:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000201c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002020:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002024:	10079073          	csrw	sstatus,a5
    int found = 0;
    80002028:	4a81                	li	s5,0
    for(p = proc; p < &proc[NPROC]; p++) {
    8000202a:	00010497          	auipc	s1,0x10
    8000202e:	d3e48493          	addi	s1,s1,-706 # 80011d68 <proc>
      if(p->state == RUNNABLE) {
    80002032:	4909                	li	s2,2
    80002034:	b75d                	j	80001fda <scheduler+0x64>

0000000080002036 <sched>:
{
    80002036:	7179                	addi	sp,sp,-48
    80002038:	f406                	sd	ra,40(sp)
    8000203a:	f022                	sd	s0,32(sp)
    8000203c:	ec26                	sd	s1,24(sp)
    8000203e:	e84a                	sd	s2,16(sp)
    80002040:	e44e                	sd	s3,8(sp)
    80002042:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002044:	00000097          	auipc	ra,0x0
    80002048:	9ea080e7          	jalr	-1558(ra) # 80001a2e <myproc>
    8000204c:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    8000204e:	fffff097          	auipc	ra,0xfffff
    80002052:	b9a080e7          	jalr	-1126(ra) # 80000be8 <holding>
    80002056:	c93d                	beqz	a0,800020cc <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002058:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    8000205a:	2781                	sext.w	a5,a5
    8000205c:	079e                	slli	a5,a5,0x7
    8000205e:	00010717          	auipc	a4,0x10
    80002062:	8f270713          	addi	a4,a4,-1806 # 80011950 <pid_lock>
    80002066:	97ba                	add	a5,a5,a4
    80002068:	0907a703          	lw	a4,144(a5)
    8000206c:	4785                	li	a5,1
    8000206e:	06f71763          	bne	a4,a5,800020dc <sched+0xa6>
  if(p->state == RUNNING)
    80002072:	4c98                	lw	a4,24(s1)
    80002074:	478d                	li	a5,3
    80002076:	06f70b63          	beq	a4,a5,800020ec <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000207a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000207e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002080:	efb5                	bnez	a5,800020fc <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002082:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002084:	00010917          	auipc	s2,0x10
    80002088:	8cc90913          	addi	s2,s2,-1844 # 80011950 <pid_lock>
    8000208c:	2781                	sext.w	a5,a5
    8000208e:	079e                	slli	a5,a5,0x7
    80002090:	97ca                	add	a5,a5,s2
    80002092:	0947a983          	lw	s3,148(a5)
    80002096:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002098:	2781                	sext.w	a5,a5
    8000209a:	079e                	slli	a5,a5,0x7
    8000209c:	00010597          	auipc	a1,0x10
    800020a0:	8d458593          	addi	a1,a1,-1836 # 80011970 <cpus+0x8>
    800020a4:	95be                	add	a1,a1,a5
    800020a6:	06048513          	addi	a0,s1,96
    800020aa:	00000097          	auipc	ra,0x0
    800020ae:	55e080e7          	jalr	1374(ra) # 80002608 <swtch>
    800020b2:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800020b4:	2781                	sext.w	a5,a5
    800020b6:	079e                	slli	a5,a5,0x7
    800020b8:	97ca                	add	a5,a5,s2
    800020ba:	0937aa23          	sw	s3,148(a5)
}
    800020be:	70a2                	ld	ra,40(sp)
    800020c0:	7402                	ld	s0,32(sp)
    800020c2:	64e2                	ld	s1,24(sp)
    800020c4:	6942                	ld	s2,16(sp)
    800020c6:	69a2                	ld	s3,8(sp)
    800020c8:	6145                	addi	sp,sp,48
    800020ca:	8082                	ret
    panic("sched p->lock");
    800020cc:	00006517          	auipc	a0,0x6
    800020d0:	14c50513          	addi	a0,a0,332 # 80008218 <digits+0x1c0>
    800020d4:	ffffe097          	auipc	ra,0xffffe
    800020d8:	4fc080e7          	jalr	1276(ra) # 800005d0 <panic>
    panic("sched locks");
    800020dc:	00006517          	auipc	a0,0x6
    800020e0:	14c50513          	addi	a0,a0,332 # 80008228 <digits+0x1d0>
    800020e4:	ffffe097          	auipc	ra,0xffffe
    800020e8:	4ec080e7          	jalr	1260(ra) # 800005d0 <panic>
    panic("sched running");
    800020ec:	00006517          	auipc	a0,0x6
    800020f0:	14c50513          	addi	a0,a0,332 # 80008238 <digits+0x1e0>
    800020f4:	ffffe097          	auipc	ra,0xffffe
    800020f8:	4dc080e7          	jalr	1244(ra) # 800005d0 <panic>
    panic("sched interruptible");
    800020fc:	00006517          	auipc	a0,0x6
    80002100:	14c50513          	addi	a0,a0,332 # 80008248 <digits+0x1f0>
    80002104:	ffffe097          	auipc	ra,0xffffe
    80002108:	4cc080e7          	jalr	1228(ra) # 800005d0 <panic>

000000008000210c <exit>:
{
    8000210c:	7179                	addi	sp,sp,-48
    8000210e:	f406                	sd	ra,40(sp)
    80002110:	f022                	sd	s0,32(sp)
    80002112:	ec26                	sd	s1,24(sp)
    80002114:	e84a                	sd	s2,16(sp)
    80002116:	e44e                	sd	s3,8(sp)
    80002118:	e052                	sd	s4,0(sp)
    8000211a:	1800                	addi	s0,sp,48
    8000211c:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000211e:	00000097          	auipc	ra,0x0
    80002122:	910080e7          	jalr	-1776(ra) # 80001a2e <myproc>
    80002126:	89aa                	mv	s3,a0
  if(p == initproc)
    80002128:	00007797          	auipc	a5,0x7
    8000212c:	ef07b783          	ld	a5,-272(a5) # 80009018 <initproc>
    80002130:	0d050493          	addi	s1,a0,208
    80002134:	15050913          	addi	s2,a0,336
    80002138:	02a79363          	bne	a5,a0,8000215e <exit+0x52>
    panic("init exiting");
    8000213c:	00006517          	auipc	a0,0x6
    80002140:	12450513          	addi	a0,a0,292 # 80008260 <digits+0x208>
    80002144:	ffffe097          	auipc	ra,0xffffe
    80002148:	48c080e7          	jalr	1164(ra) # 800005d0 <panic>
      fileclose(f);
    8000214c:	00002097          	auipc	ra,0x2
    80002150:	678080e7          	jalr	1656(ra) # 800047c4 <fileclose>
      p->ofile[fd] = 0;
    80002154:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002158:	04a1                	addi	s1,s1,8
    8000215a:	01248563          	beq	s1,s2,80002164 <exit+0x58>
    if(p->ofile[fd]){
    8000215e:	6088                	ld	a0,0(s1)
    80002160:	f575                	bnez	a0,8000214c <exit+0x40>
    80002162:	bfdd                	j	80002158 <exit+0x4c>
  begin_op();
    80002164:	00002097          	auipc	ra,0x2
    80002168:	18e080e7          	jalr	398(ra) # 800042f2 <begin_op>
  iput(p->cwd);
    8000216c:	1509b503          	ld	a0,336(s3)
    80002170:	00002097          	auipc	ra,0x2
    80002174:	97c080e7          	jalr	-1668(ra) # 80003aec <iput>
  end_op();
    80002178:	00002097          	auipc	ra,0x2
    8000217c:	1fa080e7          	jalr	506(ra) # 80004372 <end_op>
  p->cwd = 0;
    80002180:	1409b823          	sd	zero,336(s3)
  acquire(&initproc->lock);
    80002184:	00007497          	auipc	s1,0x7
    80002188:	e9448493          	addi	s1,s1,-364 # 80009018 <initproc>
    8000218c:	6088                	ld	a0,0(s1)
    8000218e:	fffff097          	auipc	ra,0xfffff
    80002192:	ad4080e7          	jalr	-1324(ra) # 80000c62 <acquire>
  wakeup1(initproc);
    80002196:	6088                	ld	a0,0(s1)
    80002198:	fffff097          	auipc	ra,0xfffff
    8000219c:	756080e7          	jalr	1878(ra) # 800018ee <wakeup1>
  release(&initproc->lock);
    800021a0:	6088                	ld	a0,0(s1)
    800021a2:	fffff097          	auipc	ra,0xfffff
    800021a6:	b74080e7          	jalr	-1164(ra) # 80000d16 <release>
  acquire(&p->lock);
    800021aa:	854e                	mv	a0,s3
    800021ac:	fffff097          	auipc	ra,0xfffff
    800021b0:	ab6080e7          	jalr	-1354(ra) # 80000c62 <acquire>
  struct proc *original_parent = p->parent;
    800021b4:	0209b483          	ld	s1,32(s3)
  release(&p->lock);
    800021b8:	854e                	mv	a0,s3
    800021ba:	fffff097          	auipc	ra,0xfffff
    800021be:	b5c080e7          	jalr	-1188(ra) # 80000d16 <release>
  acquire(&original_parent->lock);
    800021c2:	8526                	mv	a0,s1
    800021c4:	fffff097          	auipc	ra,0xfffff
    800021c8:	a9e080e7          	jalr	-1378(ra) # 80000c62 <acquire>
  acquire(&p->lock);
    800021cc:	854e                	mv	a0,s3
    800021ce:	fffff097          	auipc	ra,0xfffff
    800021d2:	a94080e7          	jalr	-1388(ra) # 80000c62 <acquire>
  reparent(p);
    800021d6:	854e                	mv	a0,s3
    800021d8:	00000097          	auipc	ra,0x0
    800021dc:	d38080e7          	jalr	-712(ra) # 80001f10 <reparent>
  wakeup1(original_parent);
    800021e0:	8526                	mv	a0,s1
    800021e2:	fffff097          	auipc	ra,0xfffff
    800021e6:	70c080e7          	jalr	1804(ra) # 800018ee <wakeup1>
  p->xstate = status;
    800021ea:	0349aa23          	sw	s4,52(s3)
  p->state = ZOMBIE;
    800021ee:	4791                	li	a5,4
    800021f0:	00f9ac23          	sw	a5,24(s3)
  release(&original_parent->lock);
    800021f4:	8526                	mv	a0,s1
    800021f6:	fffff097          	auipc	ra,0xfffff
    800021fa:	b20080e7          	jalr	-1248(ra) # 80000d16 <release>
  sched();
    800021fe:	00000097          	auipc	ra,0x0
    80002202:	e38080e7          	jalr	-456(ra) # 80002036 <sched>
  panic("zombie exit");
    80002206:	00006517          	auipc	a0,0x6
    8000220a:	06a50513          	addi	a0,a0,106 # 80008270 <digits+0x218>
    8000220e:	ffffe097          	auipc	ra,0xffffe
    80002212:	3c2080e7          	jalr	962(ra) # 800005d0 <panic>

0000000080002216 <yield>:
{
    80002216:	1101                	addi	sp,sp,-32
    80002218:	ec06                	sd	ra,24(sp)
    8000221a:	e822                	sd	s0,16(sp)
    8000221c:	e426                	sd	s1,8(sp)
    8000221e:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002220:	00000097          	auipc	ra,0x0
    80002224:	80e080e7          	jalr	-2034(ra) # 80001a2e <myproc>
    80002228:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000222a:	fffff097          	auipc	ra,0xfffff
    8000222e:	a38080e7          	jalr	-1480(ra) # 80000c62 <acquire>
  p->state = RUNNABLE;
    80002232:	4789                	li	a5,2
    80002234:	cc9c                	sw	a5,24(s1)
  sched();
    80002236:	00000097          	auipc	ra,0x0
    8000223a:	e00080e7          	jalr	-512(ra) # 80002036 <sched>
  release(&p->lock);
    8000223e:	8526                	mv	a0,s1
    80002240:	fffff097          	auipc	ra,0xfffff
    80002244:	ad6080e7          	jalr	-1322(ra) # 80000d16 <release>
}
    80002248:	60e2                	ld	ra,24(sp)
    8000224a:	6442                	ld	s0,16(sp)
    8000224c:	64a2                	ld	s1,8(sp)
    8000224e:	6105                	addi	sp,sp,32
    80002250:	8082                	ret

0000000080002252 <sleep>:
{
    80002252:	7179                	addi	sp,sp,-48
    80002254:	f406                	sd	ra,40(sp)
    80002256:	f022                	sd	s0,32(sp)
    80002258:	ec26                	sd	s1,24(sp)
    8000225a:	e84a                	sd	s2,16(sp)
    8000225c:	e44e                	sd	s3,8(sp)
    8000225e:	1800                	addi	s0,sp,48
    80002260:	89aa                	mv	s3,a0
    80002262:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002264:	fffff097          	auipc	ra,0xfffff
    80002268:	7ca080e7          	jalr	1994(ra) # 80001a2e <myproc>
    8000226c:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    8000226e:	05250663          	beq	a0,s2,800022ba <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    80002272:	fffff097          	auipc	ra,0xfffff
    80002276:	9f0080e7          	jalr	-1552(ra) # 80000c62 <acquire>
    release(lk);
    8000227a:	854a                	mv	a0,s2
    8000227c:	fffff097          	auipc	ra,0xfffff
    80002280:	a9a080e7          	jalr	-1382(ra) # 80000d16 <release>
  p->chan = chan;
    80002284:	0334b423          	sd	s3,40(s1)
  p->state = SLEEPING;
    80002288:	4785                	li	a5,1
    8000228a:	cc9c                	sw	a5,24(s1)
  sched();
    8000228c:	00000097          	auipc	ra,0x0
    80002290:	daa080e7          	jalr	-598(ra) # 80002036 <sched>
  p->chan = 0;
    80002294:	0204b423          	sd	zero,40(s1)
    release(&p->lock);
    80002298:	8526                	mv	a0,s1
    8000229a:	fffff097          	auipc	ra,0xfffff
    8000229e:	a7c080e7          	jalr	-1412(ra) # 80000d16 <release>
    acquire(lk);
    800022a2:	854a                	mv	a0,s2
    800022a4:	fffff097          	auipc	ra,0xfffff
    800022a8:	9be080e7          	jalr	-1602(ra) # 80000c62 <acquire>
}
    800022ac:	70a2                	ld	ra,40(sp)
    800022ae:	7402                	ld	s0,32(sp)
    800022b0:	64e2                	ld	s1,24(sp)
    800022b2:	6942                	ld	s2,16(sp)
    800022b4:	69a2                	ld	s3,8(sp)
    800022b6:	6145                	addi	sp,sp,48
    800022b8:	8082                	ret
  p->chan = chan;
    800022ba:	03353423          	sd	s3,40(a0)
  p->state = SLEEPING;
    800022be:	4785                	li	a5,1
    800022c0:	cd1c                	sw	a5,24(a0)
  sched();
    800022c2:	00000097          	auipc	ra,0x0
    800022c6:	d74080e7          	jalr	-652(ra) # 80002036 <sched>
  p->chan = 0;
    800022ca:	0204b423          	sd	zero,40(s1)
  if(lk != &p->lock){
    800022ce:	bff9                	j	800022ac <sleep+0x5a>

00000000800022d0 <wait>:
{
    800022d0:	715d                	addi	sp,sp,-80
    800022d2:	e486                	sd	ra,72(sp)
    800022d4:	e0a2                	sd	s0,64(sp)
    800022d6:	fc26                	sd	s1,56(sp)
    800022d8:	f84a                	sd	s2,48(sp)
    800022da:	f44e                	sd	s3,40(sp)
    800022dc:	f052                	sd	s4,32(sp)
    800022de:	ec56                	sd	s5,24(sp)
    800022e0:	e85a                	sd	s6,16(sp)
    800022e2:	e45e                	sd	s7,8(sp)
    800022e4:	0880                	addi	s0,sp,80
    800022e6:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800022e8:	fffff097          	auipc	ra,0xfffff
    800022ec:	746080e7          	jalr	1862(ra) # 80001a2e <myproc>
    800022f0:	892a                	mv	s2,a0
  acquire(&p->lock);
    800022f2:	fffff097          	auipc	ra,0xfffff
    800022f6:	970080e7          	jalr	-1680(ra) # 80000c62 <acquire>
    havekids = 0;
    800022fa:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800022fc:	4a11                	li	s4,4
        havekids = 1;
    800022fe:	4a85                	li	s5,1
    for(np = proc; np < &proc[NPROC]; np++){
    80002300:	0001a997          	auipc	s3,0x1a
    80002304:	c6898993          	addi	s3,s3,-920 # 8001bf68 <tickslock>
    havekids = 0;
    80002308:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    8000230a:	00010497          	auipc	s1,0x10
    8000230e:	a5e48493          	addi	s1,s1,-1442 # 80011d68 <proc>
    80002312:	a08d                	j	80002374 <wait+0xa4>
          pid = np->pid;
    80002314:	0384a983          	lw	s3,56(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002318:	000b0e63          	beqz	s6,80002334 <wait+0x64>
    8000231c:	4691                	li	a3,4
    8000231e:	03448613          	addi	a2,s1,52
    80002322:	85da                	mv	a1,s6
    80002324:	05093503          	ld	a0,80(s2)
    80002328:	fffff097          	auipc	ra,0xfffff
    8000232c:	3f8080e7          	jalr	1016(ra) # 80001720 <copyout>
    80002330:	02054263          	bltz	a0,80002354 <wait+0x84>
          freeproc(np);
    80002334:	8526                	mv	a0,s1
    80002336:	00000097          	auipc	ra,0x0
    8000233a:	8aa080e7          	jalr	-1878(ra) # 80001be0 <freeproc>
          release(&np->lock);
    8000233e:	8526                	mv	a0,s1
    80002340:	fffff097          	auipc	ra,0xfffff
    80002344:	9d6080e7          	jalr	-1578(ra) # 80000d16 <release>
          release(&p->lock);
    80002348:	854a                	mv	a0,s2
    8000234a:	fffff097          	auipc	ra,0xfffff
    8000234e:	9cc080e7          	jalr	-1588(ra) # 80000d16 <release>
          return pid;
    80002352:	a8a9                	j	800023ac <wait+0xdc>
            release(&np->lock);
    80002354:	8526                	mv	a0,s1
    80002356:	fffff097          	auipc	ra,0xfffff
    8000235a:	9c0080e7          	jalr	-1600(ra) # 80000d16 <release>
            release(&p->lock);
    8000235e:	854a                	mv	a0,s2
    80002360:	fffff097          	auipc	ra,0xfffff
    80002364:	9b6080e7          	jalr	-1610(ra) # 80000d16 <release>
            return -1;
    80002368:	59fd                	li	s3,-1
    8000236a:	a089                	j	800023ac <wait+0xdc>
    for(np = proc; np < &proc[NPROC]; np++){
    8000236c:	28848493          	addi	s1,s1,648
    80002370:	03348463          	beq	s1,s3,80002398 <wait+0xc8>
      if(np->parent == p){
    80002374:	709c                	ld	a5,32(s1)
    80002376:	ff279be3          	bne	a5,s2,8000236c <wait+0x9c>
        acquire(&np->lock);
    8000237a:	8526                	mv	a0,s1
    8000237c:	fffff097          	auipc	ra,0xfffff
    80002380:	8e6080e7          	jalr	-1818(ra) # 80000c62 <acquire>
        if(np->state == ZOMBIE){
    80002384:	4c9c                	lw	a5,24(s1)
    80002386:	f94787e3          	beq	a5,s4,80002314 <wait+0x44>
        release(&np->lock);
    8000238a:	8526                	mv	a0,s1
    8000238c:	fffff097          	auipc	ra,0xfffff
    80002390:	98a080e7          	jalr	-1654(ra) # 80000d16 <release>
        havekids = 1;
    80002394:	8756                	mv	a4,s5
    80002396:	bfd9                	j	8000236c <wait+0x9c>
    if(!havekids || p->killed){
    80002398:	c701                	beqz	a4,800023a0 <wait+0xd0>
    8000239a:	03092783          	lw	a5,48(s2)
    8000239e:	c39d                	beqz	a5,800023c4 <wait+0xf4>
      release(&p->lock);
    800023a0:	854a                	mv	a0,s2
    800023a2:	fffff097          	auipc	ra,0xfffff
    800023a6:	974080e7          	jalr	-1676(ra) # 80000d16 <release>
      return -1;
    800023aa:	59fd                	li	s3,-1
}
    800023ac:	854e                	mv	a0,s3
    800023ae:	60a6                	ld	ra,72(sp)
    800023b0:	6406                	ld	s0,64(sp)
    800023b2:	74e2                	ld	s1,56(sp)
    800023b4:	7942                	ld	s2,48(sp)
    800023b6:	79a2                	ld	s3,40(sp)
    800023b8:	7a02                	ld	s4,32(sp)
    800023ba:	6ae2                	ld	s5,24(sp)
    800023bc:	6b42                	ld	s6,16(sp)
    800023be:	6ba2                	ld	s7,8(sp)
    800023c0:	6161                	addi	sp,sp,80
    800023c2:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    800023c4:	85ca                	mv	a1,s2
    800023c6:	854a                	mv	a0,s2
    800023c8:	00000097          	auipc	ra,0x0
    800023cc:	e8a080e7          	jalr	-374(ra) # 80002252 <sleep>
    havekids = 0;
    800023d0:	bf25                	j	80002308 <wait+0x38>

00000000800023d2 <wakeup>:
{
    800023d2:	7139                	addi	sp,sp,-64
    800023d4:	fc06                	sd	ra,56(sp)
    800023d6:	f822                	sd	s0,48(sp)
    800023d8:	f426                	sd	s1,40(sp)
    800023da:	f04a                	sd	s2,32(sp)
    800023dc:	ec4e                	sd	s3,24(sp)
    800023de:	e852                	sd	s4,16(sp)
    800023e0:	e456                	sd	s5,8(sp)
    800023e2:	0080                	addi	s0,sp,64
    800023e4:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    800023e6:	00010497          	auipc	s1,0x10
    800023ea:	98248493          	addi	s1,s1,-1662 # 80011d68 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    800023ee:	4985                	li	s3,1
      p->state = RUNNABLE;
    800023f0:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    800023f2:	0001a917          	auipc	s2,0x1a
    800023f6:	b7690913          	addi	s2,s2,-1162 # 8001bf68 <tickslock>
    800023fa:	a811                	j	8000240e <wakeup+0x3c>
    release(&p->lock);
    800023fc:	8526                	mv	a0,s1
    800023fe:	fffff097          	auipc	ra,0xfffff
    80002402:	918080e7          	jalr	-1768(ra) # 80000d16 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002406:	28848493          	addi	s1,s1,648
    8000240a:	03248063          	beq	s1,s2,8000242a <wakeup+0x58>
    acquire(&p->lock);
    8000240e:	8526                	mv	a0,s1
    80002410:	fffff097          	auipc	ra,0xfffff
    80002414:	852080e7          	jalr	-1966(ra) # 80000c62 <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    80002418:	4c9c                	lw	a5,24(s1)
    8000241a:	ff3791e3          	bne	a5,s3,800023fc <wakeup+0x2a>
    8000241e:	749c                	ld	a5,40(s1)
    80002420:	fd479ee3          	bne	a5,s4,800023fc <wakeup+0x2a>
      p->state = RUNNABLE;
    80002424:	0154ac23          	sw	s5,24(s1)
    80002428:	bfd1                	j	800023fc <wakeup+0x2a>
}
    8000242a:	70e2                	ld	ra,56(sp)
    8000242c:	7442                	ld	s0,48(sp)
    8000242e:	74a2                	ld	s1,40(sp)
    80002430:	7902                	ld	s2,32(sp)
    80002432:	69e2                	ld	s3,24(sp)
    80002434:	6a42                	ld	s4,16(sp)
    80002436:	6aa2                	ld	s5,8(sp)
    80002438:	6121                	addi	sp,sp,64
    8000243a:	8082                	ret

000000008000243c <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000243c:	7179                	addi	sp,sp,-48
    8000243e:	f406                	sd	ra,40(sp)
    80002440:	f022                	sd	s0,32(sp)
    80002442:	ec26                	sd	s1,24(sp)
    80002444:	e84a                	sd	s2,16(sp)
    80002446:	e44e                	sd	s3,8(sp)
    80002448:	1800                	addi	s0,sp,48
    8000244a:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000244c:	00010497          	auipc	s1,0x10
    80002450:	91c48493          	addi	s1,s1,-1764 # 80011d68 <proc>
    80002454:	0001a997          	auipc	s3,0x1a
    80002458:	b1498993          	addi	s3,s3,-1260 # 8001bf68 <tickslock>
    acquire(&p->lock);
    8000245c:	8526                	mv	a0,s1
    8000245e:	fffff097          	auipc	ra,0xfffff
    80002462:	804080e7          	jalr	-2044(ra) # 80000c62 <acquire>
    if(p->pid == pid){
    80002466:	5c9c                	lw	a5,56(s1)
    80002468:	01278d63          	beq	a5,s2,80002482 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000246c:	8526                	mv	a0,s1
    8000246e:	fffff097          	auipc	ra,0xfffff
    80002472:	8a8080e7          	jalr	-1880(ra) # 80000d16 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002476:	28848493          	addi	s1,s1,648
    8000247a:	ff3491e3          	bne	s1,s3,8000245c <kill+0x20>
  }
  return -1;
    8000247e:	557d                	li	a0,-1
    80002480:	a821                	j	80002498 <kill+0x5c>
      p->killed = 1;
    80002482:	4785                	li	a5,1
    80002484:	d89c                	sw	a5,48(s1)
      if(p->state == SLEEPING){
    80002486:	4c98                	lw	a4,24(s1)
    80002488:	00f70f63          	beq	a4,a5,800024a6 <kill+0x6a>
      release(&p->lock);
    8000248c:	8526                	mv	a0,s1
    8000248e:	fffff097          	auipc	ra,0xfffff
    80002492:	888080e7          	jalr	-1912(ra) # 80000d16 <release>
      return 0;
    80002496:	4501                	li	a0,0
}
    80002498:	70a2                	ld	ra,40(sp)
    8000249a:	7402                	ld	s0,32(sp)
    8000249c:	64e2                	ld	s1,24(sp)
    8000249e:	6942                	ld	s2,16(sp)
    800024a0:	69a2                	ld	s3,8(sp)
    800024a2:	6145                	addi	sp,sp,48
    800024a4:	8082                	ret
        p->state = RUNNABLE;
    800024a6:	4789                	li	a5,2
    800024a8:	cc9c                	sw	a5,24(s1)
    800024aa:	b7cd                	j	8000248c <kill+0x50>

00000000800024ac <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800024ac:	7179                	addi	sp,sp,-48
    800024ae:	f406                	sd	ra,40(sp)
    800024b0:	f022                	sd	s0,32(sp)
    800024b2:	ec26                	sd	s1,24(sp)
    800024b4:	e84a                	sd	s2,16(sp)
    800024b6:	e44e                	sd	s3,8(sp)
    800024b8:	e052                	sd	s4,0(sp)
    800024ba:	1800                	addi	s0,sp,48
    800024bc:	84aa                	mv	s1,a0
    800024be:	892e                	mv	s2,a1
    800024c0:	89b2                	mv	s3,a2
    800024c2:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024c4:	fffff097          	auipc	ra,0xfffff
    800024c8:	56a080e7          	jalr	1386(ra) # 80001a2e <myproc>
  if(user_dst){
    800024cc:	c08d                	beqz	s1,800024ee <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800024ce:	86d2                	mv	a3,s4
    800024d0:	864e                	mv	a2,s3
    800024d2:	85ca                	mv	a1,s2
    800024d4:	6928                	ld	a0,80(a0)
    800024d6:	fffff097          	auipc	ra,0xfffff
    800024da:	24a080e7          	jalr	586(ra) # 80001720 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800024de:	70a2                	ld	ra,40(sp)
    800024e0:	7402                	ld	s0,32(sp)
    800024e2:	64e2                	ld	s1,24(sp)
    800024e4:	6942                	ld	s2,16(sp)
    800024e6:	69a2                	ld	s3,8(sp)
    800024e8:	6a02                	ld	s4,0(sp)
    800024ea:	6145                	addi	sp,sp,48
    800024ec:	8082                	ret
    memmove((char *)dst, src, len);
    800024ee:	000a061b          	sext.w	a2,s4
    800024f2:	85ce                	mv	a1,s3
    800024f4:	854a                	mv	a0,s2
    800024f6:	fffff097          	auipc	ra,0xfffff
    800024fa:	8c4080e7          	jalr	-1852(ra) # 80000dba <memmove>
    return 0;
    800024fe:	8526                	mv	a0,s1
    80002500:	bff9                	j	800024de <either_copyout+0x32>

0000000080002502 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002502:	7179                	addi	sp,sp,-48
    80002504:	f406                	sd	ra,40(sp)
    80002506:	f022                	sd	s0,32(sp)
    80002508:	ec26                	sd	s1,24(sp)
    8000250a:	e84a                	sd	s2,16(sp)
    8000250c:	e44e                	sd	s3,8(sp)
    8000250e:	e052                	sd	s4,0(sp)
    80002510:	1800                	addi	s0,sp,48
    80002512:	892a                	mv	s2,a0
    80002514:	84ae                	mv	s1,a1
    80002516:	89b2                	mv	s3,a2
    80002518:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000251a:	fffff097          	auipc	ra,0xfffff
    8000251e:	514080e7          	jalr	1300(ra) # 80001a2e <myproc>
  if(user_src){
    80002522:	c08d                	beqz	s1,80002544 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002524:	86d2                	mv	a3,s4
    80002526:	864e                	mv	a2,s3
    80002528:	85ca                	mv	a1,s2
    8000252a:	6928                	ld	a0,80(a0)
    8000252c:	fffff097          	auipc	ra,0xfffff
    80002530:	280080e7          	jalr	640(ra) # 800017ac <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002534:	70a2                	ld	ra,40(sp)
    80002536:	7402                	ld	s0,32(sp)
    80002538:	64e2                	ld	s1,24(sp)
    8000253a:	6942                	ld	s2,16(sp)
    8000253c:	69a2                	ld	s3,8(sp)
    8000253e:	6a02                	ld	s4,0(sp)
    80002540:	6145                	addi	sp,sp,48
    80002542:	8082                	ret
    memmove(dst, (char*)src, len);
    80002544:	000a061b          	sext.w	a2,s4
    80002548:	85ce                	mv	a1,s3
    8000254a:	854a                	mv	a0,s2
    8000254c:	fffff097          	auipc	ra,0xfffff
    80002550:	86e080e7          	jalr	-1938(ra) # 80000dba <memmove>
    return 0;
    80002554:	8526                	mv	a0,s1
    80002556:	bff9                	j	80002534 <either_copyin+0x32>

0000000080002558 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002558:	715d                	addi	sp,sp,-80
    8000255a:	e486                	sd	ra,72(sp)
    8000255c:	e0a2                	sd	s0,64(sp)
    8000255e:	fc26                	sd	s1,56(sp)
    80002560:	f84a                	sd	s2,48(sp)
    80002562:	f44e                	sd	s3,40(sp)
    80002564:	f052                	sd	s4,32(sp)
    80002566:	ec56                	sd	s5,24(sp)
    80002568:	e85a                	sd	s6,16(sp)
    8000256a:	e45e                	sd	s7,8(sp)
    8000256c:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    8000256e:	00006517          	auipc	a0,0x6
    80002572:	b7250513          	addi	a0,a0,-1166 # 800080e0 <digits+0x88>
    80002576:	ffffe097          	auipc	ra,0xffffe
    8000257a:	0ac080e7          	jalr	172(ra) # 80000622 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000257e:	00010497          	auipc	s1,0x10
    80002582:	94248493          	addi	s1,s1,-1726 # 80011ec0 <proc+0x158>
    80002586:	0001a917          	auipc	s2,0x1a
    8000258a:	b3a90913          	addi	s2,s2,-1222 # 8001c0c0 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000258e:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    80002590:	00006997          	auipc	s3,0x6
    80002594:	cf098993          	addi	s3,s3,-784 # 80008280 <digits+0x228>
    printf("%d %s %s", p->pid, state, p->name);
    80002598:	00006a97          	auipc	s5,0x6
    8000259c:	cf0a8a93          	addi	s5,s5,-784 # 80008288 <digits+0x230>
    printf("\n");
    800025a0:	00006a17          	auipc	s4,0x6
    800025a4:	b40a0a13          	addi	s4,s4,-1216 # 800080e0 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025a8:	00006b97          	auipc	s7,0x6
    800025ac:	d18b8b93          	addi	s7,s7,-744 # 800082c0 <states.0>
    800025b0:	a00d                	j	800025d2 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800025b2:	ee06a583          	lw	a1,-288(a3)
    800025b6:	8556                	mv	a0,s5
    800025b8:	ffffe097          	auipc	ra,0xffffe
    800025bc:	06a080e7          	jalr	106(ra) # 80000622 <printf>
    printf("\n");
    800025c0:	8552                	mv	a0,s4
    800025c2:	ffffe097          	auipc	ra,0xffffe
    800025c6:	060080e7          	jalr	96(ra) # 80000622 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025ca:	28848493          	addi	s1,s1,648
    800025ce:	03248263          	beq	s1,s2,800025f2 <procdump+0x9a>
    if(p->state == UNUSED)
    800025d2:	86a6                	mv	a3,s1
    800025d4:	ec04a783          	lw	a5,-320(s1)
    800025d8:	dbed                	beqz	a5,800025ca <procdump+0x72>
      state = "???";
    800025da:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025dc:	fcfb6be3          	bltu	s6,a5,800025b2 <procdump+0x5a>
    800025e0:	02079713          	slli	a4,a5,0x20
    800025e4:	01d75793          	srli	a5,a4,0x1d
    800025e8:	97de                	add	a5,a5,s7
    800025ea:	6390                	ld	a2,0(a5)
    800025ec:	f279                	bnez	a2,800025b2 <procdump+0x5a>
      state = "???";
    800025ee:	864e                	mv	a2,s3
    800025f0:	b7c9                	j	800025b2 <procdump+0x5a>
  }
}
    800025f2:	60a6                	ld	ra,72(sp)
    800025f4:	6406                	ld	s0,64(sp)
    800025f6:	74e2                	ld	s1,56(sp)
    800025f8:	7942                	ld	s2,48(sp)
    800025fa:	79a2                	ld	s3,40(sp)
    800025fc:	7a02                	ld	s4,32(sp)
    800025fe:	6ae2                	ld	s5,24(sp)
    80002600:	6b42                	ld	s6,16(sp)
    80002602:	6ba2                	ld	s7,8(sp)
    80002604:	6161                	addi	sp,sp,80
    80002606:	8082                	ret

0000000080002608 <swtch>:
    80002608:	00153023          	sd	ra,0(a0)
    8000260c:	00253423          	sd	sp,8(a0)
    80002610:	e900                	sd	s0,16(a0)
    80002612:	ed04                	sd	s1,24(a0)
    80002614:	03253023          	sd	s2,32(a0)
    80002618:	03353423          	sd	s3,40(a0)
    8000261c:	03453823          	sd	s4,48(a0)
    80002620:	03553c23          	sd	s5,56(a0)
    80002624:	05653023          	sd	s6,64(a0)
    80002628:	05753423          	sd	s7,72(a0)
    8000262c:	05853823          	sd	s8,80(a0)
    80002630:	05953c23          	sd	s9,88(a0)
    80002634:	07a53023          	sd	s10,96(a0)
    80002638:	07b53423          	sd	s11,104(a0)
    8000263c:	0005b083          	ld	ra,0(a1)
    80002640:	0085b103          	ld	sp,8(a1)
    80002644:	6980                	ld	s0,16(a1)
    80002646:	6d84                	ld	s1,24(a1)
    80002648:	0205b903          	ld	s2,32(a1)
    8000264c:	0285b983          	ld	s3,40(a1)
    80002650:	0305ba03          	ld	s4,48(a1)
    80002654:	0385ba83          	ld	s5,56(a1)
    80002658:	0405bb03          	ld	s6,64(a1)
    8000265c:	0485bb83          	ld	s7,72(a1)
    80002660:	0505bc03          	ld	s8,80(a1)
    80002664:	0585bc83          	ld	s9,88(a1)
    80002668:	0605bd03          	ld	s10,96(a1)
    8000266c:	0685bd83          	ld	s11,104(a1)
    80002670:	8082                	ret

0000000080002672 <trapinit>:
void kernelvec();

extern int devintr();

void trapinit(void)
{
    80002672:	1141                	addi	sp,sp,-16
    80002674:	e406                	sd	ra,8(sp)
    80002676:	e022                	sd	s0,0(sp)
    80002678:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000267a:	00006597          	auipc	a1,0x6
    8000267e:	c6e58593          	addi	a1,a1,-914 # 800082e8 <states.0+0x28>
    80002682:	0001a517          	auipc	a0,0x1a
    80002686:	8e650513          	addi	a0,a0,-1818 # 8001bf68 <tickslock>
    8000268a:	ffffe097          	auipc	ra,0xffffe
    8000268e:	548080e7          	jalr	1352(ra) # 80000bd2 <initlock>
}
    80002692:	60a2                	ld	ra,8(sp)
    80002694:	6402                	ld	s0,0(sp)
    80002696:	0141                	addi	sp,sp,16
    80002698:	8082                	ret

000000008000269a <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void trapinithart(void)
{
    8000269a:	1141                	addi	sp,sp,-16
    8000269c:	e422                	sd	s0,8(sp)
    8000269e:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800026a0:	00003797          	auipc	a5,0x3
    800026a4:	78078793          	addi	a5,a5,1920 # 80005e20 <kernelvec>
    800026a8:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800026ac:	6422                	ld	s0,8(sp)
    800026ae:	0141                	addi	sp,sp,16
    800026b0:	8082                	ret

00000000800026b2 <usertrapret>:

//
// return to user space
//
void usertrapret(void)
{
    800026b2:	1141                	addi	sp,sp,-16
    800026b4:	e406                	sd	ra,8(sp)
    800026b6:	e022                	sd	s0,0(sp)
    800026b8:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800026ba:	fffff097          	auipc	ra,0xfffff
    800026be:	374080e7          	jalr	884(ra) # 80001a2e <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026c2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800026c6:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800026c8:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    800026cc:	00005617          	auipc	a2,0x5
    800026d0:	93460613          	addi	a2,a2,-1740 # 80007000 <_trampoline>
    800026d4:	00005697          	auipc	a3,0x5
    800026d8:	92c68693          	addi	a3,a3,-1748 # 80007000 <_trampoline>
    800026dc:	8e91                	sub	a3,a3,a2
    800026de:	040007b7          	lui	a5,0x4000
    800026e2:	17fd                	addi	a5,a5,-1
    800026e4:	07b2                	slli	a5,a5,0xc
    800026e6:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800026e8:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800026ec:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800026ee:	180026f3          	csrr	a3,satp
    800026f2:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800026f4:	6d38                	ld	a4,88(a0)
    800026f6:	6134                	ld	a3,64(a0)
    800026f8:	6585                	lui	a1,0x1
    800026fa:	96ae                	add	a3,a3,a1
    800026fc:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800026fe:	6d38                	ld	a4,88(a0)
    80002700:	00000697          	auipc	a3,0x0
    80002704:	13868693          	addi	a3,a3,312 # 80002838 <usertrap>
    80002708:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp(); // hartid for cpuid()
    8000270a:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    8000270c:	8692                	mv	a3,tp
    8000270e:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002710:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.

  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002714:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002718:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000271c:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002720:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002722:	6f18                	ld	a4,24(a4)
    80002724:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002728:	692c                	ld	a1,80(a0)
    8000272a:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    8000272c:	00005717          	auipc	a4,0x5
    80002730:	96470713          	addi	a4,a4,-1692 # 80007090 <userret>
    80002734:	8f11                	sub	a4,a4,a2
    80002736:	97ba                	add	a5,a5,a4
  ((void (*)(uint64, uint64))fn)(TRAPFRAME, satp);
    80002738:	577d                	li	a4,-1
    8000273a:	177e                	slli	a4,a4,0x3f
    8000273c:	8dd9                	or	a1,a1,a4
    8000273e:	02000537          	lui	a0,0x2000
    80002742:	157d                	addi	a0,a0,-1
    80002744:	0536                	slli	a0,a0,0xd
    80002746:	9782                	jalr	a5
}
    80002748:	60a2                	ld	ra,8(sp)
    8000274a:	6402                	ld	s0,0(sp)
    8000274c:	0141                	addi	sp,sp,16
    8000274e:	8082                	ret

0000000080002750 <clockintr>:
  w_sepc(sepc);
  w_sstatus(sstatus);
}

void clockintr()
{
    80002750:	1101                	addi	sp,sp,-32
    80002752:	ec06                	sd	ra,24(sp)
    80002754:	e822                	sd	s0,16(sp)
    80002756:	e426                	sd	s1,8(sp)
    80002758:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    8000275a:	0001a497          	auipc	s1,0x1a
    8000275e:	80e48493          	addi	s1,s1,-2034 # 8001bf68 <tickslock>
    80002762:	8526                	mv	a0,s1
    80002764:	ffffe097          	auipc	ra,0xffffe
    80002768:	4fe080e7          	jalr	1278(ra) # 80000c62 <acquire>
  ticks++;
    8000276c:	00007517          	auipc	a0,0x7
    80002770:	8b450513          	addi	a0,a0,-1868 # 80009020 <ticks>
    80002774:	411c                	lw	a5,0(a0)
    80002776:	2785                	addiw	a5,a5,1
    80002778:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    8000277a:	00000097          	auipc	ra,0x0
    8000277e:	c58080e7          	jalr	-936(ra) # 800023d2 <wakeup>
  release(&tickslock);
    80002782:	8526                	mv	a0,s1
    80002784:	ffffe097          	auipc	ra,0xffffe
    80002788:	592080e7          	jalr	1426(ra) # 80000d16 <release>
}
    8000278c:	60e2                	ld	ra,24(sp)
    8000278e:	6442                	ld	s0,16(sp)
    80002790:	64a2                	ld	s1,8(sp)
    80002792:	6105                	addi	sp,sp,32
    80002794:	8082                	ret

0000000080002796 <devintr>:
// and handle it.
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int devintr()
{
    80002796:	1101                	addi	sp,sp,-32
    80002798:	ec06                	sd	ra,24(sp)
    8000279a:	e822                	sd	s0,16(sp)
    8000279c:	e426                	sd	s1,8(sp)
    8000279e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800027a0:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if ((scause & 0x8000000000000000L) &&
    800027a4:	00074d63          	bltz	a4,800027be <devintr+0x28>
    if (irq)
      plic_complete(irq);

    return 1;
  }
  else if (scause == 0x8000000000000001L)
    800027a8:	57fd                	li	a5,-1
    800027aa:	17fe                	slli	a5,a5,0x3f
    800027ac:	0785                	addi	a5,a5,1

    return 2;
  }
  else
  {
    return 0;
    800027ae:	4501                	li	a0,0
  else if (scause == 0x8000000000000001L)
    800027b0:	06f70363          	beq	a4,a5,80002816 <devintr+0x80>
  }
}
    800027b4:	60e2                	ld	ra,24(sp)
    800027b6:	6442                	ld	s0,16(sp)
    800027b8:	64a2                	ld	s1,8(sp)
    800027ba:	6105                	addi	sp,sp,32
    800027bc:	8082                	ret
      (scause & 0xff) == 9)
    800027be:	0ff77793          	andi	a5,a4,255
  if ((scause & 0x8000000000000000L) &&
    800027c2:	46a5                	li	a3,9
    800027c4:	fed792e3          	bne	a5,a3,800027a8 <devintr+0x12>
    int irq = plic_claim();
    800027c8:	00003097          	auipc	ra,0x3
    800027cc:	760080e7          	jalr	1888(ra) # 80005f28 <plic_claim>
    800027d0:	84aa                	mv	s1,a0
    if (irq == UART0_IRQ)
    800027d2:	47a9                	li	a5,10
    800027d4:	02f50763          	beq	a0,a5,80002802 <devintr+0x6c>
    else if (irq == VIRTIO0_IRQ)
    800027d8:	4785                	li	a5,1
    800027da:	02f50963          	beq	a0,a5,8000280c <devintr+0x76>
    return 1;
    800027de:	4505                	li	a0,1
    else if (irq)
    800027e0:	d8f1                	beqz	s1,800027b4 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800027e2:	85a6                	mv	a1,s1
    800027e4:	00006517          	auipc	a0,0x6
    800027e8:	b0c50513          	addi	a0,a0,-1268 # 800082f0 <states.0+0x30>
    800027ec:	ffffe097          	auipc	ra,0xffffe
    800027f0:	e36080e7          	jalr	-458(ra) # 80000622 <printf>
      plic_complete(irq);
    800027f4:	8526                	mv	a0,s1
    800027f6:	00003097          	auipc	ra,0x3
    800027fa:	756080e7          	jalr	1878(ra) # 80005f4c <plic_complete>
    return 1;
    800027fe:	4505                	li	a0,1
    80002800:	bf55                	j	800027b4 <devintr+0x1e>
      uartintr();
    80002802:	ffffe097          	auipc	ra,0xffffe
    80002806:	224080e7          	jalr	548(ra) # 80000a26 <uartintr>
    8000280a:	b7ed                	j	800027f4 <devintr+0x5e>
      virtio_disk_intr();
    8000280c:	00004097          	auipc	ra,0x4
    80002810:	bba080e7          	jalr	-1094(ra) # 800063c6 <virtio_disk_intr>
    80002814:	b7c5                	j	800027f4 <devintr+0x5e>
    if (cpuid() == 0)
    80002816:	fffff097          	auipc	ra,0xfffff
    8000281a:	1ec080e7          	jalr	492(ra) # 80001a02 <cpuid>
    8000281e:	c901                	beqz	a0,8000282e <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002820:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002824:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002826:	14479073          	csrw	sip,a5
    return 2;
    8000282a:	4509                	li	a0,2
    8000282c:	b761                	j	800027b4 <devintr+0x1e>
      clockintr();
    8000282e:	00000097          	auipc	ra,0x0
    80002832:	f22080e7          	jalr	-222(ra) # 80002750 <clockintr>
    80002836:	b7ed                	j	80002820 <devintr+0x8a>

0000000080002838 <usertrap>:
{
    80002838:	1101                	addi	sp,sp,-32
    8000283a:	ec06                	sd	ra,24(sp)
    8000283c:	e822                	sd	s0,16(sp)
    8000283e:	e426                	sd	s1,8(sp)
    80002840:	e04a                	sd	s2,0(sp)
    80002842:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002844:	100027f3          	csrr	a5,sstatus
  if ((r_sstatus() & SSTATUS_SPP) != 0)
    80002848:	1007f793          	andi	a5,a5,256
    8000284c:	e3ad                	bnez	a5,800028ae <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000284e:	00003797          	auipc	a5,0x3
    80002852:	5d278793          	addi	a5,a5,1490 # 80005e20 <kernelvec>
    80002856:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    8000285a:	fffff097          	auipc	ra,0xfffff
    8000285e:	1d4080e7          	jalr	468(ra) # 80001a2e <myproc>
    80002862:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002864:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002866:	14102773          	csrr	a4,sepc
    8000286a:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000286c:	14202773          	csrr	a4,scause
  if (r_scause() == 8)
    80002870:	47a1                	li	a5,8
    80002872:	04f71c63          	bne	a4,a5,800028ca <usertrap+0x92>
    if (p->killed)
    80002876:	591c                	lw	a5,48(a0)
    80002878:	e3b9                	bnez	a5,800028be <usertrap+0x86>
    p->trapframe->epc += 4;
    8000287a:	6cb8                	ld	a4,88(s1)
    8000287c:	6f1c                	ld	a5,24(a4)
    8000287e:	0791                	addi	a5,a5,4
    80002880:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002882:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002886:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000288a:	10079073          	csrw	sstatus,a5
    syscall();
    8000288e:	00000097          	auipc	ra,0x0
    80002892:	3e8080e7          	jalr	1000(ra) # 80002c76 <syscall>
  if (p->killed)
    80002896:	589c                	lw	a5,48(s1)
    80002898:	efd1                	bnez	a5,80002934 <usertrap+0xfc>
  usertrapret();
    8000289a:	00000097          	auipc	ra,0x0
    8000289e:	e18080e7          	jalr	-488(ra) # 800026b2 <usertrapret>
}
    800028a2:	60e2                	ld	ra,24(sp)
    800028a4:	6442                	ld	s0,16(sp)
    800028a6:	64a2                	ld	s1,8(sp)
    800028a8:	6902                	ld	s2,0(sp)
    800028aa:	6105                	addi	sp,sp,32
    800028ac:	8082                	ret
    panic("usertrap: not from user mode");
    800028ae:	00006517          	auipc	a0,0x6
    800028b2:	a6250513          	addi	a0,a0,-1438 # 80008310 <states.0+0x50>
    800028b6:	ffffe097          	auipc	ra,0xffffe
    800028ba:	d1a080e7          	jalr	-742(ra) # 800005d0 <panic>
      exit(-1);
    800028be:	557d                	li	a0,-1
    800028c0:	00000097          	auipc	ra,0x0
    800028c4:	84c080e7          	jalr	-1972(ra) # 8000210c <exit>
    800028c8:	bf4d                	j	8000287a <usertrap+0x42>
  else if ((which_dev = devintr()) != 0)
    800028ca:	00000097          	auipc	ra,0x0
    800028ce:	ecc080e7          	jalr	-308(ra) # 80002796 <devintr>
    800028d2:	892a                	mv	s2,a0
    800028d4:	c501                	beqz	a0,800028dc <usertrap+0xa4>
  if (p->killed)
    800028d6:	589c                	lw	a5,48(s1)
    800028d8:	c3a1                	beqz	a5,80002918 <usertrap+0xe0>
    800028da:	a815                	j	8000290e <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028dc:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    800028e0:	5c90                	lw	a2,56(s1)
    800028e2:	00006517          	auipc	a0,0x6
    800028e6:	a4e50513          	addi	a0,a0,-1458 # 80008330 <states.0+0x70>
    800028ea:	ffffe097          	auipc	ra,0xffffe
    800028ee:	d38080e7          	jalr	-712(ra) # 80000622 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028f2:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800028f6:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    800028fa:	00006517          	auipc	a0,0x6
    800028fe:	a6650513          	addi	a0,a0,-1434 # 80008360 <states.0+0xa0>
    80002902:	ffffe097          	auipc	ra,0xffffe
    80002906:	d20080e7          	jalr	-736(ra) # 80000622 <printf>
    p->killed = 1;
    8000290a:	4785                	li	a5,1
    8000290c:	d89c                	sw	a5,48(s1)
    exit(-1);
    8000290e:	557d                	li	a0,-1
    80002910:	fffff097          	auipc	ra,0xfffff
    80002914:	7fc080e7          	jalr	2044(ra) # 8000210c <exit>
  if (which_dev == 2)
    80002918:	4789                	li	a5,2
    8000291a:	f8f910e3          	bne	s2,a5,8000289a <usertrap+0x62>
    if (p->is_alarm == 1)
    8000291e:	1784a783          	lw	a5,376(s1)
    80002922:	4705                	li	a4,1
    80002924:	00e78a63          	beq	a5,a4,80002938 <usertrap+0x100>
    if (p->is_alarm && p->count_of_trick >= p->alarm_interval && p->alarm_interval > 0 && !p->in_alarm_handler)
    80002928:	ef89                	bnez	a5,80002942 <usertrap+0x10a>
    yield();
    8000292a:	00000097          	auipc	ra,0x0
    8000292e:	8ec080e7          	jalr	-1812(ra) # 80002216 <yield>
    80002932:	b7a5                	j	8000289a <usertrap+0x62>
  int which_dev = 0;
    80002934:	4901                	li	s2,0
    80002936:	bfe1                	j	8000290e <usertrap+0xd6>
      p->count_of_trick++;
    80002938:	1744a783          	lw	a5,372(s1)
    8000293c:	2785                	addiw	a5,a5,1
    8000293e:	16f4aa23          	sw	a5,372(s1)
    if (p->is_alarm && p->count_of_trick >= p->alarm_interval && p->alarm_interval > 0 && !p->in_alarm_handler)
    80002942:	1704a783          	lw	a5,368(s1)
    80002946:	1744a703          	lw	a4,372(s1)
    8000294a:	fef740e3          	blt	a4,a5,8000292a <usertrap+0xf2>
    8000294e:	fcf05ee3          	blez	a5,8000292a <usertrap+0xf2>
    80002952:	2804a783          	lw	a5,640(s1)
    80002956:	fbf1                	bnez	a5,8000292a <usertrap+0xf2>
      p->user_reg.epc = p->trapframe->epc;
    80002958:	6cbc                	ld	a5,88(s1)
    8000295a:	6f98                	ld	a4,24(a5)
    8000295c:	18e4b023          	sd	a4,384(s1)
      p->user_reg.ra = p->trapframe->ra;
    80002960:	7798                	ld	a4,40(a5)
    80002962:	18e4b423          	sd	a4,392(s1)
      p->user_reg.sp = p->trapframe->sp;
    80002966:	7b98                	ld	a4,48(a5)
    80002968:	18e4b823          	sd	a4,400(s1)
      p->user_reg.gp = p->trapframe->gp;
    8000296c:	7f98                	ld	a4,56(a5)
    8000296e:	18e4bc23          	sd	a4,408(s1)
      p->user_reg.tp = p->trapframe->tp;
    80002972:	63b8                	ld	a4,64(a5)
    80002974:	1ae4b023          	sd	a4,416(s1)
      p->user_reg.s0 = p->trapframe->s0;
    80002978:	73b8                	ld	a4,96(a5)
    8000297a:	1ce4b023          	sd	a4,448(s1)
      p->user_reg.s1 = p->trapframe->s1;
    8000297e:	77b8                	ld	a4,104(a5)
    80002980:	1ce4b423          	sd	a4,456(s1)
      p->user_reg.s2 = p->trapframe->s2;
    80002984:	7bd8                	ld	a4,176(a5)
    80002986:	20e4b823          	sd	a4,528(s1)
      p->user_reg.s3 = p->trapframe->s3;
    8000298a:	7fd8                	ld	a4,184(a5)
    8000298c:	20e4bc23          	sd	a4,536(s1)
      p->user_reg.s4 = p->trapframe->s4;
    80002990:	63f8                	ld	a4,192(a5)
    80002992:	22e4b023          	sd	a4,544(s1)
      p->user_reg.s5 = p->trapframe->s5;
    80002996:	67f8                	ld	a4,200(a5)
    80002998:	22e4b423          	sd	a4,552(s1)
      p->user_reg.s6 = p->trapframe->s6;
    8000299c:	6bf8                	ld	a4,208(a5)
    8000299e:	22e4b823          	sd	a4,560(s1)
      p->user_reg.s7 = p->trapframe->s7;
    800029a2:	6ff8                	ld	a4,216(a5)
    800029a4:	22e4bc23          	sd	a4,568(s1)
      p->user_reg.s8 = p->trapframe->s8;
    800029a8:	73f8                	ld	a4,224(a5)
    800029aa:	24e4b023          	sd	a4,576(s1)
      p->user_reg.s9 = p->trapframe->s9;
    800029ae:	77f8                	ld	a4,232(a5)
    800029b0:	24e4b423          	sd	a4,584(s1)
      p->user_reg.s10 = p->trapframe->s10;
    800029b4:	7bf8                	ld	a4,240(a5)
    800029b6:	24e4b823          	sd	a4,592(s1)
      p->user_reg.s11 = p->trapframe->s11;
    800029ba:	7ff8                	ld	a4,248(a5)
    800029bc:	24e4bc23          	sd	a4,600(s1)
      p->user_reg.t0 = p->trapframe->t0;
    800029c0:	67b8                	ld	a4,72(a5)
    800029c2:	1ae4b423          	sd	a4,424(s1)
      p->user_reg.t1 = p->trapframe->t1;
    800029c6:	6bb8                	ld	a4,80(a5)
    800029c8:	1ae4b823          	sd	a4,432(s1)
      p->user_reg.t2 = p->trapframe->t2;
    800029cc:	6fb8                	ld	a4,88(a5)
    800029ce:	1ae4bc23          	sd	a4,440(s1)
      p->user_reg.t3 = p->trapframe->t3;
    800029d2:	1007b703          	ld	a4,256(a5)
    800029d6:	26e4b023          	sd	a4,608(s1)
      p->user_reg.t4 = p->trapframe->t4;
    800029da:	1087b703          	ld	a4,264(a5)
    800029de:	26e4b423          	sd	a4,616(s1)
      p->user_reg.t5 = p->trapframe->t5;
    800029e2:	1107b703          	ld	a4,272(a5)
    800029e6:	26e4b823          	sd	a4,624(s1)
      p->user_reg.t6 = p->trapframe->t6;
    800029ea:	1187b703          	ld	a4,280(a5)
    800029ee:	26e4bc23          	sd	a4,632(s1)
      p->user_reg.a0 = p->trapframe->a0;
    800029f2:	7bb8                	ld	a4,112(a5)
    800029f4:	1ce4b823          	sd	a4,464(s1)
      p->user_reg.a1 = p->trapframe->a1;
    800029f8:	7fb8                	ld	a4,120(a5)
    800029fa:	1ce4bc23          	sd	a4,472(s1)
      p->user_reg.a2 = p->trapframe->a2;
    800029fe:	63d8                	ld	a4,128(a5)
    80002a00:	1ee4b023          	sd	a4,480(s1)
      p->user_reg.a3 = p->trapframe->a3;
    80002a04:	67d8                	ld	a4,136(a5)
    80002a06:	1ee4b423          	sd	a4,488(s1)
      p->user_reg.a4 = p->trapframe->a4;
    80002a0a:	6bd8                	ld	a4,144(a5)
    80002a0c:	1ee4b823          	sd	a4,496(s1)
      p->user_reg.a5 = p->trapframe->a5;
    80002a10:	6fd8                	ld	a4,152(a5)
    80002a12:	1ee4bc23          	sd	a4,504(s1)
      p->user_reg.a6 = p->trapframe->a6;
    80002a16:	73d8                	ld	a4,160(a5)
    80002a18:	20e4b023          	sd	a4,512(s1)
      p->user_reg.a7 = p->trapframe->a7;
    80002a1c:	77d8                	ld	a4,168(a5)
    80002a1e:	20e4b423          	sd	a4,520(s1)
      p->in_alarm_handler = 1;
    80002a22:	4705                	li	a4,1
    80002a24:	28e4a023          	sw	a4,640(s1)
      p->trapframe->epc = p->handle;
    80002a28:	1684b703          	ld	a4,360(s1)
    80002a2c:	ef98                	sd	a4,24(a5)
      p->count_of_trick = 0;
    80002a2e:	1604aa23          	sw	zero,372(s1)
    80002a32:	bde5                	j	8000292a <usertrap+0xf2>

0000000080002a34 <kerneltrap>:
{
    80002a34:	7179                	addi	sp,sp,-48
    80002a36:	f406                	sd	ra,40(sp)
    80002a38:	f022                	sd	s0,32(sp)
    80002a3a:	ec26                	sd	s1,24(sp)
    80002a3c:	e84a                	sd	s2,16(sp)
    80002a3e:	e44e                	sd	s3,8(sp)
    80002a40:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a42:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a46:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a4a:	142029f3          	csrr	s3,scause
  if ((sstatus & SSTATUS_SPP) == 0)
    80002a4e:	1004f793          	andi	a5,s1,256
    80002a52:	cb85                	beqz	a5,80002a82 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a54:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002a58:	8b89                	andi	a5,a5,2
  if (intr_get() != 0)
    80002a5a:	ef85                	bnez	a5,80002a92 <kerneltrap+0x5e>
  if ((which_dev = devintr()) == 0)
    80002a5c:	00000097          	auipc	ra,0x0
    80002a60:	d3a080e7          	jalr	-710(ra) # 80002796 <devintr>
    80002a64:	cd1d                	beqz	a0,80002aa2 <kerneltrap+0x6e>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a66:	4789                	li	a5,2
    80002a68:	06f50a63          	beq	a0,a5,80002adc <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a6c:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a70:	10049073          	csrw	sstatus,s1
}
    80002a74:	70a2                	ld	ra,40(sp)
    80002a76:	7402                	ld	s0,32(sp)
    80002a78:	64e2                	ld	s1,24(sp)
    80002a7a:	6942                	ld	s2,16(sp)
    80002a7c:	69a2                	ld	s3,8(sp)
    80002a7e:	6145                	addi	sp,sp,48
    80002a80:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002a82:	00006517          	auipc	a0,0x6
    80002a86:	8fe50513          	addi	a0,a0,-1794 # 80008380 <states.0+0xc0>
    80002a8a:	ffffe097          	auipc	ra,0xffffe
    80002a8e:	b46080e7          	jalr	-1210(ra) # 800005d0 <panic>
    panic("kerneltrap: interrupts enabled");
    80002a92:	00006517          	auipc	a0,0x6
    80002a96:	91650513          	addi	a0,a0,-1770 # 800083a8 <states.0+0xe8>
    80002a9a:	ffffe097          	auipc	ra,0xffffe
    80002a9e:	b36080e7          	jalr	-1226(ra) # 800005d0 <panic>
    printf("scause %p\n", scause);
    80002aa2:	85ce                	mv	a1,s3
    80002aa4:	00006517          	auipc	a0,0x6
    80002aa8:	92450513          	addi	a0,a0,-1756 # 800083c8 <states.0+0x108>
    80002aac:	ffffe097          	auipc	ra,0xffffe
    80002ab0:	b76080e7          	jalr	-1162(ra) # 80000622 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ab4:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002ab8:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002abc:	00006517          	auipc	a0,0x6
    80002ac0:	91c50513          	addi	a0,a0,-1764 # 800083d8 <states.0+0x118>
    80002ac4:	ffffe097          	auipc	ra,0xffffe
    80002ac8:	b5e080e7          	jalr	-1186(ra) # 80000622 <printf>
    panic("kerneltrap");
    80002acc:	00006517          	auipc	a0,0x6
    80002ad0:	92450513          	addi	a0,a0,-1756 # 800083f0 <states.0+0x130>
    80002ad4:	ffffe097          	auipc	ra,0xffffe
    80002ad8:	afc080e7          	jalr	-1284(ra) # 800005d0 <panic>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002adc:	fffff097          	auipc	ra,0xfffff
    80002ae0:	f52080e7          	jalr	-174(ra) # 80001a2e <myproc>
    80002ae4:	d541                	beqz	a0,80002a6c <kerneltrap+0x38>
    80002ae6:	fffff097          	auipc	ra,0xfffff
    80002aea:	f48080e7          	jalr	-184(ra) # 80001a2e <myproc>
    80002aee:	4d18                	lw	a4,24(a0)
    80002af0:	478d                	li	a5,3
    80002af2:	f6f71de3          	bne	a4,a5,80002a6c <kerneltrap+0x38>
    yield();
    80002af6:	fffff097          	auipc	ra,0xfffff
    80002afa:	720080e7          	jalr	1824(ra) # 80002216 <yield>
    80002afe:	b7bd                	j	80002a6c <kerneltrap+0x38>

0000000080002b00 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002b00:	1101                	addi	sp,sp,-32
    80002b02:	ec06                	sd	ra,24(sp)
    80002b04:	e822                	sd	s0,16(sp)
    80002b06:	e426                	sd	s1,8(sp)
    80002b08:	1000                	addi	s0,sp,32
    80002b0a:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002b0c:	fffff097          	auipc	ra,0xfffff
    80002b10:	f22080e7          	jalr	-222(ra) # 80001a2e <myproc>
  switch (n) {
    80002b14:	4795                	li	a5,5
    80002b16:	0497e163          	bltu	a5,s1,80002b58 <argraw+0x58>
    80002b1a:	048a                	slli	s1,s1,0x2
    80002b1c:	00006717          	auipc	a4,0x6
    80002b20:	90c70713          	addi	a4,a4,-1780 # 80008428 <states.0+0x168>
    80002b24:	94ba                	add	s1,s1,a4
    80002b26:	409c                	lw	a5,0(s1)
    80002b28:	97ba                	add	a5,a5,a4
    80002b2a:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002b2c:	6d3c                	ld	a5,88(a0)
    80002b2e:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002b30:	60e2                	ld	ra,24(sp)
    80002b32:	6442                	ld	s0,16(sp)
    80002b34:	64a2                	ld	s1,8(sp)
    80002b36:	6105                	addi	sp,sp,32
    80002b38:	8082                	ret
    return p->trapframe->a1;
    80002b3a:	6d3c                	ld	a5,88(a0)
    80002b3c:	7fa8                	ld	a0,120(a5)
    80002b3e:	bfcd                	j	80002b30 <argraw+0x30>
    return p->trapframe->a2;
    80002b40:	6d3c                	ld	a5,88(a0)
    80002b42:	63c8                	ld	a0,128(a5)
    80002b44:	b7f5                	j	80002b30 <argraw+0x30>
    return p->trapframe->a3;
    80002b46:	6d3c                	ld	a5,88(a0)
    80002b48:	67c8                	ld	a0,136(a5)
    80002b4a:	b7dd                	j	80002b30 <argraw+0x30>
    return p->trapframe->a4;
    80002b4c:	6d3c                	ld	a5,88(a0)
    80002b4e:	6bc8                	ld	a0,144(a5)
    80002b50:	b7c5                	j	80002b30 <argraw+0x30>
    return p->trapframe->a5;
    80002b52:	6d3c                	ld	a5,88(a0)
    80002b54:	6fc8                	ld	a0,152(a5)
    80002b56:	bfe9                	j	80002b30 <argraw+0x30>
  panic("argraw");
    80002b58:	00006517          	auipc	a0,0x6
    80002b5c:	8a850513          	addi	a0,a0,-1880 # 80008400 <states.0+0x140>
    80002b60:	ffffe097          	auipc	ra,0xffffe
    80002b64:	a70080e7          	jalr	-1424(ra) # 800005d0 <panic>

0000000080002b68 <fetchaddr>:
{
    80002b68:	1101                	addi	sp,sp,-32
    80002b6a:	ec06                	sd	ra,24(sp)
    80002b6c:	e822                	sd	s0,16(sp)
    80002b6e:	e426                	sd	s1,8(sp)
    80002b70:	e04a                	sd	s2,0(sp)
    80002b72:	1000                	addi	s0,sp,32
    80002b74:	84aa                	mv	s1,a0
    80002b76:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002b78:	fffff097          	auipc	ra,0xfffff
    80002b7c:	eb6080e7          	jalr	-330(ra) # 80001a2e <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002b80:	653c                	ld	a5,72(a0)
    80002b82:	02f4f863          	bgeu	s1,a5,80002bb2 <fetchaddr+0x4a>
    80002b86:	00848713          	addi	a4,s1,8
    80002b8a:	02e7e663          	bltu	a5,a4,80002bb6 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002b8e:	46a1                	li	a3,8
    80002b90:	8626                	mv	a2,s1
    80002b92:	85ca                	mv	a1,s2
    80002b94:	6928                	ld	a0,80(a0)
    80002b96:	fffff097          	auipc	ra,0xfffff
    80002b9a:	c16080e7          	jalr	-1002(ra) # 800017ac <copyin>
    80002b9e:	00a03533          	snez	a0,a0
    80002ba2:	40a00533          	neg	a0,a0
}
    80002ba6:	60e2                	ld	ra,24(sp)
    80002ba8:	6442                	ld	s0,16(sp)
    80002baa:	64a2                	ld	s1,8(sp)
    80002bac:	6902                	ld	s2,0(sp)
    80002bae:	6105                	addi	sp,sp,32
    80002bb0:	8082                	ret
    return -1;
    80002bb2:	557d                	li	a0,-1
    80002bb4:	bfcd                	j	80002ba6 <fetchaddr+0x3e>
    80002bb6:	557d                	li	a0,-1
    80002bb8:	b7fd                	j	80002ba6 <fetchaddr+0x3e>

0000000080002bba <fetchstr>:
{
    80002bba:	7179                	addi	sp,sp,-48
    80002bbc:	f406                	sd	ra,40(sp)
    80002bbe:	f022                	sd	s0,32(sp)
    80002bc0:	ec26                	sd	s1,24(sp)
    80002bc2:	e84a                	sd	s2,16(sp)
    80002bc4:	e44e                	sd	s3,8(sp)
    80002bc6:	1800                	addi	s0,sp,48
    80002bc8:	892a                	mv	s2,a0
    80002bca:	84ae                	mv	s1,a1
    80002bcc:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002bce:	fffff097          	auipc	ra,0xfffff
    80002bd2:	e60080e7          	jalr	-416(ra) # 80001a2e <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002bd6:	86ce                	mv	a3,s3
    80002bd8:	864a                	mv	a2,s2
    80002bda:	85a6                	mv	a1,s1
    80002bdc:	6928                	ld	a0,80(a0)
    80002bde:	fffff097          	auipc	ra,0xfffff
    80002be2:	c5c080e7          	jalr	-932(ra) # 8000183a <copyinstr>
  if(err < 0)
    80002be6:	00054763          	bltz	a0,80002bf4 <fetchstr+0x3a>
  return strlen(buf);
    80002bea:	8526                	mv	a0,s1
    80002bec:	ffffe097          	auipc	ra,0xffffe
    80002bf0:	2f6080e7          	jalr	758(ra) # 80000ee2 <strlen>
}
    80002bf4:	70a2                	ld	ra,40(sp)
    80002bf6:	7402                	ld	s0,32(sp)
    80002bf8:	64e2                	ld	s1,24(sp)
    80002bfa:	6942                	ld	s2,16(sp)
    80002bfc:	69a2                	ld	s3,8(sp)
    80002bfe:	6145                	addi	sp,sp,48
    80002c00:	8082                	ret

0000000080002c02 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002c02:	1101                	addi	sp,sp,-32
    80002c04:	ec06                	sd	ra,24(sp)
    80002c06:	e822                	sd	s0,16(sp)
    80002c08:	e426                	sd	s1,8(sp)
    80002c0a:	1000                	addi	s0,sp,32
    80002c0c:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002c0e:	00000097          	auipc	ra,0x0
    80002c12:	ef2080e7          	jalr	-270(ra) # 80002b00 <argraw>
    80002c16:	c088                	sw	a0,0(s1)
  return 0;
}
    80002c18:	4501                	li	a0,0
    80002c1a:	60e2                	ld	ra,24(sp)
    80002c1c:	6442                	ld	s0,16(sp)
    80002c1e:	64a2                	ld	s1,8(sp)
    80002c20:	6105                	addi	sp,sp,32
    80002c22:	8082                	ret

0000000080002c24 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002c24:	1101                	addi	sp,sp,-32
    80002c26:	ec06                	sd	ra,24(sp)
    80002c28:	e822                	sd	s0,16(sp)
    80002c2a:	e426                	sd	s1,8(sp)
    80002c2c:	1000                	addi	s0,sp,32
    80002c2e:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002c30:	00000097          	auipc	ra,0x0
    80002c34:	ed0080e7          	jalr	-304(ra) # 80002b00 <argraw>
    80002c38:	e088                	sd	a0,0(s1)
  return 0;
}
    80002c3a:	4501                	li	a0,0
    80002c3c:	60e2                	ld	ra,24(sp)
    80002c3e:	6442                	ld	s0,16(sp)
    80002c40:	64a2                	ld	s1,8(sp)
    80002c42:	6105                	addi	sp,sp,32
    80002c44:	8082                	ret

0000000080002c46 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002c46:	1101                	addi	sp,sp,-32
    80002c48:	ec06                	sd	ra,24(sp)
    80002c4a:	e822                	sd	s0,16(sp)
    80002c4c:	e426                	sd	s1,8(sp)
    80002c4e:	e04a                	sd	s2,0(sp)
    80002c50:	1000                	addi	s0,sp,32
    80002c52:	84ae                	mv	s1,a1
    80002c54:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002c56:	00000097          	auipc	ra,0x0
    80002c5a:	eaa080e7          	jalr	-342(ra) # 80002b00 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002c5e:	864a                	mv	a2,s2
    80002c60:	85a6                	mv	a1,s1
    80002c62:	00000097          	auipc	ra,0x0
    80002c66:	f58080e7          	jalr	-168(ra) # 80002bba <fetchstr>
}
    80002c6a:	60e2                	ld	ra,24(sp)
    80002c6c:	6442                	ld	s0,16(sp)
    80002c6e:	64a2                	ld	s1,8(sp)
    80002c70:	6902                	ld	s2,0(sp)
    80002c72:	6105                	addi	sp,sp,32
    80002c74:	8082                	ret

0000000080002c76 <syscall>:
[SYS_sigreturn]   sys_sigreturn,
};

void
syscall(void)
{
    80002c76:	1101                	addi	sp,sp,-32
    80002c78:	ec06                	sd	ra,24(sp)
    80002c7a:	e822                	sd	s0,16(sp)
    80002c7c:	e426                	sd	s1,8(sp)
    80002c7e:	e04a                	sd	s2,0(sp)
    80002c80:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002c82:	fffff097          	auipc	ra,0xfffff
    80002c86:	dac080e7          	jalr	-596(ra) # 80001a2e <myproc>
    80002c8a:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002c8c:	05853903          	ld	s2,88(a0)
    80002c90:	0a893783          	ld	a5,168(s2)
    80002c94:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002c98:	37fd                	addiw	a5,a5,-1
    80002c9a:	4759                	li	a4,22
    80002c9c:	00f76f63          	bltu	a4,a5,80002cba <syscall+0x44>
    80002ca0:	00369713          	slli	a4,a3,0x3
    80002ca4:	00005797          	auipc	a5,0x5
    80002ca8:	79c78793          	addi	a5,a5,1948 # 80008440 <syscalls>
    80002cac:	97ba                	add	a5,a5,a4
    80002cae:	639c                	ld	a5,0(a5)
    80002cb0:	c789                	beqz	a5,80002cba <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002cb2:	9782                	jalr	a5
    80002cb4:	06a93823          	sd	a0,112(s2)
    80002cb8:	a839                	j	80002cd6 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002cba:	15848613          	addi	a2,s1,344
    80002cbe:	5c8c                	lw	a1,56(s1)
    80002cc0:	00005517          	auipc	a0,0x5
    80002cc4:	74850513          	addi	a0,a0,1864 # 80008408 <states.0+0x148>
    80002cc8:	ffffe097          	auipc	ra,0xffffe
    80002ccc:	95a080e7          	jalr	-1702(ra) # 80000622 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002cd0:	6cbc                	ld	a5,88(s1)
    80002cd2:	577d                	li	a4,-1
    80002cd4:	fbb8                	sd	a4,112(a5)
  }
}
    80002cd6:	60e2                	ld	ra,24(sp)
    80002cd8:	6442                	ld	s0,16(sp)
    80002cda:	64a2                	ld	s1,8(sp)
    80002cdc:	6902                	ld	s2,0(sp)
    80002cde:	6105                	addi	sp,sp,32
    80002ce0:	8082                	ret

0000000080002ce2 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002ce2:	1101                	addi	sp,sp,-32
    80002ce4:	ec06                	sd	ra,24(sp)
    80002ce6:	e822                	sd	s0,16(sp)
    80002ce8:	1000                	addi	s0,sp,32
  int n;
  if (argint(0, &n) < 0)
    80002cea:	fec40593          	addi	a1,s0,-20
    80002cee:	4501                	li	a0,0
    80002cf0:	00000097          	auipc	ra,0x0
    80002cf4:	f12080e7          	jalr	-238(ra) # 80002c02 <argint>
    return -1;
    80002cf8:	57fd                	li	a5,-1
  if (argint(0, &n) < 0)
    80002cfa:	00054963          	bltz	a0,80002d0c <sys_exit+0x2a>
  exit(n);
    80002cfe:	fec42503          	lw	a0,-20(s0)
    80002d02:	fffff097          	auipc	ra,0xfffff
    80002d06:	40a080e7          	jalr	1034(ra) # 8000210c <exit>
  return 0; // not reached
    80002d0a:	4781                	li	a5,0
}
    80002d0c:	853e                	mv	a0,a5
    80002d0e:	60e2                	ld	ra,24(sp)
    80002d10:	6442                	ld	s0,16(sp)
    80002d12:	6105                	addi	sp,sp,32
    80002d14:	8082                	ret

0000000080002d16 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002d16:	1141                	addi	sp,sp,-16
    80002d18:	e406                	sd	ra,8(sp)
    80002d1a:	e022                	sd	s0,0(sp)
    80002d1c:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002d1e:	fffff097          	auipc	ra,0xfffff
    80002d22:	d10080e7          	jalr	-752(ra) # 80001a2e <myproc>
}
    80002d26:	5d08                	lw	a0,56(a0)
    80002d28:	60a2                	ld	ra,8(sp)
    80002d2a:	6402                	ld	s0,0(sp)
    80002d2c:	0141                	addi	sp,sp,16
    80002d2e:	8082                	ret

0000000080002d30 <sys_fork>:

uint64
sys_fork(void)
{
    80002d30:	1141                	addi	sp,sp,-16
    80002d32:	e406                	sd	ra,8(sp)
    80002d34:	e022                	sd	s0,0(sp)
    80002d36:	0800                	addi	s0,sp,16
  return fork();
    80002d38:	fffff097          	auipc	ra,0xfffff
    80002d3c:	0ca080e7          	jalr	202(ra) # 80001e02 <fork>
}
    80002d40:	60a2                	ld	ra,8(sp)
    80002d42:	6402                	ld	s0,0(sp)
    80002d44:	0141                	addi	sp,sp,16
    80002d46:	8082                	ret

0000000080002d48 <sys_wait>:

uint64
sys_wait(void)
{
    80002d48:	1101                	addi	sp,sp,-32
    80002d4a:	ec06                	sd	ra,24(sp)
    80002d4c:	e822                	sd	s0,16(sp)
    80002d4e:	1000                	addi	s0,sp,32
  uint64 p;
  if (argaddr(0, &p) < 0)
    80002d50:	fe840593          	addi	a1,s0,-24
    80002d54:	4501                	li	a0,0
    80002d56:	00000097          	auipc	ra,0x0
    80002d5a:	ece080e7          	jalr	-306(ra) # 80002c24 <argaddr>
    80002d5e:	87aa                	mv	a5,a0
    return -1;
    80002d60:	557d                	li	a0,-1
  if (argaddr(0, &p) < 0)
    80002d62:	0007c863          	bltz	a5,80002d72 <sys_wait+0x2a>
  return wait(p);
    80002d66:	fe843503          	ld	a0,-24(s0)
    80002d6a:	fffff097          	auipc	ra,0xfffff
    80002d6e:	566080e7          	jalr	1382(ra) # 800022d0 <wait>
}
    80002d72:	60e2                	ld	ra,24(sp)
    80002d74:	6442                	ld	s0,16(sp)
    80002d76:	6105                	addi	sp,sp,32
    80002d78:	8082                	ret

0000000080002d7a <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002d7a:	7179                	addi	sp,sp,-48
    80002d7c:	f406                	sd	ra,40(sp)
    80002d7e:	f022                	sd	s0,32(sp)
    80002d80:	ec26                	sd	s1,24(sp)
    80002d82:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if (argint(0, &n) < 0)
    80002d84:	fdc40593          	addi	a1,s0,-36
    80002d88:	4501                	li	a0,0
    80002d8a:	00000097          	auipc	ra,0x0
    80002d8e:	e78080e7          	jalr	-392(ra) # 80002c02 <argint>
    return -1;
    80002d92:	54fd                	li	s1,-1
  if (argint(0, &n) < 0)
    80002d94:	00054f63          	bltz	a0,80002db2 <sys_sbrk+0x38>
  addr = myproc()->sz;
    80002d98:	fffff097          	auipc	ra,0xfffff
    80002d9c:	c96080e7          	jalr	-874(ra) # 80001a2e <myproc>
    80002da0:	4524                	lw	s1,72(a0)
  if (growproc(n) < 0)
    80002da2:	fdc42503          	lw	a0,-36(s0)
    80002da6:	fffff097          	auipc	ra,0xfffff
    80002daa:	fe8080e7          	jalr	-24(ra) # 80001d8e <growproc>
    80002dae:	00054863          	bltz	a0,80002dbe <sys_sbrk+0x44>
    return -1;
  return addr;
}
    80002db2:	8526                	mv	a0,s1
    80002db4:	70a2                	ld	ra,40(sp)
    80002db6:	7402                	ld	s0,32(sp)
    80002db8:	64e2                	ld	s1,24(sp)
    80002dba:	6145                	addi	sp,sp,48
    80002dbc:	8082                	ret
    return -1;
    80002dbe:	54fd                	li	s1,-1
    80002dc0:	bfcd                	j	80002db2 <sys_sbrk+0x38>

0000000080002dc2 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002dc2:	7139                	addi	sp,sp,-64
    80002dc4:	fc06                	sd	ra,56(sp)
    80002dc6:	f822                	sd	s0,48(sp)
    80002dc8:	f426                	sd	s1,40(sp)
    80002dca:	f04a                	sd	s2,32(sp)
    80002dcc:	ec4e                	sd	s3,24(sp)
    80002dce:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if (argint(0, &n) < 0)
    80002dd0:	fcc40593          	addi	a1,s0,-52
    80002dd4:	4501                	li	a0,0
    80002dd6:	00000097          	auipc	ra,0x0
    80002dda:	e2c080e7          	jalr	-468(ra) # 80002c02 <argint>
    return -1;
    80002dde:	57fd                	li	a5,-1
  if (argint(0, &n) < 0)
    80002de0:	06054963          	bltz	a0,80002e52 <sys_sleep+0x90>
  acquire(&tickslock);
    80002de4:	00019517          	auipc	a0,0x19
    80002de8:	18450513          	addi	a0,a0,388 # 8001bf68 <tickslock>
    80002dec:	ffffe097          	auipc	ra,0xffffe
    80002df0:	e76080e7          	jalr	-394(ra) # 80000c62 <acquire>
  ticks0 = ticks;
    80002df4:	00006917          	auipc	s2,0x6
    80002df8:	22c92903          	lw	s2,556(s2) # 80009020 <ticks>
  while (ticks - ticks0 < n)
    80002dfc:	fcc42783          	lw	a5,-52(s0)
    80002e00:	cf85                	beqz	a5,80002e38 <sys_sleep+0x76>
    if (myproc()->killed)
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002e02:	00019997          	auipc	s3,0x19
    80002e06:	16698993          	addi	s3,s3,358 # 8001bf68 <tickslock>
    80002e0a:	00006497          	auipc	s1,0x6
    80002e0e:	21648493          	addi	s1,s1,534 # 80009020 <ticks>
    if (myproc()->killed)
    80002e12:	fffff097          	auipc	ra,0xfffff
    80002e16:	c1c080e7          	jalr	-996(ra) # 80001a2e <myproc>
    80002e1a:	591c                	lw	a5,48(a0)
    80002e1c:	e3b9                	bnez	a5,80002e62 <sys_sleep+0xa0>
    sleep(&ticks, &tickslock);
    80002e1e:	85ce                	mv	a1,s3
    80002e20:	8526                	mv	a0,s1
    80002e22:	fffff097          	auipc	ra,0xfffff
    80002e26:	430080e7          	jalr	1072(ra) # 80002252 <sleep>
  while (ticks - ticks0 < n)
    80002e2a:	409c                	lw	a5,0(s1)
    80002e2c:	412787bb          	subw	a5,a5,s2
    80002e30:	fcc42703          	lw	a4,-52(s0)
    80002e34:	fce7efe3          	bltu	a5,a4,80002e12 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002e38:	00019517          	auipc	a0,0x19
    80002e3c:	13050513          	addi	a0,a0,304 # 8001bf68 <tickslock>
    80002e40:	ffffe097          	auipc	ra,0xffffe
    80002e44:	ed6080e7          	jalr	-298(ra) # 80000d16 <release>
  backtrace();
    80002e48:	ffffd097          	auipc	ra,0xffffd
    80002e4c:	72c080e7          	jalr	1836(ra) # 80000574 <backtrace>
  return 0;
    80002e50:	4781                	li	a5,0
}
    80002e52:	853e                	mv	a0,a5
    80002e54:	70e2                	ld	ra,56(sp)
    80002e56:	7442                	ld	s0,48(sp)
    80002e58:	74a2                	ld	s1,40(sp)
    80002e5a:	7902                	ld	s2,32(sp)
    80002e5c:	69e2                	ld	s3,24(sp)
    80002e5e:	6121                	addi	sp,sp,64
    80002e60:	8082                	ret
      release(&tickslock);
    80002e62:	00019517          	auipc	a0,0x19
    80002e66:	10650513          	addi	a0,a0,262 # 8001bf68 <tickslock>
    80002e6a:	ffffe097          	auipc	ra,0xffffe
    80002e6e:	eac080e7          	jalr	-340(ra) # 80000d16 <release>
      return -1;
    80002e72:	57fd                	li	a5,-1
    80002e74:	bff9                	j	80002e52 <sys_sleep+0x90>

0000000080002e76 <sys_kill>:

uint64
sys_kill(void)
{
    80002e76:	1101                	addi	sp,sp,-32
    80002e78:	ec06                	sd	ra,24(sp)
    80002e7a:	e822                	sd	s0,16(sp)
    80002e7c:	1000                	addi	s0,sp,32
  int pid;

  if (argint(0, &pid) < 0)
    80002e7e:	fec40593          	addi	a1,s0,-20
    80002e82:	4501                	li	a0,0
    80002e84:	00000097          	auipc	ra,0x0
    80002e88:	d7e080e7          	jalr	-642(ra) # 80002c02 <argint>
    80002e8c:	87aa                	mv	a5,a0
    return -1;
    80002e8e:	557d                	li	a0,-1
  if (argint(0, &pid) < 0)
    80002e90:	0007c863          	bltz	a5,80002ea0 <sys_kill+0x2a>
  return kill(pid);
    80002e94:	fec42503          	lw	a0,-20(s0)
    80002e98:	fffff097          	auipc	ra,0xfffff
    80002e9c:	5a4080e7          	jalr	1444(ra) # 8000243c <kill>
}
    80002ea0:	60e2                	ld	ra,24(sp)
    80002ea2:	6442                	ld	s0,16(sp)
    80002ea4:	6105                	addi	sp,sp,32
    80002ea6:	8082                	ret

0000000080002ea8 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002ea8:	1101                	addi	sp,sp,-32
    80002eaa:	ec06                	sd	ra,24(sp)
    80002eac:	e822                	sd	s0,16(sp)
    80002eae:	e426                	sd	s1,8(sp)
    80002eb0:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002eb2:	00019517          	auipc	a0,0x19
    80002eb6:	0b650513          	addi	a0,a0,182 # 8001bf68 <tickslock>
    80002eba:	ffffe097          	auipc	ra,0xffffe
    80002ebe:	da8080e7          	jalr	-600(ra) # 80000c62 <acquire>
  xticks = ticks;
    80002ec2:	00006497          	auipc	s1,0x6
    80002ec6:	15e4a483          	lw	s1,350(s1) # 80009020 <ticks>
  release(&tickslock);
    80002eca:	00019517          	auipc	a0,0x19
    80002ece:	09e50513          	addi	a0,a0,158 # 8001bf68 <tickslock>
    80002ed2:	ffffe097          	auipc	ra,0xffffe
    80002ed6:	e44080e7          	jalr	-444(ra) # 80000d16 <release>
  return xticks;
}
    80002eda:	02049513          	slli	a0,s1,0x20
    80002ede:	9101                	srli	a0,a0,0x20
    80002ee0:	60e2                	ld	ra,24(sp)
    80002ee2:	6442                	ld	s0,16(sp)
    80002ee4:	64a2                	ld	s1,8(sp)
    80002ee6:	6105                	addi	sp,sp,32
    80002ee8:	8082                	ret

0000000080002eea <sys_sigreturn>:

// sys_sigreturn
uint64
sys_sigreturn(void)
{
    80002eea:	1141                	addi	sp,sp,-16
    80002eec:	e406                	sd	ra,8(sp)
    80002eee:	e022                	sd	s0,0(sp)
    80002ef0:	0800                	addi	s0,sp,16
  // save enough state in struct proc context when the timer goes off
  // that sigreturn can correctly return to the interrupted user code.
  struct proc *p = myproc();
    80002ef2:	fffff097          	auipc	ra,0xfffff
    80002ef6:	b3c080e7          	jalr	-1220(ra) # 80001a2e <myproc>
  p->trapframe->epc = p->user_reg.epc;
    80002efa:	6d3c                	ld	a5,88(a0)
    80002efc:	18053703          	ld	a4,384(a0)
    80002f00:	ef98                	sd	a4,24(a5)
  p->trapframe->ra = p->user_reg.ra;
    80002f02:	6d3c                	ld	a5,88(a0)
    80002f04:	18853703          	ld	a4,392(a0)
    80002f08:	f798                	sd	a4,40(a5)
  p->trapframe->sp = p->user_reg.sp;
    80002f0a:	6d3c                	ld	a5,88(a0)
    80002f0c:	19053703          	ld	a4,400(a0)
    80002f10:	fb98                	sd	a4,48(a5)
  p->trapframe->gp = p->user_reg.gp;
    80002f12:	6d3c                	ld	a5,88(a0)
    80002f14:	19853703          	ld	a4,408(a0)
    80002f18:	ff98                	sd	a4,56(a5)
  p->trapframe->tp = p->user_reg.tp;
    80002f1a:	6d3c                	ld	a5,88(a0)
    80002f1c:	1a053703          	ld	a4,416(a0)
    80002f20:	e3b8                	sd	a4,64(a5)

  p->trapframe->s0 = p->user_reg.s0;
    80002f22:	6d3c                	ld	a5,88(a0)
    80002f24:	1c053703          	ld	a4,448(a0)
    80002f28:	f3b8                	sd	a4,96(a5)
  p->trapframe->s1 = p->user_reg.s1;
    80002f2a:	6d3c                	ld	a5,88(a0)
    80002f2c:	1c853703          	ld	a4,456(a0)
    80002f30:	f7b8                	sd	a4,104(a5)
  p->trapframe->s2 = p->user_reg.s2;
    80002f32:	6d3c                	ld	a5,88(a0)
    80002f34:	21053703          	ld	a4,528(a0)
    80002f38:	fbd8                	sd	a4,176(a5)
  p->trapframe->s3 = p->user_reg.s3;
    80002f3a:	6d3c                	ld	a5,88(a0)
    80002f3c:	21853703          	ld	a4,536(a0)
    80002f40:	ffd8                	sd	a4,184(a5)
  p->trapframe->s4 = p->user_reg.s4;
    80002f42:	6d3c                	ld	a5,88(a0)
    80002f44:	22053703          	ld	a4,544(a0)
    80002f48:	e3f8                	sd	a4,192(a5)
  p->trapframe->s5 = p->user_reg.s5;
    80002f4a:	6d3c                	ld	a5,88(a0)
    80002f4c:	22853703          	ld	a4,552(a0)
    80002f50:	e7f8                	sd	a4,200(a5)
  p->trapframe->s6 = p->user_reg.s6;
    80002f52:	6d3c                	ld	a5,88(a0)
    80002f54:	23053703          	ld	a4,560(a0)
    80002f58:	ebf8                	sd	a4,208(a5)
  p->trapframe->s7 = p->user_reg.s7;
    80002f5a:	6d3c                	ld	a5,88(a0)
    80002f5c:	23853703          	ld	a4,568(a0)
    80002f60:	eff8                	sd	a4,216(a5)
  p->trapframe->s8 = p->user_reg.s8;
    80002f62:	6d3c                	ld	a5,88(a0)
    80002f64:	24053703          	ld	a4,576(a0)
    80002f68:	f3f8                	sd	a4,224(a5)
  p->trapframe->s9 = p->user_reg.s9;
    80002f6a:	6d3c                	ld	a5,88(a0)
    80002f6c:	24853703          	ld	a4,584(a0)
    80002f70:	f7f8                	sd	a4,232(a5)
  p->trapframe->s10 = p->user_reg.s10;
    80002f72:	6d3c                	ld	a5,88(a0)
    80002f74:	25053703          	ld	a4,592(a0)
    80002f78:	fbf8                	sd	a4,240(a5)
  p->trapframe->s11 = p->user_reg.s11;
    80002f7a:	6d3c                	ld	a5,88(a0)
    80002f7c:	25853703          	ld	a4,600(a0)
    80002f80:	fff8                	sd	a4,248(a5)

  p->trapframe->t0 = p->user_reg.t0;
    80002f82:	6d3c                	ld	a5,88(a0)
    80002f84:	1a853703          	ld	a4,424(a0)
    80002f88:	e7b8                	sd	a4,72(a5)
  p->trapframe->t1 = p->user_reg.t1;
    80002f8a:	6d3c                	ld	a5,88(a0)
    80002f8c:	1b053703          	ld	a4,432(a0)
    80002f90:	ebb8                	sd	a4,80(a5)
  p->trapframe->t2 = p->user_reg.t2;
    80002f92:	6d3c                	ld	a5,88(a0)
    80002f94:	1b853703          	ld	a4,440(a0)
    80002f98:	efb8                	sd	a4,88(a5)
  p->trapframe->t3 = p->user_reg.t3;
    80002f9a:	6d3c                	ld	a5,88(a0)
    80002f9c:	26053703          	ld	a4,608(a0)
    80002fa0:	10e7b023          	sd	a4,256(a5)
  p->trapframe->t4 = p->user_reg.t4;
    80002fa4:	6d3c                	ld	a5,88(a0)
    80002fa6:	26853703          	ld	a4,616(a0)
    80002faa:	10e7b423          	sd	a4,264(a5)
  p->trapframe->t5 = p->user_reg.t5;
    80002fae:	6d3c                	ld	a5,88(a0)
    80002fb0:	27053703          	ld	a4,624(a0)
    80002fb4:	10e7b823          	sd	a4,272(a5)
  p->trapframe->t6 = p->user_reg.t6;
    80002fb8:	6d3c                	ld	a5,88(a0)
    80002fba:	27853703          	ld	a4,632(a0)
    80002fbe:	10e7bc23          	sd	a4,280(a5)

  p->trapframe->a0 = p->user_reg.a0;
    80002fc2:	6d3c                	ld	a5,88(a0)
    80002fc4:	1d053703          	ld	a4,464(a0)
    80002fc8:	fbb8                	sd	a4,112(a5)
  p->trapframe->a1 = p->user_reg.a1;
    80002fca:	6d3c                	ld	a5,88(a0)
    80002fcc:	1d853703          	ld	a4,472(a0)
    80002fd0:	ffb8                	sd	a4,120(a5)
  p->trapframe->a2 = p->user_reg.a2;
    80002fd2:	6d3c                	ld	a5,88(a0)
    80002fd4:	1e053703          	ld	a4,480(a0)
    80002fd8:	e3d8                	sd	a4,128(a5)
  p->trapframe->a3 = p->user_reg.a3;
    80002fda:	6d3c                	ld	a5,88(a0)
    80002fdc:	1e853703          	ld	a4,488(a0)
    80002fe0:	e7d8                	sd	a4,136(a5)
  p->trapframe->a4 = p->user_reg.a4;
    80002fe2:	6d3c                	ld	a5,88(a0)
    80002fe4:	1f053703          	ld	a4,496(a0)
    80002fe8:	ebd8                	sd	a4,144(a5)
  p->trapframe->a5 = p->user_reg.a5;
    80002fea:	6d3c                	ld	a5,88(a0)
    80002fec:	1f853703          	ld	a4,504(a0)
    80002ff0:	efd8                	sd	a4,152(a5)
  p->trapframe->a6 = p->user_reg.a6;
    80002ff2:	6d3c                	ld	a5,88(a0)
    80002ff4:	20053703          	ld	a4,512(a0)
    80002ff8:	f3d8                	sd	a4,160(a5)
  p->trapframe->a7 = p->user_reg.a7;
    80002ffa:	6d3c                	ld	a5,88(a0)
    80002ffc:	20853703          	ld	a4,520(a0)
    80003000:	f7d8                	sd	a4,168(a5)
  p->handle = 0;
    80003002:	16053423          	sd	zero,360(a0)
  // p->count_of_trick = 0;
  // p->alarm_interval = 0;
  // p->is_alarm = 0;
  p->in_alarm_handler = 0;
    80003006:	28052023          	sw	zero,640(a0)
  // usertrapret();
  // p->is_alarm = 0;
  // p->in_alarm_handler = 0;
  return 0;
}
    8000300a:	4501                	li	a0,0
    8000300c:	60a2                	ld	ra,8(sp)
    8000300e:	6402                	ld	s0,0(sp)
    80003010:	0141                	addi	sp,sp,16
    80003012:	8082                	ret

0000000080003014 <sys_sigalarm>:

uint64
sys_sigalarm(void)
{
    80003014:	7179                	addi	sp,sp,-48
    80003016:	f406                	sd	ra,40(sp)
    80003018:	f022                	sd	s0,32(sp)
    8000301a:	ec26                	sd	s1,24(sp)
    8000301c:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000301e:	fffff097          	auipc	ra,0xfffff
    80003022:	a10080e7          	jalr	-1520(ra) # 80001a2e <myproc>
    80003026:	84aa                	mv	s1,a0
  p->is_alarm = 1;
    80003028:	4785                	li	a5,1
    8000302a:	16f52c23          	sw	a5,376(a0)
  int tracks = 0;
    8000302e:	fc042e23          	sw	zero,-36(s0)
  if (argint(0, &tracks) < 0)
    80003032:	fdc40593          	addi	a1,s0,-36
    80003036:	4501                	li	a0,0
    80003038:	00000097          	auipc	ra,0x0
    8000303c:	bca080e7          	jalr	-1078(ra) # 80002c02 <argint>
    return -1;
    80003040:	57fd                	li	a5,-1
  if (argint(0, &tracks) < 0)
    80003042:	04054763          	bltz	a0,80003090 <sys_sigalarm+0x7c>
  p->alarm_interval = tracks;
    80003046:	fdc42583          	lw	a1,-36(s0)
    8000304a:	16b4a823          	sw	a1,368(s1)
  printf("tracks: %d \n", p->alarm_interval);
    8000304e:	00005517          	auipc	a0,0x5
    80003052:	4b250513          	addi	a0,a0,1202 # 80008500 <syscalls+0xc0>
    80003056:	ffffd097          	auipc	ra,0xffffd
    8000305a:	5cc080e7          	jalr	1484(ra) # 80000622 <printf>
  uint64 func = 0;
    8000305e:	fc043823          	sd	zero,-48(s0)
  if (argaddr(1, &func) < 0)
    80003062:	fd040593          	addi	a1,s0,-48
    80003066:	4505                	li	a0,1
    80003068:	00000097          	auipc	ra,0x0
    8000306c:	bbc080e7          	jalr	-1092(ra) # 80002c24 <argaddr>
    80003070:	00054d63          	bltz	a0,8000308a <sys_sigalarm+0x76>
    return -1;
  p->handle = func;
    80003074:	fd043783          	ld	a5,-48(s0)
    80003078:	16f4b423          	sd	a5,360(s1)
  if(tracks == 0 && func == 0)
    8000307c:	fdc42703          	lw	a4,-36(s0)
    80003080:	e719                	bnez	a4,8000308e <sys_sigalarm+0x7a>
    80003082:	ef89                	bnez	a5,8000309c <sys_sigalarm+0x88>
    p->is_alarm = 0;
    80003084:	1604ac23          	sw	zero,376(s1)
    80003088:	a021                	j	80003090 <sys_sigalarm+0x7c>
    return -1;
    8000308a:	57fd                	li	a5,-1
    8000308c:	a011                	j	80003090 <sys_sigalarm+0x7c>
  return 0;
    8000308e:	4781                	li	a5,0
    80003090:	853e                	mv	a0,a5
    80003092:	70a2                	ld	ra,40(sp)
    80003094:	7402                	ld	s0,32(sp)
    80003096:	64e2                	ld	s1,24(sp)
    80003098:	6145                	addi	sp,sp,48
    8000309a:	8082                	ret
  return 0;
    8000309c:	4781                	li	a5,0
    8000309e:	bfcd                	j	80003090 <sys_sigalarm+0x7c>

00000000800030a0 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800030a0:	7179                	addi	sp,sp,-48
    800030a2:	f406                	sd	ra,40(sp)
    800030a4:	f022                	sd	s0,32(sp)
    800030a6:	ec26                	sd	s1,24(sp)
    800030a8:	e84a                	sd	s2,16(sp)
    800030aa:	e44e                	sd	s3,8(sp)
    800030ac:	e052                	sd	s4,0(sp)
    800030ae:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800030b0:	00005597          	auipc	a1,0x5
    800030b4:	46058593          	addi	a1,a1,1120 # 80008510 <syscalls+0xd0>
    800030b8:	00019517          	auipc	a0,0x19
    800030bc:	ec850513          	addi	a0,a0,-312 # 8001bf80 <bcache>
    800030c0:	ffffe097          	auipc	ra,0xffffe
    800030c4:	b12080e7          	jalr	-1262(ra) # 80000bd2 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800030c8:	00021797          	auipc	a5,0x21
    800030cc:	eb878793          	addi	a5,a5,-328 # 80023f80 <bcache+0x8000>
    800030d0:	00021717          	auipc	a4,0x21
    800030d4:	11870713          	addi	a4,a4,280 # 800241e8 <bcache+0x8268>
    800030d8:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800030dc:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800030e0:	00019497          	auipc	s1,0x19
    800030e4:	eb848493          	addi	s1,s1,-328 # 8001bf98 <bcache+0x18>
    b->next = bcache.head.next;
    800030e8:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800030ea:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800030ec:	00005a17          	auipc	s4,0x5
    800030f0:	42ca0a13          	addi	s4,s4,1068 # 80008518 <syscalls+0xd8>
    b->next = bcache.head.next;
    800030f4:	2b893783          	ld	a5,696(s2)
    800030f8:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800030fa:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800030fe:	85d2                	mv	a1,s4
    80003100:	01048513          	addi	a0,s1,16
    80003104:	00001097          	auipc	ra,0x1
    80003108:	4b2080e7          	jalr	1202(ra) # 800045b6 <initsleeplock>
    bcache.head.next->prev = b;
    8000310c:	2b893783          	ld	a5,696(s2)
    80003110:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003112:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003116:	45848493          	addi	s1,s1,1112
    8000311a:	fd349de3          	bne	s1,s3,800030f4 <binit+0x54>
  }
}
    8000311e:	70a2                	ld	ra,40(sp)
    80003120:	7402                	ld	s0,32(sp)
    80003122:	64e2                	ld	s1,24(sp)
    80003124:	6942                	ld	s2,16(sp)
    80003126:	69a2                	ld	s3,8(sp)
    80003128:	6a02                	ld	s4,0(sp)
    8000312a:	6145                	addi	sp,sp,48
    8000312c:	8082                	ret

000000008000312e <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    8000312e:	7179                	addi	sp,sp,-48
    80003130:	f406                	sd	ra,40(sp)
    80003132:	f022                	sd	s0,32(sp)
    80003134:	ec26                	sd	s1,24(sp)
    80003136:	e84a                	sd	s2,16(sp)
    80003138:	e44e                	sd	s3,8(sp)
    8000313a:	1800                	addi	s0,sp,48
    8000313c:	892a                	mv	s2,a0
    8000313e:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80003140:	00019517          	auipc	a0,0x19
    80003144:	e4050513          	addi	a0,a0,-448 # 8001bf80 <bcache>
    80003148:	ffffe097          	auipc	ra,0xffffe
    8000314c:	b1a080e7          	jalr	-1254(ra) # 80000c62 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003150:	00021497          	auipc	s1,0x21
    80003154:	0e84b483          	ld	s1,232(s1) # 80024238 <bcache+0x82b8>
    80003158:	00021797          	auipc	a5,0x21
    8000315c:	09078793          	addi	a5,a5,144 # 800241e8 <bcache+0x8268>
    80003160:	02f48f63          	beq	s1,a5,8000319e <bread+0x70>
    80003164:	873e                	mv	a4,a5
    80003166:	a021                	j	8000316e <bread+0x40>
    80003168:	68a4                	ld	s1,80(s1)
    8000316a:	02e48a63          	beq	s1,a4,8000319e <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    8000316e:	449c                	lw	a5,8(s1)
    80003170:	ff279ce3          	bne	a5,s2,80003168 <bread+0x3a>
    80003174:	44dc                	lw	a5,12(s1)
    80003176:	ff3799e3          	bne	a5,s3,80003168 <bread+0x3a>
      b->refcnt++;
    8000317a:	40bc                	lw	a5,64(s1)
    8000317c:	2785                	addiw	a5,a5,1
    8000317e:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003180:	00019517          	auipc	a0,0x19
    80003184:	e0050513          	addi	a0,a0,-512 # 8001bf80 <bcache>
    80003188:	ffffe097          	auipc	ra,0xffffe
    8000318c:	b8e080e7          	jalr	-1138(ra) # 80000d16 <release>
      acquiresleep(&b->lock);
    80003190:	01048513          	addi	a0,s1,16
    80003194:	00001097          	auipc	ra,0x1
    80003198:	45c080e7          	jalr	1116(ra) # 800045f0 <acquiresleep>
      return b;
    8000319c:	a8b9                	j	800031fa <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000319e:	00021497          	auipc	s1,0x21
    800031a2:	0924b483          	ld	s1,146(s1) # 80024230 <bcache+0x82b0>
    800031a6:	00021797          	auipc	a5,0x21
    800031aa:	04278793          	addi	a5,a5,66 # 800241e8 <bcache+0x8268>
    800031ae:	00f48863          	beq	s1,a5,800031be <bread+0x90>
    800031b2:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800031b4:	40bc                	lw	a5,64(s1)
    800031b6:	cf81                	beqz	a5,800031ce <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800031b8:	64a4                	ld	s1,72(s1)
    800031ba:	fee49de3          	bne	s1,a4,800031b4 <bread+0x86>
  panic("bget: no buffers");
    800031be:	00005517          	auipc	a0,0x5
    800031c2:	36250513          	addi	a0,a0,866 # 80008520 <syscalls+0xe0>
    800031c6:	ffffd097          	auipc	ra,0xffffd
    800031ca:	40a080e7          	jalr	1034(ra) # 800005d0 <panic>
      b->dev = dev;
    800031ce:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    800031d2:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    800031d6:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800031da:	4785                	li	a5,1
    800031dc:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800031de:	00019517          	auipc	a0,0x19
    800031e2:	da250513          	addi	a0,a0,-606 # 8001bf80 <bcache>
    800031e6:	ffffe097          	auipc	ra,0xffffe
    800031ea:	b30080e7          	jalr	-1232(ra) # 80000d16 <release>
      acquiresleep(&b->lock);
    800031ee:	01048513          	addi	a0,s1,16
    800031f2:	00001097          	auipc	ra,0x1
    800031f6:	3fe080e7          	jalr	1022(ra) # 800045f0 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800031fa:	409c                	lw	a5,0(s1)
    800031fc:	cb89                	beqz	a5,8000320e <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800031fe:	8526                	mv	a0,s1
    80003200:	70a2                	ld	ra,40(sp)
    80003202:	7402                	ld	s0,32(sp)
    80003204:	64e2                	ld	s1,24(sp)
    80003206:	6942                	ld	s2,16(sp)
    80003208:	69a2                	ld	s3,8(sp)
    8000320a:	6145                	addi	sp,sp,48
    8000320c:	8082                	ret
    virtio_disk_rw(b, 0);
    8000320e:	4581                	li	a1,0
    80003210:	8526                	mv	a0,s1
    80003212:	00003097          	auipc	ra,0x3
    80003216:	f2a080e7          	jalr	-214(ra) # 8000613c <virtio_disk_rw>
    b->valid = 1;
    8000321a:	4785                	li	a5,1
    8000321c:	c09c                	sw	a5,0(s1)
  return b;
    8000321e:	b7c5                	j	800031fe <bread+0xd0>

0000000080003220 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003220:	1101                	addi	sp,sp,-32
    80003222:	ec06                	sd	ra,24(sp)
    80003224:	e822                	sd	s0,16(sp)
    80003226:	e426                	sd	s1,8(sp)
    80003228:	1000                	addi	s0,sp,32
    8000322a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000322c:	0541                	addi	a0,a0,16
    8000322e:	00001097          	auipc	ra,0x1
    80003232:	45c080e7          	jalr	1116(ra) # 8000468a <holdingsleep>
    80003236:	cd01                	beqz	a0,8000324e <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003238:	4585                	li	a1,1
    8000323a:	8526                	mv	a0,s1
    8000323c:	00003097          	auipc	ra,0x3
    80003240:	f00080e7          	jalr	-256(ra) # 8000613c <virtio_disk_rw>
}
    80003244:	60e2                	ld	ra,24(sp)
    80003246:	6442                	ld	s0,16(sp)
    80003248:	64a2                	ld	s1,8(sp)
    8000324a:	6105                	addi	sp,sp,32
    8000324c:	8082                	ret
    panic("bwrite");
    8000324e:	00005517          	auipc	a0,0x5
    80003252:	2ea50513          	addi	a0,a0,746 # 80008538 <syscalls+0xf8>
    80003256:	ffffd097          	auipc	ra,0xffffd
    8000325a:	37a080e7          	jalr	890(ra) # 800005d0 <panic>

000000008000325e <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000325e:	1101                	addi	sp,sp,-32
    80003260:	ec06                	sd	ra,24(sp)
    80003262:	e822                	sd	s0,16(sp)
    80003264:	e426                	sd	s1,8(sp)
    80003266:	e04a                	sd	s2,0(sp)
    80003268:	1000                	addi	s0,sp,32
    8000326a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000326c:	01050913          	addi	s2,a0,16
    80003270:	854a                	mv	a0,s2
    80003272:	00001097          	auipc	ra,0x1
    80003276:	418080e7          	jalr	1048(ra) # 8000468a <holdingsleep>
    8000327a:	c92d                	beqz	a0,800032ec <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000327c:	854a                	mv	a0,s2
    8000327e:	00001097          	auipc	ra,0x1
    80003282:	3c8080e7          	jalr	968(ra) # 80004646 <releasesleep>

  acquire(&bcache.lock);
    80003286:	00019517          	auipc	a0,0x19
    8000328a:	cfa50513          	addi	a0,a0,-774 # 8001bf80 <bcache>
    8000328e:	ffffe097          	auipc	ra,0xffffe
    80003292:	9d4080e7          	jalr	-1580(ra) # 80000c62 <acquire>
  b->refcnt--;
    80003296:	40bc                	lw	a5,64(s1)
    80003298:	37fd                	addiw	a5,a5,-1
    8000329a:	0007871b          	sext.w	a4,a5
    8000329e:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800032a0:	eb05                	bnez	a4,800032d0 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800032a2:	68bc                	ld	a5,80(s1)
    800032a4:	64b8                	ld	a4,72(s1)
    800032a6:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800032a8:	64bc                	ld	a5,72(s1)
    800032aa:	68b8                	ld	a4,80(s1)
    800032ac:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800032ae:	00021797          	auipc	a5,0x21
    800032b2:	cd278793          	addi	a5,a5,-814 # 80023f80 <bcache+0x8000>
    800032b6:	2b87b703          	ld	a4,696(a5)
    800032ba:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800032bc:	00021717          	auipc	a4,0x21
    800032c0:	f2c70713          	addi	a4,a4,-212 # 800241e8 <bcache+0x8268>
    800032c4:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800032c6:	2b87b703          	ld	a4,696(a5)
    800032ca:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800032cc:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800032d0:	00019517          	auipc	a0,0x19
    800032d4:	cb050513          	addi	a0,a0,-848 # 8001bf80 <bcache>
    800032d8:	ffffe097          	auipc	ra,0xffffe
    800032dc:	a3e080e7          	jalr	-1474(ra) # 80000d16 <release>
}
    800032e0:	60e2                	ld	ra,24(sp)
    800032e2:	6442                	ld	s0,16(sp)
    800032e4:	64a2                	ld	s1,8(sp)
    800032e6:	6902                	ld	s2,0(sp)
    800032e8:	6105                	addi	sp,sp,32
    800032ea:	8082                	ret
    panic("brelse");
    800032ec:	00005517          	auipc	a0,0x5
    800032f0:	25450513          	addi	a0,a0,596 # 80008540 <syscalls+0x100>
    800032f4:	ffffd097          	auipc	ra,0xffffd
    800032f8:	2dc080e7          	jalr	732(ra) # 800005d0 <panic>

00000000800032fc <bpin>:

void
bpin(struct buf *b) {
    800032fc:	1101                	addi	sp,sp,-32
    800032fe:	ec06                	sd	ra,24(sp)
    80003300:	e822                	sd	s0,16(sp)
    80003302:	e426                	sd	s1,8(sp)
    80003304:	1000                	addi	s0,sp,32
    80003306:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003308:	00019517          	auipc	a0,0x19
    8000330c:	c7850513          	addi	a0,a0,-904 # 8001bf80 <bcache>
    80003310:	ffffe097          	auipc	ra,0xffffe
    80003314:	952080e7          	jalr	-1710(ra) # 80000c62 <acquire>
  b->refcnt++;
    80003318:	40bc                	lw	a5,64(s1)
    8000331a:	2785                	addiw	a5,a5,1
    8000331c:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000331e:	00019517          	auipc	a0,0x19
    80003322:	c6250513          	addi	a0,a0,-926 # 8001bf80 <bcache>
    80003326:	ffffe097          	auipc	ra,0xffffe
    8000332a:	9f0080e7          	jalr	-1552(ra) # 80000d16 <release>
}
    8000332e:	60e2                	ld	ra,24(sp)
    80003330:	6442                	ld	s0,16(sp)
    80003332:	64a2                	ld	s1,8(sp)
    80003334:	6105                	addi	sp,sp,32
    80003336:	8082                	ret

0000000080003338 <bunpin>:

void
bunpin(struct buf *b) {
    80003338:	1101                	addi	sp,sp,-32
    8000333a:	ec06                	sd	ra,24(sp)
    8000333c:	e822                	sd	s0,16(sp)
    8000333e:	e426                	sd	s1,8(sp)
    80003340:	1000                	addi	s0,sp,32
    80003342:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003344:	00019517          	auipc	a0,0x19
    80003348:	c3c50513          	addi	a0,a0,-964 # 8001bf80 <bcache>
    8000334c:	ffffe097          	auipc	ra,0xffffe
    80003350:	916080e7          	jalr	-1770(ra) # 80000c62 <acquire>
  b->refcnt--;
    80003354:	40bc                	lw	a5,64(s1)
    80003356:	37fd                	addiw	a5,a5,-1
    80003358:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000335a:	00019517          	auipc	a0,0x19
    8000335e:	c2650513          	addi	a0,a0,-986 # 8001bf80 <bcache>
    80003362:	ffffe097          	auipc	ra,0xffffe
    80003366:	9b4080e7          	jalr	-1612(ra) # 80000d16 <release>
}
    8000336a:	60e2                	ld	ra,24(sp)
    8000336c:	6442                	ld	s0,16(sp)
    8000336e:	64a2                	ld	s1,8(sp)
    80003370:	6105                	addi	sp,sp,32
    80003372:	8082                	ret

0000000080003374 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003374:	1101                	addi	sp,sp,-32
    80003376:	ec06                	sd	ra,24(sp)
    80003378:	e822                	sd	s0,16(sp)
    8000337a:	e426                	sd	s1,8(sp)
    8000337c:	e04a                	sd	s2,0(sp)
    8000337e:	1000                	addi	s0,sp,32
    80003380:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003382:	00d5d59b          	srliw	a1,a1,0xd
    80003386:	00021797          	auipc	a5,0x21
    8000338a:	2d67a783          	lw	a5,726(a5) # 8002465c <sb+0x1c>
    8000338e:	9dbd                	addw	a1,a1,a5
    80003390:	00000097          	auipc	ra,0x0
    80003394:	d9e080e7          	jalr	-610(ra) # 8000312e <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003398:	0074f713          	andi	a4,s1,7
    8000339c:	4785                	li	a5,1
    8000339e:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800033a2:	14ce                	slli	s1,s1,0x33
    800033a4:	90d9                	srli	s1,s1,0x36
    800033a6:	00950733          	add	a4,a0,s1
    800033aa:	05874703          	lbu	a4,88(a4)
    800033ae:	00e7f6b3          	and	a3,a5,a4
    800033b2:	c69d                	beqz	a3,800033e0 <bfree+0x6c>
    800033b4:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800033b6:	94aa                	add	s1,s1,a0
    800033b8:	fff7c793          	not	a5,a5
    800033bc:	8ff9                	and	a5,a5,a4
    800033be:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800033c2:	00001097          	auipc	ra,0x1
    800033c6:	106080e7          	jalr	262(ra) # 800044c8 <log_write>
  brelse(bp);
    800033ca:	854a                	mv	a0,s2
    800033cc:	00000097          	auipc	ra,0x0
    800033d0:	e92080e7          	jalr	-366(ra) # 8000325e <brelse>
}
    800033d4:	60e2                	ld	ra,24(sp)
    800033d6:	6442                	ld	s0,16(sp)
    800033d8:	64a2                	ld	s1,8(sp)
    800033da:	6902                	ld	s2,0(sp)
    800033dc:	6105                	addi	sp,sp,32
    800033de:	8082                	ret
    panic("freeing free block");
    800033e0:	00005517          	auipc	a0,0x5
    800033e4:	16850513          	addi	a0,a0,360 # 80008548 <syscalls+0x108>
    800033e8:	ffffd097          	auipc	ra,0xffffd
    800033ec:	1e8080e7          	jalr	488(ra) # 800005d0 <panic>

00000000800033f0 <balloc>:
{
    800033f0:	711d                	addi	sp,sp,-96
    800033f2:	ec86                	sd	ra,88(sp)
    800033f4:	e8a2                	sd	s0,80(sp)
    800033f6:	e4a6                	sd	s1,72(sp)
    800033f8:	e0ca                	sd	s2,64(sp)
    800033fa:	fc4e                	sd	s3,56(sp)
    800033fc:	f852                	sd	s4,48(sp)
    800033fe:	f456                	sd	s5,40(sp)
    80003400:	f05a                	sd	s6,32(sp)
    80003402:	ec5e                	sd	s7,24(sp)
    80003404:	e862                	sd	s8,16(sp)
    80003406:	e466                	sd	s9,8(sp)
    80003408:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000340a:	00021797          	auipc	a5,0x21
    8000340e:	23a7a783          	lw	a5,570(a5) # 80024644 <sb+0x4>
    80003412:	cbd1                	beqz	a5,800034a6 <balloc+0xb6>
    80003414:	8baa                	mv	s7,a0
    80003416:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003418:	00021b17          	auipc	s6,0x21
    8000341c:	228b0b13          	addi	s6,s6,552 # 80024640 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003420:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003422:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003424:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003426:	6c89                	lui	s9,0x2
    80003428:	a831                	j	80003444 <balloc+0x54>
    brelse(bp);
    8000342a:	854a                	mv	a0,s2
    8000342c:	00000097          	auipc	ra,0x0
    80003430:	e32080e7          	jalr	-462(ra) # 8000325e <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003434:	015c87bb          	addw	a5,s9,s5
    80003438:	00078a9b          	sext.w	s5,a5
    8000343c:	004b2703          	lw	a4,4(s6)
    80003440:	06eaf363          	bgeu	s5,a4,800034a6 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003444:	41fad79b          	sraiw	a5,s5,0x1f
    80003448:	0137d79b          	srliw	a5,a5,0x13
    8000344c:	015787bb          	addw	a5,a5,s5
    80003450:	40d7d79b          	sraiw	a5,a5,0xd
    80003454:	01cb2583          	lw	a1,28(s6)
    80003458:	9dbd                	addw	a1,a1,a5
    8000345a:	855e                	mv	a0,s7
    8000345c:	00000097          	auipc	ra,0x0
    80003460:	cd2080e7          	jalr	-814(ra) # 8000312e <bread>
    80003464:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003466:	004b2503          	lw	a0,4(s6)
    8000346a:	000a849b          	sext.w	s1,s5
    8000346e:	8662                	mv	a2,s8
    80003470:	faa4fde3          	bgeu	s1,a0,8000342a <balloc+0x3a>
      m = 1 << (bi % 8);
    80003474:	41f6579b          	sraiw	a5,a2,0x1f
    80003478:	01d7d69b          	srliw	a3,a5,0x1d
    8000347c:	00c6873b          	addw	a4,a3,a2
    80003480:	00777793          	andi	a5,a4,7
    80003484:	9f95                	subw	a5,a5,a3
    80003486:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000348a:	4037571b          	sraiw	a4,a4,0x3
    8000348e:	00e906b3          	add	a3,s2,a4
    80003492:	0586c683          	lbu	a3,88(a3)
    80003496:	00d7f5b3          	and	a1,a5,a3
    8000349a:	cd91                	beqz	a1,800034b6 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000349c:	2605                	addiw	a2,a2,1
    8000349e:	2485                	addiw	s1,s1,1
    800034a0:	fd4618e3          	bne	a2,s4,80003470 <balloc+0x80>
    800034a4:	b759                	j	8000342a <balloc+0x3a>
  panic("balloc: out of blocks");
    800034a6:	00005517          	auipc	a0,0x5
    800034aa:	0ba50513          	addi	a0,a0,186 # 80008560 <syscalls+0x120>
    800034ae:	ffffd097          	auipc	ra,0xffffd
    800034b2:	122080e7          	jalr	290(ra) # 800005d0 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800034b6:	974a                	add	a4,a4,s2
    800034b8:	8fd5                	or	a5,a5,a3
    800034ba:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800034be:	854a                	mv	a0,s2
    800034c0:	00001097          	auipc	ra,0x1
    800034c4:	008080e7          	jalr	8(ra) # 800044c8 <log_write>
        brelse(bp);
    800034c8:	854a                	mv	a0,s2
    800034ca:	00000097          	auipc	ra,0x0
    800034ce:	d94080e7          	jalr	-620(ra) # 8000325e <brelse>
  bp = bread(dev, bno);
    800034d2:	85a6                	mv	a1,s1
    800034d4:	855e                	mv	a0,s7
    800034d6:	00000097          	auipc	ra,0x0
    800034da:	c58080e7          	jalr	-936(ra) # 8000312e <bread>
    800034de:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800034e0:	40000613          	li	a2,1024
    800034e4:	4581                	li	a1,0
    800034e6:	05850513          	addi	a0,a0,88
    800034ea:	ffffe097          	auipc	ra,0xffffe
    800034ee:	874080e7          	jalr	-1932(ra) # 80000d5e <memset>
  log_write(bp);
    800034f2:	854a                	mv	a0,s2
    800034f4:	00001097          	auipc	ra,0x1
    800034f8:	fd4080e7          	jalr	-44(ra) # 800044c8 <log_write>
  brelse(bp);
    800034fc:	854a                	mv	a0,s2
    800034fe:	00000097          	auipc	ra,0x0
    80003502:	d60080e7          	jalr	-672(ra) # 8000325e <brelse>
}
    80003506:	8526                	mv	a0,s1
    80003508:	60e6                	ld	ra,88(sp)
    8000350a:	6446                	ld	s0,80(sp)
    8000350c:	64a6                	ld	s1,72(sp)
    8000350e:	6906                	ld	s2,64(sp)
    80003510:	79e2                	ld	s3,56(sp)
    80003512:	7a42                	ld	s4,48(sp)
    80003514:	7aa2                	ld	s5,40(sp)
    80003516:	7b02                	ld	s6,32(sp)
    80003518:	6be2                	ld	s7,24(sp)
    8000351a:	6c42                	ld	s8,16(sp)
    8000351c:	6ca2                	ld	s9,8(sp)
    8000351e:	6125                	addi	sp,sp,96
    80003520:	8082                	ret

0000000080003522 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003522:	7179                	addi	sp,sp,-48
    80003524:	f406                	sd	ra,40(sp)
    80003526:	f022                	sd	s0,32(sp)
    80003528:	ec26                	sd	s1,24(sp)
    8000352a:	e84a                	sd	s2,16(sp)
    8000352c:	e44e                	sd	s3,8(sp)
    8000352e:	e052                	sd	s4,0(sp)
    80003530:	1800                	addi	s0,sp,48
    80003532:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003534:	47ad                	li	a5,11
    80003536:	04b7fe63          	bgeu	a5,a1,80003592 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    8000353a:	ff45849b          	addiw	s1,a1,-12
    8000353e:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003542:	0ff00793          	li	a5,255
    80003546:	0ae7e463          	bltu	a5,a4,800035ee <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    8000354a:	08052583          	lw	a1,128(a0)
    8000354e:	c5b5                	beqz	a1,800035ba <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003550:	00092503          	lw	a0,0(s2)
    80003554:	00000097          	auipc	ra,0x0
    80003558:	bda080e7          	jalr	-1062(ra) # 8000312e <bread>
    8000355c:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000355e:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003562:	02049713          	slli	a4,s1,0x20
    80003566:	01e75593          	srli	a1,a4,0x1e
    8000356a:	00b784b3          	add	s1,a5,a1
    8000356e:	0004a983          	lw	s3,0(s1)
    80003572:	04098e63          	beqz	s3,800035ce <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003576:	8552                	mv	a0,s4
    80003578:	00000097          	auipc	ra,0x0
    8000357c:	ce6080e7          	jalr	-794(ra) # 8000325e <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003580:	854e                	mv	a0,s3
    80003582:	70a2                	ld	ra,40(sp)
    80003584:	7402                	ld	s0,32(sp)
    80003586:	64e2                	ld	s1,24(sp)
    80003588:	6942                	ld	s2,16(sp)
    8000358a:	69a2                	ld	s3,8(sp)
    8000358c:	6a02                	ld	s4,0(sp)
    8000358e:	6145                	addi	sp,sp,48
    80003590:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003592:	02059793          	slli	a5,a1,0x20
    80003596:	01e7d593          	srli	a1,a5,0x1e
    8000359a:	00b504b3          	add	s1,a0,a1
    8000359e:	0504a983          	lw	s3,80(s1)
    800035a2:	fc099fe3          	bnez	s3,80003580 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800035a6:	4108                	lw	a0,0(a0)
    800035a8:	00000097          	auipc	ra,0x0
    800035ac:	e48080e7          	jalr	-440(ra) # 800033f0 <balloc>
    800035b0:	0005099b          	sext.w	s3,a0
    800035b4:	0534a823          	sw	s3,80(s1)
    800035b8:	b7e1                	j	80003580 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800035ba:	4108                	lw	a0,0(a0)
    800035bc:	00000097          	auipc	ra,0x0
    800035c0:	e34080e7          	jalr	-460(ra) # 800033f0 <balloc>
    800035c4:	0005059b          	sext.w	a1,a0
    800035c8:	08b92023          	sw	a1,128(s2)
    800035cc:	b751                	j	80003550 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800035ce:	00092503          	lw	a0,0(s2)
    800035d2:	00000097          	auipc	ra,0x0
    800035d6:	e1e080e7          	jalr	-482(ra) # 800033f0 <balloc>
    800035da:	0005099b          	sext.w	s3,a0
    800035de:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800035e2:	8552                	mv	a0,s4
    800035e4:	00001097          	auipc	ra,0x1
    800035e8:	ee4080e7          	jalr	-284(ra) # 800044c8 <log_write>
    800035ec:	b769                	j	80003576 <bmap+0x54>
  panic("bmap: out of range");
    800035ee:	00005517          	auipc	a0,0x5
    800035f2:	f8a50513          	addi	a0,a0,-118 # 80008578 <syscalls+0x138>
    800035f6:	ffffd097          	auipc	ra,0xffffd
    800035fa:	fda080e7          	jalr	-38(ra) # 800005d0 <panic>

00000000800035fe <iget>:
{
    800035fe:	7179                	addi	sp,sp,-48
    80003600:	f406                	sd	ra,40(sp)
    80003602:	f022                	sd	s0,32(sp)
    80003604:	ec26                	sd	s1,24(sp)
    80003606:	e84a                	sd	s2,16(sp)
    80003608:	e44e                	sd	s3,8(sp)
    8000360a:	e052                	sd	s4,0(sp)
    8000360c:	1800                	addi	s0,sp,48
    8000360e:	89aa                	mv	s3,a0
    80003610:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    80003612:	00021517          	auipc	a0,0x21
    80003616:	04e50513          	addi	a0,a0,78 # 80024660 <icache>
    8000361a:	ffffd097          	auipc	ra,0xffffd
    8000361e:	648080e7          	jalr	1608(ra) # 80000c62 <acquire>
  empty = 0;
    80003622:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003624:	00021497          	auipc	s1,0x21
    80003628:	05448493          	addi	s1,s1,84 # 80024678 <icache+0x18>
    8000362c:	00023697          	auipc	a3,0x23
    80003630:	adc68693          	addi	a3,a3,-1316 # 80026108 <log>
    80003634:	a039                	j	80003642 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003636:	02090b63          	beqz	s2,8000366c <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    8000363a:	08848493          	addi	s1,s1,136
    8000363e:	02d48a63          	beq	s1,a3,80003672 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003642:	449c                	lw	a5,8(s1)
    80003644:	fef059e3          	blez	a5,80003636 <iget+0x38>
    80003648:	4098                	lw	a4,0(s1)
    8000364a:	ff3716e3          	bne	a4,s3,80003636 <iget+0x38>
    8000364e:	40d8                	lw	a4,4(s1)
    80003650:	ff4713e3          	bne	a4,s4,80003636 <iget+0x38>
      ip->ref++;
    80003654:	2785                	addiw	a5,a5,1
    80003656:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    80003658:	00021517          	auipc	a0,0x21
    8000365c:	00850513          	addi	a0,a0,8 # 80024660 <icache>
    80003660:	ffffd097          	auipc	ra,0xffffd
    80003664:	6b6080e7          	jalr	1718(ra) # 80000d16 <release>
      return ip;
    80003668:	8926                	mv	s2,s1
    8000366a:	a03d                	j	80003698 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000366c:	f7f9                	bnez	a5,8000363a <iget+0x3c>
    8000366e:	8926                	mv	s2,s1
    80003670:	b7e9                	j	8000363a <iget+0x3c>
  if(empty == 0)
    80003672:	02090c63          	beqz	s2,800036aa <iget+0xac>
  ip->dev = dev;
    80003676:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    8000367a:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000367e:	4785                	li	a5,1
    80003680:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003684:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    80003688:	00021517          	auipc	a0,0x21
    8000368c:	fd850513          	addi	a0,a0,-40 # 80024660 <icache>
    80003690:	ffffd097          	auipc	ra,0xffffd
    80003694:	686080e7          	jalr	1670(ra) # 80000d16 <release>
}
    80003698:	854a                	mv	a0,s2
    8000369a:	70a2                	ld	ra,40(sp)
    8000369c:	7402                	ld	s0,32(sp)
    8000369e:	64e2                	ld	s1,24(sp)
    800036a0:	6942                	ld	s2,16(sp)
    800036a2:	69a2                	ld	s3,8(sp)
    800036a4:	6a02                	ld	s4,0(sp)
    800036a6:	6145                	addi	sp,sp,48
    800036a8:	8082                	ret
    panic("iget: no inodes");
    800036aa:	00005517          	auipc	a0,0x5
    800036ae:	ee650513          	addi	a0,a0,-282 # 80008590 <syscalls+0x150>
    800036b2:	ffffd097          	auipc	ra,0xffffd
    800036b6:	f1e080e7          	jalr	-226(ra) # 800005d0 <panic>

00000000800036ba <fsinit>:
fsinit(int dev) {
    800036ba:	7179                	addi	sp,sp,-48
    800036bc:	f406                	sd	ra,40(sp)
    800036be:	f022                	sd	s0,32(sp)
    800036c0:	ec26                	sd	s1,24(sp)
    800036c2:	e84a                	sd	s2,16(sp)
    800036c4:	e44e                	sd	s3,8(sp)
    800036c6:	1800                	addi	s0,sp,48
    800036c8:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800036ca:	4585                	li	a1,1
    800036cc:	00000097          	auipc	ra,0x0
    800036d0:	a62080e7          	jalr	-1438(ra) # 8000312e <bread>
    800036d4:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800036d6:	00021997          	auipc	s3,0x21
    800036da:	f6a98993          	addi	s3,s3,-150 # 80024640 <sb>
    800036de:	02000613          	li	a2,32
    800036e2:	05850593          	addi	a1,a0,88
    800036e6:	854e                	mv	a0,s3
    800036e8:	ffffd097          	auipc	ra,0xffffd
    800036ec:	6d2080e7          	jalr	1746(ra) # 80000dba <memmove>
  brelse(bp);
    800036f0:	8526                	mv	a0,s1
    800036f2:	00000097          	auipc	ra,0x0
    800036f6:	b6c080e7          	jalr	-1172(ra) # 8000325e <brelse>
  if(sb.magic != FSMAGIC)
    800036fa:	0009a703          	lw	a4,0(s3)
    800036fe:	102037b7          	lui	a5,0x10203
    80003702:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003706:	02f71263          	bne	a4,a5,8000372a <fsinit+0x70>
  initlog(dev, &sb);
    8000370a:	00021597          	auipc	a1,0x21
    8000370e:	f3658593          	addi	a1,a1,-202 # 80024640 <sb>
    80003712:	854a                	mv	a0,s2
    80003714:	00001097          	auipc	ra,0x1
    80003718:	b3a080e7          	jalr	-1222(ra) # 8000424e <initlog>
}
    8000371c:	70a2                	ld	ra,40(sp)
    8000371e:	7402                	ld	s0,32(sp)
    80003720:	64e2                	ld	s1,24(sp)
    80003722:	6942                	ld	s2,16(sp)
    80003724:	69a2                	ld	s3,8(sp)
    80003726:	6145                	addi	sp,sp,48
    80003728:	8082                	ret
    panic("invalid file system");
    8000372a:	00005517          	auipc	a0,0x5
    8000372e:	e7650513          	addi	a0,a0,-394 # 800085a0 <syscalls+0x160>
    80003732:	ffffd097          	auipc	ra,0xffffd
    80003736:	e9e080e7          	jalr	-354(ra) # 800005d0 <panic>

000000008000373a <iinit>:
{
    8000373a:	7179                	addi	sp,sp,-48
    8000373c:	f406                	sd	ra,40(sp)
    8000373e:	f022                	sd	s0,32(sp)
    80003740:	ec26                	sd	s1,24(sp)
    80003742:	e84a                	sd	s2,16(sp)
    80003744:	e44e                	sd	s3,8(sp)
    80003746:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    80003748:	00005597          	auipc	a1,0x5
    8000374c:	e7058593          	addi	a1,a1,-400 # 800085b8 <syscalls+0x178>
    80003750:	00021517          	auipc	a0,0x21
    80003754:	f1050513          	addi	a0,a0,-240 # 80024660 <icache>
    80003758:	ffffd097          	auipc	ra,0xffffd
    8000375c:	47a080e7          	jalr	1146(ra) # 80000bd2 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003760:	00021497          	auipc	s1,0x21
    80003764:	f2848493          	addi	s1,s1,-216 # 80024688 <icache+0x28>
    80003768:	00023997          	auipc	s3,0x23
    8000376c:	9b098993          	addi	s3,s3,-1616 # 80026118 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    80003770:	00005917          	auipc	s2,0x5
    80003774:	e5090913          	addi	s2,s2,-432 # 800085c0 <syscalls+0x180>
    80003778:	85ca                	mv	a1,s2
    8000377a:	8526                	mv	a0,s1
    8000377c:	00001097          	auipc	ra,0x1
    80003780:	e3a080e7          	jalr	-454(ra) # 800045b6 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003784:	08848493          	addi	s1,s1,136
    80003788:	ff3498e3          	bne	s1,s3,80003778 <iinit+0x3e>
}
    8000378c:	70a2                	ld	ra,40(sp)
    8000378e:	7402                	ld	s0,32(sp)
    80003790:	64e2                	ld	s1,24(sp)
    80003792:	6942                	ld	s2,16(sp)
    80003794:	69a2                	ld	s3,8(sp)
    80003796:	6145                	addi	sp,sp,48
    80003798:	8082                	ret

000000008000379a <ialloc>:
{
    8000379a:	715d                	addi	sp,sp,-80
    8000379c:	e486                	sd	ra,72(sp)
    8000379e:	e0a2                	sd	s0,64(sp)
    800037a0:	fc26                	sd	s1,56(sp)
    800037a2:	f84a                	sd	s2,48(sp)
    800037a4:	f44e                	sd	s3,40(sp)
    800037a6:	f052                	sd	s4,32(sp)
    800037a8:	ec56                	sd	s5,24(sp)
    800037aa:	e85a                	sd	s6,16(sp)
    800037ac:	e45e                	sd	s7,8(sp)
    800037ae:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800037b0:	00021717          	auipc	a4,0x21
    800037b4:	e9c72703          	lw	a4,-356(a4) # 8002464c <sb+0xc>
    800037b8:	4785                	li	a5,1
    800037ba:	04e7fa63          	bgeu	a5,a4,8000380e <ialloc+0x74>
    800037be:	8aaa                	mv	s5,a0
    800037c0:	8bae                	mv	s7,a1
    800037c2:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800037c4:	00021a17          	auipc	s4,0x21
    800037c8:	e7ca0a13          	addi	s4,s4,-388 # 80024640 <sb>
    800037cc:	00048b1b          	sext.w	s6,s1
    800037d0:	0044d793          	srli	a5,s1,0x4
    800037d4:	018a2583          	lw	a1,24(s4)
    800037d8:	9dbd                	addw	a1,a1,a5
    800037da:	8556                	mv	a0,s5
    800037dc:	00000097          	auipc	ra,0x0
    800037e0:	952080e7          	jalr	-1710(ra) # 8000312e <bread>
    800037e4:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800037e6:	05850993          	addi	s3,a0,88
    800037ea:	00f4f793          	andi	a5,s1,15
    800037ee:	079a                	slli	a5,a5,0x6
    800037f0:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800037f2:	00099783          	lh	a5,0(s3)
    800037f6:	c785                	beqz	a5,8000381e <ialloc+0x84>
    brelse(bp);
    800037f8:	00000097          	auipc	ra,0x0
    800037fc:	a66080e7          	jalr	-1434(ra) # 8000325e <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003800:	0485                	addi	s1,s1,1
    80003802:	00ca2703          	lw	a4,12(s4)
    80003806:	0004879b          	sext.w	a5,s1
    8000380a:	fce7e1e3          	bltu	a5,a4,800037cc <ialloc+0x32>
  panic("ialloc: no inodes");
    8000380e:	00005517          	auipc	a0,0x5
    80003812:	dba50513          	addi	a0,a0,-582 # 800085c8 <syscalls+0x188>
    80003816:	ffffd097          	auipc	ra,0xffffd
    8000381a:	dba080e7          	jalr	-582(ra) # 800005d0 <panic>
      memset(dip, 0, sizeof(*dip));
    8000381e:	04000613          	li	a2,64
    80003822:	4581                	li	a1,0
    80003824:	854e                	mv	a0,s3
    80003826:	ffffd097          	auipc	ra,0xffffd
    8000382a:	538080e7          	jalr	1336(ra) # 80000d5e <memset>
      dip->type = type;
    8000382e:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003832:	854a                	mv	a0,s2
    80003834:	00001097          	auipc	ra,0x1
    80003838:	c94080e7          	jalr	-876(ra) # 800044c8 <log_write>
      brelse(bp);
    8000383c:	854a                	mv	a0,s2
    8000383e:	00000097          	auipc	ra,0x0
    80003842:	a20080e7          	jalr	-1504(ra) # 8000325e <brelse>
      return iget(dev, inum);
    80003846:	85da                	mv	a1,s6
    80003848:	8556                	mv	a0,s5
    8000384a:	00000097          	auipc	ra,0x0
    8000384e:	db4080e7          	jalr	-588(ra) # 800035fe <iget>
}
    80003852:	60a6                	ld	ra,72(sp)
    80003854:	6406                	ld	s0,64(sp)
    80003856:	74e2                	ld	s1,56(sp)
    80003858:	7942                	ld	s2,48(sp)
    8000385a:	79a2                	ld	s3,40(sp)
    8000385c:	7a02                	ld	s4,32(sp)
    8000385e:	6ae2                	ld	s5,24(sp)
    80003860:	6b42                	ld	s6,16(sp)
    80003862:	6ba2                	ld	s7,8(sp)
    80003864:	6161                	addi	sp,sp,80
    80003866:	8082                	ret

0000000080003868 <iupdate>:
{
    80003868:	1101                	addi	sp,sp,-32
    8000386a:	ec06                	sd	ra,24(sp)
    8000386c:	e822                	sd	s0,16(sp)
    8000386e:	e426                	sd	s1,8(sp)
    80003870:	e04a                	sd	s2,0(sp)
    80003872:	1000                	addi	s0,sp,32
    80003874:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003876:	415c                	lw	a5,4(a0)
    80003878:	0047d79b          	srliw	a5,a5,0x4
    8000387c:	00021597          	auipc	a1,0x21
    80003880:	ddc5a583          	lw	a1,-548(a1) # 80024658 <sb+0x18>
    80003884:	9dbd                	addw	a1,a1,a5
    80003886:	4108                	lw	a0,0(a0)
    80003888:	00000097          	auipc	ra,0x0
    8000388c:	8a6080e7          	jalr	-1882(ra) # 8000312e <bread>
    80003890:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003892:	05850793          	addi	a5,a0,88
    80003896:	40c8                	lw	a0,4(s1)
    80003898:	893d                	andi	a0,a0,15
    8000389a:	051a                	slli	a0,a0,0x6
    8000389c:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    8000389e:	04449703          	lh	a4,68(s1)
    800038a2:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800038a6:	04649703          	lh	a4,70(s1)
    800038aa:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800038ae:	04849703          	lh	a4,72(s1)
    800038b2:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800038b6:	04a49703          	lh	a4,74(s1)
    800038ba:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800038be:	44f8                	lw	a4,76(s1)
    800038c0:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800038c2:	03400613          	li	a2,52
    800038c6:	05048593          	addi	a1,s1,80
    800038ca:	0531                	addi	a0,a0,12
    800038cc:	ffffd097          	auipc	ra,0xffffd
    800038d0:	4ee080e7          	jalr	1262(ra) # 80000dba <memmove>
  log_write(bp);
    800038d4:	854a                	mv	a0,s2
    800038d6:	00001097          	auipc	ra,0x1
    800038da:	bf2080e7          	jalr	-1038(ra) # 800044c8 <log_write>
  brelse(bp);
    800038de:	854a                	mv	a0,s2
    800038e0:	00000097          	auipc	ra,0x0
    800038e4:	97e080e7          	jalr	-1666(ra) # 8000325e <brelse>
}
    800038e8:	60e2                	ld	ra,24(sp)
    800038ea:	6442                	ld	s0,16(sp)
    800038ec:	64a2                	ld	s1,8(sp)
    800038ee:	6902                	ld	s2,0(sp)
    800038f0:	6105                	addi	sp,sp,32
    800038f2:	8082                	ret

00000000800038f4 <idup>:
{
    800038f4:	1101                	addi	sp,sp,-32
    800038f6:	ec06                	sd	ra,24(sp)
    800038f8:	e822                	sd	s0,16(sp)
    800038fa:	e426                	sd	s1,8(sp)
    800038fc:	1000                	addi	s0,sp,32
    800038fe:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003900:	00021517          	auipc	a0,0x21
    80003904:	d6050513          	addi	a0,a0,-672 # 80024660 <icache>
    80003908:	ffffd097          	auipc	ra,0xffffd
    8000390c:	35a080e7          	jalr	858(ra) # 80000c62 <acquire>
  ip->ref++;
    80003910:	449c                	lw	a5,8(s1)
    80003912:	2785                	addiw	a5,a5,1
    80003914:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003916:	00021517          	auipc	a0,0x21
    8000391a:	d4a50513          	addi	a0,a0,-694 # 80024660 <icache>
    8000391e:	ffffd097          	auipc	ra,0xffffd
    80003922:	3f8080e7          	jalr	1016(ra) # 80000d16 <release>
}
    80003926:	8526                	mv	a0,s1
    80003928:	60e2                	ld	ra,24(sp)
    8000392a:	6442                	ld	s0,16(sp)
    8000392c:	64a2                	ld	s1,8(sp)
    8000392e:	6105                	addi	sp,sp,32
    80003930:	8082                	ret

0000000080003932 <ilock>:
{
    80003932:	1101                	addi	sp,sp,-32
    80003934:	ec06                	sd	ra,24(sp)
    80003936:	e822                	sd	s0,16(sp)
    80003938:	e426                	sd	s1,8(sp)
    8000393a:	e04a                	sd	s2,0(sp)
    8000393c:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    8000393e:	c115                	beqz	a0,80003962 <ilock+0x30>
    80003940:	84aa                	mv	s1,a0
    80003942:	451c                	lw	a5,8(a0)
    80003944:	00f05f63          	blez	a5,80003962 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003948:	0541                	addi	a0,a0,16
    8000394a:	00001097          	auipc	ra,0x1
    8000394e:	ca6080e7          	jalr	-858(ra) # 800045f0 <acquiresleep>
  if(ip->valid == 0){
    80003952:	40bc                	lw	a5,64(s1)
    80003954:	cf99                	beqz	a5,80003972 <ilock+0x40>
}
    80003956:	60e2                	ld	ra,24(sp)
    80003958:	6442                	ld	s0,16(sp)
    8000395a:	64a2                	ld	s1,8(sp)
    8000395c:	6902                	ld	s2,0(sp)
    8000395e:	6105                	addi	sp,sp,32
    80003960:	8082                	ret
    panic("ilock");
    80003962:	00005517          	auipc	a0,0x5
    80003966:	c7e50513          	addi	a0,a0,-898 # 800085e0 <syscalls+0x1a0>
    8000396a:	ffffd097          	auipc	ra,0xffffd
    8000396e:	c66080e7          	jalr	-922(ra) # 800005d0 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003972:	40dc                	lw	a5,4(s1)
    80003974:	0047d79b          	srliw	a5,a5,0x4
    80003978:	00021597          	auipc	a1,0x21
    8000397c:	ce05a583          	lw	a1,-800(a1) # 80024658 <sb+0x18>
    80003980:	9dbd                	addw	a1,a1,a5
    80003982:	4088                	lw	a0,0(s1)
    80003984:	fffff097          	auipc	ra,0xfffff
    80003988:	7aa080e7          	jalr	1962(ra) # 8000312e <bread>
    8000398c:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000398e:	05850593          	addi	a1,a0,88
    80003992:	40dc                	lw	a5,4(s1)
    80003994:	8bbd                	andi	a5,a5,15
    80003996:	079a                	slli	a5,a5,0x6
    80003998:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    8000399a:	00059783          	lh	a5,0(a1)
    8000399e:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800039a2:	00259783          	lh	a5,2(a1)
    800039a6:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800039aa:	00459783          	lh	a5,4(a1)
    800039ae:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800039b2:	00659783          	lh	a5,6(a1)
    800039b6:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800039ba:	459c                	lw	a5,8(a1)
    800039bc:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800039be:	03400613          	li	a2,52
    800039c2:	05b1                	addi	a1,a1,12
    800039c4:	05048513          	addi	a0,s1,80
    800039c8:	ffffd097          	auipc	ra,0xffffd
    800039cc:	3f2080e7          	jalr	1010(ra) # 80000dba <memmove>
    brelse(bp);
    800039d0:	854a                	mv	a0,s2
    800039d2:	00000097          	auipc	ra,0x0
    800039d6:	88c080e7          	jalr	-1908(ra) # 8000325e <brelse>
    ip->valid = 1;
    800039da:	4785                	li	a5,1
    800039dc:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800039de:	04449783          	lh	a5,68(s1)
    800039e2:	fbb5                	bnez	a5,80003956 <ilock+0x24>
      panic("ilock: no type");
    800039e4:	00005517          	auipc	a0,0x5
    800039e8:	c0450513          	addi	a0,a0,-1020 # 800085e8 <syscalls+0x1a8>
    800039ec:	ffffd097          	auipc	ra,0xffffd
    800039f0:	be4080e7          	jalr	-1052(ra) # 800005d0 <panic>

00000000800039f4 <iunlock>:
{
    800039f4:	1101                	addi	sp,sp,-32
    800039f6:	ec06                	sd	ra,24(sp)
    800039f8:	e822                	sd	s0,16(sp)
    800039fa:	e426                	sd	s1,8(sp)
    800039fc:	e04a                	sd	s2,0(sp)
    800039fe:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003a00:	c905                	beqz	a0,80003a30 <iunlock+0x3c>
    80003a02:	84aa                	mv	s1,a0
    80003a04:	01050913          	addi	s2,a0,16
    80003a08:	854a                	mv	a0,s2
    80003a0a:	00001097          	auipc	ra,0x1
    80003a0e:	c80080e7          	jalr	-896(ra) # 8000468a <holdingsleep>
    80003a12:	cd19                	beqz	a0,80003a30 <iunlock+0x3c>
    80003a14:	449c                	lw	a5,8(s1)
    80003a16:	00f05d63          	blez	a5,80003a30 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003a1a:	854a                	mv	a0,s2
    80003a1c:	00001097          	auipc	ra,0x1
    80003a20:	c2a080e7          	jalr	-982(ra) # 80004646 <releasesleep>
}
    80003a24:	60e2                	ld	ra,24(sp)
    80003a26:	6442                	ld	s0,16(sp)
    80003a28:	64a2                	ld	s1,8(sp)
    80003a2a:	6902                	ld	s2,0(sp)
    80003a2c:	6105                	addi	sp,sp,32
    80003a2e:	8082                	ret
    panic("iunlock");
    80003a30:	00005517          	auipc	a0,0x5
    80003a34:	bc850513          	addi	a0,a0,-1080 # 800085f8 <syscalls+0x1b8>
    80003a38:	ffffd097          	auipc	ra,0xffffd
    80003a3c:	b98080e7          	jalr	-1128(ra) # 800005d0 <panic>

0000000080003a40 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003a40:	7179                	addi	sp,sp,-48
    80003a42:	f406                	sd	ra,40(sp)
    80003a44:	f022                	sd	s0,32(sp)
    80003a46:	ec26                	sd	s1,24(sp)
    80003a48:	e84a                	sd	s2,16(sp)
    80003a4a:	e44e                	sd	s3,8(sp)
    80003a4c:	e052                	sd	s4,0(sp)
    80003a4e:	1800                	addi	s0,sp,48
    80003a50:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003a52:	05050493          	addi	s1,a0,80
    80003a56:	08050913          	addi	s2,a0,128
    80003a5a:	a021                	j	80003a62 <itrunc+0x22>
    80003a5c:	0491                	addi	s1,s1,4
    80003a5e:	01248d63          	beq	s1,s2,80003a78 <itrunc+0x38>
    if(ip->addrs[i]){
    80003a62:	408c                	lw	a1,0(s1)
    80003a64:	dde5                	beqz	a1,80003a5c <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003a66:	0009a503          	lw	a0,0(s3)
    80003a6a:	00000097          	auipc	ra,0x0
    80003a6e:	90a080e7          	jalr	-1782(ra) # 80003374 <bfree>
      ip->addrs[i] = 0;
    80003a72:	0004a023          	sw	zero,0(s1)
    80003a76:	b7dd                	j	80003a5c <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003a78:	0809a583          	lw	a1,128(s3)
    80003a7c:	e185                	bnez	a1,80003a9c <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003a7e:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003a82:	854e                	mv	a0,s3
    80003a84:	00000097          	auipc	ra,0x0
    80003a88:	de4080e7          	jalr	-540(ra) # 80003868 <iupdate>
}
    80003a8c:	70a2                	ld	ra,40(sp)
    80003a8e:	7402                	ld	s0,32(sp)
    80003a90:	64e2                	ld	s1,24(sp)
    80003a92:	6942                	ld	s2,16(sp)
    80003a94:	69a2                	ld	s3,8(sp)
    80003a96:	6a02                	ld	s4,0(sp)
    80003a98:	6145                	addi	sp,sp,48
    80003a9a:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003a9c:	0009a503          	lw	a0,0(s3)
    80003aa0:	fffff097          	auipc	ra,0xfffff
    80003aa4:	68e080e7          	jalr	1678(ra) # 8000312e <bread>
    80003aa8:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003aaa:	05850493          	addi	s1,a0,88
    80003aae:	45850913          	addi	s2,a0,1112
    80003ab2:	a021                	j	80003aba <itrunc+0x7a>
    80003ab4:	0491                	addi	s1,s1,4
    80003ab6:	01248b63          	beq	s1,s2,80003acc <itrunc+0x8c>
      if(a[j])
    80003aba:	408c                	lw	a1,0(s1)
    80003abc:	dde5                	beqz	a1,80003ab4 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003abe:	0009a503          	lw	a0,0(s3)
    80003ac2:	00000097          	auipc	ra,0x0
    80003ac6:	8b2080e7          	jalr	-1870(ra) # 80003374 <bfree>
    80003aca:	b7ed                	j	80003ab4 <itrunc+0x74>
    brelse(bp);
    80003acc:	8552                	mv	a0,s4
    80003ace:	fffff097          	auipc	ra,0xfffff
    80003ad2:	790080e7          	jalr	1936(ra) # 8000325e <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003ad6:	0809a583          	lw	a1,128(s3)
    80003ada:	0009a503          	lw	a0,0(s3)
    80003ade:	00000097          	auipc	ra,0x0
    80003ae2:	896080e7          	jalr	-1898(ra) # 80003374 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003ae6:	0809a023          	sw	zero,128(s3)
    80003aea:	bf51                	j	80003a7e <itrunc+0x3e>

0000000080003aec <iput>:
{
    80003aec:	1101                	addi	sp,sp,-32
    80003aee:	ec06                	sd	ra,24(sp)
    80003af0:	e822                	sd	s0,16(sp)
    80003af2:	e426                	sd	s1,8(sp)
    80003af4:	e04a                	sd	s2,0(sp)
    80003af6:	1000                	addi	s0,sp,32
    80003af8:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003afa:	00021517          	auipc	a0,0x21
    80003afe:	b6650513          	addi	a0,a0,-1178 # 80024660 <icache>
    80003b02:	ffffd097          	auipc	ra,0xffffd
    80003b06:	160080e7          	jalr	352(ra) # 80000c62 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b0a:	4498                	lw	a4,8(s1)
    80003b0c:	4785                	li	a5,1
    80003b0e:	02f70363          	beq	a4,a5,80003b34 <iput+0x48>
  ip->ref--;
    80003b12:	449c                	lw	a5,8(s1)
    80003b14:	37fd                	addiw	a5,a5,-1
    80003b16:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003b18:	00021517          	auipc	a0,0x21
    80003b1c:	b4850513          	addi	a0,a0,-1208 # 80024660 <icache>
    80003b20:	ffffd097          	auipc	ra,0xffffd
    80003b24:	1f6080e7          	jalr	502(ra) # 80000d16 <release>
}
    80003b28:	60e2                	ld	ra,24(sp)
    80003b2a:	6442                	ld	s0,16(sp)
    80003b2c:	64a2                	ld	s1,8(sp)
    80003b2e:	6902                	ld	s2,0(sp)
    80003b30:	6105                	addi	sp,sp,32
    80003b32:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b34:	40bc                	lw	a5,64(s1)
    80003b36:	dff1                	beqz	a5,80003b12 <iput+0x26>
    80003b38:	04a49783          	lh	a5,74(s1)
    80003b3c:	fbf9                	bnez	a5,80003b12 <iput+0x26>
    acquiresleep(&ip->lock);
    80003b3e:	01048913          	addi	s2,s1,16
    80003b42:	854a                	mv	a0,s2
    80003b44:	00001097          	auipc	ra,0x1
    80003b48:	aac080e7          	jalr	-1364(ra) # 800045f0 <acquiresleep>
    release(&icache.lock);
    80003b4c:	00021517          	auipc	a0,0x21
    80003b50:	b1450513          	addi	a0,a0,-1260 # 80024660 <icache>
    80003b54:	ffffd097          	auipc	ra,0xffffd
    80003b58:	1c2080e7          	jalr	450(ra) # 80000d16 <release>
    itrunc(ip);
    80003b5c:	8526                	mv	a0,s1
    80003b5e:	00000097          	auipc	ra,0x0
    80003b62:	ee2080e7          	jalr	-286(ra) # 80003a40 <itrunc>
    ip->type = 0;
    80003b66:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003b6a:	8526                	mv	a0,s1
    80003b6c:	00000097          	auipc	ra,0x0
    80003b70:	cfc080e7          	jalr	-772(ra) # 80003868 <iupdate>
    ip->valid = 0;
    80003b74:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003b78:	854a                	mv	a0,s2
    80003b7a:	00001097          	auipc	ra,0x1
    80003b7e:	acc080e7          	jalr	-1332(ra) # 80004646 <releasesleep>
    acquire(&icache.lock);
    80003b82:	00021517          	auipc	a0,0x21
    80003b86:	ade50513          	addi	a0,a0,-1314 # 80024660 <icache>
    80003b8a:	ffffd097          	auipc	ra,0xffffd
    80003b8e:	0d8080e7          	jalr	216(ra) # 80000c62 <acquire>
    80003b92:	b741                	j	80003b12 <iput+0x26>

0000000080003b94 <iunlockput>:
{
    80003b94:	1101                	addi	sp,sp,-32
    80003b96:	ec06                	sd	ra,24(sp)
    80003b98:	e822                	sd	s0,16(sp)
    80003b9a:	e426                	sd	s1,8(sp)
    80003b9c:	1000                	addi	s0,sp,32
    80003b9e:	84aa                	mv	s1,a0
  iunlock(ip);
    80003ba0:	00000097          	auipc	ra,0x0
    80003ba4:	e54080e7          	jalr	-428(ra) # 800039f4 <iunlock>
  iput(ip);
    80003ba8:	8526                	mv	a0,s1
    80003baa:	00000097          	auipc	ra,0x0
    80003bae:	f42080e7          	jalr	-190(ra) # 80003aec <iput>
}
    80003bb2:	60e2                	ld	ra,24(sp)
    80003bb4:	6442                	ld	s0,16(sp)
    80003bb6:	64a2                	ld	s1,8(sp)
    80003bb8:	6105                	addi	sp,sp,32
    80003bba:	8082                	ret

0000000080003bbc <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003bbc:	1141                	addi	sp,sp,-16
    80003bbe:	e422                	sd	s0,8(sp)
    80003bc0:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003bc2:	411c                	lw	a5,0(a0)
    80003bc4:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003bc6:	415c                	lw	a5,4(a0)
    80003bc8:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003bca:	04451783          	lh	a5,68(a0)
    80003bce:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003bd2:	04a51783          	lh	a5,74(a0)
    80003bd6:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003bda:	04c56783          	lwu	a5,76(a0)
    80003bde:	e99c                	sd	a5,16(a1)
}
    80003be0:	6422                	ld	s0,8(sp)
    80003be2:	0141                	addi	sp,sp,16
    80003be4:	8082                	ret

0000000080003be6 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003be6:	457c                	lw	a5,76(a0)
    80003be8:	0ed7e863          	bltu	a5,a3,80003cd8 <readi+0xf2>
{
    80003bec:	7159                	addi	sp,sp,-112
    80003bee:	f486                	sd	ra,104(sp)
    80003bf0:	f0a2                	sd	s0,96(sp)
    80003bf2:	eca6                	sd	s1,88(sp)
    80003bf4:	e8ca                	sd	s2,80(sp)
    80003bf6:	e4ce                	sd	s3,72(sp)
    80003bf8:	e0d2                	sd	s4,64(sp)
    80003bfa:	fc56                	sd	s5,56(sp)
    80003bfc:	f85a                	sd	s6,48(sp)
    80003bfe:	f45e                	sd	s7,40(sp)
    80003c00:	f062                	sd	s8,32(sp)
    80003c02:	ec66                	sd	s9,24(sp)
    80003c04:	e86a                	sd	s10,16(sp)
    80003c06:	e46e                	sd	s11,8(sp)
    80003c08:	1880                	addi	s0,sp,112
    80003c0a:	8baa                	mv	s7,a0
    80003c0c:	8c2e                	mv	s8,a1
    80003c0e:	8ab2                	mv	s5,a2
    80003c10:	84b6                	mv	s1,a3
    80003c12:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003c14:	9f35                	addw	a4,a4,a3
    return 0;
    80003c16:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003c18:	08d76f63          	bltu	a4,a3,80003cb6 <readi+0xd0>
  if(off + n > ip->size)
    80003c1c:	00e7f463          	bgeu	a5,a4,80003c24 <readi+0x3e>
    n = ip->size - off;
    80003c20:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c24:	0a0b0863          	beqz	s6,80003cd4 <readi+0xee>
    80003c28:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c2a:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003c2e:	5cfd                	li	s9,-1
    80003c30:	a82d                	j	80003c6a <readi+0x84>
    80003c32:	020a1d93          	slli	s11,s4,0x20
    80003c36:	020ddd93          	srli	s11,s11,0x20
    80003c3a:	05890793          	addi	a5,s2,88
    80003c3e:	86ee                	mv	a3,s11
    80003c40:	963e                	add	a2,a2,a5
    80003c42:	85d6                	mv	a1,s5
    80003c44:	8562                	mv	a0,s8
    80003c46:	fffff097          	auipc	ra,0xfffff
    80003c4a:	866080e7          	jalr	-1946(ra) # 800024ac <either_copyout>
    80003c4e:	05950d63          	beq	a0,s9,80003ca8 <readi+0xc2>
      brelse(bp);
      break;
    }
    brelse(bp);
    80003c52:	854a                	mv	a0,s2
    80003c54:	fffff097          	auipc	ra,0xfffff
    80003c58:	60a080e7          	jalr	1546(ra) # 8000325e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c5c:	013a09bb          	addw	s3,s4,s3
    80003c60:	009a04bb          	addw	s1,s4,s1
    80003c64:	9aee                	add	s5,s5,s11
    80003c66:	0569f663          	bgeu	s3,s6,80003cb2 <readi+0xcc>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003c6a:	000ba903          	lw	s2,0(s7)
    80003c6e:	00a4d59b          	srliw	a1,s1,0xa
    80003c72:	855e                	mv	a0,s7
    80003c74:	00000097          	auipc	ra,0x0
    80003c78:	8ae080e7          	jalr	-1874(ra) # 80003522 <bmap>
    80003c7c:	0005059b          	sext.w	a1,a0
    80003c80:	854a                	mv	a0,s2
    80003c82:	fffff097          	auipc	ra,0xfffff
    80003c86:	4ac080e7          	jalr	1196(ra) # 8000312e <bread>
    80003c8a:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c8c:	3ff4f613          	andi	a2,s1,1023
    80003c90:	40cd07bb          	subw	a5,s10,a2
    80003c94:	413b073b          	subw	a4,s6,s3
    80003c98:	8a3e                	mv	s4,a5
    80003c9a:	2781                	sext.w	a5,a5
    80003c9c:	0007069b          	sext.w	a3,a4
    80003ca0:	f8f6f9e3          	bgeu	a3,a5,80003c32 <readi+0x4c>
    80003ca4:	8a3a                	mv	s4,a4
    80003ca6:	b771                	j	80003c32 <readi+0x4c>
      brelse(bp);
    80003ca8:	854a                	mv	a0,s2
    80003caa:	fffff097          	auipc	ra,0xfffff
    80003cae:	5b4080e7          	jalr	1460(ra) # 8000325e <brelse>
  }
  return tot;
    80003cb2:	0009851b          	sext.w	a0,s3
}
    80003cb6:	70a6                	ld	ra,104(sp)
    80003cb8:	7406                	ld	s0,96(sp)
    80003cba:	64e6                	ld	s1,88(sp)
    80003cbc:	6946                	ld	s2,80(sp)
    80003cbe:	69a6                	ld	s3,72(sp)
    80003cc0:	6a06                	ld	s4,64(sp)
    80003cc2:	7ae2                	ld	s5,56(sp)
    80003cc4:	7b42                	ld	s6,48(sp)
    80003cc6:	7ba2                	ld	s7,40(sp)
    80003cc8:	7c02                	ld	s8,32(sp)
    80003cca:	6ce2                	ld	s9,24(sp)
    80003ccc:	6d42                	ld	s10,16(sp)
    80003cce:	6da2                	ld	s11,8(sp)
    80003cd0:	6165                	addi	sp,sp,112
    80003cd2:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003cd4:	89da                	mv	s3,s6
    80003cd6:	bff1                	j	80003cb2 <readi+0xcc>
    return 0;
    80003cd8:	4501                	li	a0,0
}
    80003cda:	8082                	ret

0000000080003cdc <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003cdc:	457c                	lw	a5,76(a0)
    80003cde:	10d7e663          	bltu	a5,a3,80003dea <writei+0x10e>
{
    80003ce2:	7159                	addi	sp,sp,-112
    80003ce4:	f486                	sd	ra,104(sp)
    80003ce6:	f0a2                	sd	s0,96(sp)
    80003ce8:	eca6                	sd	s1,88(sp)
    80003cea:	e8ca                	sd	s2,80(sp)
    80003cec:	e4ce                	sd	s3,72(sp)
    80003cee:	e0d2                	sd	s4,64(sp)
    80003cf0:	fc56                	sd	s5,56(sp)
    80003cf2:	f85a                	sd	s6,48(sp)
    80003cf4:	f45e                	sd	s7,40(sp)
    80003cf6:	f062                	sd	s8,32(sp)
    80003cf8:	ec66                	sd	s9,24(sp)
    80003cfa:	e86a                	sd	s10,16(sp)
    80003cfc:	e46e                	sd	s11,8(sp)
    80003cfe:	1880                	addi	s0,sp,112
    80003d00:	8baa                	mv	s7,a0
    80003d02:	8c2e                	mv	s8,a1
    80003d04:	8ab2                	mv	s5,a2
    80003d06:	8936                	mv	s2,a3
    80003d08:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003d0a:	00e687bb          	addw	a5,a3,a4
    80003d0e:	0ed7e063          	bltu	a5,a3,80003dee <writei+0x112>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003d12:	00043737          	lui	a4,0x43
    80003d16:	0cf76e63          	bltu	a4,a5,80003df2 <writei+0x116>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d1a:	0a0b0763          	beqz	s6,80003dc8 <writei+0xec>
    80003d1e:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d20:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003d24:	5cfd                	li	s9,-1
    80003d26:	a091                	j	80003d6a <writei+0x8e>
    80003d28:	02099d93          	slli	s11,s3,0x20
    80003d2c:	020ddd93          	srli	s11,s11,0x20
    80003d30:	05848793          	addi	a5,s1,88
    80003d34:	86ee                	mv	a3,s11
    80003d36:	8656                	mv	a2,s5
    80003d38:	85e2                	mv	a1,s8
    80003d3a:	953e                	add	a0,a0,a5
    80003d3c:	ffffe097          	auipc	ra,0xffffe
    80003d40:	7c6080e7          	jalr	1990(ra) # 80002502 <either_copyin>
    80003d44:	07950263          	beq	a0,s9,80003da8 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003d48:	8526                	mv	a0,s1
    80003d4a:	00000097          	auipc	ra,0x0
    80003d4e:	77e080e7          	jalr	1918(ra) # 800044c8 <log_write>
    brelse(bp);
    80003d52:	8526                	mv	a0,s1
    80003d54:	fffff097          	auipc	ra,0xfffff
    80003d58:	50a080e7          	jalr	1290(ra) # 8000325e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d5c:	01498a3b          	addw	s4,s3,s4
    80003d60:	0129893b          	addw	s2,s3,s2
    80003d64:	9aee                	add	s5,s5,s11
    80003d66:	056a7663          	bgeu	s4,s6,80003db2 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003d6a:	000ba483          	lw	s1,0(s7)
    80003d6e:	00a9559b          	srliw	a1,s2,0xa
    80003d72:	855e                	mv	a0,s7
    80003d74:	fffff097          	auipc	ra,0xfffff
    80003d78:	7ae080e7          	jalr	1966(ra) # 80003522 <bmap>
    80003d7c:	0005059b          	sext.w	a1,a0
    80003d80:	8526                	mv	a0,s1
    80003d82:	fffff097          	auipc	ra,0xfffff
    80003d86:	3ac080e7          	jalr	940(ra) # 8000312e <bread>
    80003d8a:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d8c:	3ff97513          	andi	a0,s2,1023
    80003d90:	40ad07bb          	subw	a5,s10,a0
    80003d94:	414b073b          	subw	a4,s6,s4
    80003d98:	89be                	mv	s3,a5
    80003d9a:	2781                	sext.w	a5,a5
    80003d9c:	0007069b          	sext.w	a3,a4
    80003da0:	f8f6f4e3          	bgeu	a3,a5,80003d28 <writei+0x4c>
    80003da4:	89ba                	mv	s3,a4
    80003da6:	b749                	j	80003d28 <writei+0x4c>
      brelse(bp);
    80003da8:	8526                	mv	a0,s1
    80003daa:	fffff097          	auipc	ra,0xfffff
    80003dae:	4b4080e7          	jalr	1204(ra) # 8000325e <brelse>
  }

  if(n > 0){
    if(off > ip->size)
    80003db2:	04cba783          	lw	a5,76(s7)
    80003db6:	0127f463          	bgeu	a5,s2,80003dbe <writei+0xe2>
      ip->size = off;
    80003dba:	052ba623          	sw	s2,76(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80003dbe:	855e                	mv	a0,s7
    80003dc0:	00000097          	auipc	ra,0x0
    80003dc4:	aa8080e7          	jalr	-1368(ra) # 80003868 <iupdate>
  }

  return n;
    80003dc8:	000b051b          	sext.w	a0,s6
}
    80003dcc:	70a6                	ld	ra,104(sp)
    80003dce:	7406                	ld	s0,96(sp)
    80003dd0:	64e6                	ld	s1,88(sp)
    80003dd2:	6946                	ld	s2,80(sp)
    80003dd4:	69a6                	ld	s3,72(sp)
    80003dd6:	6a06                	ld	s4,64(sp)
    80003dd8:	7ae2                	ld	s5,56(sp)
    80003dda:	7b42                	ld	s6,48(sp)
    80003ddc:	7ba2                	ld	s7,40(sp)
    80003dde:	7c02                	ld	s8,32(sp)
    80003de0:	6ce2                	ld	s9,24(sp)
    80003de2:	6d42                	ld	s10,16(sp)
    80003de4:	6da2                	ld	s11,8(sp)
    80003de6:	6165                	addi	sp,sp,112
    80003de8:	8082                	ret
    return -1;
    80003dea:	557d                	li	a0,-1
}
    80003dec:	8082                	ret
    return -1;
    80003dee:	557d                	li	a0,-1
    80003df0:	bff1                	j	80003dcc <writei+0xf0>
    return -1;
    80003df2:	557d                	li	a0,-1
    80003df4:	bfe1                	j	80003dcc <writei+0xf0>

0000000080003df6 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003df6:	1141                	addi	sp,sp,-16
    80003df8:	e406                	sd	ra,8(sp)
    80003dfa:	e022                	sd	s0,0(sp)
    80003dfc:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003dfe:	4639                	li	a2,14
    80003e00:	ffffd097          	auipc	ra,0xffffd
    80003e04:	036080e7          	jalr	54(ra) # 80000e36 <strncmp>
}
    80003e08:	60a2                	ld	ra,8(sp)
    80003e0a:	6402                	ld	s0,0(sp)
    80003e0c:	0141                	addi	sp,sp,16
    80003e0e:	8082                	ret

0000000080003e10 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003e10:	7139                	addi	sp,sp,-64
    80003e12:	fc06                	sd	ra,56(sp)
    80003e14:	f822                	sd	s0,48(sp)
    80003e16:	f426                	sd	s1,40(sp)
    80003e18:	f04a                	sd	s2,32(sp)
    80003e1a:	ec4e                	sd	s3,24(sp)
    80003e1c:	e852                	sd	s4,16(sp)
    80003e1e:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003e20:	04451703          	lh	a4,68(a0)
    80003e24:	4785                	li	a5,1
    80003e26:	00f71a63          	bne	a4,a5,80003e3a <dirlookup+0x2a>
    80003e2a:	892a                	mv	s2,a0
    80003e2c:	89ae                	mv	s3,a1
    80003e2e:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e30:	457c                	lw	a5,76(a0)
    80003e32:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003e34:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e36:	e79d                	bnez	a5,80003e64 <dirlookup+0x54>
    80003e38:	a8a5                	j	80003eb0 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003e3a:	00004517          	auipc	a0,0x4
    80003e3e:	7c650513          	addi	a0,a0,1990 # 80008600 <syscalls+0x1c0>
    80003e42:	ffffc097          	auipc	ra,0xffffc
    80003e46:	78e080e7          	jalr	1934(ra) # 800005d0 <panic>
      panic("dirlookup read");
    80003e4a:	00004517          	auipc	a0,0x4
    80003e4e:	7ce50513          	addi	a0,a0,1998 # 80008618 <syscalls+0x1d8>
    80003e52:	ffffc097          	auipc	ra,0xffffc
    80003e56:	77e080e7          	jalr	1918(ra) # 800005d0 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e5a:	24c1                	addiw	s1,s1,16
    80003e5c:	04c92783          	lw	a5,76(s2)
    80003e60:	04f4f763          	bgeu	s1,a5,80003eae <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e64:	4741                	li	a4,16
    80003e66:	86a6                	mv	a3,s1
    80003e68:	fc040613          	addi	a2,s0,-64
    80003e6c:	4581                	li	a1,0
    80003e6e:	854a                	mv	a0,s2
    80003e70:	00000097          	auipc	ra,0x0
    80003e74:	d76080e7          	jalr	-650(ra) # 80003be6 <readi>
    80003e78:	47c1                	li	a5,16
    80003e7a:	fcf518e3          	bne	a0,a5,80003e4a <dirlookup+0x3a>
    if(de.inum == 0)
    80003e7e:	fc045783          	lhu	a5,-64(s0)
    80003e82:	dfe1                	beqz	a5,80003e5a <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003e84:	fc240593          	addi	a1,s0,-62
    80003e88:	854e                	mv	a0,s3
    80003e8a:	00000097          	auipc	ra,0x0
    80003e8e:	f6c080e7          	jalr	-148(ra) # 80003df6 <namecmp>
    80003e92:	f561                	bnez	a0,80003e5a <dirlookup+0x4a>
      if(poff)
    80003e94:	000a0463          	beqz	s4,80003e9c <dirlookup+0x8c>
        *poff = off;
    80003e98:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003e9c:	fc045583          	lhu	a1,-64(s0)
    80003ea0:	00092503          	lw	a0,0(s2)
    80003ea4:	fffff097          	auipc	ra,0xfffff
    80003ea8:	75a080e7          	jalr	1882(ra) # 800035fe <iget>
    80003eac:	a011                	j	80003eb0 <dirlookup+0xa0>
  return 0;
    80003eae:	4501                	li	a0,0
}
    80003eb0:	70e2                	ld	ra,56(sp)
    80003eb2:	7442                	ld	s0,48(sp)
    80003eb4:	74a2                	ld	s1,40(sp)
    80003eb6:	7902                	ld	s2,32(sp)
    80003eb8:	69e2                	ld	s3,24(sp)
    80003eba:	6a42                	ld	s4,16(sp)
    80003ebc:	6121                	addi	sp,sp,64
    80003ebe:	8082                	ret

0000000080003ec0 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003ec0:	711d                	addi	sp,sp,-96
    80003ec2:	ec86                	sd	ra,88(sp)
    80003ec4:	e8a2                	sd	s0,80(sp)
    80003ec6:	e4a6                	sd	s1,72(sp)
    80003ec8:	e0ca                	sd	s2,64(sp)
    80003eca:	fc4e                	sd	s3,56(sp)
    80003ecc:	f852                	sd	s4,48(sp)
    80003ece:	f456                	sd	s5,40(sp)
    80003ed0:	f05a                	sd	s6,32(sp)
    80003ed2:	ec5e                	sd	s7,24(sp)
    80003ed4:	e862                	sd	s8,16(sp)
    80003ed6:	e466                	sd	s9,8(sp)
    80003ed8:	1080                	addi	s0,sp,96
    80003eda:	84aa                	mv	s1,a0
    80003edc:	8aae                	mv	s5,a1
    80003ede:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003ee0:	00054703          	lbu	a4,0(a0)
    80003ee4:	02f00793          	li	a5,47
    80003ee8:	02f70363          	beq	a4,a5,80003f0e <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003eec:	ffffe097          	auipc	ra,0xffffe
    80003ef0:	b42080e7          	jalr	-1214(ra) # 80001a2e <myproc>
    80003ef4:	15053503          	ld	a0,336(a0)
    80003ef8:	00000097          	auipc	ra,0x0
    80003efc:	9fc080e7          	jalr	-1540(ra) # 800038f4 <idup>
    80003f00:	89aa                	mv	s3,a0
  while(*path == '/')
    80003f02:	02f00913          	li	s2,47
  len = path - s;
    80003f06:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80003f08:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003f0a:	4b85                	li	s7,1
    80003f0c:	a865                	j	80003fc4 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003f0e:	4585                	li	a1,1
    80003f10:	4505                	li	a0,1
    80003f12:	fffff097          	auipc	ra,0xfffff
    80003f16:	6ec080e7          	jalr	1772(ra) # 800035fe <iget>
    80003f1a:	89aa                	mv	s3,a0
    80003f1c:	b7dd                	j	80003f02 <namex+0x42>
      iunlockput(ip);
    80003f1e:	854e                	mv	a0,s3
    80003f20:	00000097          	auipc	ra,0x0
    80003f24:	c74080e7          	jalr	-908(ra) # 80003b94 <iunlockput>
      return 0;
    80003f28:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003f2a:	854e                	mv	a0,s3
    80003f2c:	60e6                	ld	ra,88(sp)
    80003f2e:	6446                	ld	s0,80(sp)
    80003f30:	64a6                	ld	s1,72(sp)
    80003f32:	6906                	ld	s2,64(sp)
    80003f34:	79e2                	ld	s3,56(sp)
    80003f36:	7a42                	ld	s4,48(sp)
    80003f38:	7aa2                	ld	s5,40(sp)
    80003f3a:	7b02                	ld	s6,32(sp)
    80003f3c:	6be2                	ld	s7,24(sp)
    80003f3e:	6c42                	ld	s8,16(sp)
    80003f40:	6ca2                	ld	s9,8(sp)
    80003f42:	6125                	addi	sp,sp,96
    80003f44:	8082                	ret
      iunlock(ip);
    80003f46:	854e                	mv	a0,s3
    80003f48:	00000097          	auipc	ra,0x0
    80003f4c:	aac080e7          	jalr	-1364(ra) # 800039f4 <iunlock>
      return ip;
    80003f50:	bfe9                	j	80003f2a <namex+0x6a>
      iunlockput(ip);
    80003f52:	854e                	mv	a0,s3
    80003f54:	00000097          	auipc	ra,0x0
    80003f58:	c40080e7          	jalr	-960(ra) # 80003b94 <iunlockput>
      return 0;
    80003f5c:	89e6                	mv	s3,s9
    80003f5e:	b7f1                	j	80003f2a <namex+0x6a>
  len = path - s;
    80003f60:	40b48633          	sub	a2,s1,a1
    80003f64:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003f68:	099c5463          	bge	s8,s9,80003ff0 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003f6c:	4639                	li	a2,14
    80003f6e:	8552                	mv	a0,s4
    80003f70:	ffffd097          	auipc	ra,0xffffd
    80003f74:	e4a080e7          	jalr	-438(ra) # 80000dba <memmove>
  while(*path == '/')
    80003f78:	0004c783          	lbu	a5,0(s1)
    80003f7c:	01279763          	bne	a5,s2,80003f8a <namex+0xca>
    path++;
    80003f80:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003f82:	0004c783          	lbu	a5,0(s1)
    80003f86:	ff278de3          	beq	a5,s2,80003f80 <namex+0xc0>
    ilock(ip);
    80003f8a:	854e                	mv	a0,s3
    80003f8c:	00000097          	auipc	ra,0x0
    80003f90:	9a6080e7          	jalr	-1626(ra) # 80003932 <ilock>
    if(ip->type != T_DIR){
    80003f94:	04499783          	lh	a5,68(s3)
    80003f98:	f97793e3          	bne	a5,s7,80003f1e <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003f9c:	000a8563          	beqz	s5,80003fa6 <namex+0xe6>
    80003fa0:	0004c783          	lbu	a5,0(s1)
    80003fa4:	d3cd                	beqz	a5,80003f46 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003fa6:	865a                	mv	a2,s6
    80003fa8:	85d2                	mv	a1,s4
    80003faa:	854e                	mv	a0,s3
    80003fac:	00000097          	auipc	ra,0x0
    80003fb0:	e64080e7          	jalr	-412(ra) # 80003e10 <dirlookup>
    80003fb4:	8caa                	mv	s9,a0
    80003fb6:	dd51                	beqz	a0,80003f52 <namex+0x92>
    iunlockput(ip);
    80003fb8:	854e                	mv	a0,s3
    80003fba:	00000097          	auipc	ra,0x0
    80003fbe:	bda080e7          	jalr	-1062(ra) # 80003b94 <iunlockput>
    ip = next;
    80003fc2:	89e6                	mv	s3,s9
  while(*path == '/')
    80003fc4:	0004c783          	lbu	a5,0(s1)
    80003fc8:	05279763          	bne	a5,s2,80004016 <namex+0x156>
    path++;
    80003fcc:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003fce:	0004c783          	lbu	a5,0(s1)
    80003fd2:	ff278de3          	beq	a5,s2,80003fcc <namex+0x10c>
  if(*path == 0)
    80003fd6:	c79d                	beqz	a5,80004004 <namex+0x144>
    path++;
    80003fd8:	85a6                	mv	a1,s1
  len = path - s;
    80003fda:	8cda                	mv	s9,s6
    80003fdc:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80003fde:	01278963          	beq	a5,s2,80003ff0 <namex+0x130>
    80003fe2:	dfbd                	beqz	a5,80003f60 <namex+0xa0>
    path++;
    80003fe4:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003fe6:	0004c783          	lbu	a5,0(s1)
    80003fea:	ff279ce3          	bne	a5,s2,80003fe2 <namex+0x122>
    80003fee:	bf8d                	j	80003f60 <namex+0xa0>
    memmove(name, s, len);
    80003ff0:	2601                	sext.w	a2,a2
    80003ff2:	8552                	mv	a0,s4
    80003ff4:	ffffd097          	auipc	ra,0xffffd
    80003ff8:	dc6080e7          	jalr	-570(ra) # 80000dba <memmove>
    name[len] = 0;
    80003ffc:	9cd2                	add	s9,s9,s4
    80003ffe:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80004002:	bf9d                	j	80003f78 <namex+0xb8>
  if(nameiparent){
    80004004:	f20a83e3          	beqz	s5,80003f2a <namex+0x6a>
    iput(ip);
    80004008:	854e                	mv	a0,s3
    8000400a:	00000097          	auipc	ra,0x0
    8000400e:	ae2080e7          	jalr	-1310(ra) # 80003aec <iput>
    return 0;
    80004012:	4981                	li	s3,0
    80004014:	bf19                	j	80003f2a <namex+0x6a>
  if(*path == 0)
    80004016:	d7fd                	beqz	a5,80004004 <namex+0x144>
  while(*path != '/' && *path != 0)
    80004018:	0004c783          	lbu	a5,0(s1)
    8000401c:	85a6                	mv	a1,s1
    8000401e:	b7d1                	j	80003fe2 <namex+0x122>

0000000080004020 <dirlink>:
{
    80004020:	7139                	addi	sp,sp,-64
    80004022:	fc06                	sd	ra,56(sp)
    80004024:	f822                	sd	s0,48(sp)
    80004026:	f426                	sd	s1,40(sp)
    80004028:	f04a                	sd	s2,32(sp)
    8000402a:	ec4e                	sd	s3,24(sp)
    8000402c:	e852                	sd	s4,16(sp)
    8000402e:	0080                	addi	s0,sp,64
    80004030:	892a                	mv	s2,a0
    80004032:	8a2e                	mv	s4,a1
    80004034:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004036:	4601                	li	a2,0
    80004038:	00000097          	auipc	ra,0x0
    8000403c:	dd8080e7          	jalr	-552(ra) # 80003e10 <dirlookup>
    80004040:	e93d                	bnez	a0,800040b6 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004042:	04c92483          	lw	s1,76(s2)
    80004046:	c49d                	beqz	s1,80004074 <dirlink+0x54>
    80004048:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000404a:	4741                	li	a4,16
    8000404c:	86a6                	mv	a3,s1
    8000404e:	fc040613          	addi	a2,s0,-64
    80004052:	4581                	li	a1,0
    80004054:	854a                	mv	a0,s2
    80004056:	00000097          	auipc	ra,0x0
    8000405a:	b90080e7          	jalr	-1136(ra) # 80003be6 <readi>
    8000405e:	47c1                	li	a5,16
    80004060:	06f51163          	bne	a0,a5,800040c2 <dirlink+0xa2>
    if(de.inum == 0)
    80004064:	fc045783          	lhu	a5,-64(s0)
    80004068:	c791                	beqz	a5,80004074 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000406a:	24c1                	addiw	s1,s1,16
    8000406c:	04c92783          	lw	a5,76(s2)
    80004070:	fcf4ede3          	bltu	s1,a5,8000404a <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004074:	4639                	li	a2,14
    80004076:	85d2                	mv	a1,s4
    80004078:	fc240513          	addi	a0,s0,-62
    8000407c:	ffffd097          	auipc	ra,0xffffd
    80004080:	df6080e7          	jalr	-522(ra) # 80000e72 <strncpy>
  de.inum = inum;
    80004084:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004088:	4741                	li	a4,16
    8000408a:	86a6                	mv	a3,s1
    8000408c:	fc040613          	addi	a2,s0,-64
    80004090:	4581                	li	a1,0
    80004092:	854a                	mv	a0,s2
    80004094:	00000097          	auipc	ra,0x0
    80004098:	c48080e7          	jalr	-952(ra) # 80003cdc <writei>
    8000409c:	872a                	mv	a4,a0
    8000409e:	47c1                	li	a5,16
  return 0;
    800040a0:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040a2:	02f71863          	bne	a4,a5,800040d2 <dirlink+0xb2>
}
    800040a6:	70e2                	ld	ra,56(sp)
    800040a8:	7442                	ld	s0,48(sp)
    800040aa:	74a2                	ld	s1,40(sp)
    800040ac:	7902                	ld	s2,32(sp)
    800040ae:	69e2                	ld	s3,24(sp)
    800040b0:	6a42                	ld	s4,16(sp)
    800040b2:	6121                	addi	sp,sp,64
    800040b4:	8082                	ret
    iput(ip);
    800040b6:	00000097          	auipc	ra,0x0
    800040ba:	a36080e7          	jalr	-1482(ra) # 80003aec <iput>
    return -1;
    800040be:	557d                	li	a0,-1
    800040c0:	b7dd                	j	800040a6 <dirlink+0x86>
      panic("dirlink read");
    800040c2:	00004517          	auipc	a0,0x4
    800040c6:	56650513          	addi	a0,a0,1382 # 80008628 <syscalls+0x1e8>
    800040ca:	ffffc097          	auipc	ra,0xffffc
    800040ce:	506080e7          	jalr	1286(ra) # 800005d0 <panic>
    panic("dirlink");
    800040d2:	00004517          	auipc	a0,0x4
    800040d6:	67650513          	addi	a0,a0,1654 # 80008748 <syscalls+0x308>
    800040da:	ffffc097          	auipc	ra,0xffffc
    800040de:	4f6080e7          	jalr	1270(ra) # 800005d0 <panic>

00000000800040e2 <namei>:

struct inode*
namei(char *path)
{
    800040e2:	1101                	addi	sp,sp,-32
    800040e4:	ec06                	sd	ra,24(sp)
    800040e6:	e822                	sd	s0,16(sp)
    800040e8:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800040ea:	fe040613          	addi	a2,s0,-32
    800040ee:	4581                	li	a1,0
    800040f0:	00000097          	auipc	ra,0x0
    800040f4:	dd0080e7          	jalr	-560(ra) # 80003ec0 <namex>
}
    800040f8:	60e2                	ld	ra,24(sp)
    800040fa:	6442                	ld	s0,16(sp)
    800040fc:	6105                	addi	sp,sp,32
    800040fe:	8082                	ret

0000000080004100 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004100:	1141                	addi	sp,sp,-16
    80004102:	e406                	sd	ra,8(sp)
    80004104:	e022                	sd	s0,0(sp)
    80004106:	0800                	addi	s0,sp,16
    80004108:	862e                	mv	a2,a1
  return namex(path, 1, name);
    8000410a:	4585                	li	a1,1
    8000410c:	00000097          	auipc	ra,0x0
    80004110:	db4080e7          	jalr	-588(ra) # 80003ec0 <namex>
}
    80004114:	60a2                	ld	ra,8(sp)
    80004116:	6402                	ld	s0,0(sp)
    80004118:	0141                	addi	sp,sp,16
    8000411a:	8082                	ret

000000008000411c <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    8000411c:	1101                	addi	sp,sp,-32
    8000411e:	ec06                	sd	ra,24(sp)
    80004120:	e822                	sd	s0,16(sp)
    80004122:	e426                	sd	s1,8(sp)
    80004124:	e04a                	sd	s2,0(sp)
    80004126:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004128:	00022917          	auipc	s2,0x22
    8000412c:	fe090913          	addi	s2,s2,-32 # 80026108 <log>
    80004130:	01892583          	lw	a1,24(s2)
    80004134:	02892503          	lw	a0,40(s2)
    80004138:	fffff097          	auipc	ra,0xfffff
    8000413c:	ff6080e7          	jalr	-10(ra) # 8000312e <bread>
    80004140:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004142:	02c92683          	lw	a3,44(s2)
    80004146:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004148:	02d05863          	blez	a3,80004178 <write_head+0x5c>
    8000414c:	00022797          	auipc	a5,0x22
    80004150:	fec78793          	addi	a5,a5,-20 # 80026138 <log+0x30>
    80004154:	05c50713          	addi	a4,a0,92
    80004158:	36fd                	addiw	a3,a3,-1
    8000415a:	02069613          	slli	a2,a3,0x20
    8000415e:	01e65693          	srli	a3,a2,0x1e
    80004162:	00022617          	auipc	a2,0x22
    80004166:	fda60613          	addi	a2,a2,-38 # 8002613c <log+0x34>
    8000416a:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    8000416c:	4390                	lw	a2,0(a5)
    8000416e:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004170:	0791                	addi	a5,a5,4
    80004172:	0711                	addi	a4,a4,4
    80004174:	fed79ce3          	bne	a5,a3,8000416c <write_head+0x50>
  }
  bwrite(buf);
    80004178:	8526                	mv	a0,s1
    8000417a:	fffff097          	auipc	ra,0xfffff
    8000417e:	0a6080e7          	jalr	166(ra) # 80003220 <bwrite>
  brelse(buf);
    80004182:	8526                	mv	a0,s1
    80004184:	fffff097          	auipc	ra,0xfffff
    80004188:	0da080e7          	jalr	218(ra) # 8000325e <brelse>
}
    8000418c:	60e2                	ld	ra,24(sp)
    8000418e:	6442                	ld	s0,16(sp)
    80004190:	64a2                	ld	s1,8(sp)
    80004192:	6902                	ld	s2,0(sp)
    80004194:	6105                	addi	sp,sp,32
    80004196:	8082                	ret

0000000080004198 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004198:	00022797          	auipc	a5,0x22
    8000419c:	f9c7a783          	lw	a5,-100(a5) # 80026134 <log+0x2c>
    800041a0:	0af05663          	blez	a5,8000424c <install_trans+0xb4>
{
    800041a4:	7139                	addi	sp,sp,-64
    800041a6:	fc06                	sd	ra,56(sp)
    800041a8:	f822                	sd	s0,48(sp)
    800041aa:	f426                	sd	s1,40(sp)
    800041ac:	f04a                	sd	s2,32(sp)
    800041ae:	ec4e                	sd	s3,24(sp)
    800041b0:	e852                	sd	s4,16(sp)
    800041b2:	e456                	sd	s5,8(sp)
    800041b4:	0080                	addi	s0,sp,64
    800041b6:	00022a97          	auipc	s5,0x22
    800041ba:	f82a8a93          	addi	s5,s5,-126 # 80026138 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800041be:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800041c0:	00022997          	auipc	s3,0x22
    800041c4:	f4898993          	addi	s3,s3,-184 # 80026108 <log>
    800041c8:	0189a583          	lw	a1,24(s3)
    800041cc:	014585bb          	addw	a1,a1,s4
    800041d0:	2585                	addiw	a1,a1,1
    800041d2:	0289a503          	lw	a0,40(s3)
    800041d6:	fffff097          	auipc	ra,0xfffff
    800041da:	f58080e7          	jalr	-168(ra) # 8000312e <bread>
    800041de:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800041e0:	000aa583          	lw	a1,0(s5)
    800041e4:	0289a503          	lw	a0,40(s3)
    800041e8:	fffff097          	auipc	ra,0xfffff
    800041ec:	f46080e7          	jalr	-186(ra) # 8000312e <bread>
    800041f0:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800041f2:	40000613          	li	a2,1024
    800041f6:	05890593          	addi	a1,s2,88
    800041fa:	05850513          	addi	a0,a0,88
    800041fe:	ffffd097          	auipc	ra,0xffffd
    80004202:	bbc080e7          	jalr	-1092(ra) # 80000dba <memmove>
    bwrite(dbuf);  // write dst to disk
    80004206:	8526                	mv	a0,s1
    80004208:	fffff097          	auipc	ra,0xfffff
    8000420c:	018080e7          	jalr	24(ra) # 80003220 <bwrite>
    bunpin(dbuf);
    80004210:	8526                	mv	a0,s1
    80004212:	fffff097          	auipc	ra,0xfffff
    80004216:	126080e7          	jalr	294(ra) # 80003338 <bunpin>
    brelse(lbuf);
    8000421a:	854a                	mv	a0,s2
    8000421c:	fffff097          	auipc	ra,0xfffff
    80004220:	042080e7          	jalr	66(ra) # 8000325e <brelse>
    brelse(dbuf);
    80004224:	8526                	mv	a0,s1
    80004226:	fffff097          	auipc	ra,0xfffff
    8000422a:	038080e7          	jalr	56(ra) # 8000325e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000422e:	2a05                	addiw	s4,s4,1
    80004230:	0a91                	addi	s5,s5,4
    80004232:	02c9a783          	lw	a5,44(s3)
    80004236:	f8fa49e3          	blt	s4,a5,800041c8 <install_trans+0x30>
}
    8000423a:	70e2                	ld	ra,56(sp)
    8000423c:	7442                	ld	s0,48(sp)
    8000423e:	74a2                	ld	s1,40(sp)
    80004240:	7902                	ld	s2,32(sp)
    80004242:	69e2                	ld	s3,24(sp)
    80004244:	6a42                	ld	s4,16(sp)
    80004246:	6aa2                	ld	s5,8(sp)
    80004248:	6121                	addi	sp,sp,64
    8000424a:	8082                	ret
    8000424c:	8082                	ret

000000008000424e <initlog>:
{
    8000424e:	7179                	addi	sp,sp,-48
    80004250:	f406                	sd	ra,40(sp)
    80004252:	f022                	sd	s0,32(sp)
    80004254:	ec26                	sd	s1,24(sp)
    80004256:	e84a                	sd	s2,16(sp)
    80004258:	e44e                	sd	s3,8(sp)
    8000425a:	1800                	addi	s0,sp,48
    8000425c:	892a                	mv	s2,a0
    8000425e:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004260:	00022497          	auipc	s1,0x22
    80004264:	ea848493          	addi	s1,s1,-344 # 80026108 <log>
    80004268:	00004597          	auipc	a1,0x4
    8000426c:	3d058593          	addi	a1,a1,976 # 80008638 <syscalls+0x1f8>
    80004270:	8526                	mv	a0,s1
    80004272:	ffffd097          	auipc	ra,0xffffd
    80004276:	960080e7          	jalr	-1696(ra) # 80000bd2 <initlock>
  log.start = sb->logstart;
    8000427a:	0149a583          	lw	a1,20(s3)
    8000427e:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004280:	0109a783          	lw	a5,16(s3)
    80004284:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004286:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000428a:	854a                	mv	a0,s2
    8000428c:	fffff097          	auipc	ra,0xfffff
    80004290:	ea2080e7          	jalr	-350(ra) # 8000312e <bread>
  log.lh.n = lh->n;
    80004294:	4d34                	lw	a3,88(a0)
    80004296:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004298:	02d05663          	blez	a3,800042c4 <initlog+0x76>
    8000429c:	05c50793          	addi	a5,a0,92
    800042a0:	00022717          	auipc	a4,0x22
    800042a4:	e9870713          	addi	a4,a4,-360 # 80026138 <log+0x30>
    800042a8:	36fd                	addiw	a3,a3,-1
    800042aa:	02069613          	slli	a2,a3,0x20
    800042ae:	01e65693          	srli	a3,a2,0x1e
    800042b2:	06050613          	addi	a2,a0,96
    800042b6:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    800042b8:	4390                	lw	a2,0(a5)
    800042ba:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800042bc:	0791                	addi	a5,a5,4
    800042be:	0711                	addi	a4,a4,4
    800042c0:	fed79ce3          	bne	a5,a3,800042b8 <initlog+0x6a>
  brelse(buf);
    800042c4:	fffff097          	auipc	ra,0xfffff
    800042c8:	f9a080e7          	jalr	-102(ra) # 8000325e <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(); // if committed, copy from log to disk
    800042cc:	00000097          	auipc	ra,0x0
    800042d0:	ecc080e7          	jalr	-308(ra) # 80004198 <install_trans>
  log.lh.n = 0;
    800042d4:	00022797          	auipc	a5,0x22
    800042d8:	e607a023          	sw	zero,-416(a5) # 80026134 <log+0x2c>
  write_head(); // clear the log
    800042dc:	00000097          	auipc	ra,0x0
    800042e0:	e40080e7          	jalr	-448(ra) # 8000411c <write_head>
}
    800042e4:	70a2                	ld	ra,40(sp)
    800042e6:	7402                	ld	s0,32(sp)
    800042e8:	64e2                	ld	s1,24(sp)
    800042ea:	6942                	ld	s2,16(sp)
    800042ec:	69a2                	ld	s3,8(sp)
    800042ee:	6145                	addi	sp,sp,48
    800042f0:	8082                	ret

00000000800042f2 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800042f2:	1101                	addi	sp,sp,-32
    800042f4:	ec06                	sd	ra,24(sp)
    800042f6:	e822                	sd	s0,16(sp)
    800042f8:	e426                	sd	s1,8(sp)
    800042fa:	e04a                	sd	s2,0(sp)
    800042fc:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800042fe:	00022517          	auipc	a0,0x22
    80004302:	e0a50513          	addi	a0,a0,-502 # 80026108 <log>
    80004306:	ffffd097          	auipc	ra,0xffffd
    8000430a:	95c080e7          	jalr	-1700(ra) # 80000c62 <acquire>
  while(1){
    if(log.committing){
    8000430e:	00022497          	auipc	s1,0x22
    80004312:	dfa48493          	addi	s1,s1,-518 # 80026108 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004316:	4979                	li	s2,30
    80004318:	a039                	j	80004326 <begin_op+0x34>
      sleep(&log, &log.lock);
    8000431a:	85a6                	mv	a1,s1
    8000431c:	8526                	mv	a0,s1
    8000431e:	ffffe097          	auipc	ra,0xffffe
    80004322:	f34080e7          	jalr	-204(ra) # 80002252 <sleep>
    if(log.committing){
    80004326:	50dc                	lw	a5,36(s1)
    80004328:	fbed                	bnez	a5,8000431a <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000432a:	509c                	lw	a5,32(s1)
    8000432c:	0017871b          	addiw	a4,a5,1
    80004330:	0007069b          	sext.w	a3,a4
    80004334:	0027179b          	slliw	a5,a4,0x2
    80004338:	9fb9                	addw	a5,a5,a4
    8000433a:	0017979b          	slliw	a5,a5,0x1
    8000433e:	54d8                	lw	a4,44(s1)
    80004340:	9fb9                	addw	a5,a5,a4
    80004342:	00f95963          	bge	s2,a5,80004354 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004346:	85a6                	mv	a1,s1
    80004348:	8526                	mv	a0,s1
    8000434a:	ffffe097          	auipc	ra,0xffffe
    8000434e:	f08080e7          	jalr	-248(ra) # 80002252 <sleep>
    80004352:	bfd1                	j	80004326 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004354:	00022517          	auipc	a0,0x22
    80004358:	db450513          	addi	a0,a0,-588 # 80026108 <log>
    8000435c:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000435e:	ffffd097          	auipc	ra,0xffffd
    80004362:	9b8080e7          	jalr	-1608(ra) # 80000d16 <release>
      break;
    }
  }
}
    80004366:	60e2                	ld	ra,24(sp)
    80004368:	6442                	ld	s0,16(sp)
    8000436a:	64a2                	ld	s1,8(sp)
    8000436c:	6902                	ld	s2,0(sp)
    8000436e:	6105                	addi	sp,sp,32
    80004370:	8082                	ret

0000000080004372 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004372:	7139                	addi	sp,sp,-64
    80004374:	fc06                	sd	ra,56(sp)
    80004376:	f822                	sd	s0,48(sp)
    80004378:	f426                	sd	s1,40(sp)
    8000437a:	f04a                	sd	s2,32(sp)
    8000437c:	ec4e                	sd	s3,24(sp)
    8000437e:	e852                	sd	s4,16(sp)
    80004380:	e456                	sd	s5,8(sp)
    80004382:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004384:	00022497          	auipc	s1,0x22
    80004388:	d8448493          	addi	s1,s1,-636 # 80026108 <log>
    8000438c:	8526                	mv	a0,s1
    8000438e:	ffffd097          	auipc	ra,0xffffd
    80004392:	8d4080e7          	jalr	-1836(ra) # 80000c62 <acquire>
  log.outstanding -= 1;
    80004396:	509c                	lw	a5,32(s1)
    80004398:	37fd                	addiw	a5,a5,-1
    8000439a:	0007891b          	sext.w	s2,a5
    8000439e:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800043a0:	50dc                	lw	a5,36(s1)
    800043a2:	e7b9                	bnez	a5,800043f0 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    800043a4:	04091e63          	bnez	s2,80004400 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    800043a8:	00022497          	auipc	s1,0x22
    800043ac:	d6048493          	addi	s1,s1,-672 # 80026108 <log>
    800043b0:	4785                	li	a5,1
    800043b2:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800043b4:	8526                	mv	a0,s1
    800043b6:	ffffd097          	auipc	ra,0xffffd
    800043ba:	960080e7          	jalr	-1696(ra) # 80000d16 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800043be:	54dc                	lw	a5,44(s1)
    800043c0:	06f04763          	bgtz	a5,8000442e <end_op+0xbc>
    acquire(&log.lock);
    800043c4:	00022497          	auipc	s1,0x22
    800043c8:	d4448493          	addi	s1,s1,-700 # 80026108 <log>
    800043cc:	8526                	mv	a0,s1
    800043ce:	ffffd097          	auipc	ra,0xffffd
    800043d2:	894080e7          	jalr	-1900(ra) # 80000c62 <acquire>
    log.committing = 0;
    800043d6:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800043da:	8526                	mv	a0,s1
    800043dc:	ffffe097          	auipc	ra,0xffffe
    800043e0:	ff6080e7          	jalr	-10(ra) # 800023d2 <wakeup>
    release(&log.lock);
    800043e4:	8526                	mv	a0,s1
    800043e6:	ffffd097          	auipc	ra,0xffffd
    800043ea:	930080e7          	jalr	-1744(ra) # 80000d16 <release>
}
    800043ee:	a03d                	j	8000441c <end_op+0xaa>
    panic("log.committing");
    800043f0:	00004517          	auipc	a0,0x4
    800043f4:	25050513          	addi	a0,a0,592 # 80008640 <syscalls+0x200>
    800043f8:	ffffc097          	auipc	ra,0xffffc
    800043fc:	1d8080e7          	jalr	472(ra) # 800005d0 <panic>
    wakeup(&log);
    80004400:	00022497          	auipc	s1,0x22
    80004404:	d0848493          	addi	s1,s1,-760 # 80026108 <log>
    80004408:	8526                	mv	a0,s1
    8000440a:	ffffe097          	auipc	ra,0xffffe
    8000440e:	fc8080e7          	jalr	-56(ra) # 800023d2 <wakeup>
  release(&log.lock);
    80004412:	8526                	mv	a0,s1
    80004414:	ffffd097          	auipc	ra,0xffffd
    80004418:	902080e7          	jalr	-1790(ra) # 80000d16 <release>
}
    8000441c:	70e2                	ld	ra,56(sp)
    8000441e:	7442                	ld	s0,48(sp)
    80004420:	74a2                	ld	s1,40(sp)
    80004422:	7902                	ld	s2,32(sp)
    80004424:	69e2                	ld	s3,24(sp)
    80004426:	6a42                	ld	s4,16(sp)
    80004428:	6aa2                	ld	s5,8(sp)
    8000442a:	6121                	addi	sp,sp,64
    8000442c:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    8000442e:	00022a97          	auipc	s5,0x22
    80004432:	d0aa8a93          	addi	s5,s5,-758 # 80026138 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004436:	00022a17          	auipc	s4,0x22
    8000443a:	cd2a0a13          	addi	s4,s4,-814 # 80026108 <log>
    8000443e:	018a2583          	lw	a1,24(s4)
    80004442:	012585bb          	addw	a1,a1,s2
    80004446:	2585                	addiw	a1,a1,1
    80004448:	028a2503          	lw	a0,40(s4)
    8000444c:	fffff097          	auipc	ra,0xfffff
    80004450:	ce2080e7          	jalr	-798(ra) # 8000312e <bread>
    80004454:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004456:	000aa583          	lw	a1,0(s5)
    8000445a:	028a2503          	lw	a0,40(s4)
    8000445e:	fffff097          	auipc	ra,0xfffff
    80004462:	cd0080e7          	jalr	-816(ra) # 8000312e <bread>
    80004466:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004468:	40000613          	li	a2,1024
    8000446c:	05850593          	addi	a1,a0,88
    80004470:	05848513          	addi	a0,s1,88
    80004474:	ffffd097          	auipc	ra,0xffffd
    80004478:	946080e7          	jalr	-1722(ra) # 80000dba <memmove>
    bwrite(to);  // write the log
    8000447c:	8526                	mv	a0,s1
    8000447e:	fffff097          	auipc	ra,0xfffff
    80004482:	da2080e7          	jalr	-606(ra) # 80003220 <bwrite>
    brelse(from);
    80004486:	854e                	mv	a0,s3
    80004488:	fffff097          	auipc	ra,0xfffff
    8000448c:	dd6080e7          	jalr	-554(ra) # 8000325e <brelse>
    brelse(to);
    80004490:	8526                	mv	a0,s1
    80004492:	fffff097          	auipc	ra,0xfffff
    80004496:	dcc080e7          	jalr	-564(ra) # 8000325e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000449a:	2905                	addiw	s2,s2,1
    8000449c:	0a91                	addi	s5,s5,4
    8000449e:	02ca2783          	lw	a5,44(s4)
    800044a2:	f8f94ee3          	blt	s2,a5,8000443e <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800044a6:	00000097          	auipc	ra,0x0
    800044aa:	c76080e7          	jalr	-906(ra) # 8000411c <write_head>
    install_trans(); // Now install writes to home locations
    800044ae:	00000097          	auipc	ra,0x0
    800044b2:	cea080e7          	jalr	-790(ra) # 80004198 <install_trans>
    log.lh.n = 0;
    800044b6:	00022797          	auipc	a5,0x22
    800044ba:	c607af23          	sw	zero,-898(a5) # 80026134 <log+0x2c>
    write_head();    // Erase the transaction from the log
    800044be:	00000097          	auipc	ra,0x0
    800044c2:	c5e080e7          	jalr	-930(ra) # 8000411c <write_head>
    800044c6:	bdfd                	j	800043c4 <end_op+0x52>

00000000800044c8 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800044c8:	1101                	addi	sp,sp,-32
    800044ca:	ec06                	sd	ra,24(sp)
    800044cc:	e822                	sd	s0,16(sp)
    800044ce:	e426                	sd	s1,8(sp)
    800044d0:	e04a                	sd	s2,0(sp)
    800044d2:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800044d4:	00022717          	auipc	a4,0x22
    800044d8:	c6072703          	lw	a4,-928(a4) # 80026134 <log+0x2c>
    800044dc:	47f5                	li	a5,29
    800044de:	08e7c063          	blt	a5,a4,8000455e <log_write+0x96>
    800044e2:	84aa                	mv	s1,a0
    800044e4:	00022797          	auipc	a5,0x22
    800044e8:	c407a783          	lw	a5,-960(a5) # 80026124 <log+0x1c>
    800044ec:	37fd                	addiw	a5,a5,-1
    800044ee:	06f75863          	bge	a4,a5,8000455e <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800044f2:	00022797          	auipc	a5,0x22
    800044f6:	c367a783          	lw	a5,-970(a5) # 80026128 <log+0x20>
    800044fa:	06f05a63          	blez	a5,8000456e <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    800044fe:	00022917          	auipc	s2,0x22
    80004502:	c0a90913          	addi	s2,s2,-1014 # 80026108 <log>
    80004506:	854a                	mv	a0,s2
    80004508:	ffffc097          	auipc	ra,0xffffc
    8000450c:	75a080e7          	jalr	1882(ra) # 80000c62 <acquire>
  for (i = 0; i < log.lh.n; i++) {
    80004510:	02c92603          	lw	a2,44(s2)
    80004514:	06c05563          	blez	a2,8000457e <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004518:	44cc                	lw	a1,12(s1)
    8000451a:	00022717          	auipc	a4,0x22
    8000451e:	c1e70713          	addi	a4,a4,-994 # 80026138 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004522:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004524:	4314                	lw	a3,0(a4)
    80004526:	04b68d63          	beq	a3,a1,80004580 <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    8000452a:	2785                	addiw	a5,a5,1
    8000452c:	0711                	addi	a4,a4,4
    8000452e:	fec79be3          	bne	a5,a2,80004524 <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004532:	0621                	addi	a2,a2,8
    80004534:	060a                	slli	a2,a2,0x2
    80004536:	00022797          	auipc	a5,0x22
    8000453a:	bd278793          	addi	a5,a5,-1070 # 80026108 <log>
    8000453e:	963e                	add	a2,a2,a5
    80004540:	44dc                	lw	a5,12(s1)
    80004542:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004544:	8526                	mv	a0,s1
    80004546:	fffff097          	auipc	ra,0xfffff
    8000454a:	db6080e7          	jalr	-586(ra) # 800032fc <bpin>
    log.lh.n++;
    8000454e:	00022717          	auipc	a4,0x22
    80004552:	bba70713          	addi	a4,a4,-1094 # 80026108 <log>
    80004556:	575c                	lw	a5,44(a4)
    80004558:	2785                	addiw	a5,a5,1
    8000455a:	d75c                	sw	a5,44(a4)
    8000455c:	a83d                	j	8000459a <log_write+0xd2>
    panic("too big a transaction");
    8000455e:	00004517          	auipc	a0,0x4
    80004562:	0f250513          	addi	a0,a0,242 # 80008650 <syscalls+0x210>
    80004566:	ffffc097          	auipc	ra,0xffffc
    8000456a:	06a080e7          	jalr	106(ra) # 800005d0 <panic>
    panic("log_write outside of trans");
    8000456e:	00004517          	auipc	a0,0x4
    80004572:	0fa50513          	addi	a0,a0,250 # 80008668 <syscalls+0x228>
    80004576:	ffffc097          	auipc	ra,0xffffc
    8000457a:	05a080e7          	jalr	90(ra) # 800005d0 <panic>
  for (i = 0; i < log.lh.n; i++) {
    8000457e:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    80004580:	00878713          	addi	a4,a5,8
    80004584:	00271693          	slli	a3,a4,0x2
    80004588:	00022717          	auipc	a4,0x22
    8000458c:	b8070713          	addi	a4,a4,-1152 # 80026108 <log>
    80004590:	9736                	add	a4,a4,a3
    80004592:	44d4                	lw	a3,12(s1)
    80004594:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004596:	faf607e3          	beq	a2,a5,80004544 <log_write+0x7c>
  }
  release(&log.lock);
    8000459a:	00022517          	auipc	a0,0x22
    8000459e:	b6e50513          	addi	a0,a0,-1170 # 80026108 <log>
    800045a2:	ffffc097          	auipc	ra,0xffffc
    800045a6:	774080e7          	jalr	1908(ra) # 80000d16 <release>
}
    800045aa:	60e2                	ld	ra,24(sp)
    800045ac:	6442                	ld	s0,16(sp)
    800045ae:	64a2                	ld	s1,8(sp)
    800045b0:	6902                	ld	s2,0(sp)
    800045b2:	6105                	addi	sp,sp,32
    800045b4:	8082                	ret

00000000800045b6 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800045b6:	1101                	addi	sp,sp,-32
    800045b8:	ec06                	sd	ra,24(sp)
    800045ba:	e822                	sd	s0,16(sp)
    800045bc:	e426                	sd	s1,8(sp)
    800045be:	e04a                	sd	s2,0(sp)
    800045c0:	1000                	addi	s0,sp,32
    800045c2:	84aa                	mv	s1,a0
    800045c4:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800045c6:	00004597          	auipc	a1,0x4
    800045ca:	0c258593          	addi	a1,a1,194 # 80008688 <syscalls+0x248>
    800045ce:	0521                	addi	a0,a0,8
    800045d0:	ffffc097          	auipc	ra,0xffffc
    800045d4:	602080e7          	jalr	1538(ra) # 80000bd2 <initlock>
  lk->name = name;
    800045d8:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800045dc:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800045e0:	0204a423          	sw	zero,40(s1)
}
    800045e4:	60e2                	ld	ra,24(sp)
    800045e6:	6442                	ld	s0,16(sp)
    800045e8:	64a2                	ld	s1,8(sp)
    800045ea:	6902                	ld	s2,0(sp)
    800045ec:	6105                	addi	sp,sp,32
    800045ee:	8082                	ret

00000000800045f0 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800045f0:	1101                	addi	sp,sp,-32
    800045f2:	ec06                	sd	ra,24(sp)
    800045f4:	e822                	sd	s0,16(sp)
    800045f6:	e426                	sd	s1,8(sp)
    800045f8:	e04a                	sd	s2,0(sp)
    800045fa:	1000                	addi	s0,sp,32
    800045fc:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800045fe:	00850913          	addi	s2,a0,8
    80004602:	854a                	mv	a0,s2
    80004604:	ffffc097          	auipc	ra,0xffffc
    80004608:	65e080e7          	jalr	1630(ra) # 80000c62 <acquire>
  while (lk->locked) {
    8000460c:	409c                	lw	a5,0(s1)
    8000460e:	cb89                	beqz	a5,80004620 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004610:	85ca                	mv	a1,s2
    80004612:	8526                	mv	a0,s1
    80004614:	ffffe097          	auipc	ra,0xffffe
    80004618:	c3e080e7          	jalr	-962(ra) # 80002252 <sleep>
  while (lk->locked) {
    8000461c:	409c                	lw	a5,0(s1)
    8000461e:	fbed                	bnez	a5,80004610 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004620:	4785                	li	a5,1
    80004622:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004624:	ffffd097          	auipc	ra,0xffffd
    80004628:	40a080e7          	jalr	1034(ra) # 80001a2e <myproc>
    8000462c:	5d1c                	lw	a5,56(a0)
    8000462e:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004630:	854a                	mv	a0,s2
    80004632:	ffffc097          	auipc	ra,0xffffc
    80004636:	6e4080e7          	jalr	1764(ra) # 80000d16 <release>
}
    8000463a:	60e2                	ld	ra,24(sp)
    8000463c:	6442                	ld	s0,16(sp)
    8000463e:	64a2                	ld	s1,8(sp)
    80004640:	6902                	ld	s2,0(sp)
    80004642:	6105                	addi	sp,sp,32
    80004644:	8082                	ret

0000000080004646 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004646:	1101                	addi	sp,sp,-32
    80004648:	ec06                	sd	ra,24(sp)
    8000464a:	e822                	sd	s0,16(sp)
    8000464c:	e426                	sd	s1,8(sp)
    8000464e:	e04a                	sd	s2,0(sp)
    80004650:	1000                	addi	s0,sp,32
    80004652:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004654:	00850913          	addi	s2,a0,8
    80004658:	854a                	mv	a0,s2
    8000465a:	ffffc097          	auipc	ra,0xffffc
    8000465e:	608080e7          	jalr	1544(ra) # 80000c62 <acquire>
  lk->locked = 0;
    80004662:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004666:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000466a:	8526                	mv	a0,s1
    8000466c:	ffffe097          	auipc	ra,0xffffe
    80004670:	d66080e7          	jalr	-666(ra) # 800023d2 <wakeup>
  release(&lk->lk);
    80004674:	854a                	mv	a0,s2
    80004676:	ffffc097          	auipc	ra,0xffffc
    8000467a:	6a0080e7          	jalr	1696(ra) # 80000d16 <release>
}
    8000467e:	60e2                	ld	ra,24(sp)
    80004680:	6442                	ld	s0,16(sp)
    80004682:	64a2                	ld	s1,8(sp)
    80004684:	6902                	ld	s2,0(sp)
    80004686:	6105                	addi	sp,sp,32
    80004688:	8082                	ret

000000008000468a <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000468a:	7179                	addi	sp,sp,-48
    8000468c:	f406                	sd	ra,40(sp)
    8000468e:	f022                	sd	s0,32(sp)
    80004690:	ec26                	sd	s1,24(sp)
    80004692:	e84a                	sd	s2,16(sp)
    80004694:	e44e                	sd	s3,8(sp)
    80004696:	1800                	addi	s0,sp,48
    80004698:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000469a:	00850913          	addi	s2,a0,8
    8000469e:	854a                	mv	a0,s2
    800046a0:	ffffc097          	auipc	ra,0xffffc
    800046a4:	5c2080e7          	jalr	1474(ra) # 80000c62 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800046a8:	409c                	lw	a5,0(s1)
    800046aa:	ef99                	bnez	a5,800046c8 <holdingsleep+0x3e>
    800046ac:	4481                	li	s1,0
  release(&lk->lk);
    800046ae:	854a                	mv	a0,s2
    800046b0:	ffffc097          	auipc	ra,0xffffc
    800046b4:	666080e7          	jalr	1638(ra) # 80000d16 <release>
  return r;
}
    800046b8:	8526                	mv	a0,s1
    800046ba:	70a2                	ld	ra,40(sp)
    800046bc:	7402                	ld	s0,32(sp)
    800046be:	64e2                	ld	s1,24(sp)
    800046c0:	6942                	ld	s2,16(sp)
    800046c2:	69a2                	ld	s3,8(sp)
    800046c4:	6145                	addi	sp,sp,48
    800046c6:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800046c8:	0284a983          	lw	s3,40(s1)
    800046cc:	ffffd097          	auipc	ra,0xffffd
    800046d0:	362080e7          	jalr	866(ra) # 80001a2e <myproc>
    800046d4:	5d04                	lw	s1,56(a0)
    800046d6:	413484b3          	sub	s1,s1,s3
    800046da:	0014b493          	seqz	s1,s1
    800046de:	bfc1                	j	800046ae <holdingsleep+0x24>

00000000800046e0 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800046e0:	1141                	addi	sp,sp,-16
    800046e2:	e406                	sd	ra,8(sp)
    800046e4:	e022                	sd	s0,0(sp)
    800046e6:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800046e8:	00004597          	auipc	a1,0x4
    800046ec:	fb058593          	addi	a1,a1,-80 # 80008698 <syscalls+0x258>
    800046f0:	00022517          	auipc	a0,0x22
    800046f4:	b6050513          	addi	a0,a0,-1184 # 80026250 <ftable>
    800046f8:	ffffc097          	auipc	ra,0xffffc
    800046fc:	4da080e7          	jalr	1242(ra) # 80000bd2 <initlock>
}
    80004700:	60a2                	ld	ra,8(sp)
    80004702:	6402                	ld	s0,0(sp)
    80004704:	0141                	addi	sp,sp,16
    80004706:	8082                	ret

0000000080004708 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004708:	1101                	addi	sp,sp,-32
    8000470a:	ec06                	sd	ra,24(sp)
    8000470c:	e822                	sd	s0,16(sp)
    8000470e:	e426                	sd	s1,8(sp)
    80004710:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004712:	00022517          	auipc	a0,0x22
    80004716:	b3e50513          	addi	a0,a0,-1218 # 80026250 <ftable>
    8000471a:	ffffc097          	auipc	ra,0xffffc
    8000471e:	548080e7          	jalr	1352(ra) # 80000c62 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004722:	00022497          	auipc	s1,0x22
    80004726:	b4648493          	addi	s1,s1,-1210 # 80026268 <ftable+0x18>
    8000472a:	00023717          	auipc	a4,0x23
    8000472e:	ade70713          	addi	a4,a4,-1314 # 80027208 <ftable+0xfb8>
    if(f->ref == 0){
    80004732:	40dc                	lw	a5,4(s1)
    80004734:	cf99                	beqz	a5,80004752 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004736:	02848493          	addi	s1,s1,40
    8000473a:	fee49ce3          	bne	s1,a4,80004732 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000473e:	00022517          	auipc	a0,0x22
    80004742:	b1250513          	addi	a0,a0,-1262 # 80026250 <ftable>
    80004746:	ffffc097          	auipc	ra,0xffffc
    8000474a:	5d0080e7          	jalr	1488(ra) # 80000d16 <release>
  return 0;
    8000474e:	4481                	li	s1,0
    80004750:	a819                	j	80004766 <filealloc+0x5e>
      f->ref = 1;
    80004752:	4785                	li	a5,1
    80004754:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004756:	00022517          	auipc	a0,0x22
    8000475a:	afa50513          	addi	a0,a0,-1286 # 80026250 <ftable>
    8000475e:	ffffc097          	auipc	ra,0xffffc
    80004762:	5b8080e7          	jalr	1464(ra) # 80000d16 <release>
}
    80004766:	8526                	mv	a0,s1
    80004768:	60e2                	ld	ra,24(sp)
    8000476a:	6442                	ld	s0,16(sp)
    8000476c:	64a2                	ld	s1,8(sp)
    8000476e:	6105                	addi	sp,sp,32
    80004770:	8082                	ret

0000000080004772 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004772:	1101                	addi	sp,sp,-32
    80004774:	ec06                	sd	ra,24(sp)
    80004776:	e822                	sd	s0,16(sp)
    80004778:	e426                	sd	s1,8(sp)
    8000477a:	1000                	addi	s0,sp,32
    8000477c:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000477e:	00022517          	auipc	a0,0x22
    80004782:	ad250513          	addi	a0,a0,-1326 # 80026250 <ftable>
    80004786:	ffffc097          	auipc	ra,0xffffc
    8000478a:	4dc080e7          	jalr	1244(ra) # 80000c62 <acquire>
  if(f->ref < 1)
    8000478e:	40dc                	lw	a5,4(s1)
    80004790:	02f05263          	blez	a5,800047b4 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004794:	2785                	addiw	a5,a5,1
    80004796:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004798:	00022517          	auipc	a0,0x22
    8000479c:	ab850513          	addi	a0,a0,-1352 # 80026250 <ftable>
    800047a0:	ffffc097          	auipc	ra,0xffffc
    800047a4:	576080e7          	jalr	1398(ra) # 80000d16 <release>
  return f;
}
    800047a8:	8526                	mv	a0,s1
    800047aa:	60e2                	ld	ra,24(sp)
    800047ac:	6442                	ld	s0,16(sp)
    800047ae:	64a2                	ld	s1,8(sp)
    800047b0:	6105                	addi	sp,sp,32
    800047b2:	8082                	ret
    panic("filedup");
    800047b4:	00004517          	auipc	a0,0x4
    800047b8:	eec50513          	addi	a0,a0,-276 # 800086a0 <syscalls+0x260>
    800047bc:	ffffc097          	auipc	ra,0xffffc
    800047c0:	e14080e7          	jalr	-492(ra) # 800005d0 <panic>

00000000800047c4 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800047c4:	7139                	addi	sp,sp,-64
    800047c6:	fc06                	sd	ra,56(sp)
    800047c8:	f822                	sd	s0,48(sp)
    800047ca:	f426                	sd	s1,40(sp)
    800047cc:	f04a                	sd	s2,32(sp)
    800047ce:	ec4e                	sd	s3,24(sp)
    800047d0:	e852                	sd	s4,16(sp)
    800047d2:	e456                	sd	s5,8(sp)
    800047d4:	0080                	addi	s0,sp,64
    800047d6:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800047d8:	00022517          	auipc	a0,0x22
    800047dc:	a7850513          	addi	a0,a0,-1416 # 80026250 <ftable>
    800047e0:	ffffc097          	auipc	ra,0xffffc
    800047e4:	482080e7          	jalr	1154(ra) # 80000c62 <acquire>
  if(f->ref < 1)
    800047e8:	40dc                	lw	a5,4(s1)
    800047ea:	06f05163          	blez	a5,8000484c <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800047ee:	37fd                	addiw	a5,a5,-1
    800047f0:	0007871b          	sext.w	a4,a5
    800047f4:	c0dc                	sw	a5,4(s1)
    800047f6:	06e04363          	bgtz	a4,8000485c <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800047fa:	0004a903          	lw	s2,0(s1)
    800047fe:	0094ca83          	lbu	s5,9(s1)
    80004802:	0104ba03          	ld	s4,16(s1)
    80004806:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    8000480a:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    8000480e:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004812:	00022517          	auipc	a0,0x22
    80004816:	a3e50513          	addi	a0,a0,-1474 # 80026250 <ftable>
    8000481a:	ffffc097          	auipc	ra,0xffffc
    8000481e:	4fc080e7          	jalr	1276(ra) # 80000d16 <release>

  if(ff.type == FD_PIPE){
    80004822:	4785                	li	a5,1
    80004824:	04f90d63          	beq	s2,a5,8000487e <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004828:	3979                	addiw	s2,s2,-2
    8000482a:	4785                	li	a5,1
    8000482c:	0527e063          	bltu	a5,s2,8000486c <fileclose+0xa8>
    begin_op();
    80004830:	00000097          	auipc	ra,0x0
    80004834:	ac2080e7          	jalr	-1342(ra) # 800042f2 <begin_op>
    iput(ff.ip);
    80004838:	854e                	mv	a0,s3
    8000483a:	fffff097          	auipc	ra,0xfffff
    8000483e:	2b2080e7          	jalr	690(ra) # 80003aec <iput>
    end_op();
    80004842:	00000097          	auipc	ra,0x0
    80004846:	b30080e7          	jalr	-1232(ra) # 80004372 <end_op>
    8000484a:	a00d                	j	8000486c <fileclose+0xa8>
    panic("fileclose");
    8000484c:	00004517          	auipc	a0,0x4
    80004850:	e5c50513          	addi	a0,a0,-420 # 800086a8 <syscalls+0x268>
    80004854:	ffffc097          	auipc	ra,0xffffc
    80004858:	d7c080e7          	jalr	-644(ra) # 800005d0 <panic>
    release(&ftable.lock);
    8000485c:	00022517          	auipc	a0,0x22
    80004860:	9f450513          	addi	a0,a0,-1548 # 80026250 <ftable>
    80004864:	ffffc097          	auipc	ra,0xffffc
    80004868:	4b2080e7          	jalr	1202(ra) # 80000d16 <release>
  }
}
    8000486c:	70e2                	ld	ra,56(sp)
    8000486e:	7442                	ld	s0,48(sp)
    80004870:	74a2                	ld	s1,40(sp)
    80004872:	7902                	ld	s2,32(sp)
    80004874:	69e2                	ld	s3,24(sp)
    80004876:	6a42                	ld	s4,16(sp)
    80004878:	6aa2                	ld	s5,8(sp)
    8000487a:	6121                	addi	sp,sp,64
    8000487c:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000487e:	85d6                	mv	a1,s5
    80004880:	8552                	mv	a0,s4
    80004882:	00000097          	auipc	ra,0x0
    80004886:	372080e7          	jalr	882(ra) # 80004bf4 <pipeclose>
    8000488a:	b7cd                	j	8000486c <fileclose+0xa8>

000000008000488c <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    8000488c:	715d                	addi	sp,sp,-80
    8000488e:	e486                	sd	ra,72(sp)
    80004890:	e0a2                	sd	s0,64(sp)
    80004892:	fc26                	sd	s1,56(sp)
    80004894:	f84a                	sd	s2,48(sp)
    80004896:	f44e                	sd	s3,40(sp)
    80004898:	0880                	addi	s0,sp,80
    8000489a:	84aa                	mv	s1,a0
    8000489c:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    8000489e:	ffffd097          	auipc	ra,0xffffd
    800048a2:	190080e7          	jalr	400(ra) # 80001a2e <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800048a6:	409c                	lw	a5,0(s1)
    800048a8:	37f9                	addiw	a5,a5,-2
    800048aa:	4705                	li	a4,1
    800048ac:	04f76763          	bltu	a4,a5,800048fa <filestat+0x6e>
    800048b0:	892a                	mv	s2,a0
    ilock(f->ip);
    800048b2:	6c88                	ld	a0,24(s1)
    800048b4:	fffff097          	auipc	ra,0xfffff
    800048b8:	07e080e7          	jalr	126(ra) # 80003932 <ilock>
    stati(f->ip, &st);
    800048bc:	fb840593          	addi	a1,s0,-72
    800048c0:	6c88                	ld	a0,24(s1)
    800048c2:	fffff097          	auipc	ra,0xfffff
    800048c6:	2fa080e7          	jalr	762(ra) # 80003bbc <stati>
    iunlock(f->ip);
    800048ca:	6c88                	ld	a0,24(s1)
    800048cc:	fffff097          	auipc	ra,0xfffff
    800048d0:	128080e7          	jalr	296(ra) # 800039f4 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800048d4:	46e1                	li	a3,24
    800048d6:	fb840613          	addi	a2,s0,-72
    800048da:	85ce                	mv	a1,s3
    800048dc:	05093503          	ld	a0,80(s2)
    800048e0:	ffffd097          	auipc	ra,0xffffd
    800048e4:	e40080e7          	jalr	-448(ra) # 80001720 <copyout>
    800048e8:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800048ec:	60a6                	ld	ra,72(sp)
    800048ee:	6406                	ld	s0,64(sp)
    800048f0:	74e2                	ld	s1,56(sp)
    800048f2:	7942                	ld	s2,48(sp)
    800048f4:	79a2                	ld	s3,40(sp)
    800048f6:	6161                	addi	sp,sp,80
    800048f8:	8082                	ret
  return -1;
    800048fa:	557d                	li	a0,-1
    800048fc:	bfc5                	j	800048ec <filestat+0x60>

00000000800048fe <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800048fe:	7179                	addi	sp,sp,-48
    80004900:	f406                	sd	ra,40(sp)
    80004902:	f022                	sd	s0,32(sp)
    80004904:	ec26                	sd	s1,24(sp)
    80004906:	e84a                	sd	s2,16(sp)
    80004908:	e44e                	sd	s3,8(sp)
    8000490a:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000490c:	00854783          	lbu	a5,8(a0)
    80004910:	c3d5                	beqz	a5,800049b4 <fileread+0xb6>
    80004912:	84aa                	mv	s1,a0
    80004914:	89ae                	mv	s3,a1
    80004916:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004918:	411c                	lw	a5,0(a0)
    8000491a:	4705                	li	a4,1
    8000491c:	04e78963          	beq	a5,a4,8000496e <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004920:	470d                	li	a4,3
    80004922:	04e78d63          	beq	a5,a4,8000497c <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004926:	4709                	li	a4,2
    80004928:	06e79e63          	bne	a5,a4,800049a4 <fileread+0xa6>
    ilock(f->ip);
    8000492c:	6d08                	ld	a0,24(a0)
    8000492e:	fffff097          	auipc	ra,0xfffff
    80004932:	004080e7          	jalr	4(ra) # 80003932 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004936:	874a                	mv	a4,s2
    80004938:	5094                	lw	a3,32(s1)
    8000493a:	864e                	mv	a2,s3
    8000493c:	4585                	li	a1,1
    8000493e:	6c88                	ld	a0,24(s1)
    80004940:	fffff097          	auipc	ra,0xfffff
    80004944:	2a6080e7          	jalr	678(ra) # 80003be6 <readi>
    80004948:	892a                	mv	s2,a0
    8000494a:	00a05563          	blez	a0,80004954 <fileread+0x56>
      f->off += r;
    8000494e:	509c                	lw	a5,32(s1)
    80004950:	9fa9                	addw	a5,a5,a0
    80004952:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004954:	6c88                	ld	a0,24(s1)
    80004956:	fffff097          	auipc	ra,0xfffff
    8000495a:	09e080e7          	jalr	158(ra) # 800039f4 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    8000495e:	854a                	mv	a0,s2
    80004960:	70a2                	ld	ra,40(sp)
    80004962:	7402                	ld	s0,32(sp)
    80004964:	64e2                	ld	s1,24(sp)
    80004966:	6942                	ld	s2,16(sp)
    80004968:	69a2                	ld	s3,8(sp)
    8000496a:	6145                	addi	sp,sp,48
    8000496c:	8082                	ret
    r = piperead(f->pipe, addr, n);
    8000496e:	6908                	ld	a0,16(a0)
    80004970:	00000097          	auipc	ra,0x0
    80004974:	3f4080e7          	jalr	1012(ra) # 80004d64 <piperead>
    80004978:	892a                	mv	s2,a0
    8000497a:	b7d5                	j	8000495e <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    8000497c:	02451783          	lh	a5,36(a0)
    80004980:	03079693          	slli	a3,a5,0x30
    80004984:	92c1                	srli	a3,a3,0x30
    80004986:	4725                	li	a4,9
    80004988:	02d76863          	bltu	a4,a3,800049b8 <fileread+0xba>
    8000498c:	0792                	slli	a5,a5,0x4
    8000498e:	00022717          	auipc	a4,0x22
    80004992:	82270713          	addi	a4,a4,-2014 # 800261b0 <devsw>
    80004996:	97ba                	add	a5,a5,a4
    80004998:	639c                	ld	a5,0(a5)
    8000499a:	c38d                	beqz	a5,800049bc <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    8000499c:	4505                	li	a0,1
    8000499e:	9782                	jalr	a5
    800049a0:	892a                	mv	s2,a0
    800049a2:	bf75                	j	8000495e <fileread+0x60>
    panic("fileread");
    800049a4:	00004517          	auipc	a0,0x4
    800049a8:	d1450513          	addi	a0,a0,-748 # 800086b8 <syscalls+0x278>
    800049ac:	ffffc097          	auipc	ra,0xffffc
    800049b0:	c24080e7          	jalr	-988(ra) # 800005d0 <panic>
    return -1;
    800049b4:	597d                	li	s2,-1
    800049b6:	b765                	j	8000495e <fileread+0x60>
      return -1;
    800049b8:	597d                	li	s2,-1
    800049ba:	b755                	j	8000495e <fileread+0x60>
    800049bc:	597d                	li	s2,-1
    800049be:	b745                	j	8000495e <fileread+0x60>

00000000800049c0 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    800049c0:	00954783          	lbu	a5,9(a0)
    800049c4:	14078563          	beqz	a5,80004b0e <filewrite+0x14e>
{
    800049c8:	715d                	addi	sp,sp,-80
    800049ca:	e486                	sd	ra,72(sp)
    800049cc:	e0a2                	sd	s0,64(sp)
    800049ce:	fc26                	sd	s1,56(sp)
    800049d0:	f84a                	sd	s2,48(sp)
    800049d2:	f44e                	sd	s3,40(sp)
    800049d4:	f052                	sd	s4,32(sp)
    800049d6:	ec56                	sd	s5,24(sp)
    800049d8:	e85a                	sd	s6,16(sp)
    800049da:	e45e                	sd	s7,8(sp)
    800049dc:	e062                	sd	s8,0(sp)
    800049de:	0880                	addi	s0,sp,80
    800049e0:	892a                	mv	s2,a0
    800049e2:	8aae                	mv	s5,a1
    800049e4:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800049e6:	411c                	lw	a5,0(a0)
    800049e8:	4705                	li	a4,1
    800049ea:	02e78263          	beq	a5,a4,80004a0e <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800049ee:	470d                	li	a4,3
    800049f0:	02e78563          	beq	a5,a4,80004a1a <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800049f4:	4709                	li	a4,2
    800049f6:	10e79463          	bne	a5,a4,80004afe <filewrite+0x13e>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800049fa:	0ec05e63          	blez	a2,80004af6 <filewrite+0x136>
    int i = 0;
    800049fe:	4981                	li	s3,0
    80004a00:	6b05                	lui	s6,0x1
    80004a02:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004a06:	6b85                	lui	s7,0x1
    80004a08:	c00b8b9b          	addiw	s7,s7,-1024
    80004a0c:	a851                	j	80004aa0 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80004a0e:	6908                	ld	a0,16(a0)
    80004a10:	00000097          	auipc	ra,0x0
    80004a14:	254080e7          	jalr	596(ra) # 80004c64 <pipewrite>
    80004a18:	a85d                	j	80004ace <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004a1a:	02451783          	lh	a5,36(a0)
    80004a1e:	03079693          	slli	a3,a5,0x30
    80004a22:	92c1                	srli	a3,a3,0x30
    80004a24:	4725                	li	a4,9
    80004a26:	0ed76663          	bltu	a4,a3,80004b12 <filewrite+0x152>
    80004a2a:	0792                	slli	a5,a5,0x4
    80004a2c:	00021717          	auipc	a4,0x21
    80004a30:	78470713          	addi	a4,a4,1924 # 800261b0 <devsw>
    80004a34:	97ba                	add	a5,a5,a4
    80004a36:	679c                	ld	a5,8(a5)
    80004a38:	cff9                	beqz	a5,80004b16 <filewrite+0x156>
    ret = devsw[f->major].write(1, addr, n);
    80004a3a:	4505                	li	a0,1
    80004a3c:	9782                	jalr	a5
    80004a3e:	a841                	j	80004ace <filewrite+0x10e>
    80004a40:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004a44:	00000097          	auipc	ra,0x0
    80004a48:	8ae080e7          	jalr	-1874(ra) # 800042f2 <begin_op>
      ilock(f->ip);
    80004a4c:	01893503          	ld	a0,24(s2)
    80004a50:	fffff097          	auipc	ra,0xfffff
    80004a54:	ee2080e7          	jalr	-286(ra) # 80003932 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004a58:	8762                	mv	a4,s8
    80004a5a:	02092683          	lw	a3,32(s2)
    80004a5e:	01598633          	add	a2,s3,s5
    80004a62:	4585                	li	a1,1
    80004a64:	01893503          	ld	a0,24(s2)
    80004a68:	fffff097          	auipc	ra,0xfffff
    80004a6c:	274080e7          	jalr	628(ra) # 80003cdc <writei>
    80004a70:	84aa                	mv	s1,a0
    80004a72:	02a05f63          	blez	a0,80004ab0 <filewrite+0xf0>
        f->off += r;
    80004a76:	02092783          	lw	a5,32(s2)
    80004a7a:	9fa9                	addw	a5,a5,a0
    80004a7c:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004a80:	01893503          	ld	a0,24(s2)
    80004a84:	fffff097          	auipc	ra,0xfffff
    80004a88:	f70080e7          	jalr	-144(ra) # 800039f4 <iunlock>
      end_op();
    80004a8c:	00000097          	auipc	ra,0x0
    80004a90:	8e6080e7          	jalr	-1818(ra) # 80004372 <end_op>

      if(r < 0)
        break;
      if(r != n1)
    80004a94:	049c1963          	bne	s8,s1,80004ae6 <filewrite+0x126>
        panic("short filewrite");
      i += r;
    80004a98:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004a9c:	0349d663          	bge	s3,s4,80004ac8 <filewrite+0x108>
      int n1 = n - i;
    80004aa0:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004aa4:	84be                	mv	s1,a5
    80004aa6:	2781                	sext.w	a5,a5
    80004aa8:	f8fb5ce3          	bge	s6,a5,80004a40 <filewrite+0x80>
    80004aac:	84de                	mv	s1,s7
    80004aae:	bf49                	j	80004a40 <filewrite+0x80>
      iunlock(f->ip);
    80004ab0:	01893503          	ld	a0,24(s2)
    80004ab4:	fffff097          	auipc	ra,0xfffff
    80004ab8:	f40080e7          	jalr	-192(ra) # 800039f4 <iunlock>
      end_op();
    80004abc:	00000097          	auipc	ra,0x0
    80004ac0:	8b6080e7          	jalr	-1866(ra) # 80004372 <end_op>
      if(r < 0)
    80004ac4:	fc04d8e3          	bgez	s1,80004a94 <filewrite+0xd4>
    }
    ret = (i == n ? n : -1);
    80004ac8:	8552                	mv	a0,s4
    80004aca:	033a1863          	bne	s4,s3,80004afa <filewrite+0x13a>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004ace:	60a6                	ld	ra,72(sp)
    80004ad0:	6406                	ld	s0,64(sp)
    80004ad2:	74e2                	ld	s1,56(sp)
    80004ad4:	7942                	ld	s2,48(sp)
    80004ad6:	79a2                	ld	s3,40(sp)
    80004ad8:	7a02                	ld	s4,32(sp)
    80004ada:	6ae2                	ld	s5,24(sp)
    80004adc:	6b42                	ld	s6,16(sp)
    80004ade:	6ba2                	ld	s7,8(sp)
    80004ae0:	6c02                	ld	s8,0(sp)
    80004ae2:	6161                	addi	sp,sp,80
    80004ae4:	8082                	ret
        panic("short filewrite");
    80004ae6:	00004517          	auipc	a0,0x4
    80004aea:	be250513          	addi	a0,a0,-1054 # 800086c8 <syscalls+0x288>
    80004aee:	ffffc097          	auipc	ra,0xffffc
    80004af2:	ae2080e7          	jalr	-1310(ra) # 800005d0 <panic>
    int i = 0;
    80004af6:	4981                	li	s3,0
    80004af8:	bfc1                	j	80004ac8 <filewrite+0x108>
    ret = (i == n ? n : -1);
    80004afa:	557d                	li	a0,-1
    80004afc:	bfc9                	j	80004ace <filewrite+0x10e>
    panic("filewrite");
    80004afe:	00004517          	auipc	a0,0x4
    80004b02:	bda50513          	addi	a0,a0,-1062 # 800086d8 <syscalls+0x298>
    80004b06:	ffffc097          	auipc	ra,0xffffc
    80004b0a:	aca080e7          	jalr	-1334(ra) # 800005d0 <panic>
    return -1;
    80004b0e:	557d                	li	a0,-1
}
    80004b10:	8082                	ret
      return -1;
    80004b12:	557d                	li	a0,-1
    80004b14:	bf6d                	j	80004ace <filewrite+0x10e>
    80004b16:	557d                	li	a0,-1
    80004b18:	bf5d                	j	80004ace <filewrite+0x10e>

0000000080004b1a <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004b1a:	7179                	addi	sp,sp,-48
    80004b1c:	f406                	sd	ra,40(sp)
    80004b1e:	f022                	sd	s0,32(sp)
    80004b20:	ec26                	sd	s1,24(sp)
    80004b22:	e84a                	sd	s2,16(sp)
    80004b24:	e44e                	sd	s3,8(sp)
    80004b26:	e052                	sd	s4,0(sp)
    80004b28:	1800                	addi	s0,sp,48
    80004b2a:	84aa                	mv	s1,a0
    80004b2c:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004b2e:	0005b023          	sd	zero,0(a1)
    80004b32:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004b36:	00000097          	auipc	ra,0x0
    80004b3a:	bd2080e7          	jalr	-1070(ra) # 80004708 <filealloc>
    80004b3e:	e088                	sd	a0,0(s1)
    80004b40:	c551                	beqz	a0,80004bcc <pipealloc+0xb2>
    80004b42:	00000097          	auipc	ra,0x0
    80004b46:	bc6080e7          	jalr	-1082(ra) # 80004708 <filealloc>
    80004b4a:	00aa3023          	sd	a0,0(s4)
    80004b4e:	c92d                	beqz	a0,80004bc0 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004b50:	ffffc097          	auipc	ra,0xffffc
    80004b54:	022080e7          	jalr	34(ra) # 80000b72 <kalloc>
    80004b58:	892a                	mv	s2,a0
    80004b5a:	c125                	beqz	a0,80004bba <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004b5c:	4985                	li	s3,1
    80004b5e:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004b62:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004b66:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004b6a:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004b6e:	00004597          	auipc	a1,0x4
    80004b72:	b7a58593          	addi	a1,a1,-1158 # 800086e8 <syscalls+0x2a8>
    80004b76:	ffffc097          	auipc	ra,0xffffc
    80004b7a:	05c080e7          	jalr	92(ra) # 80000bd2 <initlock>
  (*f0)->type = FD_PIPE;
    80004b7e:	609c                	ld	a5,0(s1)
    80004b80:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004b84:	609c                	ld	a5,0(s1)
    80004b86:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004b8a:	609c                	ld	a5,0(s1)
    80004b8c:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004b90:	609c                	ld	a5,0(s1)
    80004b92:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004b96:	000a3783          	ld	a5,0(s4)
    80004b9a:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004b9e:	000a3783          	ld	a5,0(s4)
    80004ba2:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004ba6:	000a3783          	ld	a5,0(s4)
    80004baa:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004bae:	000a3783          	ld	a5,0(s4)
    80004bb2:	0127b823          	sd	s2,16(a5)
  return 0;
    80004bb6:	4501                	li	a0,0
    80004bb8:	a025                	j	80004be0 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004bba:	6088                	ld	a0,0(s1)
    80004bbc:	e501                	bnez	a0,80004bc4 <pipealloc+0xaa>
    80004bbe:	a039                	j	80004bcc <pipealloc+0xb2>
    80004bc0:	6088                	ld	a0,0(s1)
    80004bc2:	c51d                	beqz	a0,80004bf0 <pipealloc+0xd6>
    fileclose(*f0);
    80004bc4:	00000097          	auipc	ra,0x0
    80004bc8:	c00080e7          	jalr	-1024(ra) # 800047c4 <fileclose>
  if(*f1)
    80004bcc:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004bd0:	557d                	li	a0,-1
  if(*f1)
    80004bd2:	c799                	beqz	a5,80004be0 <pipealloc+0xc6>
    fileclose(*f1);
    80004bd4:	853e                	mv	a0,a5
    80004bd6:	00000097          	auipc	ra,0x0
    80004bda:	bee080e7          	jalr	-1042(ra) # 800047c4 <fileclose>
  return -1;
    80004bde:	557d                	li	a0,-1
}
    80004be0:	70a2                	ld	ra,40(sp)
    80004be2:	7402                	ld	s0,32(sp)
    80004be4:	64e2                	ld	s1,24(sp)
    80004be6:	6942                	ld	s2,16(sp)
    80004be8:	69a2                	ld	s3,8(sp)
    80004bea:	6a02                	ld	s4,0(sp)
    80004bec:	6145                	addi	sp,sp,48
    80004bee:	8082                	ret
  return -1;
    80004bf0:	557d                	li	a0,-1
    80004bf2:	b7fd                	j	80004be0 <pipealloc+0xc6>

0000000080004bf4 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004bf4:	1101                	addi	sp,sp,-32
    80004bf6:	ec06                	sd	ra,24(sp)
    80004bf8:	e822                	sd	s0,16(sp)
    80004bfa:	e426                	sd	s1,8(sp)
    80004bfc:	e04a                	sd	s2,0(sp)
    80004bfe:	1000                	addi	s0,sp,32
    80004c00:	84aa                	mv	s1,a0
    80004c02:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004c04:	ffffc097          	auipc	ra,0xffffc
    80004c08:	05e080e7          	jalr	94(ra) # 80000c62 <acquire>
  if(writable){
    80004c0c:	02090d63          	beqz	s2,80004c46 <pipeclose+0x52>
    pi->writeopen = 0;
    80004c10:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004c14:	21848513          	addi	a0,s1,536
    80004c18:	ffffd097          	auipc	ra,0xffffd
    80004c1c:	7ba080e7          	jalr	1978(ra) # 800023d2 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004c20:	2204b783          	ld	a5,544(s1)
    80004c24:	eb95                	bnez	a5,80004c58 <pipeclose+0x64>
    release(&pi->lock);
    80004c26:	8526                	mv	a0,s1
    80004c28:	ffffc097          	auipc	ra,0xffffc
    80004c2c:	0ee080e7          	jalr	238(ra) # 80000d16 <release>
    kfree((char*)pi);
    80004c30:	8526                	mv	a0,s1
    80004c32:	ffffc097          	auipc	ra,0xffffc
    80004c36:	e44080e7          	jalr	-444(ra) # 80000a76 <kfree>
  } else
    release(&pi->lock);
}
    80004c3a:	60e2                	ld	ra,24(sp)
    80004c3c:	6442                	ld	s0,16(sp)
    80004c3e:	64a2                	ld	s1,8(sp)
    80004c40:	6902                	ld	s2,0(sp)
    80004c42:	6105                	addi	sp,sp,32
    80004c44:	8082                	ret
    pi->readopen = 0;
    80004c46:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004c4a:	21c48513          	addi	a0,s1,540
    80004c4e:	ffffd097          	auipc	ra,0xffffd
    80004c52:	784080e7          	jalr	1924(ra) # 800023d2 <wakeup>
    80004c56:	b7e9                	j	80004c20 <pipeclose+0x2c>
    release(&pi->lock);
    80004c58:	8526                	mv	a0,s1
    80004c5a:	ffffc097          	auipc	ra,0xffffc
    80004c5e:	0bc080e7          	jalr	188(ra) # 80000d16 <release>
}
    80004c62:	bfe1                	j	80004c3a <pipeclose+0x46>

0000000080004c64 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004c64:	711d                	addi	sp,sp,-96
    80004c66:	ec86                	sd	ra,88(sp)
    80004c68:	e8a2                	sd	s0,80(sp)
    80004c6a:	e4a6                	sd	s1,72(sp)
    80004c6c:	e0ca                	sd	s2,64(sp)
    80004c6e:	fc4e                	sd	s3,56(sp)
    80004c70:	f852                	sd	s4,48(sp)
    80004c72:	f456                	sd	s5,40(sp)
    80004c74:	f05a                	sd	s6,32(sp)
    80004c76:	ec5e                	sd	s7,24(sp)
    80004c78:	e862                	sd	s8,16(sp)
    80004c7a:	1080                	addi	s0,sp,96
    80004c7c:	84aa                	mv	s1,a0
    80004c7e:	8b2e                	mv	s6,a1
    80004c80:	8ab2                	mv	s5,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    80004c82:	ffffd097          	auipc	ra,0xffffd
    80004c86:	dac080e7          	jalr	-596(ra) # 80001a2e <myproc>
    80004c8a:	892a                	mv	s2,a0

  acquire(&pi->lock);
    80004c8c:	8526                	mv	a0,s1
    80004c8e:	ffffc097          	auipc	ra,0xffffc
    80004c92:	fd4080e7          	jalr	-44(ra) # 80000c62 <acquire>
  for(i = 0; i < n; i++){
    80004c96:	09505763          	blez	s5,80004d24 <pipewrite+0xc0>
    80004c9a:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    80004c9c:	21848a13          	addi	s4,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004ca0:	21c48993          	addi	s3,s1,540
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004ca4:	5c7d                	li	s8,-1
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004ca6:	2184a783          	lw	a5,536(s1)
    80004caa:	21c4a703          	lw	a4,540(s1)
    80004cae:	2007879b          	addiw	a5,a5,512
    80004cb2:	02f71b63          	bne	a4,a5,80004ce8 <pipewrite+0x84>
      if(pi->readopen == 0 || pr->killed){
    80004cb6:	2204a783          	lw	a5,544(s1)
    80004cba:	c3d1                	beqz	a5,80004d3e <pipewrite+0xda>
    80004cbc:	03092783          	lw	a5,48(s2)
    80004cc0:	efbd                	bnez	a5,80004d3e <pipewrite+0xda>
      wakeup(&pi->nread);
    80004cc2:	8552                	mv	a0,s4
    80004cc4:	ffffd097          	auipc	ra,0xffffd
    80004cc8:	70e080e7          	jalr	1806(ra) # 800023d2 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004ccc:	85a6                	mv	a1,s1
    80004cce:	854e                	mv	a0,s3
    80004cd0:	ffffd097          	auipc	ra,0xffffd
    80004cd4:	582080e7          	jalr	1410(ra) # 80002252 <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004cd8:	2184a783          	lw	a5,536(s1)
    80004cdc:	21c4a703          	lw	a4,540(s1)
    80004ce0:	2007879b          	addiw	a5,a5,512
    80004ce4:	fcf709e3          	beq	a4,a5,80004cb6 <pipewrite+0x52>
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004ce8:	4685                	li	a3,1
    80004cea:	865a                	mv	a2,s6
    80004cec:	faf40593          	addi	a1,s0,-81
    80004cf0:	05093503          	ld	a0,80(s2)
    80004cf4:	ffffd097          	auipc	ra,0xffffd
    80004cf8:	ab8080e7          	jalr	-1352(ra) # 800017ac <copyin>
    80004cfc:	03850563          	beq	a0,s8,80004d26 <pipewrite+0xc2>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004d00:	21c4a783          	lw	a5,540(s1)
    80004d04:	0017871b          	addiw	a4,a5,1
    80004d08:	20e4ae23          	sw	a4,540(s1)
    80004d0c:	1ff7f793          	andi	a5,a5,511
    80004d10:	97a6                	add	a5,a5,s1
    80004d12:	faf44703          	lbu	a4,-81(s0)
    80004d16:	00e78c23          	sb	a4,24(a5)
  for(i = 0; i < n; i++){
    80004d1a:	2b85                	addiw	s7,s7,1
    80004d1c:	0b05                	addi	s6,s6,1
    80004d1e:	f97a94e3          	bne	s5,s7,80004ca6 <pipewrite+0x42>
    80004d22:	a011                	j	80004d26 <pipewrite+0xc2>
    80004d24:	4b81                	li	s7,0
  }
  wakeup(&pi->nread);
    80004d26:	21848513          	addi	a0,s1,536
    80004d2a:	ffffd097          	auipc	ra,0xffffd
    80004d2e:	6a8080e7          	jalr	1704(ra) # 800023d2 <wakeup>
  release(&pi->lock);
    80004d32:	8526                	mv	a0,s1
    80004d34:	ffffc097          	auipc	ra,0xffffc
    80004d38:	fe2080e7          	jalr	-30(ra) # 80000d16 <release>
  return i;
    80004d3c:	a039                	j	80004d4a <pipewrite+0xe6>
        release(&pi->lock);
    80004d3e:	8526                	mv	a0,s1
    80004d40:	ffffc097          	auipc	ra,0xffffc
    80004d44:	fd6080e7          	jalr	-42(ra) # 80000d16 <release>
        return -1;
    80004d48:	5bfd                	li	s7,-1
}
    80004d4a:	855e                	mv	a0,s7
    80004d4c:	60e6                	ld	ra,88(sp)
    80004d4e:	6446                	ld	s0,80(sp)
    80004d50:	64a6                	ld	s1,72(sp)
    80004d52:	6906                	ld	s2,64(sp)
    80004d54:	79e2                	ld	s3,56(sp)
    80004d56:	7a42                	ld	s4,48(sp)
    80004d58:	7aa2                	ld	s5,40(sp)
    80004d5a:	7b02                	ld	s6,32(sp)
    80004d5c:	6be2                	ld	s7,24(sp)
    80004d5e:	6c42                	ld	s8,16(sp)
    80004d60:	6125                	addi	sp,sp,96
    80004d62:	8082                	ret

0000000080004d64 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004d64:	715d                	addi	sp,sp,-80
    80004d66:	e486                	sd	ra,72(sp)
    80004d68:	e0a2                	sd	s0,64(sp)
    80004d6a:	fc26                	sd	s1,56(sp)
    80004d6c:	f84a                	sd	s2,48(sp)
    80004d6e:	f44e                	sd	s3,40(sp)
    80004d70:	f052                	sd	s4,32(sp)
    80004d72:	ec56                	sd	s5,24(sp)
    80004d74:	e85a                	sd	s6,16(sp)
    80004d76:	0880                	addi	s0,sp,80
    80004d78:	84aa                	mv	s1,a0
    80004d7a:	892e                	mv	s2,a1
    80004d7c:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004d7e:	ffffd097          	auipc	ra,0xffffd
    80004d82:	cb0080e7          	jalr	-848(ra) # 80001a2e <myproc>
    80004d86:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004d88:	8526                	mv	a0,s1
    80004d8a:	ffffc097          	auipc	ra,0xffffc
    80004d8e:	ed8080e7          	jalr	-296(ra) # 80000c62 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d92:	2184a703          	lw	a4,536(s1)
    80004d96:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004d9a:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d9e:	02f71463          	bne	a4,a5,80004dc6 <piperead+0x62>
    80004da2:	2244a783          	lw	a5,548(s1)
    80004da6:	c385                	beqz	a5,80004dc6 <piperead+0x62>
    if(pr->killed){
    80004da8:	030a2783          	lw	a5,48(s4)
    80004dac:	ebc1                	bnez	a5,80004e3c <piperead+0xd8>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004dae:	85a6                	mv	a1,s1
    80004db0:	854e                	mv	a0,s3
    80004db2:	ffffd097          	auipc	ra,0xffffd
    80004db6:	4a0080e7          	jalr	1184(ra) # 80002252 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004dba:	2184a703          	lw	a4,536(s1)
    80004dbe:	21c4a783          	lw	a5,540(s1)
    80004dc2:	fef700e3          	beq	a4,a5,80004da2 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004dc6:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004dc8:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004dca:	05505363          	blez	s5,80004e10 <piperead+0xac>
    if(pi->nread == pi->nwrite)
    80004dce:	2184a783          	lw	a5,536(s1)
    80004dd2:	21c4a703          	lw	a4,540(s1)
    80004dd6:	02f70d63          	beq	a4,a5,80004e10 <piperead+0xac>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004dda:	0017871b          	addiw	a4,a5,1
    80004dde:	20e4ac23          	sw	a4,536(s1)
    80004de2:	1ff7f793          	andi	a5,a5,511
    80004de6:	97a6                	add	a5,a5,s1
    80004de8:	0187c783          	lbu	a5,24(a5)
    80004dec:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004df0:	4685                	li	a3,1
    80004df2:	fbf40613          	addi	a2,s0,-65
    80004df6:	85ca                	mv	a1,s2
    80004df8:	050a3503          	ld	a0,80(s4)
    80004dfc:	ffffd097          	auipc	ra,0xffffd
    80004e00:	924080e7          	jalr	-1756(ra) # 80001720 <copyout>
    80004e04:	01650663          	beq	a0,s6,80004e10 <piperead+0xac>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e08:	2985                	addiw	s3,s3,1
    80004e0a:	0905                	addi	s2,s2,1
    80004e0c:	fd3a91e3          	bne	s5,s3,80004dce <piperead+0x6a>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004e10:	21c48513          	addi	a0,s1,540
    80004e14:	ffffd097          	auipc	ra,0xffffd
    80004e18:	5be080e7          	jalr	1470(ra) # 800023d2 <wakeup>
  release(&pi->lock);
    80004e1c:	8526                	mv	a0,s1
    80004e1e:	ffffc097          	auipc	ra,0xffffc
    80004e22:	ef8080e7          	jalr	-264(ra) # 80000d16 <release>
  return i;
}
    80004e26:	854e                	mv	a0,s3
    80004e28:	60a6                	ld	ra,72(sp)
    80004e2a:	6406                	ld	s0,64(sp)
    80004e2c:	74e2                	ld	s1,56(sp)
    80004e2e:	7942                	ld	s2,48(sp)
    80004e30:	79a2                	ld	s3,40(sp)
    80004e32:	7a02                	ld	s4,32(sp)
    80004e34:	6ae2                	ld	s5,24(sp)
    80004e36:	6b42                	ld	s6,16(sp)
    80004e38:	6161                	addi	sp,sp,80
    80004e3a:	8082                	ret
      release(&pi->lock);
    80004e3c:	8526                	mv	a0,s1
    80004e3e:	ffffc097          	auipc	ra,0xffffc
    80004e42:	ed8080e7          	jalr	-296(ra) # 80000d16 <release>
      return -1;
    80004e46:	59fd                	li	s3,-1
    80004e48:	bff9                	j	80004e26 <piperead+0xc2>

0000000080004e4a <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004e4a:	de010113          	addi	sp,sp,-544
    80004e4e:	20113c23          	sd	ra,536(sp)
    80004e52:	20813823          	sd	s0,528(sp)
    80004e56:	20913423          	sd	s1,520(sp)
    80004e5a:	21213023          	sd	s2,512(sp)
    80004e5e:	ffce                	sd	s3,504(sp)
    80004e60:	fbd2                	sd	s4,496(sp)
    80004e62:	f7d6                	sd	s5,488(sp)
    80004e64:	f3da                	sd	s6,480(sp)
    80004e66:	efde                	sd	s7,472(sp)
    80004e68:	ebe2                	sd	s8,464(sp)
    80004e6a:	e7e6                	sd	s9,456(sp)
    80004e6c:	e3ea                	sd	s10,448(sp)
    80004e6e:	ff6e                	sd	s11,440(sp)
    80004e70:	1400                	addi	s0,sp,544
    80004e72:	892a                	mv	s2,a0
    80004e74:	dea43423          	sd	a0,-536(s0)
    80004e78:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004e7c:	ffffd097          	auipc	ra,0xffffd
    80004e80:	bb2080e7          	jalr	-1102(ra) # 80001a2e <myproc>
    80004e84:	84aa                	mv	s1,a0

  begin_op();
    80004e86:	fffff097          	auipc	ra,0xfffff
    80004e8a:	46c080e7          	jalr	1132(ra) # 800042f2 <begin_op>

  if((ip = namei(path)) == 0){
    80004e8e:	854a                	mv	a0,s2
    80004e90:	fffff097          	auipc	ra,0xfffff
    80004e94:	252080e7          	jalr	594(ra) # 800040e2 <namei>
    80004e98:	c93d                	beqz	a0,80004f0e <exec+0xc4>
    80004e9a:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004e9c:	fffff097          	auipc	ra,0xfffff
    80004ea0:	a96080e7          	jalr	-1386(ra) # 80003932 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004ea4:	04000713          	li	a4,64
    80004ea8:	4681                	li	a3,0
    80004eaa:	e4840613          	addi	a2,s0,-440
    80004eae:	4581                	li	a1,0
    80004eb0:	8556                	mv	a0,s5
    80004eb2:	fffff097          	auipc	ra,0xfffff
    80004eb6:	d34080e7          	jalr	-716(ra) # 80003be6 <readi>
    80004eba:	04000793          	li	a5,64
    80004ebe:	00f51a63          	bne	a0,a5,80004ed2 <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004ec2:	e4842703          	lw	a4,-440(s0)
    80004ec6:	464c47b7          	lui	a5,0x464c4
    80004eca:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004ece:	04f70663          	beq	a4,a5,80004f1a <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004ed2:	8556                	mv	a0,s5
    80004ed4:	fffff097          	auipc	ra,0xfffff
    80004ed8:	cc0080e7          	jalr	-832(ra) # 80003b94 <iunlockput>
    end_op();
    80004edc:	fffff097          	auipc	ra,0xfffff
    80004ee0:	496080e7          	jalr	1174(ra) # 80004372 <end_op>
  }
  return -1;
    80004ee4:	557d                	li	a0,-1
}
    80004ee6:	21813083          	ld	ra,536(sp)
    80004eea:	21013403          	ld	s0,528(sp)
    80004eee:	20813483          	ld	s1,520(sp)
    80004ef2:	20013903          	ld	s2,512(sp)
    80004ef6:	79fe                	ld	s3,504(sp)
    80004ef8:	7a5e                	ld	s4,496(sp)
    80004efa:	7abe                	ld	s5,488(sp)
    80004efc:	7b1e                	ld	s6,480(sp)
    80004efe:	6bfe                	ld	s7,472(sp)
    80004f00:	6c5e                	ld	s8,464(sp)
    80004f02:	6cbe                	ld	s9,456(sp)
    80004f04:	6d1e                	ld	s10,448(sp)
    80004f06:	7dfa                	ld	s11,440(sp)
    80004f08:	22010113          	addi	sp,sp,544
    80004f0c:	8082                	ret
    end_op();
    80004f0e:	fffff097          	auipc	ra,0xfffff
    80004f12:	464080e7          	jalr	1124(ra) # 80004372 <end_op>
    return -1;
    80004f16:	557d                	li	a0,-1
    80004f18:	b7f9                	j	80004ee6 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004f1a:	8526                	mv	a0,s1
    80004f1c:	ffffd097          	auipc	ra,0xffffd
    80004f20:	bd6080e7          	jalr	-1066(ra) # 80001af2 <proc_pagetable>
    80004f24:	8b2a                	mv	s6,a0
    80004f26:	d555                	beqz	a0,80004ed2 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f28:	e6842783          	lw	a5,-408(s0)
    80004f2c:	e8045703          	lhu	a4,-384(s0)
    80004f30:	c735                	beqz	a4,80004f9c <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004f32:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f34:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004f38:	6a05                	lui	s4,0x1
    80004f3a:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004f3e:	dee43023          	sd	a4,-544(s0)
  uint64 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    80004f42:	6d85                	lui	s11,0x1
    80004f44:	7d7d                	lui	s10,0xfffff
    80004f46:	ac1d                	j	8000517c <exec+0x332>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004f48:	00003517          	auipc	a0,0x3
    80004f4c:	7a850513          	addi	a0,a0,1960 # 800086f0 <syscalls+0x2b0>
    80004f50:	ffffb097          	auipc	ra,0xffffb
    80004f54:	680080e7          	jalr	1664(ra) # 800005d0 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004f58:	874a                	mv	a4,s2
    80004f5a:	009c86bb          	addw	a3,s9,s1
    80004f5e:	4581                	li	a1,0
    80004f60:	8556                	mv	a0,s5
    80004f62:	fffff097          	auipc	ra,0xfffff
    80004f66:	c84080e7          	jalr	-892(ra) # 80003be6 <readi>
    80004f6a:	2501                	sext.w	a0,a0
    80004f6c:	1aa91863          	bne	s2,a0,8000511c <exec+0x2d2>
  for(i = 0; i < sz; i += PGSIZE){
    80004f70:	009d84bb          	addw	s1,s11,s1
    80004f74:	013d09bb          	addw	s3,s10,s3
    80004f78:	1f74f263          	bgeu	s1,s7,8000515c <exec+0x312>
    pa = walkaddr(pagetable, va + i);
    80004f7c:	02049593          	slli	a1,s1,0x20
    80004f80:	9181                	srli	a1,a1,0x20
    80004f82:	95e2                	add	a1,a1,s8
    80004f84:	855a                	mv	a0,s6
    80004f86:	ffffc097          	auipc	ra,0xffffc
    80004f8a:	166080e7          	jalr	358(ra) # 800010ec <walkaddr>
    80004f8e:	862a                	mv	a2,a0
    if(pa == 0)
    80004f90:	dd45                	beqz	a0,80004f48 <exec+0xfe>
      n = PGSIZE;
    80004f92:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004f94:	fd49f2e3          	bgeu	s3,s4,80004f58 <exec+0x10e>
      n = sz - i;
    80004f98:	894e                	mv	s2,s3
    80004f9a:	bf7d                	j	80004f58 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004f9c:	4481                	li	s1,0
  iunlockput(ip);
    80004f9e:	8556                	mv	a0,s5
    80004fa0:	fffff097          	auipc	ra,0xfffff
    80004fa4:	bf4080e7          	jalr	-1036(ra) # 80003b94 <iunlockput>
  end_op();
    80004fa8:	fffff097          	auipc	ra,0xfffff
    80004fac:	3ca080e7          	jalr	970(ra) # 80004372 <end_op>
  p = myproc();
    80004fb0:	ffffd097          	auipc	ra,0xffffd
    80004fb4:	a7e080e7          	jalr	-1410(ra) # 80001a2e <myproc>
    80004fb8:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004fba:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004fbe:	6785                	lui	a5,0x1
    80004fc0:	17fd                	addi	a5,a5,-1
    80004fc2:	94be                	add	s1,s1,a5
    80004fc4:	77fd                	lui	a5,0xfffff
    80004fc6:	8fe5                	and	a5,a5,s1
    80004fc8:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004fcc:	6609                	lui	a2,0x2
    80004fce:	963e                	add	a2,a2,a5
    80004fd0:	85be                	mv	a1,a5
    80004fd2:	855a                	mv	a0,s6
    80004fd4:	ffffc097          	auipc	ra,0xffffc
    80004fd8:	4fc080e7          	jalr	1276(ra) # 800014d0 <uvmalloc>
    80004fdc:	8c2a                	mv	s8,a0
  ip = 0;
    80004fde:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004fe0:	12050e63          	beqz	a0,8000511c <exec+0x2d2>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004fe4:	75f9                	lui	a1,0xffffe
    80004fe6:	95aa                	add	a1,a1,a0
    80004fe8:	855a                	mv	a0,s6
    80004fea:	ffffc097          	auipc	ra,0xffffc
    80004fee:	704080e7          	jalr	1796(ra) # 800016ee <uvmclear>
  stackbase = sp - PGSIZE;
    80004ff2:	7afd                	lui	s5,0xfffff
    80004ff4:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80004ff6:	df043783          	ld	a5,-528(s0)
    80004ffa:	6388                	ld	a0,0(a5)
    80004ffc:	c925                	beqz	a0,8000506c <exec+0x222>
    80004ffe:	e8840993          	addi	s3,s0,-376
    80005002:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80005006:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005008:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    8000500a:	ffffc097          	auipc	ra,0xffffc
    8000500e:	ed8080e7          	jalr	-296(ra) # 80000ee2 <strlen>
    80005012:	0015079b          	addiw	a5,a0,1
    80005016:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    8000501a:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    8000501e:	13596363          	bltu	s2,s5,80005144 <exec+0x2fa>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005022:	df043d83          	ld	s11,-528(s0)
    80005026:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    8000502a:	8552                	mv	a0,s4
    8000502c:	ffffc097          	auipc	ra,0xffffc
    80005030:	eb6080e7          	jalr	-330(ra) # 80000ee2 <strlen>
    80005034:	0015069b          	addiw	a3,a0,1
    80005038:	8652                	mv	a2,s4
    8000503a:	85ca                	mv	a1,s2
    8000503c:	855a                	mv	a0,s6
    8000503e:	ffffc097          	auipc	ra,0xffffc
    80005042:	6e2080e7          	jalr	1762(ra) # 80001720 <copyout>
    80005046:	10054363          	bltz	a0,8000514c <exec+0x302>
    ustack[argc] = sp;
    8000504a:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    8000504e:	0485                	addi	s1,s1,1
    80005050:	008d8793          	addi	a5,s11,8
    80005054:	def43823          	sd	a5,-528(s0)
    80005058:	008db503          	ld	a0,8(s11)
    8000505c:	c911                	beqz	a0,80005070 <exec+0x226>
    if(argc >= MAXARG)
    8000505e:	09a1                	addi	s3,s3,8
    80005060:	fb3c95e3          	bne	s9,s3,8000500a <exec+0x1c0>
  sz = sz1;
    80005064:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005068:	4a81                	li	s5,0
    8000506a:	a84d                	j	8000511c <exec+0x2d2>
  sp = sz;
    8000506c:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    8000506e:	4481                	li	s1,0
  ustack[argc] = 0;
    80005070:	00349793          	slli	a5,s1,0x3
    80005074:	f9040713          	addi	a4,s0,-112
    80005078:	97ba                	add	a5,a5,a4
    8000507a:	ee07bc23          	sd	zero,-264(a5) # ffffffffffffeef8 <end+0xffffffff7ffd3ef8>
  sp -= (argc+1) * sizeof(uint64);
    8000507e:	00148693          	addi	a3,s1,1
    80005082:	068e                	slli	a3,a3,0x3
    80005084:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005088:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    8000508c:	01597663          	bgeu	s2,s5,80005098 <exec+0x24e>
  sz = sz1;
    80005090:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005094:	4a81                	li	s5,0
    80005096:	a059                	j	8000511c <exec+0x2d2>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005098:	e8840613          	addi	a2,s0,-376
    8000509c:	85ca                	mv	a1,s2
    8000509e:	855a                	mv	a0,s6
    800050a0:	ffffc097          	auipc	ra,0xffffc
    800050a4:	680080e7          	jalr	1664(ra) # 80001720 <copyout>
    800050a8:	0a054663          	bltz	a0,80005154 <exec+0x30a>
  p->trapframe->a1 = sp;
    800050ac:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    800050b0:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800050b4:	de843783          	ld	a5,-536(s0)
    800050b8:	0007c703          	lbu	a4,0(a5)
    800050bc:	cf11                	beqz	a4,800050d8 <exec+0x28e>
    800050be:	0785                	addi	a5,a5,1
    if(*s == '/')
    800050c0:	02f00693          	li	a3,47
    800050c4:	a039                	j	800050d2 <exec+0x288>
      last = s+1;
    800050c6:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    800050ca:	0785                	addi	a5,a5,1
    800050cc:	fff7c703          	lbu	a4,-1(a5)
    800050d0:	c701                	beqz	a4,800050d8 <exec+0x28e>
    if(*s == '/')
    800050d2:	fed71ce3          	bne	a4,a3,800050ca <exec+0x280>
    800050d6:	bfc5                	j	800050c6 <exec+0x27c>
  safestrcpy(p->name, last, sizeof(p->name));
    800050d8:	4641                	li	a2,16
    800050da:	de843583          	ld	a1,-536(s0)
    800050de:	158b8513          	addi	a0,s7,344
    800050e2:	ffffc097          	auipc	ra,0xffffc
    800050e6:	dce080e7          	jalr	-562(ra) # 80000eb0 <safestrcpy>
  oldpagetable = p->pagetable;
    800050ea:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    800050ee:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    800050f2:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800050f6:	058bb783          	ld	a5,88(s7)
    800050fa:	e6043703          	ld	a4,-416(s0)
    800050fe:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005100:	058bb783          	ld	a5,88(s7)
    80005104:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005108:	85ea                	mv	a1,s10
    8000510a:	ffffd097          	auipc	ra,0xffffd
    8000510e:	a84080e7          	jalr	-1404(ra) # 80001b8e <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005112:	0004851b          	sext.w	a0,s1
    80005116:	bbc1                	j	80004ee6 <exec+0x9c>
    80005118:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    8000511c:	df843583          	ld	a1,-520(s0)
    80005120:	855a                	mv	a0,s6
    80005122:	ffffd097          	auipc	ra,0xffffd
    80005126:	a6c080e7          	jalr	-1428(ra) # 80001b8e <proc_freepagetable>
  if(ip){
    8000512a:	da0a94e3          	bnez	s5,80004ed2 <exec+0x88>
  return -1;
    8000512e:	557d                	li	a0,-1
    80005130:	bb5d                	j	80004ee6 <exec+0x9c>
    80005132:	de943c23          	sd	s1,-520(s0)
    80005136:	b7dd                	j	8000511c <exec+0x2d2>
    80005138:	de943c23          	sd	s1,-520(s0)
    8000513c:	b7c5                	j	8000511c <exec+0x2d2>
    8000513e:	de943c23          	sd	s1,-520(s0)
    80005142:	bfe9                	j	8000511c <exec+0x2d2>
  sz = sz1;
    80005144:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005148:	4a81                	li	s5,0
    8000514a:	bfc9                	j	8000511c <exec+0x2d2>
  sz = sz1;
    8000514c:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005150:	4a81                	li	s5,0
    80005152:	b7e9                	j	8000511c <exec+0x2d2>
  sz = sz1;
    80005154:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005158:	4a81                	li	s5,0
    8000515a:	b7c9                	j	8000511c <exec+0x2d2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000515c:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005160:	e0843783          	ld	a5,-504(s0)
    80005164:	0017869b          	addiw	a3,a5,1
    80005168:	e0d43423          	sd	a3,-504(s0)
    8000516c:	e0043783          	ld	a5,-512(s0)
    80005170:	0387879b          	addiw	a5,a5,56
    80005174:	e8045703          	lhu	a4,-384(s0)
    80005178:	e2e6d3e3          	bge	a3,a4,80004f9e <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000517c:	2781                	sext.w	a5,a5
    8000517e:	e0f43023          	sd	a5,-512(s0)
    80005182:	03800713          	li	a4,56
    80005186:	86be                	mv	a3,a5
    80005188:	e1040613          	addi	a2,s0,-496
    8000518c:	4581                	li	a1,0
    8000518e:	8556                	mv	a0,s5
    80005190:	fffff097          	auipc	ra,0xfffff
    80005194:	a56080e7          	jalr	-1450(ra) # 80003be6 <readi>
    80005198:	03800793          	li	a5,56
    8000519c:	f6f51ee3          	bne	a0,a5,80005118 <exec+0x2ce>
    if(ph.type != ELF_PROG_LOAD)
    800051a0:	e1042783          	lw	a5,-496(s0)
    800051a4:	4705                	li	a4,1
    800051a6:	fae79de3          	bne	a5,a4,80005160 <exec+0x316>
    if(ph.memsz < ph.filesz)
    800051aa:	e3843603          	ld	a2,-456(s0)
    800051ae:	e3043783          	ld	a5,-464(s0)
    800051b2:	f8f660e3          	bltu	a2,a5,80005132 <exec+0x2e8>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800051b6:	e2043783          	ld	a5,-480(s0)
    800051ba:	963e                	add	a2,a2,a5
    800051bc:	f6f66ee3          	bltu	a2,a5,80005138 <exec+0x2ee>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800051c0:	85a6                	mv	a1,s1
    800051c2:	855a                	mv	a0,s6
    800051c4:	ffffc097          	auipc	ra,0xffffc
    800051c8:	30c080e7          	jalr	780(ra) # 800014d0 <uvmalloc>
    800051cc:	dea43c23          	sd	a0,-520(s0)
    800051d0:	d53d                	beqz	a0,8000513e <exec+0x2f4>
    if(ph.vaddr % PGSIZE != 0)
    800051d2:	e2043c03          	ld	s8,-480(s0)
    800051d6:	de043783          	ld	a5,-544(s0)
    800051da:	00fc77b3          	and	a5,s8,a5
    800051de:	ff9d                	bnez	a5,8000511c <exec+0x2d2>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800051e0:	e1842c83          	lw	s9,-488(s0)
    800051e4:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800051e8:	f60b8ae3          	beqz	s7,8000515c <exec+0x312>
    800051ec:	89de                	mv	s3,s7
    800051ee:	4481                	li	s1,0
    800051f0:	b371                	j	80004f7c <exec+0x132>

00000000800051f2 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800051f2:	7179                	addi	sp,sp,-48
    800051f4:	f406                	sd	ra,40(sp)
    800051f6:	f022                	sd	s0,32(sp)
    800051f8:	ec26                	sd	s1,24(sp)
    800051fa:	e84a                	sd	s2,16(sp)
    800051fc:	1800                	addi	s0,sp,48
    800051fe:	892e                	mv	s2,a1
    80005200:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005202:	fdc40593          	addi	a1,s0,-36
    80005206:	ffffe097          	auipc	ra,0xffffe
    8000520a:	9fc080e7          	jalr	-1540(ra) # 80002c02 <argint>
    8000520e:	04054063          	bltz	a0,8000524e <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005212:	fdc42703          	lw	a4,-36(s0)
    80005216:	47bd                	li	a5,15
    80005218:	02e7ed63          	bltu	a5,a4,80005252 <argfd+0x60>
    8000521c:	ffffd097          	auipc	ra,0xffffd
    80005220:	812080e7          	jalr	-2030(ra) # 80001a2e <myproc>
    80005224:	fdc42703          	lw	a4,-36(s0)
    80005228:	01a70793          	addi	a5,a4,26
    8000522c:	078e                	slli	a5,a5,0x3
    8000522e:	953e                	add	a0,a0,a5
    80005230:	611c                	ld	a5,0(a0)
    80005232:	c395                	beqz	a5,80005256 <argfd+0x64>
    return -1;
  if(pfd)
    80005234:	00090463          	beqz	s2,8000523c <argfd+0x4a>
    *pfd = fd;
    80005238:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    8000523c:	4501                	li	a0,0
  if(pf)
    8000523e:	c091                	beqz	s1,80005242 <argfd+0x50>
    *pf = f;
    80005240:	e09c                	sd	a5,0(s1)
}
    80005242:	70a2                	ld	ra,40(sp)
    80005244:	7402                	ld	s0,32(sp)
    80005246:	64e2                	ld	s1,24(sp)
    80005248:	6942                	ld	s2,16(sp)
    8000524a:	6145                	addi	sp,sp,48
    8000524c:	8082                	ret
    return -1;
    8000524e:	557d                	li	a0,-1
    80005250:	bfcd                	j	80005242 <argfd+0x50>
    return -1;
    80005252:	557d                	li	a0,-1
    80005254:	b7fd                	j	80005242 <argfd+0x50>
    80005256:	557d                	li	a0,-1
    80005258:	b7ed                	j	80005242 <argfd+0x50>

000000008000525a <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000525a:	1101                	addi	sp,sp,-32
    8000525c:	ec06                	sd	ra,24(sp)
    8000525e:	e822                	sd	s0,16(sp)
    80005260:	e426                	sd	s1,8(sp)
    80005262:	1000                	addi	s0,sp,32
    80005264:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005266:	ffffc097          	auipc	ra,0xffffc
    8000526a:	7c8080e7          	jalr	1992(ra) # 80001a2e <myproc>
    8000526e:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005270:	0d050793          	addi	a5,a0,208
    80005274:	4501                	li	a0,0
    80005276:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005278:	6398                	ld	a4,0(a5)
    8000527a:	cb19                	beqz	a4,80005290 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000527c:	2505                	addiw	a0,a0,1
    8000527e:	07a1                	addi	a5,a5,8
    80005280:	fed51ce3          	bne	a0,a3,80005278 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005284:	557d                	li	a0,-1
}
    80005286:	60e2                	ld	ra,24(sp)
    80005288:	6442                	ld	s0,16(sp)
    8000528a:	64a2                	ld	s1,8(sp)
    8000528c:	6105                	addi	sp,sp,32
    8000528e:	8082                	ret
      p->ofile[fd] = f;
    80005290:	01a50793          	addi	a5,a0,26
    80005294:	078e                	slli	a5,a5,0x3
    80005296:	963e                	add	a2,a2,a5
    80005298:	e204                	sd	s1,0(a2)
      return fd;
    8000529a:	b7f5                	j	80005286 <fdalloc+0x2c>

000000008000529c <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000529c:	715d                	addi	sp,sp,-80
    8000529e:	e486                	sd	ra,72(sp)
    800052a0:	e0a2                	sd	s0,64(sp)
    800052a2:	fc26                	sd	s1,56(sp)
    800052a4:	f84a                	sd	s2,48(sp)
    800052a6:	f44e                	sd	s3,40(sp)
    800052a8:	f052                	sd	s4,32(sp)
    800052aa:	ec56                	sd	s5,24(sp)
    800052ac:	0880                	addi	s0,sp,80
    800052ae:	89ae                	mv	s3,a1
    800052b0:	8ab2                	mv	s5,a2
    800052b2:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800052b4:	fb040593          	addi	a1,s0,-80
    800052b8:	fffff097          	auipc	ra,0xfffff
    800052bc:	e48080e7          	jalr	-440(ra) # 80004100 <nameiparent>
    800052c0:	892a                	mv	s2,a0
    800052c2:	12050e63          	beqz	a0,800053fe <create+0x162>
    return 0;

  ilock(dp);
    800052c6:	ffffe097          	auipc	ra,0xffffe
    800052ca:	66c080e7          	jalr	1644(ra) # 80003932 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800052ce:	4601                	li	a2,0
    800052d0:	fb040593          	addi	a1,s0,-80
    800052d4:	854a                	mv	a0,s2
    800052d6:	fffff097          	auipc	ra,0xfffff
    800052da:	b3a080e7          	jalr	-1222(ra) # 80003e10 <dirlookup>
    800052de:	84aa                	mv	s1,a0
    800052e0:	c921                	beqz	a0,80005330 <create+0x94>
    iunlockput(dp);
    800052e2:	854a                	mv	a0,s2
    800052e4:	fffff097          	auipc	ra,0xfffff
    800052e8:	8b0080e7          	jalr	-1872(ra) # 80003b94 <iunlockput>
    ilock(ip);
    800052ec:	8526                	mv	a0,s1
    800052ee:	ffffe097          	auipc	ra,0xffffe
    800052f2:	644080e7          	jalr	1604(ra) # 80003932 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800052f6:	2981                	sext.w	s3,s3
    800052f8:	4789                	li	a5,2
    800052fa:	02f99463          	bne	s3,a5,80005322 <create+0x86>
    800052fe:	0444d783          	lhu	a5,68(s1)
    80005302:	37f9                	addiw	a5,a5,-2
    80005304:	17c2                	slli	a5,a5,0x30
    80005306:	93c1                	srli	a5,a5,0x30
    80005308:	4705                	li	a4,1
    8000530a:	00f76c63          	bltu	a4,a5,80005322 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    8000530e:	8526                	mv	a0,s1
    80005310:	60a6                	ld	ra,72(sp)
    80005312:	6406                	ld	s0,64(sp)
    80005314:	74e2                	ld	s1,56(sp)
    80005316:	7942                	ld	s2,48(sp)
    80005318:	79a2                	ld	s3,40(sp)
    8000531a:	7a02                	ld	s4,32(sp)
    8000531c:	6ae2                	ld	s5,24(sp)
    8000531e:	6161                	addi	sp,sp,80
    80005320:	8082                	ret
    iunlockput(ip);
    80005322:	8526                	mv	a0,s1
    80005324:	fffff097          	auipc	ra,0xfffff
    80005328:	870080e7          	jalr	-1936(ra) # 80003b94 <iunlockput>
    return 0;
    8000532c:	4481                	li	s1,0
    8000532e:	b7c5                	j	8000530e <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005330:	85ce                	mv	a1,s3
    80005332:	00092503          	lw	a0,0(s2)
    80005336:	ffffe097          	auipc	ra,0xffffe
    8000533a:	464080e7          	jalr	1124(ra) # 8000379a <ialloc>
    8000533e:	84aa                	mv	s1,a0
    80005340:	c521                	beqz	a0,80005388 <create+0xec>
  ilock(ip);
    80005342:	ffffe097          	auipc	ra,0xffffe
    80005346:	5f0080e7          	jalr	1520(ra) # 80003932 <ilock>
  ip->major = major;
    8000534a:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    8000534e:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005352:	4a05                	li	s4,1
    80005354:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    80005358:	8526                	mv	a0,s1
    8000535a:	ffffe097          	auipc	ra,0xffffe
    8000535e:	50e080e7          	jalr	1294(ra) # 80003868 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005362:	2981                	sext.w	s3,s3
    80005364:	03498a63          	beq	s3,s4,80005398 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    80005368:	40d0                	lw	a2,4(s1)
    8000536a:	fb040593          	addi	a1,s0,-80
    8000536e:	854a                	mv	a0,s2
    80005370:	fffff097          	auipc	ra,0xfffff
    80005374:	cb0080e7          	jalr	-848(ra) # 80004020 <dirlink>
    80005378:	06054b63          	bltz	a0,800053ee <create+0x152>
  iunlockput(dp);
    8000537c:	854a                	mv	a0,s2
    8000537e:	fffff097          	auipc	ra,0xfffff
    80005382:	816080e7          	jalr	-2026(ra) # 80003b94 <iunlockput>
  return ip;
    80005386:	b761                	j	8000530e <create+0x72>
    panic("create: ialloc");
    80005388:	00003517          	auipc	a0,0x3
    8000538c:	38850513          	addi	a0,a0,904 # 80008710 <syscalls+0x2d0>
    80005390:	ffffb097          	auipc	ra,0xffffb
    80005394:	240080e7          	jalr	576(ra) # 800005d0 <panic>
    dp->nlink++;  // for ".."
    80005398:	04a95783          	lhu	a5,74(s2)
    8000539c:	2785                	addiw	a5,a5,1
    8000539e:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800053a2:	854a                	mv	a0,s2
    800053a4:	ffffe097          	auipc	ra,0xffffe
    800053a8:	4c4080e7          	jalr	1220(ra) # 80003868 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800053ac:	40d0                	lw	a2,4(s1)
    800053ae:	00003597          	auipc	a1,0x3
    800053b2:	37258593          	addi	a1,a1,882 # 80008720 <syscalls+0x2e0>
    800053b6:	8526                	mv	a0,s1
    800053b8:	fffff097          	auipc	ra,0xfffff
    800053bc:	c68080e7          	jalr	-920(ra) # 80004020 <dirlink>
    800053c0:	00054f63          	bltz	a0,800053de <create+0x142>
    800053c4:	00492603          	lw	a2,4(s2)
    800053c8:	00003597          	auipc	a1,0x3
    800053cc:	36058593          	addi	a1,a1,864 # 80008728 <syscalls+0x2e8>
    800053d0:	8526                	mv	a0,s1
    800053d2:	fffff097          	auipc	ra,0xfffff
    800053d6:	c4e080e7          	jalr	-946(ra) # 80004020 <dirlink>
    800053da:	f80557e3          	bgez	a0,80005368 <create+0xcc>
      panic("create dots");
    800053de:	00003517          	auipc	a0,0x3
    800053e2:	35250513          	addi	a0,a0,850 # 80008730 <syscalls+0x2f0>
    800053e6:	ffffb097          	auipc	ra,0xffffb
    800053ea:	1ea080e7          	jalr	490(ra) # 800005d0 <panic>
    panic("create: dirlink");
    800053ee:	00003517          	auipc	a0,0x3
    800053f2:	35250513          	addi	a0,a0,850 # 80008740 <syscalls+0x300>
    800053f6:	ffffb097          	auipc	ra,0xffffb
    800053fa:	1da080e7          	jalr	474(ra) # 800005d0 <panic>
    return 0;
    800053fe:	84aa                	mv	s1,a0
    80005400:	b739                	j	8000530e <create+0x72>

0000000080005402 <sys_dup>:
{
    80005402:	7179                	addi	sp,sp,-48
    80005404:	f406                	sd	ra,40(sp)
    80005406:	f022                	sd	s0,32(sp)
    80005408:	ec26                	sd	s1,24(sp)
    8000540a:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000540c:	fd840613          	addi	a2,s0,-40
    80005410:	4581                	li	a1,0
    80005412:	4501                	li	a0,0
    80005414:	00000097          	auipc	ra,0x0
    80005418:	dde080e7          	jalr	-546(ra) # 800051f2 <argfd>
    return -1;
    8000541c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000541e:	02054363          	bltz	a0,80005444 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005422:	fd843503          	ld	a0,-40(s0)
    80005426:	00000097          	auipc	ra,0x0
    8000542a:	e34080e7          	jalr	-460(ra) # 8000525a <fdalloc>
    8000542e:	84aa                	mv	s1,a0
    return -1;
    80005430:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005432:	00054963          	bltz	a0,80005444 <sys_dup+0x42>
  filedup(f);
    80005436:	fd843503          	ld	a0,-40(s0)
    8000543a:	fffff097          	auipc	ra,0xfffff
    8000543e:	338080e7          	jalr	824(ra) # 80004772 <filedup>
  return fd;
    80005442:	87a6                	mv	a5,s1
}
    80005444:	853e                	mv	a0,a5
    80005446:	70a2                	ld	ra,40(sp)
    80005448:	7402                	ld	s0,32(sp)
    8000544a:	64e2                	ld	s1,24(sp)
    8000544c:	6145                	addi	sp,sp,48
    8000544e:	8082                	ret

0000000080005450 <sys_read>:
{
    80005450:	7179                	addi	sp,sp,-48
    80005452:	f406                	sd	ra,40(sp)
    80005454:	f022                	sd	s0,32(sp)
    80005456:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005458:	fe840613          	addi	a2,s0,-24
    8000545c:	4581                	li	a1,0
    8000545e:	4501                	li	a0,0
    80005460:	00000097          	auipc	ra,0x0
    80005464:	d92080e7          	jalr	-622(ra) # 800051f2 <argfd>
    return -1;
    80005468:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000546a:	04054163          	bltz	a0,800054ac <sys_read+0x5c>
    8000546e:	fe440593          	addi	a1,s0,-28
    80005472:	4509                	li	a0,2
    80005474:	ffffd097          	auipc	ra,0xffffd
    80005478:	78e080e7          	jalr	1934(ra) # 80002c02 <argint>
    return -1;
    8000547c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000547e:	02054763          	bltz	a0,800054ac <sys_read+0x5c>
    80005482:	fd840593          	addi	a1,s0,-40
    80005486:	4505                	li	a0,1
    80005488:	ffffd097          	auipc	ra,0xffffd
    8000548c:	79c080e7          	jalr	1948(ra) # 80002c24 <argaddr>
    return -1;
    80005490:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005492:	00054d63          	bltz	a0,800054ac <sys_read+0x5c>
  return fileread(f, p, n);
    80005496:	fe442603          	lw	a2,-28(s0)
    8000549a:	fd843583          	ld	a1,-40(s0)
    8000549e:	fe843503          	ld	a0,-24(s0)
    800054a2:	fffff097          	auipc	ra,0xfffff
    800054a6:	45c080e7          	jalr	1116(ra) # 800048fe <fileread>
    800054aa:	87aa                	mv	a5,a0
}
    800054ac:	853e                	mv	a0,a5
    800054ae:	70a2                	ld	ra,40(sp)
    800054b0:	7402                	ld	s0,32(sp)
    800054b2:	6145                	addi	sp,sp,48
    800054b4:	8082                	ret

00000000800054b6 <sys_write>:
{
    800054b6:	7179                	addi	sp,sp,-48
    800054b8:	f406                	sd	ra,40(sp)
    800054ba:	f022                	sd	s0,32(sp)
    800054bc:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054be:	fe840613          	addi	a2,s0,-24
    800054c2:	4581                	li	a1,0
    800054c4:	4501                	li	a0,0
    800054c6:	00000097          	auipc	ra,0x0
    800054ca:	d2c080e7          	jalr	-724(ra) # 800051f2 <argfd>
    return -1;
    800054ce:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054d0:	04054163          	bltz	a0,80005512 <sys_write+0x5c>
    800054d4:	fe440593          	addi	a1,s0,-28
    800054d8:	4509                	li	a0,2
    800054da:	ffffd097          	auipc	ra,0xffffd
    800054de:	728080e7          	jalr	1832(ra) # 80002c02 <argint>
    return -1;
    800054e2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054e4:	02054763          	bltz	a0,80005512 <sys_write+0x5c>
    800054e8:	fd840593          	addi	a1,s0,-40
    800054ec:	4505                	li	a0,1
    800054ee:	ffffd097          	auipc	ra,0xffffd
    800054f2:	736080e7          	jalr	1846(ra) # 80002c24 <argaddr>
    return -1;
    800054f6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054f8:	00054d63          	bltz	a0,80005512 <sys_write+0x5c>
  return filewrite(f, p, n);
    800054fc:	fe442603          	lw	a2,-28(s0)
    80005500:	fd843583          	ld	a1,-40(s0)
    80005504:	fe843503          	ld	a0,-24(s0)
    80005508:	fffff097          	auipc	ra,0xfffff
    8000550c:	4b8080e7          	jalr	1208(ra) # 800049c0 <filewrite>
    80005510:	87aa                	mv	a5,a0
}
    80005512:	853e                	mv	a0,a5
    80005514:	70a2                	ld	ra,40(sp)
    80005516:	7402                	ld	s0,32(sp)
    80005518:	6145                	addi	sp,sp,48
    8000551a:	8082                	ret

000000008000551c <sys_close>:
{
    8000551c:	1101                	addi	sp,sp,-32
    8000551e:	ec06                	sd	ra,24(sp)
    80005520:	e822                	sd	s0,16(sp)
    80005522:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005524:	fe040613          	addi	a2,s0,-32
    80005528:	fec40593          	addi	a1,s0,-20
    8000552c:	4501                	li	a0,0
    8000552e:	00000097          	auipc	ra,0x0
    80005532:	cc4080e7          	jalr	-828(ra) # 800051f2 <argfd>
    return -1;
    80005536:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005538:	02054463          	bltz	a0,80005560 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000553c:	ffffc097          	auipc	ra,0xffffc
    80005540:	4f2080e7          	jalr	1266(ra) # 80001a2e <myproc>
    80005544:	fec42783          	lw	a5,-20(s0)
    80005548:	07e9                	addi	a5,a5,26
    8000554a:	078e                	slli	a5,a5,0x3
    8000554c:	97aa                	add	a5,a5,a0
    8000554e:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005552:	fe043503          	ld	a0,-32(s0)
    80005556:	fffff097          	auipc	ra,0xfffff
    8000555a:	26e080e7          	jalr	622(ra) # 800047c4 <fileclose>
  return 0;
    8000555e:	4781                	li	a5,0
}
    80005560:	853e                	mv	a0,a5
    80005562:	60e2                	ld	ra,24(sp)
    80005564:	6442                	ld	s0,16(sp)
    80005566:	6105                	addi	sp,sp,32
    80005568:	8082                	ret

000000008000556a <sys_fstat>:
{
    8000556a:	1101                	addi	sp,sp,-32
    8000556c:	ec06                	sd	ra,24(sp)
    8000556e:	e822                	sd	s0,16(sp)
    80005570:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005572:	fe840613          	addi	a2,s0,-24
    80005576:	4581                	li	a1,0
    80005578:	4501                	li	a0,0
    8000557a:	00000097          	auipc	ra,0x0
    8000557e:	c78080e7          	jalr	-904(ra) # 800051f2 <argfd>
    return -1;
    80005582:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005584:	02054563          	bltz	a0,800055ae <sys_fstat+0x44>
    80005588:	fe040593          	addi	a1,s0,-32
    8000558c:	4505                	li	a0,1
    8000558e:	ffffd097          	auipc	ra,0xffffd
    80005592:	696080e7          	jalr	1686(ra) # 80002c24 <argaddr>
    return -1;
    80005596:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005598:	00054b63          	bltz	a0,800055ae <sys_fstat+0x44>
  return filestat(f, st);
    8000559c:	fe043583          	ld	a1,-32(s0)
    800055a0:	fe843503          	ld	a0,-24(s0)
    800055a4:	fffff097          	auipc	ra,0xfffff
    800055a8:	2e8080e7          	jalr	744(ra) # 8000488c <filestat>
    800055ac:	87aa                	mv	a5,a0
}
    800055ae:	853e                	mv	a0,a5
    800055b0:	60e2                	ld	ra,24(sp)
    800055b2:	6442                	ld	s0,16(sp)
    800055b4:	6105                	addi	sp,sp,32
    800055b6:	8082                	ret

00000000800055b8 <sys_link>:
{
    800055b8:	7169                	addi	sp,sp,-304
    800055ba:	f606                	sd	ra,296(sp)
    800055bc:	f222                	sd	s0,288(sp)
    800055be:	ee26                	sd	s1,280(sp)
    800055c0:	ea4a                	sd	s2,272(sp)
    800055c2:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800055c4:	08000613          	li	a2,128
    800055c8:	ed040593          	addi	a1,s0,-304
    800055cc:	4501                	li	a0,0
    800055ce:	ffffd097          	auipc	ra,0xffffd
    800055d2:	678080e7          	jalr	1656(ra) # 80002c46 <argstr>
    return -1;
    800055d6:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800055d8:	10054e63          	bltz	a0,800056f4 <sys_link+0x13c>
    800055dc:	08000613          	li	a2,128
    800055e0:	f5040593          	addi	a1,s0,-176
    800055e4:	4505                	li	a0,1
    800055e6:	ffffd097          	auipc	ra,0xffffd
    800055ea:	660080e7          	jalr	1632(ra) # 80002c46 <argstr>
    return -1;
    800055ee:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800055f0:	10054263          	bltz	a0,800056f4 <sys_link+0x13c>
  begin_op();
    800055f4:	fffff097          	auipc	ra,0xfffff
    800055f8:	cfe080e7          	jalr	-770(ra) # 800042f2 <begin_op>
  if((ip = namei(old)) == 0){
    800055fc:	ed040513          	addi	a0,s0,-304
    80005600:	fffff097          	auipc	ra,0xfffff
    80005604:	ae2080e7          	jalr	-1310(ra) # 800040e2 <namei>
    80005608:	84aa                	mv	s1,a0
    8000560a:	c551                	beqz	a0,80005696 <sys_link+0xde>
  ilock(ip);
    8000560c:	ffffe097          	auipc	ra,0xffffe
    80005610:	326080e7          	jalr	806(ra) # 80003932 <ilock>
  if(ip->type == T_DIR){
    80005614:	04449703          	lh	a4,68(s1)
    80005618:	4785                	li	a5,1
    8000561a:	08f70463          	beq	a4,a5,800056a2 <sys_link+0xea>
  ip->nlink++;
    8000561e:	04a4d783          	lhu	a5,74(s1)
    80005622:	2785                	addiw	a5,a5,1
    80005624:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005628:	8526                	mv	a0,s1
    8000562a:	ffffe097          	auipc	ra,0xffffe
    8000562e:	23e080e7          	jalr	574(ra) # 80003868 <iupdate>
  iunlock(ip);
    80005632:	8526                	mv	a0,s1
    80005634:	ffffe097          	auipc	ra,0xffffe
    80005638:	3c0080e7          	jalr	960(ra) # 800039f4 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000563c:	fd040593          	addi	a1,s0,-48
    80005640:	f5040513          	addi	a0,s0,-176
    80005644:	fffff097          	auipc	ra,0xfffff
    80005648:	abc080e7          	jalr	-1348(ra) # 80004100 <nameiparent>
    8000564c:	892a                	mv	s2,a0
    8000564e:	c935                	beqz	a0,800056c2 <sys_link+0x10a>
  ilock(dp);
    80005650:	ffffe097          	auipc	ra,0xffffe
    80005654:	2e2080e7          	jalr	738(ra) # 80003932 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005658:	00092703          	lw	a4,0(s2)
    8000565c:	409c                	lw	a5,0(s1)
    8000565e:	04f71d63          	bne	a4,a5,800056b8 <sys_link+0x100>
    80005662:	40d0                	lw	a2,4(s1)
    80005664:	fd040593          	addi	a1,s0,-48
    80005668:	854a                	mv	a0,s2
    8000566a:	fffff097          	auipc	ra,0xfffff
    8000566e:	9b6080e7          	jalr	-1610(ra) # 80004020 <dirlink>
    80005672:	04054363          	bltz	a0,800056b8 <sys_link+0x100>
  iunlockput(dp);
    80005676:	854a                	mv	a0,s2
    80005678:	ffffe097          	auipc	ra,0xffffe
    8000567c:	51c080e7          	jalr	1308(ra) # 80003b94 <iunlockput>
  iput(ip);
    80005680:	8526                	mv	a0,s1
    80005682:	ffffe097          	auipc	ra,0xffffe
    80005686:	46a080e7          	jalr	1130(ra) # 80003aec <iput>
  end_op();
    8000568a:	fffff097          	auipc	ra,0xfffff
    8000568e:	ce8080e7          	jalr	-792(ra) # 80004372 <end_op>
  return 0;
    80005692:	4781                	li	a5,0
    80005694:	a085                	j	800056f4 <sys_link+0x13c>
    end_op();
    80005696:	fffff097          	auipc	ra,0xfffff
    8000569a:	cdc080e7          	jalr	-804(ra) # 80004372 <end_op>
    return -1;
    8000569e:	57fd                	li	a5,-1
    800056a0:	a891                	j	800056f4 <sys_link+0x13c>
    iunlockput(ip);
    800056a2:	8526                	mv	a0,s1
    800056a4:	ffffe097          	auipc	ra,0xffffe
    800056a8:	4f0080e7          	jalr	1264(ra) # 80003b94 <iunlockput>
    end_op();
    800056ac:	fffff097          	auipc	ra,0xfffff
    800056b0:	cc6080e7          	jalr	-826(ra) # 80004372 <end_op>
    return -1;
    800056b4:	57fd                	li	a5,-1
    800056b6:	a83d                	j	800056f4 <sys_link+0x13c>
    iunlockput(dp);
    800056b8:	854a                	mv	a0,s2
    800056ba:	ffffe097          	auipc	ra,0xffffe
    800056be:	4da080e7          	jalr	1242(ra) # 80003b94 <iunlockput>
  ilock(ip);
    800056c2:	8526                	mv	a0,s1
    800056c4:	ffffe097          	auipc	ra,0xffffe
    800056c8:	26e080e7          	jalr	622(ra) # 80003932 <ilock>
  ip->nlink--;
    800056cc:	04a4d783          	lhu	a5,74(s1)
    800056d0:	37fd                	addiw	a5,a5,-1
    800056d2:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800056d6:	8526                	mv	a0,s1
    800056d8:	ffffe097          	auipc	ra,0xffffe
    800056dc:	190080e7          	jalr	400(ra) # 80003868 <iupdate>
  iunlockput(ip);
    800056e0:	8526                	mv	a0,s1
    800056e2:	ffffe097          	auipc	ra,0xffffe
    800056e6:	4b2080e7          	jalr	1202(ra) # 80003b94 <iunlockput>
  end_op();
    800056ea:	fffff097          	auipc	ra,0xfffff
    800056ee:	c88080e7          	jalr	-888(ra) # 80004372 <end_op>
  return -1;
    800056f2:	57fd                	li	a5,-1
}
    800056f4:	853e                	mv	a0,a5
    800056f6:	70b2                	ld	ra,296(sp)
    800056f8:	7412                	ld	s0,288(sp)
    800056fa:	64f2                	ld	s1,280(sp)
    800056fc:	6952                	ld	s2,272(sp)
    800056fe:	6155                	addi	sp,sp,304
    80005700:	8082                	ret

0000000080005702 <sys_unlink>:
{
    80005702:	7151                	addi	sp,sp,-240
    80005704:	f586                	sd	ra,232(sp)
    80005706:	f1a2                	sd	s0,224(sp)
    80005708:	eda6                	sd	s1,216(sp)
    8000570a:	e9ca                	sd	s2,208(sp)
    8000570c:	e5ce                	sd	s3,200(sp)
    8000570e:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005710:	08000613          	li	a2,128
    80005714:	f3040593          	addi	a1,s0,-208
    80005718:	4501                	li	a0,0
    8000571a:	ffffd097          	auipc	ra,0xffffd
    8000571e:	52c080e7          	jalr	1324(ra) # 80002c46 <argstr>
    80005722:	18054163          	bltz	a0,800058a4 <sys_unlink+0x1a2>
  begin_op();
    80005726:	fffff097          	auipc	ra,0xfffff
    8000572a:	bcc080e7          	jalr	-1076(ra) # 800042f2 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000572e:	fb040593          	addi	a1,s0,-80
    80005732:	f3040513          	addi	a0,s0,-208
    80005736:	fffff097          	auipc	ra,0xfffff
    8000573a:	9ca080e7          	jalr	-1590(ra) # 80004100 <nameiparent>
    8000573e:	84aa                	mv	s1,a0
    80005740:	c979                	beqz	a0,80005816 <sys_unlink+0x114>
  ilock(dp);
    80005742:	ffffe097          	auipc	ra,0xffffe
    80005746:	1f0080e7          	jalr	496(ra) # 80003932 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000574a:	00003597          	auipc	a1,0x3
    8000574e:	fd658593          	addi	a1,a1,-42 # 80008720 <syscalls+0x2e0>
    80005752:	fb040513          	addi	a0,s0,-80
    80005756:	ffffe097          	auipc	ra,0xffffe
    8000575a:	6a0080e7          	jalr	1696(ra) # 80003df6 <namecmp>
    8000575e:	14050a63          	beqz	a0,800058b2 <sys_unlink+0x1b0>
    80005762:	00003597          	auipc	a1,0x3
    80005766:	fc658593          	addi	a1,a1,-58 # 80008728 <syscalls+0x2e8>
    8000576a:	fb040513          	addi	a0,s0,-80
    8000576e:	ffffe097          	auipc	ra,0xffffe
    80005772:	688080e7          	jalr	1672(ra) # 80003df6 <namecmp>
    80005776:	12050e63          	beqz	a0,800058b2 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000577a:	f2c40613          	addi	a2,s0,-212
    8000577e:	fb040593          	addi	a1,s0,-80
    80005782:	8526                	mv	a0,s1
    80005784:	ffffe097          	auipc	ra,0xffffe
    80005788:	68c080e7          	jalr	1676(ra) # 80003e10 <dirlookup>
    8000578c:	892a                	mv	s2,a0
    8000578e:	12050263          	beqz	a0,800058b2 <sys_unlink+0x1b0>
  ilock(ip);
    80005792:	ffffe097          	auipc	ra,0xffffe
    80005796:	1a0080e7          	jalr	416(ra) # 80003932 <ilock>
  if(ip->nlink < 1)
    8000579a:	04a91783          	lh	a5,74(s2)
    8000579e:	08f05263          	blez	a5,80005822 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800057a2:	04491703          	lh	a4,68(s2)
    800057a6:	4785                	li	a5,1
    800057a8:	08f70563          	beq	a4,a5,80005832 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800057ac:	4641                	li	a2,16
    800057ae:	4581                	li	a1,0
    800057b0:	fc040513          	addi	a0,s0,-64
    800057b4:	ffffb097          	auipc	ra,0xffffb
    800057b8:	5aa080e7          	jalr	1450(ra) # 80000d5e <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800057bc:	4741                	li	a4,16
    800057be:	f2c42683          	lw	a3,-212(s0)
    800057c2:	fc040613          	addi	a2,s0,-64
    800057c6:	4581                	li	a1,0
    800057c8:	8526                	mv	a0,s1
    800057ca:	ffffe097          	auipc	ra,0xffffe
    800057ce:	512080e7          	jalr	1298(ra) # 80003cdc <writei>
    800057d2:	47c1                	li	a5,16
    800057d4:	0af51563          	bne	a0,a5,8000587e <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800057d8:	04491703          	lh	a4,68(s2)
    800057dc:	4785                	li	a5,1
    800057de:	0af70863          	beq	a4,a5,8000588e <sys_unlink+0x18c>
  iunlockput(dp);
    800057e2:	8526                	mv	a0,s1
    800057e4:	ffffe097          	auipc	ra,0xffffe
    800057e8:	3b0080e7          	jalr	944(ra) # 80003b94 <iunlockput>
  ip->nlink--;
    800057ec:	04a95783          	lhu	a5,74(s2)
    800057f0:	37fd                	addiw	a5,a5,-1
    800057f2:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800057f6:	854a                	mv	a0,s2
    800057f8:	ffffe097          	auipc	ra,0xffffe
    800057fc:	070080e7          	jalr	112(ra) # 80003868 <iupdate>
  iunlockput(ip);
    80005800:	854a                	mv	a0,s2
    80005802:	ffffe097          	auipc	ra,0xffffe
    80005806:	392080e7          	jalr	914(ra) # 80003b94 <iunlockput>
  end_op();
    8000580a:	fffff097          	auipc	ra,0xfffff
    8000580e:	b68080e7          	jalr	-1176(ra) # 80004372 <end_op>
  return 0;
    80005812:	4501                	li	a0,0
    80005814:	a84d                	j	800058c6 <sys_unlink+0x1c4>
    end_op();
    80005816:	fffff097          	auipc	ra,0xfffff
    8000581a:	b5c080e7          	jalr	-1188(ra) # 80004372 <end_op>
    return -1;
    8000581e:	557d                	li	a0,-1
    80005820:	a05d                	j	800058c6 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005822:	00003517          	auipc	a0,0x3
    80005826:	f2e50513          	addi	a0,a0,-210 # 80008750 <syscalls+0x310>
    8000582a:	ffffb097          	auipc	ra,0xffffb
    8000582e:	da6080e7          	jalr	-602(ra) # 800005d0 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005832:	04c92703          	lw	a4,76(s2)
    80005836:	02000793          	li	a5,32
    8000583a:	f6e7f9e3          	bgeu	a5,a4,800057ac <sys_unlink+0xaa>
    8000583e:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005842:	4741                	li	a4,16
    80005844:	86ce                	mv	a3,s3
    80005846:	f1840613          	addi	a2,s0,-232
    8000584a:	4581                	li	a1,0
    8000584c:	854a                	mv	a0,s2
    8000584e:	ffffe097          	auipc	ra,0xffffe
    80005852:	398080e7          	jalr	920(ra) # 80003be6 <readi>
    80005856:	47c1                	li	a5,16
    80005858:	00f51b63          	bne	a0,a5,8000586e <sys_unlink+0x16c>
    if(de.inum != 0)
    8000585c:	f1845783          	lhu	a5,-232(s0)
    80005860:	e7a1                	bnez	a5,800058a8 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005862:	29c1                	addiw	s3,s3,16
    80005864:	04c92783          	lw	a5,76(s2)
    80005868:	fcf9ede3          	bltu	s3,a5,80005842 <sys_unlink+0x140>
    8000586c:	b781                	j	800057ac <sys_unlink+0xaa>
      panic("isdirempty: readi");
    8000586e:	00003517          	auipc	a0,0x3
    80005872:	efa50513          	addi	a0,a0,-262 # 80008768 <syscalls+0x328>
    80005876:	ffffb097          	auipc	ra,0xffffb
    8000587a:	d5a080e7          	jalr	-678(ra) # 800005d0 <panic>
    panic("unlink: writei");
    8000587e:	00003517          	auipc	a0,0x3
    80005882:	f0250513          	addi	a0,a0,-254 # 80008780 <syscalls+0x340>
    80005886:	ffffb097          	auipc	ra,0xffffb
    8000588a:	d4a080e7          	jalr	-694(ra) # 800005d0 <panic>
    dp->nlink--;
    8000588e:	04a4d783          	lhu	a5,74(s1)
    80005892:	37fd                	addiw	a5,a5,-1
    80005894:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005898:	8526                	mv	a0,s1
    8000589a:	ffffe097          	auipc	ra,0xffffe
    8000589e:	fce080e7          	jalr	-50(ra) # 80003868 <iupdate>
    800058a2:	b781                	j	800057e2 <sys_unlink+0xe0>
    return -1;
    800058a4:	557d                	li	a0,-1
    800058a6:	a005                	j	800058c6 <sys_unlink+0x1c4>
    iunlockput(ip);
    800058a8:	854a                	mv	a0,s2
    800058aa:	ffffe097          	auipc	ra,0xffffe
    800058ae:	2ea080e7          	jalr	746(ra) # 80003b94 <iunlockput>
  iunlockput(dp);
    800058b2:	8526                	mv	a0,s1
    800058b4:	ffffe097          	auipc	ra,0xffffe
    800058b8:	2e0080e7          	jalr	736(ra) # 80003b94 <iunlockput>
  end_op();
    800058bc:	fffff097          	auipc	ra,0xfffff
    800058c0:	ab6080e7          	jalr	-1354(ra) # 80004372 <end_op>
  return -1;
    800058c4:	557d                	li	a0,-1
}
    800058c6:	70ae                	ld	ra,232(sp)
    800058c8:	740e                	ld	s0,224(sp)
    800058ca:	64ee                	ld	s1,216(sp)
    800058cc:	694e                	ld	s2,208(sp)
    800058ce:	69ae                	ld	s3,200(sp)
    800058d0:	616d                	addi	sp,sp,240
    800058d2:	8082                	ret

00000000800058d4 <sys_open>:

uint64
sys_open(void)
{
    800058d4:	7131                	addi	sp,sp,-192
    800058d6:	fd06                	sd	ra,184(sp)
    800058d8:	f922                	sd	s0,176(sp)
    800058da:	f526                	sd	s1,168(sp)
    800058dc:	f14a                	sd	s2,160(sp)
    800058de:	ed4e                	sd	s3,152(sp)
    800058e0:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800058e2:	08000613          	li	a2,128
    800058e6:	f5040593          	addi	a1,s0,-176
    800058ea:	4501                	li	a0,0
    800058ec:	ffffd097          	auipc	ra,0xffffd
    800058f0:	35a080e7          	jalr	858(ra) # 80002c46 <argstr>
    return -1;
    800058f4:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800058f6:	0c054163          	bltz	a0,800059b8 <sys_open+0xe4>
    800058fa:	f4c40593          	addi	a1,s0,-180
    800058fe:	4505                	li	a0,1
    80005900:	ffffd097          	auipc	ra,0xffffd
    80005904:	302080e7          	jalr	770(ra) # 80002c02 <argint>
    80005908:	0a054863          	bltz	a0,800059b8 <sys_open+0xe4>

  begin_op();
    8000590c:	fffff097          	auipc	ra,0xfffff
    80005910:	9e6080e7          	jalr	-1562(ra) # 800042f2 <begin_op>

  if(omode & O_CREATE){
    80005914:	f4c42783          	lw	a5,-180(s0)
    80005918:	2007f793          	andi	a5,a5,512
    8000591c:	cbdd                	beqz	a5,800059d2 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    8000591e:	4681                	li	a3,0
    80005920:	4601                	li	a2,0
    80005922:	4589                	li	a1,2
    80005924:	f5040513          	addi	a0,s0,-176
    80005928:	00000097          	auipc	ra,0x0
    8000592c:	974080e7          	jalr	-1676(ra) # 8000529c <create>
    80005930:	892a                	mv	s2,a0
    if(ip == 0){
    80005932:	c959                	beqz	a0,800059c8 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005934:	04491703          	lh	a4,68(s2)
    80005938:	478d                	li	a5,3
    8000593a:	00f71763          	bne	a4,a5,80005948 <sys_open+0x74>
    8000593e:	04695703          	lhu	a4,70(s2)
    80005942:	47a5                	li	a5,9
    80005944:	0ce7ec63          	bltu	a5,a4,80005a1c <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005948:	fffff097          	auipc	ra,0xfffff
    8000594c:	dc0080e7          	jalr	-576(ra) # 80004708 <filealloc>
    80005950:	89aa                	mv	s3,a0
    80005952:	10050263          	beqz	a0,80005a56 <sys_open+0x182>
    80005956:	00000097          	auipc	ra,0x0
    8000595a:	904080e7          	jalr	-1788(ra) # 8000525a <fdalloc>
    8000595e:	84aa                	mv	s1,a0
    80005960:	0e054663          	bltz	a0,80005a4c <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005964:	04491703          	lh	a4,68(s2)
    80005968:	478d                	li	a5,3
    8000596a:	0cf70463          	beq	a4,a5,80005a32 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    8000596e:	4789                	li	a5,2
    80005970:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005974:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005978:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    8000597c:	f4c42783          	lw	a5,-180(s0)
    80005980:	0017c713          	xori	a4,a5,1
    80005984:	8b05                	andi	a4,a4,1
    80005986:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    8000598a:	0037f713          	andi	a4,a5,3
    8000598e:	00e03733          	snez	a4,a4
    80005992:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005996:	4007f793          	andi	a5,a5,1024
    8000599a:	c791                	beqz	a5,800059a6 <sys_open+0xd2>
    8000599c:	04491703          	lh	a4,68(s2)
    800059a0:	4789                	li	a5,2
    800059a2:	08f70f63          	beq	a4,a5,80005a40 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800059a6:	854a                	mv	a0,s2
    800059a8:	ffffe097          	auipc	ra,0xffffe
    800059ac:	04c080e7          	jalr	76(ra) # 800039f4 <iunlock>
  end_op();
    800059b0:	fffff097          	auipc	ra,0xfffff
    800059b4:	9c2080e7          	jalr	-1598(ra) # 80004372 <end_op>

  return fd;
}
    800059b8:	8526                	mv	a0,s1
    800059ba:	70ea                	ld	ra,184(sp)
    800059bc:	744a                	ld	s0,176(sp)
    800059be:	74aa                	ld	s1,168(sp)
    800059c0:	790a                	ld	s2,160(sp)
    800059c2:	69ea                	ld	s3,152(sp)
    800059c4:	6129                	addi	sp,sp,192
    800059c6:	8082                	ret
      end_op();
    800059c8:	fffff097          	auipc	ra,0xfffff
    800059cc:	9aa080e7          	jalr	-1622(ra) # 80004372 <end_op>
      return -1;
    800059d0:	b7e5                	j	800059b8 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800059d2:	f5040513          	addi	a0,s0,-176
    800059d6:	ffffe097          	auipc	ra,0xffffe
    800059da:	70c080e7          	jalr	1804(ra) # 800040e2 <namei>
    800059de:	892a                	mv	s2,a0
    800059e0:	c905                	beqz	a0,80005a10 <sys_open+0x13c>
    ilock(ip);
    800059e2:	ffffe097          	auipc	ra,0xffffe
    800059e6:	f50080e7          	jalr	-176(ra) # 80003932 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800059ea:	04491703          	lh	a4,68(s2)
    800059ee:	4785                	li	a5,1
    800059f0:	f4f712e3          	bne	a4,a5,80005934 <sys_open+0x60>
    800059f4:	f4c42783          	lw	a5,-180(s0)
    800059f8:	dba1                	beqz	a5,80005948 <sys_open+0x74>
      iunlockput(ip);
    800059fa:	854a                	mv	a0,s2
    800059fc:	ffffe097          	auipc	ra,0xffffe
    80005a00:	198080e7          	jalr	408(ra) # 80003b94 <iunlockput>
      end_op();
    80005a04:	fffff097          	auipc	ra,0xfffff
    80005a08:	96e080e7          	jalr	-1682(ra) # 80004372 <end_op>
      return -1;
    80005a0c:	54fd                	li	s1,-1
    80005a0e:	b76d                	j	800059b8 <sys_open+0xe4>
      end_op();
    80005a10:	fffff097          	auipc	ra,0xfffff
    80005a14:	962080e7          	jalr	-1694(ra) # 80004372 <end_op>
      return -1;
    80005a18:	54fd                	li	s1,-1
    80005a1a:	bf79                	j	800059b8 <sys_open+0xe4>
    iunlockput(ip);
    80005a1c:	854a                	mv	a0,s2
    80005a1e:	ffffe097          	auipc	ra,0xffffe
    80005a22:	176080e7          	jalr	374(ra) # 80003b94 <iunlockput>
    end_op();
    80005a26:	fffff097          	auipc	ra,0xfffff
    80005a2a:	94c080e7          	jalr	-1716(ra) # 80004372 <end_op>
    return -1;
    80005a2e:	54fd                	li	s1,-1
    80005a30:	b761                	j	800059b8 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005a32:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005a36:	04691783          	lh	a5,70(s2)
    80005a3a:	02f99223          	sh	a5,36(s3)
    80005a3e:	bf2d                	j	80005978 <sys_open+0xa4>
    itrunc(ip);
    80005a40:	854a                	mv	a0,s2
    80005a42:	ffffe097          	auipc	ra,0xffffe
    80005a46:	ffe080e7          	jalr	-2(ra) # 80003a40 <itrunc>
    80005a4a:	bfb1                	j	800059a6 <sys_open+0xd2>
      fileclose(f);
    80005a4c:	854e                	mv	a0,s3
    80005a4e:	fffff097          	auipc	ra,0xfffff
    80005a52:	d76080e7          	jalr	-650(ra) # 800047c4 <fileclose>
    iunlockput(ip);
    80005a56:	854a                	mv	a0,s2
    80005a58:	ffffe097          	auipc	ra,0xffffe
    80005a5c:	13c080e7          	jalr	316(ra) # 80003b94 <iunlockput>
    end_op();
    80005a60:	fffff097          	auipc	ra,0xfffff
    80005a64:	912080e7          	jalr	-1774(ra) # 80004372 <end_op>
    return -1;
    80005a68:	54fd                	li	s1,-1
    80005a6a:	b7b9                	j	800059b8 <sys_open+0xe4>

0000000080005a6c <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005a6c:	7175                	addi	sp,sp,-144
    80005a6e:	e506                	sd	ra,136(sp)
    80005a70:	e122                	sd	s0,128(sp)
    80005a72:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005a74:	fffff097          	auipc	ra,0xfffff
    80005a78:	87e080e7          	jalr	-1922(ra) # 800042f2 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005a7c:	08000613          	li	a2,128
    80005a80:	f7040593          	addi	a1,s0,-144
    80005a84:	4501                	li	a0,0
    80005a86:	ffffd097          	auipc	ra,0xffffd
    80005a8a:	1c0080e7          	jalr	448(ra) # 80002c46 <argstr>
    80005a8e:	02054963          	bltz	a0,80005ac0 <sys_mkdir+0x54>
    80005a92:	4681                	li	a3,0
    80005a94:	4601                	li	a2,0
    80005a96:	4585                	li	a1,1
    80005a98:	f7040513          	addi	a0,s0,-144
    80005a9c:	00000097          	auipc	ra,0x0
    80005aa0:	800080e7          	jalr	-2048(ra) # 8000529c <create>
    80005aa4:	cd11                	beqz	a0,80005ac0 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005aa6:	ffffe097          	auipc	ra,0xffffe
    80005aaa:	0ee080e7          	jalr	238(ra) # 80003b94 <iunlockput>
  end_op();
    80005aae:	fffff097          	auipc	ra,0xfffff
    80005ab2:	8c4080e7          	jalr	-1852(ra) # 80004372 <end_op>
  return 0;
    80005ab6:	4501                	li	a0,0
}
    80005ab8:	60aa                	ld	ra,136(sp)
    80005aba:	640a                	ld	s0,128(sp)
    80005abc:	6149                	addi	sp,sp,144
    80005abe:	8082                	ret
    end_op();
    80005ac0:	fffff097          	auipc	ra,0xfffff
    80005ac4:	8b2080e7          	jalr	-1870(ra) # 80004372 <end_op>
    return -1;
    80005ac8:	557d                	li	a0,-1
    80005aca:	b7fd                	j	80005ab8 <sys_mkdir+0x4c>

0000000080005acc <sys_mknod>:

uint64
sys_mknod(void)
{
    80005acc:	7135                	addi	sp,sp,-160
    80005ace:	ed06                	sd	ra,152(sp)
    80005ad0:	e922                	sd	s0,144(sp)
    80005ad2:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005ad4:	fffff097          	auipc	ra,0xfffff
    80005ad8:	81e080e7          	jalr	-2018(ra) # 800042f2 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005adc:	08000613          	li	a2,128
    80005ae0:	f7040593          	addi	a1,s0,-144
    80005ae4:	4501                	li	a0,0
    80005ae6:	ffffd097          	auipc	ra,0xffffd
    80005aea:	160080e7          	jalr	352(ra) # 80002c46 <argstr>
    80005aee:	04054a63          	bltz	a0,80005b42 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005af2:	f6c40593          	addi	a1,s0,-148
    80005af6:	4505                	li	a0,1
    80005af8:	ffffd097          	auipc	ra,0xffffd
    80005afc:	10a080e7          	jalr	266(ra) # 80002c02 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005b00:	04054163          	bltz	a0,80005b42 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005b04:	f6840593          	addi	a1,s0,-152
    80005b08:	4509                	li	a0,2
    80005b0a:	ffffd097          	auipc	ra,0xffffd
    80005b0e:	0f8080e7          	jalr	248(ra) # 80002c02 <argint>
     argint(1, &major) < 0 ||
    80005b12:	02054863          	bltz	a0,80005b42 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005b16:	f6841683          	lh	a3,-152(s0)
    80005b1a:	f6c41603          	lh	a2,-148(s0)
    80005b1e:	458d                	li	a1,3
    80005b20:	f7040513          	addi	a0,s0,-144
    80005b24:	fffff097          	auipc	ra,0xfffff
    80005b28:	778080e7          	jalr	1912(ra) # 8000529c <create>
     argint(2, &minor) < 0 ||
    80005b2c:	c919                	beqz	a0,80005b42 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005b2e:	ffffe097          	auipc	ra,0xffffe
    80005b32:	066080e7          	jalr	102(ra) # 80003b94 <iunlockput>
  end_op();
    80005b36:	fffff097          	auipc	ra,0xfffff
    80005b3a:	83c080e7          	jalr	-1988(ra) # 80004372 <end_op>
  return 0;
    80005b3e:	4501                	li	a0,0
    80005b40:	a031                	j	80005b4c <sys_mknod+0x80>
    end_op();
    80005b42:	fffff097          	auipc	ra,0xfffff
    80005b46:	830080e7          	jalr	-2000(ra) # 80004372 <end_op>
    return -1;
    80005b4a:	557d                	li	a0,-1
}
    80005b4c:	60ea                	ld	ra,152(sp)
    80005b4e:	644a                	ld	s0,144(sp)
    80005b50:	610d                	addi	sp,sp,160
    80005b52:	8082                	ret

0000000080005b54 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005b54:	7135                	addi	sp,sp,-160
    80005b56:	ed06                	sd	ra,152(sp)
    80005b58:	e922                	sd	s0,144(sp)
    80005b5a:	e526                	sd	s1,136(sp)
    80005b5c:	e14a                	sd	s2,128(sp)
    80005b5e:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005b60:	ffffc097          	auipc	ra,0xffffc
    80005b64:	ece080e7          	jalr	-306(ra) # 80001a2e <myproc>
    80005b68:	892a                	mv	s2,a0
  
  begin_op();
    80005b6a:	ffffe097          	auipc	ra,0xffffe
    80005b6e:	788080e7          	jalr	1928(ra) # 800042f2 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005b72:	08000613          	li	a2,128
    80005b76:	f6040593          	addi	a1,s0,-160
    80005b7a:	4501                	li	a0,0
    80005b7c:	ffffd097          	auipc	ra,0xffffd
    80005b80:	0ca080e7          	jalr	202(ra) # 80002c46 <argstr>
    80005b84:	04054b63          	bltz	a0,80005bda <sys_chdir+0x86>
    80005b88:	f6040513          	addi	a0,s0,-160
    80005b8c:	ffffe097          	auipc	ra,0xffffe
    80005b90:	556080e7          	jalr	1366(ra) # 800040e2 <namei>
    80005b94:	84aa                	mv	s1,a0
    80005b96:	c131                	beqz	a0,80005bda <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005b98:	ffffe097          	auipc	ra,0xffffe
    80005b9c:	d9a080e7          	jalr	-614(ra) # 80003932 <ilock>
  if(ip->type != T_DIR){
    80005ba0:	04449703          	lh	a4,68(s1)
    80005ba4:	4785                	li	a5,1
    80005ba6:	04f71063          	bne	a4,a5,80005be6 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005baa:	8526                	mv	a0,s1
    80005bac:	ffffe097          	auipc	ra,0xffffe
    80005bb0:	e48080e7          	jalr	-440(ra) # 800039f4 <iunlock>
  iput(p->cwd);
    80005bb4:	15093503          	ld	a0,336(s2)
    80005bb8:	ffffe097          	auipc	ra,0xffffe
    80005bbc:	f34080e7          	jalr	-204(ra) # 80003aec <iput>
  end_op();
    80005bc0:	ffffe097          	auipc	ra,0xffffe
    80005bc4:	7b2080e7          	jalr	1970(ra) # 80004372 <end_op>
  p->cwd = ip;
    80005bc8:	14993823          	sd	s1,336(s2)
  return 0;
    80005bcc:	4501                	li	a0,0
}
    80005bce:	60ea                	ld	ra,152(sp)
    80005bd0:	644a                	ld	s0,144(sp)
    80005bd2:	64aa                	ld	s1,136(sp)
    80005bd4:	690a                	ld	s2,128(sp)
    80005bd6:	610d                	addi	sp,sp,160
    80005bd8:	8082                	ret
    end_op();
    80005bda:	ffffe097          	auipc	ra,0xffffe
    80005bde:	798080e7          	jalr	1944(ra) # 80004372 <end_op>
    return -1;
    80005be2:	557d                	li	a0,-1
    80005be4:	b7ed                	j	80005bce <sys_chdir+0x7a>
    iunlockput(ip);
    80005be6:	8526                	mv	a0,s1
    80005be8:	ffffe097          	auipc	ra,0xffffe
    80005bec:	fac080e7          	jalr	-84(ra) # 80003b94 <iunlockput>
    end_op();
    80005bf0:	ffffe097          	auipc	ra,0xffffe
    80005bf4:	782080e7          	jalr	1922(ra) # 80004372 <end_op>
    return -1;
    80005bf8:	557d                	li	a0,-1
    80005bfa:	bfd1                	j	80005bce <sys_chdir+0x7a>

0000000080005bfc <sys_exec>:

uint64
sys_exec(void)
{
    80005bfc:	7145                	addi	sp,sp,-464
    80005bfe:	e786                	sd	ra,456(sp)
    80005c00:	e3a2                	sd	s0,448(sp)
    80005c02:	ff26                	sd	s1,440(sp)
    80005c04:	fb4a                	sd	s2,432(sp)
    80005c06:	f74e                	sd	s3,424(sp)
    80005c08:	f352                	sd	s4,416(sp)
    80005c0a:	ef56                	sd	s5,408(sp)
    80005c0c:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005c0e:	08000613          	li	a2,128
    80005c12:	f4040593          	addi	a1,s0,-192
    80005c16:	4501                	li	a0,0
    80005c18:	ffffd097          	auipc	ra,0xffffd
    80005c1c:	02e080e7          	jalr	46(ra) # 80002c46 <argstr>
    return -1;
    80005c20:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005c22:	0c054a63          	bltz	a0,80005cf6 <sys_exec+0xfa>
    80005c26:	e3840593          	addi	a1,s0,-456
    80005c2a:	4505                	li	a0,1
    80005c2c:	ffffd097          	auipc	ra,0xffffd
    80005c30:	ff8080e7          	jalr	-8(ra) # 80002c24 <argaddr>
    80005c34:	0c054163          	bltz	a0,80005cf6 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005c38:	10000613          	li	a2,256
    80005c3c:	4581                	li	a1,0
    80005c3e:	e4040513          	addi	a0,s0,-448
    80005c42:	ffffb097          	auipc	ra,0xffffb
    80005c46:	11c080e7          	jalr	284(ra) # 80000d5e <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005c4a:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005c4e:	89a6                	mv	s3,s1
    80005c50:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005c52:	02000a13          	li	s4,32
    80005c56:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005c5a:	00391793          	slli	a5,s2,0x3
    80005c5e:	e3040593          	addi	a1,s0,-464
    80005c62:	e3843503          	ld	a0,-456(s0)
    80005c66:	953e                	add	a0,a0,a5
    80005c68:	ffffd097          	auipc	ra,0xffffd
    80005c6c:	f00080e7          	jalr	-256(ra) # 80002b68 <fetchaddr>
    80005c70:	02054a63          	bltz	a0,80005ca4 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005c74:	e3043783          	ld	a5,-464(s0)
    80005c78:	c3b9                	beqz	a5,80005cbe <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005c7a:	ffffb097          	auipc	ra,0xffffb
    80005c7e:	ef8080e7          	jalr	-264(ra) # 80000b72 <kalloc>
    80005c82:	85aa                	mv	a1,a0
    80005c84:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005c88:	cd11                	beqz	a0,80005ca4 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005c8a:	6605                	lui	a2,0x1
    80005c8c:	e3043503          	ld	a0,-464(s0)
    80005c90:	ffffd097          	auipc	ra,0xffffd
    80005c94:	f2a080e7          	jalr	-214(ra) # 80002bba <fetchstr>
    80005c98:	00054663          	bltz	a0,80005ca4 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005c9c:	0905                	addi	s2,s2,1
    80005c9e:	09a1                	addi	s3,s3,8
    80005ca0:	fb491be3          	bne	s2,s4,80005c56 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ca4:	10048913          	addi	s2,s1,256
    80005ca8:	6088                	ld	a0,0(s1)
    80005caa:	c529                	beqz	a0,80005cf4 <sys_exec+0xf8>
    kfree(argv[i]);
    80005cac:	ffffb097          	auipc	ra,0xffffb
    80005cb0:	dca080e7          	jalr	-566(ra) # 80000a76 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005cb4:	04a1                	addi	s1,s1,8
    80005cb6:	ff2499e3          	bne	s1,s2,80005ca8 <sys_exec+0xac>
  return -1;
    80005cba:	597d                	li	s2,-1
    80005cbc:	a82d                	j	80005cf6 <sys_exec+0xfa>
      argv[i] = 0;
    80005cbe:	0a8e                	slli	s5,s5,0x3
    80005cc0:	fc040793          	addi	a5,s0,-64
    80005cc4:	9abe                	add	s5,s5,a5
    80005cc6:	e80ab023          	sd	zero,-384(s5) # ffffffffffffee80 <end+0xffffffff7ffd3e80>
  int ret = exec(path, argv);
    80005cca:	e4040593          	addi	a1,s0,-448
    80005cce:	f4040513          	addi	a0,s0,-192
    80005cd2:	fffff097          	auipc	ra,0xfffff
    80005cd6:	178080e7          	jalr	376(ra) # 80004e4a <exec>
    80005cda:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005cdc:	10048993          	addi	s3,s1,256
    80005ce0:	6088                	ld	a0,0(s1)
    80005ce2:	c911                	beqz	a0,80005cf6 <sys_exec+0xfa>
    kfree(argv[i]);
    80005ce4:	ffffb097          	auipc	ra,0xffffb
    80005ce8:	d92080e7          	jalr	-622(ra) # 80000a76 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005cec:	04a1                	addi	s1,s1,8
    80005cee:	ff3499e3          	bne	s1,s3,80005ce0 <sys_exec+0xe4>
    80005cf2:	a011                	j	80005cf6 <sys_exec+0xfa>
  return -1;
    80005cf4:	597d                	li	s2,-1
}
    80005cf6:	854a                	mv	a0,s2
    80005cf8:	60be                	ld	ra,456(sp)
    80005cfa:	641e                	ld	s0,448(sp)
    80005cfc:	74fa                	ld	s1,440(sp)
    80005cfe:	795a                	ld	s2,432(sp)
    80005d00:	79ba                	ld	s3,424(sp)
    80005d02:	7a1a                	ld	s4,416(sp)
    80005d04:	6afa                	ld	s5,408(sp)
    80005d06:	6179                	addi	sp,sp,464
    80005d08:	8082                	ret

0000000080005d0a <sys_pipe>:

uint64
sys_pipe(void)
{
    80005d0a:	7139                	addi	sp,sp,-64
    80005d0c:	fc06                	sd	ra,56(sp)
    80005d0e:	f822                	sd	s0,48(sp)
    80005d10:	f426                	sd	s1,40(sp)
    80005d12:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005d14:	ffffc097          	auipc	ra,0xffffc
    80005d18:	d1a080e7          	jalr	-742(ra) # 80001a2e <myproc>
    80005d1c:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005d1e:	fd840593          	addi	a1,s0,-40
    80005d22:	4501                	li	a0,0
    80005d24:	ffffd097          	auipc	ra,0xffffd
    80005d28:	f00080e7          	jalr	-256(ra) # 80002c24 <argaddr>
    return -1;
    80005d2c:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005d2e:	0e054063          	bltz	a0,80005e0e <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005d32:	fc840593          	addi	a1,s0,-56
    80005d36:	fd040513          	addi	a0,s0,-48
    80005d3a:	fffff097          	auipc	ra,0xfffff
    80005d3e:	de0080e7          	jalr	-544(ra) # 80004b1a <pipealloc>
    return -1;
    80005d42:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005d44:	0c054563          	bltz	a0,80005e0e <sys_pipe+0x104>
  fd0 = -1;
    80005d48:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005d4c:	fd043503          	ld	a0,-48(s0)
    80005d50:	fffff097          	auipc	ra,0xfffff
    80005d54:	50a080e7          	jalr	1290(ra) # 8000525a <fdalloc>
    80005d58:	fca42223          	sw	a0,-60(s0)
    80005d5c:	08054c63          	bltz	a0,80005df4 <sys_pipe+0xea>
    80005d60:	fc843503          	ld	a0,-56(s0)
    80005d64:	fffff097          	auipc	ra,0xfffff
    80005d68:	4f6080e7          	jalr	1270(ra) # 8000525a <fdalloc>
    80005d6c:	fca42023          	sw	a0,-64(s0)
    80005d70:	06054863          	bltz	a0,80005de0 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005d74:	4691                	li	a3,4
    80005d76:	fc440613          	addi	a2,s0,-60
    80005d7a:	fd843583          	ld	a1,-40(s0)
    80005d7e:	68a8                	ld	a0,80(s1)
    80005d80:	ffffc097          	auipc	ra,0xffffc
    80005d84:	9a0080e7          	jalr	-1632(ra) # 80001720 <copyout>
    80005d88:	02054063          	bltz	a0,80005da8 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005d8c:	4691                	li	a3,4
    80005d8e:	fc040613          	addi	a2,s0,-64
    80005d92:	fd843583          	ld	a1,-40(s0)
    80005d96:	0591                	addi	a1,a1,4
    80005d98:	68a8                	ld	a0,80(s1)
    80005d9a:	ffffc097          	auipc	ra,0xffffc
    80005d9e:	986080e7          	jalr	-1658(ra) # 80001720 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005da2:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005da4:	06055563          	bgez	a0,80005e0e <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005da8:	fc442783          	lw	a5,-60(s0)
    80005dac:	07e9                	addi	a5,a5,26
    80005dae:	078e                	slli	a5,a5,0x3
    80005db0:	97a6                	add	a5,a5,s1
    80005db2:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005db6:	fc042503          	lw	a0,-64(s0)
    80005dba:	0569                	addi	a0,a0,26
    80005dbc:	050e                	slli	a0,a0,0x3
    80005dbe:	9526                	add	a0,a0,s1
    80005dc0:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005dc4:	fd043503          	ld	a0,-48(s0)
    80005dc8:	fffff097          	auipc	ra,0xfffff
    80005dcc:	9fc080e7          	jalr	-1540(ra) # 800047c4 <fileclose>
    fileclose(wf);
    80005dd0:	fc843503          	ld	a0,-56(s0)
    80005dd4:	fffff097          	auipc	ra,0xfffff
    80005dd8:	9f0080e7          	jalr	-1552(ra) # 800047c4 <fileclose>
    return -1;
    80005ddc:	57fd                	li	a5,-1
    80005dde:	a805                	j	80005e0e <sys_pipe+0x104>
    if(fd0 >= 0)
    80005de0:	fc442783          	lw	a5,-60(s0)
    80005de4:	0007c863          	bltz	a5,80005df4 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005de8:	01a78513          	addi	a0,a5,26
    80005dec:	050e                	slli	a0,a0,0x3
    80005dee:	9526                	add	a0,a0,s1
    80005df0:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005df4:	fd043503          	ld	a0,-48(s0)
    80005df8:	fffff097          	auipc	ra,0xfffff
    80005dfc:	9cc080e7          	jalr	-1588(ra) # 800047c4 <fileclose>
    fileclose(wf);
    80005e00:	fc843503          	ld	a0,-56(s0)
    80005e04:	fffff097          	auipc	ra,0xfffff
    80005e08:	9c0080e7          	jalr	-1600(ra) # 800047c4 <fileclose>
    return -1;
    80005e0c:	57fd                	li	a5,-1
}
    80005e0e:	853e                	mv	a0,a5
    80005e10:	70e2                	ld	ra,56(sp)
    80005e12:	7442                	ld	s0,48(sp)
    80005e14:	74a2                	ld	s1,40(sp)
    80005e16:	6121                	addi	sp,sp,64
    80005e18:	8082                	ret
    80005e1a:	0000                	unimp
    80005e1c:	0000                	unimp
	...

0000000080005e20 <kernelvec>:
    80005e20:	7111                	addi	sp,sp,-256
    80005e22:	e006                	sd	ra,0(sp)
    80005e24:	e40a                	sd	sp,8(sp)
    80005e26:	e80e                	sd	gp,16(sp)
    80005e28:	ec12                	sd	tp,24(sp)
    80005e2a:	f016                	sd	t0,32(sp)
    80005e2c:	f41a                	sd	t1,40(sp)
    80005e2e:	f81e                	sd	t2,48(sp)
    80005e30:	fc22                	sd	s0,56(sp)
    80005e32:	e0a6                	sd	s1,64(sp)
    80005e34:	e4aa                	sd	a0,72(sp)
    80005e36:	e8ae                	sd	a1,80(sp)
    80005e38:	ecb2                	sd	a2,88(sp)
    80005e3a:	f0b6                	sd	a3,96(sp)
    80005e3c:	f4ba                	sd	a4,104(sp)
    80005e3e:	f8be                	sd	a5,112(sp)
    80005e40:	fcc2                	sd	a6,120(sp)
    80005e42:	e146                	sd	a7,128(sp)
    80005e44:	e54a                	sd	s2,136(sp)
    80005e46:	e94e                	sd	s3,144(sp)
    80005e48:	ed52                	sd	s4,152(sp)
    80005e4a:	f156                	sd	s5,160(sp)
    80005e4c:	f55a                	sd	s6,168(sp)
    80005e4e:	f95e                	sd	s7,176(sp)
    80005e50:	fd62                	sd	s8,184(sp)
    80005e52:	e1e6                	sd	s9,192(sp)
    80005e54:	e5ea                	sd	s10,200(sp)
    80005e56:	e9ee                	sd	s11,208(sp)
    80005e58:	edf2                	sd	t3,216(sp)
    80005e5a:	f1f6                	sd	t4,224(sp)
    80005e5c:	f5fa                	sd	t5,232(sp)
    80005e5e:	f9fe                	sd	t6,240(sp)
    80005e60:	bd5fc0ef          	jal	ra,80002a34 <kerneltrap>
    80005e64:	6082                	ld	ra,0(sp)
    80005e66:	6122                	ld	sp,8(sp)
    80005e68:	61c2                	ld	gp,16(sp)
    80005e6a:	7282                	ld	t0,32(sp)
    80005e6c:	7322                	ld	t1,40(sp)
    80005e6e:	73c2                	ld	t2,48(sp)
    80005e70:	7462                	ld	s0,56(sp)
    80005e72:	6486                	ld	s1,64(sp)
    80005e74:	6526                	ld	a0,72(sp)
    80005e76:	65c6                	ld	a1,80(sp)
    80005e78:	6666                	ld	a2,88(sp)
    80005e7a:	7686                	ld	a3,96(sp)
    80005e7c:	7726                	ld	a4,104(sp)
    80005e7e:	77c6                	ld	a5,112(sp)
    80005e80:	7866                	ld	a6,120(sp)
    80005e82:	688a                	ld	a7,128(sp)
    80005e84:	692a                	ld	s2,136(sp)
    80005e86:	69ca                	ld	s3,144(sp)
    80005e88:	6a6a                	ld	s4,152(sp)
    80005e8a:	7a8a                	ld	s5,160(sp)
    80005e8c:	7b2a                	ld	s6,168(sp)
    80005e8e:	7bca                	ld	s7,176(sp)
    80005e90:	7c6a                	ld	s8,184(sp)
    80005e92:	6c8e                	ld	s9,192(sp)
    80005e94:	6d2e                	ld	s10,200(sp)
    80005e96:	6dce                	ld	s11,208(sp)
    80005e98:	6e6e                	ld	t3,216(sp)
    80005e9a:	7e8e                	ld	t4,224(sp)
    80005e9c:	7f2e                	ld	t5,232(sp)
    80005e9e:	7fce                	ld	t6,240(sp)
    80005ea0:	6111                	addi	sp,sp,256
    80005ea2:	10200073          	sret
    80005ea6:	00000013          	nop
    80005eaa:	00000013          	nop
    80005eae:	0001                	nop

0000000080005eb0 <timervec>:
    80005eb0:	34051573          	csrrw	a0,mscratch,a0
    80005eb4:	e10c                	sd	a1,0(a0)
    80005eb6:	e510                	sd	a2,8(a0)
    80005eb8:	e914                	sd	a3,16(a0)
    80005eba:	710c                	ld	a1,32(a0)
    80005ebc:	7510                	ld	a2,40(a0)
    80005ebe:	6194                	ld	a3,0(a1)
    80005ec0:	96b2                	add	a3,a3,a2
    80005ec2:	e194                	sd	a3,0(a1)
    80005ec4:	4589                	li	a1,2
    80005ec6:	14459073          	csrw	sip,a1
    80005eca:	6914                	ld	a3,16(a0)
    80005ecc:	6510                	ld	a2,8(a0)
    80005ece:	610c                	ld	a1,0(a0)
    80005ed0:	34051573          	csrrw	a0,mscratch,a0
    80005ed4:	30200073          	mret
	...

0000000080005eda <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005eda:	1141                	addi	sp,sp,-16
    80005edc:	e422                	sd	s0,8(sp)
    80005ede:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005ee0:	0c0007b7          	lui	a5,0xc000
    80005ee4:	4705                	li	a4,1
    80005ee6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005ee8:	c3d8                	sw	a4,4(a5)
}
    80005eea:	6422                	ld	s0,8(sp)
    80005eec:	0141                	addi	sp,sp,16
    80005eee:	8082                	ret

0000000080005ef0 <plicinithart>:

void
plicinithart(void)
{
    80005ef0:	1141                	addi	sp,sp,-16
    80005ef2:	e406                	sd	ra,8(sp)
    80005ef4:	e022                	sd	s0,0(sp)
    80005ef6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005ef8:	ffffc097          	auipc	ra,0xffffc
    80005efc:	b0a080e7          	jalr	-1270(ra) # 80001a02 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005f00:	0085171b          	slliw	a4,a0,0x8
    80005f04:	0c0027b7          	lui	a5,0xc002
    80005f08:	97ba                	add	a5,a5,a4
    80005f0a:	40200713          	li	a4,1026
    80005f0e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005f12:	00d5151b          	slliw	a0,a0,0xd
    80005f16:	0c2017b7          	lui	a5,0xc201
    80005f1a:	953e                	add	a0,a0,a5
    80005f1c:	00052023          	sw	zero,0(a0)
}
    80005f20:	60a2                	ld	ra,8(sp)
    80005f22:	6402                	ld	s0,0(sp)
    80005f24:	0141                	addi	sp,sp,16
    80005f26:	8082                	ret

0000000080005f28 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005f28:	1141                	addi	sp,sp,-16
    80005f2a:	e406                	sd	ra,8(sp)
    80005f2c:	e022                	sd	s0,0(sp)
    80005f2e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005f30:	ffffc097          	auipc	ra,0xffffc
    80005f34:	ad2080e7          	jalr	-1326(ra) # 80001a02 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005f38:	00d5179b          	slliw	a5,a0,0xd
    80005f3c:	0c201537          	lui	a0,0xc201
    80005f40:	953e                	add	a0,a0,a5
  return irq;
}
    80005f42:	4148                	lw	a0,4(a0)
    80005f44:	60a2                	ld	ra,8(sp)
    80005f46:	6402                	ld	s0,0(sp)
    80005f48:	0141                	addi	sp,sp,16
    80005f4a:	8082                	ret

0000000080005f4c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005f4c:	1101                	addi	sp,sp,-32
    80005f4e:	ec06                	sd	ra,24(sp)
    80005f50:	e822                	sd	s0,16(sp)
    80005f52:	e426                	sd	s1,8(sp)
    80005f54:	1000                	addi	s0,sp,32
    80005f56:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005f58:	ffffc097          	auipc	ra,0xffffc
    80005f5c:	aaa080e7          	jalr	-1366(ra) # 80001a02 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005f60:	00d5151b          	slliw	a0,a0,0xd
    80005f64:	0c2017b7          	lui	a5,0xc201
    80005f68:	97aa                	add	a5,a5,a0
    80005f6a:	c3c4                	sw	s1,4(a5)
}
    80005f6c:	60e2                	ld	ra,24(sp)
    80005f6e:	6442                	ld	s0,16(sp)
    80005f70:	64a2                	ld	s1,8(sp)
    80005f72:	6105                	addi	sp,sp,32
    80005f74:	8082                	ret

0000000080005f76 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005f76:	1141                	addi	sp,sp,-16
    80005f78:	e406                	sd	ra,8(sp)
    80005f7a:	e022                	sd	s0,0(sp)
    80005f7c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005f7e:	479d                	li	a5,7
    80005f80:	04a7cc63          	blt	a5,a0,80005fd8 <free_desc+0x62>
    panic("virtio_disk_intr 1");
  if(disk.free[i])
    80005f84:	00022797          	auipc	a5,0x22
    80005f88:	07c78793          	addi	a5,a5,124 # 80028000 <disk>
    80005f8c:	00a78733          	add	a4,a5,a0
    80005f90:	6789                	lui	a5,0x2
    80005f92:	97ba                	add	a5,a5,a4
    80005f94:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005f98:	eba1                	bnez	a5,80005fe8 <free_desc+0x72>
    panic("virtio_disk_intr 2");
  disk.desc[i].addr = 0;
    80005f9a:	00451713          	slli	a4,a0,0x4
    80005f9e:	00024797          	auipc	a5,0x24
    80005fa2:	0627b783          	ld	a5,98(a5) # 8002a000 <disk+0x2000>
    80005fa6:	97ba                	add	a5,a5,a4
    80005fa8:	0007b023          	sd	zero,0(a5)
  disk.free[i] = 1;
    80005fac:	00022797          	auipc	a5,0x22
    80005fb0:	05478793          	addi	a5,a5,84 # 80028000 <disk>
    80005fb4:	97aa                	add	a5,a5,a0
    80005fb6:	6509                	lui	a0,0x2
    80005fb8:	953e                	add	a0,a0,a5
    80005fba:	4785                	li	a5,1
    80005fbc:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005fc0:	00024517          	auipc	a0,0x24
    80005fc4:	05850513          	addi	a0,a0,88 # 8002a018 <disk+0x2018>
    80005fc8:	ffffc097          	auipc	ra,0xffffc
    80005fcc:	40a080e7          	jalr	1034(ra) # 800023d2 <wakeup>
}
    80005fd0:	60a2                	ld	ra,8(sp)
    80005fd2:	6402                	ld	s0,0(sp)
    80005fd4:	0141                	addi	sp,sp,16
    80005fd6:	8082                	ret
    panic("virtio_disk_intr 1");
    80005fd8:	00002517          	auipc	a0,0x2
    80005fdc:	7b850513          	addi	a0,a0,1976 # 80008790 <syscalls+0x350>
    80005fe0:	ffffa097          	auipc	ra,0xffffa
    80005fe4:	5f0080e7          	jalr	1520(ra) # 800005d0 <panic>
    panic("virtio_disk_intr 2");
    80005fe8:	00002517          	auipc	a0,0x2
    80005fec:	7c050513          	addi	a0,a0,1984 # 800087a8 <syscalls+0x368>
    80005ff0:	ffffa097          	auipc	ra,0xffffa
    80005ff4:	5e0080e7          	jalr	1504(ra) # 800005d0 <panic>

0000000080005ff8 <virtio_disk_init>:
{
    80005ff8:	1101                	addi	sp,sp,-32
    80005ffa:	ec06                	sd	ra,24(sp)
    80005ffc:	e822                	sd	s0,16(sp)
    80005ffe:	e426                	sd	s1,8(sp)
    80006000:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006002:	00002597          	auipc	a1,0x2
    80006006:	7be58593          	addi	a1,a1,1982 # 800087c0 <syscalls+0x380>
    8000600a:	00024517          	auipc	a0,0x24
    8000600e:	09e50513          	addi	a0,a0,158 # 8002a0a8 <disk+0x20a8>
    80006012:	ffffb097          	auipc	ra,0xffffb
    80006016:	bc0080e7          	jalr	-1088(ra) # 80000bd2 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000601a:	100017b7          	lui	a5,0x10001
    8000601e:	4398                	lw	a4,0(a5)
    80006020:	2701                	sext.w	a4,a4
    80006022:	747277b7          	lui	a5,0x74727
    80006026:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    8000602a:	0ef71163          	bne	a4,a5,8000610c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000602e:	100017b7          	lui	a5,0x10001
    80006032:	43dc                	lw	a5,4(a5)
    80006034:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006036:	4705                	li	a4,1
    80006038:	0ce79a63          	bne	a5,a4,8000610c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000603c:	100017b7          	lui	a5,0x10001
    80006040:	479c                	lw	a5,8(a5)
    80006042:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006044:	4709                	li	a4,2
    80006046:	0ce79363          	bne	a5,a4,8000610c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000604a:	100017b7          	lui	a5,0x10001
    8000604e:	47d8                	lw	a4,12(a5)
    80006050:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006052:	554d47b7          	lui	a5,0x554d4
    80006056:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000605a:	0af71963          	bne	a4,a5,8000610c <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000605e:	100017b7          	lui	a5,0x10001
    80006062:	4705                	li	a4,1
    80006064:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006066:	470d                	li	a4,3
    80006068:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000606a:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    8000606c:	c7ffe737          	lui	a4,0xc7ffe
    80006070:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd375f>
    80006074:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006076:	2701                	sext.w	a4,a4
    80006078:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000607a:	472d                	li	a4,11
    8000607c:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000607e:	473d                	li	a4,15
    80006080:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80006082:	6705                	lui	a4,0x1
    80006084:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006086:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    8000608a:	5bdc                	lw	a5,52(a5)
    8000608c:	2781                	sext.w	a5,a5
  if(max == 0)
    8000608e:	c7d9                	beqz	a5,8000611c <virtio_disk_init+0x124>
  if(max < NUM)
    80006090:	471d                	li	a4,7
    80006092:	08f77d63          	bgeu	a4,a5,8000612c <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006096:	100014b7          	lui	s1,0x10001
    8000609a:	47a1                	li	a5,8
    8000609c:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    8000609e:	6609                	lui	a2,0x2
    800060a0:	4581                	li	a1,0
    800060a2:	00022517          	auipc	a0,0x22
    800060a6:	f5e50513          	addi	a0,a0,-162 # 80028000 <disk>
    800060aa:	ffffb097          	auipc	ra,0xffffb
    800060ae:	cb4080e7          	jalr	-844(ra) # 80000d5e <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    800060b2:	00022717          	auipc	a4,0x22
    800060b6:	f4e70713          	addi	a4,a4,-178 # 80028000 <disk>
    800060ba:	00c75793          	srli	a5,a4,0xc
    800060be:	2781                	sext.w	a5,a5
    800060c0:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct VRingDesc *) disk.pages;
    800060c2:	00024797          	auipc	a5,0x24
    800060c6:	f3e78793          	addi	a5,a5,-194 # 8002a000 <disk+0x2000>
    800060ca:	e398                	sd	a4,0(a5)
  disk.avail = (uint16*)(((char*)disk.desc) + NUM*sizeof(struct VRingDesc));
    800060cc:	00022717          	auipc	a4,0x22
    800060d0:	fb470713          	addi	a4,a4,-76 # 80028080 <disk+0x80>
    800060d4:	e798                	sd	a4,8(a5)
  disk.used = (struct UsedArea *) (disk.pages + PGSIZE);
    800060d6:	00023717          	auipc	a4,0x23
    800060da:	f2a70713          	addi	a4,a4,-214 # 80029000 <disk+0x1000>
    800060de:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    800060e0:	4705                	li	a4,1
    800060e2:	00e78c23          	sb	a4,24(a5)
    800060e6:	00e78ca3          	sb	a4,25(a5)
    800060ea:	00e78d23          	sb	a4,26(a5)
    800060ee:	00e78da3          	sb	a4,27(a5)
    800060f2:	00e78e23          	sb	a4,28(a5)
    800060f6:	00e78ea3          	sb	a4,29(a5)
    800060fa:	00e78f23          	sb	a4,30(a5)
    800060fe:	00e78fa3          	sb	a4,31(a5)
}
    80006102:	60e2                	ld	ra,24(sp)
    80006104:	6442                	ld	s0,16(sp)
    80006106:	64a2                	ld	s1,8(sp)
    80006108:	6105                	addi	sp,sp,32
    8000610a:	8082                	ret
    panic("could not find virtio disk");
    8000610c:	00002517          	auipc	a0,0x2
    80006110:	6c450513          	addi	a0,a0,1732 # 800087d0 <syscalls+0x390>
    80006114:	ffffa097          	auipc	ra,0xffffa
    80006118:	4bc080e7          	jalr	1212(ra) # 800005d0 <panic>
    panic("virtio disk has no queue 0");
    8000611c:	00002517          	auipc	a0,0x2
    80006120:	6d450513          	addi	a0,a0,1748 # 800087f0 <syscalls+0x3b0>
    80006124:	ffffa097          	auipc	ra,0xffffa
    80006128:	4ac080e7          	jalr	1196(ra) # 800005d0 <panic>
    panic("virtio disk max queue too short");
    8000612c:	00002517          	auipc	a0,0x2
    80006130:	6e450513          	addi	a0,a0,1764 # 80008810 <syscalls+0x3d0>
    80006134:	ffffa097          	auipc	ra,0xffffa
    80006138:	49c080e7          	jalr	1180(ra) # 800005d0 <panic>

000000008000613c <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    8000613c:	7175                	addi	sp,sp,-144
    8000613e:	e506                	sd	ra,136(sp)
    80006140:	e122                	sd	s0,128(sp)
    80006142:	fca6                	sd	s1,120(sp)
    80006144:	f8ca                	sd	s2,112(sp)
    80006146:	f4ce                	sd	s3,104(sp)
    80006148:	f0d2                	sd	s4,96(sp)
    8000614a:	ecd6                	sd	s5,88(sp)
    8000614c:	e8da                	sd	s6,80(sp)
    8000614e:	e4de                	sd	s7,72(sp)
    80006150:	e0e2                	sd	s8,64(sp)
    80006152:	fc66                	sd	s9,56(sp)
    80006154:	f86a                	sd	s10,48(sp)
    80006156:	f46e                	sd	s11,40(sp)
    80006158:	0900                	addi	s0,sp,144
    8000615a:	8aaa                	mv	s5,a0
    8000615c:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    8000615e:	00c52c83          	lw	s9,12(a0)
    80006162:	001c9c9b          	slliw	s9,s9,0x1
    80006166:	1c82                	slli	s9,s9,0x20
    80006168:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    8000616c:	00024517          	auipc	a0,0x24
    80006170:	f3c50513          	addi	a0,a0,-196 # 8002a0a8 <disk+0x20a8>
    80006174:	ffffb097          	auipc	ra,0xffffb
    80006178:	aee080e7          	jalr	-1298(ra) # 80000c62 <acquire>
  for(int i = 0; i < 3; i++){
    8000617c:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    8000617e:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006180:	00022c17          	auipc	s8,0x22
    80006184:	e80c0c13          	addi	s8,s8,-384 # 80028000 <disk>
    80006188:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    8000618a:	4b0d                	li	s6,3
    8000618c:	a0ad                	j	800061f6 <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    8000618e:	00fc0733          	add	a4,s8,a5
    80006192:	975e                	add	a4,a4,s7
    80006194:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006198:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    8000619a:	0207c563          	bltz	a5,800061c4 <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    8000619e:	2905                	addiw	s2,s2,1
    800061a0:	0611                	addi	a2,a2,4
    800061a2:	19690d63          	beq	s2,s6,8000633c <virtio_disk_rw+0x200>
    idx[i] = alloc_desc();
    800061a6:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    800061a8:	00024717          	auipc	a4,0x24
    800061ac:	e7070713          	addi	a4,a4,-400 # 8002a018 <disk+0x2018>
    800061b0:	87ce                	mv	a5,s3
    if(disk.free[i]){
    800061b2:	00074683          	lbu	a3,0(a4)
    800061b6:	fee1                	bnez	a3,8000618e <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    800061b8:	2785                	addiw	a5,a5,1
    800061ba:	0705                	addi	a4,a4,1
    800061bc:	fe979be3          	bne	a5,s1,800061b2 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    800061c0:	57fd                	li	a5,-1
    800061c2:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    800061c4:	01205d63          	blez	s2,800061de <virtio_disk_rw+0xa2>
    800061c8:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    800061ca:	000a2503          	lw	a0,0(s4)
    800061ce:	00000097          	auipc	ra,0x0
    800061d2:	da8080e7          	jalr	-600(ra) # 80005f76 <free_desc>
      for(int j = 0; j < i; j++)
    800061d6:	2d85                	addiw	s11,s11,1
    800061d8:	0a11                	addi	s4,s4,4
    800061da:	ffb918e3          	bne	s2,s11,800061ca <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800061de:	00024597          	auipc	a1,0x24
    800061e2:	eca58593          	addi	a1,a1,-310 # 8002a0a8 <disk+0x20a8>
    800061e6:	00024517          	auipc	a0,0x24
    800061ea:	e3250513          	addi	a0,a0,-462 # 8002a018 <disk+0x2018>
    800061ee:	ffffc097          	auipc	ra,0xffffc
    800061f2:	064080e7          	jalr	100(ra) # 80002252 <sleep>
  for(int i = 0; i < 3; i++){
    800061f6:	f8040a13          	addi	s4,s0,-128
{
    800061fa:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    800061fc:	894e                	mv	s2,s3
    800061fe:	b765                	j	800061a6 <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80006200:	00024717          	auipc	a4,0x24
    80006204:	e0073703          	ld	a4,-512(a4) # 8002a000 <disk+0x2000>
    80006208:	973e                	add	a4,a4,a5
    8000620a:	00071623          	sh	zero,12(a4)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000620e:	00022517          	auipc	a0,0x22
    80006212:	df250513          	addi	a0,a0,-526 # 80028000 <disk>
    80006216:	00024717          	auipc	a4,0x24
    8000621a:	dea70713          	addi	a4,a4,-534 # 8002a000 <disk+0x2000>
    8000621e:	6314                	ld	a3,0(a4)
    80006220:	96be                	add	a3,a3,a5
    80006222:	00c6d603          	lhu	a2,12(a3)
    80006226:	00166613          	ori	a2,a2,1
    8000622a:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000622e:	f8842683          	lw	a3,-120(s0)
    80006232:	6310                	ld	a2,0(a4)
    80006234:	97b2                	add	a5,a5,a2
    80006236:	00d79723          	sh	a3,14(a5)

  disk.info[idx[0]].status = 0;
    8000623a:	20048613          	addi	a2,s1,512 # 10001200 <_entry-0x6fffee00>
    8000623e:	0612                	slli	a2,a2,0x4
    80006240:	962a                	add	a2,a2,a0
    80006242:	02060823          	sb	zero,48(a2) # 2030 <_entry-0x7fffdfd0>
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006246:	00469793          	slli	a5,a3,0x4
    8000624a:	630c                	ld	a1,0(a4)
    8000624c:	95be                	add	a1,a1,a5
    8000624e:	6689                	lui	a3,0x2
    80006250:	03068693          	addi	a3,a3,48 # 2030 <_entry-0x7fffdfd0>
    80006254:	96ca                	add	a3,a3,s2
    80006256:	96aa                	add	a3,a3,a0
    80006258:	e194                	sd	a3,0(a1)
  disk.desc[idx[2]].len = 1;
    8000625a:	6314                	ld	a3,0(a4)
    8000625c:	96be                	add	a3,a3,a5
    8000625e:	4585                	li	a1,1
    80006260:	c68c                	sw	a1,8(a3)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006262:	6314                	ld	a3,0(a4)
    80006264:	96be                	add	a3,a3,a5
    80006266:	4509                	li	a0,2
    80006268:	00a69623          	sh	a0,12(a3)
  disk.desc[idx[2]].next = 0;
    8000626c:	6314                	ld	a3,0(a4)
    8000626e:	97b6                	add	a5,a5,a3
    80006270:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006274:	00baa223          	sw	a1,4(s5)
  disk.info[idx[0]].b = b;
    80006278:	03563423          	sd	s5,40(a2)

  // avail[0] is flags
  // avail[1] tells the device how far to look in avail[2...].
  // avail[2...] are desc[] indices the device should process.
  // we only tell device the first index in our chain of descriptors.
  disk.avail[2 + (disk.avail[1] % NUM)] = idx[0];
    8000627c:	6714                	ld	a3,8(a4)
    8000627e:	0026d783          	lhu	a5,2(a3)
    80006282:	8b9d                	andi	a5,a5,7
    80006284:	0789                	addi	a5,a5,2
    80006286:	0786                	slli	a5,a5,0x1
    80006288:	97b6                	add	a5,a5,a3
    8000628a:	00979023          	sh	s1,0(a5)
  __sync_synchronize();
    8000628e:	0ff0000f          	fence
  disk.avail[1] = disk.avail[1] + 1;
    80006292:	6718                	ld	a4,8(a4)
    80006294:	00275783          	lhu	a5,2(a4)
    80006298:	2785                	addiw	a5,a5,1
    8000629a:	00f71123          	sh	a5,2(a4)

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000629e:	100017b7          	lui	a5,0x10001
    800062a2:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800062a6:	004aa783          	lw	a5,4(s5)
    800062aa:	02b79163          	bne	a5,a1,800062cc <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    800062ae:	00024917          	auipc	s2,0x24
    800062b2:	dfa90913          	addi	s2,s2,-518 # 8002a0a8 <disk+0x20a8>
  while(b->disk == 1) {
    800062b6:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800062b8:	85ca                	mv	a1,s2
    800062ba:	8556                	mv	a0,s5
    800062bc:	ffffc097          	auipc	ra,0xffffc
    800062c0:	f96080e7          	jalr	-106(ra) # 80002252 <sleep>
  while(b->disk == 1) {
    800062c4:	004aa783          	lw	a5,4(s5)
    800062c8:	fe9788e3          	beq	a5,s1,800062b8 <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    800062cc:	f8042483          	lw	s1,-128(s0)
    800062d0:	20048793          	addi	a5,s1,512
    800062d4:	00479713          	slli	a4,a5,0x4
    800062d8:	00022797          	auipc	a5,0x22
    800062dc:	d2878793          	addi	a5,a5,-728 # 80028000 <disk>
    800062e0:	97ba                	add	a5,a5,a4
    800062e2:	0207b423          	sd	zero,40(a5)
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    800062e6:	00024917          	auipc	s2,0x24
    800062ea:	d1a90913          	addi	s2,s2,-742 # 8002a000 <disk+0x2000>
    800062ee:	a019                	j	800062f4 <virtio_disk_rw+0x1b8>
      i = disk.desc[i].next;
    800062f0:	00e4d483          	lhu	s1,14(s1)
    free_desc(i);
    800062f4:	8526                	mv	a0,s1
    800062f6:	00000097          	auipc	ra,0x0
    800062fa:	c80080e7          	jalr	-896(ra) # 80005f76 <free_desc>
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    800062fe:	0492                	slli	s1,s1,0x4
    80006300:	00093783          	ld	a5,0(s2)
    80006304:	94be                	add	s1,s1,a5
    80006306:	00c4d783          	lhu	a5,12(s1)
    8000630a:	8b85                	andi	a5,a5,1
    8000630c:	f3f5                	bnez	a5,800062f0 <virtio_disk_rw+0x1b4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000630e:	00024517          	auipc	a0,0x24
    80006312:	d9a50513          	addi	a0,a0,-614 # 8002a0a8 <disk+0x20a8>
    80006316:	ffffb097          	auipc	ra,0xffffb
    8000631a:	a00080e7          	jalr	-1536(ra) # 80000d16 <release>
}
    8000631e:	60aa                	ld	ra,136(sp)
    80006320:	640a                	ld	s0,128(sp)
    80006322:	74e6                	ld	s1,120(sp)
    80006324:	7946                	ld	s2,112(sp)
    80006326:	79a6                	ld	s3,104(sp)
    80006328:	7a06                	ld	s4,96(sp)
    8000632a:	6ae6                	ld	s5,88(sp)
    8000632c:	6b46                	ld	s6,80(sp)
    8000632e:	6ba6                	ld	s7,72(sp)
    80006330:	6c06                	ld	s8,64(sp)
    80006332:	7ce2                	ld	s9,56(sp)
    80006334:	7d42                	ld	s10,48(sp)
    80006336:	7da2                	ld	s11,40(sp)
    80006338:	6149                	addi	sp,sp,144
    8000633a:	8082                	ret
  if(write)
    8000633c:	01a037b3          	snez	a5,s10
    80006340:	f6f42823          	sw	a5,-144(s0)
  buf0.reserved = 0;
    80006344:	f6042a23          	sw	zero,-140(s0)
  buf0.sector = sector;
    80006348:	f7943c23          	sd	s9,-136(s0)
  disk.desc[idx[0]].addr = (uint64) kvmpa((uint64) &buf0);
    8000634c:	f8042483          	lw	s1,-128(s0)
    80006350:	00449913          	slli	s2,s1,0x4
    80006354:	00024997          	auipc	s3,0x24
    80006358:	cac98993          	addi	s3,s3,-852 # 8002a000 <disk+0x2000>
    8000635c:	0009ba03          	ld	s4,0(s3)
    80006360:	9a4a                	add	s4,s4,s2
    80006362:	f7040513          	addi	a0,s0,-144
    80006366:	ffffb097          	auipc	ra,0xffffb
    8000636a:	dc8080e7          	jalr	-568(ra) # 8000112e <kvmpa>
    8000636e:	00aa3023          	sd	a0,0(s4)
  disk.desc[idx[0]].len = sizeof(buf0);
    80006372:	0009b783          	ld	a5,0(s3)
    80006376:	97ca                	add	a5,a5,s2
    80006378:	4741                	li	a4,16
    8000637a:	c798                	sw	a4,8(a5)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000637c:	0009b783          	ld	a5,0(s3)
    80006380:	97ca                	add	a5,a5,s2
    80006382:	4705                	li	a4,1
    80006384:	00e79623          	sh	a4,12(a5)
  disk.desc[idx[0]].next = idx[1];
    80006388:	f8442783          	lw	a5,-124(s0)
    8000638c:	0009b703          	ld	a4,0(s3)
    80006390:	974a                	add	a4,a4,s2
    80006392:	00f71723          	sh	a5,14(a4)
  disk.desc[idx[1]].addr = (uint64) b->data;
    80006396:	0792                	slli	a5,a5,0x4
    80006398:	0009b703          	ld	a4,0(s3)
    8000639c:	973e                	add	a4,a4,a5
    8000639e:	058a8693          	addi	a3,s5,88
    800063a2:	e314                	sd	a3,0(a4)
  disk.desc[idx[1]].len = BSIZE;
    800063a4:	0009b703          	ld	a4,0(s3)
    800063a8:	973e                	add	a4,a4,a5
    800063aa:	40000693          	li	a3,1024
    800063ae:	c714                	sw	a3,8(a4)
  if(write)
    800063b0:	e40d18e3          	bnez	s10,80006200 <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800063b4:	00024717          	auipc	a4,0x24
    800063b8:	c4c73703          	ld	a4,-948(a4) # 8002a000 <disk+0x2000>
    800063bc:	973e                	add	a4,a4,a5
    800063be:	4689                	li	a3,2
    800063c0:	00d71623          	sh	a3,12(a4)
    800063c4:	b5a9                	j	8000620e <virtio_disk_rw+0xd2>

00000000800063c6 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800063c6:	1101                	addi	sp,sp,-32
    800063c8:	ec06                	sd	ra,24(sp)
    800063ca:	e822                	sd	s0,16(sp)
    800063cc:	e426                	sd	s1,8(sp)
    800063ce:	e04a                	sd	s2,0(sp)
    800063d0:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800063d2:	00024517          	auipc	a0,0x24
    800063d6:	cd650513          	addi	a0,a0,-810 # 8002a0a8 <disk+0x20a8>
    800063da:	ffffb097          	auipc	ra,0xffffb
    800063de:	888080e7          	jalr	-1912(ra) # 80000c62 <acquire>

  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    800063e2:	00024717          	auipc	a4,0x24
    800063e6:	c1e70713          	addi	a4,a4,-994 # 8002a000 <disk+0x2000>
    800063ea:	02075783          	lhu	a5,32(a4)
    800063ee:	6b18                	ld	a4,16(a4)
    800063f0:	00275683          	lhu	a3,2(a4)
    800063f4:	8ebd                	xor	a3,a3,a5
    800063f6:	8a9d                	andi	a3,a3,7
    800063f8:	cab9                	beqz	a3,8000644e <virtio_disk_intr+0x88>
    int id = disk.used->elems[disk.used_idx].id;

    if(disk.info[id].status != 0)
    800063fa:	00022917          	auipc	s2,0x22
    800063fe:	c0690913          	addi	s2,s2,-1018 # 80028000 <disk>
      panic("virtio_disk_intr status");
    
    disk.info[id].b->disk = 0;   // disk is done with buf
    wakeup(disk.info[id].b);

    disk.used_idx = (disk.used_idx + 1) % NUM;
    80006402:	00024497          	auipc	s1,0x24
    80006406:	bfe48493          	addi	s1,s1,-1026 # 8002a000 <disk+0x2000>
    int id = disk.used->elems[disk.used_idx].id;
    8000640a:	078e                	slli	a5,a5,0x3
    8000640c:	97ba                	add	a5,a5,a4
    8000640e:	43dc                	lw	a5,4(a5)
    if(disk.info[id].status != 0)
    80006410:	20078713          	addi	a4,a5,512
    80006414:	0712                	slli	a4,a4,0x4
    80006416:	974a                	add	a4,a4,s2
    80006418:	03074703          	lbu	a4,48(a4)
    8000641c:	ef21                	bnez	a4,80006474 <virtio_disk_intr+0xae>
    disk.info[id].b->disk = 0;   // disk is done with buf
    8000641e:	20078793          	addi	a5,a5,512
    80006422:	0792                	slli	a5,a5,0x4
    80006424:	97ca                	add	a5,a5,s2
    80006426:	7798                	ld	a4,40(a5)
    80006428:	00072223          	sw	zero,4(a4)
    wakeup(disk.info[id].b);
    8000642c:	7788                	ld	a0,40(a5)
    8000642e:	ffffc097          	auipc	ra,0xffffc
    80006432:	fa4080e7          	jalr	-92(ra) # 800023d2 <wakeup>
    disk.used_idx = (disk.used_idx + 1) % NUM;
    80006436:	0204d783          	lhu	a5,32(s1)
    8000643a:	2785                	addiw	a5,a5,1
    8000643c:	8b9d                	andi	a5,a5,7
    8000643e:	02f49023          	sh	a5,32(s1)
  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    80006442:	6898                	ld	a4,16(s1)
    80006444:	00275683          	lhu	a3,2(a4)
    80006448:	8a9d                	andi	a3,a3,7
    8000644a:	fcf690e3          	bne	a3,a5,8000640a <virtio_disk_intr+0x44>
  }
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    8000644e:	10001737          	lui	a4,0x10001
    80006452:	533c                	lw	a5,96(a4)
    80006454:	8b8d                	andi	a5,a5,3
    80006456:	d37c                	sw	a5,100(a4)

  release(&disk.vdisk_lock);
    80006458:	00024517          	auipc	a0,0x24
    8000645c:	c5050513          	addi	a0,a0,-944 # 8002a0a8 <disk+0x20a8>
    80006460:	ffffb097          	auipc	ra,0xffffb
    80006464:	8b6080e7          	jalr	-1866(ra) # 80000d16 <release>
}
    80006468:	60e2                	ld	ra,24(sp)
    8000646a:	6442                	ld	s0,16(sp)
    8000646c:	64a2                	ld	s1,8(sp)
    8000646e:	6902                	ld	s2,0(sp)
    80006470:	6105                	addi	sp,sp,32
    80006472:	8082                	ret
      panic("virtio_disk_intr status");
    80006474:	00002517          	auipc	a0,0x2
    80006478:	3bc50513          	addi	a0,a0,956 # 80008830 <syscalls+0x3f0>
    8000647c:	ffffa097          	auipc	ra,0xffffa
    80006480:	154080e7          	jalr	340(ra) # 800005d0 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
