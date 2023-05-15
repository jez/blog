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

> **Update**: While writing this post, I had a series of realizations and ended up
> building two features which make some of the parts of this post obsolete:
> [`has_attached_class!`] and [`T::Class`].
>
> I've rewritten some of the post below in light of those new features, but the core
> principles in this post are still useful, both to gain familiarity with Sorbet's
> generic types and how to think about interface design in Sorbet.
>
> With that out of the way...

[`has_attached_class!`]: https://sorbet.org/docs/attached-class#has_attached_class-tattached_class-in-module-instance-methods
[`T::Class`]: https://sorbet.org/docs/class-of#tclass-vs-tclass_of

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

The straightforward attempt at writing a Sorbet signature for this method doesn't work.
The strategy that _does_ work uses abstract methods, which brings me to one of my
most-offered tips for type-level design in Sorbet:

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
work, there are reasons why it should not work, and the Sorbet docs [elaborate
why](https://sorbet.org/docs/class-of#tclass-vs-tclass_of).

In short, `T.type_parameter(:U)` doesn't stand for "some unknown class," it stands for
"some unknown type." It could mean any of `T.any(Integer, String)`, `T::Array[Integer]`,
`T.noreturn`, or any other type. Meanwhile, `T.class_of(...)` is defined very narrowly to
mean "get the singleton class of `...`." Arbitrary types don't have singleton class, only
classes have singleton classes.

# ⚠️&#xFE0F; How to mostly solve this with `T::Class`

As of May 2023, Sorbet has a separate feature, called `T::Class[...]`, which _does_ work
the way people have expected `T.class_of` to work:

```ruby
sig do
  type_parameters(:U)
    .params(klass: T::Class[T.type_parameter(:U)])
    .returns(T.type_parameter(:U))
end
def instantiate_class(klass)
  instance = klass.new
  # ...
  instance
end
```

This code works, but it comes with the downside that the call to `new` is **not statically
checked**. Here we passed no arguments, but it might be that `klass`'s constructor has one
or more required arguments.

# ✅ How to solve this with `abstract` methods

When we see something like this:

```ruby
def instantiate_class(klass)
  klass.new
end
```

and we want to write a precise signature here, what's critical is to notice that there is
some de-facto API that `klass` is meant to conform to. That's exactly what interfaces are
for.

In particular, the de-facto API is that `klass` has some method that tells us how to
create instances, and that method takes no arguments. Let's translate that API to an
interface:

<figure class="left-align-caption">

```{.ruby .numberLines .hl-5 .hl-7 .hl-8 .hl-17}
module ThingFactory
  extend T::Generic
  interface!

  has_attached_class!(:out)

  sig {abstract.returns(T.attached_class)}
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

<figcaption>[→ View on sorbet.run](https://sorbet.run/#%23%20typed%3A%20strict%0Aclass%20Module%3B%20include%20T%3A%3ASig%3B%20end%0A%0Amodule%20ThingFactory%0A%20%20extend%20T%3A%3AGeneric%0A%20%20interface!%0A%0A%20%20has_attached_class!%28%3Aout%29%0A%0A%20%20sig%20%7Babstract.returns%28T.attached_class%29%7D%0A%20%20def%20make_thing%3B%20end%0Aend%0A%0Asig%20do%0A%20%20type_parameters%28%3AInstance%29%0A%20%20%20%20.params%28klass%3A%20ThingFactory%5BT.type_parameter%28%3AInstance%29%5D%29%0A%20%20%20%20.returns%28T.type_parameter%28%3AInstance%29%29%0Aend%0Adef%20instantiate_class%28klass%29%0A%20%20klass.make_thing%0Aend)</figcaption>

</figure>

This `ThingFactory` has two notable definitions: a method called `make_thing`, and a call
to [`has_attached_class!`] above that. `has_attached_class!` both allows using
`T.attached_class` in instance methods of this module and makes this module generic in
that attached class. It's a way for Sorbet to track the relationship between one type and
the type of instances it constructs.

Naming the method `make_thing` (instead of `new`) is a slight sacrifice. Choosing a name
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

```{.ruby .numberLines .hl-2 .hl-5 .hl-14}
class GoodThing
  extend ThingFactory

  sig {override.returns(T.attached_class)}
  def self.make_thing # ✅
    new
  end
end

class BadThing
  extend ThingFactory

  sig {override.params(x: Integer).returns(T.attached_class)}
  def self.make_thing(x) # ⛔️ must accept no more than 0 required arguments
    new
  end
end
```

<figcaption>
[→ View complete example on sorbet.run](https://sorbet.run/#%23%20typed%3A%20strict%0Aclass%20Module%3B%20include%20T%3A%3ASig%3B%20end%0A%0Amodule%20ThingFactory%0A%20%20extend%20T%3A%3AGeneric%0A%20%20interface!%0A%0A%20%20has_attached_class!%28%3Aout%29%0A%0A%20%20sig%20%7Babstract.returns%28T.attached_class%29%7D%0A%20%20def%20make_thing%3B%20end%0Aend%0A%0Asig%20do%0A%20%20type_parameters%28%3AInstance%29%0A%20%20%20%20.params%28klass%3A%20ThingFactory%5BT.type_parameter%28%3AInstance%29%5D%29%0A%20%20%20%20.returns%28T.type_parameter%28%3AInstance%29%29%0Aend%0Adef%20instantiate_class%28klass%29%0A%20%20klass.make_thing%0Aend%0A%0Aclass%20GoodThing%0A%20%20extend%20ThingFactory%0A%0A%20%20sig%20%7Boverride.returns%28T.attached_class%29%7D%0A%20%20def%20self.make_thing%20%23%20%E2%9C%85%0A%20%20%20%20new%0A%20%20end%0Aend%0A%0Aclass%20BadThing%0A%20%20extend%20ThingFactory%0A%0A%20%20sig%20%7Boverride.params%28x%3A%20Integer%29.returns%28T.attached_class%29%7D%0A%20%20def%20self.make_thing%28x%29%20%23%20%E2%9B%94%EF%B8%8F%20must%20accept%20no%20more%20than%200%20required%20arguments%0A%20%20%20%20new%0A%20%20end%0Aend)
</figcaption>
</figure>

See how the `BadThing` class attempts to incompatibly implement `make_thing`? Sorbet
correctly reports an error on line 14 saying that `make_thing` must not accept an extra
required argument.

Something else worth mentioning: we're implementing this interface on the **singleton
class** of `GoodThing` and `BadThing`:

- On line 3, we use `extend` (instead of `include`) to mix in the interface.
- On line 5, `def make_thing` from the interface becomes `def self.make_thing`. Also,
  since it's now a singleton class method, we can use `T.attached_class` for free (no need
  for an extra call to `has_attached_class!` or anything).

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
[→ View complete example on sorbet.run](https://sorbet.run/#%23%20typed%3A%20strict%0Aclass%20Module%3B%20include%20T%3A%3ASig%3B%20end%0A%0Amodule%20AbstractThing%0A%20%20extend%20T%3A%3AHelpers%0A%20%20abstract!%0A%0A%20%20sig%20%7Babstract.returns%28Integer%29%7D%0A%20%20def%20foo%3B%20end%0Aend%0A%0Amodule%20ThingFactory%0A%20%20extend%20T%3A%3AGeneric%0A%20%20interface!%0A%0A%20%20has_attached_class!%28%3Aout%29%0A%0A%20%20sig%20%7Babstract.returns%28T.attached_class%29%7D%0A%20%20def%20make_thing%3B%20end%0Aend%0A%0Asig%20do%0A%20%20type_parameters%28%3AInstance%29%0A%20%20%20%20.params%28klass%3A%20ThingFactory%5BT.type_parameter%28%3AInstance%29%5D%29%0A%20%20%20%20.returns%28T.type_parameter%28%3AInstance%29%29%0Aend%0Adef%20instantiate_class_bad%28klass%29%0A%20%20instance%20%3D%20klass.make_thing%0A%20%20instance.foo%20%23%20error%3A%20forgot%20%60T.all%60%0A%20%20instance%0Aend%0A%0Asig%20do%0A%20%20type_parameters%28%3AInstance%29%0A%20%20%20%20.params%28klass%3A%20ThingFactory%5BT.all%28AbstractThing%2C%20T.type_parameter%28%3AInstance%29%29%5D%29%0A%20%20%20%20.returns%28T.type_parameter%28%3AInstance%29%29%0Aend%0Adef%20instantiate_class%28klass%29%0A%20%20instance%20%3D%20klass.make_thing%0A%20%20instance.foo%0A%20%20instance%0Aend%0A%0Aclass%20GoodThing%0A%20%20extend%20T%3A%3AGeneric%0A%20%20include%20AbstractThing%0A%20%20extend%20ThingFactory%0A%0A%20%20sig%20%7Boverride.returns%28T.attached_class%29%7D%0A%20%20def%20self.make_thing%20%23%20%E2%9C%85%0A%20%20%20%20new%0A%20%20end%0A%0A%20%20sig%20%7Boverride.returns%28Integer%29%7D%0A%20%20def%20foo%3B%200%3B%20end%0Aend)
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

  has_attached_class!(:out) { {upper: AbstractThing} }

  sig {abstract.returns(T.attached_class)}
  def make_thing; end

  sig {returns(T.attached_class)}
  def make_thing_and_call_foo
    instance = self.make_thing
    instance.foo # ✅ also OK
    instance
  end
end
```

<figcaption>
[→ View complete example on sorbet.run](https://sorbet.run/#%23%20typed%3A%20strict%0Aclass%20Module%3B%20include%20T%3A%3ASig%3B%20end%0A%0Amodule%20AbstractThing%0A%20%20extend%20T%3A%3AHelpers%0A%20%20abstract!%0A%0A%20%20sig%20%7Babstract.returns%28Integer%29%7D%0A%20%20def%20foo%3B%20end%0Aend%0A%0Amodule%20ThingFactory%0A%20%20extend%20T%3A%3AGeneric%0A%20%20abstract!%0A%0A%20%20has_attached_class!%28%3Aout%29%20%7B%20%7Bupper%3A%20AbstractThing%7D%20%7D%0A%0A%20%20sig%20%7Babstract.returns%28T.attached_class%29%7D%0A%20%20def%20make_thing%3B%20end%0A%0A%20%20sig%20%7Breturns%28T.attached_class%29%7D%0A%20%20def%20make_thing_and_call_foo%0A%20%20%20%20instance%20%3D%20self.make_thing%0A%20%20%20%20instance.foo%0A%20%20%20%20instance%0A%20%20end%0Aend%0A%0Asig%20do%0A%20%20type_parameters%28%3AInstance%29%0A%20%20%20%20.params%28klass%3A%20ThingFactory%5BT.type_parameter%28%3AInstance%29%5D%29%0A%20%20%20%20.returns%28T.type_parameter%28%3AInstance%29%29%0Aend%0Adef%20instantiate_class_bad%28klass%29%0A%20%20instance%20%3D%20klass.make_thing%0A%20%20instance.foo%0A%20%20instance%0Aend%0A%0Asig%20do%0A%20%20type_parameters%28%3AInstance%29%0A%20%20%20%20.params%28klass%3A%20ThingFactory%5BT.all%28AbstractThing%2C%20T.type_parameter%28%3AInstance%29%29%5D%29%0A%20%20%20%20.returns%28T.type_parameter%28%3AInstance%29%29%0Aend%0Adef%20instantiate_class%28klass%29%0A%20%20klass.make_thing_and_call_foo%0Aend%0A%0Aclass%20GoodThing%0A%20%20extend%20T%3A%3AGeneric%0A%20%20include%20AbstractThing%0A%20%20extend%20ThingFactory%0A%0A%20%20sig%20%7Boverride.returns%28T.attached_class%29%7D%0A%20%20def%20self.make_thing%20%23%20%E2%9C%85%0A%20%20%20%20new%0A%20%20end%0A%0A%20%20sig%20%7Boverride.returns%28Integer%29%7D%0A%20%20def%20foo%3B%200%3B%20end%0Aend)
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

    has_attached_class!(:out) { {upper: Thing} }

    sig {abstract.returns(T.attached_class)}
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

<figcaption>[→ View complete example on sorbet.run][final-example]</figcaption>
</figure>

[final-example]: https://sorbet.run/#%23%20typed%3A%20strict%0Aclass%20Module%3B%20include%20T%3A%3ASig%3B%20end%0A%0Amodule%20Thing%0A%20%20extend%20T%3A%3AHelpers%0A%20%20interface!%0A%20%20%0A%20%20sig%20%7Babstract.returns%28Integer%29%7D%0A%20%20def%20foo%3B%20end%0A%0A%20%20module%20Factory%0A%20%20%20%20extend%20T%3A%3AGeneric%0A%20%20%20%20interface!%0A%0A%20%20%20%20has_attached_class!%28%3Aout%29%20%7B%20%7Bupper%3A%20Thing%7D%20%7D%0A%0A%20%20%20%20sig%20%7Babstract.returns%28T.attached_class%29%7D%0A%20%20%20%20def%20make_thing%3B%20end%0A%20%20end%0A%20%20mixes_in_class_methods%28Factory%29%0Aend%0A%0Asig%20do%0A%20%20type_parameters%28%3AInstance%29%0A%20%20%20%20.params%28%0A%20%20%20%20%20%20klass%3A%20Thing%3A%3AFactory%5BT.all%28Thing%2C%20T.type_parameter%28%3AInstance%29%29%5D%0A%20%20%20%20%29%0A%20%20%20%20.returns%28T.type_parameter%28%3AInstance%29%29%0Aend%0Adef%20instantiate_class%28klass%29%0A%20%20instance%20%3D%20klass.make_thing%0A%20%20instance.foo%0A%20%20instance%0Aend%0A%0Aclass%20GoodThing%0A%20%20extend%20T%3A%3AGeneric%0A%20%20include%20Thing%0A%0A%20%20sig%20%7Boverride.returns%28Integer%29%7D%0A%20%20def%20foo%3B%200%3B%20end%0A%0A%20%20sig%20%7Boverride.returns%28T.attached_class%29%7D%0A%20%20def%20self.make_thing%20%23%20%E2%9C%85%0A%20%20%20%20new%0A%20%20end%0Aend

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

That's where `has_attached_class!` comes in! It essentially provides syntactic sugar to
let people define these `<AttachedClass>` generic types, without having to conflict with
any names of constants the user might already be using in that class.

Realizing that we could build `has_attached_class!` with just a syntactic rewrite was a
key insight that unblocked most of the work on `T::Class` that had blocked us from making
progress on this feature in the past. There's more context in [the original pull
request][6757].

[6757]: https://github.com/sorbet/sorbet/pull/6757

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
