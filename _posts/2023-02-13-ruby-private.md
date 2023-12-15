---
# vim:tw=90
layout: post
title: "Ruby's private keyword is weird"
date: 2023-02-13T13:58:43-05:00
description: >
  Ruby's `private` keyword means something different compared to basically all other
  object-oriented languages. Most other languages don't even have a feature matching what
  Ruby calls `private`, but incredibly, Scala does, which it calls `protected[this]`
  (meaning "object-protected", as opposed to the normal `protected` keyword which is
  called "class-protected").

  First let's review what `private` normally means, and then discuss what `private` in
  Ruby means (which will also amount to an explanation of what `protected[this]` means in
  Scala).
math: false
categories: ['ruby', 'scala']
# subtitle:
# author:
# author_url:
---

Ruby's `private` keyword means something different compared to basically all other
object-oriented languages. Most other languages don't even have a feature matching what
Ruby calls `private`, but incredibly, Scala does, which it calls `protected[this]` (meaning
"object-protected", as opposed to the normal `protected` keyword which is called
"class-protected").

First let's review what `private` normally means, and then discuss what `private` in Ruby
means (which will also amount to an explanation of what `protected[this]` means in Scala).

# Background: the normal meaning of `private`

Conventionally, `private` means "only code contained inside my class's body can access
this member," for example in Java:

```{.java .numberLines .hl-2}
class Parent {
    private int x;

    Parent(int x) {
        this.x = x;
        //   └── (1) allowed ✅
    }

    boolean equals(Parent other) {
        return this.x == other.x;
        //          │          └── (2) allowed ✅
        //          └── (1) allowed ✅
    }
}

class Child extends Parent {
    Child(int x) { super(x); }
    int example() {
        return this.x; // (3) not allowed ⛔️
    }
}

Parent parent = new Parent(0);
parent.x; // (4) not allowed ⛔️
```

In this example we see a member `x` marked private. In summary:

1.  ✅ The member `x` can be accessed as `this.x` inside methods within the class body of `Parent`
1.  ✅ The member `x` can also be accessed on other instances of `Parent` within the class
    body of `Parent`, like `other.x`
1.  ⛔️ The member `x` cannot be accessed in subclasses of `Parent`, like `Child`
1.  ⛔️ The member `x` cannot be accessed outside of the inheritance hierarchy of `Parent`

Now let's translate this example to Ruby to see what restrictions the `private` keyword in
Ruby brings.

# Restrictions on `private` in Ruby

Here's the same Java example, converted to Ruby. What we see is that points (2) and (3)
flip!

```{.ruby .numberLines .hl-3}
class Parent
  attr_accessor :x
  private :x, :x=

  def initialize(x)
    self.x = x
    #    └── (1) allowed ✅
  end

  def ==(other)
    self.x == other.x
    #    │         └── (2) not allowed ⛔️
    #    └── (1) allowed ✅
  end
end

class Child < Parent
  def example
    self.x # (3) allowed ✅
  end
end

parent = Parent.new(0)
parent.x # (4) not allowed ⛔️
```

Here's what Ruby's `private` keyword allows:

1.  ✅ The member `x` can be accessed as `self.x` inside methods within the class body of `Parent`
1.  ⛔️ The member `x` cannot be accessed on other instances of `Parent` within the class
    body of `Parent`, like `other.x`
1.  ✅ The member `x` cannot be accessed in subclasses of `Parent`, like `Child`
1.  ⛔️ The member `x` cannot be accessed outside of the inheritance hierarchy of `Parent`

# Why is Ruby like this?

Most other object-oriented languages rely on type checking to report visibility errors
before the program runs. Ruby doesn't have a type checker and also is quite dynamic.
Classes can be reopened and extended basically at whim, and the notion of "within the
class body" barely exists in Ruby because of how easy it is to dynamically define methods
from anywhere:

```ruby
module MyDSL
  def make_method
    define_method(:get_x) do
      MyDSL.internal_helper
      #     └── should this be allowed? 🤔
      # (technically inside the class body of MyDSL)

      self.x
      #    └── should this be allowed? 🤔
      # (technically not inside the class body of Parent)
    end
  end

  private_class_method def self.internal_helper
    # ...
  end
end

class Parent
  extend MyDSL
  make_method
end
```

Real-world Ruby code tends to toss away conventional notions of "defined inside the class
body," and even if it didn't, it wouldn't have a type checker to easily check visibility.

Instead, Ruby picks a simpler way to enforce visibility: a private call is allowed
anywhere that the receiver is either omitted or is `self`, **syntactically**.[^omit] That
syntactic restriction means that things like this are not allowed:

[^omit]:
  {-} The receiver is the `x` in `x.foo`. When a method call's receiver is omitted like
  `foo()`, Ruby implicitly assumes that it had been called like `self.foo()`.

```ruby
class A
  private def foo; end
end

def identity(self); self; end

identity(self).foo # ⛔️ not syntactically `self.foo`
self.itself.foo    # ⛔️ not syntactically `self.foo`
```

By using local syntax to determine when it's okay to call private methods, Ruby ends up
allowing access via inherited classes and denying access via something like `other.x`.
This mechanism is very simple to check: it just a matter of remembering a bit like
`isPrivateOk` per method call and a bit per method def like `isPrivate`, which can be done
without any sort of non-local/static analysis.

# Ruby is not unique: `protected[this]` in Scala

For a while, I thought that Ruby was unique in having a visibility modifier that worked
like this, but recently I learned that Scala actually has a similar feature:
`protected[this]`. The name wasn't immediately obvious to me, but it's actually kind of
sensible:

- Like the `protected` visibility modifier, `protected[this]` allows (certain kinds of)
  member access from subclasses.
- The `[this]` portion is called an "access qualifier" which limits all access to happen via
  the `this` keyword.

It seems that Scala allows other things to appear inside the `[...]`, but I stopped short
of wrapping my head around what. I learned about this feature from this page:

[→ Scala Language Specification, Version 2.13, Chapter 5 Classes and Objects, Section 5.2
Modifiers](https://scala-lang.org/files/archive/spec/2.13/05-classes-and-objects.html#modifiers)

Maybe worth a skim if you're more curious than I was.

Scala also has `private[this]`, which excludes access via subclasses (leaving only access
via `this` inside the parent class). Ruby doesn't have a visibility level matching this,
which means that Ruby has no means to hide a member from subclasses.

# A note about Ruby instance variables

Despite not being declared with the `private` keyword, instance variables in Ruby behave
exactly like `private` methods!

```{.ruby .numberLines .hl-3}
class Parent
  def initialize(x)
    @x = x
    #└── "declares" an instance variable
    #    (automatically private)
  end

  def ==(other)
    @x == other.@x
    #│           └── (2) syntax error ⛔️
    #└── (1) allowed ✅
  end
end

class Child < Parent
  def example
    @x # (3) allowed ✅
  end
end

parent = Parent.new(0)
parent.@x # (4) syntax error ⛔️
```

So you might next ask, "would it make sense to have 'public' instance variables?" I can
see arguments both ways:

### Pros

- Maybe it scratches a burning itch for symmetry?
- It could be used to resolve problems that arise in Sorbet's control flow-sensitive
  typing, which I [discussed in a previous post].
    - Counter point, also raised in the post above: you could imagine solving this another
      way, by treating `x.foo` and `x.foo()` differently (despite both meaning the same
      thing in the Ruby VM).
- Maybe (_maybe_) it could be optimized more easily by the Ruby VM?
  - Counter point, the VM already has a lot of special cases for `attr_reader`-defined
    methods, so I'm not actually certain whether this point is valid.

[discussed in a previous post]: https://blog.jez.io/syntactic-control-flow/#properties-and-attributes-in-other-languages

### Cons

- In order to keep backwards compatibility, it wouldn't even be all that symmetric.
  - Methods would default to public visibility and have a `private` keyword, but instance
    variables would default to private and have some sort of `public` keyword.
- Instance variables in Ruby represent encapsulated state. They shouldn't leak into the
  public API, and should instead be exposed by proper methods.

It's not a fight I want to start (nor one I feel strongly about). But I will at least
point out that nearly all other languages expose a (syntactic) difference between calling
a method and accessing an attribute.

# Any other languages?

So far, I'm only aware of Ruby's `private` modifier and Scala's `protected[this]` which
behave like this. If you know of any other languages, please email me! I'd love to hear
about them.

\

\

# Appendix: Some unanswered questions

- Question 1: why does Scala have both `private`/`protected` and
  `private[this]`/`protected[this]`?

  I don't know of the history there, but I do know that the latter is useful especially in
  generic classes with covariant and/or contravariant type members. More on that in another
  post (maybe). I will say though, it's actually quite lucky that Ruby works the way it
  does, or Sorbet would not be able to provide generic, co-/contravariant classes with [as
  few changes as this!](https://github.com/sorbet/sorbet/pull/6721)

- Question 2: what's up with Ruby's `protected` keyword?

  A great question, but one that I'll have to save for another post!




