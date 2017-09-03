---
layout: post
title: "Vim as a Man Page Viewer"
date: 2014-12-20 20:17:46 -0600
comments: false
categories: [vim, bash]
description: >
  Use vim as a man page viewer to get better syntax highlighting, scroll
  quickly with a mouse, tabs, and more.
share: false
permalink: /:year/:month/:day/:title/
---

Man pages are an essential part of every developer's workflow. Unfortunately,
the default system pager `less` isn't the best interface. That's why I wrote a
Vim plugin and a short shell function to take care of opening man pages in Vim.

<!-- more -->

## The Plugin

If you're eager to dive right into the source or to install the plugin, head on
over to the [GitHub repository][vman-github]. It's a whopping 32 SLOC, so feel
free to peek under the hood.

## Why?

You might be thinking, "But Jake, `man` works just fine for me, why would I
switch?" I'm glad you asked!

### Mouse Support

The first reason why I was interested in getting man pages to open in Vim was
because I wanted to be able to scroll with the mouse. When I have to read man
pages for a long time, usually as a part of some more all-encompasing bit of
research, I find scrolling to be a much better interface for quickly perusing
the content of a man page.

### Syntax Highlighting

As it turns out, man pages have a syntax to them, and Vim does a pretty
excellent job at highlighting them. Rather than talk about it, here are some
screenshots. Note how code samples (C system calls and library functions) are
also syntax highlighted appropriately.

```bash Example 1
vman vim
```

{% img /images/vim.1.png %}

```bash Example 2
vman 3 printf
```

{% img /images/printf.3.png %}

### All the benefits of Vim

While `less` makes a good effort to emulate certain Vim keybindings (or maybe
it's the other way around, I don't know which came first), `less` certainly
falls short of the full power of Vim.

For example, once you've opened a man page in Vim, you can open a new tab or
split side-by-side with the man page. Especially if you're switching between Vim
and the man page often, being able to open man pages in tabs or splits is
invaluable.

## Mine doesn't look like yours!

A couple of my other plugins are showing in the screenshots above. I'm using the
[Solarized Dark color scheme][vim-colors-solarized], the plugin
[vim-airline][vim-airline] to take over the statuslines at the very top and
bottom, and iTerm2 on Mac OS X 10.10.

You can see my complete configuration [on GitHub][dotfiles].

## Feedback

As a matter of fact, this was my first Vim plugin! If you notice anything out of
place, even if it's a small detail, I'd love to hear it. Make no assumptions
about the reasoning behind why certain decisions were made, because I have none
XD


[vman-github]: https://github.com/jez/vim-superman

[vim.1]: /images/vim.1.png
[printf.3]: /images/printf.3.png

[vim-colors-solarized]: https://github.com/altercation/vim-colors-solarized
[vim-airline]: https://github.com/bling/vim-airline

[dotfiles]: https://github.com/jez/dotfiles
