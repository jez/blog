---
layout: post
title: "Solarized LaTeX Listings"
date: 2014-10-04 06:35:05 -0400
comments: true
categories: [LaTeX, design]
description: I wrote a LaTeX package for styling code listings with Solarized.
image:
  feature: /images/abstract-7.jpg
  credit: dargadgetz
  creditlink: http://www.dargadgetz.com/ios-7-abstract-wallpaper-pack-for-iphone-5-and-ipod-touch-retina/
share: true
---

Out of the box, LaTeX listings are pretty bad. With a bit of work, you can ascribe some colors to the code, but you're still stuck with choosing a theme. Given that I recently just switched to the Solarized colorscheme in Vim and iTerm2, I made a LaTeX package that styles code listings with the predefined Solarized light colors.

<!-- more -->

## [Source][source]

The source for this theme is on GitHub, and the README has pretty good documentation. Here's an example of the final result:

{% img /images/solarized-light-screenshot.png %}

After you install them in the right place, you can include `\usepackage{solarized-light}` to turn source code listings light (as in above), `\usepackage{solarized-dark}` to have listings styled with the dark Solarized theme, and just `\usepackage{solarized}` to have access to the raw Solarized color codes (see the source for their names).

Once you've done this, you just have to include your code in your LaTeX file using the `listings` packages. You might want to check out [the LaTeX wiki][listings] for more information on how to get started quickly with code listings, or [the official documentation][docs] for a more comprehensive reference.

{% include jake-on-the-web.markdown %}

[source]: https://github.com/jez/latex-solarized
[listings]: http://en.wikibooks.org/wiki/LaTeX/Source_Code_Listings
[docs]: http://mirror.hmc.edu/ctan/macros/latex/contrib/listings/listings.pdf
