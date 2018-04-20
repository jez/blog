---
layout: post
title: Lenses & Composition
date: 2018-02-05 23:07:37 -0800
comments: false
share: false
categories: ['haskell', 'types', 'fragment']
description: >
  It's really cool how composition works with lenses!
strong_keywords: false
---

<p></p>

A lens is really just a function `a -> b` that we represent
backwards[^backwards] and with an extra `Functor f` parameter lying
around:

```
type Lens' a b = Functor f => (b -> f b) -> (a -> f a)
```

**What does this mean for function composition?**

<!-- more -->

Normal function composition looks like this:

```haskell
(.) :: (b -> c) -> (a -> b) -> (a -> c)

f :: a -> b
g :: b -> c

g . f :: (a -> c)
```

We often have to read code that looks like this:

```haskell
g . f $ x
```

This means "start with `x`, then run `f` on it, and run `g` after that."
This sentence reads opposite from how the code reads!

What about for lenses? Here we have `f'` and `g'` which behave similarly
in some sense to `f` and `g` from before:

```haskell
f' :: Functor f => (b -> f b) -> (a -> f a)
--  ≈ a -> b
g' :: Functor f => (c -> f c) -> (b -> f b)
--  ≈ b -> c

f' . g' :: Functor f => (c -> f c) -> (a -> f a)
--       ≈ a -> c
```

In the lens world, `^.` behaves kind of like a flipped `$` that turns
lenses into getters, which lets us write code like this:

```haskell
x ^. f' . g'
```

This means "start with `x`, then get `f'` from it, then get `g'` after
that." The sentence reads just like the code!

This is pretty cool, because it means that lenses (which are
"functional" getters) read almost exactly like property access (which
are "imperative" getters). Same concise syntax, but with an elegant
semantics.

[^backwards]: I'm exaggerating a bit here 😅 To see what I *really* mean, see [this post](/lens-intuition).

<!-- vim:tw=72
-->
