---
layout: post
title: "Running a VPS, Log 1: Managing Dotfiles Across Machines"
date: 2014-06-19 23:10:51 -0400
comments: false
categories: [git, best practices, summer projects, dotfiles]
description: An overview of how I use rcm and git to seamlessly manage my dotfiles and configuration scripts across 10+ remote servers.
share: false
permalink: /:year/:month/:day/:title/
published: false
---

You could say I'm a bit of a geek when it comes to configuring my terminal environment; this obsession has led me to concoct ever-elaborate setup scripts and configuration files. On top of this, between my laptop's multiple boot environments, the servers I use for school, work, and ScottyLabs, and now [metagross](/2014/06/19/running-a-vps-log-0), keeping my configuration files in sync is a must. I handle it swiftly using a combination of git and rcm.

<!-- more -->

# My Scripts
I've put a decent amount of time into my dotfiles. I like to think they're pretty good. That being said, I'm not about to go over every piece of them, because that would bore even me. I might come back to these pieces in a series on getting started with the terminal (aimed at incoming CS freshmen and other up-and-coming hackers), but for now, a link will suffice.

### [jez/dotfiles](https://github.com/jez/dotfiles/)

# rcm + git
rcm, short for rc file (as in .bash<b>rc</b>, .vim<b>rc</b>) management, is a tool that manages symlinks between dotfiles in one directory and your home directory. This is cool because, once all your config files contained in one folder, they can be tracked with git for version control without having to put your entire `$HOME` directory inside a git repo.

On a single machine, rcm works like this. You have one directory (usually `~/.dotfiles`, but configurable to any directory) which stores all the config files. In here, all files which are meant to be tracked and symlinked do _not_ include the prefixed '`.`'; instead, it is added as part of the linking process. After installation, which is easily handled through the brew formula, the .deb, or the Makefile, there are a couple of new tools available.

The first worth mentioning is `man 7 rcm`, which documents what was just installed. Taking a glance at this page, we see that rcm is actually a suite of tools: `lsrc`, `mkrc`, `rcdn`, and `rcup`. While all these tools are useful, the most important is `rcup`. After collecting all your dotfiles into `~/.dotfiles`, simply executing `rcup` symlinks all the necessary files to their appropriate locations.

From here, you get all the benefits of git, like pushing to GitHub, collaborating with others, lightweight branching, and syncing files easily even when your workflow is distributed across many servers.

# Caveats
To be fair, I don't use `rcm` in the way I think it's creators imagined it would be used. Specifically, the software includes certain provisions to designate which files should affect various machines using a tag system. While it could possibly work, in my mind it's much more tedious than what I've come up with.

Succinctly, the issue is this: when cloning a repo and running `rcup` for the first time, you can't easily say "this is my VPS, it's running Debian GNU/Linux, has these system binaries installed, and therefore should start up using these methods and scripts". For this, we're on our own.

# Installation
The solution I came up with regarding a multiple-environment workflow deals with handling all the necessary machine-dependent configuration within my dotfiles _themselves_. That way I can minimize code reuse and have everything in one convenient file. As a result, [my bash_profile](https://github.com/jez/dotfiles/tree/master/bash_profile) is a bit lengthy at about 300 lines, and it has three large case statements, but I make all this up through deployment. Deployment is __incredibly__ swift. Again, You can take a look at the file to see how it works, but when I had finished [locking down my server](/2014/06/19/running-a-vps-log-1), these are the only configuration commands I had to run:

<figure>

```{.bash .numberLines}
# install rcm using deb and dpkg
$ wget https://thoughtbot.github.io/rcm/debs/rcm_1.2.3-1_all.deb
$ sudo dpkg -i rcm_1.2.3-1_all.deb

# clone dotfiles down, into the ~/.dotfiles directory
$ git clone https://github.com/jez/dotfiles ~/.dotfiles

# make the symlinks
$ rcup
```

<figcaption>Installing rcm and dotfiles</figcaption>
</figure>

Voilà! After that, I had my sick bash prompt, my [snazzy update function](/2014/06/11/update-your-software-its-the-law/), my delightful vim colorscheme, solarized dir colors--the list goes on and on.

Sure, it's taken a bit of effort to get the point where I can run these commands and have it Just Work, but doing that work once means that from now on, whenever I sit down at a new work computer, a new VPS, a new laptop, or some other workstation, I'm only a few commands away from my favorite settings.

