---
# vim:tw=90 fo-=tc
layout: post
title: "A trick for invariant generics in Sorbet"
date: 2024-06-05T20:28:55-04:00
description: >
  There's a neat trick for using generic methods to get around some of the limitations that invariant type members in generic classes carry.
math: false
categories: ['ruby', 'sorbet']
# subtitle:
# author:
# author_url:
---

There's a neat trick for using generic methods to get around some of the limitations that invariant type members in generic classes carry.

The problem I'm trying to solve:

- Sometimes my generic class (say, `Box`) needs a `type_member` (say, `Elem`) to be invariant, because the type member is used in both [input and output positions]. For example, maybe this is a generic, mutable container (as contrasted with an immutable, read-only container).

- ... but I still want to allow covariant subtyping in methods that take this generic type as an argument. For example, if I write a method that takes a `Box[Numeric]`, you should be able to call it if you have a `Box[Integer]`. Normally, the fact that `Elem` is invariant prevents this.

The solution is to change the parameter type from `Box[Numeric]` to the more generic `Box[T.all(T.type_parameter(:Elem), Numeric)]`.[^bounds]

[^bounds]:
  {-} You'll recognize this type (rather verbose) type as typical of a method which wants to [place bounds on generic methods].

At this point, let's just look at code.

## Statement of the problem

Here's our mutable, invariant `Box` class:

```{.ruby .numberLines .hl-8 .hl-16 .hl-20}
class Box
  extend T::Sig
  extend T::Generic

  # Needs to be invariant: this type supports reading
  # and writing the `val` field
  # (appears in both input and output positions)
  Elem = type_member

  sig { params(val: Elem).void }
  def initialize(val)
    @val = val
  end

  sig { returns(Elem) }
  #             ^^^^ output position
  attr_reader :val

  sig { params(val: Elem).returns(Elem) }
  #                 ^^^^ input position
  attr_writer :val
end
```

A method which operates on `Box[Numeric]` is allowed to do things like this:

```{.ruby .numberLines .hl-4 .hl-8}
sig { params(box: Box[Numeric]).void }
def mutates_numeric_box(box)
  # Can call arbitrary Numeric methods:
  raise unless box.val.zero?

  # Can set the value of the box to any Numeric,
  # regardless of what was in it before.
  box.val = (1 / 2r)
  #         ^^^^^^^^ instance of Rational
end
```

Recall that because of invariance, Sorbet has to reject things like this:

```{.ruby}
complex_box = Box[Complex].new(3 + 4i)
mutates_numeric_box(complex_box)
#                   ^^^^^^^^^^^ ❌ Box[Complex] is not a subtype of Box[Numeric]
radius = complex_box.val.polar.fetch(0)
#                        ^^^^^ runtime: 💥 Method `polar` does not exist on `Rational`
```

Sorbet must report an error on the call to `mutates_numeric_box`: after the call, Sorbet still thinks that `complex_box` has type `Box[Complex]` but it actually holds a `Rational` value. Allowing the program to continue is disastrous, and the program crashes with an exception on the call to `polar` on the next line.

It's frustrating because the only way to get from a `Box[Complex]` to a `Box[Numeric]` (so that we can call this method at all) is to make an entirely new box, with an explicitly wider type:

```ruby
numeric_box = Box[Numeric].new(complex_box.val)
```

... which is annoying on its own (imagine having to do this for every call to `mutates_numeric_box`!) but having done this, there's no way to safely recover the fact that this `Box[Numeric]` started with a `Complex`. That fact has been forgotten.

## What we can do instead, and what we give up

We can define our method using `type_parameters` (with a [pseudo bound][place bounds on generic methods]), which allows being called with `Box[Complex]`, but places more constraints on what we're allowed to do inside the method itself.

```{.ruby .numberLines .hl-15 .hl-16 .hl-17}
sig do
  type_parameters(:Elem)
    .params(
      box: Box[T.all(T.type_parameter(:Elem), Numeric)],
      elem: T.all(T.type_parameter(:Elem), Numeric)
    )
    .void
end
def mutates_generic_numeric_box(box, elem)
  initial_value = box.val

  # Can still call arbitrary Numeric methods:
  raise unless box.val.zero?

  # CAN'T set val to an arbitrary Numeric value
  # (It might not have been a Box that holds strings!)
  box.val = (1 / 2r)
  #          ^^^^^^ ❌ Rational is not a subtype of
  #                    T.all(T.type_parameter(:Elem), Numeric)
  #                    (because Rational is not a subtype of
  #                    T.type_parameter(:Elem))

  # ... but we CAN set val to a user-provided value:
  box.val = elem

  # ... and we CAN set val to its original value:
  box.val = initial_value
end
```

Note the new constraints on this implementation. We're no longer able to overwrite `val` with an arbitrary `Numeric` value, like we could before with `Rational`. It's not like we can't set this field at all: we just need something with the right type. As I discuss in [Sorbet, Generics, and Parametricity], this limits us to only set `val` to something we've been given as an argument. In our case, we've been given `box.val` and `elem`—those are the **only** two things we're allowed to assign to `val`.

This is... not all that limiting in practice? Especially considering that it means we're now allowed to use subtyping at the call site:

```{.ruby}
complex_box = Box[Complex].new(3 + 4i)
mutates_generic_numeric_box(complex_box, 4 + 3i) # ✅
radius = complex_box.val.polar.fetch(0)          # ✅
```

\

\

The only real tradeoff with this approach is that the generic signature with `type_parameters` is quite verbose.[^verbose] Verbosity aside, the tradeoffs which limit what kinds of method implementations are allowed are not typically show-stopping limitations in real-world code.

[^verbose]:
  {-} I have some ideas for what the new syntax should be, it's mostly just an open question of whether the feature should be more or less syntactic sugar for the current syntax with `T.all` and have bad error messages, or whether we should expand Sorbet's type system to track bounds on type parameters, possibly introducing uncaught bugs.

- For more information on variance and generics in Sorbet, see the docs:\
  [Generic Classes and Methods →](https://sorbet.org/docs/generics)

- For the full code in this post in sorbet.run:\
  [View in sorbet.run →](https://sorbet.run/#%23%20typed%3A%20strict%0Aextend%20T%3A%3ASig%0A%0Aclass%20Box%0A%20%20extend%20T%3A%3ASig%0A%20%20extend%20T%3A%3AGeneric%0A%0A%20%20%23%20Needs%20to%20be%20invariant%3A%20this%20type%20supports%20reading%0A%20%20%23%20and%20writing%20the%20%60val%60%20field%0A%20%20%23%20%28appears%20in%20both%20input%20and%20output%20positions%29%0A%20%20Elem%20%3D%20type_member%0A%0A%20%20sig%20%7B%20params%28val%3A%20Elem%29.void%20%7D%0A%20%20def%20initialize%28val%29%0A%20%20%20%20%40val%20%3D%20val%0A%20%20end%0A%0A%20%20sig%20%7B%20returns%28Elem%29%20%7D%0A%20%20%23%20%20%20%20%20%20%20%20%20%20%20%20%20%5E%5E%5E%5E%20output%20position%0A%20%20attr_reader%20%3Aval%0A%0A%20%20sig%20%7B%20params%28val%3A%20Elem%29.returns%28Elem%29%20%7D%0A%20%20%23%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%5E%5E%5E%5E%20input%20position%0A%20%20attr_writer%20%3Aval%0Aend%0A%0Asig%20%7B%20params%28box%3A%20Box%5BNumeric%5D%29.void%20%7D%0Adef%20mutates_numeric_box%28box%29%0A%20%20%23%20Can%20call%20arbitrary%20Numeric%20methods%3A%0A%20%20raise%20unless%20box.val.zero%3F%0A%0A%20%20%23%20Can%20set%20the%20value%20of%20the%20box%20to%20any%20Numeric%2C%0A%20%20%23%20regardless%20of%20what%20was%20in%20it%20before.%0A%20%20box.val%20%3D%20%281%20%2F%202r%29%0A%20%20%23%20%20%20%20%20%20%20%20%20%5E%5E%5E%5E%5E%5E%5E%5E%20instance%20of%20Rational%0Aend%0A%0Acomplex_box%20%3D%20Box%5BComplex%5D.new%283%20%2B%204i%29%0Amutates_numeric_box%28complex_box%29%0A%23%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%5E%5E%5E%5E%5E%5E%5E%5E%5E%5E%5E%20%E2%9D%8C%20Box%5BComplex%5D%20is%20not%20a%20subtype%20of%20Box%5BNumeric%5D%0Aradius%20%3D%20complex_box.val.polar.fetch%280%29%0A%23%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%5E%5E%5E%5E%5E%20runtime%3A%20%F0%9F%92%A5%20Method%20%60polar%60%20does%20not%20exist%20on%20%60Rational%60%0A%0Anumeric_box%20%3D%20Box%5BNumeric%5D.new%28complex_box.val%29%0Amutates_numeric_box%28numeric_box%29%0A%0A%23%20------------------------------------------%0A%0Asig%20do%0A%20%20type_parameters%28%3AElem%29%0A%20%20%20%20.params%28%0A%20%20%20%20%20%20box%3A%20Box%5BT.all%28T.type_parameter%28%3AElem%29%2C%20Numeric%29%5D%2C%0A%20%20%20%20%20%20elem%3A%20T.all%28T.type_parameter%28%3AElem%29%2C%20Numeric%29%0A%20%20%20%20%29%0A%20%20%20%20.void%0Aend%0Adef%20mutates_generic_numeric_box%28box%2C%20elem%29%0A%20%20initial_value%20%3D%20box.val%0A%0A%20%20%23%20Can%20still%20call%20arbitrary%20Numeric%20methods%3A%0A%20%20raise%20unless%20box.val.zero%3F%0A%0A%20%20%23%20CAN'T%20set%20val%20to%20an%20arbitrary%20Numeric%20value%0A%20%20%23%20%28It%20might%20not%20have%20been%20a%20Box%20that%20holds%20strings!%29%0A%20%20box.val%20%3D%20%281%20%2F%202r%29%0A%20%20%23%20%20%20%20%20%20%20%20%20%20%5E%5E%5E%5E%5E%5E%20%E2%9D%8C%20Rational%20is%20not%20a%20subtype%20of%0A%20%20%23%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20T.all%28T.type_parameter%28%3AElem%29%2C%20Numeric%29%0A%20%20%23%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%28because%20Rational%20is%20not%20a%20subtype%20of%0A%20%20%23%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20T.type_parameter%28%3AElem%29%29%0A%0A%20%20%23%20...%20but%20we%20CAN%20set%20val%20to%20a%20user-provided%20value%3A%0A%20%20box.val%20%3D%20elem%0A%0A%20%20%23%20...%20and%20we%20CAN%20set%20val%20to%20its%20original%20value%3A%0A%20%20box.val%20%3D%20initial_value%0Aend%0A%0Acomplex_box%20%3D%20Box%5BComplex%5D.new%283%20%2B%204i%29%0Amutates_generic_numeric_box%28complex_box%2C%204%20%2B%203i%29%20%23%20%E2%9C%85%0Aradius%20%3D%20complex_box.val.polar.fetch%280%29%20%20%20%20%20%20%20%20%20%20%23%20%E2%9C%85%0A)



[input and output positions]: https://sorbet.org/docs/generics#input-and-output-positions
[place bounds on generic methods]: https://sorbet.org/docs/generics#placing-bounds-on-generic-methods
[Sorbet, Generics, and Parametricity]: https://blog.jez.io/sorbet-parametricity/
