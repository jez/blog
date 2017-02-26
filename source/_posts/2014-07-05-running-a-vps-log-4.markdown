---
layout: post
title: "Running a VPS, Log 4: Debugging a Broken Mail Server"
date: 2014-07-07 01:08:00 -0400
comments: false
categories: [summer projects, mail, troubleshooting]
description: Just kidding. My poor mail server hardly works at all.
share: false
---

Whereas the tutorial I'm following to setup this mail server initially promised a working setup in more or less two hours, it's nearing two weeks for me and I've still got plenty of issues. In this log, I'll discuss some of the tools, log files, and online resources which I've found helpful, as well as give a description of my problem as I best understand it.

<!-- more -->

### `telnet`
As I mentioned in my [last log][log-3], I've been using three basic tools to connect to and test my mail server. While a graphical client might have a few tools for debugging a faulty connection--Mail.app's [Connection Doctor][doctor] comes to mind--they don't usually afford full control to the debugger. 

This is where some truly powerful command line tools come into play, the first of which is `telnet`. Telnet opens up a text-based communication channel between you and a server; once connected, you can ask the server anything. SMTP is the broken part of my server, so I'll focus exclusively on examples dealing with connecting on SMTP ports. That being said, these tools are meant to be general purpose and should work for any type of service or port you can think of which exposes a textual interface.

On a working mail server, we should be able to have the following dialog with the server:

```plain telnet
$ telnet mail.zimmerman.io 25
  Trying 107.170.7.111...
  Connected to metagross.zimmerman.io.
  Escape character is '^]'.
  220 ************************************
> EHLO [206.71.229.162]
  250-metagross
  250-PIPELINING
  250-SIZE 10240000
  250-VRFY
  250-ETRN
  250-XXXXXXXA
  250-ENHANCEDSTATUSCODES
  250-8BITMIME
  250-STARTTLS
  250 DSN
> 
```

A few notes: 

- The first two characters of each line follow this legend:
    - `$ ` indicates a line entered at the bash REPL
    - `> ` indicates a line entered and sent to the server
    - all other lines are responses from the server
- `telnet` by default takes two arguments: a domain/IP address, and a port number.
- `EHLO` is an SMTP command asking the server to identify itself and list which subset of commands it will respond to.

From here, we can use commands like `MAIL from: <address>`, `RCPT to: <address>`, and `DATA` to send an email, using only plain text SMTP commands. Pretty powerful. There are also commands to initiate an encrypted connection (using `STARTTLS`), authenticate a user (using `AUTH`), and [more][telnet25].

Earlier I said that one thing we can discern from the server's `EHLO` response is what types of commands it will respond to. I also mentioned that this particular dialog would occur with a _working_ mail server. Sneak peak of a problem I'm having: I can't get `250-STARTTLS` to appear in my server's response. We'll come back to this.

### OpenSSL's &nbsp; `s_client`
The second command line utility that is useful in debugging a mail server, especially those where SSL/TLS encryption is involved, is provided by OpenSSL. OpenSSL exposes a variety of commands, one of which, `s_client`, aids with establishing an encrypted connection between you and a server. 

The syntax of the command looks like this:

```
$ openssl s_client -connect <host>:<port> [options]
```

This client becomes particularly important, because one Postfix option I've specified in the file `/etc/postfix/main.cf` is `smtpd_tls_auth_only = yes`. What this means is that Postfix won't send the line `250-AUTH PLAIN LOGIN` unless we're running on a secure connection. Merely using `telnet` to connect on port 25 will not initiate a secure connection.

There are a couple of ways we can use `s_client` to start off this encryption. The first way is to use port 465 to connect using sSMTP: `$ openssl s_client -connect mail.zimmerman.io:465`. We could also connect to port 25 and then immediately initiate an encrypted connection by issuing the STARTTLS command: `$ openssl s_client mail.zimmerman:25 -starttls smtp`. Either way, we get an encrypted connection to our server, and now the line `250-AUTH PLAIN LOGIN` line will appear in the server's `EHLO` response. We can continue sending SMTP commands just as with `telnet`.

## The Problems Set In
If there's one thing I've learned about mail servers, it's that they're hard. Like, they're really hard.

The problems first set in when I tried to test my setup with Mail.app. For whatever reason, no combination of settings would let me send mail through my server. I opened the logs located at `/var/log/syslog` and `/var/log/mail.log` to see if I could discern what was going on, but nothing showed up. After a bit of Googling, I found some information on how to use the above tools and started to diagnose my problem.

After using them for a little bit, I had the following diagnostic list of things I could and could not do:

- I could connect to port 25 using `telnet` (`telnet mail.zimmerman.io 25`)...
    - ... but neither `STARTTLS` nor `AUTH` appeared in the `EHLO` response, so I couldn't send emails.
- I could not connect to port 465 nor port 587 using neither `telnet` nor `s_client`
    - `telnet` simply aborted telling me that my connection had been refused, whereas `openssl` at least gave me an error number: `connect:errno=61`

{% img /images/smtp-connection-refused-1.png %}

- I could connect to port 25 using `telnet` __from my server__ (`telnet localhost 25` after ssh'ing)
    - This meant that I could send emails, because I had set `permit_mynetworks` as one of the values under `smtpd_recipient_restrictions` (i.e., you don't have to authenticate if you've already ssh'ed in)
- I could connect to port 25 using `s_client` and initiate a STARTTLS command __from my server__
    - This was unnecessary, because the server would already accept my request to send emails to foreign recipients (because `permit_mynetworks` was enabled)
- I could still not connect to ports 465 or 587.
    - I got "connection refused" errors again, but this time the `openssl` error number was 111.

{% img /images/smtp-connection-refused-2.png %}

## Potential Fixes
I have a few ideas on why my server won't let me in. I know for sure that it's not a firewall issue; I have all the requisite ports (25/465/587 and 143/993) open.

```plain ufw Firewall Settings
$ ufw status
Status: active

To                         Action      From
--                         ------      ----
53                         ALLOW       Anywhere
22/tcp                     ALLOW       Anywhere
7                          ALLOW       Anywhere
25/tcp                     ALLOW       Anywhere
143                        ALLOW       Anywhere
465/tcp                    ALLOW       Anywhere
993                        ALLOW       Anywhere
587/tcp                    ALLOW       Anywhere
53                         ALLOW       Anywhere (v6)
22/tcp                     ALLOW       Anywhere (v6)
7                          ALLOW       Anywhere (v6)
25/tcp                     ALLOW       Anywhere (v6)
143                        ALLOW       Anywhere (v6)
465/tcp                    ALLOW       Anywhere (v6)
993                        ALLOW       Anywhere (v6)
587/tcp                    ALLOW       Anywhere (v6)
```

It could be an issue with my certificates. Because I'm cheap and didn't want to pay excessive amounts of money for a fun summer experiment, I decided to self-sign my SSL certificates. (This means that while my traffic will be encrypted, people who try to connect to my server can't necessarily trust that I am who I say I am. It's the same reason why we have notaries to verify our signatures.) I'm skeptical that this could be the reason, though, because nothing was showing up in the logs. If it had been a certificate error, it would have almost certainly shown up in the logs at some point.

Every error message that I got said the same thing: connection refused. But it only said connection refused on ports 465 and 587, ports that are expecting to receive communication over an encrypted channel. This means one of two things: my firewall is blocking the connection, which I've already ruled out, or some other middle-man is kicking me out before we even get to Postfix, where something would show up in the logs.

I have a feeling that this could have something to do with the way my DNS is configured. As it stands, I have an A record on my `@` domain pointing to the IP address for GitHub pages, because [zimmerman.io](http://zimmerman.io) is where I am hosting my personal site. However, I have a CNAME redirect which points `mail.zimmerman.io` to `metagross.zimmerman.io`, which is an A record linking to my droplet's IP address. I also have an MX record set up on the `@` domain, so that all mail directed to "@zimmerman.io" is sent to `mail.zimmerman.io`.

__UPDATE__: After I wrote this post, I switched to the domain jez.io for all of my static site hosting. The links above should continue to work for a while, but at some point they might die.
<br>

{% img /images/mail-dns-1.png %}

<br>
I think that the confusion is in the multiple uses of the `@` domain. Taking a scrutinous look at the differences between my setup and the [tutorial][nsa] I've been working out of, the one glaring difference is that his mail is set up on a subdomain whereas I wanted my mail to be set up on the apex domain. I thought that I made the necessary changes to my setup to get this to work, but now I'm not so sure.

It's also quite possible that I'm completely off the mark with this diagnosis. The world of mail servers is a murky place; certainly one that I don't understand that well after only two weeks. But it has been a very rewarding experience so far, and I'd like to see if I can't fix this issue.

[log-3]: /2014/07/04/running-a-vps-log-3
[doctor]: http://support.apple.com/kb/PH14945
[telnet25]: http://www.port25.com/how-to-check-an-smtp-connection-with-a-manual-telnet-session-2/
[nsa]: http://sealedabstract.com/code/nsa-proof-your-e-mail-in-2-hours/

{% include jake-on-the-web.markdown %}
