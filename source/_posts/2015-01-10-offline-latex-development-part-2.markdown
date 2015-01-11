---
layout: post
title: "Offline LaTeX Development - Part 2"
date: 2015-01-10 16:00:00 -0600
comments: true
categories: [latex, terminal, vim, osx]
description: >
  LaTeX development with Vim and the command line, now featuring split-pane
  windows!
image:
  feature: /images/latex-amethyst.png
share: true
---

I've already written about how I develop LaTeX offline in Vim using GNU Make.
Recently, though, I found a tool that implements another feature that GUI
editors had to themselves: splitting panes.

<!-- more -->

## [Offline LaTeX Development][part1]

If you missed it, check out my previous post here before reading on. There's a
lot of handy stuff there!

## Split Panes

Out of the box, tools like ShareLaTeX and TeXShop feature split pane editing:
you can have your LaTeX on one half of the screen and the PDF on the other.
Previously, I justified not having this feature with the reasoning that the
`:WV` binding (something I explained [here][part1]) immediately opened up the
PDF and the windows switched.

However, I read about a tool called [Amethyst][amethyst] on Hacker News the
other day and immediately realized it's potential for improving my LaTeX setup.
Amethyst is a tool that strives to be a tiling window manager like xmonad for OS
X. At times it falls short of this goal, but for the most part it works really
well. Just open up two apps, like MacVim and Preview, and it'll show them
side-by-side with no added effort. There are also plenty of keybindings to
manipulate the window arrangements.

Here's a screenshot of what the new setup looks like:

{% img /images/latex-amethyst.png %}

After looking into it a little more, it looks like there are other OS X tools
for spitting the screen into two panes, like [BetterTouchTool][btt], though I
haven't actually tried any of them out.

{% include jake-on-the-web.markdown %}

[part1]: /2014/10/06/offline-latex-development/
[amethyst]: http://ianyh.com/amethyst/
[btt]: http://www.bettertouchtool.net/
