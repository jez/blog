---
layout: post
title: "Mastering git log for Collaboration"
date: 2015-01-16 20:57:01 -0500
comments: false
categories: [git]
description: >
  Mastering git log is probably the best way to collaborate effectively on a
  project that uses Git.
share: false
permalink: /:year/:month/:day/:title/
---

Git is an incredibly powerful platform for collaboration. The ability to create
light-weight branches as well as push to and pull from multiple remote repos is
the foundation of this power. Learning to harness the `git log` command will
help with visualizing all the information that supports these features, refining
and invigorating your current workflows.

<!-- more -->

## Learn Git Branching

Obviously, to take full advantage of the collaborative features of Git, you
first have to learn how to use Git branching. There's an [excellent interactive
tutorial][learnGitBranching] that instructs by converting the Git commands you
run into fancy web animations. If you have a basic understanding of Git but have
always wanted to learn about some of its more powerful features, this is the
best tutorial out there. For a taste of how it works, there's also a
[non-interactive demo][demo] that features the animations which make this
tutorial so well-designed.

After I ran through this tutorial, I felt for the first time like I _really_
knew Git. Unfortunately, being a visual learner, I struggled when trying to
apply the same abstractions to actual git repositories. Shortly thereafter, I
discovered that the `git log` command actually has features to replicate many of
the same visualizations, but from right within the terminal!

## `git log`

The following is a set of shell aliases that let you run `git log` with a
lengthy set of flags culminating in some pretty awesome Git logs. I'm going to
leave a discussion of what the individual flags do to the man pages and just
skip straight to the good part. Feel free to copy and paste these into your
`~/.bashrc`, `~/.zshrc`, or similar file.

```bash pretty git log aliases
# pretty Git log
alias gl='git log --graph --pretty="%C(bold green)%h%Creset%C(auto)%d%Creset %s"'

# pretty Git log, all references
alias gll='gl --all'

# pretty Git log, show authors
alias gla='git log --graph --pretty="%C(bold green)%h%Creset %C(yellow)%an%Creset%C(auto)%d%Creset %s"'

# pretty Git log, all references, show authors
alias glla='gla --all'
```

As you can see, there are four aliases, and each does something a little
different. The first, `gl`, just shows the graph for the current branch. `gll`
shows the graph for _all_ branches, including those which may have diverged from
the current branch. Then there's a variation on each of these, `gla` and
`glla`, which add author information to the logs produced by their
companion.

On top of it all, I've customized the colors to work especially nicely if you're
using the [Solarized][solarized] color scheme in your terminal. If you don't do
anything but copy the above aliases, the only thing that will look different
from the screenshots below is the text between the parentheses, which will
instead all be the same color. To color these the same as below, add this text to
the end of your `~/.gitconfig` file:

```plain Global Git configuration settings
[color "decorate"]
  head = bold white
  branch = bold magenta
  remotebranch = blue
  tag = bold red
```

Of course, feel free to tinker with these colors to your liking.

## Screenshots

Here are an abundant number of screenshots showing what the commands look like
for the [TartanHacks website][tartanhacks] and the [Autolab Project][autolab].

### gl

{% img /images/gl-tartanhacks.png %}

Even when just using `gl`, you'll be able to see all branches that lie further
down on the tree. For example, from the `add_gitignore` branch we can see the
`origin/gh-pages` branch because it's along the same path in history.

### gll

{% img /images/gll-tartanhacks.png %}

Here we see that multiple branches have diverged from `origin/gh-pages`; both
`add_gitignore` and `fix_seo_and_readability` share `origin/gh-pages` as a
common ancestor, but neither have anything in common with the other, which is
why `fix_seo_and_readability` only showed up once we used `gll`.

### gla

{% img /images/gla-tartanhacks.png %}

Same as `gl` above, but with author information!

### glla

{% img /images/glla-tartanhacks.png %}

Same as `gll` above, but again with author information!

- - -

Here are the same four examples, but for the [Autolab][autolab] repo. It's a
little more involved because more people are working on it simultaneously. For
projects like this, which have several open pull requests and feature branches,
these aliases really shine.

### gl

{% img /images/gl-autolab.png %}

### gll

{% img /images/gll-autolab.png %}

### gla

{% img /images/gla-autolab.png %}

### glla

{% img /images/glla-autolab.png %}


## Dotfiles

If you're hungry for more handy Git aliases or just some general ways to beef up
your terminal experience, you can find these four aliases and more in the
[zshrc][zshrc] in my [dotfiles repository][dotfiles] on GitHub.

## Update

After testing out these aliases on various environments, I discovered that one
of the features I was using in the pretty format (the one that colors remotes
and branches, `%C(auto)`) is not available in older versions of Git. These are
the revised versions of the above aliases that I use on older machines:

```bash Compatible Git log aliases
# pretty Git log
alias gl='git log --graph --pretty="%C(bold green)%h%Creset%C(blue)%d%Creset %s"'

# pretty Git log, all references
alias gll='gl --all'

# pretty Git log, show authors
alias gla='git log --graph --pretty="%C(bold green)%h%Creset %C(yellow)%an%Creset%C(blue)%d%Creset %s"'

# pretty Git log, all references, show authors
alias glla='gla --all'
```

The only real difference is that all the remotes, branches, and tags are blue,
instead of being configurable in you `~/.gitconfig` file.





[learnGitBranching]: http://pcottle.github.io/learnGitBranching/
[demo]: http://pcottle.github.io/learnGitBranching/?demo
[solarized]: ethanschoonover.com/solarized
[tartanhacks]: https://github.com/ScottyLabs/tartanhacks
[autolab]: https://github.com/autolab/Autolab
[zshrc]: https://github.com/jez/dotfiles/blob/master/zshrc
[dotfiles]: https://github.com/jez/dotfiles
