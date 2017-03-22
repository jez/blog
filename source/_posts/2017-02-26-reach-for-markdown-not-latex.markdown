---
layout: post
title: "Reach for Markdown, not LaTeX"
date: 2017-02-26 21:26:53 -0500
comments: false
share: false
categories:
  - markdown
  - latex
  - vim
description: >
  Writing should be a pleasant experience. With the right tools, it can be.
  LaTeX is powerful but cumbersome to use. With Markdown, we can focus on our
  writing, and worry about the presentation later. Pandoc can take care of the
  presentation for us, so the only thing left to do is start.
pinned: true
---

I've written [in the past][latex-part1] ([twice][latex-part2]) about how to
streamline the writing process when using LaTeX. Since then, I've found that I
enjoy writing even more when I don't have to reach for LaTeX at all. By reaching
first for Markdown, then for LaTeX when necessary, writing is easier and more
enjoyable.

<!-- more -->

## Writing at the Command Line

Last year, I [gave a talk][writing-cli] about the merits of writing primarily at
the command line. My main claims were that when writing we want:

- an open document format (so that our writings are future proof)
- to be using open source software (for considerations of privacy and cost)
- to optimize for the "common case"
- to be able to write for print and digital (PDFs, web pages, etc.)

Markdown solves these constraints nicely:

- It's a plain text format---plain text has been around for decades and will
  be for decades more.
- Given a plain text format, we can bring our own text editor.
- Plenty of open source programs manipulate Markdown.
- When we need advanced features, we can mix LaTeX into our Markdown documents.

For those unfamiliar with Markdown, it's super quick to pick up. If you only
look at one guide, see this one:

- [CommonMark](http://commonmark.org/help/)

If you want to start comparing features available in certain implementations of
Markdown:

- [GitHub Flavored Markdown](https://guides.github.com/features/mastering-markdown/)
- [Markdown.pl](https://daringfireball.net/projects/markdown/)
- [Pandoc Markdown](http://pandoc.org/MANUAL.html#pandocs-markdown)

For more on why you should want to be writing at the command line, you can
[check out the talk slides][writing-cli].


## Pandoc Starter

The central tool I spoke about in *Writing at the Command Line* is [Pandoc].
Pandoc is an amazingly simple command line program that takes in Markdown files
and spits out really anything you can think of.

To make using Pandoc even easier than it already is, I put together a
[collection of starter templates][pandoc-starter]. They're all available [on
Github][pandoc-starter] if you'd prefer to dive right in.

There are currently six different templates, specialized for the kind of
document you'd like to create. Each has a `README` for installation and usage
instructions, as well as a `Makefile` for invoking `pandoc` correctly.

All the templates generate PDFs from Markdown by way of LaTeX. In addition to
Pandoc, you'll also need LaTeX installed locally.

### [`article`][ps-article]

This template uses the standard LaTeX `article` document class. It's a
no frills, no nonsense choice.

[![article template](/images/pandoc-starter-article.png)][ps-article-pdf]

### [`tufte-handout`][ps-tufte-handout]

As an alternative to the `article` document class, there's also the
`tufte-handout` document class. It originates from the style Edward Tufte
popularized in his books and articles on visualization and design.

Apart from a different font (it uses Palatino instead of the default Computer
Modern), this template features the ability add side notes to your documents. I
often find myself reaching for this template when I want to disguise the fact
that I'm secretly using LaTeX.

[![tufte-handout template](/images/pandoc-starter-tufte-handout.png)][ps-tufte-handout-pdf]

### [`homework`][ps-homework]

A second alternative to the `article` document class is the `homework` document
class. It works nicely for homework assignments and problem sets. The class
itself has a number of handy features, like:

- the option to put your name on every page, or only on the first page
- an option to use wide or narrow margins
- most of the AMS Math packages you'd include in the process of typesetting a
  math assignment
- a convenient environment for typesetting induction proofs

For more features and usage information, check out [this blog post][homework] or
[the source][homework-github] on GitHub.

[![homework template](/images/pandoc-starter-homework.png)][ps-homework-pdf]

### [`beamer`][ps-beamer]

LaTeX provides the `beamer` document class for creating slides; this template
makes it even easier to use:

- Make a new slide with a "`##`" header
- Make a section divider with a "`#`" header
- Mix lists, links, code, and other Markdown features you're familiar with to
  create the content for a slide.

So basically, just write the outline for your talk, and Pandoc takes care of
making the slides---it doesn't get much simpler.

[![beamer template](/images/pandoc-starter-beamer.png)][ps-beamer-pdf]

### [`beamer-solarized`][ps-beamer-solarized]

The default beamer styles are pretty boring. To add a bit of flair and
personality to my slide decks, I made a Solarized theme for beamer.

In addition to the screenshot below, the [Writing at the Command
Line][writing-cli] slides I linked to earlier also use this theme, if you want
to see a less contrived example.

[![beamer solarized template](/images/pandoc-starter-beamer-solarized.png)][ps-beamer-solarized-pdf]

### [`book-writeup`][ps-book-writeup]

Finally, sometimes a simple article or slide deck doesn't cut it. Usually this
means I'd like to group the writing into chapters. This template makes writing a
chapter as easy as using a "`#`" Markdown header.

[![book writeup template](/images/pandoc-starter-book-writeup.png)][ps-book-writeup-pdf]


## Writing Plugins for Vim

If you happen to use Vim, I'd highly recommend installing [goyo.vim] for
writing. It removes all the visual frills Vim includes to make writing code
easier so you can focus on your writing without distractions.

I also really enjoy [vim-pandoc] and [vim-pandoc-syntax]. They're a pair of
complementary plugins for highlighting and working with Pandoc Markdown-flavored
documents. They work so well that I use them for Markdown documents even when
not using Pandoc.


## Reach for Markdown

Writing should be a pleasant experience. With the right tools, it can be. LaTeX
is powerful but cumbersome to use. With Markdown, we can focus on our writing,
and worry about the presentation later. Pandoc can take care of the presentation
for us, so the [only thing left to do is start][pandoc-starter].

{% include jake-on-the-web.markdown %}


[latex-part1]: /2014/10/06/offline-latex-development/
[latex-part2]: /2015/01/10/offline-latex-development-part-2/
[writing-cli]: https://jez.io/talks/writing-at-the-command-line/
[Pandoc]: https://pandoc.org/
[pandoc-starter]: https://github.com/jez/pandoc-starter
[homework]: /2015/01/10/the-latex-homework-document-class/
[homework-github]: https://github.com/jez/latex-homework-class
[goyo.vim]: https://github.com/junegunn/goyo.vim
[vim-pandoc]: https://github.com/vim-pandoc/vim-pandoc
[vim-pandoc-syntax]: https://github.com/vim-pandoc/vim-pandoc-syntax

[ps-article]: https://github.com/jez/pandoc-starter/tree/master/article
[ps-tufte-handout]: https://github.com/jez/pandoc-starter/tree/master/tufte-handout
[ps-homework]: https://github.com/jez/pandoc-starter/tree/master/tufte-handout
[ps-beamer]: https://github.com/jez/pandoc-starter/tree/master/beamer
[ps-beamer-solarized]: https://github.com/jez/pandoc-starter/tree/master/beamer-solarized
[ps-book-writeup]: https://github.com/jez/pandoc-starter/tree/master/book-writeup

[ps-article-pdf]: https://github.com/jez/pandoc-starter/blob/master/article/src/sample.pdf
[ps-tufte-handout-pdf]: https://github.com/jez/pandoc-starter/blob/master/tufte-handout/src/sample.pdf
[ps-homework-pdf]: https://github.com/jez/pandoc-starter/blob/master/homework/src/sample.pdf
[ps-beamer-pdf]: https://github.com/jez/pandoc-starter/blob/master/beamer/src/sample.pdf
[ps-beamer-solarized-pdf]: https://github.com/jez/pandoc-starter/blob/master/beamer-solarized/src/sample.pdf
[ps-book-writeup-pdf]: https://github.com/jez/pandoc-starter/blob/master/book-writeup/src/sample.pdf
