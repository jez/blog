---
# vim:tw=90
layout: post
title: "Gripes with RSS after one week"
date: 2022-12-31T00:01:09-05:00
description:
  A quick experience report with using an RSS reader for a week. Overall, I'm happy with
  how things are turning out, but I have a lot of gripes.
math: false
categories: ['rss', 'fragment']
# subtitle:
# author:
# author_url:
---

After reading "[This is the year of the RSS Reader]" last week, I figured I'd try RSS
out.[^rss] Google cancelled Reader before I started college and before I discovered Hacker
News, so I'm not in the "nostalgic for an earlier internet" camp of people, and I never
really used RSS for longer than a few minutes prior to this week.

[^rss]:
  {-} I'm using "RSS" and "Atom" and "feed" interchangeably in this post.

[This is the year of the RSS Reader]: https://www.niemanlab.org/2022/12/this-is-the-year-of-the-rss-reader-really/

<!-- more -->

Overall, I'm happy with how things are turning out, but I have a lot of gripes. You'll
notice as you keep reading that a lot of them boil down to not really liking any of the
RSS readers I've tried so far. If you read to the end and have suggestions for a different
client to try, please let me know.

# On finding feeds

It's been hard to tell between "doesn't have an RSS feed" or "has a feed but doesn't
display it in the page." A page can declare an RSS feed using a `<link>` tag in the
`<head>` something like this:

```{.html}
<link rel="alternate" type="application/atom+xml" href="/atom.xml">
```

But browsers won't surface that to you. Sometimes people have links to their RSS feeds
directly in the page, but quite a few don't, not even on the home page.[^understand]

[^understand]:
  {-} I think this is somewhat understandable. Maybe you're going for a minimal aesthetic
  on the page and don't want to slap a "subscribe" button everywhere, or maybe you just
  don't want to self-promote your blog on every page.

So the only option is to guess and check with your client (and each client has its own
quirks, see below).

It's actually kind of weird how many places have feeds but don't show them. For
example: every Substack has a feed and a `<link>` in the `<head>`, but no mention of it in
the page.[^substack]

[^substack]:
  {-} There's certainly no end to the pop-ups attempting to collect your email address,
  though.

Subreddits have RSS feeds, but don't even mention it as `<link>`: you just have to search
the web for "how to get subreddit as RSS."[^reddit] Funnily enough, the `old.reddit.com`
view **does** have a `<link>` to the RSS feed.

[^reddit]:
  {-} The trick: change `/r/subreddit/` to `/r/subreddit.rss`

And then lots of small bloggers make no mention of RSS in the page, despite publishing RSS
feeds (likely only because their blog software makes one by default, not because they're
all avid RSS users). I don't really fault these people—it's their choice what they want to
mention on their sites or not, and at least a lot of the time there _are_
properly-formatted feeds (so much so that guess-and-check is a viable strategy).

I'm not sure there's a solution here? Short of complaining loudly enough for browser
vendors to add (back?) some sort of button to show when a page has an RSS `<link>` tag, it
seems just like something to suffer through. You might say, "oh you can get an extension
for this!" and well sure, but:

- Every extension that does this will need to be able to access the full page contents of
  every page, which seems a bit excessive. I'd love to not have to trust another browser
  extension for what my browser could do with a simple `querySelectorAll`.

- That would only really work on desktop, probably? I read the most on my phone these
  days, and I'd really love for it to be obvious on my phone when an article has a
  corresponding feed.

# On clients

Apart from my experience with feeds, I have some personal gripes with the clients I tried
out.

I really was hoping to have my feed reader built into the browser.[^app] When browsing the
web, I prefer to never leave my web browser, opening tabs as I queue things up to read.
I'd love if, for example, the iOS Safari "Reading List" would let me save feeds, not just
individual articles. I just want a list of links that open as browser tabs, plus a count
of unread articles.

[^app]:
  {-} Or, short of that, to have it be a mobile-friendly web app with a mobile client for
  badges.

I installed [NetNewsWire] on iOS after ~10 minutes of research and started filling up my
feeds. I couldn't get it to behave like I wanted, so I [filed an issue] and looked for
something else.[^oss] The rest of the client was plain and simple, which I really liked. I
think if it weren't for this one problem I would have had no complaints here.

[^oss]:
  {-} I will say, it was neat that I could file an issue in the first place.

[NetNewsWire]: https://netnewswire.com/
[filed an issue]: https://github.com/Ranchero-Software/NetNewsWire/issues/3791

I tried out Feedly next. Their mobile web version basically didn't work at all—when I went
to click on an article, instead of opening an article, it popped over this list of icons:

![](/assets/img/light/feedly-mobile-web.png){.center style="max-width: 390px;"}

![](/assets/img/dark/feedly-mobile-web.png){.center style="max-width: 390px;"}

"Looks like mobile web is probably not a priority," I said, and then installed the mobile
app. On the one hand, I was able to get the "Open in Browser" functionality to work like I
wanted. But on the other, I disliked almost everything else:

- It felt like I was constantly being pushed to subscribe to more and more feeds. (Lots of
  "you might like" suggestions everywhere, upgrade banners everywhere, etc.)

  This probably makes sense, because Feedly's model requires that you pay once you get to
  100 feeds.

- There were a lot of "social" features, like how many other Feedly users subscribe to
  this feed.

- I kept getting pop ups saying things like"try out our AI-enhanced recommender."

And to top it all off, the app was super sluggish and I didn't love the interface (all the
buttons were tiny). So I went back to NetNewsWire and decided to just suck it up on the
"Open in Browser" issue.

I promptly ran into [three](https://github.com/Ranchero-Software/NetNewsWire/issues/3049)
[more](https://github.com/Ranchero-Software/NetNewsWire/issues/3797)
[issues](https://github.com/Ranchero-Software/NetNewsWire/issues/3662) with NetNewsWire
and felt myself spiraling into the despair of, "maybe I should just bUiLd My OwN."

# On reading content

So far, I've yet to find a good balance of content.

I tried a few "popular" feeds, and they updated way too much—all the content was just
stuff I didn't want to look at.

I fell back on feeds of coworkers or former coworkers, whose posts I know I'd like to read
if they posted. But of course, people are busy and I only saw a few new articles get
posted from these people over the past week.

I'm looking for some goldilocks area between "fire hose of content" and "content desert,"
but I haven't found it yet. Which has meant that I still find myself consuming content the
way I used to (doom scrolling on Hacker News).

I have a feeling that maybe this will die down. I've been more willing to give small
bloggers I discover more of an "innocent until proven guilty" approach—if I see a decent
post, I'll add the feed and remove it if it becomes noisy/uninteresting in the future.
It's probably a marathon not a sprint to finding good feeds.

# RSS on my own blog

I realized that ever since I redesigned my blog to have all sorts of fancy features (like
side notes, code block line highlights, dark mode images, table of contents, etc.), my RSS
feed content has been broken. Sorry about that!

I spent some time trying to make things better, but in the end I gave up. I wrote up some
notes on that [in this post](/rss-excerpt-only/). The **tl;dr** is that I worked myself
into a corner with my Jekyll + `pandoc` rendering pipeline, which makes it kind of tricky
to customize the markup that gets sent into my feed file, making my posts get kind of
garbled by a feed reader.

Even if I could fix markup to not be egregiously bad, I don't want to have to write
assuming the feature set of the least common denominator feed reader—I said earlier that I
really want RSS to be a list of links that become tabs in my browser, and I really like
the typesetting features I currently use to compose my posts.

So I stopped publishing full blog contents to the feed, leaving only the post summary plus
a link to the post online. This means I (selfishly) don't have to spend time thinking
about how my posts format in an RSS feed at the expense of readers not being able to
easily save my posts to read offline.

# Wrapping up

I'm sure a lot of these gripes are just ignorance and lack of familiarity. If you see me
blabbing on about an obviously-solved problem, feel free to let me know.

But on the other hand, I know that I definitely couldn't recommend this to my family
members over the way they currently get their news (mostly Facebook and mobile news apps).
If I'm struggling with it this much, I can't imagine trying to get my parents to take this
dive.
