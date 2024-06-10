---
# vim:tw=90 fo-=tc
layout: post
title: "Generic-method-default"
date: 2024-06-09T13:47:45-04:00
description: TODO
math: false
categories: ['TODO']
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
def example(x = 0)
  #             ^ ❌ Argument does not have asserted type `T.type_parameter(:U)`
  #                  Got `Integer`
  return x
end
```

This is intentional, and aligns with most other popular type systems.

## Alternatives and workarounds

There are a couple of alternatives. Earlier alternatives listed here are preferred to later ones.

### Remove the default, add another method

This is the most straightforward solution:

```ruby
sig do
  type_parameters(:U)
    .params(x: T.type_parameter(:U))
    .returns(T.type_parameter(:U))
end
def example(x)
  return x
end

sig { returns(Integer) }
def example_int = example(0)
```

There are now two methods, `example` and `example_int`, with `example_int` implemented in terms of `example`. What used to be a default argument (`= 0`) is now an explicit argument inside the implementation of `example_int` (`example(0)`).

This works because the contract of a method with a signature including `type_parameters(:U)` means "this method holds **for all** choices of types to call this method with." Choosing `Integer` by passing `0` at the call site is a valid choice.[^for-all]

[^for-all]:
  {-} Attempting to set a non-generic default argument invalidates this _for all_ property, as we'll see below.


### Declare an overloaded method

Sorbet has minimal support for defining methods with overloaded signatures. In particular, one of the biggest downsides is that overloads can only be declared in RBI files and declaring a method with an override means that the method's implementation is not checked. Overloads are only meant for use when declaring types for third-party code which cannot be changed, not first-party code inside a given project.

[See the docs](https://sorbet.org/docs/overloads) for more on the downsides of and restrictions which apply to method overloads.

We can use method overloads to annotate our `example` method above:

```ruby
# -- example.rbi --
sig { returns(Integer) }
sig do
  type_parameters(:U)
    .params(x: T.type_parameter(:U))
    .returns(T.type_parameter(:U))
end
def example(x = 0); end
#               ^ This is an RBI file--default arguments are not checked here.

# -- example.rb --
# typed: false

def example(x = 0)
  x
end
```

Note that, due to Sorbet's restrictions around using methods with overloaded signatures, the implementation of `example` must be either:

- In a `# typed: false` file,
- Hidden from Sorbet with with `define_method(:example)`, or
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
def example(x = T.unsafe(0))
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
def example(x = T.cast(0, T.type_parameter(:U)))
  T.reveal_type(x) # => T.type_parameter(:U)
  return x
end
```

This `T.cast` will never raise, because Sorbet [erases generics at runtime]. A `T.cast` involving a generic type is always a no-op.

[erases generics at runtime]: https://sorbet.org/docs/generics#generics-and-runtime-checks

Note that even the `T.cast` option is still unsafe in the sense that it is possible to misuse the annotation so that the static types do not match the runtime values. This is discussed extensively below.

## Why this choice is justified

The main reason why Sorbet makes this choice is for simplicity. For example, C++ allows using generics (template) functions with non-generic default values. The price C++ pays for this is that:

- There must be a separate copy of every method for every unique set of types that method is called with, everywhere in the program. This bloats memory and speed of type checking, which goes against Sorbet's performance goals.
- The default value is checked only when those instantiated versions of the function are called. If there is a type mismatch with the default value, that mismatch might never be reported, or might be redundantly reported dozens or hundreds of times. This goes against Sorbet's goals of useful, actionable error messages.

It's easiest to see by way of a method with two parameters. Conceptually, writing `type_parameters(:U)` in a signature is meant to say "this method"

```ruby
sig do
  type_parameters(:U)
    .params(
      x: T.type_parameter(:U),
      y: T.type_parameter(:U)
    )
    .returns(T.type_parameter(:U))
end
def example(x, y = 0)
  x
end

example('')
```

Conceptually, only the signature of a method form its public API. The expression which computes the default value of a parameter is an implementation detail.

So given a `sig` like this:

```ruby
sig do
  type_parameters(:U)
    .params(x: T.type_parameter(:U))
    .returns(T.type_parameter(:U))
end
```

```ruby
example()
```

## Appendix: Comparison with other languages

The method signature is the public API, while the choice of default argument is an implementation detail.


Conceptually part of the implementation, not the call site:

- Default expression gets to refer to other arguments
- Method signature is the specification, value is the implementation that's meant to uphold that contract
- Interacts weirdly with subclassing / liskov substitution?

For example, normally it's Liskov-compatible 

```ruby
# typed: true

extend T::Sig

class Parent
  extend T::Sig

  sig do
    type_parameters(:U)
      .params(x: T.type_parameter(:U))
      .returns(T.type_parameter(:U))
  end
  def foo(x)
    x
  end
end

class Child < Parent
  sig do
    type_parameters(:U)
      .params(x: T.type_parameter(:U))
      .returns(T.type_parameter(:U))
  end
  def foo(x = '')
    x
  end
end

sig { params(x: Parent).void }
def example(x)
  res = x.foo
  T.reveal_type(res)
end
```

Survey of other languages

- TypeScript, C# behave like Sorbet
- Java doesn't allow defaults (only overloading)
  - Rust doesn't allow default *or* overloading
- Scala treats defaults as virtual getter methods (sounds insane??)
- C++ uses templates for generics, which means that `T` isn't a generic type, it's always a concrete type, and there's one copy of each function per type that gets instantiated in the program, and the default argument will be checked against all of those instantiations (depending on how implicit conversions work out, some or all of the instantiations might not work, but that's only checked when it gets instantiated)
