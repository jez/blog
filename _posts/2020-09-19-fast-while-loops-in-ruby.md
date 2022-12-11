---
# vim:tw=90
layout: post
title: "Fast While Loops in Ruby"
date: 2020-09-19T18:55:52-05:00
description: >-
  A dive into how the Sorbet Compiler deals with control flow, something it's particularly
  good at speeding up.
math: false
categories: ['ruby', 'sorbet-compiler']
# subtitle:
# author:
# author_url:
---

> **Disclaimer**: this post was first drafted as a Stripe-internal email. On December 10,
> 2022 I republished it here, largely unchanged from the original. See [Some Old Sorbet
> Compiler Notes](/old-compiler-notes/) for more. The Sorbet Compiler is still largely an
> experimental project: this post is available purely for curiosity's sake.
>
> Any benchmark numbers included in this post are intended to be educational about how the
> Sorbet Compiler approaches speeding up code. They should not be taken as representative
> or predictive of any real-world workload, and are likely out-of-date with respect to
> improvements that have been made since this post originally appeared.

Let's continue our series in comparing Ruby performance, interpreted vs compiled, on
microbenchmarks. Previously in the series:

-   [Types Make Array Access Faster](/types-make-array-access-faster/)
-   [Another Look at Typed Array Access](/another-look-at-typed-array-access/)

In both those posts, I mentioned that the Sorbet Compiler is able to speed up not only
heavily typed code but also certain kinds of untyped code. One of the snippets we had
compared was this `while` loop:

``` ruby
i = 0
while i < 10_000_000
  i += 1
end
```

which showed these timings:

  ------------------------------------------------
  benchmark                 interpreted   compiled
  ------------------------ ------------ ----------
  [while_10_000_000.rb]          0.205s     0.048s
  ------------------------------------------------

[while_10_000_000.rb]: https://github.com/sorbet/sorbet/blob/master/test/testdata/ruby_benchmark/stripe/while_10_000_000.rb

When the Ruby VM encounters a `while` loop like this, it first parses and translates that
source text into [bytecode instructions](https://en.wikipedia.org/wiki/Bytecode) that look
something like this, simplified:

``` plain
0007 jump          17
0009 getlocal      i
0011 putobject     1
0012 opt_plus
0015 setlocal      i
0017 getlocal      i
0019 putobject     10000000
0021 opt_lt
0024 branchif      9
```

*(You can use `ruby --dump=insns foo.rb` to play around with full output.)*

This output almost looks like assembly! There are variable gets and sets, conditional
branches, addition, comparison, etc. And assembly is fast right? So if Ruby builds this
assembly-like representation of our code internally, why doesn't it run as fast as the
compiled code?

To get these bytecode instructions to mean something, the Ruby VM interprets them on the
fly. Somewhere in the Ruby VM, there's essentially one big loop over each instruction
type, where each instruction is implemented by arbitrarily complicated C code:

``` c
while ((next_instruction = get_instruction()) {
  switch (next_instruction->type) {
    case getlocal: vm_getlocal(); break;
    case opt_plus: vm_opt_plus(); break;
    case opt_lt:   vm_opt_lt(); break;
    case branchif: vm_branchif(); break;
    // ...
  }
}
```

*(It's actually a lot messier; see [vm_exec.c], [insns.def], and [vm_insnhelper.c] if you want to poke around.)*

[vm_exec.c]: https://github.com/ruby/ruby/blob/a0c7c23c9cec0d0ffcba012279cd652d28ad5bf3/vm_exec.c#L113-L118
[insns.def]: https://github.com/ruby/ruby/blob/a0c7c23c9cec0d0ffcba012279cd652d28ad5bf3/insns.def#L1088-L1100
[vm_insnhelper.c]: https://github.com/ruby/ruby/blob/a0c7c23c9cec0d0ffcba012279cd652d28ad5bf3/vm_insnhelper.c#L4235-L4267

That arbitrarily complicated C code is almost always doing more than a few handfuls of
pointer reads and writes to bookkeep runtime data structures. It's full of conditional
code paths that execute only part of the time. In our short Ruby program above, all we
needed to happen was for the computer to do an integer comparison, an integer increment,
and an assembly jump. When the Ruby VM runs our code, it does way more than just that.

But with the Sorbet compiler, the integer comparison, increment, and jump are almost the
only things executed. I've [included a snippet](#appendix-compiled-while-program)
of the Sorbet Compiler's assembly output at the end of this post. It's short enough to be
understood in full, and in fact I've annotated each line with what the instructions all
mean.

This works in large part due to the magic of Sorbet's type checking algorithm (which will
have already mapped out the flow of control in a program before the compiler kicks in) and
LLVM (which is really good at taking [maps of control
flow](https://en.wikipedia.org/wiki/Control-flow_graph) and removing the redundant parts).

As for why the compiler is **particularly** good at speeding up this specific program:

-   The Ruby VM stores local variables on a stack-like data structure which lives on the
    heap. To read and write a variable, the Ruby VM has to follow pointers that end up
    touching the heap. The compiler keeps almost it's entire working memory in registers.

-   The compiler inlines the code for `+` and `<` on `Integer` specifically, because given
    the static type annotations those are the most likely. Meanwhile, the Ruby VM has to
    handle the possibility that `+` is running on `Integer`, or `Float`, or `String`, or
    `Array`, or something else.

    This has huge consequences for the [instruction cache](#appendix-instruction-cache):
    the compiled code's main loop spans only \~200 bytes. Meanwhile the VM's
    implementation of `+` and `<` are around \~700 bytes each, and the core instruction
    processing loop is upwards of 32K bytes, only fractions of which are needed for this
    program.

-   This Ruby code doesn't take full advantage of the Ruby VM's features. Ruby makes it
    easy to handle exceptions, call blocks, dispatch dynamically, reflect, and more. This
    script is taking absolutely zero advantage of those high-level features.

For the bread and butter of a programming language (control flow and local variables), the
code the compiler emits is super low overhead. The assembly the Sorbet compiler emits
reduces our simple program to its essence, cutting out the fatty parts of the Ruby VM and
leaving behind a lean executable.

# Appendix: Compiled `while` program

This is a snippet of the compiled output for the while program above. I've cut a large chunk of the compiled output, most of which is just book keeping to register C functions with the Ruby VM and pre-allocate some `String` and `Symbol` constants.

But, I haven't snipped anything out of the middle of the snippet below—it occurs contiguous in the compiled output.

```{.gnuassembler .tight-code}
94c:    mov    $0x1,%ebp                     #    i = 0
951:    mov    $0x14,%r13d                   #    %r13 = Qtrue
957:    jmp    97f <func_Object#jez+0xbf>    #    jump to start of while loop
959:    nopl   0x0(%rax)

960:    mov    %rbp,%rdi                     # ─┐
963:    mov    %r15,%rsi                     #  │
966:    mov    $0x1,%edx                     #  │ slow path call to `+` (defensive,
96b:    lea    0x18(%rsp),%rcx               #  │ in case static types are wrong)
970:    lea    0x2008a9(%rip),%r8            #  │
977:    callq  7d0 <sorbet_callFuncWithCache>#  │ call back into the Ruby VM
97c:    mov    %rax,%rbp                     # ─┘

97f:    mov    %r12,(%rbx)                   # ─┐ start of while loop
982:    movq   $0x1312d01,0x18(%rsp)         #  │ store Integer(10_000_000) to stack
989:                                         #  │
98b:    test   $0x1,%bpl                     #  │ i.is_a?(Integer)
98f:    je     9de <func_Object#jez+0x11e>   #  │ jump to slow path `<` if not int
                                             #  │
991:    cmp    $0x1312d00,%rbp               #  │ 10,000,000 < i  (fast path)
998:    mov    $0x0,%eax                     #  │ store Qfalse in %rax if less,
99d:    cmovl  %r13,%rax                     #  │ otherwise, store Qtrue
                                             #  │
9a1:    test   $0xfffffffffffffff7,%rax      #  │ bitwise AND with Qnil (Ruby nil)
9a7:    je     a04 <func_Object#jez+0x144>   # ─┘ jump out of loop if AND is zero
                                             #    (i.e., %rax is Qfalse or Qnil)

9a9:    mov    %r14,(%rbx)                   #    set line numbers in VM

9ac:    movq   $0x3,0x18(%rsp)               #    store Integer(1) in a VALUE[]
                                             #    on the stack (for slow path `+`)
9b3:
9b5:    test   $0x1,%bpl                     # ─┐ i.is_a?(Integer)
9b9:    je     960 <func_Object#jez+0xa0>    # ─┘ jump to slow path `+` if not int

                                             # ─┐ i += 1          (fast path)
9bb:    add    $0x2,%rbp                     #  │ (LSB of Ruby ints are always 1,
                                             # ─┘  thus adding 0x2 adds 1)

9bf:    jno    97f <func_Object#jez+0xbf>    # ─┐
9c1:    sar    %rbp                          #  │
9c4:    movabs $0x8000000000000000,%rax      #  │
9cb:                                         #  │
9ce:    xor    %rax,%rbp                     #  ├─ promote int to Bignum
9d1:    mov    %rbp,%rdi                     #  │  (if overflow)
9d4:    callq  830 <rb_int2big@plt>          #  │
9d9:    mov    %rax,%rbp                     #  │
9dc:    jmp    97f <func_Object#jez+0xbf>    # ─┘
9de:    mov    %rbp,%rdi                     # ─┐
                                             #  │
9e1:    mov    0x8(%rsp),%rsi                #  │
9e6:    mov    $0x1,%edx                     #  │ slow path call to `<`
9eb:    lea    0x18(%rsp),%rcx               #  │ (in case static types are wrong)
9f0:    lea    0x200809(%rip),%r8            #  │
9f7:    callq  7d0 <sorbet_callFuncWithCache>#  │ call back into the Ruby VM
9fc:    test   $0xfffffffffffffff7,%rax      #  │
a02:    jne    9a9 <func_Object#jez+0xe9>    # ─┘
a04:    ...                                  #    end of while loop (clean up, return)
```

# Appendix: Instruction cache

You can use `lscpu` to see how big your CPU's instruction cache is:

``` plain
❯ lscpu
Architecture:                    x86_64
CPU(s):                          16
Thread(s) per core:              2
Core(s) per socket:              8
Socket(s):                       1
NUMA node(s):                    1
Model name:                      AMD Ryzen 7 3700X 8-Core Processor
CPU max MHz:                     3600.0000
CPU min MHz:                     2200.0000
L1d cache:                       256 KiB
L1i cache:                       256 KiB      # <-- instruction cache
L2 cache:                        4 MiB
L3 cache:                        32 MiB
```

For my CPU (Ryzen 3700X), that 256 KiB is total for the whole chip, which means each of
the 8 cores gets its own 32 KiB of L1 instruction cache. That cache is then shared for
every program that gets scheduled onto that core (which is why it's important for the
kernel to have some sort of CPU affinity for processes when scheduling them—if a process
gets scheduled back onto the CPU it just was on, its instructions might still be in the
cache.)

