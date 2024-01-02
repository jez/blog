---
# vim:tw=90 fo-=tc
layout: post
title: "Abstract singleton class methods are an abomination"
date: 2024-01-01T19:25:23-05:00
description: >
  Abstract singleton class methods do not belong in a well-behaved type system. Sorbet allows them anyways, which causes problems. Here's why they're bad and what to do instead.
math: false
categories: ['ruby', 'sorbet', 'types']
# subtitle:
# author:
# author_url:
---

Sometimes I get a Sorbet question like this, and it brings me nothing but shame:

> Is there a way to specify that a method accepts a `T.class_of(Foo)` where `Foo` is an abstract class, but all callers to this function must pass non-abstract classes?

It's one of Sorbet's original sins rearing its head: choosing to allow abstract singleton class methods. The choice is an **unsound** compromise, made to allow easier adoption in existing Ruby codebases.

If you haven't come across it before, the problem with abstract singleton class methods boils down to this:

```{.ruby .numberLines .hl-3 .hl-14 .hl-18}
class AbstractParent
  abstract!
  sig { abstract.void }
  def self.foo; end
end

class ConcreteChild < AbstractParent
  sig { override.void }
  def self.foo = puts("hello!")
end

sig { params(klass: T.class_of(AbstractParent)).void }
def example(klass)
  klass.foo
end

example(ConcreteChild)  # ✅
example(AbstractParent) # 💥 call to abstract method foo
```

The call to `foo` on line 14 expects `klass` to be an instance of a concrete class, so all its methods (including `foo`) have implementations. But at runtime, the object `AbstractParent` is **not** an instance of a concrete class.[^specifically] The method `foo` is not implemented on the `AbstractParent` object, so the call raises unexpectedly at runtime despite Sorbet reporting no static error.

[^specifically]:
  {-} Specifically: it's the singleton instance of a singleton class which Sorbet allowed defining abstract methods on.

In every sane language, making a type abstract is **supposed** to prevent this problem! That is, if `A` is abstract, then having `x` with type `A` should necessarily imply that whatever `x` is bound to at runtime is an instance of a concrete subclass of `A`. Abstract classes should not be instantiable!

For non-singleton classes, Sorbet enforces this guarantee: marking a class `abstract!` hijacks the `self.new` method at runtime to make it raise an exception, which prevents instantiating abstract classes.[^trickery]

[^trickery]:
  {-} ... ignoring Ruby trickery which well-behaved programs won't use.

But for _singleton classes_, there's no way to prevent a class's singleton class from being created—the act of declaring a class automatically creates the singleton class. Knowing this, Sorbet should never consider a singleton class to be abstract, preventing the declaration of abstract singleton class methods. **It does anyway**, which is how we ended up with this mess.

**Strive to avoid designs that depend on abstract singleton class methods.**\
Sorbet won't stop you, so you'll have to stop yourself.

# What should I use instead?

There are some alternatives to abstract singleton class methods. They all involve a certain amount of refactoring, and there isn't always a best one. The options:

1.  Define an interface or [abstract module], declare the abstract method on it, and `extend` the interface into the concrete classes. Ideally: replace the abstract parent class with this interface entirely.

    <figure class="left-align-caption">

    ```{.ruby .numberLines .hl-12 .hl-17 .hl-23}
    module HasFoo
      abstract!
      sig { abstract.void }
      def foo; end
    end

    class ConcreteChild
      extend HasFoo
      sig { override.void }
      def self.foo = puts("hello!")
    end

    sig { params(klass: HasFoo) }
    def example(klass)
      klass.foo
    end

    example(ConcreteChild)  # ✅
    example(HasFoo)         # ❌ static type error prevents this
    ```

    <figcaption>
    [View on sorbet.run →](https://sorbet.run/#%23%20typed%3A%20true%0Aclass%20Module%0A%20%20include%20T%3A%3ASig%0A%20%20include%20T%3A%3AHelpers%0Aend%0A%0Amodule%20HasFoo%0A%20%20abstract!%0A%20%20sig%20%7B%20abstract.void%20%7D%0A%20%20def%20foo%3B%20end%0Aend%0A%0Aclass%20ConcreteChild%0A%20%20extend%20HasFoo%0A%20%20sig%20%7B%20override.void%20%7D%0A%20%20def%20self.foo%20%3D%20puts%28%22hello!%22%29%0Aend%0A%0Asig%20%7B%20params%28klass%3A%20HasFoo%29.void%20%7D%0Adef%20example%28klass%29%0A%20%20klass.foo%0Aend%0A%0Aexample%28ConcreteChild%29%20%20%23%20%E2%9C%85%0Aexample%28HasFoo%29%20%20%20%20%20%20%20%20%20%23%20%E2%9D%8C%20type%20error%20prevents%20calling%20this%0A)
    </figcaption>
    </figure>

    Note how `example` uses `HasFoo` instead of `T.class_of(AbstractParent)`, and how the `extend` is in the child class—there isn't even an abstract parent class anymore.

    This is the best option when a class's only abstract methods are singleton class methods. If you want to look at a **more realistic example**, there's an involved one in [the Sorbet docs](https://sorbet.org/docs/generics#a-type_template-example).

1.  Define the abstract module inside a module that is mixed into another module using [mixes_in_class_methods].

    This is the best option if a class has _both_ abstract instance and singleton class methods. It has the same downside as above, in that it involves refactoring some types.

    [mixes_in_class_methods example →](https://sorbet.run/#%23%20typed%3A%20true%0Aclass%20Module%0A%20%20include%20T%3A%3ASig%0A%20%20include%20T%3A%3AHelpers%0Aend%0A%0Amodule%20AbstractParent%0A%20%20abstract!%0A%20%20sig%20%7B%20abstract.void%20%7D%0A%20%20def%20bar%3B%20end%0A%0A%20%20module%20ClassMethods%0A%20%20%20%20abstract!%0A%20%20%20%20sig%20%7B%20abstract.void%20%7D%0A%20%20%20%20def%20foo%3B%20end%0A%20%20end%0A%20%20mixes_in_class_methods%28ClassMethods%29%0Aend%0A%0AAbstractParentClass%20%3D%20T.type_alias%20do%0A%20%20T.all%28AbstractParent%3A%3AClassMethods%2C%20T%3A%3AClass%5BAbstractParent%5D%29%0Aend%0A%0Aclass%20ConcreteChild%0A%20%20include%20AbstractParent%0A%20%20sig%20%7B%20override.void%20%7D%0A%20%20def%20bar%20%3D%20puts%28%22hello!%22%29%0A%0A%20%20sig%20%7B%20override.void%20%7D%0A%20%20def%20self.foo%20%3D%20puts%28%22hello!%22%29%0Aend%0A%0Asig%20%7B%20params%28klass%3A%20AbstractParentClass%29.void%20%7D%0Adef%20example%28klass%29%0A%20%20klass.foo%0A%20%20obj%20%3D%20klass.new%0A%20%20obj.bar%0Aend%0A)

1.  Make the method `overridable` instead of `abstract`, effectively giving the method a default implementation.

    This option does not need as big of a refactor, because it does not introduce any new types or interfaces. But there isn't always a sensible default implementation, so sometimes this option doesn't it can't .

[abstract module]: https://sorbet.org/docs/abstract

[mixes_in_class_methods]: https://sorbet.org/docs/abstract#interfaces-and-the-included-hook

# What do other languages do?

Basically every other typed language correctly avoids this pitfall. For example:

- Scala `object` definitions (analogous to Ruby's singleton classes) cannot have abstract methods, because the object _is_ instantiated (just like Ruby singleton classes).

  [Scala example →](https://godbolt.org/z/x4eMrrb7M)

- In Java and C++, the analogue to singleton class methods are `static` methods. As the name implies, these methods use [static dispatch instead of dynamic dispatch][static-dynamic]. Abstract methods are only useful in combination with dynamic dispatch, so these languages simply ban `abstract static` methods.

  [Java example →](https://godbolt.org/z/1rr8qxhW7)\
  [C++ example →](https://godbolt.org/z/x114TEs3n)

- Despite also using the `static` keyword, TypeScript `static` methods use [dynamic dispatch][static-dynamic]. But TypeScript recognizes that the object representing a class _always exists_ at runtime, so it also bans `static abstract` methods.

  [TypeScript example →](https://www.typescriptlang.org/play?#code/IYIwzgLgTsDGEAJYBthjAgguacIAVgoBTAO0QG8AoBBUSGeBSYCAS1gQDMB7HgCgCUALgQA3HmwAmAbioBfIA)

[static-dynamic]: https://lukasatkinson.de/2016/dynamic-vs-static-dispatch/

Of course, in these languages there isn't the same [rich link](/inheritance-in-ruby/#wait-why-do-we-care-about-inheriting-both) between a class and its singleton class, so the comparison to other languages is a bit shallow.

# Why have abstract singleton class methods at all?

We noticed a ton of code that looked like this when rolling out Sorbet in Stripe's codebase many years ago:

```ruby
class AbstractParent
  def self.foo
    raise NotImplementedError.new("Missing implementation of foo")
  end
end
```

Allowing existing methods like `foo` to be abstract at least requires subclasses to implement them or mark themselves `abstract!`. It's much better than the alternative above of just raising hoping that tests discover unimplemented methods.

There's an escape hatch for code which chooses to use abstract singleton class methods (in spite of all their problems). It's possible to manually check whether a class object is abstract before calling the method:

```{.ruby .numberLines .hl-3 .hl-9}
sig { params(klass: T.class_of(AbstractParent)) }
def example(klass)
  return if T::AbstractUtils.abstract_module?(klass)
    
  klass.foo
end

example(ConcreteChild)
example(AbstractParent) # early return, before klass.foo
```

This `abstract_module?` method doesn't solve the original problem; nothing in Sorbet checks that it's called before calling an abstract singleton class method. But it at least lets authors work around known shortcomings in their code's design without large refactors. Know that from the type system's perspective, **all the three options above** are better than relying on `abstract_module?` checks at runtime.

# Further reading

- [Inheritance in Ruby, in pictures →](/inheritance-in-ruby/)\
  A solid understanding of abstract methods requires understanding how Ruby's inheritance features work (`<`, `include`, and `extend`).

- [Typing klass.new in Ruby with Sorbet →](/typing-klass-new/)\
  If the method you're trying to make abstract is a class's constructor, there's some subtlety to it.

- [Every type is defined by its intro and elim forms →](/intro-elim/)\
  For some high level thoughts on type-driven code organization.

