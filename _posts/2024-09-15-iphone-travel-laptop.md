---
# vim:tw=90 fo-=tc
layout: post
title: "Using my iPhone as a travel laptop"
date: 2024-09-15T12:19:49-04:00
description: >
  A while back I picked up a tiny, folding, wireless keyboard to turn my phone into a passable laptop replacement when traveling. It's already incredible, and only one or two features are missing from iOS which would make it really amazing.
math: false
categories: ['meta']
# subtitle:
# author:
# author_url:
---

A while back I picked up a tiny, folding, wireless keyboard to turn my phone into a passable laptop replacement when traveling (thanks to some excellent apps and the power of SSH). It's already incredible, and only one or two features are missing from iOS which would make it really amazing.

![Hard to use my phone for scale when I need it to take the picture](/assets/img/folding-keyboard-vs-airpods.jpg)

I picked up this [wireless folding keyboard][keyboard] for \$25 on Amazon. It's only slight bigger than my phone itself (iPhone 12) and even fits in my jeans front pocket.

[keyboard]: https://www.amazon.com/dp/B0BZLMG7SN/

![](/assets/img/folding-keyboard-folded.jpg)

For many of my personal trips, bringing a full-sized laptop or even an iPad is overkill, especially if there's only a 10% chance that I'll end up using it. When I do wish I had a laptop, it's usually because suddenly I want to do a little blogging or light programming.[^chance] Now, all I have to do is tuck this keyboard somewhere in a carry-on.

[^chance]:
  For example, the trip calls for nothing but day hiking, but one day we get rained out. Or the trip calls for nothing but skiing, but the first day I get injured.

It's the software that makes this setup workable as a short-term laptop replacement:

- At home, I have a computer running SSH.

  It happens that it's a desktop running Linux, but it could just as easily be a laptop running macOS with Remote Login enabled in the system settings.

- I have [Tailscale] installed on both my phone and the computer at home, filling the role of a VPN.

  This lets my phone SSH to the computer while traveling without having to deal with setting up port forwarding (and thus exposing the computer to the public internet).

- I have [Blink Shell] installed on my phone. Blink has a ton of features, but I basically only use it for the terminal SSH client.

[Tailscale]: https://tailscale.com
[Blink Shell]: https://blink.sh

There's a lot of things I love about this setup:

- I have access to every (headless) program installed on my computer.

  I use Vim for blogging and programming, so I don't need a graphical text editor, **but** Blink [embeds VS Code] for those who don't. Blink's copy of VS Code allows remotely editing files on any host that it can SSH into. I haven't used it extensively, but it works _shockingly_ well from what I've tried.

- Tailscale gives me access to my blog preview.

  Each device on a tailnet gets an IP address, so I can just point iOS Safari at `<computer-tailnet-ip>:4000` and preview my blog while I write.[^mobile-first]

- Blink pairs **perfectly** with AirPlay screen mirroring.

  With the Blink app open in iOS screen mirroring mode, Blink magically uses the connected display as a full-resolution, non-mirrored external display. It turns any random smart TV into a 4K external monitor.

  <!-- TODO(jez) picture of Blink on a TV -->

  Without AirPlay, Blink plus the iPhone in landscape mode is passable: there's plenty of horizontal space, but vertical space comes at a premium.[^retro]

[embeds VS Code]: https://docs.blink.sh/advanced/code#starting-blink-code

[^mobile-first]:
  Side benefit: I'm reading the mobile version of my post while I write, making it less likely that the post looks bad on mobile (due to something like a super long line of code or wordy heading).

[^retro]:
  I can get a 107x21 terminal with my phone on my lap and the text at a comfortable size. Plenty big enough for 80-character code lines plus some space for line numbers, but tedious when four of the rows are taken up with status lines and tab bars from Vim & Tmux.

## How it could be amazing

It's impressive how well it already works—I wrote this whole post with just phone and keyboard while waiting in an airport terminal![^images]

[^images]:
  To get the images in the post, I have Dropbox on both my phone and the home computer, and Image Magick to convert & resize the photos.

But there's a few things holding this setup from being amazing.

- For some reason, `Cmd-Tab` to switch to the most recently used app is one of the few keyboard shortcuts that **doesn't** transfer from macOS. It's crazy, because it works on iPadOS.

  This seems like an oversight? Surely someone at Apple could sneak this into a future iOS update.

  Right now, my workaround is to use `Cmd-Space` to bring up "Siri Suggestions" (aka Spotlight-for-iOS) and type the name of the app I want to switch to.

- The input latency stacks up.

  I haven't isolated where the typing latency comes from, but I imagine it's smeared across lots of things (my top hunches right now are: physical distance to the computer at home, lag in AirPlay screen mirroring, and lag in the Blink terminal emulator).

  I try to minimize how much the lag affects me by using lots of keyboard shortcuts. I've included some of my favorites in the [Appendix](#appendix-fun-keyboard-shortcuts) below.

- iOS Safari doesn't do the "AirPlay screen mirroring is external display" trick. If this worked, it would be absolutely **killer**.

  It makes sense that iOS doesn't magically become full-screen by default—non power-users attempting to screen mirror would not expect it.

  But it would be incredible if an iPhone could drive a web browser at a full 4K resolution. Given how many things are already possible to do with nothing more than a desktop web browser, having one on my phone would be huge.

- Some apps only work in portrait mode.

  Slack and the iOS Settings app are the two that I find myself wanting to use the most while using this travel setup which don't support landscape.

  Slack is a double offender because it also doesn't support _any_ keyboard shortcuts on iOS that the desktop app supports, as far as I can tell.

## Work vs personal

For personal use cases, where I'm basically only blogging or writing code in Vim and compiling at the terminal, this setup is great for light usage.

But I have a dream of one day being able to use this setup for **work trips** too. Think of how cool it would be to travel to an office in another city, sit down at any desk, plug in my phone over USB-C and get to work. This is _almost_ possible.

For me, the things holding it back are all related to where I work (where we can't connect our phones to the corporate VPN) and how important Slack is for work trips (Slack doesn't support iOS landscape mode, let alone the magical Blink external display mode). It's so close to being a reality!

\

I have one of the most powerful computers ever built in my pocket at all times. It would be **so cool** if I use it like one, and we're so close to being there.

\


## Appendix: Fun keyboard shortcuts

Some of the keyboard shortcuts I noticed myself using the most while writing this post:

- Vim
  - `Ctrl-W` and `Ctrl-U` in insert mode to delete the previous word or line.
  - `{`/`}` to move back/forward a paragraph.
  - `[s`/`]s` to jump to the previous/next spelling mistake (lots of typos on this small keyboard with the lag).
  - `z=1` (bound to `<leader>z`) to accept the first suggested spelling correction.
  - `Ctrl-[`, which is the same as `Esc` in terminals.
- iOS
  - `Opt-Backspace` and `Cmd-Backspace`, which delete the previous word or line.
  - `Cmd-Space`, to bring up "Siri Suggestions" (which I only use to launch apps).
  - `Cmd-.`, which usually does whatever `Esc` does on iOS.[^esc]
- Safari
  - `Cmd-L` to focus the address bar in Safari.
  - `Cmd-T`/`Cmd-W` open and close tabs.
  - `Cmd-Opt-Left`/`Cmd-Opt-Right` to go to the previous/next tab.
  - `Cmd-[`/`Cmd-]` to go to back and forward in a tab's history.
- Blink
  - `Cmd-T`/`Cmd-W` open and close tabs.
  - `Cmd-O` to toggle focus between the phone and the external display in screen mirroring.

[^esc]:
  Actually typing `Esc` on this keyboard requires pressing <code>Shift-Fn-\`</code> which I find harder.

  I don't know the origin of `Cmd-.` acting like `Esc` on macOS (and iOS by extension), but it's right there in the [Human Interface Guidelines].

[Human Interface Guidelines]: https://developer.apple.com/design/human-interface-guidelines/keyboards/

In general, I've had great success by blindly trying macOS keyboard shortcuts and having them also work on iOS.

