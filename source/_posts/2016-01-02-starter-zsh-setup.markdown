---
layout: post
title: "Starter Zsh Setup"
date: 2016-01-02 23:14:16 -0600
comments: false
categories: [dotfiles, zsh]
description: >
  Zsh has given me so much mileage with respect to efficiency at the command
  line. Looking back I'm a little sad I didn't switch to it sooner. One of the
  reasons why it took so long was that I didn't know where to start; with this
  in mind, I've collected some of the zsh-specific bits of my dotfiles into one
  place to help people hit the ground running.
share: false
redirect_from:
- /2016/01/02/starter-zsh-setup/
---

Zsh has given me so much mileage with respect to efficiency at the command line.
Looking back I'm a little sad I didn't switch to it sooner. One of the reasons
why it took so long was that I didn't know where to start; with this in mind,
I've collected some of the zsh-specific bits of my dotfiles into one place to
help people hit the ground running.

<!-- more -->

To cut to the chase, you can find my [starter zshrc][starter] on GitHub. It
contains usage information as well as loads of inline comments to give you a
line-by-line summary.

Note: it's an _starter_ zshrc. What I mean by this is that it's more of
a skeleton. It's been crafted with the assumption that you're coming from bash
and you already have some bash config that you're weary to part with. The
content here aims to be minimally invasive, and since zsh is largely compatible
with bash, the rest of your config should fit right in.


## Going Further

I have even more zsh-specific and general configuration nuggets in my personal
dotfiles, which are [also on GitHub][dotfiles]. I add to them nearly every day,
and I'm pretty fond of them if I do say so myself. You might want to read
[Noteworthy Dotfile Hacks][hacks] if you're looking for a quick overview of some
snippets and features I've collected into my dotfiles.



[starter]: https://github.com/jez/starter-zshrc
[dotfiles]: https://github.com/jez/dotfiles
[hacks]: http://blog.jez.io/2015/03/10/noteworthy-dotfile-hacks/
