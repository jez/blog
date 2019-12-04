---
layout: post
title: "SML Dev Setup"
date: 2016-03-09 20:06:15 -0600
comments: false
categories: ['vim', 'osx', 'sml']
description: >
  Let's walk through a couple easy steps you can take to make developing SML
  feel more fluid, both in and out of your editor.
share: false
redirect_from:
- /2016/03/09/sml-dev-setup/
---

When it comes right down to it, SML is a pretty great language. It's clear that
extensive thought has gone into its design and implementation. I quite enjoy
programming in SML, due in no small part to my collection of workflow hacks that
make editing and developing with SML responsive and interactive.

<!-- more -->

We're going to be walking through a couple easy steps to make developing SML
feel more fluid. I have a slight preference for Vim (Neovim) on macOS, but many
of these steps are platform agnostic.

## Installing SML Locally

While developing SML in a remote environment like the shared Andrew Unix
machines makes it easy to dive right in, I prefer doing development on my
laptop—it doesn't get slow when there are many people logged in, there's no
nightly reboots, and it doesn't matter whether I have a strong WiFi connection.

On macOS and Ubuntu, the two most popular implementations of SML are already
packaged. Take the time to install a version of SML right now:

- At CMU we use [SML/NJ][smlnj], which is convenient because it has a REPL that
  for playing around with SML interactively.

- To play around with releasing programs written in SML to other people, install
  [MLton][mlton]. It has better support for compiling SML programs to standalone
  executables which can be shared from one machine to another. (I have a
  separate post on [using SML to release software publically][sml-travis-ci]
  with more details).

```bash Install SML from your package manager
# macOS -- one or both of:
brew install smlnj
brew install mlton

# Ubuntu -- one or both of:
sudo apt-get install smlnj
sudo apt-get install mlton
```

Feel free to install both; they'll play nicely with each other, and each offers
advantages over the other.

Note for macOS users: if you've never used [Homebrew][brew] before, you'll need
to [install it first][brew].

Note for Ubuntu users: the versions of these two that ship in the default
package distribution are frequently out of date. If that matters to you,
consider following the the [SML/NJ][smlnj] and [MLton][mlton] installation
instructions directly.


## Getting Comfortable with SML/NJ

The rest of these steps should apply regardless of whether you're working on SML
locally or remotely.

One thing that I've seen far too many times from course documentation is that
they tell students to run their code like this:

1. Run `sml`
2. Type `use "foo.sml";` or `CM.make "sources.cm";` at the REPL

Don't get me wrong; this works, but there's a better way. Being responsible
CLI-citizens, we should always be looking for ways to tab-complete. We can
easily get tab-completion on the filename by changing our workflow:

1. Run `sml foo.sml` or `sml -m sources.cm`

Look at that! We've,

- dropped a step (having to launch the REPL first), and
- introduced tab completion (because the shell has filename completion)

It's the little things, but they add up.


## Enhancing the REPL

Speaking of the little things, when using the SML REPL, you don't have access to
all the usual command line niceties like command history and access to arrow
keys for editing, let alone Vi-like keybindings. To get started, you'll have to
change how you launch the SML/NJ REPL. In particular, we're going to preface our
commands with `rlwrap`:

```bash
# instead of this...
$ sml

# use this:
$ rlwrap sml
```

`rlwrap` stands for "readline wrap." Readline is a library that adds all the
features mentioned above to any REPL program:

- Command history tracking (up arrow keys)
- Line editing with arrow keys
- Configuration through the `~/.inputrc` file
  - We can use this to get fancy features like Vi keybindings

For more information, see [these lines][inputrc] of my inputrc, a small part of
my [dotfiles repo][dotfiles] on GitHub.

## Setting Up Vim

Programming is so much more enjoyable when you're not fighting your editor. For
me, this means striving to get the most out of Vim. In this section, I'll
outline all the cool tips and tricks I have for developing SML in Vim.

But first, if you've never taken a look into how to configure Vim, I suggest you
start out by walking through this quick workshop called [Vim as an
IDE][vim-as-an-ide]. It'll teach you where to start when configuring Vim and get
you set up with a bunch of standard plugins that improve on the standard Vim
experience tenfold.

No actually, take a second and [walk through it][vim-as-an-ide]. We'll still be
here when you're done, and you'll appreciate Vim more when you're done.


### ALE

[ALE][ale] is a Vim plugin that provides what it calls "asynchronous linting."
That's a fancy way of saying that it can show little red x's on all the lines
that have errors. It works for many languages out of the box, including Standard
ML.

It's super simple to set up. The [ALE homepage][ale] should have all the
instructions.

With ALE set up, try writing this into a file called `test.sml`:

```sml test.sml
val foo : string = 42
```

While typing, any errors should appear as markers to the left of the line
numbers. Super handy!

If nothing shows up, check `:ALEInfo` which dumps a bunch of information
about whether ALE was set up correctly. In particular, SML support requires
having [SML/NJ][smlnj] installed (i.e., installing it on your laptop or working
on a server where it's already installed).

### Extra ALE Setup

While the default settings for ALE work well enough, there's plenty of reasons
to tweak them. For example, here are [all my ALE settings][ale-vimrc].

The key changes I make:

- I ask ALE to show a list of all errors if there were any.
- I ask ALE to only run when the file was saved (not when it was opened or
  edited).

(You'll also see a bunch of settings for other languages, but you won't find any
SML-specific config... it's not needed!)

Also, a tip for those who've never used Vim's location list: you can close the
list of errors with `:lclose`.

### Using ALE with CM files

Sometimes a single SML file is self-contained enough to type check on it's own.
But most of the time, we're working with multi-file SML projects. With SML/NJ,
multi-file SML projects are managed using CM files (`*.cm` files) which declare
groups of SML files that must be compiled together to make sense.

ALE's support for SML handles both of these scenarios. When opening an SML file,
ALE will search up the folder hierarchy for any `*.cm` file, stopping when it
finds the first one. When there are multiple in a single folder, it takes the
alphabetically first option.

Usually this works fine but sometimes ALE picks the wrong one. There are
instructions for how to manually fix this by setting some variables in the ALE
help:

```
:help ale-sml-options
```

### `vim-better-sml`

After all that, I still wasn't satisfied with developing SML in Vim, so I wrote
a plugin to make it even better: [vim-better-sml][vim-better-sml]. Here's a
quick rundown of its features:

- It supports for embedding a REPL directly inside Vim.
- It supports asking for the type of a variable under the cursor.
- It supports jump to definition, even into the Standard Basis Library.
- `*.sig` files are properly detected as SML signature files.
- Many small annoyances with syntax highlighting and indentation are fixed.

For more information, including how to install it, check out the homepage:
[vim-better-sml][vim-better-sml]. For the most part, the plugin itself will
guide you through the installation, declaring any dependencies that might be
missing.

I recorded a screencast of all those features above in action, which you might
want to check out:

[![thumbnail][demo-thumbnail]](https://youtu.be/Z5FsPZ5cm8Y)


## General Vim Settings

As a quick addendum, one common complaint people have when editing SML is that
it forces the line to wrap if it extends past 80 characters. Some people don't
like that, and others don't like that it doesn't do it frequently enough
(namely, it only wraps the line if your **cursor** extends past 80 characters,
not the end of the line).

If you don't want Vim to do any of this wrapping, run this:

```vim Disable hard line wrapping
setlocal textwidth=0
```

If you'd like this change to persist between Vim sessions, add it to
`~/.vim/after/ftplugin/sml.vim`. These folders and file likely don't exist
yet; you'll have to create them. The `after` folder in Vim is used to override
settings loaded from plugins.

Alternatively, if you'd like a little better idea when Vim's going to hard wrap
your line, you can add one of these lines to your vimrc:

```vim Show a color column
" Always draw the line at 80 characters
set colorcolumn=80

" Draw the line at whatever the current value of textwidth is
set colorcolumn+=0
```

That way, it's easier to see when a line is getting long.


## TL;DR

We covered a lot, so here's a quick recap:

- Install SML locally. It's super easy to do on macOS and Linux (use your
  package manager), and means you don't have to have a Wi-Fi connection to
  develop SML.
- Invest time into learning Vim. Here's a reference: [Vim as an
  IDE][vim-as-an-ide].
- Install [ALE][ale]. It tells you what lines your errors are on.
- Install [vim-better-sml][vim-better-sml]. It includes a whole host of added
  power features.

And as always, you can see even more Vim settings in my [dotfiles
repo][dotfiles] on GitHub.


[brew]: http://brew.sh
[smlnj]: http://smlnj.org/
[mlton]: http://www.mlton.org/
[sml-travis-ci]: /sml-travis-ci/
[vim-as-an-ide]: https://github.com/jez/vim-as-an-ide
[ale]: https://github.com/dense-analysis/ale
[ale-vimrc]: https://github.com/jez/dotfiles/blob/b942b6336ee968c9d94a9ea363c1cbcdb44b9846/vim/plug-settings.vim#L227-L239
[pull-1719]: https://github.com/scrooloose/syntastic/pull/1719
[vim-better-sml]: https://github.com/jez/vim-better-sml
[dotfiles]: https://github.com/jez/dotfiles
[inputrc]: https://github.com/jez/dotfiles/blob/ed8e531eebe43a8aef05fc4cb768157d03408cea/inputrc#L12-L14
[demo-thumbnail]: /images/vim-better-sml-demo-thumbnail.png
