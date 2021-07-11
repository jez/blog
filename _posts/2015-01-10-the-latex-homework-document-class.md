---
layout: post
title: "The LaTeX homework Document Class"
date: 2015-01-10 17:00:00 -0600
comments: false
categories: ['latex']
description: "A LaTeX \\documentclass for typesetting homework assignments."
share: false
permalink: /:year/:month/:day/:title/
---

There are LaTeX document classes for typesetting books, articles, exams,
presentations, and more. Now, there's one for homework assignments, too.

<!-- more -->

# [Source][homework]

Check out and download the source [on GitHub][homework].

# What

This is a LaTeX document class. That means you use it with
`\documentclass{homework}` at the top of the document. It provides a document
layout and some helper commands that make working with questions easy.

# Installation

Certainly the easiest way to start using this template is to copy the .cls file
to your computer in the same directory as your LaTeX project directory.

A better way to install this template is to fork [the above
repository][homework] and then clone that fork to a particular folder on your
computer:

<figure>

```{.bash .numberLines}
git clone https://github.com/<your-username>/latex-hw-template
```

<figcaption>Install</figcaption>
</figure>

Then, whenever you need to use the template, you can copy the template wherever.
Also, if there are ever any updates, you can simply run

<figure>

```{.bash .numberLines}
git pull
```

<figcaption>Update</figcaption>
</figure>

to update the template.

## Preferred Installation

The _best_ way to install this file is to [follow the instructions
here][install], keeping in mind that you're trying to install a `.cls` file
instead of three `.sty` files.

[install]: https://github.com/jez/latex-solarized#installation

# Usage

See the [homework.tex][homework.tex] file for an exhaustive list of usage
examples. There are also comments explaining features for which there are no
examples given.

The result is the following:

[![](/assets/img/homework-class.png)](/assets/img/homework-class.png)

The class file also has a bunch of helper `\usepackage`s that you might want to
take a look at in [homework.cls][homework.cls].

For your convenience, the file [template.tex][template.tex] is a nearly-empty
LaTeX file that contains the bare essentials to get started using the homework
class.

## `\question`

To start a question, just type `\question`. It will add the text "Question #"
with a line underneath to the document. If you'd like to change "Question" to
something else, use

<figure>

```{.tex .numberLines}
\renewcommand{\questiontype}{Whatever You Want}
% Now questions will be titled "Whatever You Want #"
```

<figcaption>Change the Question Type</figcaption>
</figure>

Similarly, if you ever need to skip numbers, you can do

<figure>

```{.tex .numberLines}
\setcounter{\questionCounter}{<target number - 1>}
```

<figcaption>Non-contiguous Question Numbers</figcaption>
</figure>

So, to skip to the 10th question, `<target number - 1>` = 9.

See [homework.tex][homework.tex] for more.

## `\question*`

Some classes like to give their homework questions fancy names. If this is the
case, you can use `\question*{The Question's Name}` to make a named question.

See [homework.tex][homework.tex] for more.

## Question Parts

Another common thing on homework assignments is to have multi-part questions. To
deal with these, use the form

<figure>

```tex
\begin{alphaparts}
  \questionpart
    This will be part (a).
  \questionpart
    This will be part (b).
\end{alphaparts}
```

<figcaption>Lettered Question Parts</figcaption>
</figure>

or

<figure>

```{.tex .numberLines}
\begin{arabicparts}
  \questionpart
    This will be part x.1.
  \questionpart
    This will be part x.2.
\end{arabicparts}
```

<figcaption>Numbered Question Parts</figcaption>
</figure>

See [homework.tex][homework.tex] for more.

## Induction Proofs

In math classes, induction proofs come up a lot, and they almost always have the
same form: base case, induction hypothesis, and induction step.

<figure>

```{.tex .numberLines}
\begin{induction}
  \basecase
    This is my fancy base case.
  \indhyp
    Assume some claim.
  \indstep
    Finish off the proof
\end{induction}
```

<figcaption>Induction Environment</figcaption>
</figure>

# Markdown

One of my favorite features of this document class is that it redefines the
`\section` macros. This means you can use tools like Markdown, which have a
concise syntax, together with a tool like [`pandoc`][pandoc] to convert Markdown
into LaTeX. As an example, consider that we have the Markdown:

<figure>

```{.plain .numberLines}
#

This is my first answer.

#

This is my next answer.

$$a^2 + b^2 = c^2$$
```

<figcaption>my-homework.md</figcaption>
</figure>

Running `pandoc -f markdown -t latex my-homework.md` will output

<figure>

```{.tex .numberLines}
% $ pandoc -f markdown -t latex my-homework.md
\section{}\label{section}

This is my first answer.

\section{}\label{section-1}

This is my next answer.

\[a^2 + b^2 = c^2\]
```

<figcaption>Convert markdown to LaTeX</figcaption>
</figure>

And since `\section` is the same thing as \question, we're golden, and this
compiles as we'd want it to. Throw it into the blank
[template.tex][template.tex] file included in the repo, and you've got yourself
a typeset homework.

# More

I've make a lot of other LaTeX-related posts. Be sure to [check them out][latex]
as well! My hope is that you find something that makes developing LaTeX just
that much easier.


[homework]: https://github.com/jez/latex-homework-class
[homework.cls]: https://github.com/jez/latex-homework-class/blob/master/homework.cls
[homework.tex]: https://github.com/jez/latex-homework-class/blob/master/homework.tex
[template.tex]: https://github.com/jez/latex-homework-class/blob/master/template.tex
[pandoc]: http://johnmacfarlane.net/pandoc/
[latex]: /categories#latex
