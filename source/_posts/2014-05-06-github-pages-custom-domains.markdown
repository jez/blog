---
layout: post
title: "GitHub Pages Custom Domains"
description: "A walkthrough of how I set up GitHub Pages with my domain name registrar."
date: 2014-05-06 03:15:35 -0400
comments: true
categories: [dns, webdev, troubleshooting]
share: true
---

I stumbled at first getting the DNS configured for my blog, because I've got a slighty more complicated setup than normal. I decided to supplement the documentation [GitHub Pages](https://pages.github.com/) gives by recounting my personal example and the setup that worked.

<!-- more -->

__UPDATE__: Since writing this post, I've switched to the domain jez.io for all of my static site hosting. The circumstances of what I wanted to accomplish and the corresponding instructions are still accurate, but you can no longer visit the links referenced in the post for some context of the setup for what you're reading. As such, all links have been updated to point to the place where the resources now reside.

<hr>

If you've never heard of [GitHub Pages](https://pages.github.com/) for web hosting, you should definitely check it out. You basically get free hosting for any static (i.e. plain HTML or [Jekyll](http://jekyllrb.com/)-served) website with git-push-to-deploy. You can even configure your site to be listed at a custom domain according to [these](https://help.github.com/articles/setting-up-a-custom-domain-with-github-pages) instructions, which are pretty thorough. I feel like it'd help, though, to supplement this documentation with a fairly common example setup.

## My setup
I have two sites which I want to host using the `zimmerman.io` domain name: my [blog](//blog.jez.io) and my [personal site](//zimmerman.io). I host my personal site at [www.zimmerman.io](//zimmerman.io), but you can also navigate to [zimmerman.io](//jez.io) and end up in the same places as before. It's served as a User Page from [this repo](https://www.github.com/jez/jez.github.io).

I host my blog at [blog.zimmerman.io](//blog.jez.io), and it's served as a Project Page in [this repo](https://www.github.com/jez/blog/).

## What the instructions say
The instructions say a few things very clearly (yay, documentation!).

First, if I want to use a custom subdomain (like what I'm doing for my blog) to host a repo, I can add a `CNAME` record with my DNS provider that points to what is in my case `z1mm32m4n.github.io`. This was counterintuitive to me, because I thought at first that this would make my blog.zimmerman.io domain redirect to my personal site, but that's not how GitHub handles it. (They're smarter than that.)

At the same time, I need to put a file in the root of the blog's repo (in the `gh-pages` branch because it's a Project Page), called `CNAME` ([view source](https://github.com/jez/blog/blob/gh-pages/CNAME)) with the contents 'blog.zimmerman.io'. After a little while, the DNS tables will update and everything here should work: I can now view my _blog_ where I want it.

## What the instructions say, but not so clearly
The next bit gave me some trouble at first (probably just because I was being impatient while the DNS tables were updating). The end goal was to have the `www` subdomain host my site and have the `@` (top-level or apex) domain redirect there. If you read carefully, the instructions say to do three things:

  1. Make the `CNAME` file ([view source](https://github.com/jez/jez.github.io/blob/master/CNAME)) in my (User) Pages repository contain `www.zimmerman.io`. __This__ is the domain at which I do want my site to be visible.
  1. Create a `CNAME` record with my DNS provider pointing to `z1mm32m4n.github.io` for the `www` subdomain. From a technical standpoint on the DNS provider's side of things, this is the same thing we did before with the `blog` subdomain.
  1. Create an `A` record pointing the `@` domain towards GitHub using the IP address they specify.

This last step is where you have to have a little faith: nowhere is there an explicit file telling GitHub, "If you get a request from zimmerman.io, send it to me!" GitHub merely notices that there __is__ a repo with a CNAME containing '__www__.zimmerman.io', and so they say, "Well, we may as well send this __top level__ domain to the __www__ domain referenced over here... I've got nothing better to do."

This was a little confusing at first, because if I wanted the opposite direction (www.zimmerman.io to redirect to zimmerman.io), I would have still created a CNAME file, but it would have contained `zimmerman.io` and I would have created an `A` record with my DNS provider, not an actual CNAME. (I still did have to create both the `A` and `CNAME` in the end, but in this setup, the `A` record is referenced in the `CNAME` file, if that makes any sense.)

## Recap
### My CNAME Files
   - For www.zimmerman.io:
       - CNAME file contains `www.zimmerman.io`
       - CNAME file resides in `master` branch of User Pages repo for jez
   - For blog.zimmerman.io
       - CNAME file contains `blog.zimmerman.io`
       - CNAME file resides in `gh-pages` branch of Project Pages repo for jez/blog

### My DNS Config
Here's a screenshot of what my records look like with my DNS provider, in case this was still unclear.


{% img /images/DNS-config.jpg %}

I'm personally using [Gandi](https://www.gandi.net/) for domain registration because they had the cheapest `.io` TLD registration, but their interface takes some getting used to. (It was certainly still worth the deal I got.)

{% include jake-on-the-web.markdown %}
