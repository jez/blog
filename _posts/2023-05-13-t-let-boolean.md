---
# vim:tw=90
layout: post
title: "Why Sorbet needs T.let(..., T::Boolean)"
date: 2023-05-13T19:31:29-04:00
description: >
  A short explanation of why Sorbet sometimes requires an explicit type annotation when
  initializing a variable whose type is changed in a loop.
math: false
categories: ['ruby', 'sorbet', 'types']
# subtitle:
# author:
# author_url:
---


Here's something everyone who's new to Sorbet trips over:

<figure class="left-align-caption">

```ruby
found_it = false
items.each do |item|
  if item == thing
    found_it = true
    #          ^^^^ error:
    # Changing the type of a variable is not permitted
    # Existing variable has type: `FalseClass`
    # Attempting to change type to: `TrueClass`
  end
end
```

<figcaption>
[View on sorbet.run →](https://sorbet.run/#%23%20typed%3A%20true%0Aextend%20T%3A%3ASig%0A%0Asig%20%7Bparams%28items%3A%20T%3A%3AArray%5BString%5D%2C%20thing%3A%20String%29.void%7D%0Adef%20example%28items%2C%20thing%29%0A%20%20found_it%20%3D%20false%0A%20%20items.each%20do%20%7Citem%7C%0A%20%20%20%20if%20item%20%3D%3D%20thing%0A%20%20%20%20%20%20found_it%20%3D%20true%0A%20%20%20%20end%0A%20%20end%0Aend%0A)
</figcaption>
</figure>

The fix is to change `found_it = false` to `found_it = T.let(false, T::Boolean)`.

But this is annoying and confusing, especially because basically no other type checker
works this way. That makes it a good candidate to change so that Sorbet spends less time
getting in people's way.

And in fact, I _have_ tried changing it! I want to talk about why this error exists at
all, and my failed attempts at improving this.

## Why does Sorbet have this weird error?

For performance and understandability.

As Nelson mentions in [Why Sorbet is Fast], Sorbet's inference algorithm is forward-only.
This means that Sorbet inspects every piece of code in a method body at most once during
inference, never revisiting a piece of code it's already typechecked. Not only does this
approach mean doing a linear amount of work, it means doing _one_ unit of work per piece
of code—the constant factors matter! It also means code at the bottom of a method never
affects a type Sorbet inferred 100 lines earlier.

But "forward-only" is weird, because control flow graphs in Sorbet[^cfg] can have cycles!
It's not possible to strictly sort code in a Sorbet CFG from start to finish. Consider
this program:

[^cfg]:
  {-} For more idiosyncrasies of Sorbet's CFGs, see [Sorbet's weird approach to exception
  handling] or [Control Flow in Sorbet is Syntactic].


```{.ruby .numberLines .hl-1 .hl-4 .hl-5}
x = 42
i = 0
while i < 2
  takes_integer(x)
  x = nil
  i += 1
end
```

The CFG for this snippet looks something like this:[^real-cfg]

[^real-cfg]:
  {-} If you really want to dive into Sorbet's internals, you can get it to print
  the exact CFG for a piece of code. See [docs/internals.md: CFG].

![](/assets/img/light/t-let-boolean-cfg.png){style="max-width: 575px;"}

![](/assets/img/dark/t-let-boolean-cfg.png){style="max-width: 575px;"}

On line 1, Sorbet infers that `x` is `Integer`. This means the call to `takes_integer` on
line 4 typechecks. But then on line 5, Sorbet realizes that inferring a type of `Integer`
for `x` was a mistake: it should have inferred `T.nilable(Integer)`, but it's too
late--Sorbet isn't going to go back to line one and infer that `x` has type
`T.nilable(Integer)`. Sorbet has already missed an error it should have reported: the call
to `takes_integer` (the second time through this loop, the call to `takes_integer` will
actually pass `nil` instead of an `Integer`). To prevent this snippet from sneaking
through without _any_ errors, it reports an error when it sees the incompatible assignment
to `x` on line 5. Better late than never.

Importantly, Sorbet only needs this if the assignment happens inside a loop, because it's
the cycles in the CFG that cause problems. Also, Sorbet always assumes that blocks are
loops, because Sorbet can't know how many times a method will call a block. If the
assignment which widens the type happens in non-cyclic code, there's no type annotation
needed.

**TL;DR**: Sorbet has this "incompatible assignment" error because without it, it would
either miss reporting important type errors, or have to use a slower type inference
algorithm with more action at a distance.

## Okay, but why not just assume that `true` and `false` are `T::Boolean`?

This compromises the expressive power of Sorbet's type system.

You'll notice the original error mentioned `TrueClass` and `FalseClass`:

```
Existing variable has type: `FalseClass`
Attempting to change type to: `TrueClass`
```

That exposes that Sorbet tracks in which environments a variable is known to be exactly
`true` or `false`, in addition to when it's `T::Boolean`.

Maybe this is the problem? Maybe Sorbet should just assume that `x = true` results in `x`
having type `T::Boolean`, which would avoid the need for the `T.let`.

But that causes other problems. Sorbet is really good at modeling situations where
one variable being truthy implies some _other_ variable has a particular type.[^neat] For
example:

[^neat]:
  {-} I'm told this is one of the particularly novel parts of Sorbet's inference
  algorithms—[Dmitry], who built it, speaks highly of it. It's probably worth writing
  about more in the future.

```{.ruby .numberLines .hl-5 .hl-7 .hl-12}
sig {params(bank_acct: T.nilable(String)).void}
def example(bank_acct)
  check_balance = false

  if bank_acct   # now we know it's not nil
    if is_special_account(bank_acct)
      check_balance = true
    end
  end

  if check_balance
    T.reveal_type(bank_acct) # error: `String`
  end
end
```

On line 12, Sorbet is smart enough to see that `bank_acct` is not `nil`, because we've
we're in an environment where `check_balance` is truthy, and we know that `check_balance`
was only set to a truthy value in environments where `bank_acct` was not `nil`.
Altogether, this allows the user to omit a redundant check to assert that `bank_acct` is
not `nil` directly on line 11.

If we changed Sorbet to treat `check_balance = true` as having type `T::Boolean` instead
of `FalseClass`, that would prevent Sorbet from modeling complex control-flow situations
like this.

I actually [tried building something][4368] that did that, and it caused many problems in
real world code that looked just like the code above. In the end, we decided against
landing the change, with the reasoning that the error message for changing a variable in a
loop is very clear, has an autocorrect, and the resulting `T.let`'d code is very obvious.

By contrast, the error message if we did it the other way would have non-obvious error
messages. There would have been workarounds to get code like the above to type check, but
they would have contorted the code, making it substantially less obvious why the code was
written like it was. And it would likely have been impossible to write autocorrects to
introduce those workarounds, so people would have had to learn them by reading the docs,
not via error messages.

\

\

So that's why Sorbet is like this, and what we've tried to do to fix this in the past.
This is still probably one of the most annoying parts of Sorbet, so it's not unreasonable
to hope it'll get fixed one day. If you think you have a solution, feel free to let me
know!


[Why Sorbet is Fast]: https://blog.nelhage.com/post/why-sorbet-is-fast/#forward-only-inference
[Sorbet's weird approach to exception handling]: /sorbet-rescue-control-flow/
[Control Flow in Sorbet is Syntactic]: /syntactic-control-flow/
[docs/internals.md: CFG]: https://github.com/sorbet/sorbet/blob/master/docs/internals.md#cfg
[Dmitry]: https://github.com/DarkDimius
[4368]: https://github.com/sorbet/sorbet/pull/4368

