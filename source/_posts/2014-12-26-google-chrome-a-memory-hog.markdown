---
layout: post
title: "Google Chrome: A Memory Hog"
date: 2014-12-26 17:00:00 -0600
comments: true
categories: [unix, bash]
description: A bash oneliner to determine how much memory Chrome is using.
image:
  feature: /images/chrome-wide.jpg
  credit: Google
share: true
---

Whenever, someone complains about a slow computer, the first thing I check is
how many Chrome tabs they have open. Chrome hogs memory like no other. For
users, this means Chrome is snappy and responsive, but oftentimes it comes at
the expense of crowding out other programs. To get an idea of how much memory
Chrome is really using, I wrote a quick bash oneliner.

<!-- more -->

## The Oneliner

For the impatient, here's the code. It uses standard Unix tools:

```bash Chrome Memory Usage
$ ps -ev | grep -i chrome | awk '{print $12}' | awk '{for(i=1;i<=NF;i++)s+=$i}END{print s}'
```

If you want to save this as an alias for handy use, add this line to your
~/.bashrc (or appropriate configuration file):

```bash Add as an alias
alias chromemem="ps -ev | grep -i chrome | awk '{print \$12}' | awk '{for(i=1;i<=NF;i++)s+=\$i}END{print s}'"
```

It outputs a percentage. Here's the alias in action:

```bash Usage
$ chromemem
60
```

I've never seen this number fall below 50%, even right after starting up the
computer and launching Chrome.

## Explanation

There's a lot of good stuff going on here, so I figured I'd give an explanation
of how this works. Let's take it step-by-step.

First, we'll need a program that tells us memory usage. I'm sure there are many,
but I'm familiar with `ps`. After checking out the man page for a few options, I
came up with `ps -ev`, to show all information about all processes. Maybe
wasteful, but it works.

```bash ps -ev
$ ps -ev
  PID STAT      TIME  SL  RE PAGEIN      VSZ    RSS   LIM     TSIZ  %CPU %MEM COMMAND
 3473 S      0:54.92   0   0      0  3579092 301244     -        0   6.7  7.2 /Applications/Google C
  365 S      3:03.17   0   0      0  3920732 206808     -        0   0.3  4.9 /Applications/Google C
  983 S      1:29.23   0   0      0  3560272 193860     -        0   0.1  4.6 /Applications/Google C
  395 S      0:13.11   0   0      0  2824936 141644     -        0   0.0  3.4 /Applications/Google C
  422 S      0:27.22   0   0      0  3345796 130796     -        0   0.0  3.1 /Applications/Google C
  ...
```

Notice that there's a convenient column describing memory usage as a percentage
of total available memory, as well as what command is being run in that
process. Let's make sure that we're looking at only the processes running
some sort of Chrome service before totaling up the memory. We can find these
lines with `ps -ev | grep -i chrome` (the -i means case-insensitive). Due to the
way I clipped the previous sample output, nothing changes in the first five
lines, but rest assured: we're only looking at Chrome processes now.

Now it's time to get rid of all the other nonsense that we included with `ps
-ev`. Luckily, there's a handy tool called `awk` that makes parsing text by
column easy. If we want to print the 12th column (which just so happens to
contain the memory consumption!) we can do `awk '{print $12}'`:

```bash ps -ev | grep -i chrome | awk '{print $12}'
$ ps -ev | grep -i chrome | awk '{print $12}'
7.2
5.1
4.6
3.4
3.2
...
```

Finally, I found myself needing a way to add up a column of numbers. A quick
Google search led me to [this StackOverflow question][sum], and I picked the
`awk` solution because I knew I could just pipe the input to awk (as opposed to
having to do weird hacks to get it to work with a bash for loop):

```bash Final Solution
$ ps -emv | grep -i chrome | awk '{print $12}' | awk '{for(i=1;i<=NF;i++)s+=$i}END{print s}'
60.4
```

Of course, you could change the last `awk` command to print out something
fancier like

```bash Final Solution
$ ps -emv | grep -i chrome | awk '{print $12}' | awk '{for(i=1;i<=NF;i++)s+=$i}END{print "Chrome is using "s"% of total memory."}'
Chrome is using 60.4% of total memory.
```

There you have it! Bash oneliners save the day yet again.

{% include jake-on-the-web.markdown %}

[sum]: http://stackoverflow.com/questions/2572495/read-from-file-and-add-numbers
