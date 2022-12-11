---
# vim:tw=90
layout: post
title: "perf, Rinse, Repeat: Making the Sorbet Compiler faster"
date: 2021-05-23T19:43:22-05:00
description: TODO
math: false
categories: ['TODO']
categories: ['ruby', 'debugging', 'sorbet-compiler']
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

The prompt for today's post began as I asked myself, "Why is the Sorbet compiler slower
than the interpreter for this benchmark?" But in asking this question (originally just out
of curiosity), I accidentally nerd-sniped half my team into making some speedups.

Thus, this post continues an ongoing series looking into the performance of compiled Ruby.
Previous posts in the series:

-   [Types Make Array Access Faster](/types-make-array-access-faster/)
-   [Another Look at Typed Array Access](/another-look-at-typed-array-access/)
-   [Fast While Loops in Ruby](/fast-while-loops-in-ruby/)
-   [Instant Runtime Type Checks in Ruby](/instant-runtime-type-checks-in-ruby/)

Unlike those posts (which mostly say, "look how much faster Ruby is when compiled!"), this
post is about something the compiler is not great at (yet!).

Our agenda:

⏱ Introduce the benchmark, and measure it.\
🔬 Profile the benchmark, and find (one part of) what's slow.\
🚀 Make it faster.\
🤔 Close with some vague next steps.

Here's our benchmark:

<figure class="left-align-caption">
``` ruby
def returns_nilclass; nil; end

i = 0
while i < 10_000_000
  self.returns_nilclass
  i += 1
end
```
<figcaption>
[→ Full benchmark in the Sorbet repo](https://github.com/sorbet/sorbet/blob/master/test/testdata/ruby_benchmark/stripe/returns_nilclass/no_sig.rb)
</figcaption>
</figure>


It's got a method that does nothing, and we call it 10 million times. The compiler is
particularly fast with `while` loops (as I [mentioned
before](/types-make-array-access-faster/)), so we subtract out time spent running the
`while` loop when looking at benchmarks:

  ---------------------------------------------------------------------------
  benchmark                                            interpreted   compiled
  -------------------------------------------------- ------------- ----------
  [while_10_000_000.rb]                                     0.186s     0.067s

  [returns_nilclass/no_sig.rb]                              0.264s     0.206s

  returns_nilclass/no_sig.rb − while_10_000_000.rb          0.078s     0.139s
  ---------------------------------------------------------------------------

[while_10_000_000.rb]: https://github.com/sorbet/sorbet/blob/master/test/testdata/ruby_benchmark/stripe/while_10_000_000.rb
[returns_nilclass/no_sig.rb]: https://github.com/sorbet/sorbet/blob/master/test/testdata/ruby_benchmark/stripe/returns_nilclass/no_sig.rb

The compiler is \~61 ms, or 78%, slower—that's obviously not great. This 78% means that
the compiler starts "in the hole" every time it does a method call. We've
[already](/another-look-at-typed-array-access/) seen
[previous posts](/fast-while-loops-in-ruby/) showing
[specific things](/instant-runtime-type-checks-in-ruby/)
that the compiler can do faster than the interpreter, so getting a speed up in the real
world means a method has to contain enough of those fast operations to pay off the "debt"
of doing another method call.

I want to be clear now and say: our hypothesis is that there is **no fundamental reason**
why this debt has to exist; merely: it does right now. Our claim is that we can speed up
Ruby code as it occurs in real-world scenarios by compiling it.

At first, I was going to cut the post here, and say "yep, we haven't won yet!" But I
mentioned this slowness to my teammates, and we effectively sniped ourselves into making
it better. This is what we did to make it faster.

<!-- TODO(jez) If you ever port Diagnosing Compiler Performance to your blog, link it here -->

<!--
> Tangentially, the last N months of my life has been measuring and diagnosing
> performance. If you're interested, you might want to read my notes on performance:
>
> → [+🕵️‍♂️ Diagnosing Compiler Performance](...)
>
> I wrote it for "people working on the Sorbet compiler," but you'll find tips that apply
> in general if you look hard enough.
-->

Our first step once the program is already this small—a mere 7 lines of code 😎[^meme]—is to
profile it with [`perf`](http://www.brendangregg.com/perf.html):

[^meme]:
  **Editor's note**: "7 lines of code" is a [Stripe meme].

[Stripe meme]: https://stripe.com/blog/payment-api-design

![Largest self time: `func_Object#returns_nilclass`](/assets/img/perf-rinse-repeat-01.png)

The heaviest entry by `Self` time is `func_Object#returns_nilclass`. That's the C function
the compiler emitted containing the code for our Ruby-level `returns_nilclass` method
above.

<!-- TODO(jez) "by Self time" used to link to the relevant section in Diagnosing Compiler Performance -->

Perf lets us dig into an individual method's assembly to see where the time is spent.
Here's the hot instructions:[^debug]

[^debug]:
  You’ll notice: we even emit debug info, mapping which Ruby-level line these instructions
  came from!\
  \
  It means that if you run Ruby under `gdb` and print a backtrace, sometimes you’ll see C
  files in the backtrace (from inside the Ruby VM), and sometimes you’ll see Ruby files
  (for C functions emitted by the Sorbet compiler).

![body of `returns_nilclass` when compiled](/assets/img/perf-rinse-repeat-02.png)

What immediately stands out is a long chain of `mov` instructions at the top of the
method, followed by an `add`. In particular, you'll notice these `mov` instructions all
look like:

``` gnuassembler
mov smallNumber(%register1),%register2
```

It's super esoteric (thanks, [AT&T assembly syntax]),[^intel] but this means: take
`%register1`, add `smallNumber` to it, assume the result is an address, get the value
stored there and put it in `%register2`.

[AT&T assembly syntax]: https://elronnd.net/writ/2021-02-13_att-asm.html

[^intel]:
  Comment from Nathan: "`perf report -M intel ...` ought to use a more reasonable
  disassembly syntax."

Sound familiar? That's basically the **assembly equivalent of `foo->bar` in C**. Start
with `foo` which is an address, add some number to get the address of the `bar` field, and
dereference to get the result. Since there's a bunch of these `mov` instructions in a row,
we probably have something like `foo->bar->qux->zap`.

Why is this slow? Bad cache locality. Chances are good that following any of those
pointers means jumping to a completely different data structure stored in memory that's
not cached.

Skipping to the answer, these `mov` instructions came from code in the Sorbet compiler
designed to reach into one of the VM's data structures and pull out a field called
`iseq_encoded` which, among other things, is important for setting up line number
information for Ruby backtraces:

``` c
const VALUE *sorbet_getIseqEncoded(rb_control_frame_t *cfp) {
    return cfp->iseq->body->iseq_encoded;
}
```

[→ Code here in codegen-payload.c](https://github.com/sorbet/sorbet/commit/0ff3751ea#diff-9c37838fc00fae9eb63691612abaa1c8a683401145d7f5a614d0c854c900da86L1130-L1132)

This code looks pretty much exactly like what we expected to find!

At this point, Trevor had an insight: we already know the contents of that `iseq_encoded`
field statically (because the compiler allocated it earlier and stored the result in a
known location). That means we don't even need this code at all. He [put together a
PR](https://github.com/sorbet/sorbet/commit/0ff3751ea) implementing the change.

Then Nathan followed on with a [similar
change](https://github.com/sorbet/sorbet/commit/56812a019), noticing that the compiled
code was doing `ruby_current_execution_context_ptr->cfp` in a bunch of places where we
could have instead passed `cfp` from the caller.

After another `perf` run, there's far less self time spent in `func_Object#returns_nilclass`!

![`perf` output after those changes](/assets/img/perf-rinse-repeat-03.png)

What took \~23.82% of self time before only takes \~8.23% now (making everything else take
proportionally more time). If we dig into the assembly again, we notice **two big
differences**:

<figure class="left-align-caption">
![Disassembly, from before](/assets/img/perf-rinse-repeat-04.png){width="43.9%" style="display: inline;"}
![Disassembly, after these two changes](/assets/img/perf-rinse-repeat-05.png){width="54.1%" style="display: inline;"}
<figcaption>
**Left**: disassembly from before. **Right**: disassembly after these two changes.
</figcaption>
</figure>

-   The `mov` chain is gone, and has been replaced with a reference to `iseqEncodedArray`
    (a global variable holding the `iseq_encoded` thing that the compiler allocated).
-   The `ruby_current_execution_context_ptr` is gone, because `cfp` is now passed from the
    caller as the fourth argument (unused, or we would see a mention of the `%r9`
    register).

But the real question: did it actually get faster? Or did we just shuffle the samples
around? We can answer by running the benchmark again:

  ---------------------------------------------------------------------------
  benchmark                                            interpreted   compiled
  -------------------------------------------------- ------------- ----------
  returns_nilclass/no_sig.rb - baseline, before             0.078s     0.139s

  returns_nilclass/no_sig.rb - baseline, after              0.079s     0.127s
  ---------------------------------------------------------------------------


The compiled version **speeds up by about 12 ms**, or 8.6%, dropping the difference
between compiled and interpreted from 78% slower to 60% slower. This is definitely good
news, but maybe not quite as good as we would have hoped (the compiler is still slower
than the interpreter). So what's next?

At this point, nearly all the slowness comes from the call site, not the definition.
Taking another look at the new perf output, we see that the heaviest methods by self time
are now:

-   32.92% – `sorbet_callFuncWithCache`
    -   A Sorbet compiler method that gets ready to call back from compiled code into the
        VM.
-   22.57% – `vm_call_sorbet_with_frame_normal`
    -   A method that we've patched into the Ruby VM that makes calling Ruby C extension
        functions faster.
-   18.45% – `vm_search_method`
    -   A method in the Ruby VM that answers, "For a method with name `foo` on value `x`,
        what method entry do I call?"

These functions all happen before the `func_Object#returns_nilclass` method is called. I'm
sure that we'll dig into them as a team eventually, but for now, I don't know why they're
slow! But the process of finding out what's wrong would look the exact same:

-   Profile and stare at the assembly to find the hot code.
-   Have a stroke of insight to realize, "wait, we can just… not do this"
    -   (or, more rare: "we need to do this, but it's faster if we do it another way").
-   Repeat until it's fast.

There are a handful of other places where we know the compiler isn't quite up to snuff
yet, and priority number one right now is to eliminate them so that we can deliver real
performance wins with the Sorbet compiler in production.
