---
layout: post
title: "What makes type checking Ruby hard?"
date: 2019-12-29 01:29:52 -0600
comments: false
share: false
categories: ['ruby', 'sorbet', 'types']
description: >
  Mutation makes typechecking Ruby harder than many other programming
  languages. Most people will immediately think I mean mutation in the
  sense of `x += 1` or something—that's not what I'm referring to. In
  fact, that's the easy kind of mutation to model in a type system.
strong_keywords: false
---

<p></p>

<!-- more -->

Mutation makes typechecking Ruby harder than many other programming
languages. Most people will immediately think I mean mutation in the
sense of `x += 1` or something—that's not what I'm referring to. In
fact, that's the easy kind of mutation to model in a type system.

What I mean is that nearly everything worth knowing statically about a
Ruby program involves mutation. Defining a class?

```ruby
class A
end
```

That mutates the global namespace of constants. After those lines run,
all code in the project can reference the class `A`.

Defining a method?

```ruby
class A
  def foo
    puts 'hello'
  end
end
```

The method `foo` is undefined just before the `def` block (at runtime!),
but defined after—mutation again.

Ruby provides things like `attr_reader` and `attr_accessor` to define
getter and setter methods:

```ruby
class B
  attr_reader :foo
end
```

`attr_reader` is not a Ruby keyword, contrary to popular belief: it's a
method on the singleton class which takes an argument. It defines an
instance method called `foo` as a side effect by mutating the class `B`.

It's the same for mixing modules into classes:

```ruby
module M; end
class C
  include M
end
```

`include` is another method disguised like a keyword which mutates the
class's list of ancestors.

One of my least favorite Ruby features: you can **redefine** (not
override) a method:

```ruby
class D
  attr_reader :foo
  alias_method :old_foo, :foo
  def foo
    puts 'Calling D#foo'
    old_foo
  end
end
```

Because `D#foo` is defined by the `attr_reader` line, the subsequent
`def` overwrites it (akin to mutating a local variable, like `x += 1`).
Oh and that `alias_method`? Another method looking like a keyword which
mutates the class.

Even the way libraries work in Ruby is powered by mutation:

```ruby
require 'some_gem'
```

`require` is a method (again, not a keyword) that looks up and runs
arbitrary Ruby code, whose result we discard. It's only convention that
the primary side effect of the `require`'d code is to mutate the global
namespace, defining more classes and methods.

## DSLs and metaprogramming

It would be one thing if Ruby constrained the places where this mutation
could occur. But instead, it provides first-class support for these
features anywhere Ruby code runs. Everything we've seen so far can be
hidden behind arbitrary computation at runtime:

- With `Module#const_set`, a Ruby program can compute an arbitrary name
  and use it to create new constant at runtime.
- `Module#define_method` does the same for methods.
- Again `require` is a method, so it can occur wherever other methods
  are called.

It's not uncommon to see Ruby libraries embrace this rather than avoid
it (Rails definitely does). Ruby programs frequently build up large
abstractions and do tons of computation which at the end of the day
result in a `define_method` or a `const_set`.

Rubyists call this "metaprogramming" or "building DSLs" but I call it
like I see it: mutation.

## Modeling mutation

Type systems are notoriously bad at modelling this kind of mutation.
Look at other typed, object-oriented languages: Java, Scala, C++, ...
Each of these languages **forbids** this kind of mutation. (Whether
because it's hard to implement support for it or because they're making
a value judgement is beyond me.)

So how can Sorbet can model this? Mostly, it just cheats. Err,
"approximates." From my experience working on the Sorbet team, I can
think of three main ways it cheats.

First, Sorbet assumes that if a class or method might exist, it does
exist, and universally throughout a project.[^autoloader] It pretends
that all `include`, `extend`, and `alias_method` statements in a class
run first, before all other code at the top-level of that class. It
restricts method redefinitions—the old and new methods must take the
same number and kinds of arguments. And it restricts `alias_method`: you
can only alias to a method on your class, not to a parent class. Sorbet
makes no attempt to model `undef_method` at all (another
method-not-keyword!).

[^autoloader]: Frequently this assumption is backed up by an autoloader. For example, Rails includes an autoloader that loads constants lazily on demand, so that the programmer doesn't have to sprinkle require statements throughout the code. But how do autoloads work? Mutation again 🙂.

Second, Sorbet cheats by implementing heuristics for the most common
DSLs. To support `attr_reader`, Sorbet says, "Hey, this method call
happens to be to some method named `attr_reader`. I'm not sure if it's
to `Module#attr_reader` or to some other `attr_reader` definition or to
any definition at all, but it's provided with a single Symbol argument,
the result is discarded, and it's called at the syntactic top-level of a
class, so I bet that it is a call to `Module#attr_reader`." It's similar
for many other popular DSLs: it makes decent educated guesses.

But after all that, it sort of gives up. Sorbet makes no attempts to
work backwards from a call to `define_method` or `const_set` inside a
method body to learn that a class or method might have been defined
somewhere. Instead, it cheats one last time and uses runtime information.

As a part of initializing a Sorbet project, Sorbet `require`s (read:
executes) as much code in a project as it can: all the gems listed in
the Gemfile and all the Ruby files in the current folder. Afterwards, it
can see the result of all that's been mutated thus far (via reflection)
and serialize what it sees into [RBI files] to convey what it saw to the
static checker. This is still imperfect (it completely misses things
that are defined after `require` time), but empirically it finds most of
the remaining undiscovered definitions.

[RBI files]: https://sorbet.org/docs/rbi

## Beyond mutation

Don't get me wrong, those approximations are really useful and
effective. But really, the way Sorbet handles mutation in a codebase is
by incentivicing people to get rid of it.

- Sorbet can type check a project in seconds, but it takes minutes to
  re-generate all RBIs files. When Sorbet can see things statically,
  there's also a canonical place to write a type annotation for it.

- It's a much better experience to click "Go to Definition" and jump to
  the actual source definition rather than to an auto-generated RBI
  file.

- And arguably, if it's easy for Sorbet to understand what's defined and
  where, it's easier for a programmer to understand. Understandable code
  lets people iterate faster, is less brittle, and harder to break by
  accident.

Programming languages are tools to change and structure the way we
think. In the long run, all code can be changed. We adopt type systems
specifically to help guide these changes, which [I've touched on
before]. When it comes to mutation in Ruby, Sorbet makes a solid effort
to model the helpful parts, while providing guide rails and suggestions
to deal with the rest.


[I've touched on before]: https://blog.jez.io/on-language-choice/

- - -

## Appendix A: By comparison with typed JavaScript

You might say, "the things that you're talking about aren't unique to
Ruby! It's the same for all dynamic programming languages!" But is that
true in practice?

Let's compare our Ruby snippets from before with JavaScript.

Ruby:

```ruby
class A
  def self.my_dsl(name)
    define_method(name) do; end
  end
end
```

JavaScript:

```js
class A {
  static myDsl(name) {
    this.prototype[name] = function() {}
  }
}
```

First I'll point out: the mutation becomes way more obvious in the
JavaScript program! But second: both TypeScript and Flow report static
errors on this program. They both complain that there's no type
annotation declaring that it's ok to treat `this.prototype` as if it
were a key-value mapping.

The fact that both Flow and TypeScript report an error here speak to how
common this idiom is in practice. It's not common, and they'd rather not
encourage programs like this, so they forbid it.

Here's another example, first in Ruby:

```ruby
require 'some_gem'

SomeNamespace::SomeClass.new
```

And then in JavaScript:

```js
import someNamespace from 'some_package';

new someNamespace.SomeClass();
```

With no RBI files declaring whether `SomeNamespace::SomeClass` exists
or not, Sorbet will report an error that the class doesn't exist. But in
TypeScript and Flow, the code is just fine, even if there's no type
declaration file. Both can still see that whatever vale is imported will
be bound to the `someNamespace` variable (even if it's treated as
`any`).

Sorbet is thus forced to come up with ways to generate RBI files for all
new projects, because without them Sorbet would be crippled: it would
have no way to distinguish between a class name that has actually been
typoed vs one that is typed correctly but for which there's no visible
definition. Meanwhile, TypeScript and Flow work completely fine in new
codebases out of the box.

So my claim is that: no, these problems **are** unique to Ruby, because
the design of the language and the culture of its use so pervasively
promote or require mutation.

## Appendix B: More things that are actually mutation

- `freeze` (ironic: to prevent mutation on a class or object... we
  mutate it!)

- `private` / `private_class_method` (not keywords! These are methods
  that take a **Symbol**; it just so happens that `def foo; end` is an
  expression that evaluates to the symbol `:foo`. Which is why there's
  both `private` and `private_class_method`, because `def self.foo; end`
  also evaluates to `:foo`, so `private def self.foo; end` would attempt
  to mark an **instance** method named `:foo` private, even it didn't
  exist!)


<!-- vim:tw=72
-->
