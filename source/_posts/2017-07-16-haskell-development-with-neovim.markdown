---
layout: post
title: "Haskell Development with Neovim"
date: 2017-07-16 13:45:31 -0500
comments: false
share: false
redirect_from:
- /2017/07/16/haskell-development-with-neovim/
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

I use [Haskell Stack][stack] exclusively. Stack's goal is reproducible builds,
which means that in general, things Just Work.

I also use [Neovim][neovim], rather than normal Vim. Usually, my justification
is ideological rather than technical. However, for Haskell my setup **requires**
Neovim. Fear not! Neovim is feature-packed and also very stable. I love Neovim,
and I'll be writing more about why in a future post.

By the way, new to Vim plugins? I happen to have [just the post for
you][vim-as-an-ide]!

<!-- TODO(jez): Update with link to Neovim post -->

## Overview

We're going to move in order of increasing complexity. That said, even the most
"complex" plugin here is actually quite painless to set up. By the end, we'll
have a complete development experience! Coming up:

- syntax highlighting & indentation (**[haskell-vim][]**)
- auto-formatting & style (**[hindent][], [stylish-haskell][]**)
- quickfix and sign column support (**using [ale][]**) for:
  - linter style suggestions (**hlint**)
  - compiler errors and warnings (**ghc-mod**)
- Type inspection, REPL integration, and more! (**[intero-neovim][]**)

To keep things concise, I've moved all the relevant configuration to the end of
the post. For now, let's start at the top.

<!-- TODO(jez) Demonstrate everything with an asciicast -->

## Syntax Highlighting & Indentation

- **Plugin**: [haskell-vim][haskell-vim][^neovimhaskell]

Vim's default Haskell filetype plugin is pretty lack luster. Everything is blue,
except for strings which are colored like comments, and keywords which are
colored like constants. Indentation is wonky in some edge cases, and isn't
configurable.

This plugin corrects all that. It's the filetype plugin for Haskell that
**should** ship with Vim.

Not only does it come with saner defaults, it also comes with more config
options, especially for indentation. This is important because it lets me
tweak the automatic indentation to my own personal style.

(Remember: all the config is at the end of the post.)

## Auto-formatting and Indentation

- **Plugin**: [vim-hindent][]
- **Tool**: `stack install hindent`
- **Tool**: `stack install stylish-haskell`

For small projects, I have an idea of what style I like best. However, for
larger projects it's unfair to ask contributors that they learn the ins and outs
of my style. Situations like these call for automated solutions.

`go fmt` famously solved this problem for Golang by building the formatting tool
into the compiler. For Haskell, there's [hindent][][^one-tool]. `hindent` can be
installed through Stack, and `vim-hindent` is a Vim plugin that shims it.

But I said I'm partial to my own style in personal projects. There's another
Haskell formatter that's much less invasive: [stylish-haskell][]. It basically
only reformats `import`s, `case` branches, and record fields, aligning them
vertically. And in fact, it's possible to use this alongside `hindent`.

With these three tools, I can pick the right tool for the job:

- **Hand saw**: let `haskell-vim` config control the indentation
- **Table saw**: run `stylish-haskell` only
- **Chainsaw**: run `hindent` only
- **Chainsaw, then sand paper**: run `hindent`, then `stylish-haskell`

Getting them to play together requires a bit of config, so I've included mine at
the end of the post.

## Quickfix & Sign Columns

- **Plugin**: [ale][]
- **Tool**: `stack install hlint`
- **Tool**: `stack build ghc-mod`
  - N.B.: This is *build* not *install* here[^build].

This step requires *either* Neovim or Vim 8; ALE stands for "Asynchronous Lint
Engine," so it's using the new asynchronous job control features of these two
editors. It's like an asynchronous Syntastic[^neomake].

ALE ships with a number of Haskell integrations by default. For example, it can
show errors if only Stack is installed. I prefer enabling two of ALE's Haskell
integrations: `hlint` and `ghc-mod`.

- `hlint` is a linter for Haskell. It warns me when I try to do silly things
  like `if x then True else False`.
- `ghc-mod` is a tool that can check files for compiler errors.

The beauty of ALE is that it works almost entirely out of the box. The only real
setup is to tell ALE to use only these two integrations explicitly. I've
included the one-liner to do this in the config at the bottom.

## Intero: The Pièce de Résistance

- **Plugin**: [intero-neovim][]

Intero is a complete development program for Haskell. It started as an Emacs
package, but has been ported almost entirely to Neovim. Probably the best way to
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
type information, and lets me jump to identifier definitions. On top of it all,
it uses Neovim to communicate back and forth with a terminal buffer so that I
get a GHCi buffer **right inside Neovim**. For Emacs users, this is nothing new
I'm sure. But having the REPL in my editor continues to blow my mind 😮.

Developing with the REPL in mind helps me write better code. Only top-level
bindings are exposed in the REPL, so I write more small, testable functions.
See here for more reasons [why the REPL is awesome][haskell-repl].

On top of providing access to the REPL, Intero provides about a dozen
convenience commands that shell out to the REPL backend asynchronously. Being
able to reload my code in the REPL---from Vim, with a single keystroke!---is a
huge boon when developing.

Intero takes a little getting used to, so be sure to read the docs for some
sample workflows. Intero also sets up no mappings by default, so I've included
my settings below.

## The Eagerly-Awaited Config

And without further ado...

```vim
" ----- neovimhaskell/haskell-vim -----

" Align 'then' two spaces after 'if'
let g:haskell_indent_if = 2
" Indent 'where' block two spaces under previous body
let g:haskell_indent_before_where = 2
" Allow a second case indent style (see haskell-vim README)
let g:haskell_indent_case_alternative = 1
" Only next under 'let' if there's an equals sign
let g:haskell_indent_let_no_in = 0

" ----- hindent & stylish-haskell -----

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

" ----- w0rp/ale -----

let g:ale_linters.haskell = ['stack-ghc-mod', 'hlint']

" ----- parsonsmatt/intero-neovim -----

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

## Wrap Up

With these tools, I feel empowered (rather than hindered) when I sit down to
work with Haskell.

- The entire setup uses Stack, so things Just Work.
  - As a consequence, everything works with the implicit global Stack project!
- It scales up in power:
  - From simple syntax highlighting and manual indentation...
  - to an indentation chainsaw and a **REPL embeded in the editor**!
- I can take full advantage of all my tools working together, leading to cleaner
  code and fewer frustrations.

Now that I'm finally at a point where I can stop fretting about my Haskell
setup, I'll have more time to explore the language and write about my
experience.

Haskell-the-language isn't quite on the same level as SML-the-language, but it's
far and above when comparing by tooling support. I'm looking forward to taking
advantage of that!


[stack]: https://www.haskellstack.org/
[neovim]: https://github.com/neovim/neovim
[vim-as-an-ide]: https://github.com/jez/vim-as-an-ide

[gist-final]: https://gist.github.com/jez/ed4dc673385c82243805a19797a37ff6

[haskell-vim]: https://github.com/neovimhaskell/haskell-vim

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

[^build]: We want to install `ghc-mod` once in every project. It can be done globally, but it might get out of sync with the current project.

[^neomake]: Some people are familiar with Neomake for this task. However, Neomake is much more minimal than ALE. Neomake basically only builds, whereas ALE is more configurable and hackable.
