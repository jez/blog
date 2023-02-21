---
# vim:tw=90
layout: post
title: "Typing klass.new in Ruby with Sorbet"
date: 2023-02-19T22:34:27-05:00
description:
  The straightforward attempt at writing a Sorbet signature for a method that calls
  `klass.new` doesn't work. The strategy that does work uses abstract methods, and so I'd
  like to walk through an extended example showing how to get such code to typecheck.
math: false
categories: ['sorbet', 'ruby', 'types']
# subtitle:
# author:
# author_url:
---

A pattern like this comes up a lot in Ruby code:

```ruby
def instantiate_class(klass)
  instance = klass.new
  # ... use `instance` somehow ...
  instance
end
```

(If you don't believe me, try grepping your codebase for `klass.new`—you might be
surprised. Where I work, I see well over 100 matches just using the variable name `klass`
alone.)

The straightforward attempt at writing a [Sorbet] signature for this method doesn't work.
The strategy that _does_ work uses abstract methods, which brings me to one of my
most-offered tips for type-level design in Sorbet:

[Sorbet]: https://sorbet.org

:::{.note .yellow}

------
🏆 &emsp; You should be using more abstract methods.
------

:::

In this post, we'll take a quick look[^quick] at the most common incorrect approach to
annotate this method, discuss why that approach doesn't work, then circle back and see how
to use abstract methods to type this method.

[^quick]:
  {-} If you're short on time or don't care for explanations, here's the [final
  code][final-example] we'll build towards.

# ⛔️ What people try: `T.class_of`

This is the method signature people try to write:

```{.ruby .numberLines .hl-4}
sig do
  type_parameters(:U)
    # !! This code does not work !!
    .params(klass: T.class_of(T.type_parameter(:U)))
    .returns(T.type_parameter(:U))
end
def instantiate_class(klass)
  instance = klass.new
  # ...
  instance
end
```

This type **does not work**.[^syntax] Even though I can see why people might expect it to
work, there are reasons why it should not work (at least, [not using the syntax
above][62]). Specifically, `T.type_parameter(:U)` doesn't stand for "some unknown class,"
it stands for "some unknown type." It could mean any of `T.any(Integer, String)`,
`T::Array[Integer]`, `T.noreturn`, or any other type.

Meanwhile, `T.class_of(...)` in Sorbet is defined very narrowly to mean "get the singleton
class of `...`." For an arbitrary type, that might not exist. On occasion we have tossed
around ideas for how to (partially) relax this constraint, but you don't have to wait for
such a feature to arrive: abstract methods and interfaces are powerful enough to model
this today.

[^syntax]:
  {-} Sometimes I wish Sorbet had used the syntax `A.singleton_class` instead of
  `T.class_of(A)`, because I think it might have made it more clear that you can't do this
  on arbitrary types. Then again, maybe people would have just done `T.any(A,
  B).singleton_class`

[62]: https://github.com/sorbet/sorbet/issues/62

# ✅ How to solve this with `abstract` methods

When we see something like this:

```ruby
def instantiate_class(klass)
  klass.new
end
```

and we want to write a precise type here, what's critical is to notice that there is some
de-facto API that `klass` is meant to conform to. That's exactly what interfaces are for.

In particular, the de-facto API is that `klass` has some method that tells us how to
create instances. Let's translate that API to an interface:

<figure class="left-align-caption">

```{.ruby .numberLines .hl-5 .hl-7 .hl-8 .hl-17}
module ThingFactory
  extend T::Generic
  interface!

  Instance = type_member(:out)

  sig {abstract.returns(Instance)}
  def make_thing; end
end

sig do
  type_parameters(:Instance)
    .params(klass: ThingFactory[T.type_parameter(:Instance)])
    .returns(T.type_parameter(:Instance))
end
def instantiate_class(klass)
  klass.make_thing
end
```

<figcaption>[→ View on sorbet.run](https://sorbet.run/#%23%20typed%3A%20strict%0Aclass%20Module%3B%20include%20T%3A%3ASig%3B%20end%0A%0Amodule%20ThingFactory%0A%20%20extend%20T%3A%3AGeneric%0A%20%20interface!%0A%0A%20%20Instance%20%3D%20type_member%28%3Aout%29%0A%0A%20%20sig%20%7Babstract.returns%28Instance%29%7D%0A%20%20def%20make_thing%3B%20end%0Aend%0A%0Asig%20do%0A%20%20type_parameters%28%3AInstance%29%0A%20%20%20%20.params%28klass%3A%20ThingFactory%5BT.type_parameter%28%3AInstance%29%5D%29%0A%20%20%20%20.returns%28T.type_parameter%28%3AInstance%29%29%0Aend%0Adef%20instantiate_class%28klass%29%0A%20%20klass.make_thing%0Aend)</figcaption>

</figure>

This `ThingFactory` has two notable definitions: a [`type_member`] called `Instance`
(which means this is a _generic_ interface), and a method called `make_thing`.

[`type_member`]: https://sorbet.org/docs/generics#type_member--type_template

As we'll see shortly, the `Instance` type member will act a bit like an "abstract"
type—it'll be something that implementation classes fill in later.

Calling the method `make_thing` (instead of `new`) is a slight sacrifice. Choosing a name
other than `new` helps Sorbet check that all classes accept the same number of constructor
arguments, with compatible types. (Technically, we could use a method named `new` in our
interface, but that runs into a [handful] of [fixable] or maybe [unfixable] bugs. It's
kind of up to you whether you care about the convenience of using the name `new`
everywhere at the cost of these bugs.)

Personally, I like that choosing a different name makes implementing the interface more
explicit, and thus easier for future readers to see what's going on.

[handful]: https://sorbet.run/#%23%20typed%3A%20strict%0Aclass%20Module%3B%20include%20T%3A%3ASig%3B%20end%0A%0Amodule%20ThingFactory%0A%20%20extend%20T%3A%3AGeneric%0A%20%20interface!%0A%0A%20%20Instance%20%3D%20type_member%28%3Aout%29%0A%0A%20%20sig%20%7Babstract.returns%28Instance%29%7D%0A%20%20def%20new%3B%20end%0Aend%0A%0Asig%20do%0A%20%20type_parameters%28%3AInstance%29%0A%20%20%20%20.params%28klass%3A%20ThingFactory%5BT.type_parameter%28%3AInstance%29%5D%29%0A%20%20%20%20.returns%28T.type_parameter%28%3AInstance%29%29%0Aend%0Adef%20instantiate_class%28klass%29%0A%20%20klass.new%0Aend%0A%0Aclass%20BadThing%0A%20%20extend%20T%3A%3AGeneric%0A%20%20extend%20ThingFactory%0A%20%20Instance%20%3D%20type_template%28%3Aout%29%20%7B%20%7Bfixed%3A%20BadThing%7D%20%7D%0A%0A%20%20sig%20%7Boverride.returns%28Instance%29%7D%0A%20%20def%20self.new%0A%20%20%20%20%23%20should%20be%20fine%2C%20maybe%3F%0A%20%20%20%20%23%20it's%20a%20valid%20override%20of%20ThingFactory%23new%2C%0A%20%20%20%20%23%20but%20an%20invalid%20override%20of%20Class%23new.%0A%0A%20%20%20%20%23%20https%3A%2F%2Fgithub.com%2Fsorbet%2Fsorbet%2Fissues%2F6564%0A%20%20%20%20super%0A%20%20end%0Aend
[fixable]: https://sorbet.run/?arg=--print=ast#%23%20typed%3A%20strict%0Aclass%20Module%3B%20include%20T%3A%3ASig%3B%20end%0A%0Amodule%20ThingFactory%0A%20%20extend%20T%3A%3AGeneric%0A%20%20interface!%0A%0A%20%20Instance%20%3D%20type_member%0A%0A%20%20sig%20%7Babstract.params%28x%3A%20Integer%29.returns%28Instance%29%7D%0A%20%20def%20new%28x%29%3B%20end%0Aend%0A%0Asig%20do%0A%20%20type_parameters%28%3AInstance%29%0A%20%20%20%20.params%28klass%3A%20ThingFactory%5BT.type_parameter%28%3AInstance%29%5D%29%0A%20%20%20%20.returns%28T.type_parameter%28%3AInstance%29%29%0Aend%0Adef%20instantiate_class%28klass%29%0A%20%20klass.new%280%29%0Aend%0A%0Aclass%20BadThing1%0A%20%20extend%20T%3A%3AGeneric%0A%20%20extend%20ThingFactory%0A%20%20Instance%20%3D%20type_template%28%3Aout%29%20%7B%20%7Bfixed%3A%20BadThing1%7D%20%7D%0A%0A%20%20%23%20Should%20be%20an%20error%20for%20forgetting%20to%20implement%20the%0A%20%20%23%20constructor%20%28which%20needs%20a%20required%20arg%2C%20so%20the%0A%20%20%23%20call%20to%20%60klass.new%280%29%60%20will%20fail%20at%20runtime%0A%0A%20%20%23%20https%3A%2F%2Fgithub.com%2Fsorbet%2Fsorbet%2Fissues%2F1317%0Aend%0A%0Aclass%20BadThing2%0A%20%20extend%20T%3A%3AGeneric%0A%20%20extend%20ThingFactory%0A%20%20Instance%20%3D%20type_template%28%3Aout%29%20%7B%20%7Bfixed%3A%20Integer%7D%20%7D%0A%0A%20%20sig%20%7Bvoid%7D%0A%20%20def%20self.example%0A%20%20%20%20x%20%3D%20new%280%29%0A%20%20%20%20T.reveal_type%28x%29%20%23%20%3D%3E%20Integer%0A%20%20%20%20%23%20%28x%20is%20an%20instance%20of%20%60BadThing2%60%20at%20runtime%29%0A%20%20%20%20%23%0A%20%20%20%20%23%20There%20should%20be%20some%20sort%20of%20error%20either%20on%20the%0A%20%20%20%20%23%20%60extend%60%20or%20the%20%60fixed%60%20that%20says%20this%20is%20a%20bad%0A%20%20%20%20%23%20override.%0A%0A%20%20%20%20%23%20https%3A%2F%2Fgithub.com%2Fsorbet%2Fsorbet%2Fissues%2F1317%0A%20%20end%0Aend
[unfixable]: https://sorbet.run/#%23%20typed%3A%20strict%0Aclass%20Module%3B%20include%20T%3A%3ASig%3B%20end%0A%0Amodule%20ThingFactory%0A%20%20extend%20T%3A%3AGeneric%0A%20%20interface!%0A%0A%20%20Instance%20%3D%20type_member%28%3Aout%29%0A%0A%20%20sig%20%7Babstract.returns%28Instance%29%7D%0A%20%20def%20new%3B%20end%0Aend%0A%0Asig%20do%0A%20%20type_parameters%28%3AInstance%29%0A%20%20%20%20.params%28klass%3A%20ThingFactory%5BT.type_parameter%28%3AInstance%29%5D%29%0A%20%20%20%20.returns%28T.type_parameter%28%3AInstance%29%29%0Aend%0Adef%20instantiate_class%28klass%29%0A%20%20klass.new%0Aend%0A%0Aclass%20BadThing1%0A%20%20extend%20T%3A%3AGeneric%0A%20%20extend%20ThingFactory%0A%20%20Instance%20%3D%20type_template%28%3Aout%29%20%7B%20%7Bfixed%3A%20BadThing1%7D%20%7D%0A%0A%20%20sig%20%7Bparams%28x%3A%20Integer%29.void%7D%0A%20%20def%20initialize%28x%29%0A%20%20%20%20%23%20should%20be%20an%20error%2C%20because%20this%20behaves%0A%20%20%20%20%23%20as%20if%20%60new%60%20has%20an%20extra%2C%20required%20param%20now%0A%0A%20%20%20%20%23%20%28no%20tracking%20issue%29%0A%20%20end%0Aend

In any case, here's how we can implement that interface:

<figure class="left-align-caption">

```{.ruby .numberLines .hl-3 .hl-4 .hl-7 .hl-18}
class GoodThing
  extend T::Generic
  extend ThingFactory
  Instance = type_template(:out) { {fixed: GoodThing} }

  sig {override.returns(Instance)}
  def self.make_thing # ✅
    new
  end
end

class BadThing
  extend T::Generic
  extend ThingFactory
  Instance = type_template(:out) { {fixed: BadThing} }

  sig {override.params(x: Integer).returns(Instance)}
  def self.make_thing(x) # ⛔️ must accept no more than 0 required arguments
    new
  end
end
```

<figcaption>
[→ View complete example on sorbet.run](https://sorbet.run/#%23%20typed%3A%20strict%0Aclass%20Module%3B%20include%20T%3A%3ASig%3B%20end%0A%0Amodule%20ThingFactory%0A%20%20extend%20T%3A%3AGeneric%0A%20%20interface!%0A%0A%20%20Instance%20%3D%20type_member%28%3Aout%29%0A%0A%20%20sig%20%7Babstract.returns%28Instance%29%7D%0A%20%20def%20make_thing%3B%20end%0Aend%0A%0Asig%20do%0A%20%20type_parameters%28%3AInstance%29%0A%20%20%20%20.params%28klass%3A%20ThingFactory%5BT.type_parameter%28%3AInstance%29%5D%29%0A%20%20%20%20.returns%28T.type_parameter%28%3AInstance%29%29%0Aend%0Adef%20instantiate_class%28klass%29%0A%20%20klass.make_thing%0Aend%0A%0Aclass%20GoodThing%0A%20%20extend%20T%3A%3AGeneric%0A%20%20extend%20ThingFactory%0A%20%20Instance%20%3D%20type_template%28%3Aout%29%20%7B%20%7Bfixed%3A%20GoodThing%7D%20%7D%0A%0A%20%20sig%20%7Boverride.returns%28Instance%29%7D%0A%20%20def%20self.make_thing%20%23%20%E2%9C%85%0A%20%20%20%20new%0A%20%20end%0Aend%0A%0Aclass%20BadThing%0A%20%20extend%20T%3A%3AGeneric%0A%20%20extend%20ThingFactory%0A%20%20Instance%20%3D%20type_template%28%3Aout%29%20%7B%20%7Bfixed%3A%20BadThing%7D%20%7D%0A%0A%20%20sig%20%7Boverride.params%28x%3A%20Integer%29.returns%28Instance%29%7D%0A%20%20def%20self.make_thing%28x%29%20%23%20%E2%9B%94%EF%B8%8F%20must%20accept%20no%20more%20than%200%20required%20arguments%0A%20%20%20%20new%0A%20%20end%0Aend)
</figcaption>
</figure>

See how the `BadThing` class attempts to incompatibly implement `make_thing`? Sorbet
correctly reports an error on line 18 saying that `make_thing` must not accept an extra
required argument.

Earlier we mentioned that `Instance` would behave kind of like an abstract
type,[^handwavy] and we see that happen on line 4. The code uses [`fixed`] to declare that
`Instance` within this class is equivalent to `GoodThing`. Kind of like how abstract
methods get concrete implementations, this `fixed` annotation acts almost like a concrete
implementation of the interface's "abstract" type `Instance`.

[`fixed`]: https://sorbet.org/docs/generics#bounds-on-type_members-and-type_templates-fixed-upper-lower

[^handwavy]:
  {-} This explanation largely appeals to intuition. _Abstract type_ has a specific
  meaning in the theory that's different from the meaning I'm using here, which is why
  I've scare-quoted or hedged my use of the term use in this post.

Something else worth mentioning: we're implementing this interface on the **singleton
class** of `GoodThing` and `BadThing`:

- On line 3, we use `extend` (instead of `include`) to mix in the interface.
- On line 4, what was a `type_member` in `ThingFactory` becomes a `type_template` in the
  implementation.
- On line 7, `def make_thing` from the interface becomes `def self.make_thing`.

So far so good: we've successfully annotated our `instantiate_class` method! But we can
actually take it one step further.


# 🔧 Extending the abstraction

Sometimes, the snippet we're trying to annotate isn't _just_ doing `klass.new`. Rather,
it's instantiating an object and then **calling some method** on that instance. The type
we've written so far won't allow that:

```{.ruby .numberLines .hl-4 .hl-5}
# sig {...}
def instantiate_class
  instance = klass.make_thing
  instance.foo
  #        ^^^ ⛔️ Call to method `foo` on unconstrained generic type
  instance
end
```

This is yet another another problem we can solve with abstract methods.

First, we define some interface `AbstractThing` which has an abstract `foo` method on it.
(Depending on the code we're trying to annotate, such an interface might already exist!)

```{.ruby .numberLines .hl-1 .hl-5 .hl-6 .hl-13 .hl-18}
module AbstractThing
  extend T::Helpers
  abstract!

  sig {abstract.returns(Integer)}
  def foo; end
end

# ...

class GoodThing
  extend T::Generic
  include AbstractThing
  extend ThingFactory

  # ...

  sig {override.returns(Integer)}
  def foo; 0; end
end
```

With that interface in hand, we use [`T.all`] to constrain the generic type argument to
`ThingFactory`.

[`T.all`]: https://sorbet.org/docs/intersection-types
[approximates bounds on `T.type_parameter`s]: https://sorbet.org/docs/generics#placing-bounds-on-generic-methods

<figure class="left-align-caption">

```{.ruby .numberLines .hl-5 .hl-12}
sig do
  type_parameters(:Instance)
    .params(
      klass: ThingFactory[
        T.all(AbstractThing, T.type_parameter(:Instance))
      ]
    )
    .returns(T.type_parameter(:Instance))
end
def instantiate_class(klass)
  instance = klass.make_thing
  instance.foo # ✅ OK
  instance
end
```

<figcaption>
[→ View complete example on sorbet.run](https://sorbet.run/#%23%20typed%3A%20strict%0Aclass%20Module%3B%20include%20T%3A%3ASig%3B%20end%0A%0Amodule%20AbstractThing%0A%20%20extend%20T%3A%3AHelpers%0A%20%20abstract!%0A%0A%20%20sig%20%7Babstract.returns%28Integer%29%7D%0A%20%20def%20foo%3B%20end%0Aend%0A%0Amodule%20ThingFactory%0A%20%20extend%20T%3A%3AGeneric%0A%20%20interface!%0A%0A%20%20Instance%20%3D%20type_member%28%3Aout%29%0A%0A%20%20sig%20%7Babstract.returns%28Instance%29%7D%0A%20%20def%20make_thing%3B%20end%0Aend%0A%0Asig%20do%0A%20%20type_parameters%28%3AInstance%29%0A%20%20%20%20.params%28klass%3A%20ThingFactory%5BT.type_parameter%28%3AInstance%29%5D%29%0A%20%20%20%20.returns%28T.type_parameter%28%3AInstance%29%29%0Aend%0Adef%20instantiate_class_bad%28klass%29%0A%20%20instance%20%3D%20klass.make_thing%0A%20%20instance.foo%0A%20%20instance%0Aend%0A%0Asig%20do%0A%20%20type_parameters%28%3AInstance%29%0A%20%20%20%20.params%28klass%3A%20ThingFactory%5BT.all%28AbstractThing%2C%20T.type_parameter%28%3AInstance%29%29%5D%29%0A%20%20%20%20.returns%28T.type_parameter%28%3AInstance%29%29%0Aend%0Adef%20instantiate_class%28klass%29%0A%20%20instance%20%3D%20klass.make_thing%0A%20%20instance.foo%0A%20%20instance%0Aend%0A%0Aclass%20GoodThing%0A%20%20extend%20T%3A%3AGeneric%0A%20%20include%20AbstractThing%0A%20%20extend%20ThingFactory%0A%20%20Instance%20%3D%20type_template%28%3Aout%29%20%7B%20%7Bfixed%3A%20GoodThing%7D%20%7D%0A%0A%20%20sig%20%7Boverride.returns%28Instance%29%7D%0A%20%20def%20self.make_thing%20%23%20%E2%9C%85%0A%20%20%20%20new%0A%20%20end%0A%0A%20%20sig%20%7Boverride.returns%28Integer%29%7D%0A%20%20def%20foo%3B%200%3B%20end%0Aend)
</figcaption>
</figure>

This has the effect of ensuring that the `foo` method we want to call is available on all
instances, no matter which kind of instance it is. (For more reading, this use of `T.all`
is how Sorbet [approximates bounds on `T.type_parameter`s].)

If we find ourselves repeatedly calling `self.make_thing.foo`, we might want to pull that
code into the `ThingFactory` interface. That's totally fine, but it'll mean that we'll use
`upper:` on the `Instance` type member to apply the bound, instead of `T.all`:

<figure class="left-align-caption">

```{.ruby .numberLines .hl-5 .hl-11 .hl-13}
module ThingFactory
  extend T::Generic
  abstract!

  Instance = type_member(:out) { {upper: AbstractThing} }

  sig {abstract.returns(Instance)}
  def make_thing; end

  sig {returns(Instance)}
  def make_thing_and_call_foo
    instance = self.make_thing
    instance.foo # ✅ also OK
    instance
  end
end
```

<figcaption>
[→ View complete example on sorbet.run](https://sorbet.run/#%23%20typed%3A%20strict%0Aclass%20Module%3B%20include%20T%3A%3ASig%3B%20end%0A%0Amodule%20AbstractThing%0A%20%20extend%20T%3A%3AHelpers%0A%20%20abstract!%0A%0A%20%20sig%20%7Babstract.returns%28Integer%29%7D%0A%20%20def%20foo%3B%20end%0Aend%0A%0Amodule%20ThingFactory%0A%20%20extend%20T%3A%3AGeneric%0A%20%20abstract!%0A%0A%20%20Instance%20%3D%20type_member%28%3Aout%29%20%7B%20%7Bupper%3A%20AbstractThing%7D%20%7D%0A%0A%20%20sig%20%7Babstract.returns%28Instance%29%7D%0A%20%20def%20make_thing%3B%20end%0A%0A%20%20sig%20%7Breturns%28Instance%29%7D%0A%20%20def%20make_thing_and_call_foo%0A%20%20%20%20instance%20%3D%20self.make_thing%0A%20%20%20%20instance.foo%0A%20%20%20%20instance%0A%20%20end%0Aend%0A%0Asig%20do%0A%20%20type_parameters%28%3AInstance%29%0A%20%20%20%20.params%28klass%3A%20ThingFactory%5BT.type_parameter%28%3AInstance%29%5D%29%0A%20%20%20%20.returns%28T.type_parameter%28%3AInstance%29%29%0Aend%0Adef%20instantiate_class_bad%28klass%29%0A%20%20instance%20%3D%20klass.make_thing%0A%20%20instance.foo%0A%20%20instance%0Aend%0A%0Asig%20do%0A%20%20type_parameters%28%3AInstance%29%0A%20%20%20%20.params%28klass%3A%20ThingFactory%5BT.all%28AbstractThing%2C%20T.type_parameter%28%3AInstance%29%29%5D%29%0A%20%20%20%20.returns%28T.type_parameter%28%3AInstance%29%29%0Aend%0Adef%20instantiate_class%28klass%29%0A%20%20klass.make_thing_and_call_foo%0Aend%0A%0Aclass%20GoodThing%0A%20%20extend%20T%3A%3AGeneric%0A%20%20include%20AbstractThing%0A%20%20extend%20ThingFactory%0A%20%20Instance%20%3D%20type_template%28%3Aout%29%20%7B%20%7Bfixed%3A%20GoodThing%7D%20%7D%0A%0A%20%20sig%20%7Boverride.returns%28Instance%29%7D%0A%20%20def%20self.make_thing%20%23%20%E2%9C%85%0A%20%20%20%20new%0A%20%20end%0A%0A%20%20sig%20%7Boverride.returns%28Integer%29%7D%0A%20%20def%20foo%3B%200%3B%20end%0Aend)
</figcaption>

</figure>

The takeaway is that if we want to call specific methods after instantiating some
arbitrary class, we need an interface and a bound. Where to put the bound (on the method
or on the type member) is up to personal preference. Some tradeoffs:

- Bounding the type member means you can _only_ use this `ThingFactory` interface with
  `AbstractThing`, preventing it from being used for anything else. Maybe that's what you
  want, or maybe it isn't.

- Bounding the type member might make for more obvious errors. For example, if someone
  accidentally wrote the wrong type in the `fixed` bound, a single error will show, right
  there. Had the bound been on the method, errors would appear at every call to
  `instantiate_class` (which is annoying because the proper fix will be to go back, find
  the `fixed`, and correct the typo).

# 🧹 Cleaning up the code

Altogether, this code works, and I've presented it in such a way as to illustrate the
concepts as plainly as possible. But it's maybe not the most idiomatic Sorbet code
imaginable.

We have two interfaces (`AbstractThing` and `ThingFactory`) that are conceptually related,
but not related in the code. Realistically, everything that implements one needs to
implement both. We can make that connection explicit with [`mixes_in_class_methods`].

[`mixes_in_class_methods`]: https://sorbet.org/docs/abstract#interfaces-and-the-included-hook

<figure class="left-align-caption">

```{.ruby .numberLines .hl-1 .hl-8 .hl-17 .hl-24}
module Thing
  extend T::Helpers
  interface!

  sig {abstract.returns(Integer)}
  def foo; end

  module Factory
    extend T::Generic
    interface!

    Instance = type_member(:out) { {upper: Thing} }

    sig {abstract.returns(Instance)}
    def make_thing; end
  end
  mixes_in_class_methods(Factory)
end

# ...

class GoodThing
  extend T::Generic
  include Thing

  # ...
end
```

<figcaption>
[→ View complete example on sorbet.run][final-example]

[final-example]: https://sorbet.run/#%23%20typed%3A%20strict%0Aclass%20Module%3B%20include%20T%3A%3ASig%3B%20end%0A%0Amodule%20Thing%0A%20%20extend%20T%3A%3AHelpers%0A%20%20interface!%0A%20%20%0A%20%20sig%20%7Babstract.returns%28Integer%29%7D%0A%20%20def%20foo%3B%20end%0A%0A%20%20module%20Factory%0A%20%20%20%20extend%20T%3A%3AGeneric%0A%20%20%20%20interface!%0A%0A%20%20%20%20Instance%20%3D%20type_member%28%3Aout%29%20%7B%20%7Bupper%3A%20Thing%7D%20%7D%0A%0A%20%20%20%20sig%20%7Babstract.returns%28Instance%29%7D%0A%20%20%20%20def%20make_thing%3B%20end%0A%20%20end%0A%20%20mixes_in_class_methods%28Factory%29%0Aend%0A%0Asig%20do%0A%20%20type_parameters%28%3AInstance%29%0A%20%20%20%20.params%28%0A%20%20%20%20%20%20klass%3A%20Thing%3A%3AFactory%5BT.all%28Thing%2C%20T.type_parameter%28%3AInstance%29%29%5D%0A%20%20%20%20%29%0A%20%20%20%20.returns%28T.type_parameter%28%3AInstance%29%29%0Aend%0Adef%20instantiate_class%28klass%29%0A%20%20instance%20%3D%20klass.make_thing%0A%20%20instance.foo%0A%20%20instance%0Aend%0A%0Aclass%20GoodThing%0A%20%20extend%20T%3A%3AGeneric%0A%20%20include%20Thing%0A%20%20Instance%20%3D%20type_template%28%3Aout%29%20%7B%20%7Bfixed%3A%20GoodThing%7D%20%7D%0A%0A%20%20sig%20%7Boverride.returns%28Integer%29%7D%0A%20%20def%20foo%3B%200%3B%20end%0A%0A%20%20sig%20%7Boverride.returns%28Instance%29%7D%0A%20%20def%20self.make_thing%20%23%20%E2%9C%85%0A%20%20%20%20new%0A%20%20end%0Aend
</figcaption>
</figure>

By using `mixes_in_class_methods`, we replace an `include` + `extend` with just a single
`include`. Also, it gives us an excuse to nest one module inside the other, so that we can
have `Thing` and `Thing::Factory`, names which read more nicely in my opinion. (Of course,
you're free to use whatever names you like.)

\

\

That should be all you need to go forth and add types to code doing `klass.new`. One more
time, here's the complete final example:

[→ View complete final example on sorbet.run][final-example]

That being said, the concepts presented in this post are quite advanced and also
uncommonly discussed online. If reading this post left you feeling unclear or confused
about something, [please reach out](https://jez.io). I'd love to update the post with your
feedback.

\

- - - - -

# Trivia

This section is just "other neat things." You should be able to safely skip it unless you
want to learn more about some esoteric parts of the implementation of Sorbet which are
related to concepts discussed above.

## `T.attached_class`

Internally, `T.attached_class` is secretly a type_member, declared something like this,
automatically, in every class:

```ruby
class MyClass
  <AttachedClass> = type_template(:out) { {upper: MyClass} }
end
```

Those angle brackets in the name are not valid Ruby syntax, which ensures that people can't
write a type member with this name, and e.g. overwrite the meaning of `T.attached_class`.

... but you could actually imagine wanting to let people define such a type member. In
fact, if people _could_ declare a type member with this magical name in a module, then it
would automatically be defined when `extend`'ing that module into a class:

```ruby
module ThingFactory
  <AttachedClass> = type_member(:out)
end

class MyClass
  extend ThingFactory

  # ... no "Must redeclare `<AttachedClass>` type_member" error
  # like we'd usually get, because Sorbet already did it for us
end
```

Such a feature in Sorbet might alleviate some of the verbosity in the above approach.

## Two modules vs one class

In the `mixes_in_class_methods` example above, it's reasonable to try to unify `Thing` and
`Thing::Factory` into a single `AbstractThing` class:

```ruby
# !! warning, doesn't work !!
class AbstractThing
  extend T::Generic
  abstract!

  sig {abstract.returns(Integer)}
  def foo; end

  Instance = type_template(:out) { {upper: AbstractThing} }
end
```

From a type system perspective, this is actually totally fine. But the one problem is that
there's no replacement for what we used to be able to write with `Factory[...]`. Said
another way: there's no way to apply a type argument to a generic singleton class (i.e.,
to a type template). This is purely a question of syntax. Specifically:

```{.ruby .numberLines .hl-3}
sig do
  type_parameters(:Instance)
    .params(klass: T.class_of(AbstractThing)[T.type_parameter(:Instance)])
    .returns(T.type_parameter(:Instance))
end
def instantiate_class(klass)
  # ...
end
```

This `T.class_of(AbstractThing)[...]` syntax isn't parsed by Sorbet. If we can bikeshed on
a syntax, the type system would very easily admit such a feature (because `type_template`
is literally just a `type_member` on the singleton class).

But sometimes, bikeshedding syntax is the hardest part of language design.

## Please don't do this

Due to an accident of history in Sorbet, the keyword `self` is allowed in type syntax. No
one knows this, and I'm pretty sure this is the first time outside of Sorbet's test suite
that it's been written down. But the keyword `self` means "the class I'm in" and it's
basically the same as writing the name of the enclosing class.

Armed with this cursed knowledge, you can confuse all the people who will ever read your
code but save on typing a few characters:

```{.ruby .numberLines .hl-4}
class GoodThing
  extend T::Generic
  extend ThingFactory
  Instance = type_template(:out) { {fixed: self} }
  #       basically the same as: { {fixed: GoodThing} }
end
```

Please don't do this if you want people to understand your code 🙂
