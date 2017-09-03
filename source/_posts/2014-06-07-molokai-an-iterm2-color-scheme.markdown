---
layout: post
title: "Molokai: An iTerm2 Color Scheme"
date: 2014-06-07 12:00:39 -0400
comments: false
categories: [terminal, design]
description: "I've used tomasr's vim color scheme 'molokai' for a long time now. Recently I decided that the default iTerm2 colors were a little lack luster, so I ported over the main colors from this theme into an iTerm2 theme."
share: false
---

I've used [tomasr][tomasr]'s vim color scheme [molokai][molokai-vim] for a long time now. Recently I decided that the default iTerm2 colors were a little lack luster, so I ported over the main colors from this theme into an iTerm2 theme.

<!-- more -->

## [<i class="fa fa-angle-double-right"></i> Installation][molokai-iterm2]
If you don't already have your iTerm2 colors configured or you're looking for a change, you should definitely check out [iTerm2-Color-Schemes][iTerm2-Color-Schemes], a GitHub repo by [mbadolato][mbadolato] filled with tons of themes he's ported, collected, and been given. 

You can see and install the [Molokai theme][molokai-iterm2] there.

## Screenshots
I don't have too many good screenshots of this theme that aren't vim because I'm actually using [solarized][solarized] dircolors for colorizing the output of my `ls` and related commands. However, there are still plenty of tools I use which resort to default ANSI colors to colorize their output, like `git` and `brew`. You can see a `git log` command along side a table of all ANSI color combinations resulting from this theme (this table can be a bit overwhelming: it's best to just look at the first two columns to get an idea of what the colors really look like).

{% img /images/molokai.png %}


[tomasr]: https://github.com/tomasr
[molokai-vim]: https://github.com/tomasr/molokai
[iTerm2-Color-Schemes]: https://github.com/mbadolato/iTerm2-Color-Schemes
[mbadolato]: https://github.com/mbadolato
[molokai-iterm2]: https://github.com/mbadolato/iTerm2-Color-Schemes#molokai
[solarized]: https://github.com/seebi/dircolors-solarized
