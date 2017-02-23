---
layout: post
title: "Setting up MobaXterm for SSH on Windows"
date: 2014-09-28 14:11:05 -0400
comments: false
categories: [terminal]
description: "How to set up MobaXterm and why you should"
share: false
---

For an optimal SSH experience, your best best is to use Linux or Mac OS X. However, if you're dead-set on using Windows, MobaXterm has the best overall experience. This post guides you through setting it up and outlines some of its coolest features.

<!-- more -->

## Download and Install
The download and installation procedure for MobaXterm is pretty standard.

### 1. Navigate to MobaXterm's Site
You'll want to download the Home Edition, so find its link on the download page, or just go [here][download]. You'll see two options: one to install as a system-wide application (labelled "installer"), and one for installing to a flash drive (labelled "portable edition"). Unless you'd really like to install to a flash drive, click the former and run the file once it's downloaded.

### 2. Install
I had trouble running the installer when I first downloaded it; Windows complained that the app was from an unrecognized publisher, so I had to click "More info" and then "Run anyway" to get the installer to run (this was on Windows 8, the process might be different if you run into this issue).

Installing MobaXterm is simple. Just click through all the menus; no special setup is required here.

### 3. Configure Your SSH Session
When you first log in, you'll see a prompt where you can directly SSH as you would on a normal terminal.

{% img /images/mobaxterm-ssh.png SSH Prompt %}

If you type `ssh <andrewid>@unix.andrew.cmu.edu`, it will prompt you for your CMU password and then log you in. The program will also ask if you want to save your password. In the free version, it doesn't allow you to encrypt your stored passwords with a master password, so they're stored in the clear (this means anyone can read these if they got control of your computer). With this in mind, it's not a good idea to allow it to save your password, but I suppose no one's stopping you.

{% img /images/mobaxterm-password.png Save Password Prompt %}

This process of typing out your username and hostname every time you want to SSH can get annoying, though. MobaXterm allows you to save sessions so that you can easily log in without typing `ssh <andrewid>@unix.andrew.cmu.edu` each time.

To create a new session, click the "Session" button in the top left.

{% img /images/mobaxterm-new-session.png New Session %}

Then you'll see a screen that allows you to enter the settings for that session.

{% img /images/mobaxterm-configure-session.png Configure New Session %}

The fields and values you'll need to populate are:

- __Remote host__: `unix.andrew.cmu.edu`
- __Specify username__: check the box, then `<Your-AndrewID>`
- __Port__: 22

You can also choose a bunch of other settings for this session. Feel free to peruse them and see if there's something you want to change (note that these settings will only be used when you use this session to log in). You might want to change the "Session name" to something more concise.

After that, click "OK" and your session will appear in the panel on the left under "Saved sessions".

## Cool MobaXterm Features
This section lists a few features that MobaXterm does better than other SSH options like PuTTY.

First, MobaXterm has tabs and splits, which make managing your connections to a remote server much more enjoyable.

MobaXterm also has more sophisticated color options. Granted, it's still not as good as most Linux or Mac OS X terminal emulators. Out of the box, the colors are more pleasant than the default PuTTY color scheme. There are also 4 other pre-installed colors schemes, including [Solarized Light and Solarized Dark][solarized].

I can't emphasize enough how much of a different having a "pretty" terminal is. Given the amount of time you'll be spending in your terminal, being able to read its text is a must. Also check out the rest of the settings. There will very likely be a few things you'd like to tweak that make the interface make more sense to you, which in turn will make you less frustrated when trying to get work done.

MobaXterm comes with a built in SCP client. This means you can transfer files between your remote server (like Andrew Unix) and your personal computer with the simplicity of a graphical, click and drag interface if you prefer. This is an alternative to WinSCP that's built into MobaXterm.

It also has a built in X server, which means that you can start programs on the remote host that have graphical displays. For example, this is useful if you have an assignment that requires you to write a program that manipulates images and view the results.

## Shameless Plug

While all these features are great, ssh is a program that was meant to be used on Unix-based systems. I personally switched from Windows + Ubuntu to Mac OS X before coming to college, and it was one of the best decisions I made. If Mac OS X is a bit much for you, though, I strongly encourage you to install Linux, using either a VM or a dual-boot configuration. Doing programming and development work in a Linux environment makes nearly every task simpler than trying to do it on Windows.

{% include jake-on-the-web.markdown %}

[download]: http://mobaxterm.mobatek.net/download-home-edition.html
[solarized]: http://ethanschoonover.com/solarized
