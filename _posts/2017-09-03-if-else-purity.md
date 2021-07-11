---
layout: post
title: "If, Else, & Purity"
date: 2017-08-31T22:38:43-07:00
comments: false
share: false
categories: ['programming', 'fragment', 'types']
description: >
  I prefer to let the language I'm using think on my behalf as much as
  possible. Ideally, the language is rich enough that the proof of
  correctness is inherent in the code I've written. Even when I use
  looser languages, these principled languages inform the structure of
  my code.
---

I prefer to let the language I'm using think on my behalf as much as
possible. Ideally, the language is rich enough that the proof of
correctness is inherent in the code I've written. Even when I use
looser languages, these principled languages inform the structure of my
code. To make this a bit more let's turn our focus to `if`, `else`, and
purity.

<!-- more -->

A cool way to understand purity is using what's known as a "modal
separation." This is a really fancy way to say that we have
[**expressions**]{.smallcaps} which are pure and always evaluate to a
value, alongside [**commands**]{.smallcaps} which are impure and are
executed for their side effects.  If you've ever used Haskell, you're
already familiar with this notion---we only need `do` notation when we
need to write impure (or "monadic") code.

In an expression language, every `if` **must** have an `else`; for the
entire `if` expression to be used as a value, both branches must in turn
evaluate to values. It's only when we move to a language with commands
where it makes sense to allow omitting the `else` branch. `if`
expressions are not some abstract concept; chances are you've
encountered them under the name "the ternary operator."

An `if` **statement** (as opposed to an `if` expression) is a command;
it's useful for running side-effectful code. Sometimes, we don't want
one of the branches to have any side effects (for example, because the
state of the world doesn't need to be changed). Languages with commands
allow omitting the `else`.

What does this mean for us? Since expression languages form the basis
for purity, every pure function can be written where the `if` is matched
with an `else`. Put another way, an unmatched `if` is a likely indicator
that the code I've written is impure.

This makes me more aware of when I'm dealing with impure code. For
example, I might want to factor out as much of the pure code into a
separate helper function. There's a time and a place for impure code.
But since pure code is more composable and easier to test, it's best to
factor the impure code out whenever possible.

In a principled language, there's a distinction between `if` expressions
and `if` statements. On the other hand, some language only have one, or
they blur the line between the two. We can draw upon our experiences
with languages that are rigorous about minutia like this to better
inform how we write clean code.

<!-- vim:tw=72
-->
