---
# vim:tw=90
layout: post
title: "Singletons and Flow-Sensitive Typing"
date: 2020-09-25T21:00:58-05:00
description: >-
  A look at how two type system features overlap in a surprising way.
math: true
categories: ['ruby', 'sorbet', 'types']
# subtitle:
# author:
# author_url:
---

> **Editing note**: This post first appeared in a work-internal email. It was first
> cross-posted to this blog December 12, 2022.

Someone asked a question at work on Slack this week, and I thought it would be a neat
chance to look at a small part of Sorbet's flow-sensitive type checking algorithm.
Paraphrasing, the question was:

<blockquote>
I want to create some config classes that can inherit from each other. For example:

```ruby
class BaseConfig; ...; end
class SpecialConfig < BaseConfig; ...; end
```

`SpecialConfig` could override some behaviors, etc. Since there's no point creating
multiple instances of the same config class, I'm thinking about using Ruby's `singleton`
module to enforce that there's only one instance of each config class. Is this good or
bad?
</blockquote>

The Ruby standard library includes the
[`singleton`](https://ruby-doc.org/stdlib-2.6.5/libdoc/singleton/rdoc/Singleton.html) gem
as a drop-in implementation of the [Singleton
pattern](https://en.wikipedia.org/wiki/Singleton_pattern). It allows people to write code
like this:

``` ruby
require 'singleton'
class MySingleton
  include Singleton
end

# all calls to `.instance` return a reference-equal object
puts MySingleton.instance

# it's impossible to construct two instances of this class
MySingleton.new # => raises `TypeError`
```

Maybe you already have your own opinions about the Singleton pattern: I'm not here to
debate you. If you don't have your own opinion, Wikipedia has you covered:

> Critics consider the singleton to be an anti-pattern in that it is frequently used in
> scenarios where it is not beneficial […] and introduces global state into an
> application.

Instead, I'd like to convince you why that this specific **combination** (the Singleton
pattern and inheritance) is a bad idea. I'm going to do it by reasoning from the
perspective of the type system, and I'll starts with the observation that if we let
singletons be subclassed, we don't really have a singleton anymore:

<figure class="left-align-caption">

``` ruby
require 'singleton'
extend T::Sig
class ParentSingleton; include Singleton; end
class ChildSingleton < ParentSingleton; end

sig {params(x: ParentSingleton).returns(TrueClass)}
def takes_parent_singleton(x)
  if x == ParentSingleton.instance
    true
  else
    T.absurd(x)
  end
end
```

<figcaption>
[→ View on sorbet.run](https://sorbet.run/#%23%20typed%3A%20true%0Arequire%20'singleton'%0Aextend%20T%3A%3ASig%0Aclass%20ParentSingleton%3B%20include%20Singleton%3B%20end%0Aclass%20ChildSingleton%20%3C%20ParentSingleton%3B%20end%0A%0Asig%20%7Bparams(x%3A%20ParentSingleton).returns(TrueClass)%7D%0Adef%20takes_parent_singleton(x)%0A%20%20if%20x%20%3D%3D%20ParentSingleton.instance%0A%20%20%20%20true%0A%20%20else%0A%20%20%20%20T.absurd(x)%0A%20%20end%0Aend)
</figcaption>
</figure>

In this snippet, we've set up a parent / child relationship between two singleton classes,
and defined a method that takes in an (the?) instance of the `ParentSingleton` class.
Ideally, this function would be trivial. Our `sig` enforces that we're given an instance
of `ParentSingleton`, so the only valid value for `x` would be `ParentSingleton.instance`,
and then the equality comparison on line 8 would never fail.

But that's not what happens, because `x` could also be `ChildSingleton.instance`:

``` ruby
takes_parent_singleton(ChildSingleton.instance)
```

`ChildSingleton` is a subtype of `ParentSingleton`, so this call site is perfectly fine
types-wise. Sorbet has to reject the definition of `takes_parent_singleton` statically so
the [`T.absurd`](https://sorbet.org/docs/exhaustiveness) never fails at runtime:

``` plain
editor.rb:12: Control flow could reach `T.absurd` because the type `ParentSingleton` wasn't handled https://srb.help/7026
    12 |    T.absurd(x)
            ^^^^^^^^^^^
```

At a high-level, Sorbet's [flow-sensitive](https://sorbet.org/docs/flow-sensitive)
analysis takes steps like these to arrive at that error message:

1.  Start by looking at `x == ParentSingleton.instance`. It's used in an `if` condition,
    so we might need to update our knowledge about the type of `x` under some
    hypotheticals.

2.  Hypothetical 1: the condition is `true`. If these values are equal, then certainly
    their types must be equal, so we record this implication in our set of knowledge:

    `x == ParentSingleton.instance` $\Longrightarrow$ `x.is_a?(ParentSingleton)`

    We read this as "whenever the left side is true, then also the right side must be
    true."

3.  Hypothetical 2: the condition is `false`. If these values are not equal, we know
    nothing types-wise. We don't record any new knowledge about the type of `x`.

4.  Finish type checking the rest of the method. When we're type checking a different part
    of our method where we know whether `x == ParentSingleton.instance` is `true` or
    `false`, we can look up the relevant knowledge we recorded earlier and apply that
    implication to the types of any variables still in scope.

Step 3 could look different, if only Sorbet had the extra knowledge that `ParentSingleton`
was [a final class](https://sorbet.org/docs/final#final-classes-and-modules), i.e., one
that can't be subclassed. In this case, everything from earlier we wished were true
actually is true: `ParentSingleton` is now a real singleton, a type inhabited by only one
value:

<figure class="left-align-caption">

``` ruby
class ParentSingleton
  include Singleton
  extend T::Helpers
  final! # <- declare that this class can't be subclassed
end

class ChildSingleton < ParentSingleton; end # static error!
```

<figcaption>
[→ View on sorbet.run](https://sorbet.run/#%23%20typed%3A%20true%0A%0Aclass%20ParentSingleton%0A%20%20include%20Singleton%0A%20%20extend%20T%3A%3AHelpers%0A%20%20final!%20%23%20%3C-%20declare%20that%20this%20class%20can't%20be%20subclassed%0Aend%0A%0Aclass%20ChildSingleton%20%3C%20ParentSingleton%3B%20end%20%23%20static%20error!)
</figcaption>
</figure>

Here's how Step 3 would look instead if `ParentSingleton` was final:

3.  Hypothetical 2: `x == ParentSingleton.instance` is `false`. Since `ParentSingleton` is
    a final class, we have exhaustively checked all values of this type and determined
    that `x` isn't any of them. That means we can record this implication in our set of
    knowledge:

    `x != ParentSingleton.instance` $\Longrightarrow$ `!x.is_a?(ParentSingleton)`

Later on when the `else` branch of our method is type checked, we'd look up this
implication and apply it to the types of the variables in scope. If `x` can't be
`ParentSingleton`, then it can't be anything, and Sorbet updates it's knowledge of the
type of `x` to [`T.noreturn`](https://sorbet.org/docs/noreturn), and it no longer reports
an error on the `T.absurd`.

In fact, this feature (in combination with a few other features) is actually how
[`T::Enum`](https://sorbet.org/docs/tenum) worked for almost a year! If you're curious you
can check out [the original
PR](https://github.com/sorbet/sorbet/pull/1473/files#diff-f035687fd87cb5891ce1011ef2b79c7cR1)
where I implemented it. (We [ended up changing
it](https://github.com/sorbet/sorbet/pull/3213) to work differently for unrelated
reasons.)

Hopefully this explanation answers the original question (don't use inheritance with
singletons!) but also gives a little insight into what's happening when Sorbet type checks
a program.
