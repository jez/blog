---
# {{{
layout: post
title: "On Programming Language Choice"
date: 2019-06-21 20:39:25 -0700
comments: false
share: false
categories: ['programming']
description: TODO
strong_keywords: false
# }}}
---

My opinion on programming language choice has changed over the years,
from "Java is the only language I know" to "Standard ML is clearly the
right answer" to something more modest now. This post is largely my
**opinion**. I withold the right to make claims without evidence and say
things you'll disagree with. But enough qualifiers—let's get into it.

<!-- more -->

Earlier in my career, I thought that the answer to "which language
should I use?" should be constant. That there should be One Best
Language. And while I still think it makes sense to compare language
designs on their relative merits, answering the question "which language
is **best** designed?" is a completely different question. Put another
way, the question I'd like to answer is: "Which language should I choose
to start this new project?"[^new-project]

[^new-project]: Fundamentally, I believe language choice **only** applies to new projects. Given an existing project, the question is not "which language" but instead "should we rewrite," to which the answer is overwhelmingly **no**. But that's a topic for another post.

The question "which language is best designed" is a question left to
programming language theorists. To claim that I (or in fact most people
reading this) have any authority to answer this question is absurd.
Language design is a well-studied, complex problem, with a wealth of
peer-reviewed, prior work. One semester studying programming language
theory in college is not sufficient qualification to answer this
question.

But as it turns out, most people trying to answer "which language is
best designed" knowingly or unknowingly end up answering the latter
question: "which language should I choose to start this new project?"
Luckily, this is a much easier question to answer! Questions like these
unocver the specifics of the project, narrowing the choice space:

- What languages does the initial team know?
- What languages will future collaborators know?
- What languages have strong package ecosystems? (Especially for our
  domain?)
- What performance properties must our solution have?

There are other questions like:

- On what time scale must we deliver results?
- How many people will be working on the project?
- How large will the project likely become?

But in my experience, these last few questions don't actually narrow the
set as much as the former questions. But there's one big question
missing so far, and it 100% overshadows all other questions. Absolutely
the most regret stemming from programming language choice has come from
forgetting to ask this question:

**In this language, how easy is it to delete code?**

Code is a liability. More code means more to understand, more systems to
maintain. More moving parts means more points of failure. More bugs mean
more people trying to fix old code with new code. Company pressures to
ship more features mean more code accumulating on top of the old code.

This is a nightmare.

So in whatever language I chose it must be trivial to delete code, and
for me that means it must be easy to statically analyze, specifically
(though not necessarily[^analysis]) a language with a type system.
Static analysis means that **when** I delete code, I can know whether
other code relied on it. Renaming a function, relocating files, deleting
unused features—these are the features I select a language for.

As a quick aside, I'd like to elaborate what I mean by "not necessarily"
a type system. Take for example the case of JavaScript's `package.json`
files (specified with JSON) versus Ruby's `Gemfile`s (specified with
Ruby code). Neither of these configuration files are "typed" in the
traditional sense, but that does not mean they're statically
unanalyzable. `package.json` files can be parsed and analyzed in any
language with a JSON parser. But `Gemfile`s can only be analyzed *from
Ruby* and even then only by *actually running the code*.

But in the case where the language does use a type system to achieve
static analysis, the set of features we get expnads from "safely delete
code" to loads of other things:

- types are machine checked documentation
- types let me navigate code faster via jump to definition
- types let me understand confusing code by hovering my cursor to see a
  function's docs
- ...

This list is of course longer, but I want to re-iterate: having chosen a
typed language was a downstream consequence of having chosen a language
where it's trivial to delete code.

Until now there's been an implicit assumption that only via static
analysis or type checking can we easily reason about how to delete code.
The alternative might be to use some sort of dynamic analysis, like
running tests, rolling out refactors behind feature flags, or use some
sort of manual QA checklist.

And while these techniques are very valuable, on their own they're a
poor substitute for static analysis. Why? Because they're opt in.
Programmers have to remember to write tests and to choose to use feature
flags. Static analysis on the other hand is opt out. Having chosen a
language with static analysis from the beginning, it applies everywhere.

And because of this, dynamic analysis fails us when we need it the most:
when we're trying to delete the code that's untested, the code that
everyone has long forgotten about. This is the code that we want the
least, but with only dynamic analysis, it's the hardest to remove, so it
sits and festers in the corners of our codebases.

So here's my unsubstantiated claim: dynamic analysis techniques
(anything that involves running the code) is not powerful enough to
empower people to delete code. If we want to delete code (and we do
because code is a liability), we want static analysis.

The next thing to point out is that not all forms of static analysis are
created equal. Arguably Haskell's static analysis is more powerful than
C's. And while I'll acknowledge that some languages give **more** static
guarantees than others, as long as it can at least reason about code
that's been mistakenly deleted, I like to consider the other questions I
posed in this article before getting into those minutia. Comparing C and
Haskell gets back into comparing language design, which I mentioned
before is a bit of a fruitless debate.

So here's my checklist when choosing a language to start a new project:

1.  Rule out languages where we can't easily delete code.
2.  Then, ask questions like "what is the team familiar with" and "what
    ecosystem do we want."
3.  If there are still too many choices then they're probably all fine,
    so just pick one.

I'm happy to debate which language is the best over lunch with you, but
that's largely an unrelated discussion from which language to choose
when starting a new project.

<!-- vim:tw=72:fdm=marker
-->
