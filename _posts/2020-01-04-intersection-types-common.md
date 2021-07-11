---
layout: post
title: "Intersection Types in Sorbet are Surprisingly Common"
date: 2020-01-04 19:50:32 -0600
comments: false
share: false
categories: ['sorbet', 'ruby', 'types']
description: >
  Conventional knowledge is that union types are common and intersection
  types are rare. But actually that's not the case—intersection types
  show up in nearly every program Sorbet type checks thanks to control
  flow.
---

Conventional knowledge is that union types are common and intersection
types are rare. But actually that's not the case—intersection types
show up in nearly every program Sorbet type checks thanks to control
flow.

[Union types] in Sorbet are incredibly common, which should be no
surprise. In Sorbet, `T.nilable(...)` is sugar for `T.any(NilClass,
...)`. `T.nilable` shows up all over the place and probably catches more
bugs than any other feature in Sorbet.

[Union types]: https://sorbet.org/docs/union-types

Sorbet also has [intersection types]. While union types mean "either
this or that," intersection types mean "both this and that." On first
glance, intersection types seem like some super niche feature which only
benefits a handful of programs. In Stripe's Ruby monorepo, the strings
`T.any` and `T.nilable` occur nearly 300 times more than `T.all` does.

[intersection types]: https://sorbet.org/docs/intersection-types

But those numbers hide something critical: intersection types power
Sorbet's [control flow-sensitive typing]. They're actually present in
every Ruby program, but just a little hard to spot. Let's look at how
pervasive they are with a few examples:

[control flow-sensitive typing]: https://sorbet.org/docs/flow-sensitive

```ruby
# typed: strict
extend T::Sig

class Parent; end
class Child < Parent; end

sig {params(x: Parent).void}
def example1(x)
  case x
  when Child
    T.reveal_type(x) # Revealed type: `Child`
  end
end
```

<a href="https://sorbet.run/#%23%20typed%3A%20strict%0Aextend%20T%3A%3ASig%0A%0Aclass%20Parent%3B%20end%0Aclass%20Child%20%3C%20Parent%3B%20end%0A%0Asig%20%7Bparams(x%3A%20Parent).void%7D%0Adef%20example1(x)%0A%20%20case%20x%0A%20%20when%20Child%0A%20%20%20%20T.reveal_type(x)%20%23%20Revealed%20type%3A%20%60Child%60%0A%20%20end%0Aend">→ View on sorbet.run</a>

Here `x` starts out having type `Parent`, but inside the `case`
statement Sorbet treats `x` as having the more specific type `Child`.
There's no `T.all` in sight, but that's because it's hiding. Sorbet
doesn't just throw away the fact that it knew `x <: Parent`. Instead, it
uses `T.all` to update its type for `x` to `T.all(Parent, Child)`.

`T.all(Parent, Child)` is equivalent to `Child` because `Child` is a
subtype of `Parent`. If types represent sets of values, then the set of
values represented by `Child` is a subset of the set of values
represented by `Parent`, so the intersection of those two sets would
just leave `Child`.[^methods]

[^methods]: If you're not convinced, consider: with `T.all(Parent, Child)` we should be able to call all the methods on `Parent` and all the methods on `Child`. But `Child` inherits `Parent`'s methods, so any method `Parent` has will already be on `Child`. So `Child` is equivalently good as `T.all(Parent, Child)`.

Sorbet attempts to simplify a large type to a smaller, equivalent type
when it can for two reasons:

- [**Usability**]{.smallcaps} – Most users don't know that `T.all` means
  "intersection type" or even what intersection types are. (And even
  those who do still end up drawing Venn diagrams from time to time!) It
  only gets more complicated when `T.all`s and `T.any`s nest inside each
  other.

  Meanwhile, `Child` is a super easy type to understand, and leads to
  nice, short error messages.

- [**Performance**]{.smallcaps} – Checking whether one type is a subtype
  of another is a super common operation, so it has to be fast. By
  collapsing `T.all(Parent, Child)` to `Child`, Sorbet does at least
  half as much work when checking subtyping (probably more, because of
  some common path optimizations).

  When this simplification happens, Sorbet even skips an allocation
  entirely. Cnstructing `T.all(Parent, Child)` in Sorbet short
  circuits and returns a reference to the already allocated `Child` type
  that was passed as an argument (with ownership tracked via
  `std::shared_ptr`[^modern-cpp]).

[^modern-cpp]: If you're looking for a good intro to modern C++ things like `shared_ptr`, I can't recommend [this blog post series](https://berthub.eu/articles/posts/cpp-intro/) enough.

Let's look at another example of control flow:

```ruby
# typed: strict
extend T::Sig

class A; end
class B; end

sig {params(a_or_b: T.any(A, B)).void}
def example2(a_or_b)
  case a_or_b
  when A
    T.reveal_type(a_or_b) # Revealed type: `A`
  end
end
```

<a href="https://sorbet.run/#%23%20typed%3A%20strict%0Aextend%20T%3A%3ASig%0A%0Aclass%20A%3B%20end%0Aclass%20B%3B%20end%0A%0Asig%20%7Bparams(a_or_b%3A%20T.any(A%2C%20B)).void%7D%0Adef%20example2(a_or_b)%0A%20%20case%20a_or_b%0A%20%20when%20A%0A%20%20%20%20T.reveal_type(a_or_b)%20%23%20Revealed%20type%3A%20%60A%60%0A%20%20end%0Aend">→ View on sorbet.run</a>

This example method accepts either `A` or `B` (`T.any(A, B)`) and then
branches on whether `a_or_b` is an instance of `A`. Again: Sorbet
doesn't throw away that it knows `a_or_b <: T.any(A, B)`. Instead it
updates its knowledge of the type of `a_or_b` using `T.all` to get
`T.all(T.any(A, B), A)`. Realizing that this is equivalent to `A` is a
bit trickier:

```ruby
T.all(T.any(A, B), A)

# Distribute
T.any( T.all(A, A) , T.all(B, A) )

# T.all(A, A) is just A (idempotence)
T.any( A , T.all(B, A) )

# A and B are classes (not mixins) and neither inherits the other.
# It's impossible to have a value of that type, so it's bottom:
T.any( A , T.noreturn )

# bottom is the identity of union
A
```

You can start to see how usability and performance and might get a
little out of hand if Sorbet didn't keep attempting to simplify things!
The cumulative effect of all the control flow in a program would result
in huge, unweidly types.

Until now you could claim that I've been hyping up intersection types as
the solution to problems that were self-imposed. That if we just
invented some other method for modeling control flow, it would have been
naturally usable or naturally performant, and we wouldn't have had
problems in the first place. So next let's look at some examples to see
why intersection types really are the most natural solution:

```ruby
module I1
  def foo1; end
end
module I2
  def foo2; end
end

sig {params(x: I1).void}
def example3(x)
  x.foo1  # Works outside
  case x
  when I2
    x.foo1  # Should (and does) still work inside
    x.foo2
  end
end
```

<a href="https://sorbet.run/#%23%20typed%3A%20true%0Aextend%20T%3A%3ASig%0A%0Amodule%20I1%0A%20%20def%20foo1%3B%20end%0Aend%0Amodule%20I2%0A%20%20def%20foo2%3B%20end%0Aend%0A%0Asig%20%7Bparams(x%3A%20I1).void%7D%0Adef%20example3(x)%0A%20%20x.foo1%20%20%23%20Works%20outside%0A%20%20case%20x%0A%20%20when%20I2%0A%20%20%20%20x.foo1%20%20%23%20Should%20(and%20does)%20still%20work%20inside%0A%20%20%20%20x.foo2%0A%20%20end%0Aend%0A">→ View on sorbet.run</a>

Unlike in the other examples, this is the first example where had we
tried to implement control-flow-sensitive typing by throwing away the
old type and using the new type instead it wouldn't have worked. The key
thing to notice: this example uses modules. Outside the `case` of course
calling `x.method_from_1` works because `x` starts out at type `I1`. But
if we treated `x` as only `I2` inside the `when I2`, we'd start
reporting an error for calling `x.method_from_1` because it doesn't
exist on `I2`.

Unlike intersecting unrelated classes (our `T.all(B, A)` example from
earlier), intersecting unrelated modules does't collapse to
`T.noreturn`. There's nothing stopping some class from including both
`I1` and `I2`. Instances of that class would be values of type
`T.any(I1, I2)`:

```ruby
class SomeClass
  include I1
  include I2
end

# This type assertion is okay:
T.let(SomeClass.new, T.all(I1, I2))
```

<a href="https://sorbet.run/#%23%20typed%3A%20true%0Aextend%20T%3A%3ASig%0A%0Amodule%20I1%0A%20%20def%20foo1%3B%20end%0Aend%0Amodule%20I2%0A%20%20def%20foo2%3B%20end%0Aend%0A%0Asig%20%7Bparams(x%3A%20I1).void%7D%0Adef%20example3(x)%0A%20%20x.foo1%20%20%23%20Works%20outside%0A%20%20case%20x%0A%20%20when%20I2%0A%20%20%20%20x.foo1%20%20%23%20Should%20(and%20does)%20still%20work%20inside%0A%20%20%20%20x.foo2%0A%20%20end%0Aend%0A%0Aclass%20SomeClass%0A%20%20include%20I1%0A%20%20include%20I2%0Aend%0A%0A%23%20This%20type%20assertion%20is%20okay%3A%0AT.let(SomeClass.new%2C%20T.all(I1%2C%20I2))">→ View on sorbet.run</a>

So at least for implementing certain cases of flow sensitive typing,
we'll *need* intersection types anyways. Then for these certain cases
we'd incur the usability and performance problems we discovered earlier
and have to solve them.

But more than that, intersection types are fundamentally easier to work
with compared to some ad hoc approach to flow sensitive typing. Type
system bugs are weird. It's frquently harder to figure out whether the
current behavior is buggy in the first place than it is to find the
cause!

In that light, intersection types present an elegant, robust model for
arriving at what the correct behavior *should* be, independent of what
Sorbet's existing behavior is. It's clear how intersection types
interact with union types, and with subtyping, and with generics, and
with variance, etc.

By repurposing intersection types to model control flow sensitivity,
when things go wrong there's a framework for discovering what's right.

(Speaking of repurposing, intersection types also play an important role
in how Sorbet [suggests potential method signatures]! That's three birds
with one stone.)

[suggests potential method signatures]: https://sorbet.run/#%23%20typed%3A%20strict%0Aextend%20T%3A%3ASig%0A%0Amodule%20M%3B%20end%0Amodule%20N%3B%20end%0A%0Asig%20%7Bparams(m%3A%20M).void%7D%0Adef%20takes_m(m)%3B%20end%0Asig%20%7Bparams(n%3A%20N).void%7D%0Adef%20takes_n(n)%3B%20end%0A%0Adef%20needs_sig(x)%0A%20%20takes_m(x)%0A%20%20takes_n(x)%0Aend


<!-- vim:tw=72
-->
