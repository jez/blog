---
layout: post
title: "Notes on Continuations"
date: 2019-06-18 18:03:13 -0700
comments: false
share: false
categories: ['recitation', 'plt', 'types']
description: >
  Some recitation notes on continuations from when I was a teaching
  assistant for 15-312 at CMU.
---

These are some notes I gave out at one of my weekly recitations when I
was teaching [15-312 Principles of Programming Languages][ppl] at CMU in
April 2017. Continuations have a *fascinating* analogy with proofs by
contradiction that I might flesh out into a proper post in the future,
but for now here are some rough recitation notes.

They're best understood with Chapter 30 of [Practical Foundations for
Programming Languages][pfpl] open. (Unfortunately this chapter isn't
available in the online preview of the 2nd edition. I'm happy to lend
you my hard copy if I know you IRL.)

[ppl]: http://www.cs.cmu.edu/~rwh/courses/ppl/
[pfpl]: http://www.cs.cmu.edu/~rwh/pfpl/

→ [Continuations](/notes/continuations.pdf)

**Abstract**:

> Continuations allow for lots of things. Intuitively, we can think of
> continuations as "functions that never come back." That is,
> continuations transfer control to some other part of your program. In
> a way, continuations are like a much nicer version of `goto`. But
> they're way more than this—specifically, they reify the concept of a
> "proof by contradiction" into the type system.


<!-- vim:tw=72
-->
