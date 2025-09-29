---
# vim:tw=90 fo-=tc
layout: post
title: "Untitled"
date: 2025-09-27T18:23:20-04:00
description: TODO
math: false
categories: ['TODO']
# subtitle:
# author:
# author_url:
---

<!-- TODO(jez) sorbet.run links -->

This is the second post in a series about Sorbet,[^sorbet] generic methods, and a concept called parametricity. Generic methods break people's intuition of what "should" work, and this series attempts to build a more accurate mental model.

[^sorbet]:
  All the examples will be using typed Ruby with [Sorbet], but realistically many of the ideas translate to other typed, object-oriented languages with support for generics.

[Sorbet]: https://sorbet.org

* [Part 1: Sorbet, Generics, and Parametricity](/sorbet-parametricity/)
* **[Part 2: ... TODO ...](#)**

[part1]: /sorbet-parametricity/

\

In Sorbet, a generic function that wants to return the same type as its input must **use the input** to construct that return value.

Commonly that means using something like `x.class.new`, which grabs the class of the method's parameter to then create an instance of that class:

```{.ruby .numberLines .hl-3 .hl-7}
sig {
  type_parameters(:U)
    .params(x: T.all(T.type_parameter(:U), Object))
    .returns(T.type_parameter(:U))
}
def foo(x)
  x.class.new
end
```

The `T.all` is Sorbet's way of [placing a bound] on a type parameter. Instead of this signature meaning, "`foo` behaves the same [**for all**]{.smallcaps} choices of `T.type_parameter(:U)`," it now means "`foo` behaves the same for all choices of `T.type_parameter(:U)` [**given that**]{.smallcaps} `T.type_parameter(:U)` is an `Object`." 

[placing a bound]: https://sorbet.org/docs/generics#placing-bounds-on-generic-methods

It's subtle but this is a big difference:

- Accepting `T.type_parameter(:U)` (unconstrained) is a promise to a method's callers that it won't rely on the specifics of that type at all: it will just pass it around unchanged. This is what we learned [from part 1][part1].

- Adding a bound weakens that promise: the method will still behave uniformly for all inputs, modulo how individual methods choose to implement the interface of that bound.

  Adding this particular bound, `Object`, is what gives us access to the `.class` method in the first place. Each subclass of `Object` chooses its own way to be constructed, introducing a source of non-uniformity in our method's behavior.

When people get this wrong, it's usually because instead of trying to **use the input** to return something the same type as the input, they instead create something unrelated that happens to have the same type as the input's upper bound:

```{.ruby .numberLines .hl-7 .hl-10}
sig {
  type_parameters(:U)
    .params(x: T.all(T.type_parameter(:U), Object))
    .returns(T.all(T.type_parameter(:U), Object))
}
def doesnt_return_input(x)
  Object.new # ⛔️ `Object` is not a `T.type_parameter(:U)`
end

res = doesnt_return_input_class([1, 2, 3])
```

Generic methods don't work this way. We can't just go, "oh, I was given something that's an `Object`, I'll just return another `Object`" because what's provided at the call site might be _more specific_ than `Object`, e.g. the `Array` that's given on line 10. Given an `Array`, Sorbet will infer `res` to have type `Array`—returning an `Object` is not specific enough.

Spelled out this way (with `Object`) it's pretty obvious, but it's the same reason why a method like this doesn't type check:

```{.ruby .numberLines .hl-3 .hl-4 .hl-5 .hl-6 .hl-11 .hl-12}
sig {
  type_parameters(:U)
    .params(x: T.all(
      T.type_parameter(:U),
      T.any(T::Array[Integer], T::Hash[Symbol, Integer])
    ))
    .returns(T.type_parameter(:U))
}
def return_empty_container(x)
  case x
  when Array
    return [] # ⛔️ `Array` is not `T.type_parameter(:U)`
  when Hash
    return {} # ⛔️ `Hash` is not `T.type_parameter(:U)`
  end
end
```

`Array` and `Hash` might have been subclassed, and by returning `[]` and `{}`, the method might accidentally widen the type.

\

A generic function that wants to return the same type as its input must **use the input** to construct that return value. What we saw [in part 1][part1] was that one way to do this is to simply return the input. Another way to do this is to ask for the capability to make new instances by placing more constraints on the input's type.

\

\


With the main lesson out of the way there are a handful of gotchas, fun observations, and other connections to draw.

## Alternative: ask for a proc to create new instances

Above, we constrained by input by asking for access to the type's class. We could also constrain the input by asking for a proc that creates instances of the argument.

```{.ruby .numberLines .hl-5}
sig {
  type_parameters(:U)
    .params(
      x: T.type_parameter(:U),
      default: T.proc.returns(T.type_parameter(:U))
    )
    .returns(T.type_parameter(:U))
}
def accepts_constructor(x, default)
  # ...
end
```

The key point remains: to return something of type `T.type_parameter(:U)`, a method must have first been given something that is or creates a value of type `T.type_parameter(:U)`.

## Be careful with `x.class.new`

Calling `x.class.new` assumes that every possible thing you're constructing exposes a constructor which takes zero arguments. That's not always true, and Sorbet will not always catch when it's not.

Consider code like this:

[^vice_versa_initialize]

[^vice_versa_initialize]:
  {-} The other way this can blow up is if the subclasses all **do** implement a uniform, non-[nullary](https://en.wikipedia.org/wiki/Arity) interface, but the parent class does not declare it. In this case, `x.class.new` dispatches all the way up to `BasicObject#initialize`, which requires that it be given zero arguments, making it impossible to pass required arguments to the subclasses' constructors.

```{.ruby .numberLines .hl-7 .hl-11 .hl-20}
class AbstractParent
  extend T::Helpers
  abstract!
end

class Child1 < AbstractParent
  def initialize(x:); end
end

class Child2 < AbstractParent
  def initialize(y:); end
end

sig {
  type_parameters(:U)
    .params(parent: T.all(AbstractParent, T.type_parameter(:U)))
    .returns(T.type_parameter(:U))
}
def example(parent)
  parent.class.new # 💥
end

example(Child1.new)
```

Sorbet says this snippet has no errors, but it will blow up on the call to `parent.class.new` on line 20. Both subclasses of `AbstractParent` have their own constructors that take custom required arguments, and they don't agree. The polymorphic call to `new` on line 20 does not pass any of them (nor could it in all cases).

When a method relies on polymorphically instantiating subclasses, make sure the to declare the `initialize` method on that class as `abstract` or `overridable` so Sorbet can flag problems if the subclasses don't all implement a uniform interface.

```ruby
class AbstractParent
  # ...

  sig { abstract.void }
  def initialize; end
end
```

Writing `abstract` or `overridable` on a method definition asks Sorbet to opt that method into [override checking](https://sorbet.org/docs/override-checking) for that method—including when the method is `initialize`.

This issue is not necessarily related to generics, it just happens to show up here too. The same problem happens for non-generic methods that accept `klass: T.class_of(AbstractParent)` which then call `klass.new`. The root of the issue is how to treat polymorphic constructor calls.

Sorbet allows polymorphic constructor calls even though it does not require the constructor to have been marked `abstract` or `overridable`. I've written about [the polymorphic constructor problem](/constructor-override-checking/) before, which is worth a read if you want to learn more about how this affects other languages or what makes Ruby unique in this regard.


## `.class.new` is a fancy way of writing `T.self_type`

The reason why `x.class.new` to create values that have type `T.type_parameter(:U)` is because of `T.self_type`. If `x` starts with type `T.all(T.type_parameter(:U), Object)`, then via a chain of substitutions we get the same thing back out:

1.  `.class` returns `T::Class[T.self_type]`[^T.class_of]

    Substitute `T.all(T.type_parameter(:U), Object)` for `T.self_type` in `T::Class[T.self_type]`

    → `T::Class[T.all(T.type_parameter(:U), Object)]`

1.  `.new` returns `T.attached_class`

    Substitute `T.all(T.type_parameter(:U), Object)` for `T.attached_class` in `T.attached_class`

    → `T.all(T.type_parameter(:U), Object)`

[^T.class_of]:
  The return type of the `class` method is not `T::Class[T.self_type]` exactly, but it's close enough for this discussion. The technicalities: (1) Sorbet doesn't allow `T.self_type` inside generic type applications like this, for reasons that will likely be lifted one day, and (2) this signature doesn't account for how Sorbet makes it possible to call methods on the receiver's singleton class.

This gives us another way to use the input: define our own methods that return `T.self_type`:

```ruby
class AbstractServiceConfig
  extend T::Helpers
  abstract!

  # Implemented by subclasses to provide the default
  # configuration for a service.
  sig { returns(T.self_type) }
  def default; end
end
```

### Gotchas with `T.self_type`

For the time being, implementing methods that return `T.self_type` requires a certain amount of care. Sorbet has a pernicious weak spot when it comes to checking that methods returning `T.self_type` are implemented correctly:

→ [sorbet/sorbet#755](https://github.com/sorbet/sorbet/issues/775)

Sorbet does not actually check that a method declared to return `T.self_type` actually returns the same type as its receiver. That is, Sorbet should reject this, but doesn't:

```{.ruby .hl-4}
class Parent
  sig {returns(T.self_type)}
  def foo
    Parent.new # 💥
  end
end

class Child < Parent; end
```

Methods that return `T.self_type` must take care to use something like `self`, `self.class.new`, or other methods that return `T.self_type` to create instances of the correct subclass. This will get fixed in Sorbet one day.

## Why `Object`, and not `Kernel`?

All of the interesting methods that are defined for all `Object`s in Ruby are actually defined in `Kernel`, a module that is mixed into `Object`.

You might then ask, why not use `T.all(Kernel, T.type_parameter(:U))` instead of `Object` in the types above?

Due to a confluence of factors (Sorbet's weaker type system when it was first designed, a need to [balance utility with pedantry](https://github.com/sorbet/sorbet/#sorbet-user-facing-design-principles), and some quirks about [how module singleton classes work](/inheritance-in-ruby/#the-include-operator)), `Kernel#class` remains `T.untyped`.

To get a typed result when calling `.class`, it has to be done on `Object`.

I hope to lift this restriction one day, but it might involve a [drastic reimagining of `mixes_in_class_methods`](/inheritance-in-ruby/#the-mixes_in_class_methods-annotation). For more, you can try [reading this pull request](https://github.com/sorbet/sorbet/pull/9393).

## Is this terrifying?

The fact that simply having an object gives you access to create instances of that object is, in some sense, terrifying. One of the reasons why I value writing types in my programs is that if I see a method with a very generic type signature, I know that the implementation of the method can only do a small number of things.

But in Sorbet, even a very wide type like `Object` confers the ability to create things of that type. Little by little, things like this make it harder to reason about what a method might do by looking only at its signature.

As an aside, this is one of the reasons why Sorbet requires that you put `include Kernel` in a module if you want to use methods like `.class`:

```ruby
module EmptyInterface
  extend T::Helpers
  abstract!
end

sig { params(x: EmptyInterface).void }
def example(x)
  x.class.new # ⛔️ Method `class` does not exist on `EmptyInterface`
end
```

The fact that Sorbet does not assume `Kernel` is in every module makes it possible to define a **truly** empty interface, which allows for defining types that permit even fewer operations.

If I see a method that takes an interface, and that interface only has one method, I know that the implementation can only call that one interface method. It makes it much easier to reason about what the method could be doing—not every type **should** confer the ability to create new instances of that type!
