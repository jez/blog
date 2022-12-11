---
# vim:tw=90
layout: post
title: "Another Look at Typed Array Access"
date: 2020-09-11T18:36:14-05:00
description: >-
  I take another look at how the Sorbet Compiler handles optimizing certain kinds of typed
  code patterns.
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

Last week in [Types Make Array Access Faster](/types-make-array-access-faster) we compared
the Ruby VM's performance on array accesses with the Sorbet Compiler's performance on
array accesses, as an example of how making types available to the Sorbet Compiler let it
speed up code. The snippet under scrutiny was basically this operation:

``` ruby
xs[0]
```

but repeated many (10M) times to make the performance difference obvious.

The data we collected looked like this:

:::{.wide .extra-wide}

  -------------------------------------------------------------------------------------------------
  benchmark                 interpreted   compiled  interpreted,\    compiled,\  compiler speedup,\
                                                      minus while   minus while           w/o while
  ------------------------ ------------ ---------- -------------- ------------- -------------------
  [while_10_000_000.rb]          0.205s     0.048s             —              —                   —

  [untyped_array_aref.rb]        0.282s     0.174s        0.077s         0.126s               0.61x

  [typed_array_aref.rb]          0.282s     0.061s        0.077s         0.013s               5.92x
  -------------------------------------------------------------------------------------------------

:::

[while_10_000_000.rb]: https://github.com/sorbet/sorbet/blob/master/test/testdata/ruby_benchmark/stripe/while_10_000_000.rb
[untyped_array_aref.rb]: https://github.com/sorbet/sorbet/blob/master/test/testdata/ruby_benchmark/stripe/untyped_array_aref.rb
[typed_array_aref.rb]: https://github.com/sorbet/sorbet/blob/master/test/testdata/ruby_benchmark/stripe/typed_array_aref.rb

And our ultimate conclusion was:

> With type information, Sorbet-compiled code is even faster than both the interpreted
> code and the compiled but untyped code.

But there was an interesting caveat along the way:

> The array access operation is actually slower than the Ruby VM if Sorbet doesn't have
> type information (0.61x speedup is less than 1, so it's a slowdown).

The idea was that for our plain `xs[0]` program, the compiler was actually **slower** than
the interpreter.

Why was the compiler slower?

It turns out that array access is one of the operations the Ruby VM is already pretty good
at, because it's special cased. We can check this looking at the [bytecode instructions]
that the Ruby VM uses to evaluate an array access:

[bytecode instructions]: https://en.wikipedia.org/wiki/Bytecode

``` plain
❯ ruby --dump=insns -e 'xs = []; xs[0]'
== disasm: #<ISeq:<main>@-e:1 (1,0)-(1,14)> (catch: FALSE)
local table (size: 1, argc: 0 [opts: 0, rest: -1, post: 0, block: -1, kw: -1@-1, kwrest: -1])
[ 1] xs@0
0000 newarray                     0                                   (   1)[Li]
0002 setlocal_WC_0                xs@0
0004 getlocal_WC_0                xs@0
0006 putobject_INT2FIX_0_
0007 opt_aref                     <callinfo!mid:[], argc:1, ARGS_SIMPLE>, <callcache>
0010 leave
```

Here's how to read this output:

-   We used the special `--dump=insns` flag to the `ruby` command line. You can try this at home!

-   Theres some stuff we don't need on the first few lines, and then the bytecode instructions start with the line reading `0000`.

-   The actual instruction that corresponds to the `xs[0]` instruction happens at index `0007`. The name of the instruction is `opt_aref`.

That's interesting! Instead of treating array access like any other method call,[^aside]
it treats it as a special, optimized instruction called `opt_aref`. Checking [the
implementation of that instruction], we find that the optimization only works if the
method receiver (`xs` in this case) is **exactly** an instance of the `Array` or `Hash`
class.

[^aside]:
  Did you know that square brackets are [just a method call] in Ruby?

[just a method call]: https://sorbet.run/#%23%20typed%3A%20true%0Aclass%20MyClass%0A%20%20extend%20T%3A%3ASig%0A%0A%20%20sig%20%7Bparams%28arg0%3A%20Integer%29.returns%28String%29%7D%0A%20%20def%20%5B%5D%28arg0%29%0A%20%20%20%20arg0.to_s%0A%20%20end%0Aend%0A%0Ax%20%3D%20MyClass.new%0AT.reveal_type%28x%5B0%5D%29%20%23%20!!

[the implementation of that instruction]: https://github.com/ruby/ruby/blob/a0c7c23c9cec0d0ffcba012279cd652d28ad5bf3/vm_insnhelper.c#L4523-L4549

In other words, it's easy to defeat this optimization by subclassing `Array`:

``` ruby
class MyArray < Array
end

xs = MyArray.new([2])
xs[0]
```

In this case, since `xs` is not exactly `Array` or `Hash` anymore, the optimization won't
apply, and [the Ruby VM falls back] to calling a method named `[]` on `xs` with argument
`0`.

[the Ruby VM falls back]: https://github.com/ruby/ruby/blob/a0c7c23c9cec0d0ffcba012279cd652d28ad5bf3/insns.def#L1305-L1309

We can see the effect of this by writing another Sorbet compiler benchmark, and adding it to our table:

:::{.wide .extra-wide}

  ----------------------------------------------------------------------------------------------------------
  benchmark                          interpreted   compiled  interpreted,\    compiled,\  compiler speedup,\
                                                               minus while   minus while           w/o while
  --------------------------------- ------------ ---------- -------------- ------------- -------------------
  [while_10_000_000.rb]                   0.205s     0.048s             —              —                   —

  [untyped_array_aref.rb]                 0.282s     0.174s        0.077s         0.126s               0.61x

  [typed_array_aref.rb]                   0.282s     0.061s        0.077s         0.013s               5.92x

  [untyped_array_subclass_aref.rb]        0.388s     0.172s        0.183s         0.124s               1.48x
  ----------------------------------------------------------------------------------------------------------

:::

[untyped_array_subclass_aref.rb]: https://github.com/sorbet/sorbet/blob/master/test/testdata/ruby_benchmark/stripe/untyped_array_subclass_aref.rb


By changing the untyped `Array` to an untyped subclass of `Array`, the interpreter slows
down[^slower] an extra 0.106ms, but our compiled version doesn't care whether it was the
`Array` case or `MyArray` case, because they're both untyped.

[^slower]:
  **Editing note**: These numbers are unchanged from when I first measured in September
  2020. They do not necessarily reflect the Sorbet Compiler's current performance.

Now that the Ruby VM hasn't effectively special cased our benchmark, the compiler starts
to shine! This is another reason why we're really optimistic about the impact of the
compiler. Our initial plans were to speed up typed code, and count on other teams adding
types everywhere. While adding types **definitely** helps (look at that 5.92x speedup!),
the compiler can still speed up certain kinds of untyped code, too.

