---
layout: post
title: "The LaTeX homework Document Class"
date: 2014-12-21 03:15:03 -0600
comments: true
categories: [latex]
description: "A LaTeX \\documentclass for typesetting homework assignments."
image:
  feature: /images/homework-class.png
share: true
---

There are LaTeX document classes for typesetting books, articles, exams, presentations, and more. Now, there's one for homework assignments, too.

<!-- more -->

## [Source][homework]

Check out and download the source [on GitHub][homework].

## What

This is a LaTeX document class. That means you use it with `\documentclass{homework}` at the top of the document. It provides a document layout and some helper commands that make working with questions easy.

## Installation
Certainly the easiest way to start using this template is to copy the .cls file to your computer in the same directory as your LaTeX project directory.

A better way to install this template is to fork [the above repository][homework] and then clone that fork to a particular folder on your computer:

```bash Install
git clone https://github.com/<your-username>/latex-hw-template
```

Then, whenever you need to use the template, you can copy the template wherever. Also, if there are ever any updates, you can simply run

```bash Update
git pull
```

to update the template.

### Preferred Installation

The _best_ way to install this file is to [follow the instructions here][install], keeping in mind that you're trying to install a `.cls` file instead of three `.sty` files.

[install]: https://github.com/Z1MM32M4N/latex-solarized#installation

## Usage

See the [homework.tex][homework.tex] file for an exhaustive list of usage examples. There are also comments explaining features for which there are no examples given.

The result is the following:

{% img /images/homework-class.png %}

The class file also has a bunch of helper `\usepackage`s that you might want to take a look at in [homework.cls][homework.cls].

For your convenience, the file [template.tex][template.tex] is a nearly-empty
LaTeX file that contains the bare essentials to get started using the homework
class.

### `\question`

To start a question, just type `\question`. It will add the text "Question #" with a line underneath to the document. If you'd like to change "Question" to something else, use

```tex Change the Question Type
\renewcommand{\questiontype}{Whatever You Want}
% Now questions will be titled "Whatever You Want #"
```

Similarly, if you ever need to skip numbers, you can do

```tex Non-contiguous Question Numbers
\setcounter{\questionCounter}{<target number - 1>}
```

So, to skip to the 10th question, `<target number - 1>` = 9.

See [homework.tex][homework.tex] for more.

### `\question*`

Some classes like to give their homework questions fancy names. If this is the case, you can use `\question*{The Question's Name}` to make a named question.

See [homework.tex][homework.tex] for more.

### Question Parts

Another common thing on homework assignments is to have multi-part questions. To deal with these, use the form

```tex Lettered Question Parts
\begin{alphaparts}
  \questionpart
    This will be part (a).
  \questionpart
    This will be part (b).
\end{alphaparts}
```
or
```tex Numbered Question Parts
\begin{arabicparts}
  \questionpart
    This will be part x.1.
  \questionpart
    This will be part x.2.
\end{arabicparts}
```

See [homework.tex][homework.tex] for more.

### Induction Proofs

In math classes, induction proofs come up a lot, and they almost always have the same form: base case, induction hypothesis, and induction step.

```tex Induction Environment
\begin{induction}
  \basecase
    This is my fancy base case.
  \indhyp
    Assume some claim.
  \indstep
    Finish off the proof
\end{induction}
```

## Markdown

One of my favorite features of this document class is that it redefines the `\section` macros. This means you can use tools like Markdown, which have a concise syntax, together with a tool like [`pandoc`][pandoc] to convert Markdown into LaTeX. As an example, consider that we have the Markdown:

```plain my-homework.md
#

This is my first answer.

#

This is my next answer.

$$a^2 + b^2 = c^2$$
```

Running `pandoc -f markdown -t latex my-homework.md` will output

```tex Convert markdown to LaTeX
% $ pandoc -f markdown -t latex my-homework.md
\section{}\label{section}

This is my first answer.

\section{}\label{section-1}

This is my next answer.

\[a^2 + b^2 = c^2\]
```

And since `\section` is the same thing as \question, we're golden, and this compiles as we'd want it to. Throw it into the blank [template.tex][template.tex] file included in the repo, and you've got yourself a typeset homework.

## More

I've make a lot of other LaTeX-related posts. Be sure to [check them out][latex] as well! My hope is that you find something that makes developing LaTeX just that much easier.

{% include jake-on-the-web.markdown %}

[homework]: https://github.com/Z1MM32M4N/latex-homework-class
[homework.cls]: https://github.com/Z1MM32M4N/latex-homework-class/blob/master/homework.cls
[homework.tex]: https://github.com/Z1MM32M4N/latex-homework-class/blob/master/homework.tex
[template.tex]: https://github.com/Z1MM32M4N/latex-homework-class/blob/master/template.tex
[pandoc]: http://johnmacfarlane.net/pandoc/
[latex]: /categories#latex
