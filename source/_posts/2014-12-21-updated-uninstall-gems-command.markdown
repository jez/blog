---
layout: post
title: "Updated uninstall_gems command"
date: 2014-12-21 00:48:26 -0600
comments: true
categories: [ruby, python]
description: >
  I updated some bugs in a script that I love to uninstall Ruby gems.
image:
  feature: /images/abstract-5.jpg
  credit: dargadgetz
  creditlink: http://www.dargadgetz.com/ios-7-abstract-wallpaper-pack-for-iphone-5-and-ipod-touch-retina/
share: true
published: false
---

A while back I found a command that removes all Ruby gems installed on a system
when you're using rbenv. It worked great, so I decided to build on top of it.

<!-- more -->

## Ugh, Ruby...

If you're anything like me, you can never do anything right on the first try
using Ruby. On one of these occasions, I got tired of trying to fix it. I
wanted to destroy everything and start over. That's when I found Ian Vaughan's
[script][iv] that magically removes all gems. I was delighted to see that it
worked perfectly on the first try, and went about the rest of my business.

## Modifications

There were two ways, though, that what this script's functionality differed
from what I wanted it to do: it always removed __all__ the gems, and it left
behind a `.ruby_version` file after it was used, clobbering any file that might
have been there before.

In my updated script, you can specify a list of ruby versions as arguments, and
it will only gems from those versions instead of all of them.  Also, it saves
and restores the value of the old `.ruby_version` file once it's done.

The new script is available [as a fork of the original Gist][gist] and also as
a part of of [my personal bin folder][bin].

## The Underlying Problem

After a bit of reflection, I realized I should be trying to solve the underlying
problem: different projects had different dependencies, and gems from one
project were bleeding into gems from another. If you're a Python developer, you
don't have this issue: [virtualenvwrapper][venv], `pip` and `requirements.txt`
files make this a non-issue.

After looking into a similar Ruby solution, I came up with [this blog
post][venv-ruby] outlining how you can do the exact same thing using virtualenvs
but with Ruby gems! You should definitely check it out if you're in the same
boat.

{% include jake-on-the-web.markdown %}

[iv]: https://gist.github.com/IanVaughan/2902499
[gist]: https://gist.github.com/Z1MM32M4N/cc2ba08062c6183a489c
[bin]: https://github.com/Z1MM32M4N/bin/blob/master/uninstall_gems
[venv]: http://virtualenvwrapper.readthedocs.org/en/latest/
[venv-ruby]: http://honza.ca/2011/06/install-ruby-gems-into-virtualenv
