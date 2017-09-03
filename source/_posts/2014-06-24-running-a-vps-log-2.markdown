---
layout: post
title: "Running a VPS, Log 2: Seriously, Back It Up"
date: 2014-06-24 23:11:14 -0400
comments: false
categories: [summer projects, digitalocean, best practices]
description: Purchasing DitigalOcean's auto-backup services was perhaps the best decision I've made in a long time.
share: false
permalink: /:year/:month/:day/:title/
published: false
---

I don't have the best track record with configuring servers. I've certainly brought down a ScottyLabs server or two before, but sometimes there's no avoiding that in the sake of learning. At times like these, you've just gotta reboot and try again. With DigitalOcean's auto-backups though, this process is incredibly easy.

<!-- more -->

## EncFS Troubles
As part of my eventual goal of hosting my own mail, I tried following [this post](//sealedabstract.com/code/nsa-proof-your-e-mail-in-2-hours/) to set up a mail server on my VPS. Unfortunately, I never even made it out the gates. The first step is to install and set up EncFS for letting you mount encrypted filesystems, which the tutorial was planning on using to store email securely. Unfortunately, after following the steps listed to a T, my poor VPS whined and complained about being misconfigured.

__Edit__: After doing a little more research, I found that the root of my issue wasn't something I had been doing. Apparently, you have to [manually update the kernel](https://www.digitalocean.com/community/tutorials/how-to-update-a-digitalocean-server-s-kernel-using-the-control-panel) through the DigitalOcean web console. You can read more about it on this [GitHub issue](https://github.com/al3x/sovereign/issues/147#issuecomment-43849647).

Regardless, my first attempt to do something cool on this new VPS was a dud. All I had to show for it was a muddled, no-longer-pristine VPS with some packages and libraries that simply didn't work. If I were to continue with the tutorial by skipping this step, I would have never known whether the cause of any future issue was something misconfigured at this step.

## The Day is Saved
But then I remembered: DigitalOcean is automatically backing up my droplet! After logging into the web interface, all I had to do was click a button and my whole system was reset to the way it looked 24 hours prior. It was _actually that easy_.

Thus, for anyone getting started with a new server, whether it be on DigitalOcean or any other service (even a box you have running in your room), I cannot stress enough the value of automatic--or at least regular--backups. Not only is this a good idea to preserve data in the event of an outage, but it lends a seemingly unbounded ability to mess around and tinker.

What this means is that you get all the fun of learning cool, new Linux-y things, but without ever having to worry about whether you'll break the whole system. Sure, this mindset isn't necessarily the best to adopt for a production machine, but for my circumstances, all I want is free reign to experiment and break things to my heart's content.

## Back to Square One
With my first attempt at installing a mail server foiled, I think for my next attempt I'll try a different path. Instead of installing and configuring everything more or less manually (I really wanted to do this for the experience of it all, learning the nitty-gritty of how it works), this time around I think I'm going to give [sovereign](https://github.com/al3x/sovereign) a try. I've heard good things, and it is in fact based on the original tutorial I had found, so it's looking pretty promising as of yet.

Whatever happens though, I'm feeling pretty good about the fact that I can turn things around with a single click.

