---
# vim:tw=90
layout: post
title: "Instant Runtime Type Checks in Ruby"
date: 2021-04-25T19:13:11-05:00
description: >-
  A dive into runtime type checking, like the kind used in Sorbet signatures, and how the
  Sorbet Compiler can speed it up.
math: false
categories: ['ruby', 'sorbet', 'sorbet-compiler']
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

After an embarrassingly long break, we're back with another post on compiled Ruby
performance! Previously in this series:

-   [Types Make Array Access Faster](/types-make-array-access-faster/)
-   [Another Look at Typed Array Access](/another-look-at-typed-array-access/)
-   [Fast While Loops in Ruby](/fast-while-loops-in-ruby/)

In this post, we're going to look at something that I've hinted at for a long time and
sort of taken for granted: the Sorbet Compiler is **much faster at runtime type checks**
than the interpreter.

Why do we care? In a compiler for a dynamically-typed language, runtime type checks are
the name of the game—they show up in all kinds of places:

-   When checking that arguments provided at a call site match the method's `sig`
-   When checking the value returned by a method against that method's `sig`
-   In the implementation of `T.let` and `T.cast` annotations
-   [Flow-sensitive checks](https://sorbet.org/docs/flow-sensitive) required by Sorbet,
    like in `case` expressions
-   Internal "fast path" guards for speculative optimizations, including:
    -   type-directed optimizations (e.g., [Types Make Array Access
        Faster](/types-make-array-access-faster/))
    -   direct calls for [final methods](https://sorbet.org/docs/final#final-methods)

So, runtime type checks show up all over the place, but how much faster are they? Let's
zoom in on the runtime type checks that happen in `case` expressions with some benchmarks:

  ---------------------------------------------------------
  benchmark                          interpreted   compiled
  -------------------------------- ------------- ----------
  [while_10_000_000.rb]                   0.212s     0.070s

  [case_nil_str_obj.rb]                   2.227s     0.142s

  case_nil_str_obj.rb − baseline          2.015s     0.072s
  ---------------------------------------------------------

[while_10_000_000.rb]: https://github.com/sorbet/sorbet/blob/master/test/testdata/ruby_benchmark/stripe/while_10_000_000.rb
[case_nil_str_obj.rb]: https://github.com/sorbet/sorbet/blob/master/test/testdata/ruby_benchmark/stripe/case_nil_str_obj.rb

The first benchmark, `while_10_000_000.rb`, is our baseline. It's just a Ruby `while` loop
that increments a counter 10 million times and then prints the counter. We subtract the
time it takes from other benchmarks to control for the fact that compiled `while` loops
really fast (see [Fast While Loops in Ruby](/fast-while-loops-in-ruby)).

Our real benchmark is `case_nil_str_obj.rb`. It has a bunch of case expressions that
basically look like this:

``` ruby
res =
  case x
  when String then true
  else false
  end
```

for a selection of different classes (`NilClass`, `String`, and `Object`) and values
(`nil` and `''`). After subtracting the baseline from both interpreted and compiled
timings, we see that what takes the interpreter 2.015s to run takes the compiler just
72ms. (And in fact, nearly all of that comes from the two `case` expressions checking for
`Object`—if we delete those two and leave just `NilClass` and `String` checks, the
compiled time drops down to about 8ms 🤯).

So the Sorbet compiler is **much** faster at runtime type checks than the Ruby VM... why is
that? There are a few reasons:

1.  Sorbet's type tests cut out the Ruby VM.
2.  Type tests for common Ruby classes have fast special cases.
3.  The power of LLVM gets us a lot of free wins.

I'd love to cover all of these, but for the sake of keeping this note short and sweet, I'm
only going to focus on the first two. (Let me know if you'd like to hear more about the
power of LLVM though!)

To see what "**cutting out the Ruby VM**" means, let's dig into a specific example.
Consider some code like we saw earlier:

``` ruby
res =
  case x
  when Integer then true
  else false
  end
```

We can get the Ruby VM to tell us the bytecode instructions that it translates this Ruby
program into with the `ruby` command line:

```{.tight-code}
❯ ruby --dump=insns -e "x = 0; case x when Integer then true else false end"
# ...
0000 putobject_INT2FIX_0_                ─┐ x = 0
0002 setlocal_WC_0            x@0        ─┘
0004 getlocal_WC_0            x@0        ─┐ store `x` on the Ruby stack
0006 dup                                 ─┘ (for checkmatch below)
0007 opt_getinlinecache       16, <is:0> ─┐
0010 putobject                true        │ load ::Integer constant
0012 getconstant              :Integer    │ (and populate inline cache)
0014 opt_setinlinecache       <is:0>     ─┘
0016 checkmatch               2          ─┐ compute `when Integer`, jump
0018 branchif                 24         ─┘ to 0024 if there's a match
0020 pop                                 ─┐
0021 putobject                false       │ false branch
0023 leave                               ─┘
0024 pop                                 ─┐
0025 putobject                true        │ true branch
0027 leave                               ─┘
```

*(I've annotated hand-annotated the output. Run the provided command to see the original
output.)*

If you're not familiar with bytecode instructions, you can imagine this as a sort of
assembly language that only the Ruby VM understands and that it evaluates in order to
execute a Ruby program.

So to do a type test in a `case` expression, the Ruby VM has to:

1.  Store the local variable `x` onto the Ruby stack
2.  Load the constant named `:Integer` by doing a search on `Object` and caching the
    result
    -   The cache will be shared across repeated invocations of the method, to speed up
        the search for next time.
3.  Run a `checkmatch` instruction to do the `when Integer` comparison, and then do a
    `branchif` conditional jump on the result.
    -   Not pictured: the `checkmatch` instruction involves searching for an `Integer.===`
        method definition, which is how the Ruby VM implements class matching.
4.  Use the result to jump to the corresponding branch

The problem is that this is an absolute **ton** of slow code. Here's a breakdown of all
the things I can see that are slow, and how the Sorbet compiler makes them faster.

First: storing variables on the stack (i.e., RAM) is much slower than registers (CPU). The
compiler keeps things in registers as much as possible.

Next up: searching for methods is slow. In this case, `Integer.===` is actually defined on
`Module`, which means chasing a lot of superclass pointers to find the class with the
`===` method:

``` plain
❯ irb
irb(main):001:0> Integer.singleton_class.ancestors
=> [#<Class:Integer>, #<Class:Numeric>, #<Class:Object>, #<Class:BasicObject>, Class, Module, Object, Kernel, BasicObject]
```

Instead of searching, the compiler can just know. Sorbet knows that `String.===`
dispatches to `Module#===`, and it knows that `Module#===` is implemented by a C function
called [`rb_obj_is_kind_of`]. Rather than doing a method search, it just calls
`rb_obj_is_kind_of` directly.

[`rb_obj_is_kind_of`]: https://github.com/ruby/ruby/blob/5445e0435260b449decf2ac16f9d09bae3cafe72/object.c#L1774-L1778

More than that, sometimes the `===` method isn't even needed. The Ruby VM has special ways
of doing type checks for the most common classes, like `Integer`, `NilClass`, `Array`, and
more. For `Integer` specifically, if the [least-significant bit] of a Ruby value is `1`,
then it's an `Integer`. Sorbet is aware of these [optimized type tests] and can emit code
to check them without even calling `rb_obj_is_kind_of`.

[least-significant bit]: https://github.com/ruby/ruby/blob/5445e0435260b449decf2ac16f9d09bae3cafe72/include/ruby/ruby.h#L444
[optimized type tests]: https://github.com/sorbet/sorbet/blob/f03e6be0599f509524a24273c0d14738048d5bc7/compiler/IREmitter/Payload.cc#L198

And last, using a bytecode instruction for conditional branches is expensive. Sorbet
compiles the conditional jump directly to an assembly instruction.

Putting that all together, in this case, Sorbet is able to do the `Integer` type test with
just three CPU instructions (I'm showing the corresponding LLVM IR instead of assembly to
make it easier to read):

``` llvm
; Take arg x (stored in register %rawArg_x) and bitwise AND with 0x1
%17 = and i64 %rawArg_x, 1, !dbg !35
; Compare whether %17 == 0
%18 = icmp eq i64 %17, 0, !dbg !35
; Jump to one of two branches depending on what the comparison said
br i1 %18, label %20, label %sorbet_isa_Integer.exit.thread, !dbg !35, !prof !36
```

Pretty amazing!

Runtime type checks are so fast in compiled code that we can afford to always emit them.
While most code at Stripe runs with runtime type checking enabled, there are a handful of
performance-sensitive paths in Stripe's codebase that use `.checked(:never)` annotations
on `sig`s to completely disable runtime type checking. This makes the code run faster, but
at the cost of runtime safety guarantees enjoyed by other parts of the codebase. With
compiled code, the checks are so fast that we don't have to strip them out to make the
code fast.
