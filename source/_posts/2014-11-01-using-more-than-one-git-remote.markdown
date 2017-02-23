---
layout: post
title: "Using Multiple Git Remotes"
date: 2014-11-01 18:12:35 -0400
comments: false
categories: [git]
description: "An overview of how multiple Git remotes can be used to synchronize code distributed in a read-only Git repo"
share: false
---

Quite often when using git, you only need to use one remote: `origin`. All your pushes and pulls communicate with this one host. However, there are many occasions when using multiple Git remotes is incredibly handy.

<!-- more -->

## Quick Overview: Remotes

If you haven't already, I strongly recommend that you check out these two Git resources in your free time:

- [__Learn Git Branching__][learnGitBranching], an interactive walkthrough of some powerful Git features
- [__A Hacker's Guide to Git__][hacker], an explanation of Git by "taking a peek under the hood"

In this article, I'll only be talking about remotes. Remotes are basically "mirrors" of a branch that you have locally, but on a different computer.

## Scenario: Working with Code in 15-150

At CMU, the class 15-150 distributes its starter code in a beautiful way: using Git! This opens up a number of things we can take advantage of, but there's one thing in particular we can do using multiple git remotes.

In 15-150, the code is distribute in a read-only Git repo. If we want a place where we can push and pull our changes, we'll need to create our own _bare repo_ (a repo that's used just for pushing and pulling). You'll note that I said push _and pull_. The reason why I want to be able to pull is because I want to have 2 clones of this repo: one on the CMU Andrew Unix servers (where the 15-150 code is hosted), and one on my laptop, where there's no network latency to edit files in Vim.

To achieve this setup, the first thing we'll do is set up the bare repo. The best place to put a bare repo is on a server so that you can always access your code. So from Andrew, I'll run the commands:

```bash Initialize the Bare Repo
# (unix.andrew.cmu.edu)
#
# `git clone --bare` is basically GitHub's "Fork" feature,
# if you're familiar with that
$ git clone --bare ~/private/gitrepos/15150
# make sure you clone this into your private folder!
```

This creates a bare repo initialized with all the 15-150 content which I can clone in two different ways: one for if I'm on Andrew, one if I'm on my laptop.

```bash Clone New Remote
# (unix.andrew.cmu.edu)
#
# Clone over Unix file path to new folder ~/private/15150
$ git clone ~/private/gitrepos/15150 ~/private/15150

# -- and/or --

# (my laptop)
#
# Clone over ssh (using ssh alias, i.e., if you use `ssh andrew`)
$ git clone ssh://andrew:/afs/andrew/usr/jezimmer/private/15150
# -- or --
# Clone over ssh (without ssh alias,
#            i.e., if you use `ssh jezimmer@unix.andrew.cmu.edu`)
$ git clone ssh://jezimmer@unix.andrew.cmu.edu:/afs/andrew/usr/jezimmer/private/15150
```

To throw in a few graphics, our setup looks like this right now:

{% img /images/multiple-remotes-1.svg %}

I'm representing bare repos as clouds and clones of those repos as squares, with arrows representing whether code can flow from one place to the next. As you can see, to send code back and forth between Andrew and my laptop, I can just push in one place and pull in the other.

The one thing missing from our picture is the original handout repo. How will we get updates as the homeworks are released? The last piece involves setting this up.

```bash Add Handout Remote
# Add the 15-150 handout remote so we can get starter code, etc.
# (unix.andrew.cmu.edu)
#
# A common name for the second remote is "upstream", though you could also
# call this remote "handout" if that would be easier to keep straight
$ cd ~/private/15150
$ git remote add upstream /afs/andrew/course/15/150/handout

# -- and/or --

# (my laptop)
#
# Add remote over ssh with alias
$ git remote add upstream ssh://andrew:/afs/andrew/course/15/150/handout
# -- or --
# Add remote over ssh without alias
$ git remote add upstream ssh://jezimmer@unix.andrew.cmu.edu:/afs/andrew/course/15/150/handout
```

Once we run those two lines, our setup looks like this, where arrows point in
the direction data can flow:

{% img /images/multiple-remotes-2.svg %}

After this, we're able to run `git pull upstream master` to get the 15-150 starter code as it's released. I find this model particularly useful for all my classes, even the ones that don't distribute their code using Git. Having code both on Andrew and on my local machine is a generally handy configuration, and using Git to push the code around to the right places makes my workflow simple.

As always, let me know if something was unclear or incorrect in the comments!

## More Applications

There are plenty other applications of using multiple remotes with Git. Perhaps the most common is to use them with the [__GitHub forking model__][forking], which is useful when collaborating on a software development project with others. You can use multiple remotes to do things like resolve merge conflicts in pull requests and to keep your fork up to date with the original repo.

{% include jake-on-the-web.markdown %}


[learnGitBranching]: http://pcottle.github.io/learnGitBranching/
[hacker]: https://wildlyinaccurate.com/a-hackers-guide-to-git
[forking]: https://help.github.com/articles/fork-a-repo/
