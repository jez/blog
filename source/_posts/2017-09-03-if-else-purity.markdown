---
layout: post
title: "If, Else, and Purity"
date: 2017-08-31T22:38:43-07:00
comments: false
share: false
categories: ['programming']
description: >
  I prefer to let the language I'm using think on my behalf as much as
  possible. Ideally, the language is rich enough that the proof of
  correctness is inherent in the code I've written. Even when I use
  looser languages, these principled languages inform the structure of
  my code.
strong_keywords: true
---

I prefer to let the language I'm using think on my behalf as much as
possible. Ideally, the language is rich enough that the proof of
correctness is inherent in the code I've written. Even when I use
looser languages, these principled languages inform the structure of my
code.

<!-- more -->

To see what I mean, let's take a look at some code:

```javascript
// Watch out! We'll improve this snippet shortly.
const getErrors = (date) => {
  let classNames = '';
  if (moment(date, 'YYYY-MM-DD', true).isValid()) {
    classNames = 'error error-date';
  }
  return classNames;
}
```

Especially when writing short functions like this one, I have these
goals in mind:

- **Correctness** should be obvious.

  Judging correctness usually comes down to exhaustiveness---especially
  for code like the above. Every case should be accounted for.

- Let's make sure it's **pure**.

  Purity is important because it makes testing and refactoring easy.
  Pure functions are also compose well with others.

- Readers should be able to follow the **intent** easily.

  Readability enables collaboration and guards the code against a
  "future me" that might not remember what's on my mind right now.

For this snippet in particular, we can actually improve along all three
axes (correctness, purity, and intent) with one easy trick:
match up the `if` with an `else`. Here's what it would look like, and
then we'll break down why such a simple technique works so well.

```javascript
// Compare this improved snippet with the one above.
const getErrors = (date) => {
  if (moment(date, 'YYYY-MM-DD', true).isValid()) {
    return 'error error-date';
  } else {
    return '';
  }
}
```


## Correctness

Understanding correctness of code really comes down to *proving* that
the code does the right thing. What tools do we have as programmers for
proving the correctness of our code?

- **Unit tests** prove that the code is correct for specific inputs.
- **Type systems** prove the absence of (certain kinds of)
  incorrectness.[^type-systems]
- **Theorem provers** prove sophisticated claims about our code for
  us.
- **Program authors** can prove the correctness of their code (i.e., with a
  traditional pen-and-paper proof).

[^type-systems]: Note the double negation here. Type systems themselves don't prove correctness, they prove that there aren't certain kinds of incorrectness, namely: type errors. Meanwhile, unit tests are rarely (if ever) exhaustive. This is why testing and type systems are complementary---one is not a substitute for the other.

The first three are exciting because they involve a computer doing most
of the work for us! That said, none of the first three are as universally
applicable as the last: doing the proof ourself. What does writing
proofs have to do with correctness of `if`s? Consider how we'd write a
proof by cases. We'd:

1. identify the cases,
1. establish that the cases are exhaustive, and finally
1. prove the claim in each case.

I use this same process to write code with cases! "Proving
the claim" is just another way of saying "returning the right value."
And better yet, we can avoid doing the second step ourselves! If we just
match every `if` with an `else`, we'll automatically know that our logic
is exhaustive. This, in turn, makes the correctness proof less toilsome.


## Purity

A cool way to understand purity is using what's known as a "modal
separation." This is a really fancy way to say that we have
**expressions** which are pure and always evaluate to a value, alongside
**commands** which are impure and are executed for their side effects.
If you've ever used Haskell, you're already familiar with this
notion---we only need `do` notation when we need to write impure (or
"monadic") code.

In an expression language, every `if` *must* have an `else`; for the
entire `if` expression to be used as a value, both branches must in turn
evaluate to values. It's only when we move to a language with commands
where it makes sense to allow omitting the `else` branch.

An `if` *statement* (as opposed to an `if` expression) is a command;
it's useful for running side-effectful code. Sometimes, we don't want
one of the branches to have any side effects (for example, because the
state of the world doesn't need to be changed). Languages with commands
allow omitting the `else`.

What does this mean for us? Every pure function can be written where the
`if` is matched with an `else`. Put another way, an unmatched `if` is a
likely indicator that the code I've written is impure.

Using this indicator makes me more aware of when I'm dealing with impure
code, alerting me to handle it appropriately. For example, I might want
to factor out as much of the pure code into a separate helper function.


## Readability

Explicitly partitioning code into the `if` branch and the `else` branch
makes it easier for me to read code. Since the code has been explicitly
split in two, I can read each half by itself. When an `if` is unmatched,
this partition breaks down. The `if` branch runs into the implicit
`else` branch: that is, the rest of the function. Now I'm left reasoning
about code knowing that the condition might be `true` or `false`. And things
only get (exponentially) worse when we add in more unmatched `if`s.

Note, though, that there's a bit of a balance when it comes to
readability. Sometimes matching every `if` leads to deeply nested code.
In these cases, it might be better to flatten the nesting to a chain of
unmatched `if`s that return early if there's an error. Even still, this
moves the function from expression-dominated to command-dominated, so
the usual caveat still applies: maybe we want to factor the pure part
out into a separate function.

Making code readable is important for sharing it and collaborating with
others. Matching `if`s with `else`s let me write more readable,
understandable code.


## Writing Clean Code

Writing clean code is as much about the small details as it is about the
large, sweeping brush strokes. There's so much nuance in every
`if-then-else`:

- They're more likely to be **pure**.
- It's easier to reason about their **correctness**.
- We can dissect their **intent** piece-by-piece

And we can get all these benefits for free! We lose nearly nothing for
giving up unmatched `if`s. Even though I was writing these examples with
JavaScript, we improve our code by considering how we'd write it in a
more principled language.

<!-- vim:tw=72
-->
