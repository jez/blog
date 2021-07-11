---
layout: post
title: "HPSTR: An Octopress Theme"
description: "All about porting the HPSTR Theme for Jekyll to Octopress, adding in cool new features along the way."
date: 2014-06-04 21:51:41 -0400
categories: [webdev, meta]
permalink: /:year/:month/:day/:title/
---

:::{.note .yellow}

| |
| --- |
| ⚠️ This blog no longer uses the HPSTR theme mentioned in this post. |
| Instead, it now uses [pandoc-markdown-jekyll-theme]. |

:::

[pandoc-markdown-jekyll-theme]: https://github.com/jez/pandoc-markdown-jekyll-theme

In case you didn't notice, we're rocking a new theme: [HPSTR for Octopress][hpstr-source]! Ported from the [theme of the same name][hpstr-jekyll] for Jekyll, this theme has a bunch of cool new features that make the theme easier to use and more customizable.

<!-- more -->

Before I begin, I have to give a huge shout out to [mmistakes][mmistakes] for crafting such an impeccable set of stylesheets and Jekyll templates. I could talk this theme up all day, but I think that the results speak for themselves. Even more praiseworthy is that the entire source code is licensed under the GPL, enabling anyone to take the source and build upon it. And on that note, I'd like to unveil what _I've_ built.

# Ported to Octopress
The theme was originally implemented for a vanilla Jekyll blog. Personally, I find the automation tools provided by Octopress to be incredibly helpful, and I didn't want to give these up to be able to deploy this theme. As a result, I had to tweak a few things in order to get it to work with a standard Octopress installation.

# Less to Sass
The HPSTR theme was originally built using Less to compile its stylesheets. Octopress uses Sass under Compass instead--a decision which I love: the rich library of plugins that Compass provides is ridiculous. Thus, this was the first step of the port.

After a quick Google search I stumbled upon [this question][less-to-sass] on Stack Overflow, which surprisingly took care of the vast majority of the conversion, leveraging mere text replacement. From there, it was mostly a matter of slugging through the Less docs to find out what a particular function did, jumping over to the Compass/Sass docs to find a corresponding mixin, and repeating.

# Sass to Compass
I didn't stop after I had the vanilla Sass working. One of Compass's coolest features is that you don't have to repeat yourself: there are mixins for seemingly everything, and when there aren't, there are 3<sup>rd</sup> party plugins. Thus, the next phase of the port was to see how much of the code I could reduce to compass mixins.

For the most part, this stage affected CSS3 properties which need vendor prefixes, to include keyframe animations. The keyframe animations are particularly worthy of a mention because I found a handy plugin called [compass-animation][compass-animation] to take care of them. It works as easily as any other Compass mixin, from installation to use.

# Octopress Mannerisms
There are a few things that Octopress users can expect to be reasonably similar from one deployment to the next, and I wanted to ensure that as many of the features dually implemented by mmistakes and Octopress used the syntax or conformed to the style set forth by Octopress. A small example of this: the `page.link` and `page.external_url` properties. Defined by the old and new themes respectively, both accomplish a similar purpose. Each specifies that the main purpose of the post is to link to a different page. Not wanting to break the service for current Octopress users, I tried to convert as many of these subtleties.

On top of this, I restructured a lot of the original code so that someone used to customizing an Octopress theme would feel more at home when checking out the source for this theme, even if some of the particulars were different. This applied mostly to the Sass directory structure, but also to the templates.

# More Powerful Customization
One of the many ways Octopress adds value on top of Jekyll is the ease with which you can get a Jekyll blog up and running, and subsequently customize and tweak that theme. This was one area where I felt that the original Jekyll theme fell short. The original stylesheets had a somewhat decent set of variables (in `less/variables.less`) that would allow you to customize the colors and font faces, but the method for customizing the size of the font was wonky (larger values produced smaller fonts), and the various mixins employed to handle setting the sizes were confusing.

To solve this, I added _loads_ of new variables handling the font sizes and line heights on a per-component basis, while also providing a master switch to easily resize everything. My theme also differs here from the original in that it's default font size is slightly larger for normal paragraph text (the whole reason why I cared about customizing the font size in the first place!).

# Like what you see?
This theme is in no way perfect, from the styles to the compatibility with the vast array of Octopress options. If my support for your favorite feature is lacking or absent altogether, patch it up and submit a pull request on [GitHub][hpstr-source]!

__I'd also love to hear about your installation process.__ If something didn't quite work out right when installing the theme from GitHub or everything went super smoothly, tell me on GitHub in an issue, on [Twitter][twitter], in the comments below, or in an [email][email]. Seriously!

[hpstr-source]: https://github.com/jez/hpstr-theme
[hpstr-jekyll]: https://github.com/mmistakes/hpstr-jekyll-theme
[mmistakes]: https://github.com/mmistakes/
[less-to-sass]: https://stackoverflow.com/questions/14970224/anyone-know-of-a-good-way-to-convert-from-less-to-sass
[compass-animation]: https://github.com/ericam/compass-animation
[twitter]: https://www.twitter.com/Z1MM32M4N
[email]: mailto:jake@zimmerman.io

