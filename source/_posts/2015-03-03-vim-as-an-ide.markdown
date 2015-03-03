---
layout: post
title: "Vim as an IDE"
date: 2015-03-03 00:01:19 -0500
comments: true
categories: [vim]
description: >
  Some screenshots and clarifications for my Vim as an IDE walkthrough on
  GitHub.
image:
  feature: /images/abstract-1.jpg
  credit: dargadgetz
  creditlink: http://www.dargadgetz.com/ios-7-abstract-wallpaper-pack-for-iphone-5-and-ipod-touch-retina/
share: true
---

I took some screenshots to accompany my [Vim as an IDE][repo] repo on GitHub.
This is by no means a complete walkthrough! It's just a reference for those who
are curious if they installed everything correctly. This is what my system looks
like for me after each step.

<!-- more -->


## 1. [Create vimrc file](https://github.com/jez/vim-as-an-ide/commit/0673f0c)

This is what Vim should look like immediately after opening it:

[![Vim as an IDE][shot-01]][shot-01]

And right after adding the two lines:

[![Vim as an IDE][shot-02]][shot-02]

## 2. [Add some general settings](https://github.com/jez/vim-as-an-ide/commit/dff7da3)

After you add these settings, your `~/.vimrc` should look like this when opened
in Vim:

[![Vim as an IDE][shot-03_1]][shot-03_1]

## 3. [Enable the mouse](https://github.com/jez/vim-as-an-ide/commit/fc77b04)

To enable the mouse, you'll have to figure out where the appropriate setting is
in your terminal emulator. Here's a screenshot of where it is in iTerm2 on OS X.

[![Vim as an IDE][shot-03]][shot-03]

## 4. [Set up Vundle boilerplate](https://github.com/jez/vim-as-an-ide/commit/1186be2)

If you add the changes introduced at this step before installing Vundle, you'll
get an error that looks like this:

[![Vim as an IDE][shot-04]][shot-04]

Otherwise, this should be the result of running `vim +PluginInstall` to install
Vundle for the first time:

[![Vim as an IDE][shot-05]][shot-05]

Remember, you can use `:qall` to quit Vim after installing plugins.

## 5. [Make Vim look good](https://github.com/jez/vim-as-an-ide/commit/457f2e2)

Your experience might diverge a little bit from these screenshots if you choose
a different colorscheme because I'll assume you're setting everything up using
Solarized Dark. If you're on a Mac and you've imported the iTerm2 colorschemes,
you should be able to find the Solarized Dark theme here:

[![Vim as an IDE][shot-06]][shot-06]

Making that change should make Vim turn these colors:

[![Vim as an IDE][shot-07]][shot-07]

Next up is changing your font to a Powerline patched font. If you downloaded and
installed Menlo for Powerline correctly, you should be able to set it using this
panel in the preferences:

[![Vim as an IDE][shot-08]][shot-08]

Finally, running `vim +PluginInstall` to install the Solarized Vim colorscheme
and vim-airline:

[![Vim as an IDE][shot-09]][shot-09]

Here's what the Vim solarized plugind does to our `~/.vimrc`:

[![Vim as an IDE][shot-10]][shot-10]

If you chose to install a Powerline patched font, you can let vim-airline use
cooler arrows by uncommenting the line highlighted in this screenshot above, to
make Vim look like this:

[![Vim as an IDE][shot-11]][shot-11]


## 6. [Plugins NERDTree and NERDTree Tabs](https://github.com/jez/vim-as-an-ide/commit/b7ff90c)

This will be the last time that I demonstrate running `vim +PluginInstall`,
because they'll all basically look the same from here on out:

[![Vim as an IDE][shot-12]][shot-12]

Once you've installed NERDTree and NERDTree Tabs (and added the settings I
listed for them), you should be able to type `\t` to bring up something that
looks like this:

[![Vim as an IDE][shot-13]][shot-13]


## 7. [Plugin Syntastic](https://github.com/jez/vim-as-an-ide/commit/144f979)

Once you've installed Syntastic, it should syntax highlight your errors by
displaying little marks next to the offending lines:

[![Vim as an IDE][shot-14]][shot-14]

You can see that we've forgotten a semi-colon, and Syntastic is pointing that
out for us.

As I was making these screenshots, I realized that I forgot to include a setting
in the right place. It's fine if you work through the whole workshop, but if you
pick and choose things, namely if you don't follow the steps for `vim-gitgutter`
eventually, you'll end up with this weird highlighting in the sign column. To
disable this highlighting, you can either wait until the `vim-gitgutter` step
(coming right up in 4 steps), or you can run this command (the one at the bottom
of the screenshot):

[![Vim as an IDE][shot-15]][shot-15]

To make the change permanent, you'll have to add that line (`:hi clear
SignColumn`) to your `~/.vimrc`.


## 8. [Plugins vim-easytags and tagbar](https://github.com/jez/vim-as-an-ide/commit/fd2c49c)

After this step, you should be able to bring up a split pane view that shows
your functions, variables, and other identifiers by pressing `\b`:

[![Vim as an IDE][shot-16]][shot-16]

If you enabled mouse reporting, you should be able to click on the things in the
pane and jump to the appropriate place in the file. I'd strongly recommend that
you read the help for all the keybindings and actions you can use with it.


## 9. [Plugin ctrlp](https://github.com/jez/vim-as-an-ide/commit/80db74f)

When `CtrlP` is installed, you can press `Ctrl + P` to bring up a list of files.
As you type, the list will be filtered to only those that "fuzzy match" what
you've typed in. As you can see, I typed in `mc`, which matched `vimrc.vim` and
`main.c`:

[![Vim as an IDE][shot-17]][shot-17]

## 10. [Plugin A.vim](https://github.com/jez/vim-as-an-ide/commit/8d4223f)

This plugin introduces a number of commands that you can read in the
documentation that enable opening "alternate" files, like C/C++ header files,
really quickly. I've run `:AV` here as an example of one of the commands it
installs, which opens the alternate file in a vertical split pane.

[![Vim as an IDE][shot-18]][shot-18]

## 11. [Plugins vim-gitgutter and vim-fugitive](https://github.com/jez/vim-as-an-ide/commit/1e5757e)

`vim-gitgutter` is really handy: it shows you a `+`, `-`, or `~` next to lines
that have been added, removed, or modified. This is good for both identifying
the pieces of code that have changed while you're working on a file as well as
reminding yourself that you have changes that need to be commited.

[![Vim as an IDE][shot-19]][shot-19]

Speaking of committing files, `vim-fugitive` lets you make Git commits from
right within Vim. Simply run `:Gcommit` to bring up a split pane where you can
craft your commit message:

[![Vim as an IDE][shot-20]][shot-20]

`vim-fugitive` can do much more than just make commits. Be sure to read the
appropriate documentation to figure out what sorts of cool things you can do!


## 12. [Plugin delimitMate](https://github.com/jez/vim-as-an-ide/commit/2fe0507)

Finally, using `delimitMate` you should be able to type an opening delimiter and
have the closing one be inserted automatically. Here's an example on
parentheses:

[![Vim as an IDE][shot-21]][shot-21]


## 13. [Plugin vim-superman](https://github.com/jez/vim-as-an-ide/commit/b185e9f)

Once you've added the appropriate function to your shell initialization file
(`~/.bashrc`, etc.), you should be able to run `vman <command>` to open man
pages. Here's an example on `vman 3 printf`:

[![Vim as an IDE][vim-superman]][vim-superman]

## 14. [Plugin vim-tmux-navigator](https://github.com/jez/vim-as-an-ide/commit/44f5225)

There's not much to show here, as this step is mostly just introducing
keybindings. If you use `tmux`, make sure to copy the appropriate snippet into
your `~/.tmux.conf` to be able to jump between tmux and Vim splits with no added
effort.


## 15. [Syntax plugins](https://github.com/jez/vim-as-an-ide/commit/5ba534e)

No screenshots again. What syntax highlighting plugins you end up installing is
largely up to you.

## 16. [Add all the extra plugins that I use](https://github.com/jez/vim-as-an-ide/commit/9089a95)

For these plugins, be sure to check the documentation. Most of them have
screenshots that show what they look like when installed and configured
correctly.

## Wrap Up

That's it! I can only take you so far in making your Vim awesome. You have to
take yourself the rest of the way by investing a little bit of effort into
reading the documentation for the plugins you think could be useful to you so
that you can fully utilize them. Be sure to comment on the commits with
questions if you're stuck or are wondering why your setup doesn't look similar
to one of the above!

{% include jake-on-the-web.markdown %}

[repo]: https://github.com/jez/vim-as-an-ide

[shot-01]: /images/vim-as-an-ide/shot-01.png
[shot-02]: /images/vim-as-an-ide/shot-02.png
[shot-03_1]: /images/vim-as-an-ide/shot-03_1.png
[shot-03]: /images/vim-as-an-ide/shot-03.png
[shot-04]: /images/vim-as-an-ide/shot-04.png
[shot-05]: /images/vim-as-an-ide/shot-05.png
[shot-06]: /images/vim-as-an-ide/shot-06.png
[shot-07]: /images/vim-as-an-ide/shot-07.png
[shot-08]: /images/vim-as-an-ide/shot-08.png
[shot-09]: /images/vim-as-an-ide/shot-09.png
[shot-10]: /images/vim-as-an-ide/shot-10.png
[shot-11]: /images/vim-as-an-ide/shot-11.png
[shot-12]: /images/vim-as-an-ide/shot-12.png
[shot-13]: /images/vim-as-an-ide/shot-13.png
[shot-14]: /images/vim-as-an-ide/shot-14.png
[shot-15]: /images/vim-as-an-ide/shot-15.png
[shot-16]: /images/vim-as-an-ide/shot-16.png
[shot-17]: /images/vim-as-an-ide/shot-17.png
[shot-18]: /images/vim-as-an-ide/shot-18.png
[shot-19]: /images/vim-as-an-ide/shot-19.png
[shot-20]: /images/vim-as-an-ide/shot-20.png
[shot-21]: /images/vim-as-an-ide/shot-21.png

[vim-superman]: /images/printf.3.png
