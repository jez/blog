---
# vim:tw=90 fo-=tc
layout: post
title: "Bugs Block Blogs"
date: 2026-01-21T17:37:55-05:00
description: When writer's block is actually the weight of the bugs you're papering over.
math: false
categories: ['fragment', 'meta']
# subtitle:
# author:
# author_url:
---

A big blocker to me writing more in the past year or so is that Sorbet is buggy. I've started a bunch of posts and gotten part the way through a rough draft, only to realize that something I wanted to comment on actually reveals a subtle bug in Sorbet.

Some post ideas that have been relegated to this bucket:

- One about `T.self_type`, and how it relates to class-level generics
- Another one comparing `@@x = 1` (Ruby class variables) and `X = 1` (Ruby constant assignments)
- A discussion of multiple inheritance and mixin inheritance

... etc. My [Typing klass.new](/typing-klass-new/) post narrowly escaped this fate, but it did spur me to build [`has_attached_class!`](https://sorbet.org/docs/attached-class#has_attached_class-tattached_class-in-module-instance-methods).

I find new ways that it's subtly broken seemingly every time I sit down to write a "Sorbet how to" post. It's usually just implementation-level concerns: it's not like the _theory_ backing Sorbet's type system is broken. It's that Sorbet's current implementation cut corners (usually for expedience in shipping early on in the project) and doesn't achieve the totality of what the theory predicts it should permit. These bugs remain unfixed just because of prioritization and time constraints: the time it to fix the bug, but also the time to codemod programs relying on the buggy behavior.

On the bright side, it means that there's plenty of work left to do, which is great because I love the feeling of fixing bugs in Sorbet. Also I guess it's encouraging that I'm finding out about these bugs first from my own investigations, vs Sorbet users reporting them? Maybe that means that they're not as consequential as they are in my mind.

The perfectionist in me struggles with just blazing forward with a post knowing that it's glossing over bugs in Sorbet, and so I end up in a spiral of "blog-driven development" where I want to write a blog post and end up getting side tracked fixing bugs in Sorbet.

