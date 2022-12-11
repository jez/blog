---
# vim:tw=90
layout: post
title: "Some Old Sorbet Compiler Notes"
date: 2022-12-10T17:38:00-05:00
description: >-
  Today I'm publshing a few of my old, internal-facing notes about the Sorbet Compiler
  here to my blog.
math: false
categories: ['meta', 'sorbet', 'sorbet-compiler']
# subtitle:
# author:
# author_url:
---

From January 2020 to December 2021 I was primarily working on the [Sorbet Compiler], an
experimental, ahead-of-time compiler for Ruby, targeting native code. For most of that
time, it was a mostly-secret, internal-only project. Today I'm publishing a few of my old,
internal-facing notes about the compiler here to my blog.

<!-- more -->

[Sorbet Compiler]: https://sorbet.org/blog/2021/07/30/open-sourcing-sorbet-compiler

In July 2021 we open sourced the Sorbet Compiler,[^logistics] but there's not much written
about it outside of Stripe. It's basically just the above blog post and this talk that
Trevor Elliott and I presented at RubyConf 2021:

[^logistics]:
  ... not so much because it was ready for widespread adoption but largely because it made
  some internal logistics easier!

<!-- https://stackoverflow.com/a/38149485 -->
<div style="position:relative; padding-bottom: 56.25%; height: 0; overflow: hidden;">
  <iframe
    style="position: absolute; top: 0; left: 0; width: 100%; height:100%;"
    src="https://www.youtube-nocookie.com/embed/BH8S1htcHXY"
    title="YouTube video player"
    frameborder="0"
    allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
    allowfullscreen>
  </iframe>
</div>

While I was working on the compiler internally, I wrote up some informal notes about how
the compiler worked and the potential it could have. None of those notes were particularly
privy to confidential information—it was just that the compiler was not a public project
at the time, so it didn't make sense to post them publicly.

I've gone back and taken those internal notes and published them here to my blog. (Mostly,
I just wanted to fill in the gaps on my blog.[^gaps]) Note that they are all quite old
now, and may not be as accurate as they were at the time of writing. I've dated them with
the date they were published internally to reflect that, which means you'll have to find
them in the archives.

[^gaps]:
  Before reposting these Sorbet Compiler posts, I only posted publicly five times in 2020
  and twice in 2021 😞

Note that the compiler is **still** not a project that we would encourage anyone to use.
At this point, it [hasn't seen active development][compiler-history] for the better part
of the last year as we've focused on improvements to Sorbet itself (though we have kept
the test suite running, so things are unlikely to have slipped into complete disrepair).

[compiler-history]: https://github.com/sorbet/sorbet/commits/master/compiler

The official word is still what's written in the [sorbet.org blog post][Sorbet Compiler]:

> We want to be clear up front: the code is nowhere near ready for external use right now,
> but we welcome you to read the code and give us feedback on our approach!

Anyways, maybe you'll enjoy the assorted notes digging into some of the compiler's guts.
If you have questions, feel free to reach out.

