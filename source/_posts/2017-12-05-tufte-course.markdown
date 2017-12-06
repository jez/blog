---
layout: post
title: "Presenting Data & Information: Notes"
date: 2017-12-05 23:37:08 -0800
comments: false
share: false
categories: ['data', 'notes']
description: >
  On Monday, December 4th, I went to Edward Tufte's one-day course on
  "Presenting Data & Information." I'm glad I went, and there were a
  number of things I took away from the day.
strong_keywords: false
---

On Monday, December 4th, I went to Edward Tufte's one-day course on
"Presenting Data & Information." I'm glad I went, and there were a
number of things I took away from the day.

<!-- more -->

### Key takeaways

1. Text, numbers, and visuals should be **woven tightly together**.
1. From a small set of principles, we can have a **rigorous, analytical
   framework** for evaluating information designs.
1. Information benefits from being shown in **space and time**.
1. Effective presentations lead to the **outsized impact** of your work.
1. **High-density** visualizations trump those of low-density.
1. Tufte-the-personality is over-hyped.
1. Learning is a lifelong process.

### Selected readings

A lot of the books are broken up into modular components, almost like
individual essays. This means they're easy to pick up and read a little
bit of. I'm happy to lend you my copies!

- "Words, Numbers, Images---Together"
    - *Beautiful Evidence*
- "The Fundamental Principles of Analytical Design"
    - *Beautiful Evidence*
- "Narratives of Space & Time"
    - *Envisioning Information*
- "High Resolution Data Graphics"
    - *The Visual Display of Quantitative Information*
- *Tips for Giving Clear Talks* (by Kayvon Fatahalian)
    - [Slides](https://www.cs.cmu.edu/~kayvonf/misc/cleartalktips.pdf)


## Integrating Visuals with Text

> "Words, Numbers, Images---Together"
>
> --- *Beautiful Evidence*

Fun fact: the word "text" comes from the Latin word for "woven."
Originally this reflected the visual appearance of the written words:
letters and words overlapped and flowed like threads in a cloth.

Tufte made the case that we need to weave more than just text; text,
but also numbers, data graphics, visuals, etc. It's especially bad when
there's a "special place" for graphics or numbers, because you lose out
on the opportunities to connect ideas and expose relationships.

This segregation of data is a recent change. When the pen was the same
tool to produce text as to produce drawings, text and images abounded!
This is especially apparent in some of da Vinci's notes, for example,
about human anatomy. Even consider the difference between content
produced on a whiteboard (marker) vs in Dropbox Paper (keyboard).
Graphics will flow when you're white-boarding with someone, not when
you're collaborating on Paper.

Finally, I think sparklines are really cool. A full-fledged
visualization can be thought to represent the granularity of an essay.
A single chart or element of the visualization parallel paragraphs of
text. Sparklines continue the progression down to the word level. He
showed some really cool examples of what happens when you can
weave visualizations with your text at the level of single words.

## Analytical Design Thinking

> "The Fundamental Principles of Analytical Design"
>
> --- *Beautiful Evidence*

The key point here was that with a few principles, we can be more
rigorous in evaluating our designs. The beauty is it parallels similar
principles from the scientific method, which is a time-tested tool for
discovering knowledge.

### The principles themselves

Show comparisons, contrasts, differences.

Show causality, mechanism, explanation.

Show multivariate data, that is, show more than 1 or 2 variables.
*Corollary*: All interesting data is multivariate (requires a JOIN of
sorts on disparate data sources).

Completely integrate words, numbers, images, diagrams, etc.

Thoroughly provide your evidence (title, sources, shortcomings, etc.)
*Corollary*: if you're afraid to show your data, you're might be lying

Quality, relevance, and integrity of content counts most of all.

### Some interesting implications

- The credibility of an "executive summary" depends intimately on the
  quality, relevance, and integrity of the evidence.
- Analytical processes for design rely heavily on mutual respect,
  because criticism is inherent to the process.
- It's easy to default to uni- or bi-variate data (these are what our
  tools are good at). By overcoming the comfort of what our tools do
  well, we can draw stronger conclusions.


## Information in Space & Time

> "Narratives of Space & Time"
>
> --- *Envisioning Information*

We often neglect to visualize information in space, instead choosing to
only visualize it in time.

Consider a slide deck: the information is segmented in to discrete
frames which are then played back over the time of the talk. On the
other hand, a poster or handout might have the same content laid out on
one page, so it's all in the field of view at once.

This echoed a similar idea to one Adam brought up in the Frontend
Learning Group: Sketch effectively converted designing UIs from
something being seen over time (by showing/hiding various Photoshop
layers) to being seen over space (artboards or screens).

Often a stronger case can be made by presenting information in both time
and in space. A general problem with information presented over time is
that it happens too fast. This isn't to say presenting information in
time is terrible: it's just shouldn't be the only way.


## Talking & Presenting

> *Tips for Giving Clear Talks*
>
> --- Kayvon Fatahalian

Tufte spent a surprising amount of time talking about effectively
presenting. I thought many of his ideas about effective presentations
were out of touch with reality.

Instead, I prefer these resources on giving clear presentations by
Kayvon Fatahalian:

- 📈 [Slides](https://www.cs.cmu.edu/~kayvonf/misc/cleartalktips.pdf)
- 📺 [Video](https://www.dropbox.com/s/96t357h8uhf52l6/clear-talk-tips.mp4?dl=0)

The key points are:

- An effective talk leads to a *non-linear* increase in the value of
  your work.
- The audience prefers not to think (much).
    - They don't want to think about what you left out or what you're
      hinting at.
    - They'd much rather think about how they can put your work to use.
- Every sentence matters.
    - If it doesn't provide value, strike it out.
- Surprises are bad.
    - Say where you're going and why before you go there.
- Titles matter.
    - Reading nothing but the titles of a slide deck should be a great
      summary of the talk.
    - Sometimes this means titles are short sentences!
- End on a positive note!
    - People remember the beginnings and ends.
    - You want them to walk out with a rising rather than sinking
      feeling.

That being said, Tufte did have a few good tips for presentations.
For example: give handouts with your talks. Handouts overcome the
low information density of slides. This tip is just a restatement of
"present information in space *and* time." The handouts might be:

- full-on lecture notes
- a simple overview/summary
- a list of key takeaways
- links to further reading
- a graphic you want to refer back to often


## High-density vs Low-density Visualizations

> "High Resolution Data Graphics"
>
> --- *The Visual Display of Quantitative Information*

Tufte discussed a very clear preference for high-density visualizations
over low-density. High-density visualizations should present
multivariate data cohesively, weaving text, numbers, and visuals.

In a high-density visualization, the arrangement and composition is key.
If you get it wrong, you end up with information overload. But the goal
is to get it right, and in doing so, you draw richer comparisons and
conclusions that are otherwise possible.

This was why Tufte had a clear preference for physical paper over
digital media: the resolution of a piece of paper (or better: two
side-by-side) is *significantly* higher than most displays are these
days. In his books, every two-page spread shows a high-density
visualization, which is what makes them so powerful.

The flip side: he detested interfaces that presented shallow views into
the data or sacrificed analytical design for aesthetic design. It's
common on the web to be scared of information overload, and instead show
less. We should present more, but *thoughtfully* and with clear
relationships between all the elements.

As a closing rebut, he made the claim that we should "design forward,
anticipating higher-resolution devices." I found this hard to reconcile
with the long tail of users that have *terrible* resolution devices
currently, with no hope of improving rapidly.


## Meta

I was a little disappointed to meet with Tufte-the-personality as
opposed to Tufte-the-writer.

As a presenter, there seemed to be a stronger focus on bravado and
showmanship than on learning and growth. Until this event, I hadn't been
aware of the somewhat cult-ish following Tufte has, and it seemed like
he was profiting off of that image. Some back-of-the-envelope math
suggests that he can easily bring in a six-figure salary from the dozen
one-day courses he runs in a year alone.

His multiple books which revisit the same core set of ideas with slight
variations suggest that he's producing content to make a living as
opposed to trying to distill ideas into a small, cohesive set of truths.
In particular, I think of my favorite programming languages textbook,
where every chapter is both complementary yet orthogonal to the others.
The book distills and reduces ideas down to their core essence. Tufte's
books dance around, giving the effect of after-images of some underlying
truth which is withheld.

Tufte's speaking style favored shaming and derision to inclusion and
passion. In the audience, there was a certain amount of, "it's okay, as
long as I laugh along with everyone else I'll belong." This line of
thinking leads to toxic behavior where people think they need to put
down others to grow.

Tufte repeatedly made arguments of the form:

- Google and the NYTimes do it.
- These two are wildly successful.
- Therefore, it's the correct thing to do.

This reasoning ignores confounding variables like survivorship
bias. It's also possible to succeed *in spite of* flawed design. While
we can draw inspiration from what others do, it's important to verify
them from first principles, rather than blindly follow.

That being said, he mentioned something to the effect of "even
lobbyists can be right." Even in spite of the commercialism of it all,
we can still learn from what he has to say. I presented the four earlier
sections before this section because I did take away many valuable
ideas from the day.


## Open Questions

How can we scale paper handouts to the digital age?

- What we want:
    - share with others
    - collaborate/discuss after
    - high-density information
    - evergreen vs moment in time
- Is something like Dropbox Paper good enough to replace physical
  paper for meeting handouts?

What is it about screens that's better than physical paper?

- paper has higher resolution + information density
- two, three, four pages of paper at once are the same as 2 x 27" monitors
- yet, why do we use screens if the information density is so low?


## Personal

I had a couple personal realizations while I was there.

At the first hackathon I ever went to during my freshman year of
college, the thing we built was a tool to try and visualize geographic
data on a 3D, interactive globe. I was so proud of this thing we built.
It was the first time I ever wrote JavaScript (I had literally never
touched it before). After 36 hours, we had a live, running thing that
people could *actually interact with!*

During the final expo and initial judging phase, one of the judges (not
the one assigned to judge us) came by and asked a simple question: "oh,
have you read anything by Edward Tufte about visualizations?" I answered
no, and he quickly rattled off a few obvious in hindsight changes we
could make to improve our project.

I was so ashamed at the time. "Who am I to try and make a data
visualization, knowing nothing about data visualization?" I truly felt
like an imposter.

This happened 4 years ago: October 2013, my freshman year of college.
Fast-forward 4 years, and not only have I browsed through his books,
I've just heard what Tufte has to say face-to-face. The learning process
is spread out over the course of a *lifetime*. Not in an afternoon of
hackathon judging. Not for the duration of a one-day course.

Reflecting on the "childlike" pride and enthusiasm I had having built
something, from knowing nothing, there's little quite as thrilling. By
that same token, we should have the same attitude when people give us
tips and suggestions for what to learn next---these tips are decidedly
*not* evidence that we should feel ashamed for knowing too little.





<!-- vim:tw=72
-->
