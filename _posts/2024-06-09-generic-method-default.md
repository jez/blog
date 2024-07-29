---
# vim:tw=90 fo-=tc
layout: post
title: "Generic methods cannot have non-generic defaults in Sorbet"
date: 2024-07-28T13:47:45-04:00
description: >
  Sorbet does not allow generic methods to have non-generic default arguments. The best
  alternative is to split the method into two methods, with one implemented by calling the
  other with the default value.
math: false
categories: ['ruby', 'sorbet', 'types']
# subtitle:
# author:
# author_url:
---

Sorbet does not allow generic methods to have non-generic default arguments:

```ruby
sig do
  type_parameters(:U)
    .params(x: T.type_parameter(:U))
    .returns(T.type_parameter(:U))
end
def do_thing(x = 0)
  #             ^ ❌ Argument does not have asserted type `T.type_parameter(:U)`
  return x
end
```

This is **intentional** and aligns with most other popular type systems. There are a couple of alternatives, listed below. Earlier alternatives are preferred to later ones.

## Alternatives

### Remove the default, add another method

This is the most straightforward solution:

```{.ruby .numberLines .hl-6 .hl-11}
sig do
  type_parameters(:U)
    .params(x: T.type_parameter(:U))
    .returns(T.type_parameter(:U))
end
def do_thing_with(x)
  return x
end

sig { returns(Integer) }
def do_thing = do_thing_with(0)
```

There are now two methods, `do_thing` and `do_thing_with`, where `do_thing` is implemented by a call to `do_thing_with`. What used to be a default argument (`= 0`) is now an explicit argument inside the implementation of `do_thing` (`do_thing_with(0)`).

The contract of a method with a signature including `type_parameters(:U)` means "this method holds **for all** arguments you could choose to call this method with." Choosing `0` at the call site is a valid choice.[^for-all]

[^for-all]:
  {-} Attempting to set a non-generic default argument invalidates this _for all_ property, as we'll see below.

Another way of saying this: a method's parameter types form a public API, and choosing the type `T.type_parameter(:U)` makes the method's public API "you can give me anything"


### Declare an overloaded method

:::{.note .yellow}

|     |
| --- |
| ⚠️  Sorbet has minimal support for defining methods with overloaded signatures.<br>[See the docs](https://sorbet.org/docs/overloads) for more on the downsides of and restrictions which apply to method overloads. |

:::

In particular, one of the biggest downsides is that overloads can only be declared in RBI files and declaring a method with an override means that the method's implementation is not checked. Overloads are only meant for use when declaring types for third-party code which cannot be changed, not first-party code inside a given project.

Despite the above disclaimer, we can use method overloads to annotate our `do_thing` method above:

```{.ruby .numberLines .hl-2 .hl-3 .hl-12}
# -- do_thing.rbi --
sig { returns(Integer) }
sig do
  type_parameters(:U)
    .params(x: T.type_parameter(:U))
    .returns(T.type_parameter(:U))
end
def do_thing(x = 0); end
#               ^ This is an RBI file--default arguments are not checked here.

# -- do_thing.rb --
# typed: false

def do_thing(x = 0)
  x
end
```

Note that, due to Sorbet's restrictions around using methods with overloaded signatures, the implementation of `do_thing` must be either:

- In a `# typed: false` file,
- Hidden from Sorbet with with `define_method(:do_thing)`, or
- Omitted from the list of list of files Sorbet typechecks (e.g., inside a gem).

[See the docs](https://sorbet.org/docs/overloads) for more.

### Use an escape hatch

If restructuring the code is not an option, there's always `T.unsafe` and `T.cast`, which have the usual caveats that they turn off Sorbet's ability to catch mistakes.

Using `T.unsafe` is easiest:

```{.ruby .numberLines .hl-7}
sig do
  type_parameters(:U)
    .params(x: T.type_parameter(:U))
    .returns(T.type_parameter(:U))
end
def do_thing(x = T.unsafe(0))
  T.reveal_type(x) # => T.untyped
  return x
end
```

But using `T.unsafe` will make the variable untyped throughout the entire method. For a slightly safer option, use `T.cast`:

```{.ruby .numberLines .hl-7}
sig do
  type_parameters(:U)
    .params(x: T.type_parameter(:U))
    .returns(T.type_parameter(:U))
end
def do_thing(x = T.cast(0, T.type_parameter(:U)))
  T.reveal_type(x) # => T.type_parameter(:U)
  return x
end
```

This `T.cast` will never raise, because Sorbet [erases generics at runtime]. A `T.cast` involving a generic type is always a no-op.

[erases generics at runtime]: https://sorbet.org/docs/generics#generics-and-runtime-checks

Note that even the `T.cast` option is still unsafe in the sense that it is possible to misuse the annotation so that the static types do not match the runtime values. This is discussed extensively below.

## Why does Sorbet behave like this?

Let's answer by seeing what this feature costs in other languages. For example, C++ allows using generic functions (templated functions) with non-generic default values. The price C++ pays for this:

- There is a copy of every method for every distinct type that method is called with, globally throughout the program. Call the method with an `int`? Get get a copy of `do_thing`. Call it somewhere else with a `string`? Get another copy, etc. etc. This slows down compilation time, which goes against Sorbet's performance goals.

- The default value is checked only when those copies of the function are called. If there is a type mismatch with the default value, that mismatch might never be reported or might be redundantly reported dozens or hundreds of times. This goes against Sorbet's goals of useful, actionable error messages.

Setting aside those costs, implementing a feature like this is complicated by method overriding. For example, if it were possible for generic methods to have non-generic defaults, and Sorbet were to use the default to infer a type for the `T.type_parameter` of the method, then we'd have a problem like this:

```{.ruby .numberLines .hl-10 .hl-22 .hl-29 .hl-30 .hl-34}
class Parent
  extend T::Sig

  sig do
    overridable.
      .type_parameters(:U)
      .params(x: T.type_parameter(:U))
      .returns(T.type_parameter(:U))
  end
  def foo(x = '')
    x
  end
end

class Child < Parent
  sig do
    override
      .type_parameters(:U)
      .params(x: T.type_parameter(:U))
      .returns(T.type_parameter(:U))
  end
  def foo(x = 0)
    x
  end
end

sig { params(parent: Parent).void }
def takes_parent(parent)
  res = parent.foo   # res == 0
  T.reveal_type(res) # => hypothetically: `String`
end

child = Child.new
takes_parent(child) # 💥
```

This example has a `Parent` and `Child` class with an `overridable` method `foo`. In `Parent` the default is set to `''`, but in the child the default is set to `0`. `Child#foo` would look to Sorbet like a compatible override (the signatures are otherwise identical), so a `Child` is a `Parent`.

But when the code takes advantage of that fact with the call to `takes_parent(child)`, this causes a problem. Sorbet will think that the call to `parent.foo` returns a `String` (`''`), but at runtime, it will be an `Integer` (`0`), because it will use `Child`'s default.

You might say, "just change override checking: require that the types in the signature are compatible, **and** require that the default values are compatible." While this might work in some other type checker, it wouldn't work in Sorbet: Sorbet requires that all methods' types are known before doing inference, and determining the type of a default requires running type inference:

```ruby
# Need to know the type of both `x` and  `self.compute_default`
# to know the type of `y`. This requires running type inference.
def complicated_default(x, y=self.compute_default(x))
  # ...
end
```

For performance and simplicity in Sorbet, determining methods' types comes strictly before running type inference.

The way that languages like C++ get around this is **not** by extending override checking to include default arguments, but rather to compile the default argument using the **static** type of the caller (e.g., since the `parent` variable's static type is `Parent`, it will behave as if the call was always `parent.foo('')`). That's not how Ruby works, so it can't be how Sorbet works.

While we're comparing other languages:

- TypeScript and C# behave just like Sorbet. Some interesting discussions of this in the TypeScript issue tracker:
  - [Default values for generic parameters](https://github.com/microsoft/TypeScript/issues/49158)
  - [[Feature request] Support generic type default values in functions](https://github.com/microsoft/TypeScript/issues/56315)
  - [Allow defering type check of default value for generic-typed function parameter until instantiation](https://github.com/microsoft/TypeScript/issues/58977)
- Java doesn't allow default arguments at all (just compile-time overloading)
- Scala allows generic functions to have default arguments, and uses a compilation strategy of turning the default values into their own methods. It sounds they [cause problems](https://contributors.scala-lang.org/t/better-default-arguments/6034) and aren't checked statically, but they tolerate it because the `copy` method of case classes depends on it.

My take is that the workarounds are so easy, proper support nearly always involves being able to use static information to change how the code is compiled, and the implementation is tricky to get correct in the presence of overriding, so it's not worth it to try to add such a feature to Sorbet.

\

- - - - -

\

## Appendix: Generic methods *can* have *generic* defaults

While generic methods cannot have non-generic defaults, they can have generic defaults:

```ruby
sig do
  type_parameters(:U)
    .params(
      x: T.type_parameter(:U),
      y: T.type_parameter(:U))
    .returns(T.type_parameter(:U))
end
def do_thing(x, y=x)
  if [true, false].sample
    return x
  else
    return y
  end
end
```

This code is completely fine, because `y` has a generic type (the type of `y` is chosen by the caller of `do_thing`, not the implementation). I include this mostly as a curiosity and justification for why the title has to be so wordy—this doesn't typically matter in cases where people have a generic method they want to add a default to, and is not typically a workaround.
