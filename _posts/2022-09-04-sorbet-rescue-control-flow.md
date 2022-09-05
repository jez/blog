---
# vim:tw=95
layout: post
title: "Sorbet’s weird approach to exception handling"
date: 2022-09-04T23:12:12-04:00
description:
  A quick post explaining why exception handling in Sorbet is weird, by way of a buggy program
  and some pretty pictures.
math: false
categories: ['ruby', 'sorbet', 'types']
# subtitle:
# author:
# author_url:
---

Here's a fun bug in Sorbet:

<figure class="left-align-caption">

```{.ruby .numberLines .hl-11 .hl-12}
def example
  begin
    loop_count = 0

    while true
      sleep(1)
      loop_count += 1
    end
  rescue Interrupt
    if loop_count
      puts("Looped #{loop_count} times")
    # ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ error: This code is unreachable
    end
  end
end
```

<figcaption>[→View on sorbet.run][example1]</figcaption>

[example1]: https://sorbet.run/#%23%20typed%3A%20true%0A%0Adef%20example%0A%20%20begin%0A%20%20%20%20loop_count%20%3D%200%0A%0A%20%20%20%20while%20true%0A%20%20%20%20%20%20sleep%281%29%0A%20%20%20%20%20%20loop_count%20%2B%3D%201%0A%20%20%20%20end%0A%20%20rescue%20Interrupt%0A%20%20%20%20if%20loop_count%0A%20%20%20%20%20%20puts%28%22Looped%20%23%7Bloop_count%7D%20times%22%29%0A%20%20%20%20end%0A%20%20end%0Aend

</figure>

Sorbet thinks that `loop_count` has type `NilClass` at the start of the `rescue` block, which
causes it to declare that the `puts` line is dead (because `NilClass` is never truthy).

But why? Clearly, we can see that `loop_count` is an `Integer`. We'd expect Sorbet to _at
least_ think `loop_count` has type `T.nilable(Integer)`, if not simply `Integer` outright.

When developing Sorbet, sometimes we choose an implementation because it's good enough, most of
the time, but is simple to implement and/or fast. Sorbet's approach to `rescue` and exception
handling is one such choice.

# Control flow and `rescue` in Sorbet

I mentioned in [my last post] that Sorbet builds a [**control flow graph**]{.smallcaps} (CFG)
in order to model control-flow sensitive types throughout the body of a method. But for
`rescue` nodes, it takes one of those "good enough, most of the time" shortcuts. It pretends
that there are only two jumps into the `rescue` block: once before any **any** code in the
`begin` block has run, and once after **all** the code in `begin` block has run:

:::{.only-light-mode}
![A hand-drawn diagram of a CFG showing how `rescue` works](/assets/img/rescue-cfg-light-mode.png)
:::

:::{.only-dark-mode}
![A hand-drawn diagram of a CFG showing how `rescue` works](/assets/img/rescue-cfg-dark-mode.png)
:::

This is a diagram of what a CFG in Sorbet mostly[^mostly] looks like. The conditions for these
jumps read from a magical `<exn-value>` variable, which Sorbet treats as
[**unanalyzable**]{.smallcaps}: Sorbet doesn't attempt to track how the value is initialized
nor how control flow affects it. At any point it might be truthy or falsy, so Sorbet will
always assume both outcomes could happen.

[^mostly]:
  If you have [Graphviz] installed, you can get Sorbet to dump its internal CFG for a given
  file with the `cfg-view.sh` script in the Sorbet repo. The CFG for the example above looks
  like [like this](/assets/img/rescue-example-01.svg).

Knowing this, we can explain the behavior in the example above:

- Since the first jump into the `rescue` block happens, the `loop_count` variable is still
  uninitialized at that point, and thus has type `NilClass` at that point.
- The second jump into the `rescue` block happens after the `begin` block finishes. But from
  Sorbet's point of view, the `begin` block never finishes: Sorbet sees the infinite `while
  true` loop and thinks that it's impossible for control to ever leave the `begin` block.[^loop]

[^loop]:
  If you're fearless, you can prove that this is what's happening in the [rendered
  CFG](/assets/img/rescue-example-01.svg) for the above example.

That second point is [simply a bug][4108]. Sorbet should be smart enough to suspend the normal
rules it applies when processing code that infinitely loops (or unconditionally raises) while
checking code in a `begin` block that has a `rescue`.[^said] But still, fixing that bug would
only make Sorbet think that `loop_count` has type `T.nilable(Integer)` in the `rescue`
body—remember we said that ideally Sorbet would know that `loop_count` is **always**
initialized, having type `Integer`.

[^said]:
  easier said than done, lol

So then, what is that weird jump to the `rescue` body doing there? Intuitively, taking that
branch means that the `begin` block raised an exception _before ever running a single line
of code in the begin block_. To answer this, some history.

# A brief history of `rescue` in Sorbet

Sorbet's [first commit] dates to October 3, 2017. Six weeks later, the [initial support for
`rescue`][afb23474] landed. The pull request description is from a time when all pull requests
were Stripe-internal, so I'll quote it here:

> This does most of the work in the CFG, preserving the semantics in the desugarer. This is
> nice since we can treat these differently if we want since we have the information this late.
>
> It introduces a series of uncomputable `if`s since 0 or more instructions from the first
> block will execute then one of the `rescue`s could match and then if none do the `else` will
> match. Check out the `.svg`s to see the chaining.
>
> If an invalid name is put in the exception expression, it will be caught by the namer since
> the tree walk goes through them.

Maybe that description only makes sense if you're a Sorbet developer. The approach it's
describing is what most people might do intuitively: any instruction in a `begin` might raise,
so record a jump from each instruction in the `begin` block to the `rescue` block. In picture
form:

:::{.only-light-mode}
![A diagram depicting the implementation described in the above commit](/assets/img/rescue-cfg-multi-block-light-mode.png)
:::

:::{.only-dark-mode}
![A diagram depicting the implementation described in the above commit](/assets/img/rescue-cfg-multi-block-dark-mode.png)
:::

After the code at the start of the method, control flows immediately to the first line of the
`begin` body. But every line of the `begin` body gets its own, tiny basic block with an
unanalyzable jump to the `rescue` block, or to the next line of the body. On its own, this
was probably enough to fix the bug in our initial example—there would be a jump after the
`loop_count = 0` assignment into the `rescue` block, so when merging all the previous
environments, Sorbet would now be able to see that `loop_count` is an `Integer`.

But importantly, this original approach was thrown out. Which brings us to our second point of
history, when [almost exactly 9 months later][a6ed41e0][^2018] the "only before and after"
approach arrived. In fact, a comment from that commit persists unchanged in the codebase today:

[^2018]:
  And only two days after I joined the team 😅

<figure class="left-align-caption">

```cpp
// We have a simplified view of the control flow here but in
// practise it has been reasonable on our codebase.
// We don't model that each expression in the `body` or `else` could
// throw, instead we model only never running anything in the
// body, or running the whole thing. To do this we  have a magic
// Unanalyzable variable at the top of the body using
// `rescueStartTemp` and one at the end of the else using
// `rescueEndTemp` which can jump into the rescue handlers.
```

<figcaption>
[→ View in `cfg/builder/builder_walk.cc`](https://github.com/sorbet/sorbet/blob/e63d2893edecc30e3eda5cd3378e02b8996e866f/cfg/builder/builder_walk.cc#L761-L768)
</figcaption>
</figure>

If we just said that the original approach didn't yield the bug in our original example, why
adopt this new approach?

For starters, the first approach had an even more insidious bug:

```ruby
begin
  x = might_raise()
  # ...
rescue
  # Sorbet would assume `x` was always set
  puts(x)
end
```

The original `rescue` implementation had a bit of an of off-by-one error, where it would think
that `x` (being an assignment as the very first instruction) would be set unconditionally. But
if the initializer for `x` raises, it in fact **won't** be set in the `rescue` block. Checking
to see whether a variable you were hoping was set by a rescue block but which might not
actually be set is much more common in correct code than asserting in the rescue block that
something was for sure set.[^unconditional] Even still: that problem on its own would have been
easy enough to fix, but there was a second problem: typechecking performance.

[^unconditional]:
  And intuitively there's an easy workaround: if you expect some variable to be unconditionally
  set, don't set it in the `begin` block, set it outside!

There are a lot of reasons why having lots of tiny basic blocks is bad for performance:

- It's not just the number of basic blocks. Sorbet also had to duplicate a bunch of setup code
  to make sure that those unanalyzable `<exn-value>` variables actually existed in the CFG. So
  the absolute number of instructions in the CFG was larger, too (versus the same number of
  instructions, but just distributed to more basic blocks).

- When finalizing a CFG, Sorbet has to compute the variables that each basic block reads and
  writes. The algorithms inside Sorbet to compute which variables are [live] by a given point
  scale poorly when there are lots of blocks.

- When typechecking a method, every basic block in the CFG requires its own [`Environment`]
  data structure, which maps variables to their types within that block. Sorbet either has to
  allocate a separate `Environment` per block (what it currently does) or incur complexity
  from making them [copy-on-write]. [Allocating is slow][nelhage-sorbet-fast] and we really
  like to avoid complexity.

- Before typechecking a basic block, Sorbet has to merge the environments of all blocks that
  can jump into it. Merging environments involves doing slow type checking operations
  (checking whether two possibly-arbitrary types are subtypes of each other).

The new "only before and after" approach is pretty clever. In practice, it more or less models
the "raise in first assignment" case while generating far fewer basic blocks, thus running much
faster.

# The bigger picture

There's a lot of these clever "good enough" tricks in Sorbet. In a sense, a lot of them are
only possible because of the stakes: Sorbet _already_ allows [`T.untyped`], so depending on
your viewpoint, either:

- There is already the holy grail of all hacks in the type system, so why not cut corners
  elsewhere when it makes sense.
- _Because_ `T.untyped` is in the type system, at least if there's a bug in Sorbet the user can
  always work around it by way of `T.untyped`.

Either way, in some sense the stakes are low. In a compiler where the stakes for being wrong
are higher (the code compute the wrong answer), maybe shortcuts aren't the best idea. And in
fact, [multiple][2962] [distinct][3044] [exception][4488] [changes][4531] landed in Sorbet's
CFG code to support the Sorbet Compiler.

It's now been over four years since we shipped the change to model `rescue` this way. I'm not
aware of a single incident caused by this bug, and I can only directly remember being asked why
Sorbet has behavior like this twice (and I read *a lot* of Sorbet questions). I can't find any
performance numbers from when the original change landed, but we can still put it into
perspective: it's the difference between a handful of people being confused over the course of
4 years, or thousands of people getting faster typechecking results thousands of times per day.
Seems like a reasonable trade-off.

Though eventually it would be nice to at least fix [that earlier bug][4108]. 😅



[my last post]: /syntactic-control-flow/
[graphviz]: https://graphviz.org/
[4108]: https://github.com/sorbet/sorbet/issues/4108
[first commit]: https://github.com/sorbet/sorbet/commit/9189734a6c061071c3d3cd4398a5d7874a8c0c49
[afb23474]: https://github.com/sorbet/sorbet/commit/afb234741f4ccd98ca2903d1621746c64a2da5ab
[a6ed41e0]: https://github.com/sorbet/sorbet/commit/a6ed41e0b8deee28ff592063934b28676ac77927#diff-c9b037996e9c16464e031136abe5d9df567c72f283d572b070d108228b733127R335-R342
[live]: https://en.wikipedia.org/wiki/Live-variable_analysis
[`Environment`]: https://github.com/sorbet/sorbet/blob/master/infer/environment.h#L127
[copy-on-write]: https://en.wikipedia.org/wiki/Copy-on-write
[nelhage-sorbet-fast]: https://blog.nelhage.com/post/why-sorbet-is-fast/
[`T.untyped`]: https://sorbet.org/docs/gradual
[2962]: https://github.com/sorbet/sorbet/pull/2962
[3044]: https://github.com/sorbet/sorbet/pull/3044
[4488]: https://github.com/sorbet/sorbet/pull/4488
[4531]: https://github.com/sorbet/sorbet/pull/4531









