---
layout: post
title: "Offline LaTeX Development"
date: 2014-10-06 18:00:00 -0400
comments: true
categories: [LaTeX, make, vim, unix]
description: 
image:
  feature: /images/abstract-7.jpg
  credit: dargadgetz
  creditlink: http://www.dargadgetz.com/ios-7-abstract-wallpaper-pack-for-iphone-5-and-ipod-touch-retina/
share: true
---

While online clients like ShareLaTeX or writeLaTeX are popular for getting started with LaTeX quickly, developing LaTeX locally with Vim and the command line is my preferred LaTeX workflow. In this post, I'll describe the changes I've made that make working with LaTeX on the command line a seamless experience. 

<!-- more -->

## Install LaTeX

Obviously, to work with LaTeX locally, you'll need LaTeX installed. To check if you already have it installed, you can run `which pdflatex`. If it's installed, this command will tell you the path to program. Otherwise, it won't print anything.

### On Linux

Installing LaTeX on Linux isn't too bad. Usually it's included in your distribution's package manager. I'll be focusing on OS X for the majority of this post though, so Google around if you end up having trouble.

### On OS X

To install LaTeX on a Mac, we'll be installing MacTeX, which includes the command line LaTeX utilities as well as a couple graphical clients for LaTeX development. You can try compiling from source, but as Homebrew points out when you try to `brew install linux`:

```plain brew install latex
$ brew install latex
Error: No available formula for latex
Installing TeX from source is weird and gross, requires a lot of patches,
and only builds 32-bit (and thus can't use Homebrew deps on Snow Leopard.)

We recommend using a MacTeX distribution: http://www.tug.org/mactex/
```

With that in mind, head on over to [http://www.tug.org/mactex/](http://www.tug.org/mactex/) and download the file `MacTeX.pkg `. Once this has downloaded and you've clicked through the installer, you should be ready to go with LaTeX. Verify this by running `which pdflatex` again.

## Use Vim

The biggest productivity improvement you gain from developing LaTeX locally is that you get to use Vim. Make sure you have a nice colorscheme for both your terminal and for Vim. __I can't stress enough how important it is to make your terminal look nice__: you want to enjoy your terminal experience, and this is one of the easiest ways to do so.

## Use Make

Compiling LaTeX is pretty straightforward. To generate a PDF, all you have to do is run the command 

```bash pdflatex
$ pdflatex <myfile>.tex
```

And you'll get a file called `<myfile>.pdf` in the current directory, plus some intermediate files. We can go one step further and put a bunch of useful build targets into a Makefile and use it to build our PDF:

```make LaTeX Makefile https://gist.github.com/Z1MM32M4N/b248a409d19c9f1c94cd
# NOTE: Change "written" to the name of your TeX file with no extension
TARGET=written

all: $(TARGET).pdf

## Generalized rule: how to build a .pdf from each .tex
LATEXPDFS=$(patsubst %.tex,%.pdf,$(wildcard *.tex))
$(LATEXPDFS): %.pdf: %.tex
  pdflatex -interaction nonstopmode $(patsubst %.pdf,%.tex,$@)

clean:
  rm *.aux *.log || true

veryclean: clean
  rm $(TARGET).pdf

view: $(TARGET).pdf
  if [ "Darwin" = "$(shell uname)" ]; then open $(TARGET).pdf ; else evince $(TARGET).pdf ; fi

submit: $(TARGET).pdf
  cp $(TARGET).pdf ../

print: $(TARGET).pdf
  lpr $(TARGET).pdf

.PHONY: all clean veryclean view print
```

If you save this to a file called `Makefile` in the same directory as your LaTeX file, we can just run `make` instead of running `pdflatex <myfile>.tex`!

As you can see, there are a bunch of other handy targets here:

- `make clean` will remove all intermediate files that are created.
- `make veryclean` will remove all intermediate files and the compiled PDF file.
- `make view` will compile the file and then open it up in a PDF viewer (if you're on OS X, or on Linux and have `evince` installed).
- `make print` will send your document to the default printer with the default options for that printer.
- `make submit` will copy your file into the parent directory. This is handy when you're working in a subfolder on an assignment to isolate the intermediate files, but your class has provided a handin script that needs the PDF file to be in the parent directory.

## Workflow Tips

Right now, our workflow looks like this:

- Create TeX file
- Edit in Vim
- Switch to terminal
- Run make view to compile and view

We can actually optimize this workflow to one less step: we don't have to get out of Vim to run make!

Vim has a command `:make` that will look for a Makefile in the current directory and run it's `all` target. It also takes a target as an optional argument, so we can do `:make view` to compile and view the document from within Vim!

Taking this one step further, we can add a command to shorten this. If we add

```vim Save, Compile and View in Vim
command WV w | make view
```

to our `.vimrc`, we'll only have to type `:WV` to save, compile, and view our PDF output.

## Wrap Up

That's it! I like this experience for a bunch of reasons:

- __It's faster__. Compiling LaTeX without having to wait for a web client to load is really nice.
- __It's more stable__. You can still edit, compile, and view your work if you don't have access to the Internet.
- __It's faster__. Using Vim to edit text is much more convenient than a standard text editor.

Do you have a LaTeX tip, a fancier Makefile, or a favorite vim plugin for LaTeX? Share it in the comments!

{% include jake-on-the-web.markdown %}

