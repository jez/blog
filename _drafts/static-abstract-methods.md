---
# vim:tw=90 fo-=tc
layout: post
title: "Abstract singleton class methods are an abomination"
date: 2023-09-05T10:56:40-04:00
description: TODO
math: false
categories: ['TODO']
# subtitle:
# author:
# author_url:
---

Sometimes I get a question like this, and it brings me nothing but shame:

> Is there a way to specify that a method accepts a `T.class_of(Foo)` where `Foo` is an abstract class, but all callers to this function must pass non-abstract classes?

It's shameful that people have to ask this question in the first place because it reflects one of Sorbet's original sins: choosing to allow abstract singleton class methods. This choice is **unsound** but was allowed as a compromise: to pave an easier path to adopting Sorbet in existing Ruby codebases.

In every sane language, this is literally what "abstract" is supposed to mean! That is, if `class A` is abstract, then having `x: A` should necessarily imply that `x` is not an instance of a concrete subclass of `A`. Abstract classes should not be instantiable!

For non-singleton classes, Sorbet enforces this: marking a class `abstract!` hijacks the `self.new` method at runtime to make it raise an exception, which prevents instantiating abstract classes.[^trickery]

[^trickery]:
  {-} ... ignoring Ruby trickery which well-behaved programs won't use.

But for _singleton classes_, Ruby has no way to prevent a class's singleton class from being created. And so no singleton class _should_ ever be considered abstract. The right thing for Sorbet to have done would have been not allowing singleton class methods from being `abstract`.

The problem with allowing abstract singleton class methods boils down to this:

```{.ruby .numberLines .hl-3 .hl-9 .hl-12}
class A
  abstract!
  sig { abstract.void }
  def self.foo; end
end

sig { params(klass: T.class_of(A)) }
def example(klass)
  klass.foo
end

example(A)
```

The call to `foo` on line 9 expects that `klass` is not an instance of an abstract class. But at runtime, the object `A` _is_ an instance of an abstract class (specifically: it's the singleton instance of an abstract singleton class). The method `foo` has not been implemented when `klass` is `A`, so the call raises unexpectedly at runtime.

Basically every other typed language correctly avoids this pitfall. For example:

<!-- TODO(jez) Playground link for all of these. -->

- Scala `object` definitions (analogous to Ruby's singleton classes) cannot have abstract methods, because the object _is_ instantiated (just like Ruby singleton classes).
- In Java and C++, the analogue to singleton class methods are `static` methods. As the name implies, these methods use [static dispatch][static-dynamic] instead of dynamic dispatch. Static dispatch precludes implementing the method via an override in a child class, so these languages simply ban `abstract static` methods because they're useless.
- Despite also using the `static` keyword, TypeScript `static` methods use [dynamic dispatch][static-dynamic]. But TypeScript recognizes that the object representing a class at runtime _always exists_, and so prevents `static abstract` methods.

[static-dynamic]: https://lukasatkinson.de/2016/dynamic-vs-static-dispatch/

## What should I use instead?

Instead of using abstract singleton class methods, some alternatives:

1.  Define an interface or [abstract module], declare the abstract method on it, and `extend` the interface into the relevant class.
1.  Define the abstract module inside a modules that is mixed into another module using [mixes_in_class_methods].
1.  Make the method `overridable` instead of `abstract`, effectively giving the method a default implementation. (This is not always possible.)
1.  Keep the abstract singleton class method but use `T::AbstractUtils.abstract_module?` to check at runtime whether a given module object is `abstract!` or not. (This can be an easy shortcut, but means Sorbet won't check whether you've done the right thing.)

[abstract module]: https://sorbet.org/docs/abstract

[mixes_in_class_methods]: https://sorbet.org/docs/abstract#interfaces-and-the-included-hook

It's hard to always suggest a single solution, so let's walk through an example to motivate the tradeoffs.

<!-- TODO(jez) Defer these to separate posts? -->

## The setup: an `AbstractModel` class

Let's say you've got some `AbstractModel` class, and you want all model subclasses to provide a `token_prefix`, which could be used to prefix all database identifiers.

```ruby
class AbstractModel
  sig { abstract.returns(String) }
  def self.token_prefix; end

  # ...
end

class Charge < AbstractModel
  sig { override.returns(String) }
  def self.token_prefix = 'ch'

  # ...
end

class Invoice < AbstractModel
  sig { override.returns(String) }
  def self.token_prefix = 'inv'

  # ...
end
```

Now you want to write a test that says "all models must have a unique token prefix." That test might look like this:

```{.ruby .numberLines .hl-7 .hl-12}
sig { returns(T::Array[T.class_of(AbstractModel)]) }
def all_model_subclasses; end

sig do
  params(
    prefixes: T::Set[String],
    klass: T.class_of(AbstractModel)
  )
  .void
end
def check_one(prefixes, klass)
  prefix = klass.token_prefix
  if prefixes.include?(prefix)
    raise "Duplicate prefix: #{prefix}"
  end
  prefixes << prefix
end

describe 'token prefixes' do
  it 'are all unique' do
    prefixes = T::Set[String].new
    all_model_subclasses.each do |klass|
      check_one(prefixes, klass)
    end
  end
end
```

Our `check_one` method calls `klass.token_prefix` to get a class's prefix, then checks it against the prefixes it's already seen. But the problem: there's nothing in the type annotations preventing `klass` from being the `AbstractModel` singleton class when the test runs! Put another way, this code typechecks:

```ruby
check_one(prefixes, AbstractModel)
```

but if this were to run, it would call `AbstractModel.token_prefix`, which would then **raise an unexpected exception** because we attempted to call an abstract method.

## Alternative 1: Use an interface

Here's one way to rewrite the code:

<style>
pre.hl-50 > code.sourceCode > span:nth-of-type(50)::after { content: ""; }
</style>

```{.ruby .numberLines .hl-1 .hl-7 .hl-11 .hl-34 .hl-50}
module HasTokenPrefix
  sig { abstract.returns(String) }
  def token_prefix; end
end

class AbstractModel
  # ...
end

class Charge < AbstractModel
  extend HasTokenPrefix

  sig { override.returns(String) }
  def self.token_prefix = 'ch'

  # ...
end

class Invoice < AbstractModel
  extend HasTokenPrefix

  sig { override.returns(String) }
  def self.token_prefix = 'inv'

  # ...
end

sig { returns(T::Array[T.class_of(AbstractModel)]) }
def all_model_subclasses; end

sig do
  params(
    prefixes: T::Set[String],
    klass: T.all(HasTokenPrefix, T.class_of(AbstractModel))
  )
  .void
end
def check_one(prefixes, klass)
  prefix = klass.token_prefix
  if prefixes.include?(prefix)
    raise "Duplicate prefix: #{prefix}"
  end
  prefixes << prefix
end

describe 'token prefixes' do
  it 'are all unique' do
    prefixes = T::Set[String].new
    all_model_subclasses.each do |klass|
      next unless klass.is_a?(HasTokenPrefix)
      check_one(prefixes, klass)
    end
  end
end
```

<!-- TODO(jez) Make a sorbet.run for this -->

In this approach, instead of defining `token_prefix` as an abstract singleton class method, we define it on a new `HasTokenPrefix` interface. One downside is that users have to remember to `extend` this into their model classes. But it means that in `check_one` where we want to call `token_prefix`, Sorbet forces us to write `T.all(HasTokenPrefix, AbstractModel)` (where `T.all` is an [intersection type]). This, in turn, requires doing an explicit `klass.is_a?(HasTokenPrefix)` before the call to `check_one`. Since `AbstractModel` is not an instance of `HasTokenPrefix`, it will be safely skipped over.

[intersection type]: https://sorbet.org/docs/intersection-types

## 

That downside about having to remember to both inherit from `AbstractModel` and extend `HasTokenPrefix` is annoying. Likely it'll manifest as confusing
