---
layout: post
title: "Variables and Binding"
date: 2017-10-28 19:04:01 -0700
comments: false
share: false
categories: ['plt']
description: >
  Nearly every interesting programming language feature derives its
  power from variables. Functions wouldn't be functions if not for
  variables. Modularity and linking reduce to variables and
  substitution. I've written in the past about all sorts of cool
  variables in types, as well as how parametric polymorphism in System F
  is the result of using type variables in two ways within the same
  system.
strong_keywords: true
mathjax: true
---

Variables are central to programming languages, yet they're often
overlooked. Academic PL theory papers usually take for granted having
proper implementations of variables. Most popular languages butcher
variables, [confusing them with assignables][words-matter]. Despite
being taken for granted, implementing substitution on variables is easy
to get wrong.

[^central]: Nearly every interesting programming language feature derives its power from variables. Functions wouldn't be functions if not for variables. Modularity and linking reduce to variables and substitution. I've written in the past about all sorts of cool [variables in types](/variables-in-types), as well as how [parametric polymorphism in System F](/system-f-param) is the result of using type variables in two ways within the same system.

<!-- more -->

There are a number of different solutions for handling variables and
binding within a programming language implementation. We'll take a look
at these three:

- explicit variables,
- de Bruijn indices, and
- locally nameless terms

Before we get to solutions, we need to outline the problem. Implementing
variables and binding reduces to implementing substitution (because
variables are giving meaning by substitution!), and the trickiest part of
substitution is variable capture.


## Variable Capture

The most common way to get variables and binding wrong is to
accidentally let variables be *captured* during substitution. Consider
this example:

```python
                      ◀────────────────┐
                             ┌──────┐  │
                       (λx. λy. x + y) y
                         └──────┘
```

There are two distinct `y` variables here:

- one which refers to the variable bound by the nested lambda
- one which refers to some `y` in the surrounding scope

For this example, let's say we choose to represent variables as string
identifiers. If we step the function application, it steps to a
substitution of `y` for `x`:

```python
  (λx. λy. x + y) y
  # Apply the function, giving us:
→ [y / x] (λy. x + y)
  # Traverse under the lambda:
→ λy. [y / x] (x + y)
  # Distribute:
→ λy. ([y / x] x) + ([y / x] y)
  # Substitute y where we found an x:
→ λy. y + y
```

__Note__: `[e₁ / x] e₂` is read as "substitute `e₁` for `x` in `e₂`."

We started with a function which would take two numbers and sum them.
After partially applying that function, we've ended up with a function
that doubles it's argument. Whoops! We can look at the issue visually in
this diagram:

```python
           ◀─────┐             ┃         ┌──┐
             λy. y + y         ┃        λy. y + y
              └──────┘         ┃         └──────┘
```

We were expecting to get out the binding structure on the left, but
instead we got the binding structure on the right. This is called
"variable capture" or just **capture** for short. The `y` that we
applied to the summing function was captured by the binding site of the
nested lambda.


## Explicit Variables

When we're implementing substitution (whether for terms, for types, or
for any other sort of syntax), our primary goal is to implement
**capture-avoiding substitution**. There are many internal
representations we can pick from to achieve this. The strategy above
where variables were simple strings is called **explicit variables**.

Explicit variables are nice because we can represent them directly with
an algebraic data type. For example, for the lambda calculus we might
have this:

```sml
datatype term
  = Var of string
  | Lam of ident * term
  | App of term * term
```

Implementing capture-avoiding substitution using this representation
isn't pleasant, but it is possible. It uses the observation that there's
no difference between, say `λx. x` and `λy. y`. Our choice of variable
names doesn't matter---they're both the identity function.

Being able to rename bound variables at will is called **α-varying**,
and when two terms can be made identical by just α-varying them,
we say they're **α-equivalent**.

It only makes sense to α-vary bound variables, not free variables. If we
have two functions like `λx. x + y` and `λx. x + z`, we can't safely
α-vary `y` to `z`, because we have no way of knowing whether `y` and `z`
are the same! Their same-ness depends on the context.

We can implement capture-avoiding substution for the explicit variable
representation by α-varying whenever we detect that a variable might be
captured. To revisit our example from earlier:

```python
  (λx. λy. x + y) y
→ [y / x] (λy. x + y)
  # our free 'y' will get captured by going under
  # this λ, so let's α-vary the bound 'y' to 'z':
→ [y / x] (λz. x + z)
→ λz. [y / x] (x + z)
→ λz. x + z
```

The trick here is that by picking `z` we picked a name that doesn't
collide with any of the free variables with in `λy. x + y`. Namely,
we're glad we didn't α-vary `y` to `x`! To ensure this, our
implementation can either

- calculate the set of free variables used in a subexpression and make
  sure not to use one of those, or
- just generate a globally unique name by incrementing a global
  counter, giving us names like `x1`, `x2`, `x3`, etc.

On the surface, explicit variables look rather naïve, and maybe they
are. However, they work perfectly if you don't need substitution in the
first place! For example, a compiler never needs to substitute a term
for a variable in another term because compilers don't evaluate code:
they translate one intermediate language into another.

On the other hand, interpreters use term substitution heavily, and even
compilers need to substitute types for variables in other types and in
terms. We'll now look at some better solutions for implementing
capture-avoiding substitution.


## De Bruijn Indices

With explicit variables, we had to keep track of names in use and check
whether to α-vary before a collision happened. The next representation
we'll look at sidesteps this problem by not giving name to variables at
all! Let's take a look at our picture from before:

```python
                             ┌──────┐
                        λx. λy. x + y
                         └──────┘
```

In this picture, the only thing that's really important to us is the
binding structure; we don't actually care that `x` is called `x`, we
just care that applying this function sticks the argument everywhere the
line on the bottom points to. We could omit the names entirely, as long
as we can still capture where the lines should connect to:

```python
                            ┌─────┐
                       (λ. λ. ◆ + ◆)
                         └────┘
```

One way of doing this is just to count how many bindings sites up you
have to go before you arrive at the location the variable is bound.
Under this representation, variables are just indices into a list of the
binding sites; we call these indices **de Bruijn indices**:

```python
                       (λ. λ. ① + ⓪)
```

**Note**: I'm using circled numbers like `⓪` for the variable with de
Bruijn index `0`.

Under this representation, a de Bruijn index of 1 means "skip over one
lambda" and an index of 0 means "skip over zero lambdas" or simply "go
to the closest lambda." In code, de Bruijn terms can be represented
with this datatype:

```sml
datatype term
  = Var of int
  | Lam of term
  | App of term * term
```

`Var` now takes an `int` instead of a `string`. `Lam` only takes the
body of the lambda: to refer to argument of a lambda function, count
back the appropriate number of `Lam`s to skip over.

Now that all variables are represented by indices, it's much easier to
know which variables are free and which are bound: a variable is free if
its index is larger than the number of lambdas it's under.

```python
                      ◀───────────────┐
                            ┌──────┐  │
                       (λ. λ. ① + ⓪) ③
                         └────┘
```

The second `③` is free because it's under zero lambdas. Put another way,
if we were keeping a list of the binding sites we'd traverse under to
reach `③` our list would be empty, so accessing index 3 would be out of
bounds.

With this representation, capture avoiding substitution becomes much
more manageable.

```python
  (λ. λ. ① + ⓪) ③
→ [③ / ⓪] (λ. ① + ⓪)
# We increment free variables as we descend under binders
→ λ. [④ / ①] (① + ⓪)
→ λ. ([④ / ①] ①) + ([④ / ①] ⓪)
→ λ. ④ + ⓪
```

Note how the `③` changed to a `④`: its new location in the program lies
under one extra lambda than before. Thus to refer to the same position
as at the start of the substitution, we increment to record that we'll
have to skip over one extra lambda. This process of adding one when
going under a binder is called **lifting** (or sometimes, **shifting**).

Lifting takes the guesswork out of implementing substitution. As a
bonus, we've actually forced α-equivalent terms to have identical
structure! Checking for α-equivalence now is a straightforward tree
traversal: we check that both nodes are simply pairwise equal, then that
their children are α-equivalent.


## de Bruijn Indices and Lifting

On the other hand, working with de Bruijn indices can still be tricky.
It's easy enough to remember to lift variables when substituting, but
more generally, you have to remember to lift *whenever* you put a free
variable into a context different from where it was defined. This can
get really hairy; spotting when a usage context diverges from a
definition context is often learned the hard way! Namely, by forgetting
to lift somewhere, pouring over the code and the types for hours, then
finally spotting the mistake.[^biased]

[^biased]: If it wasn't clear, this has happened to me many times, and yes I'm still getting over it 😓

To make this a little more concrete, I'll use a specific example. It
comes from the judgement for deciding whether two type constructors are
equivalent in System F<sub>ω</sub>. Focus on the variables and contexts
in use (don't pay too much attention to what the judgement actually is):

$$
\frac{
\Gamma, \alpha :: \kappa_1 \; \vdash \; c \, \alpha \iff c' \, \alpha :: \kappa_2
}{
\Gamma \; \vdash \; c \iff c' :: \kappa_1 \to \kappa_2
}
$$

In words, "to check whether type constructors `c` and `c'` are
equivalent, assume that `α` is a type constructor of kind `κ₁`, then
apply `α` to `c` and `c'` and see if you get the same result in both
cases." Though again, understanding this judgement is beside the point.

The real tricky part here is obscured by the fact that we're
representing variables with names instead of de Bruijn indices. If we
were to take a naive pass at translating  this rule to use de Bruijn
indices, we might end up with:

$$
\frac{
\Gamma, \kappa_1 \; \vdash \; c \, ⓪ \iff c' \, ⓪ :: \kappa_2
}{
\Gamma \; \vdash \; c \iff c' :: \kappa_1 \to \kappa_2
}
$$

Note how `Γ` became a stack instead of a map because we're mapping
*indices* to kinds (instead of string keys to kinds). The element we
just pushed on (`κ₁`) is on the top of the stack at index `0`, and
everything else in the context can now be found at `index + 1`. That
means that above the line, `⓪` refers to the `κ₁` in the context.

But `⓪)` might *also* be in use at the top level of `c` or `c'`! In
either of these terms, `⓪` at the top level is a free variable referring
to the first thing in `Γ`. The problem is that the first thing in `Γ,
κ₁` is not the first thing in `Γ`! To preserve the correct binding
structure, we'd have to go through `c` and `c'`, lifting all free
variables by one to reflect the fact that we just injected something
into the surrounding context:

$$
\frac{
\Gamma, \kappa_1 \; \vdash \; (c \uparrow) \, ⓪ \iff (c' \uparrow) \, ⓪ :: \kappa_2
}{
\Gamma \; \vdash \; c \iff c' :: \kappa_1 \to \kappa_2
}
$$

In this rule, `↑` is the lifting operator, which traverses through a
term's free variables and increments them. After it's run, there will be
no free variables in `c` or `c'` with index 0, which gives us room to
use `⓪` for our own purposes.

In some sense, this is the opposite problem that we had when we used
explicit variables. For that, we had to go through and rename *bound
variables* so that nothing clashed. Now, we have to lift *free
variables* so that nothing clashes. Put another way, explicit variables
excel at dealing with free variables, while de Bruijn indices excel at
representing bound variables.

The next representation we'll look at, locally nameless terms,
effectively steals the best of each, combining them into one
representation.

## Locally Nameless Terms

We identified that de Bruijn indices represent bound variables well at
the expense of free variables. **Locally nameless terms** solve this by
giving free variables explicit names, but using indices instead of names
for bound (or "local") variables, thus the name[^globally-nameless].

[^globally-nameless]: We could, by analogy, refer to the de Bruijn index representation as the globally nameless representation, which is more descriptive but isn't something you'll hear used anywhere.

Locally nameless terms might be represented by a data type like this:

```sml
datatype term
  = FV of string
  | BV of int
  | Lam of term
  | App of term * term
```

`FV` constructs a free variable, and similarly `BV` constructs a bound
variable. `FV` takes a `String`, because free variables get names, and
`BV` takes an `Int`, because bound variables are nameless de Bruijn
indices. As before, `Lam` only takes the body of the lambda function;
we'll use de Bruijn indices to count back to the appropriate binding
site of a variable.

In practice, locally nameless terms are best provided through a library,
where this internal implementation is hidden and the user interacts with
an abstract interface:

```sml
(* The actual type of a locally nameless term with *)
(* a distinction between FV and BV is hidden       *)
type term

(* termView is only one level deep: after that, *)
(* you end up with a term, which is abstract    *)
datatype termView
  = Var of string
  | Lam of string * term
  | App of term * term

(* Convert between the abstract and view types *)
val out : term -> termView
val into : termView -> term

(* Substitution and alpha equivalence work on abstract terms *)
val subst : term -> string -> term
val aeq : term -> term -> bool
```

The fresh name generation from explicit variables is handled under the
hood by `out`. Lifting is handled automatically every time we call
`into` on a `Lam`. By only implementing operations like `subst` and
`aeq` on the abstract representations, we've effectively forced the type
system to check that we lift and generate fresh names in all the right
places!


## Closing Considerations

Locally nameless terms are generally pretty great. They blend the
strengths of explicit variables and de Bruijn indices into a new
structure that makes working with variables and binding hard to get
wrong. That being said, I'd be remiss if I didn't point out two
drawbacks:

- Locally nameless terms can be slow.
  - In most code, we'll find ourselves converting between `term`s
    and `termView`s. This brings with it the overhead of the function
    call, allocating new memory for the new structures, and can even
    sometimes make a linear algorithm accidentally quadratic.
- It's more annoying to use pattern matching.
  - Most of the time we'll have things of type `term`. Since `term` is
    abstract, we can't pattern match on it directly; we have to instead
    call `out` and pattern match the result.

Despite these drawbacks, I still prefer locally nameless terms.

- I'll gladly trade correctness for performance, and it's definitely
  easier to be correct when working with locally nameless terms. We can
  always optimize for performance later by profiling the code to find
  the slowness!
- Calling `out` in a few places is a small ergonomic price to pay for
  correctness. When you forget to call `out` or `into`, the type checker
  will remind you. There are also some cool language extensions which
  can make calling `out` and `in` syntactically more pleasant, like
  [View Patterns] in Haskell.

Variables show up in the most interesting places, and I always smile
when I find them being used in new and surprising ways. On the flip
side, languages that implement variables and binding suffer no end of
trouble and programmers are forced to cope with their absence.[^trouble]

I think variables are just so cool!

[^trouble]: It's for this very reason that variables are the first topic we cover in 15-312 Principles of Programming Languages.


[variables-in-types]: /variables-in-types/
[system-f]: /system-f-param/
[words-matter]: https://existentialtype.wordpress.com/2012/02/01/words-matter/
[View Patterns]: https://ocharles.org.uk/blog/posts/2014-12-02-view-patterns.html

<!-- vim:tw=72
-->
