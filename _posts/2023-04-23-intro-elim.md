---
# vim:tw=90
layout: post
title: "Every type is defined by its intro and elim forms"
date: 2023-04-23T19:43:00-04:00
description: >-
  I took a course about programming languages in college. It was a very theory-oriented
  course, but as it turned out I learned more about how to write software from this theory
  course than many of my peers who took our school's software engineering elective.
math: false
categories: ['programming', 'plt', 'types']
# subtitle:
# author:
# author_url:
---


I took a course about programming languages in college. It was a very theory-oriented
course, and honestly I only signed up to meet a requirement—the school wanted to ensure
we took a smattering of theory courses before sending us out into the Real World. But as
it turned out, I learned more practical skills about how to write good code from this
theory course than many of my peers who took our school's software engineering elective.

The biggest lesson? **Every type is defined by its intro and elim forms.**

<!-- more -->

It's a short lesson, but one that applies _all over the place_. To reword it into more
familiar terms: when defining a new data structure, you have to declare how to
construct—or "introduce"—values of that structure. You also have to declare what the data
structure can do, which usually involves reading, transforming, or otherwise destructuring
the data, which we can call "eliminating."

Constructing and destructuring. Introducing and eliminating. Every type is defined by
operations that do one of these two things, and we can call those operations "forms" for
short.

Importantly, if we're sloppy in defining a type's intro and elim forms, the type's meaning
is equally sloppy. Sloppy definitions are kind of obviously bad if you're in the business
of writing proofs about type systems. But what the course made me realize: they're just as
bad for us software engineers! Sloppily-defined types make it hard to build a mental model
of what the type does, which leads to confusion, misuse, and bugs.

Even in languages without a static type system, this lesson still applies. We define data
structures when writing code in all languages, and those data structures are defined by
their intro and elim forms in every last one of them. The operations which create and
transform data structures shape a programmer's mental model of a codebase, regardless of
whether there's a type system to reify that mental model into type annotations.

But this is the infuriating part: most real-world languages are cavalier when it comes to
defining types. Sloppily-defined types are the **default**, and programmers usually have
to work to overcome deficiencies in their language to define types well.

To give some color, here are three common problems I see. (This is not an exhaustive
list.)

### Too many constructors

Some languages automatically define a ton of ways to construct an object. For example,
define a simple struct like this in C++:

```cpp
struct A {
  int x;
  string y;
  bool z;
};
```

and suddenly you've got all these options for instantiating it:

[^go-rust-contrast]

```cpp
// Initialize all the fields to their default/zero value.
A a;

// Initialize by providing values for all the fields.
A a{.x = 1, .y = "hey", .z = true};

// Initialize by providing only some of the fields
A a{42};
```

When defining a type, we should be explicit about which of these we want. Do we want the
type to have an implicit "default" value? Do we want to allow omitting some of the
values during initialization? Do we want to _prevent_ providing some values during
initialization? Do we want to do any validation on these values, and fail to construct
an instance if validation fails?

For some types, the answer to these questions will be, "yes, a default value is fine,"
"yes, omitting some values is fine," "no, let them pass all the values if they
want," and "no, we don't need validation." But other times our answers will be
different, and in many languages it's too hard to remember all the things we have to
retroactively lock down after defining a new type. It would be better if we could start
from nothing and build up what's allowed, offering syntactic conveniences for
commonly-defined operations.

[^go-rust-contrast]:
  {-} It's even worse in Go, where there's nothing you can do to turn this "everything can
  be zero-initialized" behavior off.\
  \
  By contrast, Rust allows writing `#[derive(Default)]` above a struct to opt into
  zero-initialization.


### Too many common methods

Many languages default to providing certain elim forms for _all_ types. For example, in
Ruby every value descends from `BasicObject`, which defines the `==` method. But there
are a couple problems with this method.

First, not every value wants to allow equality comparisons! The classic example of
this is function values—since we can't solve the halting problem, the only real way of
defining `==` for lambda values is reference equality. But then if a lambda is ever
duplicated for some reason,[^dup] suddenly two things which are conceptually equal are
not, which is likely to cause a logic error.

Second, the contract of this `==` method is that _any value_ can be compared for
equality to _any other value_, even of a different class![^sorbet-eq] For many people,
that amounts to a sloppy, bug-inducing definition of `==`: they'd rather know that
they're comparing two completely incompatible things, than have the comparison silently
evaluate to `false` and continue running. But the language has made this choice, and now
all our types must inherit this possibly-unwanted elim form.[^rust-eq]

[^dup]:
  This can happen for very accidental reasons. Given `def ex; ->{1}; end` then `ex() ==
  ex()` is `false`.

[^sorbet-eq]:
  I wrote about the difficulty this causes for Sorbet in [this post][sorbet-eq-post].

[^rust-eq]:
  Some languages, like Rust and Haskell, do not define `==` by default but can generate a
  default implementation easily, on request.

### Types are not their elim forms

Some languages equate "defining a type" with "defining an interface." But that's akin to
saying that it's enough to define a type by only specifying its elim forms! For
example, in Java there's basically no way to abstract over how a type is created:

```java
interface Foo {
  void foo();
}
```
This interface specifies how values of type `Foo` can be used (by calling `x.foo()`),
but not how they can be created. You can settle for defining a constructor on a class
(maybe even an abstract class), but this ties the abstract specification of a type with
it's concrete implementation. Best to let a language's facilities for abstraction
abstract over both intro and elim forms.[^ts-new]

[^ts-new]:
  To temper people misinterpreting this as a Rust shill post, a TypeScript example this
  time. TypeScript lets interfaces declare a `new()` method, which thus allows abstracting
  over how a type is created. There's a few tricks to it, and [this post][ts-new-post]
  outlines them as well or better than I could.

[sorbet-eq-post]: /problems-typing-ruby-equality/
[ts-new-post]: https://fettblog.eu/typescript-interface-constructor-pattern/

\

I've listed these three as personal pet peeves, but if you start to pay attention, you'll
find more. When defining types, start asking yourself:

- How can someone create values of this type?
- Is that the _only_ way?
- What should be possible to do with this type?
- Is my language implicitly defining unwanted operations on my type by default?

We rarely get to choose the language we use, and even when we do, every language has its
own warts. None are going to offer the exacting precision for defining types that exists
in the world of theory.

And yet, we can familiarize ourselves with those warts and the tools the language _does_
offer. That learned familiarity, and a constant eye towards intro and elim forms, lets us
sharpen the meaning of our types, making the code we write more powerful.

\

- - - - -

\

# Appendix: tools for defining intro and elim forms

An informal and non-exhaustive list of some features that many languages have around
controlling intro and elim forms. If you have any common tricks, feel free to tell me
about them! I may update this list over time.

### Visibility modifiers

If you make a method private, that removes an elim form from your type.\
If you make a constructor private, that removes an intro form from your type.

### Abstract methods and interfaces

Even though in many languages these only allow specifying elim forms, they're still
wildly useful. My personal experience also tells me that they're wildly underused.

Interfaces allow multiple classes to share the same elim forms. They also allow a form
of "self control," where a method promises to only use some of the elim forms that a
type might otherwise have. Providing fewer elim forms makes a type's mental model
smaller and more understandable.

### Smart constructors

Usually just a clever use of visibility modifiers and static methods, not something
built into the language. Most languages don't allow specifying the return type of a
constructor, which places limits on what kinds of intro forms you can define. You can
get around this by marking the constructor private, providing your own static method
which creates instances of the class (which may have an arbitrary return type).

In this C++ example, we see the `CardNumber::make` method returns
`optional<CardNumber>`, in effect saying that constructing a `CardNumber` might fail:

```{.cpp .numberLines .hl-7 .hl-9}
class CardNumber {
private:
  string number_;
  CardNumber(string number) : number_(number) {}

public:
  static optional<CardNumber> make(string number) {
    if (!luhnCheck(number)) {
      return nullopt;
    }
    return CardNumber(number);
  }

  string number() { return this->number_; }
}
```

The only way to introduce a value of type `CardNumber` is to call `make`. That function
will return `nullopt` if the provided number is invalid according to the [Luhn
algorithm].

[Smart constructors]: https://wiki.haskell.org/Smart_constructors
[Luhn algorithm]: https://en.wikipedia.org/wiki/Luhn_algorithm

# Appendix: operational vs denotational semantics

If you want to get _very_ into the weeds, the idea that all types are defined by
introduction and elimination forms assumes you're approaching type theory from an
[operational semantics] viewpoint.

Simply as a disclaimer, I want to note that this is not the only viewpoint from which to
approach type theory. Another popular approach uses [denotational semantics], where
instead of describing a type by what it does, you describe a type by what mathematical
properties all elements of that type have.

There are fun real-world insights to draw from denotational semantics too, but that'll
have to be some other post.

[operational semantics]: https://en.wikipedia.org/wiki/Operational_semantics
[denotational semantics]: https://en.wikipedia.org/wiki/Denotational_semantics



