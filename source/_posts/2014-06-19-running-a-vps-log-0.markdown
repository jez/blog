---
layout: post
title: "Running a VPS: Log 0"
date: 2014-06-19 21:45:29 -0400
comments: true
categories: [linux, vps, summer projects, security, intro]
description: My VPS setup, from provider to deployment to inital setup.
image:
  feature: /images/blue-ring.png
share: true
---

Since last Christmas, I've had a raspberry pi running as a server at my home back in Wisconsin. I had tons of plans for this little guy, but I quickly discovered that he was going to be a bit _too_ little for most of them. Thus, I am now the proud sysadmin of my own virtual private server. 

<!-- more -->

## Hosting
Because at this point in my life I'm moving around too much to host my own server somewhere, I decided to contract this part out. I didn't look around too much at VPS providers, but I eventually settled in on DigitalOcean, because it was both recommended at the CClub talk and the most cost-effective of the all the providers I checked. For $10 per month I get a 1-core processor, 1GB of RAM, 30GB of SSD storage, and 2TB of network data transfer. More than enough for a casual VPS.

## [Safety First](http://plusbryan.com/my-first-5-minutes-on-a-server-or-essential-security-for-linux-servers)
Especially in light of recent security and privacy breeches, the first thing to do on any server is to lock it down. For that, I followed [these instructions](http://plusbryan.com/my-first-5-minutes-on-a-server-or-essential-security-for-linux-servers), with a few modifications. 

The post goes over setting up a few simple daemons and setup commands that can be completed in 5 minutes if you've done this before or half an hour if you want to stop and read up on all the protocols as you go. While I won't reiterate the steps, the list includes setting up the root and an additional sudo user, installing [fail2ban](http://www.fail2ban.org/wiki/index.php/Main_Page) for combating brute-force login attempts, setting up ssh logins, setting up a firewall with [Uncomplicated Firewall](https://wiki.ubuntu.com/UncomplicatedFirewall), and a few other sanity checks.

## Personalization
At this point, the server was safe, but I still couldn't call it "mine." My .bash_profile, .vimrc, and all my other configuration scripts were missing. Fortunately, I had prepared for this moment, and getting everything in working order was incredibly easy. Because there's so much to talk about, I'll be [writing about it] in another post, but in the meantime, I'm using a program called [rcm](https://github.com/thoughtbot/rcm) that turns [GitHub](https://github.com/Z1MM32M4N/dotfiles) into the perfect place to store configuration scripts.

I also spent a long time pondering the consequences of [this comic](http://xkcd.com/910/). Eventually I settled on the name of my favorite Pokemon: Metagross. So without further ado, I'd like to introduce my shiny new login message:

<center>
{% img /images/metagross-motd.png %}
</center>

## Onwards
So there we are! I've got a bunch of things in the works and even more things planned, so it should be a nice, long-running summer project.

- - -
### For the Curious
While I didn't end up using my raspberry pi very extensively, I did manage to get a few things out of it. For one, it gave me my first experiences using Arch Linux. Admittedly, I didn't get the full experience as it came essentially pre-loaded with it, but it was an experience nonetheless. At some point, once I've settled into living in one place for more than a few months, I plan on building a desktop and running Arch for the lulz.

Also, and this part is still the biggest reason why I keep it up, is that I can run the No-IP Dynamic Update Client as a daemon to keep tabs on the public IP address for my house back in Wisconsin. This lets me do cool things, like ssh into my raspi from anywhere, administer my family's wireless router when it breaks, and potentially log into one of their computers if I needed to (although whenever I do remote into their computer's, I almost always use the Chrome Remote Desktop Client because it's incredibly easy to use but still entirely full-featured).
