---
# {{{
# vim:tw=72:fdm=marker
layout: post
title: "Exploring Ruby with clangd"
date: 2020-07-21 15:40:23 -0700
comments: false
share: false
categories: ['ruby', 'vim', 'debugging']
description: >
  I've managed to get LSP-based IDE features powered by [clangd] working
  for the Ruby VM's source code (in my case, in Vim). Here's how I did it!
strong_keywords: false
fancy_blockquotes: true
# }}}
---

I've managed to get LSP-based IDE features powered by [clangd] working
for the Ruby VM's source code (in my case, in Vim). Here's how I did it!

[clangd]: https://clangd.llvm.org/

<!-- more -->

I've been making a point to learn more about [things I depend
on](/search-down-the-stack/) recently. Today, that means learning about
Ruby. And what better way to learn than to check out the source code,
and jump around?

[clangd] is an editor-agnostic language server that uses the [Language
Server Protocol](https://langserver.org/) to power IDE-like features in
your preferred text editor. All it needs is a `compile_commands.json`,
which is basically a mapping of filename to options to pass to `clang`
so that it knows things like which warnings to enable and where to
search for header files.

[clangd] works best for projects built using `cmake`, but the Ruby VM
doesn't use `cmake`. Regardless, we can make a `compile_commands.json`
file by using [Bear] to trace the execution of a Ruby build, and use the
trace information to write out a `compile_commands.json` file.

[Bear]: https://github.com/rizsotto/Bear

## Steps

I could only get these steps to work for Linux, as the Bear README
mentions that on macOS you have to disable System Integrity Protection
to get it to work.

### 1. Install [Bear]

I describe how I built Bear from source in the Appendix.

### 2. Clone the Ruby source code.

```bash
git clone https://github.com/ruby/ruby
cd ruby
```

### 3. Configure the Ruby build.

We have to tell the `configure` script to use Clang to compile (or
if you're confident that your system compiler toolchain is Clang,
you can just run `./configure`).

```bash
# Create the ./configure file
autoconf
# This only works when using clang to build Ruby
./configure CC=clang
```

### 4. Use `bear` to invoke `make`

Bear will use a dynamically preloaded library to trace system calls
that exec `clang` processes, looking at things like the command line
arguments given to Clang.

```bash
bear make
```

### 5. That's it!

The output is `./compile_commands.json`, which should be non-empty. If
it's empty or just has `[]`, it didn't work. There's some
troubleshooting in the [Bear] README.

The `compile_commands.json` file will be consumed by `clangd` in your
editor. Check <https://langserver.org> to find an LSP client for your
preferred editor, and follow its setup instructions.

Once you've built the `compile_commands.json` file and configured your
editor to use LSP with `clangd`, you should be able to do things like
Jump to Definition and Hover on the Ruby source code!


## Appendix: Building Bear from source

This is probably common knowledge for people who use `cmake` regularly,
but this is how I built Bear from source, because I built it on a
machine where I didn't have root so I couldn't write to `/usr/local`.

```bash
git clone https://github.com/rizsotto/Bear
cd Bear
mkdir build
cd build

# Install to $HOME/.local/bin instead of /usr/local/bin
cmake .. "-DCMAKE_INSTALL_PREFIX=$HOME/.local"
make -j$(nproc)
make install

# → $HOME/.local/bin/bear exists now
```

## Appendix: LSP in Neovim with LanguageClient-neovim

I use Neovim. My preferred LSP client is [LanguageClient-neovim]. Here's
the parts of my Neovim config files that setup `clangd`:

[→ `vim/plug-settings.vim` in jez/dotfiles](https://github.com/jez/dotfiles/blob/865a74d93d8ab1c28713ae0dcd53797b6c26dc6a/vim/plug-settings.vim#L576-L587)

[LanguageClient-neovim]: https://github.com/autozimu/LanguageClient-neovim
