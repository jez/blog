---
layout: post
title: "Google Chrome: A Memory Hog"
date: 2014-12-29 17:00:00 -0600
comments: false
categories: [unix, bash]
description: A bash oneliner to determine how much memory Chrome is using.
share: false
permalink: /:year/:month/:day/:title/
---

Whenever someone complains about a slow computer, the first thing I check is
how many Chrome tabs they have open. Chrome hogs memory like no other. For
users, this means Chrome is snappy and responsive, but oftentimes it comes at
the expense of crowding out other programs. To get an idea of how much memory
Chrome is really using, I wrote a quick bash oneliner.

<!-- more -->

# Why does Chrome Hog Memory?

[An article posted to Hacker News][iframe-irony] recently brought some light to
the question of why Chrome and Firefox suck up so much memory: Adblock Plus. The
general idea is that the excessive use of iframes in most websites today ramps
up the amount of processing that Adblock Plus has to do, driving memory usage
through the roof. For more specifics, check out the rest of of the article.

# The Oneliner

For the impatient, here's the code. It uses standard Unix tools:

<figure>

```{.bash .numberLines}
$ ps -ev | grep -i chrome | awk '{print $12}' | awk '{for(i=1;i<=NF;i++)s+=$i}END{print s}'
```

<figcaption>Chrome Memory Usage</figcaption>
</figure>

Pretty isn't it? If you want to save this as an alias for handy use, add this
line to your ~/.bashrc (or appropriate configuration file):

<figure>

```{.bash .numberLines}
alias chromemem="ps -ev | grep -i chrome | awk '{print \$12}' | awk '{for(i=1;i<=NF;i++)s+=\$i}END{print s}'"
```

<figcaption>Add as an alias</figcaption>
</figure>

It outputs a percentage. Here's the alias in action:

<figure>

```{.bash .numberLines}
$ chromemem
60
```

<figcaption>Usage</figcaption>
</figure>

# Explanation

There's a lot of good stuff going on here, so let's take it step-by-step.

First, we'll need a program that tells us memory usage. I'm sure there are many,
but I'm familiar with `ps`. After checking out the man page for a few options, I
came up with `ps -ev`, to show all information about all processes. Maybe
wasteful, but it works.

<figure class="wide extra-wide">

```{.bash .numberLines}
$ ps -ev
  PID STAT      TIME  SL  RE PAGEIN      VSZ    RSS   LIM     TSIZ  %CPU %MEM COMMAND
 3473 S      0:54.92   0   0      0  3579092 301244     -        0   6.7  7.2 /Applications/Google Chrome.app/Contents/Frameworks/...
  365 S      3:03.17   0   0      0  3920732 206808     -        0   0.3  4.9 /Applications/Google Chrome.app/Contents/Frameworks/...
  983 S      1:29.23   0   0      0  3560272 193860     -        0   0.1  4.6 /Applications/Google Chrome.app/Contents/Frameworks/...
  395 S      0:13.11   0   0      0  2824936 141644     -        0   0.0  3.4 /Applications/Google Chrome.app/Contents/Frameworks/...
  422 S      0:27.22   0   0      0  3345796 130796     -        0   0.0  3.1 /Applications/Google Chrome.app/Contents/Frameworks/...
  ...
```

<figcaption>ps -ev</figcaption>
</figure>

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

<figure>

```{.bash .numberLines}
$ ps -ev | grep -i chrome | awk '{print $12}'
7.2
5.1
4.6
3.4
3.2
...
```

<figcaption>ps -ev | grep -i chrome | awk '{print $12}'</figcaption>
</figure>

Finally, I found myself needing a way to add up a column of numbers. A quick
Google search led me to [this StackOverflow question][sum], and I picked the
`awk` solution because I knew I could just pipe the input to awk (as opposed to
having to do weird hacks to get it to work with a bash for loop):

<figure>

```{.bash .numberLines}
$ ps -emv | grep -i chrome | awk '{print $12}' | awk '{for(i=1;i<=NF;i++)s+=$i}END{print s}'
60.4
```

<figcaption>Final Solution</figcaption>
</figure>

Of course, you could change the last `awk` command to print out something
fancier like

<figure>

```{.bash .numberLines}
$ ps -emv | grep -i chrome | awk '{print $12}' | awk '{for(i=1;i<=NF;i++)s+=$i}END{print "Chrome is using "s"% of total memory."}'
Chrome is using 60.4% of total memory.
```

<figcaption>Final Solution</figcaption>
</figure>

There you have it! Bash oneliners save the day yet again.

# Update

After writing this article, I stopped using Ad Block Plus, and I noticed a
significant drop in Chrome's memory usage. Obviously, though, that came at the
cost of not blocking ads! Also, from time to time I would encounter a site that
seemed sluggish, presumably because of all the ads attempting to be loaded. My
simple solution to this was just to disable JavaScript on that page (I use an
extension called Quick JavaScript Switcher), but this wasn't an automated
solution.

Then I discovered [μBlock][ublock], an "efficient blocker for Chromium and
Firefox." The fancy graphs on it's homepage convinced me to give it a shot, and
from what I can tell so far it's responsive and effective.


[iframe-irony]: http://mobile.extremetech.com/latest/221392-iframe-irony-adblock-plus-is-probably-the-reason-firefox-and-chrome-are-such-memory-hogs
[sum]: http://stackoverflow.com/questions/2572495/read-from-file-and-add-numbers
[ublock]: https://github.com/gorhill/uBlock
