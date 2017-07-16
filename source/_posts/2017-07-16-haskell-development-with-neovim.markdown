---
layout: post
title: "Haskell Development with Neovim"
date: 2017-07-16 13:45:31 -0500
comments: false
share: false
categories: ['haskell', 'vim']
description: >
  After a year and a half of using Haskell on and off, I've finally settled on a
  set of high-quality development and editor tools, using Stack and Neovim.
---

Configuring an editor for a new language is a double-edged sword: it's intensely
satisfying when done, but takes time away from diving into the language itself!
After using Haskell for a little over a year, I've settled on a high-quality set
of editor plugins. They're simple, powerful, and all play nicely together.

<!-- more -->

## Requirements

I use [Haskell Stack][stack] exclusively for managing GHC versions, installing
packages, and building projects. Stack's goal is reproducible builds, which
means that if two different people have the same code and both run `stack
build`, they both get the same result. Since builds are reproducible, Stack can
cache pretty aggressively to save time in the future[^recomp]. I never have to
invoke `ghc` or `cabal` manually; Stack handles everything.

I also use [Neovim][neovim], rather than normal Vim. Usually my justification
for using it is more philosophical than technical, but with my Haskell setup
it's actually a requirement (we'll see why further on). Neovim is quite stable,
works as a drop-in replacement for Vim, yet brings new features[^logo]. I love
Neovim, and I'll be writing more about why in a future post.

<!-- TODO(jez): Update with link to Neovim post -->

## Overview

We're going to move in order of increasing complexity. That said, even the most
"complex" plugin here is actually quite painless to set up. By the end, we'll
have a complete development experience! Coming up:

- syntax highlighting & indentation ([haskell-vim][])
- auto-formatting & style ([hindent][], [stylish-haskell][])
- quickfix and sign column icons (using [ale][]) for:
  - linter style suggestions (hlint)
  - compiler errors and warnings (ghc-mod)
- Type inspection, REPL integration, and **more!** ([intero-neovim][])

If you just want to browse the final configuration, [here's a Gist][gist-final].

<!-- TODO(jez) Demonstrate everything with an asciicast -->

## Syntax Highlighting & Indentation

- **Plugin**: [haskell-vim][haskell-vim][^neovimhaskell]

Vim's default Haskell filetype plugin is pretty lack luster. Everything is blue,
except for strings which are colored like comments and keywords which are
colored like constants. Indentation is wonky in some edge cases, and isn't
configurable.

This plugin corrects all that. It's the filetype plugin for Haskell that
**should** ship with Vim.

`haskell-vim` lets me configure certain parts of the indentation, too. These are
my indentation settings. Note that the last setting only works because I've
merged [this PR][pr-98] locally.

```vim neovimhaskell/haskell-vim
" Align 'then' two spaces after 'if'
let g:haskell_indent_if = 2
" Indent 'where' block two spaces under previous body
let g:haskell_indent_before_where = 2
" Allow a second case indent style (see haskell-vim README)
let g:haskell_indent_case_alternative = 1
" Correct bug with aggressive let indentation
let g:haskell_indent_let_no_in = 0
```

## Auto-formatting and Indentation

- **Plugin**: [vim-hindent][]
- **Tool**: `stack install hindent`
- **Tool**: `stack install stylish-haskell`

For small projects, I like using my own, personal style. However, for larger
projects it's a burden to ask contributors to learn my personal style. In these
cases, tools come into play.

`go fmt` famously solved this problem for Golang by building the formatting tool
into the compiler. For Haskell, there's [hindent][][^one-tool]. `hindent` can be
installed through Stack, and `vim-hindent` shims it.

But I said I'm partial to my own style in personal projects. There's another
Haskell formatter that's much less invasive: [stylish-haskell][]. It basically
only works with `import`s, `case` branches, and record fields, aligning them
vertically.

With these three tools, I can pick the right hammer for the job:

- **Bare hands**: manually control the style myself
- **Normal hammer**: run `stylish-haskell` only
- **Sledgehammer**: run `hindent` only
- **Sledgehammer, then band-aid**: run `hindent`, then `stylish-haskell`

Here's the config that gets them to play nicely together:

```vim hindent, vim-hindent, and stylish-haskell
" Indenting on save is too aggressive for me
let g:hindent_on_save = 0

" Helper function, called below with mappings
function! HaskellFormat(which) abort
  if a:which ==# 'hindent' || a:which ==# 'both'
    :Hindent
  endif
  if a:which ==# 'stylish' || a:which ==# 'both'
    silent! exe 'undojoin'
    silent! exe 'keepjumps %!stylish-haskell'
  endif
endfunction

" Key bindings
augroup haskellStylish
  au!
  " Just hindent
  au FileType haskell nnoremap <leader>hi :Hindent<CR>
  " Just stylish-haskell
  au FileType haskell nnoremap <leader>hs :call HaskellFormat('stylish')<CR>
  " First hindent, then stylish-haskell
  au FileType haskell nnoremap <leader>hf :call HaskellFormat('both')<CR>
augroup END
```

## Quickfix & Sign Columns

- **Plugin**: [ale][]
- **Tool**: `stack install hlint`
- **Tool**: `stack build ghc-mod`

This is where the Neovim dependency starts to creep up, though Vim 8 is an
acceptable alternative for now. ALE stands for "Asynchronous Lint Engine." It's
like Syntastic, but asynchronous[^neomake].

There are a number of Haskell engines that ship with ALE. For example, it will
be able to show errors if all that's installed is Stack. My preferred tools to
use for Haskell with ALE are `hlint` and `ghc-mod`.

- `hlint` is a linter for Haskell. It warns about silly things like `if x then
  True else False`.
- `ghc-mod` is a tool that can check files for compiler errors

Note that we want to **stack build** ghc-mod, not stack install it. The former
ensures that `ghc-mod` is local to the current stack project, so that the
version never gets out of sync with your project.

Once we've installed all these programs, the setup is minimal. We'll be able to
see `hlint` and `ghc-mod` errors in our quickfix window right away.

```vim ALE setup
let g:ale_linters.haskell = ['stack-ghc-mod', 'hlint']
```

## Intero: The Pièce de Résistance

- **Plugin**: [intero-neovim][]

Intero is a complete development program for Haskell. Probably the best way to
introduce it is with this asciicast:

<p align="center">
  <a href="https://asciinema.org/a/128416">
    <img
      width="700px"
      alt="Intero for Neovim asciicast"
      src="https://asciinema.org/a/128416.png">
  </a>
</p>

Intero is designed for stack, sets itself up automatically, has point-and-click
type information, and lets you jump to definitions. On top of it all, it uses
Neovim to communicate back and forth with a terminal buffer so that you get a
GHCi buffer **right inside Neovim**.

Developing with the REPL in mind helps me write code better. Only top-level
bindings are exposed in the REPL, so I write more small, testable functions.
See here for more reasons [why the REPL is awesome][haskell-repl].

On top of providing access to the REPL, Intero provides about a dozen
convenience commands that shell out to the REPL backend. Being able to reload
your code in the REPL---from Vim, with a single keystroke!---is a huge boon when
developing.

Intero sets up no mappings by default, so here are mine. I also flip two config
variables to make Intero a little faster:

```vim Intero settings
" Prefer starting Intero manually (faster startup times)
let g:intero_start_immediately = 0
" Use ALE (works even when not using Intero)
let g:intero_use_neomake = 0

augroup interoMaps
  au!

  au FileType haskell nnoremap <silent> <leader>io :InteroOpen<CR>
  au FileType haskell nnoremap <silent> <leader>iov :InteroOpen<CR><C-W>H
  au FileType haskell nnoremap <silent> <leader>ih :InteroHide<CR>
  au FileType haskell nnoremap <silent> <leader>is :InteroStart<CR>
  au FileType haskell nnoremap <silent> <leader>ik :InteroKill<CR>

  au FileType haskell nnoremap <silent> <leader>wr :w \| :InteroReload<CR>
  au FileType haskell nnoremap <silent> <leader>il :InteroLoadCurrentModule<CR>
  au FileType haskell nnoremap <silent> <leader>if :InteroLoadCurrentFile<CR>

  au FileType haskell map <leader>t <Plug>InteroGenericType
  au FileType haskell map <leader>T <Plug>InteroType
  au FileType haskell nnoremap <silent> <leader>it :InteroTypeInsert<CR>

  au FileType haskell nnoremap <silent> <leader>jd :InteroGoToDef<CR>
  au FileType haskell nnoremap <silent> <leader>iu :InteroUses<CR>
  au FileType haskell nnoremap <leader>ist :InteroSetTargets<SPACE>
augroup END
```

Intero takes a little getting used to, so be sure to read the docs for some
sample workflows.


## Wrap Up

With these tools, I feel empowered rather than hindered when I sit down to write
some Haskell.

- It uses Stack whenever possible, so things Just Work.
  - As a consequence, this means all these plugins work with the implicit global
    Stack project!
- It scales up in power:
  - from simple syntax highlighting to a **REPL in the editor**!
  - from manual indentation to an indentation sledgehammer

{% include jake-on-the-web.markdown %}

[stack]: https://www.haskellstack.org/
[neovim]: https://github.com/neovim/neovim

[gist-final]: https://gist.github.com/jez/ed4dc673385c82243805a19797a37ff6

[haskell-vim]: https://github.com/neovimhaskell/haskell-vim
[pr-98]: https://github.com/neovimhaskell/haskell-vim/pull/98

[vim-hindent]: https://github.com/alx741/vim-hindent
[hindent]: https://github.com/commercialhaskell/hindent
[stylish-haskell]: https://github.com/jaspervdj/stylish-haskell

[ale]: https://github.com/w0rp/ale
[intero-neovim]: https://github.com/parsonsmatt/intero-neovim
[haskell-repl]: http://chrisdone.com/posts/haskell-repl


[^recomp]: Tip: sometimes it's handy for [force a complete recompile](https://github.com/commercialhaskell/stack/blob/3d29b8c/doc/faq.md#why-doesnt-stack-rebuild-my-project-when-i-specify---ghc-options-on-the-command-line).

[^logo]: If you still aren't convinced, the [Neovim logo](https://github.com/neovim/neovim#readme) makes for a much better laptop sticker than Vim's.

[^neovimhaskell]: While listed under "neovimhaskell" on GitHub, this plugin works with normal Vim, too.

[^one-tool]: Chris Done explains the appeal of solving style issues with tooling for Haskell well. The moral of the story is that hindent version 5 ships with only the most popular style formatter in an effort to arrive at a singular Haskell style: <http://chrisdone.com/posts/hindent-5>

[^neomake]: Some people are familiar with Neomake for this task. However, Neomake is much more minimal than ALE. Neomake basically only builds, whereas ALE is more configurable and hackable.
