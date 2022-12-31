---
# vim:tw=90
layout: post
title: "Moving to excerpt-only for feeds"
date: 2022-12-30T16:50:17-05:00
description:
  I've been struggling to get the RSS version of my posts to look good in the presence of
  all the features my blog supports (side notes, line highlights on code blocks, light-
  and dark-mode images, etc.). With that in mind, I'm switching to share only a link and a
  post summary in the feed, omitting the full content.
math: false
categories: ['meta', 'rss']
# subtitle:
# author:
# author_url:
---

I've been struggling to get the RSS version of my posts to look good in the presence of
all the features my blog supports (side notes, line highlights on code blocks, light-
and dark-mode images, etc.). With that in mind, I'm switching to share only a link and a
post summary in the feed, omitting the full content.

<!-- more -->

There were too many problems with the way posts rendered, and I didn't have the patience
to continue working around the problems. The way side notes render in a feed is
particularly annoying:

![Highlighted: what would normally appear as a sidenote](/assets/img/light/rss-side-note.jpg){.center style="max-width: 390px;"}

![Highlighted: what would normally appear as a sidenote](/assets/img/dark/rss-side-note.jpg){.center style="max-width: 390px;"}

I've taken this example from [this post](/sorbet-rescue-control-flow/). In that post, the
side note appears in-line with a superscript number, and the paragraph continues after the
side note anchor. But because of the HTML markup I'm using [to achieve that], elements
that ought to be hidden are not (in particular, the `<input>` element).

[to achieve that]: https://jez.io/pandoc-markdown-css-theme/features/#side-notes-and-margin-notes

A similar problem happens with light- and dark-mode images:

![A feed reader showing both light and dark images](/assets/img/light/rss-double-image.jpg){.center style="max-width: 390px;"}

![A feed reader showing both light and dark images](/assets/img/dark/rss-double-image.jpg){.center style="max-width: 390px;"}

Feed readers don't use the CSS (admittedly, by design) to know that one of the two
versions of the images [will have `display: none`][dark-mode-images], so it shows both.
Because the dark-mode image uses white lines instead of black lines, a lot of the lines in
the drawing aren't even visible, making it hard to tell that the diagram is identical to
the previous one (modulo colors).

[dark-mode-images]: /hand-drawn-diagrams/

Another gripe was that code blocks on my site support highlighting individual lines, [like
this][cb-hl]. Those get dropped by feed readers, stripping the context from any
explanation that says "look at the highlighted lines."

And another gripe was that the way I render the table of contents was making it look like
the navigation elements on the page were part of the post content. Every post's preview in
a feed reader always looked the same, starting with text like "← Return home" or "Home
Contents...", instead of the actual intro of the post.

[cb-hl]: https://blog.jez.io/syntactic-control-flow/#cb2-25

After spending some time, it ended up being more effort than I wanted to spend to render a
post differently for the blog view or the feed view. I could have left it quirks and all,
but I'd rather encourage people to read the posts on the web where they'll be typeset as
intended (especially considering that my blog theme is quite responsive at all screen
sizes). Sorry for any inconveniences!
