---
# vim:tw=90 fo-=tc
layout: post
title: "Approximating strace with Instruments.app"
date: 2024-10-09T17:17:13-04:00
description: "The other day I learned that Instruments.app can record file system activity on macOS!"
math: false
categories: ['debugging', 'linux', 'osx']
# subtitle:
# author:
# author_url:
---

The other day I learned that Instruments.app can record file system activity on macOS!

![Instruments.app on macOS tracing `git status`](/assets/img/instruments-app-strace.png)

## `strace` is great, but...

One of the things I _always_ use `strace` on Linux for is tracing a process to see, for example, which global config files it's reading—it's so simple, just

```
strace -- git status 2> trace.log
```

and then look through the logs to see where it's looking for files. For example, I discovered that `git` installed via Homebrew reads out of `/home/linuxbrew/.linuxbrew/etc/gitconfig` instead of `/etc/gitconfig` this way!

I'm sure you know how frustrating it is to think your program works one way when it's actually doing something else entirely... `strace` makes it easy to figure out when your program works a different way without having to traipse through the program's source code.

... but since macOS shipped [System Integrity Protection], I haven't been able to get the macOS alternatives like `dtrace` or `dtruss` to work.

[System Integrity Protection]:
  <https://en.wikipedia.org/wiki/System_Integrity_Protection>

## Instruments.app can trace arbitrary programs!

Using the "Filesystem Activity" instrument in Instruments.app, I can run a program and see all the file system activity the program does!

There is also a "System Call Trace" instrument, but unlike `strace` it doesn't seem to record arguments and return values of syscalls—only the File System activity records arguments and return values for file system syscalls. So it's not a complete alternative to `strace` but at least it's better than trying to figure out how to work around System Integrity Protection.

\

While I was searching the internet trying to figure out whether Instruments.app could trace file system activity, I also stumbled on this great post:

→ [Did you know about Instruments?](https://registerspill.thorstenball.com/p/did-you-know-about-instruments)

It's full of more great tips!

