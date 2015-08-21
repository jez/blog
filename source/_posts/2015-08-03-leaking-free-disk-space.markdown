---
layout: post
title: "Leaking Free Disk Space"
date: 2015-08-03 00:05:31 -0700
comments: true
categories: ['linux']
description: >
  I finally tracked down a free disk space leakage that's been bothering me for
  months.
image:
  feature: /images/abstract-1.jpg
  credit: dargadgetz
  creditlink: http://www.dargadgetz.com/ios-7-abstract-wallpaper-pack-for-iphone-5-and-ipod-touch-retina/
share: true
---

I've been watching a disk space leakage creep slowly upwards for months now;
finally, I figured out where it was going!

<!-- more -->

Whenever I set up a VPS, I follow Brian Kennedy's excellent [My First 5 Minutes
On A Server; Or, Essential Security for Linux Servers][essential]. It covers
setting up a number of initial tools that make server administration much
easier:

- fail2ban, for blocking suspicious log in activity
- setting up a non-root user
- ufw, a simple firewall program
- unattended-upgrades, which installs security upgrades periodically
- logwatch, so you can read a digest of what's happened in your logs

Ever since I set up my VPS, I'd seen the disk space creep up in the daily
logwatch digest. I had looked a few times and figured it must be related to some
sort of misconfiguration of the Ruby app server I have running on it right now.

Recently, it got up to more than half of my disk space gone. For a VPS that I
used maybe twice a month, this was ridiculous. I investigated once more and
finally came up with the culprit: `unattended-upgrades` wasn't autoremoving
packages. I had gigabytes worth of packages that could be autoremoved.

## Solution

There's a one-line config file fix. Add this to
/etc/apt/apt.conf.d/50unattended-upgrades:

```plain /etc/apt/apt.conf.d/50unattended-upgrades
...
// Do automatic removal of new unused dependencies after the upgrade
// (equivalent to apt-get autoremove)
Unattended-Upgrade::Remove-Unused-Dependencies "true";
...
```

Update: It looks like a bug in unattented-upgrades is [preventing it from
automatically removing header packages][bug]. For the time being you will have
to either manually auto-remove these packages, or add `sudo apt-get autoremove
-y` to your crontab.

{% include jake-on-the-web.markdown %}


[essential]: http://plusbryan.com/my-first-5-minutes-on-a-server-or-essential-security-for-linux-servers
[bug]: https://bugs.launchpad.net/ubuntu/+source/unattended-upgrades/+bug/1267059
