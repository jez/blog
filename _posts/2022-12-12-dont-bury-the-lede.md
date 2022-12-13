---
# vim:tw=90
layout: post
title: "Don’t bury the lede in technical docs"
date: 2022-11-29T21:21:10-05:00
description: >-
  Figure out the main point, and then just say it (before anything else). This makes a
  piece of writing stronger.
math: false
categories: ['writing']
# subtitle:
# author:
# author_url:
---

I've noticed that programmers really like to bury the lede. An easy way to make technical
writing stronger is to **figure out the main point, and then just say it** (before
anything else). All the supporting information can come after. Why does this strengthen
the piece?

**Readers will find it easier to read.** Readers won't have to store all your supporting
evidence in a mental queue while waiting for a point to be made. Instead, they'll read the
main point, then check supporting evidence against that claim piece by piece (only holding
one piece of evidence in mind at a time).

**The piece will sound more authoritative.** This falls somewhat naturally out of the new
structure—it's a lot harder to use weasel words to water down your main claims when they
come first.

**Skimming the piece will be more effective.** Skimming becomes ineffective if the topic
sentence is buried somewhere in a paragraph, because skimmers will skip it.

A suggestion: go so far as to write the claims into section headers. Sometimes, this is
just a technique I use while drafting, and I'll change the section headers before
publishing. But sometimes I'll actually keep those headings in the finished product. It's
nice because headings have to be short: short headings imply short, focused claims, which
are strong claims. This doc isn't long enough for section headers, but I still did this
for the title itself.[^1]

[^1]:
  I learned this technique from one of my college professor's "[Tips for Giving Clear
  Talks](https://graphics.stanford.edu/~kayvonf/misc/cleartalktips.pdf)" presentation.
  It's worth a read, as a lot of the tips work for long-form writing as well as
  presentations. (I have a local recording of the talk I can share if you'd like more than
  just the slides.)

Another suggestion: before publishing, try bolding the topic sentence in each paragraph.
First, it'll expose whether a paragraph's main point is buried at the bottom. But also,
it'll expose whether your topic sentence is a succinct: if a paragraph's main point isn't
succinct, there will be bold all over the place and maybe even bold in multiple places.
Like with the previous tip, sometimes I'll keep and sometimes I'll drop these bolded
claims before publishing (as you can see above).

Burying the lede manifests most frequently by programmers putting the "Why" before the
"What." I have various theories why this is, but I think it's mostly because programmers
feel like logical proofs need to flow from assumptions to conclusions—that by introducing
the claim first and supporting it second, they're not being rigorous. Another theory:
people think that they need to make their writing more entertaining by making it
"suspenseful." Suspense rarely improves technical writing, where the focus is on conveying
facts quickly.

Here's two common examples of putting why before what, and how inverting things makes the
writing stronger:

-   A "look at what I did" email that puts the "background" section ahead of the "impact"
    section.

    Unless you're really good at narration (funny, clever, etc.), the background is going
    to be more boring than the impact you're announcing. Leading with impact is the
    easiest tool you have in an email to wow the reader and capture their attention. Once
    captivated, they'll continue with your background for more details, or decide that
    they don't need to.

-   A help doc structured like "Here's something incorrect that you could do you do.
    Here's why it's a problem. You need to do this instead."

    Writing the claim first anchors all further examples on what to pay attention to.
    Here's an [example in the Sorbet docs] about using `T.attached_class` in an argument.
    Note how the first sentence is "you can't do this, because of soundness problems." The
    alternative would be to dive into the bad example immediately, leaving readers
    wondering what the final point will eventually be.

[example in the Sorbet docs]: https://sorbet.org/docs/attached-class#tattached_class-as-an-argument

Don't bury the lede. Instead, start by saying what you want to say, and then follow up by
supporting it. Your piece will sound stronger and be more effective, and your readers will
thank you.
