---
layout: post
title: "Search Down the Stack"
date: 2020-06-06 19:08:20 -0500
comments: false
share: false
categories: ['fragment', 'linux', 'debugging']
description: >
  I've found it useful to search though the source code of things
  lower in the stack lately.
---

I've found it useful to search though the source code of things lower in
the stack lately. For example I saw an error something like this at work
recently:

```
❯ rake test
symbol lookup error: /home/jez/.../foo.so: undefined symbol bar
```

I was pretty confused. Modulo the names of commands and files, this was
pretty much all the output.

So I started searching. First I searched through my codebase for
`"symbol lookup error"`, but found nothing. Surely that string exists
somewhere. That must mean it's coming from lower in the stack?

The next level lower would mean third party Ruby gems. At work we use
Bundler [in a mode][deployment] where it installs all gems into a single
convenient folder in the current directory: `./vendor/bundle/`. But a
search in that folder turned up nothing again. So... further down?

[deployment]: https://bundler.io/v2.0/guides/deploying.html#manual-deployment

If it's not from the app, and not from the gems, then maybe it's in Ruby
itself? I cloned the [Ruby source], checked out the [version tag] for
the Ruby version we're running, and searched for `"symbol lookup error"`
once again. And again nothing!

[Ruby source]: https://github.com/ruby/ruby
[version tag]: https://github.com/ruby/ruby/tree/v2_6_5

There's still plenty of layers below us, so let's keep peeling them
back. Ruby is written in C, which means we should check libc next (the C
standard library). There are multiple libc implementations, but I was
running this on Linux, so let's check GNU libc (glibc). glibc is [isn't
on GitHub], but that's not a huge deterrant. Here's the search:

[isn't on GitHub]: https://www.gnu.org/software/libc/sources.html

```
❯ rg -t c 'symbol lookup error'
dl-lookup.c
876:      _dl_signal_cexception (0, &exception, N_("symbol lookup error"));
```

That's a bit of a smoking gun! After all those layers, we found our
error message in libc itself. (This gave me a lot of leads on the problem
at hand, e.g., I had definitely ruled out a problem in my app or its
dependencies, and I was thinking, "probably something is wrong about
how `foo.so` was compiled." There's a fun story here about how Ruby C
extensions work, but that's a [tangent for another time].)

[tangent for another time]: /linkers-ruby-c-exts/

My point is that [searching all the code] is a super power, and it
applies to more than just searching the code we've written. What a
blessing that the tools we're building on, like Ruby and GNU libc, are
all open source!

[searching all the code]: https://livegrep.com/search/linux

The next time it looks like a problem is outside the scope of your app's
code, maybe try searching the code:

- inside your gems or packages!
- inside your language's standard library!
  - Some IDEs will even let you jump-to-def into core libraries 😮
- inside your language's runtime
  - (if you're using a language with a runtime like Ruby or Python or
    even [JavaScript])
- powering your operating system kernel! [^kernel]

For me, I've already noticed it help save me time and give me more
context when I'm debugging.

[JavaScript]: https://github.com/v8/v8

[^kernel]: This might sound daunting, but sometimes it can be useful. A good thing to keep in mind: every **system call** like `open(2)` or `write(2)` or `select(2)` (and every other function from section 2 of the man pages) is really just a way for your program to request that the operating system do something; knowing that can be a decent place to start traipsing through code in the operating system.


<!-- vim:tw=72
-->
