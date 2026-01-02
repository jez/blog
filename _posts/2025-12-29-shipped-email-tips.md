---
# vim:tw=90 fo-=tc
layout: post
title: "Mechanical tips to improve shipped emails"
date: 2025-12-29T16:53:35-05:00
description: >
  I end up giving the same mechanical feedback on ~every shipped email draft I read. These are some simple tips for making a shipped email useful to busy readers.
math: false
categories: ['writing', 'practices']
# subtitle:
# author:
# author_url:
---

I end up giving the same mechanical feedback on ~every shipped email[^shipped-email] draft I read. These are some simple tips for making a shipped email useful to busy readers.

[^shipped-email]:
  {-} A **shipped email** is a company-internal email sent to announce when some unit of work has wrapped up. To my knowledge, it's [predominantly a Stripe-ism][jmduke], so the ideas in this post may not be relevant to all writers.

[jmduke]: https://buttondown.com/blog/shipped-at

I want to stress **mechanical**. Software engineers spend time getting better at writing code, problem solving, and "software engineering" more generally. Technical writing is a skill just like writing code, but for some reason software engineers tend to view writing well as something intangible. For sure, truly great writing tends to have a _je ne sais quoi_ quality to it, but we can settle for good writing with a short list of mechanical transformations.

Here I focus mostly on shipped emails, but many of these suggestions apply to all forms of technical writing. I should say: I am not an expert nor even a professional writer. I've never been paid to write, never trained with a professional editor. The closest thing I have to a credential is a cardboard star which says "most likely to become a writer" awarded by my high school graduating class. You're welcome to disagree, but I stand by these suggestions.

# Make the subject line a statement

The subject should read as a statement about what is now possible or what was done. Avoid stating only the project's name.

A subject should appeal to the **marginal reader**: someone who wasn't aware that the work was happening, but who benefits from knowing about it. The subject needs to convince the marginal reader to read on.[^unneeded] An unknown project codename in the subject line won't do that.

[^unneeded]:
  {-} The opposite is also true: a subject can assure readers that an email is skippable because they already know its contents or that they're not the intended audience.

I shipped a Sorbet feature recently. Here are two example subject lines:

> [shipped] T::Module

vs

> [shipped] Sorbet supports functions that are generic over Ruby module objects

The first subject names what shipped. The second contextualizes what shipped. A reader need not know what `T::Module` means beforehand: the email is going to lay that out. The second subject is rich with clues for the marginal reader:

- It includes keywords Sorbet and Ruby. Programmers who predominantly work in JavaScript or Go know that they don't have to bother clicking in.
- It frames the ship in terms familiar to the ideal audience: those familiar with generic functions and module objects in Sorbet (or at least, those who want to learn more about them).

# Don't be afraid of bullets for the TL;DR

A TL;DR or BLUF[^bluf] section offers skimmable takeaways at the top of an email. Something can be skimmable yet longer than one sentence. By contrast, single sentences often sacrifice salience for brevity. A TL;DR must have both.

[^bluf]: {-} "too long; didn't read" and "bottom line up front"

Double check whether a single-sentence TL;DR delivers substance. Here's an example:

> **TL;DR**: We shipped some improvements to how Sorbet flags untyped code in editors.

vs

> **TL;DR**:
>
> - Our default VS Code settings will now [highlight untyped code] in non-test files.
> - This setting remains configurable: you can opt to highlight untyped nowhere, everywhere, or only in non-test files (instructions below).

[highlight untyped code]: https://sorbet.org/docs/highlight-untyped

Rewriting with bullet points leaves the summary skimmable while making space for substance. The first example lacks the sort of takeaway that a good TL;DR needs.[^tldr-subject] "Some improvements" weasels out of actually stating those improvements. The second example states the two improvements (a default has been changed, but the default has not been fixed in place).

[^tldr-subject]:
  {-} Oddly enough, this TL;DR could be lightly edited into a decent subject line.

I don't want to imply there _must_ be bullets. Use the length as an indicator: if the TL;DR has one sentence ask whether it lacks substance. Bullets are a quick remedy in those cases.

# Follow the TL;DR with a visual

If at all possible, grab attention after the TL;DR with a visual. Examples:

- **Plots** or **charts** of the metric the initiative was tracking
- A **code block** showing how to use the new API library you built
- Quotes of **testimonials** from early users of the thing you shipped

There's almost always a visual you can add.

Especially for ships where the thing built is a new API, new library, new way of writing code, etc., having a code block between the TL;DR and the rest of the email that shows the new, desirable code first before all other examples anchors the email. The alternative is showing the old, bad code first, saying something about how it's bad, then showing the new, good code. We want to hoist the main point, (e.g., the good code that people should copy) to be the first thing readers see.

# Make headings statements, too

Most shipped emails end up following a template, using the following section headings verbatim:

- TL;DR
- Background
- What we did
- Impact
- What's next

Leaving these templated headings untouched wastes prime real estate. Templates like these are useful reminders of what to include, but readers _already expect_ to find that information. Use the headings to answer the questions they're looking for.

Better headings state what the background is, what we did, what the impact was, etc. For example:

| Templated   | Revised                                   |
| :---------- | :---------------------------------------- |
| Background  | A primer on constant literal references   |
| What we did | Fitting 32 bytes of data in a 16-byte bag |
| Future work | The memory usage is still too high        |

The headings on the left convey more information. A busy reader gains more from headings that state the answers, not the questions. These revised headings signal where individual readers might want to dive into the main content, or at least lend context for readers who skim ahead then read from the top.

# Consider "what we did" ahead of "background"

Many shipped email templates encourage [burying the lede] by listing "Background" before "What we did." That's often backwards. When sitting down to outline an email, sketch things out with the background section towards the bottom.

"Background" before "what we did" lends narrative structure. For example, a short story is going to have the inciting action build up to the climax. But in technical writing, you often **don't want narrative structure**. Technical writing emphasizes efficiency and clarity.

There's a concept in journalism called the [inverted pyramid]: journalists want the most "newsworthy" information at the top of the article, with background and additional information at the end. Inverting the narrative structure so the big surprise is first leads to efficient and clear writing.

[burying the lede]: /dont-bury-the-lede/
[inverted pyramid]: https://en.wikipedia.org/wiki/Inverted_pyramid_(journalism)

I am guilty of this myself _all the time_, but fixing it is surprisingly mechanical. I'll realize that what I actually want to say is the third paragraph, or the second section, or maybe way at the bottom of the email. Then I'll just hoist it up to the top, wholesale. More often than not it already stands on its own, and the paragraphs or sentences that follow lend supporting evidence to the main point. I found myself doing this more than a handful of times while writing this post.

Sure, there are times when the background is truly the most important thing and should be first. For example, retrospectives and incident reviews. I'll leave this one as a "consider" instead of "do," because there are great emails that leave background first.


\

That's mostly it for the structural suggestions. They're mechanical and unambiguous: they apply nearly all the time, so it's easy to get in the habit of checking them as soon as there's a rough draft.

Up next are the harder-to-spot tips about sentences and paragraphs themselves.

\

# Hoist the last sentence first

The same way our email should state the important thing at the top, and then provide supporting evidence, so should our sentences.

> I find I have a habit while drafting to write the thing that I really want to say only once I'm three or four sentences in. I'm sure that's in no small part because I don't know what I'm trying to say when staring down a blank page, but just because it's the last sentence I typed doesn't mean it best fits at the bottom. Having found what to say, hoist it to the top of the paragraph.

vs

> Having found what to say, hoist it to the top of the paragraph. I find I have a habit while drafting to write the thing that I really want to say only once I'm three or four sentences in. I'm sure that's in no small part because I don't know what I'm trying to say when staring down a blank page, but just because it's the last sentence I typed doesn't mean it best fits at the bottom.

It's the same paragraph, but with the last sentence first.

The second version lets readers evaluate all the evidence against the initial claim, one piece at a time. It states the topic of the paragraph first, recasting all subsequent sentences as supporting evidence. The first version doesn't make it clear what point I'm about to make. It begins as a meandering personal anecdote, with a payoff only at the end of the paragraph. That forces readers to guess where it's going, or hold all the claims in mind until the end.

With the way I personally write drafts, I find that my stream of consciousness typing tends to leave the main point somewhere at the bottom of each paragraph. It's a pretty mechanical improvement to hoist it to the top.


# Use fewer leading dependent clauses

There's a time and a place for leading dependent clauses, but overuse makes prose hard to skim. Consider pushing them from the start back to the end of a sentence. Dependent clauses deal in suspense, echoing the narrative structure discussed previously but on a sentence level. A well-placed leading dependent clause can break up monotonous sentences and bring intrigue, but when overused they lead to clunky technical writing.

> For those who don't know, this sentence starts with a dependent clause. Rather than being understandable on its own, it modifies the independent clause that comes after. Having read the first part, and sometimes the second part, readers must push dependent clauses onto a "stack" in their mind. Upon reaching a sentence end, the stack resolves itself, and the reader's head space is free again.

We can invert dependent clauses at the sentence level the same way we can invert our narrative structure at the document level or our sentences at the paragraph level.

> This sentence ends with a dependent clause, which modifies what came before. There's no more complex stack of modifications because each trailing clause modifies the top of the stack in place, rather than pushing temporary context. Skimming becomes easier: our eyes are good at finding sentence breaks, which now host the core idea of each sentence.

Just spotting the leading dependent clauses is mechanical. Sometimes I'll invert the sentence; sometimes the clauses survive scrutiny. Sometimes I might realize the clause itself was fluff and omit it entirely, but it's the mechanical act of checking that tends to make the writing better.


# Strengthen verbs to active alternatives

> Verbs are the most important of all your tools. They push the sentence forward and give it momentum.
>
> — _On Writing Well_, William Zinsser

Some examples from this post:

| Bland | Active |
| :--- | :--- |
| **There is** more information in the headings on the left. | The headings on the left **convey** more information. |
| Leaving these templated headings untouched **is a waste of** prime real estate. | Leaving these templated headings untouched **wastes** prime real estate. |
| By contrast, single sentences **are** short but often not salient. | By contrast, single sentences often **sacrifice** salience for brevity. |

This one is harder to be mechanical about, because there are weak verbs everywhere, and realistically we don't have time to audit all of them before sending an email. That being said, something to watch out for: verbs like _is_, _does_, or _has_ paired with an adjective or adverb often simplify to the verb form of the adjective or adverb.

For more mechanical tips to improve writing, I recommend the whole of Chapter 10, "Bits & Pieces" from _On Writing Well_ (quoted above). The whole book is worth a read, but much of it avoids prescribing a solution, in favor of outlining principles. (In fact I've avoided focusing on the principles because I think it does a much better job of that than I'd ever do.) But if you're just looking for quick tips, "Bits & Pieces" is the place to start.

