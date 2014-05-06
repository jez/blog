---
layout: post
title: "Adding a Network Printer to a Linux Server"
date: 2014-05-06 02:09:29 -0400
comments: true
categories: [linux, print-sl, printing, CUPS]
---

As I mentioned in my last post, I'm a part of a student organization called [ScottyLabs](//www.scottylabs.org). We do tons of cool things, but the project which I'm currently working on is [Print@ScottyLabs](//print.scottylabs.org). It's a really handy service which lets you send an attachment to <mailto:print@scottylabs.org> and have it sent to the printer. I'm currently in the process of rewriting much of the code base from scratch to support a plethora of highly-requested features, so there will no doubt be more posts about my exploits in this area. In this post, I'd like to talk about my most recent task: configuring our server to send jobs to a school-affiliated, network-attached printer using CUPS. <!-- more --><a href="#tldr">tl;dr</a>

## The Hard Way
Luckily, CMU (and arguably every college) is not terribly notable for keeping up-to-date information on it's website. This means that I got the wonderful opportunity to dig through CUPS documentation, sketchy printer manufacturer websites, and the depths of the Internet to finagle together a solution. Here's to hoping that you have a far more pleasurable experience. These are the steps I went through to get it done, so without further ado...

## What Didn't Work
The Common Unix Printing System (CUPS) is a relatively new standard which is designed to improve over the rather haphazard methods used for printing in the past. It improves in a lot of ways and has a few neat features. One of these is a handy web interface which lets you interact with your configuration files, add printers, view the print queue, etc. through a beginner-friendly GUI, which I was when I started and I still am now. 

By default, when `cupsd` (the CUPS daemon) starts up, it listens on `localhost` port 631 for incoming HTTP requests (note that by default external requests are refused, so you can either enable these or [tunnel your traffic](http://ubuntuguide.org/wiki/Using_SSH_to_Port_Forward) through an `ssh` proxy). Additionally, you must be either `root` or in the `lpadmin` group to access the administration parts of this web GUI.

For whatever reason, neither using the `root` username and password nor adding myself to the `lpadmin ` group worked. I was incessantly blocked by the interface when I tried to give it my credentials for adding a printer using this interface. Defeated, I needed to find another way. I’m telling you this as a sort of justification for the super hacky solution that I came up with (but that works in the end, even if it’s non-standard). If you have any ideas on why this failed, I'd love to hear them!

## When in doubt, duct tape
The instructions to install CMU print drivers on Linux only work for environments with desktop environments installed. (You can read these instructions [here](http://www.cmu.edu/computing/clusters/printing/how-to/linux/pers-cluster.html)). So, in keeping with the UNIX philosophy that everything’s a file, the solution I came up with was essentially to follow these instructions on a __personal Linux box__, then __copy and modify__ the corresponding files to achieve the same effect on the server we need them to be on.

It’s at this point that you’re probably wondering why I didn’t just do a little research and figure out how to make these modifications myself. There are a couple of reasons. First, that takes a lot of time. Second, when you install a CUPS printer, you need a PostScript Printer Description (PPD) file to tell CUPS how the printer works. Despite my best efforts searching the web, I couldn’t find a central repository where these .ppd files were stored. However, most desktop environments have the ability to search __somewhere mystical__ (read: you should tell me if you know) and download these .ppd files. 

<a name="tldr"></a>
## Do you think I really care, just tell me how it works 
The process is not too complicated. Go back to that [website from above](http://www.cmu.edu/computing/clusters/printing/how-to/linux/pers-cluster.html) and follow the instructions to install a printer on a personal Linux machine. They should be fairly self explanatory. Say perhaps that you want to install the print drivers for the queue `andrew-color`. After following along and inserting “andrew-color” as the print queue where required, you’ll come up to a screen that asks you to name your printer. This name does not have to be the name of the queue, but I always make it that. Either way, remember what you enter as your name for the printer (again, I’m using the name “andrew-color”). 

Also, part of the process should involve you specifying a PPD file. The easiest way to do this is to go to a printer that dispatches jobs from that queue and to get the make and model for it. In the case of andrew-color, the Wean printer is an HP Color LaserJet CP6015x. Using this information, we can query some magic box for the right PPD file, which is important.

Now that everything is all installed, we can pluck the information we need. If you’re on a standard Linux install, your CUPS files will be in `/etc/cups`. The specific files that are of interest to us are `/etc/cups/printers.conf` and `/etc/cups/ppd/<your-printer-name>.ppd`, so my file is called `/etc/cups/ppd/andrew-color.ppd`. We need the entire .ppd file, and it will go into the corresponding directory on our server. As for `printers.conf`, we just need a specific entry. This file is a list of all the installed printers, each wrapped in `<Printer your-printer-name></Printer>` tags. Yank this text however you want from your local computer to the server, and add it to the corresponding `printers.conf` file. If your personal Linux machine made the `<Printer></Printer>` tags into `<DefaultPrinter x></DefaultPrinter>` tags, go ahead and change this to just `<Printer x></Printer>`. To recap, now I’ve got about 20 lines of configuration data, which begins with the line `<Printer andrew-color>` and ends with the line `</Printer>`.

Somewhere in the middle of this entry, there should be a line which reads something like `Filter application/vnd.cups-postscript 0 hpps`. CUPS has a filtering functionality that lets you interact with the data before it gets printed, which you can read more about [here](http://en.wikipedia.org/wiki/CUPS#Filtering_process). We want to make sure that we use the `foomatic` filters (because that's how our server is configured), so we have to change the existing filters so that they read
```
Filter application/vnd.cups-raw 0 -
Filter application/vnd.cups-postscript 100 foomatic-rip
Filter application/vnd.cups-pdf 0 foomatic-rip
```
in the end. After all this, if you’ve copied the PPD file into the right folder (`/etc/cups/ppd/`), then you’re all set! Restart CUPS with `sudo /etc/init.d/cups restart` so that your changes take effect. You can print using `lp` and the `-d` flag to specify the print queue you want. Remember that we picked the name “andrew-color” for our print queue above, so a sample `lp` command would look like this:

`lp -t ‘My First Color Print Job’ -U jezimmer -d andrew-color /path/to/myfile.pdf`

Happy printing!

{% include jake-on-the-web.markdown %}


