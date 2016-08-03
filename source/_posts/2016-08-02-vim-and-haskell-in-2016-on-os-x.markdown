---
layout: post
title: "Vim and Haskell in 2016 on OS X"
date: 2016-08-02 21:04:08 -0700
comments: true
categories: ['best practices', 'osx', 'haskell', 'vim']
description: >
  Stephen Diehl's article "Vim and Haskell in 2016" does a great job of
  outlining the quickest way to get a quality Haskell development experience.
  His post presumes Ubuntu; here we presume OS X.
share: true
---

Stephen Diehl's article [Vim and Haskell in 2016][vim-and-haskell] does a great
job of outlining the quickest way to get a quality Haskell development
experience. His post presumes Ubuntu; here we presume OS X.

<!-- more -->

This post wouldn't actually be necessary if it weren't for one thing: [System
Integrity Protection][rootless] in OS X El Capitan, also known as "rootless"
mode. It affects Haskell's build and install step in a subtle (but solved) way,
and the rest of the article will cover what to watch out for when installing on
OS X.

If you don't follow these instructions and you're on OS X El Capitan, you'll
likely run into an issue that looks like `/usr/bin/ar: permission denied`. The
Stack installation instructions call this out specifically:

> If you are on OS X 10.11 ("El Capitan") or later, GHC 7.8.4 is incompatible
> with System Integrity Protection (a.k.a. "rootless"). GHC 7.10.2 includes a
> fix, so this only affects users of GHC 7.8.4.

At the risk of spoiling the surprise, we're going to set up Stack while taking
care to make sure that we get GHC >= 7.10. So let's do just that!


## Environment Prep (optional)

Note that this step is optional and has nothing to do with OS X; I just wanted
to point it out quickly.

Under [Dev Environment][dev-environment] on [Vim and Haskell in
2016][vim-and-haskell], Stephen Diehl writes:

> Times have changed quite a bit, and the new preferred way of installing GHC in
> 2016 is to forgo using the system package manager for installing ghc and use
> Stack to manage the path to the compiler executable and sandboxes.

Stack stores it's metadata in the `~/.stack` folder by default. If you're not a
huge fan of things cluttering up your home folder, set the `STACK_ROOT` variable
in you bashrc or zshrc:

```bash Set STACK_ROOT to avoid clutter
export XDG_DATA_HOME="$HOME/.local/share"

# Have Haskell Stack use XDG Base Directory spec
export STACK_ROOT="$XDG_DATA_HOME/stack"
```

Of course, the choice of location is up to you. In particular I've chosen to
adhere to the [XDG Base Directory specification][xdg] here, which you may want
to take a peek at if you're unfamiliar. That's why you see references to
`XDG_DATA_HOME`.

Make sure you restart your terminal to pick up the new variables before
continuing.


## Install Stack from Homebrew

If you're like me, you'll want to take a second to purge anything
Haskell-related from previous botched setup attempts:

```bash Wipe the slate clean
# If you had GHC installed
$ brew uninstall ghc

# If you tried and failed at installing Stack already
$ brew uninstall haskell-stack
$ rm -r ~/.stack
# If you happened to also set STACK_ROOT
$ rm -r $STACK_ROOT
```

With that out of the way, we can actually get our hands on Stack. For OS X,
we'll install through Homebrew:

```console Install Stack
$ brew install haskell-stack
```


## Configure Stack, avoiding "rootless" issues

Here's the trick. We need to run `stack setup` for the first time to let Stack
configure itself. But remember: we want to make sure that Stack doesn't set
itself up with version 7.8.4 of GHC. We can get around this by specifying an
explicit resolver to the `stack` command (you can find more information on
"resolvers" elsewhere):

```bash Side-step rootless issue in setup
# Change the resolver to the most up-to-date one. This is a hack to ensure that
# get GHC version > 7.8, because there's an issue with El Capitan's rootless
# mode.
stack --resolver=lts-6.10 setup
```

You'll notice we use the `--resolver=...` flag to force Stack to use a specific
resolver. This post will be out of date as soon as it's written, so check
[Stackage][snapshots] to find the latest LTS snapshot.


## Return to Vim and Haskell in 2016

That's it for the environment setup! Now you'll want to turn your attention to
configuring Vim.

The steps to set up Vim are platform independent, so now that we've set up Stack
correctly, you can head over to [Vim and Haskell in 2016][vim-and-haskell] to
finish things out.


{% include jake-on-the-web.markdown %}


[vim-and-haskell]: http://www.stephendiehl.com/posts/vim_2016.html
[dev-environment]: http://www.stephendiehl.com/posts/vim_2016.html#dev-environment
[rootless]: https://support.apple.com/en-us/HT204899
[xdg]: https://wiki.archlinux.org/index.php/XDG_Base_Directory_support
[snapshots]: https://www.stackage.org/snapshots
