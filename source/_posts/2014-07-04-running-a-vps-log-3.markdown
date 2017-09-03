---
layout: post
title: "Running a VPS, Log 3: A Mail Server that Works... Kind of."
date: 2014-07-04 14:11:14 -0400
comments: false
categories: [summer projects, digitalocean, mail]
description: So my mail works now. Kinda.
share: false
---

After some initial troubles, I finally managed to get basic send and receive functionality  working on my mail server, using EncFS, Dovecot, and Postfix. That being said, it's _far_ from a perfect system, and it needs a good deal more TLC to get it working at a level that's on par with a more "professional" email service provider. This post details some fixes that I've implemented so far, as well as the functionality that I've managed to get working.

<!-- more -->

## EncFS Troubles Revisited

I mentioned in my [last log][log-2] that I had somehow managed to botch my first mail server-related endeavor: installing EncFS, a program for creating encrypted file systems. The way it's supposed to work is depicted below:

{% img /images/encfs.svg %}

Emails originating elsewhere are transfered over the internet to my server according to the DNS settings we've put in place. These emails need to be stored somewhere upon their receipt; ideally, somewhere encrypted. Thus, the goal is to set up an encrypted file system in user space, such that each incoming email is first stored in `/decrypted-mail/`, and then is automatically encrypted and stored in `/encrypted-mail/`. (__Note__: this is not quite how the encryption process works. For more information, you should check out the [Arch Wiki][encfs] page on EncFS.)

There are some disadvantages to this type of encryption, most notably that it leaks information about the file system itself. However, as was mentioned in the comments on the [tutorial I'm working from][nsa], "if the host/harddisk is given to authorities they cannot decrypt it and thus cannot access your e-mails," which is good enough for me.

### Upgrading the Kernel

After following the instructions from the tutorial perfectly, _and_ repeating them after having restored from a clean backup, EncFS refused to work. Luckily, I found this [GitHub issue][issue] detailing the source of the problem as well as a simple fix for it.

Apparently, my issue was that DigitalOcean doesn't initialize freshly created Debian 7 droplets with the most recent kernel. Unfortunately libfuse, a library used by EncFS to create and manage the encrypted file system, was expecting a more up-to-date kernel version.

Upgrading my kernel version was just a few steps, though. I had to run

```bash
$ sudo apt-get update
$ sudp apt-get upgrade
```

to update the list of downloaded kernels, then

```bash
$ sudo shutdown -h now
```
to tell the server to shutdown and power off. Next up is to switch over the kernel version on the [DigitalOcean control panel][solution]. All in all, nothing too difficult: the hardest part was that I never expected my problem to have anything to do with DigitalOcean.

## Postfix & Dovecot

With EncFS finally up and running, I moved on to getting the basic send and receive functionality implemented. For the most part, this process was straight-forward, and is outlined (albeit very scarcely) [here][nsa].

Then suddenly, the tutorial proclaimed, "At this point, it should basically work. You should be able to send and receive mail." I was pretty surprised: I had no idea how to actually go about testing my setup! It simply did not list any way of doing this. It turns out, there are basically three ways to establish a connection with the mail server; I'll discuss the first here, and the others in a [future post][/2014/06/24/running-a-vps-log-4] on troubleshooting problems with my setup.

### Mail Client

For the true hackers who don't make mistakes and set up their systems perfectly on their first try, simply launching a desktop or mobile mail client and configuring a few account settings, should be enough. Since I'm developing on a Mac and was too lazy to install a fancier, potentially more feature-rich client, I'm using Mail.app.

A series of dialogs should drive the process of setting up a new user account. My Mail.app setup is shown below.

{% img /images/imap-settings.png %}

IMAP on my setup works fine, so I'll give some pointers about setting it up correctly:

- __Email Address__ or __Username__: Fields that ask for this information should always include a full email address--in my case `jake@zimmerman.io`. This is because our MySQL server is configured to store the full address, so Dovecot needs a full address to use to for IMAP authentication.
- __Password__: This is the password coupled with the email address referenced above, which was SHA512-hashed and stored in the database.
- __Incoming__ or __IMAP Mail Server__: Whatever is in this field needs to eventually resolve to the IP address of our IMAP server. Simply putting the server's IP address directly into this field will suffice. To be more sophisticated though, we'll want to configure this field with a domain name and let our client resolve it, as this is more robust. There are a few ways this can be done; to give a quick overview, you can either set up
    - a CNAME record which resolves to the mail server's IP.
    - an MX record on the `@` or apex domain which resolves to the mail server's IP. (This is the option depicted in the screenshot above).
    - an A record which resolves directly to the mail server's IP.
- __Port__: 993. We've configured our server to use SSL to connect over IMAPS, which runs by default over port 993. Be sure to check "Use SSL" if such an option is available.

As far as SMTP goes, this is where my setup starts breaking. I'll come back to why exactly it's failing in more detail [here][debugging], but for now, know that I had to change the line `smtpd_tls_auth_only = yes` in `/etc/postfix/main.cf` to `... = no`, to even get things to work. With this line enabled, credentials are sent over the wire in plain text. Sadly, crypto is hard, and this is the only thing that I have done to manage to get it working.

At this point I could connect to the server "zimmerman.io" on port 25 using my email with the _same_ password from above. As a side note, this form of authentication is pretty nifty. If you noticed, we're using the same password on IMAP with Dovecot and on SMTP with Postfix. Using the SASL protocol, Postfix can pass on the user's credentials to Dovecot, which then uses its connection to the database to confirm or deny the request for authentication. For a simple, one-user setup, this is a rather elegant solution.

## Debugging a Broken Mail Server

With SSL authentication turned off, I was able to get Mail.app to send and receive emails. Additionally, I could do the same using the third-party Android client myMail. For whatever reason, the default Android client wouldn't even accept my IMAP login, whereas myMail was smart enough to log me after only asking for my email and password.

Ideally, I'd like to have a setup where my password isn't being sent in a format anyone can read. To debug some of these close-to-the-system settings, there are a bunch of [command line tools][debugging] which help to inspect exactly what's going wrong with the system.

[log-2]: /2014/06/24/running-a-vps-log-2
[encfs]: https://wiki.archlinux.org/index.php/EncFS
[nsa]: http://sealedabstract.com/code/nsa-proof-your-e-mail-in-2-hours/
[issue]: https://github.com/al3x/sovereign/issues/147#issuecomment-43849647
[solution]: https://www.digitalocean.com/community/tutorials/how-to-update-a-digitalocean-server-s-kernel-using-the-control-panel
[sasl]: http://en.wikipedia.org/wiki/Simple_Authentication_and_Security_Layer
[debugging]: /2014/07/05/running-a-vps-log-4


