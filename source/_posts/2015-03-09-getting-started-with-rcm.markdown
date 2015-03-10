---
layout: post
title: "Getting Started with RCM"
date: 2015-03-09 18:30:39 -0500
comments: true
categories: [dotfiles]
description: >
  An overview of how I use the software suite rcm to manage my dotfiles across
  multiple machines.
image:
  feature: /images/blue-ring.png
share: true
---

I recently rewrote most of my dotfiles to clean them up and in the process
decided to take a renewed look at using [rcm][rcm]'s array of features to manage
syncing my dotfiles across multiple servers and hosts.

<!-- more -->

## Installation and Usage

Thoughbot has written some excellent documentation for rcm, including a whole
set of man pages and a [nice blog post][rcm] that runs through its core
features. As far as [installation][rcm-install] goes, there's a package for just
about every platform on top of the standard autotools, so you should have no
problem getting up and running.

Rather than just run through the same stuff, I'm going to walk through some of
the places where my experience varied from the examples given in the
documentation.


## Background

I've already been using rcm for a while now, though my setup was a little
non-standard as far as rcm installations go; instead of using the system built
into rcm for managing host-specific configuration files, I had [huge case
statements][case] littering my config files. After starting to get a little
traffic for [some of my other configuration work][ide], I decided it was time to
make my config files something worth looking at.

Thus, given the state of my old files, much of my effort this time around
were spent refactoring my current setup to increase modularity and get it to
integrate nicely with rcm. I think that this use case is a little
under-documented and lacking in first-class support in the suite, so I'll talk
about how I got around this later on. That being said, if you're coming from no
dotfiles management software or are interested in trying out something new,
you'll have a much smoother experience.


## Goals

My two goals for the refactor that I mentioned above were to

- make everything modular, so that people could more easily pick and choose
  pieces from my dotfiles to include in theirs, and
- make it easy to swap around host-specific configurations.

While the work required to achieve this setup was a bit hairy, maintaining it
should be straightforward from now on.

If you haven't taken a second to peruse some of the [documentation][rcm7] yet,
it probably wouldn't hurt to do so now. It's about to get technical.


## Host-independent files

I started this time around with the host independent files, because they
required no real refactoring. Linking these up was a simple matter of running
commands that looked like

```
$ mkrc <rc-file>
```

I ran this on files like my `.vimrc`, `.tmux.conf`, `.ackrc`, and other simple
files. I also handled my `.vim/` folder in this step, but slightly differently.
The default rcm behavior is to create symlinks when given a single file, and to
recursively descend and create symlinks when given a folder. For folders like my
`.vim/` folder, which can get pretty large pretty quickly, I used the `-S`
option to force rcm to symlink the directory:

```
$ mkrc -S .vim/
```

The first time I ran `mkrc`, it automatically created a folder called
`~/.dotfiles`, which is where all my dotfiles files will live from now on. Then,
every time `mkrc` is run, it moves the file into this folder and creates a
symbolic link where it use to exist. I always thought this was a curious name
for the program, "make rc file", but really what I just mentioned is all there
is to it: `mkrc` _moves_ and _links_ an rc file.

{% img /images/mkrc-host-independent.png %}

Above you can see the results of this first step on a couple files: my `.vimrc`
and my `.vim/` folder. You can see that where there once were a file and a
folder, there are now two symbolic links, which point to the moved files inside
of my `.dotfiles/` directory.


## Host-dependent files

Next up are obviously the host-dependent files, though we can split this
category once more based on which need to be refactored.

### Just Add Water

For my host-dependent
files that didn't need to be refactored, like my `.ssh/config` and my
`.gitconfig` (files which, by the way, I wasn't tracking at all before this
rewrite), I just ran the following command:

```
$ mkrc -o .gitconfig
```

When I'm on my Mac, this goes through the same move + link procedure described
above, but it moves the file into the `~/.dotfiles/host-Jacobs-MacBook-Air/`
subfolder.


### Refactor and Profit

Finally, I dealt with the piece of my dotfiles that was sorely lacking a
refactor: my `.zshrc`. For this, I took a cue from [Zach Holman's
dotfiles][holman] organization and broke up my zshrc into it's components, like
`aliases.sh`, `colors.sh`, and more. Most important of these components was
the `host.sh` file, which contained all the host-specific configurations that I
was doing. Whenever I deploy my `.zshrc` on a new host now, rcm will put a
`host.sh` file in a location where my `.zshrc` knows where to look, but the
contents of that file change depending on the host. Getting the many `host.sh`
files in place is where I think mkrc's power can be improved.

The `mkrc -o` command takes an option that lets you specify a host explicitly
(`-B <hostname>`) rather than calculating it with the `hostname` command, but it doesn't
let you specify that you'd just like to move the file, rather than move and link
it. As such, when I was refactoring, I created a bunch of files:
`host-Jacobs-MacBook-Air.sh`, `host-ghost.zimmerman.io.sh`, etc., creating one
`host-<something>.sh` file for each host that I needed to deploy my dotfiles to.
Then, for each of these files, I

- ran `mkrc -o -B <hostname> host-<hostname>.sh`
- removed the link created by `mkrc` (I skipped this step the last time around,
  when I had just linked the correct `host.sh` file for the host I was working
  on)
- renamed the file that rcm created in the `.dotfiles/host-<hostname>/` folder
  to just `host.sh`.

Since there were a bunch of different host-specific files in my case, this
process was a little tedious. It'd have been nice if there was an option to
automate my use case, but I'm not sure if it's common enough to warrant
the additional complexity, especially considering it's a one-time cost.

In any case, with all this in place, I had finally met my two goals: everything
was modular, and host-specific configurations were clearly defined and easily
deployable.


## Up Next

If you're reading this and wondering where to go next, you could:

- take a dive into the rcm documentation to get started applying it to your own
  set of dotfiles
- browse my [new-and-improved dotfiles][dotfiles] repository on GitHub
- wait for an upcoming post where I point out some of the noteworthy things I've
  added in my dotfiles

If you're using rcm or trying to get started with it but are having issues, feel
free to drop questions in the comments and I'll see if I can't help sort things
out.


{% include jake-on-the-web.markdown %}


[rcm]: https://robots.thoughtbot.com/rcm-for-rc-files-in-dotfiles-repos
[rcm-install]: https://github.com/thoughtbot/rcm#installation
[case]: https://github.com/jez/dotfiles/blob/6beee7eb426a21102da174f65d1a706bedc28b57/zshrc#L135-L204
[ide]: https://github.com/jez/vim-as-an-ide
[rcm7]: http://thoughtbot.github.io/rcm/rcm.7.html
[holman]: https://github.com/holman/dotfiles
[dotfiles]: https://github.com/jez/dotfiles
