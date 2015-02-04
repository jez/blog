---
layout: post
title: "New GitHub Username"
date: 2015-02-03 04:01:04 -0500
comments: true
categories: [meta, git]
description: I've changed my GitHub username! Please update your remote urls.
image:
  feature: /images/abstract-5.jpg
  credit: dargadgetz
  creditlink: http://www.dargadgetz.com/ios-7-abstract-wallpaper-pack-for-iphone-5-and-ipod-touch-retina/
share: true
---

I've changed my GitHub username from Z1MM32M4N to jez (hopefully it'll be a
little easier to type now!). Make sure you update any remote URLs for repos of
mine that you've cloned.

<!-- more -->

## Updating your Git remotes

If you've cloned one of my repositories, you can update it's URL by running

```bash
$ git remote -v
```

to check the current remote URL, which should look something like
`https://github.com/Z1MM32M4N/<repo name>`. Then, you can run

```bash
$ git remote set-url origin https://github.com/jez/<repo name>
```

to actually change the URL.

Because of the way that GitHub handles username changes, you should be able to
continue using the current URLs at least for the time being, but any time you
pull you'll get a message from GitHub asking to update the remote URLs.

I tried to update all links referencing Z1MM32M4N to use the new username, but
I'm sure I've missed a few. If you find a "broken" link, shoot me a message
letting me know!

{% include jake-on-the-web.markdown %}
