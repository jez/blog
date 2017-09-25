---
layout: post
title: System Fω and Parameterization
date: 2017-09-27 19:14:45 -0700
comments: false
share: false
categories: ['recitation', 'sml', 'plt']
description: >
  Some recitation-style notes on System F, polymorphism, and functions.
  I used to not know the difference between ∀(t.τ) and λ(u.c). Turns
  out, there's a huge difference!
strong_keywords: false
mathjax: true
---

My understanding of System F<sub>ω</sub> used to be really shaky. In
particular, I'd been confused about the difference between `∀(t.τ)`
(forall types) and `λ(u.c)` (type abstractions) for a long time. Both of
these constructs have to do with parameterization (factoring out a
variable so that it's bound), but each has a drastically different
meaning.

<!-- more -->

## Questions

We'll start off with some questions to keep in mind throughout these
notes. Our goals by the end are to understand what the questions are
asking, and have at least a partial---if not complete---answer to each.

First, consider this code.

```sml
datatype 'a list = Nil | Cons of 'a * 'a list
```

- What really is "`list`" in this code?
- Or put another way, how would we define `list` in System
  F<sub>ω</sub>?

Thinking more broadly,

- What separates `∀(t.τ)` and `λ(u.c)`?
- What is parameterization, and how does it relate to these things?


## System F<sub>ω</sub>

The answers to most of these questions rely on a solid definition of
System F<sub>ω</sub>. We'll be using this setup.

```
Kind κ ::= * | κ → κ | ···

           abstract       concrete      arity/valence
Con c  ::= ···
         | arr(c₁; c₂)    c₁ → c₂       (Con, Con)Con
         | all{κ}(u.c)    ∀(u ∷ κ). c   (Kind, Con.Con)Con
         | lam{κ}(u.c)    λ(u ∷ κ). c   (Kind, Con.Con)Con
         | app(c₁; c₂)    c₁(c₂)        (Con, Con)Con
```

Some points to note:

- `∀(u ∷ κ). c` and `λ(u ∷ κ). c` have the same arity.
- `∀(u ∷ κ). c` and `λ(u ∷ κ). c` both *bind* a constructor variable.
  This makes these two operators *parametric*.
- Only `λ(u ∷ κ). c` has a matching elim form: `c₁(c₂)`.
  (There are no elim forms for `c₁ → c₂` and `∀(u ∷ κ). c`, because they
  construct types of kind `*`. This will be important later.)

It'll also be important to have these two inference rules for kinding:

$$
\frac{
  \Delta, u :: \kappa \vdash c :: *
}{
  \Delta \vdash \forall(u :: \kappa). \, c :: *
}\;(\texttt{forall-kind})
$$
$$
\frac{
  \Delta, u :: \kappa \vdash c :: \kappa'
}{
  \Delta \vdash \lambda(u :: \kappa). \, c :: \kappa \to \kappa'
}\;(\texttt{lambda-kind})
$$


## Defining the `list` Constructor

Let's take another look at this datatype definition from above:

```sml
datatype 'a list = Nil | Cons of 'a * 'a list
```

We've [already seen][variables-in-types] how to encode the type of lists
of integers using inductive types:

[variables-in-types]: /variables-in-types/

```
intlist = μ(t. 1 + (int × t))
```

Knowing what we know about System F (the "**polymorphic** lambda
calculus"), our next question should be "how do we encode
**polymorphic** lists?" Or more specifically, which of these two
operators (`λ` or `∀`) should we pick, and why?

First, we should be more specific, because there's a difference between
`list` and `'a list`. Let's start off with defining `list` in
particular. From what we know of programming in Standard ML, we can do
things like:

```sml
type grades = int list

type key = string
type val = real
type updates = (key, val) list
```

If we look really closely, what's actually happening here is that `list`
is a type-level *function* that returns a type (and we use the `type foo
= ...` syntax to store that returned type in a variable).[^backwards]

[^backwards]: Noticing that these are functions is a bit weird because in Standard ML, the type applications are backwards. Instead of `f(x)`, it's `x f`. But this is more similar to how we actually think; in some sense, the parameters of a function are like adjectives modifying a noun---and adjectives come before the noun they describe.

Since `list` is actually a function from types to types, it must have
an arrow kind: `* → *`. Looking back at our two inference rules for
kinding, we see only one rule that lets us introduce an arrow kind: `λ(u
∷ κ). c`. On the other hand, `∀(u ∷ κ). c` must have kind `*`; it
*can't* be used to define type constructors.

Step 1: define list constructor? Check:

```
list = λ(α ∷ *). μ(t. 1 + (α × t)))
```

## Defining Polymorphic Lists

It doesn't stop with the above definition, because it's still not
*polymorphic*. In particular, we can't just go write functions on
polymorphic lists with code like this:

```sml
fun foo (x : list) = (* ··· *)
```

We can't say `x : list` because all intermediate terms in a given
program have to type check as a type of kind `*`, whereas `list ∷ * →
*`. Another way of saying this: there isn't any way to introduce a value
of type `list` because there's no way to introduce values with arrow
kinds.

Meanwhile, we *can* write this:

```sml
fun foo (x : 'a list) = (* ··· *)
```

When you get down to it, this is actually kind of weird. Why is it okay
to use `'a list`? I never defined `'a` anywhere, so wouldn't that make
it an unbound variable?

It turns out that when we use type variables like this, SML
automatically binds them for us by inserting `∀`s into our code. In
particular, it implicitly infers a type like this:

```sml
val foo : forall 'a. 'a list -> ()
```

SML inserts this `forall` automatically because its type system is a bit
less polymorphic than System F<sub>ω</sub>'s, which can be thought of as
a drawback. But on the other hand, it does at least save us from typing
these `forall` annotations. For most of the other "drawbacks" we get
from not being able to write the `forall` ourself, SML makes up the
difference with modules.[^rankn]

[^rankn]: Other languages (like Haskell or PureScript) have a language feature called "Rank-N Types" which is really just a fancy way of saying "you can put the `forall a.` anywhere you want." Oftentimes, this makes it harder for the compiler to infer where the variable bindings are, so you sometimes have to use more annotations than you might if you weren't using Rank-N types.

Step 2: make polymorphic list for use in annotation? Check:

```
α list = ∀(α ∷ *). list(α)
```

## Variables & Parameterization

Tada! We've figured out how to take a list datatype from SML and encode
it in System F<sub>ω</sub>, using these two definitions:

```
  list = λ(α ∷ *). μ(t. 1 + (α × t)))
α list = ∀(α ∷ *). list(α)
```

We could end here, but there's one more interesting point. If we look
back, we started out with the `∀` and `λ` operators having the same
arity, but somewhere along the way their behaviors differed. `λ` was
used to create type constructors, while `∀` was used to introduce
polymorphism.

Where did this split come from? What distinguishes `∀` as being the
go-to type for polymorphism, while `λ` makes type constructors
(type-to-type functions)? Recall one of the earliest ideas we teach in
[15-312][ppl]:

[ppl]: http://www.cs.cmu.edu/~rwh/courses/ppl/

> ... the core idea carries over from school mathematics, namely
> that **a variable is an unknown, or a place-holder, whose meaning is
> given by substitution.**
>
> -- Harper, *Practical Foundations for Programming Languages*

Variables are given meaning by substitution, so we can look to the
appropriate substitutions to uncover the meaning and the differences
between `λ` and `∀`. Let's first look at the substitution for `λ`:

$$
\frac{
  \Delta, u :: \kappa_1 \vdash c_2 :: \kappa_2 \qquad \Delta \vdash c_1
  :: \kappa_1
}{
  \Delta \vdash (\lambda(u :: \kappa_1). \, c_2)(c_1) \equiv  [c_1/u]c_2 :: \kappa_2
}
$$

We can think of this as saying "when you apply one type to another, the
second type gets full access to the first type to construct a new type."
We notice that the substitution here is completely **internal to the
type system**.[^def-equiv]

[^def-equiv]: It's not super relevant to this discussion, but this inference rule is for the judgement defining equality of type constructors. This comes up all over the place when you're writing a compiler for SML. If this sounds interesting, definitely take 15-417 HOT Compilation!

On the other hand, the substitution for `∀` **bridges the gap** from
types to terms:

$$
\frac{
  \Delta \, \Gamma, e : \forall (u :: \kappa). \tau \qquad \Delta \vdash c :: \kappa
}{
  \Delta \, \Gamma \vdash e[c] : [c/u]\tau
}
$$
$$
\frac{
  \mbox{}
}{
  (\Lambda u. \, e)[\tau] \mapsto [\tau / u]e
}
$$

When we're type checking a polymorphic type application, we don't get to
know anything about the type parameter `u` other than its kind. But when
we're running a program and get to the evaluation of a polymorphic type
application, we substitute the concrete `τ` directly in for `u` in `e`,
which bridges the gap from the type-level to the term-level.

At the end of the day, all the interesting stuff came from using
functions (aka, something parameterized by a value) in cool ways. Isn't
that baffling? Functions are so powerful that they seem to always pop up
at the heart of the most interesting constructs. I think it's
straight-up amazing that something so simple can at the same time be
that powerful. Functions!


<!-- vim:tw=72
-->
