---
layout: post
title: "Noteworthy Dotfile Hacks"
date: 2015-03-10 00:22:33 -0500
comments: false
categories: [dotfiles, zsh, git, vim, tmux]
description: >
  Because it's much easier (for me at least) to read a blog post than read the
  code.
share: false
---

There are some hidden gems in my dotfiles. This is a post to showcase them,
putting them front and center.

<!-- more -->

I often tell people "oh, and you can also go check out my dotfiles repository
for more cool configurations" when I'm giving out dotfiles advice. If someone
gave me this advice, I know I wouldn't follow up, even if I had the utmost awe
for the recommender. Drudging through config files isn't all that fun, even
though they can do fun things. Why not get rid of the drudgery?

This post is designed to bring the coolest parts of my dotfiles to the top. It's
organized by topic, so feel free to skip around.

__Note__: throughout this post, I'll be linking to my dotfiles _at a specific
commit_ on GitHub. While this solves the problem of line-level links breaking on
updates, it means that you'll almost certainly be looking at out-dated code.
Make sure to check out the corresponding file on the `master` branch for the
most up-to-date version.

Also, I [just wrote][modular] about one of my biggest dotfile hacks: using rcm
to keep my dotfiles in sync across machines. Be sure to give it a read if you're
running into that problem.

## `tmux`

I have a lot of cool stuff going on in my `.tmux.conf`

- I [bind the prefix key to `C-f`][tmux-prefix], something which I haven't seen
  many people do.  I've never had a problem with it conflicting with commonly
  used shortcuts, and it's incredibly easy to press (compared with the common
  options of `C-a` and `C-b`)
- I integrate with two Vim plugins:
  - [vim-tmux-navigator][vim-tmux-navigator], which lets you jump between vim
    splits and tmux splits as if they were the same thing
  - [tmuxline][tmuxline], which makes my tmux status bar look just like Vim with
    vim-airline (it even pulls down the colors from your Vim configuration!).

[tmux-prefix]: https://github.com/jez/dotfiles/blob/0ca7dfb042e8d0e6790e7142487812517b5a4209/tmux.conf#L1-L4
[vim-tmux-navigator]: https://github.com/jez/dotfiles/blob/0ca7dfb042e8d0e6790e7142487812517b5a4209/tmux.conf#L18-L27
[tmuxline]: https://github.com/jez/dotfiles/blob/0ca7dfb042e8d0e6790e7142487812517b5a4209/tmux.conf#L48-L49


## `dircolors`

I use the GNU `dircolors` command to change the colors output by the `ls`
program. After running `brew install coreutils` on OS X, I'm able to see the
colors thanks to [this file][dircolors] and [this snippet][gnubin] in my zshrc.

{% img https://raw.githubusercontent.com/huyz/dircolors-solarized/master/img/screen-dircolors-in-iTerm2-solarized_dark.png %}

(image from the [dircolors-solarized][dircolors-solarized] repository on GitHub)

[dircolors]: https://github.com/jez/dotfiles/blob/0ca7dfb042e8d0e6790e7142487812517b5a4209/dircolors
[gnubin]: https://github.com/jez/dotfiles/blob/0ca7dfb042e8d0e6790e7142487812517b5a4209/host-Jacobs-MacBook-Air/util/host.sh#L19-L21
[dircolors-solarized]: https://github.com/seebi/dircolors-solarized


## `gitconfig`

I talked about this [in a previous post][glla], but I have some [special
settings][decorate] in my global gitconfig for adding colored decoration to git
log commands. Here's a screenshot from that post:

{% img /images/glla-tartanhacks.png %}

[glla]: /2015/01/16/mastering-git-log-for-collaboration/
[decorate]: https://github.com/jez/dotfiles/blob/eba0202443de6bcc171dbe6bc133fa9fe02357f7/host-Jacobs-MacBook-Air/gitconfig#L20-L24

## `aklog cs.cmu.edu`

For my friends at CMU, I have `aklog cs.cmu.edu` in [my ~/.zshenv][cmu-zshenv],
which gets run even when you log in interactively (like what happens when you
`scp` something), so that I can copy files from my local machine to the SCS AFS
space, which is useful for doing things like making handins. Note that the file
linked to above is a host-specific file that only "exists" for me on Andrew
machines. You can read more about my setup [in my
previous post][modular].

[cmu-zshenv]: https://github.com/jez/dotfiles/blob/eba0202443de6bcc171dbe6bc133fa9fe02357f7/host-andrew/util/host.zshenv#L1
[modular]: /2015/03/09/getting-started-with-rcm/

## zsh-syntax-highlighting

I use a [zsh plugin][zsh-syntax] to syntax highlight my commands as I type them
on the command line, similar to how the fish shell does it. It does various
things, like coloring the command red or green based on whether it exists,
underlines filenames that exist, highlights filenames that might be misspelled
in yellow, highlights built-ins like `if` and `for` in orange, etc.

Here are some examples from my setup:

{% img /images/zsh-syntax-highlighting-for-loop.png %}

{% img /images/zsh-syntax-highlighting.png %}

[zsh-syntax]: https://github.com/jez/dotfiles/blob/eba0202443de6bcc171dbe6bc133fa9fe02357f7/util/misc.zsh#L79-L80

## Automatic Dotfile Updates

I wrote a pretty robust script that reminds me to update my dotfiles and my
system regularly. All it does is remind me to check for system updates once
every 24 hours, but it works so well that I had updated my system `bash` version
before I even read about Shell Shock!

The relevant links are [here][auto-update] for the core script that I [source in
my zshrc][update-zsh], and then the following host specific links:
- [here][update-mac] for my MacBook
- [here][update-ubuntu] for my Ubuntu VPS

[auto-update]: https://github.com/jez/dotfiles/blob/eba0202443de6bcc171dbe6bc133fa9fe02357f7/util/auto-update.sh
[update-zsh]: https://github.com/jez/dotfiles/blob/eba0202443de6bcc171dbe6bc133fa9fe02357f7/zshrc#L44-L45
[update-mac]: https://github.com/jez/dotfiles/blob/eba0202443de6bcc171dbe6bc133fa9fe02357f7/host-Jacobs-MacBook-Air/util/host.sh#L69-L86
[update-ubuntu]: https://github.com/jez/dotfiles/blob/eba0202443de6bcc171dbe6bc133fa9fe02357f7/host-ghost.zimmerman.io/util/host.sh#L24-L31


## Shell aliases

I'd like to think that my whole [`aliases.sh`][aliases] file is golden, but if
you're looking for some specific things I like about it, check out my [`git log`][glla-code]
aliases, which I wrote about [here][glla], and my [`chromemem`][chromemem-code] alias, which I wrote about [here][chromemem].

[aliases]: https://github.com/jez/dotfiles/blob/eba0202443de6bcc171dbe6bc133fa9fe02357f7/util/aliases.sh
[glla-code]: https://github.com/jez/dotfiles/blob/eba0202443de6bcc171dbe6bc133fa9fe02357f7/util/aliases.sh#L75-L86
[glla]: /2015/01/16/mastering-git-log-for-collaboration/
[chromemem-code]: https://github.com/jez/dotfiles/blob/eba0202443de6bcc171dbe6bc133fa9fe02357f7/util/aliases.sh#L44-L45
[chromemem]: /2014/12/29/google-chrome-a-memory-hog/


## Ruby Virtualenvs

I wrote about how I use [Python Virtualenvs to sandbox Ruby
gems][ruby-virtualenvs], a post in which I dropped some snippets that you can
use to configure virtualenvwrapper to work with Ruby projects. I actually went
ahead and [fed those files right into rcm][virtualenvs], so they'll always be available if I
ever get a new laptop.

[ruby-virtualenvs]: /2014/12/22/ruby-virtualenvs/
[virtualenvs]: https://github.com/jez/dotfiles/tree/eba0202443de6bcc171dbe6bc133fa9fe02357f7/host-Jacobs-MacBook-Air/virtualenvs


## `ssh`

My hostname on every machine I ssh to for school is `jezimmer`, but there are
countless servers I can ssh into (7 for `unix.andrew.cmu.edu`, 99+ for
`ghc*.ghc.andrew.cmu.edu`, 10 for 15-213, the list goes on). [These
lines][ssh-jezimmer] enable me to ssh to any of those machines with just a
hostname, and the username is assumed to be `jezimmer`.

[ssh-jezimmer]: https://github.com/jez/dotfiles/blob/eba0202443de6bcc171dbe6bc133fa9fe02357f7/host-Jacobs-MacBook-Air/ssh/config#L7-L19

## iTerm2

There's not much to show for this one, but in Preferences > General of iTerm2,
you can opt to load your iTerm2 preferences from a specific location. I've set
this to `/Users/jake/.dotfiles`, which means that my iTerm2 settings are always
written to my `.dotfiles/` directory. If I ever make changes to iTerm2, they get
propagated as changes that Git picks up on and which I subsequently check into
Git history.

## Vim

I'm in love with my Vim setup. If you're looking for help getting started
configuring Vim, you should checkout the [Vim plugins workshop I put
together][vim-as-an-ide], which gets you started with a "fully-configured" Vim
setup. Once you think you've "mastered" that and you're ready for more, here are
a list of things I'm proud of in my `.vimrc`:

- [`set breakindent`][breakindent] A feature new in Vim 7.4, this allows you to
  align wrapped text at the same indentation level as the preceding text.
- [these mappings][long-lines], which let me move around (move up and down in
  particular) in long lines just as if they were short.
- [this mapping][tab-help], which lets me open Vim help pages in new tabs

[vim-as-an-ide]: https://github.com/jez/vim-as-an-ide
[breakindent]: https://github.com/jez/dotfiles/blob/eba0202443de6bcc171dbe6bc133fa9fe02357f7/vimrc#L65-L67
[long-lines]: https://github.com/jez/dotfiles/blob/eba0202443de6bcc171dbe6bc133fa9fe02357f7/vimrc#L100-L106
[tab-help]: https://github.com/jez/dotfiles/blob/eba0202443de6bcc171dbe6bc133fa9fe02357f7/vimrc#L90-L91


## Other

I've only highlighted a fraction of my configuration files, but I think I've
managed to capture a good portion of them. If you thought that one of these
snippets was useful, are having trouble getting something to work, or have
something interesting to share, leave a comment below! 

{% include jake-on-the-web.markdown %}
