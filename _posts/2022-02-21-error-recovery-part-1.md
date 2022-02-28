---
# vim:tw=90
layout: post
title: "Parse Error Recovery in Sorbet: Part 1"
date: 2022-02-21T03:56:34-05:00
description: >
  I've spent a lot of time recently making Sorbet's parser recover from syntax errors when
  parsing. I didn't have any experience with this before getting started, no one told me
  what the good tools or techniques for improving a parser were, and none of the things I
  read quite described the ideas I ended up implementing. I figured I'd share the
  experience so that you can learn too.
math: false
categories: ['sorbet', 'parsing']
subtitle: "Why Recover from Syntax Errors"
# author:
# author_url:
---

I've spent a lot of time recently making [Sorbet]'s parser recover from syntax errors when
parsing. I didn't have any experience with this before getting started, no one told me
what the good tools or techniques for improving a parser were, and none of the things I
read quite described the ideas I ended up implementing. I figured I'd share the experience
so that you can learn too.

[Sorbet]: https://sorbet.org

<!-- more -->

The original post kept growing and growing as I wrote it, so I broke it up into a handful
of parts:

- [**Part 1: Why Recover from Syntax Errors**][part1]
- [Part 2: What I Didn't Do][part2]
- (*coming soon*) Part 3: Tools and Techniques for Debugging a (Bison) Parser
- (*coming soon*) Part 4: Bison's `error` Token
- (*coming soon*) Part 5: Backtracking, aka Lexer Hacks
- (*coming soon*) Part 6: Falling Back on Indentation, aka More Lexer Hacks

[part1]: /error-recovery-part-1/
[part2]: /error-recovery-part-2/
[part3]: /error-recovery-part-3/
[part4]: /error-recovery-part-4/
[part5]: /error-recovery-part-5/
[part6]: /error-recovery-part-6/

<!-- more -->

This part is going to set the stage a bit and briefly mention why Sorbet cares so much
about syntax errors. The short answer? Editor support is everything.

There are people out there who clamor for a type checker in any codebase they work for.
They're zealous, early-adopters who evangelize types to everyone around them. They love
even just being able to run the type checker in the command line or in CI hand have it
reject code where the types don't check. Sorbet has snuck its way into many codebases this
way! But this approach always introduces friction: there's always a group of people who
see the type checker as an antagonist, sitting there and rejecting code that passes the
test suite and gets the job done.

Having a powerful editor integration drives organic adoption. A command line interface to
a type checker is only really good at reporting errors, but an editor interface exposes so
much more: inline hover lets programmers explore a code's types and documentation by
pointing. Language-aware jump-to-definition and find-all-references mean spending less
time fumbling around a code base and more time looking at the code that's relevant in the
moment. And of course autocompletion is huge. Maybe you're a curmudgeon like me who
doesn't use completion except the occasional keyword completion in Vim, but I've learned
that many, many people feel like moving back to the dark ages when they have to work in a
codebase that doesn't have fast, accurate autocompletion. Every additional editor feature
is another spoonful of sugar—once there are enough, it overwhelms any feeling that the
type checker tastes like medicine.

But if a syntax error means that the parser returns an empty parse result, all those
spoonfuls fall to the floor with a loud clang. Hover and go-to-def are serve stale
(read: imperfect) results at best, if anything. Autocomplete yields no results no matter
how long you wait for the menu to appear.

And in Sorbet's situation, it's even more severe because of how it has chosen to implement
the persistent editor mode. I'm sure I'll discuss this in more depth at some point
(because despite the criticism I'm going to leverage against it, I still think it works
**really** well), but here's a quick overview of Sorbet's language server architecture:

- Nearly every part of Sorbet's offline pipeline is embarrassingly parallel.

  All of the syntactic transformations on the tree happen without access to any sort of
  codebase-wide information. Type inference is only local—inferring types in one method
  body never affects the type check result of another method, let alone another file.
  Program-wide state is made immutable and shared across threads using shared memory (no
  copying).

- Sorbet does not track dependencies.

  That means it doesn't track which files `require` what other files. It doesn't have a
  way to incrementally update its class hierarchy (symbol table) when something changes.
  It only caches parse results and which what errors came from which files. There are no
  module or package boundaries—Sorbet views a codebase as one codebase.[^packager]

- Given all of this, there are two paths in server mode: the fast path and the slow path.

  When an edit comes in, Sorbet quickly decides whether the edit changes any global
  information. If it can, Sorbet throws everything away (except for cached parse results)
  and type checks the entire codebase from scratch. Otherwise, it leaves the symbol table
  unchanged and just retypechecks the edited file.

[^packager]:
  This is starting to change, but only because the approach mentioned here doesn't scale
  to 10 million-line Ruby codebases. It's probably possible to count all such codebases on
  your fingers.

On one hand, this is a very elegant architecture. Sorbet can be almost entirely understood
by how it behaves in batch mode. Put another way, if a user reports a bug in the editor
mode, it almost always reproduces outside of the editor mode. It's rare in Sorbet to find
a bug that only reproduces when the user makes one edit followed by another edit.

But on the other hand, if the parser can't recover from a syntax error, not only can
Sorbet not provide those fancy editor features, it also makes it look like all the
definitions in a file were deleted, which makes it look like the contents of the symbol
table will have changed, which kicks off a retypecheck of the whole codebase. Most syntax
errors are introduced in completely benign places (like `x.` or `if x`), not as part of
changing what's defined in a file (like `def foo` or `X =`) because people spend more time
editing method bodies than anything else. So most syntax errors can take the fast path as
long as the parser can manage to return a decent result.

**All of this is to say**: it's important for Sorbet to recover from syntax errors for two
reasons: it can't provide editor features like completion consistently without it, and in
large codebases it makes Sorbet deliver in-editor type checking errors far faster. In
future posts we'll ramp up to more technical and esoteric parsing topics. In particular,
the next post gives some historical context about Sorbet's parser and some ideas I
rejected for how to get better parse results for syntax errors.

<p style="text-align: right;">
  [Part 2: What I Didn't Do →](/error-recovery-part-2/)
</p>
