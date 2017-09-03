---
layout: post
title: "Show where a Python package is used"
date: 2015-06-11 23:36:05 -0700
comments: false
categories: ['bash', 'python']
description: >
  'I wrote a simple bash script that lists which Python packages use a given
  package.'
share: false
permalink: /:year/:month/:day/:title/
---

A while back I was doing some spring cleaning of my Python packages. I noticed
that there were a bunch of packages that I couldn't recall installing. I wanted
to know if I could safely remove them, so I wrote a simple bash script to tell
me called `pip-uses`.

<!-- more -->

## Source

Rather than post the source here and let it get more out of date every time I
change it, you can find the source [on GitHub][pip-uses-github]. It's in my [bin
repository][bin-github], where I keep my notable helper scripts; feel free to
poke around.


## Motivations

I was primarily influenced by Homebrew's `brew uses` command. It does a nice job
of giving you exactly the information you want, and I think the way the command
is named makes sense.

```plain Homebrew: brew uses
$ brew uses --installed pango
imagemagick
```

`pip-uses` gives you basically the experience:

```plain Pip: pip-uses
$ pip-uses stevedore
virtualenvwrapper
```

In this example, the Python package `virtualenvwrapper` uses `stevedore`, just
as `imagemagick` uses `pango`. Both commands can save you from accidentally
removing a crucial dependency and answer the burning question, "How in the world
did this thing get installed?"


## Wish List

I'm not doing much Python development these days, but if I had some spare time
I'd love for the script to also have these features:

- Recursive enumeration of dependencies
  - It'd be nice if `pip-uses` kept recursively searching until it found no more
    dependencies. This way, it'd be easy to see if you could safely uninstall a
    whole slew of packages that you're no longer using.
- Operate on more than one package
  - I didn't need it at the time, so I didn't implement it, but it'd be nice if
    the command took a variable amount of arguments and ran the same logic on
    all supplied packages.
- Integrate with `pip`
  - Programs like `brew` and `pip` allow developers to add "external commands"
    by adding commands to the `PATH` that look like `brew-xyz` or `git-xyz`. I
    couldn't find if there was a special way to add external commands to `pip`.

If you find this script useful and end up implementing one of these feature or
more on top of `pip-uses`, be sure to send me a Pull Request!



[pip-uses-github]: https://github.com/jez/bin/blob/master/pip-uses
[bin-github]: https://github.com/jez/bin

