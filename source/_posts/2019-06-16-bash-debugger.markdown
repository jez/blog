---
layout: post
title: "A Debugger for Bash in Six Lines of Bash"
date: 2019-06-16 09:25:06 -0700
comments: false
share: false
categories: ['bash']
description: I implemented a debugger for Bash in six lines of Bash.
strong_keywords: false
---

I implemented a "debugger" for Bash in six lines of Bash. It kind of
behaves like JavaScript's `debugger` keyword. Here's how it works:

<!-- more -->

```bash
debugger() {
  echo "Stopped in REPL. Press ^D to resume, or ^C to abort."
  local line
  while read -r -p "> " line; do
    eval "$line"
  done
  echo
}
```

And there it is. Add this to a script, insert a call to `debugger`
somewhere, and run the script. It'll pause right execution right there.
Once paused, we can do things like:

- print the contents of variables with `echo`
- run commands that are on our `PATH` (e.g., `pwd`, `ls`, ...)
- call functions defined in the script

... and pretty much everything that we could have done if we were
editing the script directly. Here's a short session demonstrating how it
can be used:

```bash
#!/usr/bin/env bash

debugger() {
  # ... implemented above ...
}

foo=1
debugger
echo "foo: $foo"
```

```
❯ foo.sh
Stopped in REPL. Press ^D to resume, or ^C to abort.
> pwd
/Users/jez
> echo $foo
1
> foo=42
> ^D
foo: 42
```


## Stopping on failures

I find that most of the time this is useful when a script is failing for
some reason. Rather than put a `debugger` call right before the failing
command, I can just add this at the top of the file:

```bash
trap 'debugger' ERR
```

When any command has a non-zero exit code, Bash will run `debugger` and
pause the program.

I've been keeping this function and `trap` call commented out at the top
of my scripts and uncommenting them when needed (It uses `eval`, which
is not the best from a security perspective, which is why it's commented
by default).


## Future work

Of course, I said "debugger" in quotes earlier because it's not
**really** a debugger:

- Using it requires editing the script we want to debug to include these
  lines, and then calling `debugger` somewhere. It doesn't launch an
  inferior process and control it, like `gdb` or `lldb` would.

- There's no `break` command to edit breakpoints while stopped. All
  breakpoints must have been written into the program up front.

- There's also no `step` or `next` commands for stepping into or over
  the next function or command.

- When it stops, it doesn't show the text content of the last line that
  executed, or even the line number.

But I have some thoughts on how to implement these, too... Bash's `trap`
builtin has a way to trap `DEBUG`, which runs after every command. I
think I could make clever use of `trap`s to implementat least one of
`step` or `next`, and definitely something that says "stopped on line X"
and maybe even use that to print the source text of that line.
Implementing `break` seems to be the hardest—I don't have any ideas for
that one right now.

I'm releasing this code into the public domain. If you want to change it
to implement any of these features, I'd be more than interested to hear
about it!

<!-- vim:tw=72
-->
