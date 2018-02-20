---
layout: post
title: "A LaTeX Homework Template"
date: 2014-10-04 02:03:27 -0400
comments: false
categories: ['latex']
description: "All about what template I use for LaTeX on homework assignments."
share: false
permalink: /:year/:month/:day/:title/
---

Writing a LaTeX document from scratch for every assignment is tedious. Especially for homework assignments, a lot of the structure is repetitive. Read on to learn about the homework template I've adapted for use in all my technical classes.

<!-- more -->

## Background

I've been using LaTeX for assignments in college for over a year now, and from the get-go I loved it; It's a powerful way to transform plain text (which is editable in Vim!) into beautiful documents. In fact, I use LaTeX + Vim or Google Docs exclusively--no Microsoft Office. People often don't understand why I prefer this combination, claiming that LaTeX is time consuming and tedious. But with a good template and some Vim-foo, editing LaTeX is a breeze. In a later post, I'll elaborate how I use Vim + Unix as an IDE for LaTeX. For now, though, let's take a look at my template!

## [The Template][template-github]

For those who like to learn by doing, I invite you to __[jump over to GitHub][template-github]__ where you can see the source, download the template, and start tinkering. The source isn't that long, and it comes with tons of examples to get you going. 

The rest of this post goes into some fancy use cases for how to get the best out of this template. If you don't read it now, check it out later if you want to take advantage of it's more powerful features. You can also leave comments here asking how something works, and issues on GitHub if something's broken.

## Screenshot

Here's a quick overview of what the theme looks like. You'll have to use your imagination a bit: this outline is more of a list of examples. I'd show you how nice one of my actual homeworks looks, but then I'd be giving out my homework!

{% img https://raw.githubusercontent.com/jez/latex-hw-template/master/screenshot.png %}

## Usage

My main use case for LaTeX is (unsurprisingly) to typeset homeworks for math and CS classes. In these classes, the questions are either numbered or have specific names, and they ask for your name, lecture, recitation section, student ID, email address, etc. It turns out that there are some pretty simple ways of modularizing each of these desired features.

### Personal Info

To solve the issue of entering personal information, the template defines a bunch of commands at the top of the file that enumerate all the fields you'll likely want to include on your homework.

```latex Personal Information 
\newcommand{\myname}{Jacob Zimmerman}
\newcommand{\myemail}{jezimmer}
\newcommand{\myhwtype}{Homework}
\newcommand{\myhwnum}{0}
\newcommand{\myclass}{12-345}
\newcommand{\mylecture}{0}
\newcommand{\mysection}{Z}
``` 

__This is where forking comes in particularly handy__. You'd like to be able to define your own defaults and push them somewhere, but you also want to be able to update the template as new changes become available. If you fork the repo, you can both have a repository where you can include your own changes as well as pull any updates as they become available. (If you're new to forks, you should definitely [check them out][forks]).

### Questions

Whenever I have an assignment to do, the questions generally come down to one of two forms: named or numbered questions. As such, there are two environments in the template that let you easily create a space to put your answers for each type of question. These are named `namedquestion` and `numedquestion` (__not__ `numberedquestion`).

__The `namedquestion` environment__ takes one required argument: the name! This environment is handy any time the questions don't have numbers attached to them, or if the ordering of the questions doesn't conform nicely to a sequential numbering.

__The `numedquestion` environment__ takes no arguments, but that doesn't mean you can't configure it. By default, `numedquestions` begin counting at 1 and go up sequentially from there. To change this, you manually set the contents of the `questionCounter` counter. Using 

```latex
\setcounter{questionCounter}{-1}
```

Before the first question will start the numbering at 0. You can use this pattern (set the `questionCounter` to one less than the next question) to arbitrarily skip around with your numbering. There's an example of this in the source.

There are also times when you'd like numbered questions to be of the form "X.y", where "X" is the section number that the question comes from, and "y" is the number of the question within that section. The template tracks the value of "X" in `\writtensection`. By default, the template sets this to 0, which causes the section number to be omitted. If you manually set `\writtensection` to a non-zero value, this number will be prepended to all questions. When you do this, the value of "y" is determined by `questionCounter`.

Similar to what we could do with `questionCounter`, you can manually turn on the section counter for certain questions by including something like 

```
\renewcommand{\writtensection}{X}
```

in front of that particular question. Use `\renewcommand{\writtensection}{0}` after that question if you'd like to turn it back off.

### Question Parts

All in all, these two environments will take care of 90% of what you need to do in your homework. Sometimes, though, questions have multiple parts. To handle this, there are two environments, `alphaparts` and `arabicparts`, that take care of alphabetic and numeric question parts, respectively.

The uses of these environments are pretty straightforward and have no real special cases. Each environment wraps around the `enumerate` environment. This means you can just use a normal `\item` to indicate a specific part of the question.

### Induction Proofs

There's one more thing that I'd like to mention here. Different people have different ways of typesetting induction proofs, with varying degrees of success. Personally, I like the `description` environment for outlining the base case, induction hypothesis, and inductive step of the proof. It works well for basically every induction proof, and looks nice and clean.

## Feedback

Be sure to let me know how you like this template! It works for me, but obviously I'm only using it for a small number of things on exactly one system. If something doesn't seem to work, or if you'd like to see a particular feature implemented, comment or create a GitHub issue to let me know! 


[template-github]: https://github.com/jez/latex-hw-template
[forks]: https://help.github.com/articles/fork-a-repo/
