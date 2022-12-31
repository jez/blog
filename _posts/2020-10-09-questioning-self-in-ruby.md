---
# vim:tw=90
layout: post
title: "Questioning self in Ruby"
date: 2020-10-09T21:12:03-05:00
description:
  Some ramblings on what `class << self` and `def self.` mean in Ruby.
math: false
categories: ['ruby']
# subtitle:
# author:
# author_url:
---

> **Editing note**: This post first appeared in a work-internal email. It was first
> cross-posted to this blog December 12, 2022.

Have you ever wondered why this Ruby snippet runs with no errors:

``` ruby
# -- example1.rb --

  def self.bar; end
  def foo; end
  bar()
  foo()
 
```

but this Ruby snippet raises a `NoMethodError` on the last line:

``` ruby
# -- example2.rb --
class A
  def self.bar; end
  def foo; end
  bar()
  foo() # undefined method `foo' for A:Class (NoMethodError)
end
```

What gives? All we did was wrap the code in a class (versus letting the code run at the
top-level of a file). The second example should be unsurprising—we write code like this
all the time, and we've come to learn that instance methods like `foo` can only be called
on instances of `A`. Within the class body of `A` only singleton methods like `bar` can be
called.

I was pretty annoyed that this intuition didn't translate to methods defined at the
top-level of a file, so I asked why. Turns out: the Ruby VM uses separate algorithms for
figuring out what class to define a method on. The two separate algorithms look like this:

## Case 1: `def qux; end`

As Ruby evaluates code, it maintains a lexical nesting scope of classes. This is the same
nesting scope that it uses when looking up constants:

``` ruby
# nesting scope: [Object]
class A
  # nesting scope: [Object, A]
  module X; end
  class B
    # nesting scope: [Object, A, B]
    puts X # => A::X
  end
end
```

In this example, the module `X` is referenced without leading `::` like `::X`, so Ruby
searches for constants named `X` in the nesting scope (it also searches other places, but
those places don't affect method definitions).

For a method definition like `def qux; end`, Ruby looks up the top of the scope and enters
a method into that class's method table. That is, this snippet defines `A#foo` because
it's nested lexically in `A`:

``` ruby
class A
  def foo; end
end
```

This was the first thing that tripped me: when defining a method using `def qux; end`, the
current value of `self` **doesn't matter at all** (this will be important later!).

## Case 2: `def (expr).qux; end`

When a method definition has a receiver, it's the opposite: the lexical class nesting
scope doesn't matter, while the value `expr` evaluates to does. The steps the Ruby VM
follows are like this:

1.  Evaluate `(expr)` to a value. I'll call that `v`. This can be an (almost) arbitrary
    value! It doesn't have to result in a `Class` instance.
2.  Take `v.singleton_class`. Every object has a singleton class.
3.  Define the method named `qux` on that singleton class.

It just so happens that when executing a class body, Ruby sets `self` to the current
class:

``` ruby
class A
  puts self == A # => true
  def self.bar; end
end
```

Looking specifically at the method definition, Ruby will evaluate `self` to the value `A`,
then take `A.singleton_class`, and then define the `bar` on that (singleton) class.

It happened that here we were calling `.singleton_class` on a class, but we can call
`.singleton_class` on any (non-class) object! That's how the file top-level works.

## The file top-level

We now can understand why `example1.rb` doesn't raise any errors:

``` ruby
# -- example1.rb --

  def self.bar; end
  def foo; end
  bar()
  foo()
```

When Ruby starts running a program, it sets the nesting scope to `Object` like [in
vm.c](https://github.com/ruby/ruby/blob/v2_7_2/vm.c#L3269). But then it sets `self` to a
completely unrelated value. The value it chooses is one it just [makes out of thin
air](https://github.com/ruby/ruby/blob/v2_7_2/vm.c#L3357-L3359) at startup. In pseudo
code, the top self is invented kind of like this:

``` ruby
RubyVM::TopSelf = Object.new
def RubyVM::TopSelf.to_s; "main"; end
self = RubyVM::TopSelf
```

(You can't actually assign to `self`—the Ruby VM does by [writing to a field in a C
struct](https://github.com/ruby/ruby/blob/5445e0435260b449decf2ac16f9d09bae3cafe72/vm.c#L3266).)
Ruby calls the top self object `main`:

``` ruby
❯ ruby -e 'puts self'
main
```

So what happens when Ruby sees `def foo; end` at the top of a file? Well, the lexical
class scope was set to `Object`, so it defines `Object#foo`.

And what happens when Ruby sees `def self.bar; end` at the top of a file? `self` has been
set to this magical `main` object (which happens to be an instance of `Object`). Ruby
computes `.singleton_class` for that `main` object and defines a method on the singleton
class of that `Object` instance directly.

From there, Ruby's method lookup algorithm takes over. To find a method on a receiver
`expr`, Ruby looks in `expr.singleton_class.ancestors`. So for the file top-level, that
includes both `self.singleton_class` and `Object`:

``` plain
❯ ruby -e 'p self.singleton_class.ancestors'
[#<Class:#<Object:0x00007fa7258be2b8>>, Object, Kernel, BasicObject]
```

but for a class body, that only includes the class's singleton class (`#<Class:A>`), not
the class itself:

``` ruby
❯ ruby -e 'class A
  p self.singleton_class.ancestors
end'
[#<Class:A>, #<Class:Object>, #<Class:BasicObject>, Class, Module, Object, Kernel, BasicObject]
```

And there it is.

## Appendix: But why?

There were a whole bunch of "…but why?" questions I had when I learned this.

-   **Why not make it as if all files were wrapped in `class Object; ...; end`?**

    I think the Ruby authors explicitly wanted `def foo; end; foo` to work, because this
    is more convenient for people writing short scripts.

-   **Why not make the first lexical scope be `main` instead of `Object`?**

    You can only define constants on a class, not an object:

    ```
    ❯ ruby -e 'self::X = 1'
    Traceback (most recent call last):
    -e:1:in `<main>': main is not a class/module (TypeError)
    ```

    `X = 1` at the top level works because that actually defines `Object::X`

    ```
    ❯ ruby -e 'X = 1; p Object::X'
    1
    ```

If you have more questions than me (or more answers) after reading this, I'm eager to hear
😅

## Appendix: Further reading

I learned most of what I learned here by reading "Chapter 9: Metaprogramming" in *Ruby
Under a Microscope* by Pat Shaughnessy:

→ <http://patshaughnessy.net/ruby-under-a-microscope>

and by reading the Ruby source code. If you want to set up really good jump-to-def on the
Ruby source code, I wrote a guide for that:

→ <https://blog.jez.io/clangd-ruby/>

