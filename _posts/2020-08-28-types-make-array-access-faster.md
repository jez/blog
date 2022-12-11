---
# vim:tw=90
layout: post
title: "Types Make Array Access Faster"
date: 2020-08-28T20:21:30-05:00
description: >-
  A short discussion of how the Sorbet Compiler is able to use type information to perform
  certain operations faster than the Ruby VM can on its own.
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

I was looking at improving the performance of the Sorbet Compiler's generated code
on Stripe's feature flag library this week. I was trying to diagnose which parts of the
compiled code are faster and slower. Specifically, there were some profiler results that
that seemed to suggest the `x[y]` operation for hashes and arrays (the Ruby VM calls this
operation `aref`) might be a problem:

<!-- more -->

```ruby
xs = [123]
puts xs[0]
```

To isolate for sure whether this was a problem or not, we wrote a benchmark. It turns out
that we misinterpreted the `perf` profile! Array access is much faster in Sorbet:

| benchmark             | interpreted | compiled | speedup vs interpreted |
| :---                  | ---:        | ---:     | ---:                   |
| [typed_array_aref.rb] | 0.282s      | 0.061s   | 4.62x                  |

Here's the full benchmark:

```ruby
xs = T.let([123], T::Array[Integer])

i = 0
while i < 10_000_000
  xs[0]
  i += 1
end

puts xs[0]
```

But it turns out that the story doesn't end there. I re-ran the benchmark with some slight
modifications:

-   the same test, but with an empty `while` loop body
-   the same test, but marking the initial assignment to `xs` as untyped

With these benchmarks, we tease apart how much of the speedup is explained by various
parts of the compiled code. Namely, how much is explained by "the Sorbet Compiler just
does loops faster" and how much is explained by knowing a type statically:

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

(I've linked to the specific benchmarks in the Sorbet compiler codebase if you want to see
them.)

What we see in this table is that Sorbet-compiled Ruby is still "faster" in absolute terms
when the type of `xs` isn't known (untyped_array_aref.rb, 0.282s vs 0.174s). But in fact,
most of this absolute difference is because the compiled `while` loop was faster!

If we subtract the compiled `while` loop timings from the compiled times, and the
interpreted `while` loop timings from the interpreted timings, what's left is how much
time was actually spent in each benchmark doing the array access operation.

After doing those subtractions and computing the speedups, we see two things:[^slower]

-   The array access operation is actually slower than the Ruby VM if Sorbet doesn't have
    type information (0.61x speedup is less than 1, so it's a slowdown). As it turns out,
    the Ruby VM has special optimizations for `xs[0]` when `xs` is an `Array`.

-   With type information, Sorbet-compiled code is even faster than both the interpreted
    code and the compiled but untyped code. Specifically, the compiler only spent `0.013s`
    computing the array access given type information, vs the interpreter spent `0.077s`,
    and the compiled but untyped version took even more at `0.126s`.

[^slower]:
  **Editing note**: These numbers are unchanged from when I first measured in August 2020.
  They do not necessarily reflect the Sorbet Compiler's current performance.

This means that with types, the `Array` index operation compiled by Sorbet is (currently)
5.92x faster than the interpreter! I say currently because: the Sorbet compiler is very
much not finished. It could get faster or slower at any time.

Hopefully this gives a glimpse of why we're confident the compiler will have an impact.
Certain Ruby features are type-agnostic, and can be sped up even if code is untyped (like
`while` loops). Adding types (which are exceedingly common in Stripe's codebase at this
point) has the potential to make code even faster.

The examples in this post are obviously contrived (no one is writing `while` loops like
this in Stripe's codebase) but the idea is that if Sorbet can showcase speedups on any
individual part of a typed Ruby program, than all you have to do to do to get fast code is
add a `# compiled: true` comment to the top of a file and Sorbet will make every
individual part faster, and the effects will compound. Performance for free!

