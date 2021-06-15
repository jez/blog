---
layout: post
title: "ABTs in Haskell"
date: 2017-11-11 22:31:41 -0800
comments: false
share: false
categories: ['plt', 'haskell', 'fragment']
description: >
  I've been learning and using Haskell on-and-off for the past couple
  of years. One of my early complaints was that I couldn't find a good
  library for working with variables and binding that used locally
  nameless terms. Recently though, I found unbound-generics, which
  checks all my previously unfilled boxes.
strong_keywords: false
fancy_blockquotes: true
---

I've been learning and using Haskell on-and-off for the past couple
of years. One of my early complaints was that I couldn't find a good
library for working with variables and binding that used locally
nameless terms. Recently though, I found [`unbound-generics`], which
checks all my previously unfilled boxes.

Abstract binding trees (or ABTs) are abstract syntax trees (ASTs)
augmented with the ability to capture the binding structure of a
program. ABTs are one of the first topics we cover in [15-312 Principles
of Programming Languages][ppl] because variables show up in every
interesting feature of a programming language.

[ppl]: https://www.cs.cmu.edu/~rwh/courses/ppl/

I recently wrote at length about the various strategies for dealing with
[variables and binding] and their implementations. While it's a good
exercise[^ppl-hw1] to implement ABTs from scratch, in most cases I'd
rather just use a library. In school we used [`abbot`], which is an ABT
library for Standard ML. For tinkering with Haskell, I recently found
[`unbound-generics`], which provides a similar API.

[^ppl-hw1]: In fact, it's hw1 for 15-312! If you're curious, check out the [handout](https://www.cs.cmu.edu/~rwh/courses/ppl/hws/assn1.pdf).

[variables and binding]: /variables-and-binding/
[`abbot`]: https://github.com/robsimmons/abbot

I gave it a test drive while learning how to implement type inference
for the simply-typed lambda calculus (STLC) and was rather pleased. The
source code for my STLC inference program is [on GitHub][stlc-infer] if
you're looking for an example of [`unbound-generics`] in action.

To pluck a few snippets out, here's the definition of STLC terms:

```haskell
data Term
  = Tvar Tvar
  | Tlam (Bind Tvar Term)
  | Tapp Term Term
  | Tlet Term (Bind Tvar Term)
  | Tz
  | Ts Term
  | Tifz Term Term (Bind Tvar Term)
  | Tbool Bool
  | Tif Term Term Term
  deriving (Show, Generic, Typeable)
```

`Bind` is the abstract type for locally nameless terms that bind a
variable. It's cool in Haskell (compared to SML) because the compiler
can automatically derive the locally nameless representation from this
data type definition (with help from the `unbound-generics` library).

Here's what it looks like in use:

```haskell
-- (This is a snippet from the type inference code)
constraintsWithCon ctx (Tlam bnd) = do
  -- 'out' the ABT to get a fresh variable
  -- (x used to be "locally nameless", but now has a globally unique name)
  (x, e) <- unbind bnd
  -- Generate fresh type variable to put into the context
  t1 <- Cvar <$> fresh (string2name "t1_")
  let ctx' = Map.insert x t1 ctx
  t2 <- constraintsWithCon ctx' e
  return $ Carrow t1 t2
```

Apart from `out` being called `unbind` and `into` being called `bind`,
the API is pretty similar. Also, unlike `abbot`, which required a
standalone build step to generate SML code, `unbound-generics` uses the
Haskell's `derive Generic` to bake the code generation for capture
avoiding substitution and alpha equivalence right into the compiler. All
in all, `unbound-generics` is really pleasant to use!

[`unbound-generics`]: https://github.com/lambdageek/unbound-generics
[stlc-infer]: https://github.com/jez/stlc-infer

<!-- vim:tw=72
-->
