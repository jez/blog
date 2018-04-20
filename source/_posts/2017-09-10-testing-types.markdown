---
layout: post
title: "Testing, Types, & Correctness"
date: 2017-09-10 16:50:36 -0700
comments: false
share: false
categories: ['programming', 'fragment', 'types']
description: >
  It's important to both have strong testing practices and languages
  with disciplined type systems. The hardest part of writing quality
  software is ensuring that it runs without bugs. This is why testing
  and type systems are complementary---they're distinct tools to help us
  write better code.
strong_keywords: false
---

Understanding correctness of code really comes down to *proving* that
the code does the right thing. What tools do we have as programmers for
proving the correctness of our code?

<!-- more -->

1. **Unit tests** prove that the code is correct for specific inputs.
1. **Type systems** prove the absence of (certain kinds of)
   incorrectness.
1. **Theorem provers** prove sophisticated claims about our code for
   us.
1. **Program authors** can prove the correctness of their code (i.e.,
   with a traditional pen-and-paper proof).

The first three are exciting because they involve a computer doing most
of the work for us! That said, none of the first three are as
universally applicable as the last: doing the proof ourself.
Unfortunately, it's also usually the most toilsome.

Note the double negation in (2). Type systems themselves don't prove
correctness, they prove that there aren't certain kinds of
incorrectness, namely: type errors. Meanwhile, unit tests are rarely (if
ever) exhaustive. This is why testing and type systems are
complementary---one is not a substitute for the other.

It's important to both have strong testing practices and languages with
disciplined type systems. The hardest part of writing quality software
is ensuring that it runs without bugs. The more tools we have in our
arsenal to combat incorrectness, the easier it is to write code for the
long term.

<!-- vim:tw=72
-->
