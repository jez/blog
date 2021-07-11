---
layout: post
title: "Standard ML in Travis&nbsp;CI"
date: 2019-06-04 09:26:45 -0700
comments: false
share: false
categories: ['sml', 'bash']
description: >
  For one of my recent projects I went through the work to get Standard
  ML building in Travis CI.
---

For one of my recent projects ([`multi-grep`]) I went through the work to
get Standard ML building in Travis CI. It turned out to be not too
hard—in fact, the hardest part is already done, and I'm happy to share
how it works.

<!-- more -->

[Travis CI] is a service that lets a project run arbitrary code when
someone commits and pushes a change. This code can do things like make
sure the tests pass, build and publish releases, and even deploy the
code somewhere.

[Travis CI]: https://travis-ci.org/

# Features

The way I set up my builds for SML with Travis CI, I can:

- build and test with both macOS and Linux
- build and test with both SML/NJ and MLton
- create executables, even with SML/NJ
- publish the resulting builds to GitHub as releases

Apart from some scripts to install things on each operating system,
under the hood it's powered by [Symbol], which is a build tool for
Standard ML I wrote which factors out most of the project-agnostic
stuff.


# The core setup

Rather than paste the code into a snippet here and wait for it to get
out of date, see my [`multi-grep`] project on GitHub for all the
up-to-date files. In total, there are three files in that repo which set
the whole thing up:

1.  [.travis.yml] (kicks off the build)
2.  [Brewfile] (deps for macOS build)
3.  [tests/travis-install.sh] (deps for Linux build)

[.travis.yml]: https://github.com/jez/multi-grep/blob/b6a42719b1ffca389556655982e6c4b7fa19c9a1/.travis.yml
[Brewfile]: https://github.com/jez/multi-grep/blob/b6a42719b1ffca389556655982e6c4b7fa19c9a1/Brewfile
[tests/travis-install.sh]: https://github.com/jez/multi-grep/blob/b6a42719b1ffca389556655982e6c4b7fa19c9a1/tests/travis-install.sh

If you haven't used Travis CI before, you'll probably also want to check
out the [Travis CI docs] to get a feel for how to actually set things
up, and where these pieces fit in.

[Travis CI docs]: https://docs.travis-ci.com/

After installing the deps on each box (like SML/NJ and MLton) and
running the tests, the command which actually builds the the whole
project is

```
./symbol install
```

This command is provided by [Symbol], a build tool I wrote for Standard
ML. I talk a little bit more about it in the section below.

# Why write a whole build tool?

I mentioned above that I'd written a build tool for Standard ML, called
[Symbol]. Why? It started as a shell script + `Makefile` for
[`multi-grep`] and then I realized that these scripts could be useful in
any Standard ML project.

SML/NJ and MLton are already great compilers with their own build tools.
It's useful to be able to build a project with both (SML/NJ for faster
builds and a REPL, and MLton for faster compiled executables). All
Symbol really does is put SML/NJ and MLton behind a unified, very
stripped down interface. It doesn't try to hide that, so that it's still
possible to fall back to those programs for more complex workflows.

There's more information [in the README][Symbol], but some key points:

- Symbol makes it easy to build and install executables, even with
  SML/NJ which traditionally uses heap images.
- Symbol is built on `make`, so if **no** source files change, even
  recompiling with MLton is instant (e.g., changing a test and
  re-running the tests doesn't require re-building everything).
- Symbol also supports scaffolding new Standard ML projects, which is
  nicer than starting from scratch.

The usage looks something like this:

```bash
# initialize a new project:
❯ symbol-new hello
❯ cd hello

# build with SML/NJ:
❯ ./symbol make
❯ .symbol-work/bin/hello
Hello, world!

# or, build with MLton:
❯ ./symbol make with=mlton
❯ .symbol-work/bin/hello
Hello, world!
```

Again, there's way more information [in the README][Symbol], so
definitely check it out if you're thinking about setting up a new
Standard ML project.

# Why Standard ML in the first place?

I'll probably get around to [writing about `multi-grep`] (and related
tools like `diff-locs` and `multi-sub`) but at the end of the day:
SML is a really pleasant language to use in a lot of ways:

- Type inference in Standard ML is a breath of fresh air.
- Data types let me wonder less about how things work.
- Pattern matching makes for concise, clean, and correct code.

Standard ML was my most commonly used programming language throughout
all of my university courses, so there's a definite soft spot in my
heart for it. There are features that I wish it had sometimes, but it's
the only language that I've used that doesn't feel fundamentally broken
in some way.

[`multi-grep`]: https://github.com/jez/multi-grep
[`diff-locs`]: https://github.com/jez/diff-locs
[`multi-sub`]: https://github.com/jez/multi-sub
[Symbol]: https://github.com/jez/symbol
[writing about `multi-grep`]: /surgery-on-code/

<!-- vim:tw=72
-->
