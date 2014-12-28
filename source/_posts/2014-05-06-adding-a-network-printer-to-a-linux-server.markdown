---
layout: post
title: "Adding a Network Printer to a Linux Server"
description: "A walkthrough of how I installed a network-attached printer to a production printing server."
date: 2014-05-06 02:09:29 -0400
comments: true
categories: [linux, printing]
share: true
---

It's one thing to plug in a CD, click through a few dialogs, and wait for the computer to chime at you saying that your printer has been installed. Unfortunately, this is not how server administration works. Here's my account of installing multiple network-attached printers on a Debian server.

<!-- more -->

## TL;DR
For those who only care about the solution: <a href="#tldr">TL;DR</a>.

## The Hard Way
As I mentioned in my last post, I'm a part of a student organization called [ScottyLabs](//www.scottylabs.org). We do tons of cool things, but the project which I'm currently working on is [Print@ScottyLabs](//print.scottylabs.org). It's a really handy service which lets you send an attachment to <mailto:print@scottylabs.org> and have it sent to the printer. I'm currently in the process of rewriting much of the code base from scratch to support a plethora of highly-requested features, so there will no doubt be more posts about my exploits.

Luckily, CMU (and arguably every college) is not terribly notable for keeping up-to-date information on it's website. This means that I got the "wonderful" opportunity to dig through CUPS documentation, sketchy printer manufacturer websites, and the depths of the Internet to finagle together a solution. Here's to hoping that you have a far more pleasurable experience. Without further ado, these are the steps I went through to get it done.

## What Didn't Work
The Common Unix Printing System (CUPS) is a relatively new standard which is designed to improve over the rather haphazard methods used for printing in the past. It improves in a lot of ways and has a few neat features. One of these is a handy web interface which lets you interact with your configuration files, add printers, view the print queue, etc. through a beginner-friendly GUI, which described me perfectly when I started and still does now.

By default, when `cupsd` (the CUPS daemon) starts up, it listens on `http://localhost:631` incoming HTTP requests. By default, external requests are refused. You can either enable these in a configuration file somewhere or [tunnel your traffic](http://ubuntuguide.org/wiki/Using_SSH_to_Port_Forward) through an `ssh` proxy, "tricking" the server into thinking your requests are coming locally. Additionally, you must be either `root` or in the `lpadmin` group to access the administration parts of this web GUI.

But for whatever reason, neither using the `root` username and password nor adding myself to the `lpadmin ` group worked. I was incessantly blocked by the interface when I tried to give it my credentials. Defeated, I needed to find another way.

I’m telling you this as a sort of justification for the super hacky solution that I came up with (but that works in the end, even if it’s non-standard). If you have any ideas on why this failed, I'd love to hear them!

## When in doubt, duct tape
The instructions to install CMU print drivers on Linux only work for environments with desktop environments installed. (You can read these instructions [here](http://www.cmu.edu/computing/clusters/printing/how-to/linux/pers-cluster.html)). So, in keeping with the UNIX philosophy that everything’s a file, the solution I came up with was essentially to follow these instructions on a __personal Linux box__, then __copy and modify__ the corresponding files to achieve the same effect on the server we need them to be on.

It’s at this point that you’re probably wondering why I didn’t just do a little research and figure out how to make these modifications myself, or perhaps figure out where the files I needed were coming from. There are a couple of reasons. First, that takes a lot of time, I'm lazy, and whatever I came up with didn't need to scale. Second, when you install a CUPS printer, you need a PostScript Printer Description (PPD) file to tell CUPS how the printer works. Despite my best efforts searching the web, I couldn’t find a central repository where these .ppd files were stored. However, most desktop environments have the ability to search __somewhere mystical__ (read: you should tell me if you know) and download these .ppd files.

<a name="tldr"></a>
## Do you think I really care, just tell me how it works
The process is not too complicated. Go back to the [CMU instructions](http://www.cmu.edu/computing/clusters/printing/how-to/linux/pers-cluster.html) to install a printer on a personal Linux machine. Following them should be fairly self explanatory. Say perhaps that you want to install the print drivers for the queue `andrew-color`. After following along and inserting “andrew-color” as the print queue where required, you’ll come up to a screen that asks you to name your printer. This name does not have to be the name of the queue, but I always make it that when I'm working with the CMU printers. Either way, be sure to remember what you entered for this name (again, I’m using the name “andrew-color”).

Also, part of the process should involve you specifying a PPD file. The easiest way to do this is to go to a printer that dispatches jobs from that queue and to get the make and model for it. In the case of andrew-color, the Wean printer is an HP Color LaserJet CP6015x. Using this information, we can use the Gnome/KDE/XFCE window, enter our make and model, and have it spit out the recommended PPD file to use (although it likely won't call as such).

Now that everything is all installed, we can pluck the information we need. If you’re on a standard Linux install, your CUPS files will be in `/etc/cups`. The specific files that are of interest to us are `/etc/cups/printers.conf` and `/etc/cups/ppd/<your-printer-name>.ppd`, so my file is called `/etc/cups/ppd/andrew-color.ppd`. We need the entire .ppd file, and it will go into the corresponding directory on our server. As for `printers.conf`, we just need a specific entry. This file is a list of all the installed printers, each wrapped in `<Printer your-printer-name></Printer>` tags. Yank this text however you want from your local computer to the server, and add it to the corresponding `printers.conf` file. If your personal Linux machine made the `<Printer></Printer>` tags into `<DefaultPrinter x></DefaultPrinter>` tags, go ahead and change this to just `<Printer x></Printer>`. To recap, now I’ve got about 20 lines of additional configuration data added to the `printers.conf` file on my server, beginning with the line `<Printer andrew-color>` and ends with the line `</Printer>`.

For my installation, I have one more thing to do. Somewhere in the middle of this entry, there is a line which reads something like `Filter application/vnd.cups-postscript 0 hpps`. CUPS has a filtering functionality that lets you interact with the data before it gets printed, which you can read more about [here](http://en.wikipedia.org/wiki/CUPS#Filtering_process). We want to make sure that we use the `foomatic` filters (because that's how our server is configured), so we have to change the existing filters so that they read
~~~
Filter application/vnd.cups-raw 0 -
Filter application/vnd.cups-postscript 100 foomatic-rip
Filter application/vnd.cups-pdf 0 foomatic-rip
~~~
After all this, if you’ve copied the PPD file into the right folder (`/etc/cups/ppd/`), then you’re all set! Restart CUPS with `sudo /etc/init.d/cups restart` so that your changes take effect. You can print using `lp` and the `-d` flag to specify the print queue you want. Remember that we picked the name “andrew-color” for our print queue above, so a sample `lp` command would look like this:

`lp -t ‘My First Color Print Job’ -U jezimmer -d andrew-color /path/to/myfile.pdf`

Happy printing!

{% include jake-on-the-web.markdown %}


