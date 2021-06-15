---
layout: post
title: Some Intuition on Lenses
date: 2018-02-05 21:09:43 -0800
comments: false
share: false
categories: ['haskell', 'types']
description: >
  I've been working with lenses on a small project recently, and I
  thought I'd write up some of my intuition about how they work.
strong_keywords: false
fancy_blockquotes: true
---

I've been working on a small project in Haskell recently that uses the
[wreq] library. It's an HTTP client library that exposes most of its
functionality through lenses. Using this library is my first time really
using lenses pervasively, so I've spent some time trying to understand
how lenses really work.

[wreq]: https://hackage.haskell.org/package/wreq

<!-- more -->

Lenses try to bring the concept of getters and setters into a functional
setting. Here, "functional" means that lenses prioritize composition
(chaining one lens after another) and immutability (returning a new
data structure[^perf] instead of mutating the old one in place).

[^perf]: It's common to think that "immutable" means "copy the entire thing" and then change the parts you care about. But if you start with **all data** being immutable, then you only need to allocate new memory for the subcomponents of your data structure that **actually** changed. Everything else can be shared by the old and the new.

In a functional setting, if we have a type `s` and we want to get some
field of type `a` from it, a getter is just a function `s -> a`.

Similarly, a setter that updates that field has the type `s -> a -> s`
which takes the old `s` and slots the `a` into it, giving us back a new
`s`.

Let's see if we can build up some intuition, starting with these types
and ending with the type of `Lens'` from the lens library:

```haskell
type Lens' s a = forall f. Functor f => (a -> f a) -> (s -> f s)
```

In particular, let's start with our getter:

```haskell
fn :: s -> a
```

The first thing we can do is convert it to continuation-passing style
(CPS). In CPS form, a function throws it's return value to a
user-specified callback function (or continuation) instead of returning
its value directly. So our `s -> a` becomes:

```haskell
fn :: (a -> r) -> s -> r
```

After we're done computing an `a` from the `s` we were given, we throw
it to the continuation of type `a -> r`. We then take **that** result and
return it. I like to put parens around the second function:

```haskell
fn :: (a -> r) -> (s -> r)
```

But it's kind of hard to do anything with this, because `r` is
completely arbitrary. It's chosen by whoever calls us, so we have no
information about what can be done on an `r`. What if we instead require
that the continuation result be a Functor?

```haskell
fn :: Functor f => (a -> f r) -> (s -> f r)
```

And while we're at it, it was kind an arbitrary stipulation that the `f
r` of the continuation's callback be the same as the `f r` of our
function's result type, so let's relax that:

```haskell
fn :: Functor f => (a -> f b) -> (s -> f t)
```

This relaxation makes sense as long as we know of some function with
type `b -> t`, because then we could

- take the `s`,
- apply our `s -> a` getter to get an `a`,
- throw this to the `a -> f b` continuation to get an `f b`, and
- `fmap` our `b -> t` function over this to get an `f t`.

In general, we might not know of some `b -> t` function. But remember
that we do have our `s -> a -> s` function! So if we choose `b = a` and
`s = t`, then we get:

```haskell
fn :: Functor f => (a -> f a) -> (s -> f s)
```

With a function like this, we can

- take the `s`,
- apply our `s -> a` getter to get an `a`,
- throw our `a` to the `a -> f a` continuation to get an `f a`,
- partially apply our `s -> a -> s` setter with the `s` we were given,
  - (so we have an `a -> s` now)
- `fmap` this `a -> s` function over the `f a` to get an `f s`

And we've arrived at the type of `Lens'`! What really happened here was
we marked the interesting[^interesting] part of our data structure with
a Functor. So if we choose an interesting Functor instance, it'll act on
that point.

[^interesting]: In the same way that glass lenses focus light on a point, functional lenses focus a data structure on a point! Isn't it neat how that name works out? It's certainly a cooler name than "generalized getter/setter [wombo combo](https://www.youtube.com/watch?v=pD_imYhNoQ4)" (video, language warning).

What if the Functor we choose is `Const a`? Well, then it's on us to
provide an `a -> f a` continuation. Since we've chosen `f = Const a` we
have to come up with a function with type `a -> Const a a`. This is a
special case of the `Const` constructor:

```haskell
Const :: forall b. a -> Const a b
```

So our continuation remembers the `a` it was given. After the last step,
we'll have a `Const a s`, which we can call `getConst` on to give us
the `a` we stashed. So by choosing `Const`, our lens acts like a getter!

What if the Functor we choose is `Identity`? Now we have to provide a
function `a -> Identity a`. At this point, you probably guessed this
makes our lens a setter. If we're trying to use a setter, then we'll
also have access to some new `y :: a` that we want to use to slot into
our `s`. Let's see what happens if we make this our continuation:

```haskell
inj :: a -> Identity a
inj x = Identity y
```

The `x :: a` is the old value of `x`. By dropping `x` on the floor and
returning `y` instead, we've slotted `y` into our `s`. Remember
that above we took the `f a` and our setter `s -> a -> s`, partially
applied it to get `a -> s`, and `fmap`'d this over the `f a`. Since our
continuation now holds a wrapped up `y :: a`, we'll reconstruct a new
`s` using `y`. Great!


## More Resources

These are some resources that helped make lenses less intimidating for
me:

- [Lenses, Folds, and
  Traversals](https://www.youtube.com/watch?v=cefnmjtAolY) (video)
  - by Edward Kmett, the author of the lens library
  - highly technical, long, exhaustive
- [Control.Lens.Getter](https://hackage.haskell.org/package/lens-4.16/docs/Control-Lens-Getter.html) (hackage)
  - in particular, the first few lines of the intro paragraph
  - also: `(^.)` to see where the `f` becomes `Const a`
- `#haskell` on Freenode
  - Special thanks to `johnw_` and `dminuoso`!

Lenses seem intimidating at first, but in the end they're just a really
cool uses of functions. We use nothing more exotic here than the Functor
type class and a couple of Functor instances, and in return we get such
concise code!

<!-- vim:tw=72
-->
