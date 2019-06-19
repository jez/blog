---
layout: post
title: "On Programming Language Choice"
date: 2019-06-21 20:39:25 -0700
comments: false
share: false
categories: ['programming']
description: "Absolutely the most regret from choosing a programming language has come from forgetting to ask this question:"
strong_keywords: false
---

My opinion on programming language choice has changed over the years,
from "Java is the only language I know" to "Standard ML is clearly the
right answer" to something a little more nuanced now. Still, since this
post is largely my **opinion**, I withold the right to make claims
without evidence and say things you'll disagree with. But enough
qualifiers—let's get into it.

<!-- more -->

Earlier in my career, I thought that the answer to "which language
should I use" ought to be constant. That there should be One Best
Language. And while I still think it makes sense to compare languages on
the relative merits of their designs, answering the question "which
language is **best** designed" is a completely different question. The
question I'll answer in this post is: "Which language should I choose to
start this new project?"[^new-project]

[^new-project]: Fundamentally, I believe language choice **only** applies to new projects. Given an existing project, the question is not "which language" but instead "should we rewrite," to which the answer is overwhelmingly **no**. But that's a topic for another post.

Answering "which language is best designed" is better left to
programming language theorists. To claim that I (or most people reading
this) have any authority to answer this question is absurd. Language
design is a well-studied, complex problem, with a wealth of
peer-reviewed, prior work. One semester studying programming language
theory in college is not sufficient qualification to answer this
question.

As it turns out, most people trying to answer the former question of
"which language is best designed" knowingly or unknowingly end up
answering the latter question: "which language should I choose to start
this new project?" Luckily, this is a much easier question to answer,
because we can narrow the choice space by asking questions like these:

- What languages does the initial team know?
- What languages will future collaborators know?
- What languages have strong package ecosystems? (Especially for our
  domain?)
- What performance properties must our solution have?

But there's one big question missing, and it 100% overshadows all other
questions. Absolutely the most regret from choosing a programming
language has come from forgetting to ask this question:

**In this language, how easy is it to delete code?**

Code is a liability. More code means more to understand and more systems
to maintain. More moving parts means more points of failure. More
failures mean more people trying to fix old code with new code. Company
pressures to ship more features mean new code accumulating on top of old
code.

This is a nightmare.

Code is a liability, so regardless of language it must be trivial to
delete. And this means our language must be easy to statically analyze
(ideally, though not necessarily, a language with a type system). Static
analysis means that **when** I delete code, I can know whether other
code relied on it. Renaming a function, relocating files, deleting
unused features—I choose languages that make these operations easy.

As a quick aside, I'd like to elaborate on what I mean by "not
necessarily" a type system. Take for example the case of JavaScript's
`package.json` files (specified with JSON) versus Ruby's `Gemfile`s
(specified with Ruby code). Neither of these configuration files are
"typed" in the traditional sense, but that does not mean they're
statically unanalyzable:

- `package.json` files can be (and frequently are) parsed and analyzed
  in any language with a JSON parser. It's easy to check that all
  required keys are passed, that custom config for some specific package
  has been set up correctly, etc.

- On the other hand, `Gemfile`s can only be analyzed from Ruby and even
  then only by actually running the code. `Gemfile`s can even have
  different behavior based on the environment—only a simple `ENV[...]`
  access away—so even running the code might not be enough to completely
  analyze it.

My point is that even though JSON is untyped[^untyped] it's still
statically analyzable, which is better than nothing.

[^untyped]: I'm aware that it's possible to use schemas and specs to approximate types for JSON, but this only goes to strengthen my argument: those make it **even easier** to statically analyze JSON.

Going back to the case where the language **does** use a type system to
achieve static analysis, the set of features we get expnads from "safely
delete code" to loads of other things:

- Types serve as machine-checked documentation.
- Jump-to-def powered by a type system is fast and accurate.
- Types power trustworthy autocompletion results, so people can rely on them.
- ...

The full list is of course longer, but I want to re-iterate: choosing a
typed language is for me a downstream consequence of choosing a language
where it's trivial to delete code.

Until now I've relied on an implicit assumption that only via static
analysis or type checking can we easily reason about how to delete code.
The alternative might be to use some sort of dynamic analysis, like
running tests, rolling out refactors behind feature flags, or using some
sort of manual QA checklist.

And while these techniques are still valuable, on their own they're a
poor substitute for static analysis. Why? First: they're opt in.
Programmers have to remember to write tests and to choose to use feature
flags. Static analysis on the other hand is opt out. Having chosen a
language with static analysis from the beginning, it applies everywhere.
This also means if we choose a language we're not satisfied with, it's
easier to change our mind in the future.

Second: they over-index on the quality of the data they're fed. An
example of "poor data quality" might be excessive use of mocks and stubs
in tests. I've seen all too many test suites that overuse mocking and
stubbing to the point where they're really just testing the testing
framework.

Another common dynamic analysis technique we use where I work is adding
"soft assertions" which we define as an assertion that raises an
exception if it fails in tests, but logs to Sentry in production. Before
deleting the core code, we'll preface all calls to it with unconditional
soft assertions, and merge to production to see whether any assertions
fire. Our confidence is directly tied to how well the production data
collected in that time represents all production data.

How long spent waiting for no soft assertions is enough to get a
representative sample? A day? A week? What if we have behavior that only
executes on the first of the month? Or code paths that customers only
hit when they're computing quarterly accounting statements? Or yearly
when they're doing taxes? A week of data collected after changing tax
code might as well be useless if that week wasn't in March or April.

For these two reasons, dynamic analysis fails us when we need it the
most: when we're trying to delete the code that's untested, uncommonly
run, and yet critically important. With only dynamic analysis, the code
that we understand the least is also the code that's the hardest to
remove.

So here's my unsubstantiated claim: dynamic analysis techniques
(anything that involves running the code) are too weak to empower people
to delete code. If we want to delete code, and we do because code is a
liability, we want static analysis.[^correctness]

[^correctness]: At this point you might think that I don't believe in dynamic analysis techniques at all. That's not the case, as [I've written before](/tests-types-correctness/) about how I value them. I'm only saying that relying on running the code to check if code can be deleted safely does not work. Tests are still useful for plenty of other things.

The next thing to point out is that not all forms of static analysis are
created equal. Arguably Haskell's static analysis is more powerful than
C's. While I'll acknowledge that some languages give **more** static
guarantees than others, as long as a language can at least reason about
code that's been mistakenly deleted, I prefer to turn my attention to
other questions getting into those minutia. Comparing C and Haskell gets
back into debating language design which, again, is a bit fruitless.

After all that, here's my checklist when choosing a language to start a
new project:

1.  Rule out languages where we can't easily delete code.
2.  Narrow the remaining languages to those that fit the circumstances.
3.  Pick any language that's left, because according to step (2) they
    all fit our project's needs.

Optimizing for deleting code minimizes the biggest regret I've seen
stemming from a language choice and keeps the door open so we can change
our mind in the future. As a consequence we usually pick up extra
benefits in the process (namely those that come from a good type
system), but choosing a language to fit the circumstances trumps
attempting to debate which type system is The Best.

&nbsp;

*If you read this far and were hoping that I declare one winner in the
end, I'm sorry to disappoint. I'm happy to indulge you over lunch or
email, or you can read [the rest] of [my blog] and [guess] at what I
might say. Regardless, thanks for your time.*

[the rest]: https://blog.jez.io/categories/#bash
[my blog]: https://blog.jez.io/categories/#haskell
[guess]: https://blog.jez.io/categories/#sml

<!-- vim:tw=72:fdm=marker
-->
