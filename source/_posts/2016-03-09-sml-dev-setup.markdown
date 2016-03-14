---
layout: post
title: "SML Dev Setup"
date: 2016-03-09 20:06:15 -0600
comments: true
categories: ['best practices', 'vim', 'osx', 'terminal', 'sml']
description: >
  Let's walk through a couple easy steps you can take to make developing SML
  feel more fluid, both in and out of your editor.
share: true
---

When it comes right down to it, SML is a pretty great language. It's clear that
extensive thought has gone into its design and implementation. I quite enjoy
programming in SML, due in no small part to my collection of workflow hacks that
make editing and developing with SML responsive and interactive.

<!-- more -->

We're going to be walking through a couple easy steps you can take to make
developing SML feel more fluid, both in and out of your editor. I have a slight
preference for Vim on OS X, but many of these steps are platform agnostic.

## Installing SML Locally

While developing SML in a remote environment like the shared Andrew Unix
machines makes it easy to dive right in, working with SML for prolonged periods
of time is best done locally.

On OS X and Ubuntu, the two most popular SML implementations are already
packaged. Take the time to install a version of SML right now. At CMU, we use
[SML/NJ][smlnj], which is convenient because it has a REPL that lets you play
around with SML interactively. If you'd like to play around with compiling and
distributing programs written in SML, you might want to install [MLton][mlton].

```bash Install SML from your package manager
# SML/NJ on OS X
brew install smlnj
# -- or --
# MLton on OS X
brew install mlton

# SML/NJ on Ubuntu
sudo apt-get install smlnj
# -- or --
# MLton on Ubuntu
sudo apt-get install mlton
```

Feel free to install both if you'd like; they'll play nicely with each other and
each offers advantages over the other.

Note for OS X users: if you've never used [Homebrew][brew] before, you'll need
to [install it first][brew].


## Getting Comfortable with SML/NJ

The rest of these steps should apply regardless of whether you're working on SML
locally or remotely.

One thing that I've seen far too many times from course documentation is that
they tell students to run their code like this:

1. Run `sml`
2. Type `use "foo.sml";` or `CM.make "sources.cm";` at the REPL

Don't get me wrong; this works, but there's a better way. Being responsible
CLI-citizens, we should always be looking for ways to tab-complete. Let's do
this by changing our workflow:

1. Run `sml foo.sml` or `sml -m sources.cm`

Look at that! We've,
- dropped a step (having to launch the REPL first), and
- introduced tab completion into our workflow (because the shell has filename
  completion)

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
$ rlwrap
```

`rlwrap` stands for "readline wrap." Readline is a library that simply adds to a
REPL program all the features mentioned above:

- Command history tracking
- Line editing with arrow keys
- Configurability through the `~/.inputrc` file
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


### Syntastic

From the Syntastic documentation:

> Syntastic is a syntax checking plugin for Vim that runs files through
> external syntax checkers and displays any resulting errors to the user. This
> can be done on demand, or automatically as files are saved. If syntax errors
> are detected, the user is notified and is happy because they didn't have to
> compile their code or execute their script to find them.

And the best part? Syntastic ships with a checker for SML by default if you
have SML/NJ installed.

If you didn't just install [Syntastic][Syntastic] from the Vim as an IDE
walkthrough, you can [visit their homepage][Syntastic] for installation
instructions. Go ahead and do this now, then try writing this in a file called
`test.sml`:

```sml test.sml
val foo : string = 42
```

You should see an 'x' next to the line and a description of the error from the
type checker. You can imagine how handy this is.


### Extra Syntastic Setup

Syntastic has their own set of [recommended settings][syntastic-settings] that
you can add at your discretion. At the very least, I'd suggest adding these
lines to your vimrc:

```vim .vimrc
...

augroup mySyntastic
  " tell syntastic to always stick any detected errors into the location-list
  au FileType sml let g:syntastic_always_populate_loc_list = 1

  " automatically open and/or close the location-list
  au FileType sml let g:syntastic_auto_loc_list = 1
augroup END

" press <Leader>S (i.e., \S) to not automatically check for errors
nnoremap <Leader>S :SyntasticToggleMode<CR>

...
```

By default, whenever you save your file, Syntastic will place symbols in Vim's
_sign column_ next to lines with errors. The first two settings above tell
Syntastic to also show a summarized list of errors at the bottom of the screen.
The final setting lets you press `<Leader>S` (which is usually just `\S`) to
disable all that. This is useful when you're still unfinished and you know your
SML isn't going to type check. Press it again to re-enable it.

Also, a tip for those who've never used Vim's location list feature before: you
can close the list with `:lclose`.


### `vim-better-sml`

The curious at this point might be wondering if Syntastic is smart enough to
figure out when the file you're using requires a CM file to compile and uses it
to show you where the errors are instead. As it turns out: no, [that's not a
feature Syntastic wants to include][pull-1719] by default. However, the
functionality isn't hard to implement, and there's already a plugin for it!

[vim-better-sml][vim-better-sml] is one of my Vim plugins. Here's a quick
rundown of its features:

- As already mentioned, it will detect when your file requires a CM file to
  build, and will pass along the information to Syntastic
- `let` expressions are indented one level under `fun` declarations
- `*.sig` files are properly detected as SML signature files
- Apostrophe characters are treated as keywords characters
- The comment string is properly registered for SML files

For more information, including how to install it, check out the homepage:
[vim-better-sml][vim-better-sml].


## General Vim Settings

As a quick addendum, one common complaint people have when editing SML is that
it forces the line to wrap if it extends to 80 characters. Some people don't
like that it does this, and others don't like that it doesn't do it frequently
enough (namely, it only wraps the line if your cursor extends past 80
characters, not the end of the line).

If you don't want Vim to do any of this wrapping, run this:

```vim Disable hard line wrapping
setlocal textwidth=0
```

If you'd like this change to persist between Vim sessions, add it to
`~/.vim/after/ftplugin/sml.vim`. These folders and file likely don't exist
yet; you'll have to create them. The `after` folder in Vim is used to override
settings loaded from plugins. As you might have guessed, files in here are run
after plugin code is.

Conversely, if you'd like a little better idea when Vim's going to hard wrap
your line, you can add this line to your vimrc:

```vim Show a color column
set colorcolumn+=0
```

Note: this will only work if you're using Vim 7.4 or above. This setting tells
Vim to draw a solid column at the same width as the value of the `textwidth`
setting.


## TL;DR

We covered a lot, so here's a quick recap:

- Install SML locally. It's super easy to do on OS X and Linux (use your package
  manager), and means you don't have have a Wi-Fi connection to develop SML.
- Invest time into learning Vim. Here's a reference: [Vim as an
  IDE][vim-as-an-ide].
- Install [Syntastic][Syntastic]. It tells you what lines your errors are on.
- Install [vim-better-sml][vim-better-sml]. It includes some features Syntastic
  doesn't by default, and includes a couple extras.
- Consider using `setlocal textwidth=0` or `set colorcolumn+=0` to deal with the
  80-character restriction when writing SML files.

And as always, you can see even more Vim settings in my [dotfiles
repo][dotfiles] on GitHub.

{% include jake-on-the-web.markdown %}

[brew]: http://brew.sh
[smlnj]: http://smlnj.org/
[mlton]: http://www.mlton.org/
[vim-as-an-ide]: https://github.com/jez/vim-as-an-ide
[Syntastic]: https://github.com/scrooloose/syntastic
[syntastic-settings]: https://github.com/scrooloose/syntastic#settings
[pull-1719]: https://github.com/scrooloose/syntastic/pull/1719
[vim-better-sml]: https://github.com/jez/vim-better-sml
[dotfiles]: https://github.com/jez/dotfiles
[inputrc]: https://github.com/jez/dotfiles/blob/ed8e531eebe43a8aef05fc4cb768157d03408cea/inputrc#L12-L14
