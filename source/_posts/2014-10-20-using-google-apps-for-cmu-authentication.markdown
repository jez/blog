---
layout: post
title: "Using Google OAuth2 for CMU Authentication"
date: 2014-10-20 06:11:37 -0400
comments: false
categories: [django, webdev]
description: "Using python-social-auth and Django, I've been able to use login.cmu.edu to sign in CMU students by AndrewID."
share: false
---

Using `python-social-auth` and Django, I've found a very straightfoward way of adding authentication to apps designed for CMU students. Given that all Andrew accounts are now Google Apps @ CMU accounts, we can take advantage of the widely used Google OAuth2 libraries to authenticate users, but just restrict sign-ins to the `andrew.cmu.edu` "hosted domain."

<!-- more -->

## Background

Finally! I've alluded many times to blogging about some of the things I'm learning from my experiences rewriting [Print@ScottyLabs][print]. After a summer of putting it off and half a semester more of dawdling, I've finally managed to lay some solid groundwork.

One of the features that we plan on adding to Print 2.0 is a web interface. For people familiar with the way Print works currently, you interact with the service entirely through email. This leads to a clunky user experience and a lot of weird bugs and edge cases. With a web interface, we hope to streamline the process of account management and printing documents.

With this in mind, we needed to decide on a user model. Ideally, we'd like this model to give us two things:

- __It should be secure.__ People who don't already have access to CMU printers shoudn't be able to easy gain access by using our system.
- __It should be familiar.__ We want to design Print 2.0 to be as close to an official-feeling CMU app as we can without stepping on the ever-present administrative toes.

Naturally, this leads to an obvious solution: have people sign in using the same [https://login.cmu.edu][weblogin] site, which is used for email, Blackboard, AutoLab, and many other on-campus services. The trick, then, is to figure out how to do this.

My first thought was to "use Shibboleth." I put this in quotes because I didn't exactly know what that meant at the time. What I was looking for was a simple OAuth2 API (like what Google or Facebook provide) that I could much just drop into my app with no other configuration required on the deployment machine. Shibboleth does not offer this solution.

Luckily, Google's OAuth2 API has a feature that allowed me to do exactly what I wanted. Thanks to a couple of resourceful members of the CMU Computer Science Facebook group (Carlos Diaz-Padron and Arthur Lee), I found out about a barely-documented parameter that you can pass in on the auth URL to restrict Google OAuth2 logins to a [specific hosted domain][hd-param]. Since all CMU Andrew accounts are Google Apps accounts (as of Fall 2013), we can ask Google to restrict logins to the `'andrew.cmu.edu'` hosted domain. From here on, the only trick is to get whatever client library you're using to handle authentication to pass this parameter with a value of `'andrew.cmu.edu'` along to Google. The rest of this post describes a bare-bones way of doing this using Django.

## Implementing Authentication

The following is a pretty long-winded explanation of my personal struggles with this. If you'd really just like to learn by example and by making your own mistakes, check out the [code on GitHub][gappscmu]. I also found the [`python-social-auth` examples][psa-examples] very helpful. In the spirit of [gitorial][gitorial], the commits are structured logically to give you a sense of how the app came together as I wrote it. In fact, I've even [made a gitorial][gapps-gitorial] for this repo!

### Python Social Auth
First up: pick a client library. I've had success using `python-social-auth` in other projects, and it's generally a mature project, so it's what I picked.

Next up: skim the docs. Given the enormous size of this project (it has solutions for tons of python frameworks and tons of authentication backends), the docs are pretty comprehensive. Unfortunately, they fell short in the one place where I needed to look.

One of the neat things about the python social auth library is that it can be easily extended to support additional authentications backends using simple object-oriented techniques. To make this happen, very few pieces of information are hardcoded; in particular, the names of the variables that allow for configuration are dynamically generated based on the available backends.

[This page][extra-args] outlines how to pass in extra, optional arguments while constructing the redirect URI for a particular authentication backend. It hints at the names of the variables that need to be defined, but sadly these hints are wrong.

__This is a correction to the documentation provided at the above link.__ Extra authentication arguments can be passed in using any of the following variables:

- `SOCIAL_AUTH_<backend>_AUTH_EXTRA_ARGUMENTS`
- `SOCIAL_AUTH_AUTH_EXTRA_ARGUMENTS` (no, this is not a typo)
- `AUTH_EXTRA_ARGUMENTS`

I'm not sure what the difference between using the second and third variables are, but all variables of the first form will allow you to scope the extra arguments to a particular backend (in case you're using more than one in the same app).

So in my case, I added the following line to my `settings.py`:

```python settings.py https://github.com/jez/google-apps-cmu-login/blob/master/config/settings.py#L66
SOCIAL_AUTH_GOOGLE_OAUTH2_AUTH_EXTRA_ARGUMENTS = {'hd' : 'andrew.cmu.edu'}
```

Phew. That's a long variable name. But Jake, how did you come up with `GOOGLE_OAUTH2` for the backend name? There's really no good answer to this, because I haven't been able to find a web-readable list of all the names in one place. The way this name is generated is by taking the `name` property of the particular backend you're using (in my case, `social.backends.google.GoogleOAuth2` has `name = 'google-oauth2'`, which I found by looking at the source), replacing all hyphens with underscores and making everything capital.

### The Django App

Now you should plenty of background knowledge to make sense of the Django app on your own, but I'll reiterate the main points here for completeness. It will be pretty choppy in most places if you're not referring to my example app on GitHub as you read.

First, we'll get all our URLs in place. For Django, all the URLs dealing with logging in are already defined; we just have to include them:

```python config/urls.py https://github.com/jez/google-apps-cmu-login/blob/master/config/urls.py#L10
    ...
    url(r'', include('social.apps.django_app.urls', namespace='social')),
    ...
```

Then we can set up some simple URLs (a home page and a logout view), and accompanying views for these URLs that do exactly what you think they should.

In our template, if the user is logged in, we'll show their AndrewID (`user.username`), or else we'll hardcode the link to the Google OAuth2 authentication backend.

__Note__: if you plan on using multiple forms of authentication (like Facebook or GitHub) in this app, be sure to check out the python social auth example for how they generate their home page such that no URLs need to be hard coded. For our purposes, though, if there's only one URL it will be fine to just write it out.

### Demo

<iframe width="420" height="315" src="//www.youtube.com/embed/GYRUvTvTSJE" frameborder="0" allowfullscreen></iframe>

### Going Forward

That's basically it. The rest is up to you to fill in. Building off this model, you should be able to make basically any Django app that you'd otherwise want to build.

One thing you'll want to look into is defining a custom Auth User model. Custom Auth User models allow you to plug into Django's default auth system to take advantage of all the features it has available for keeping track of your users. The [Django docs][auth-user] on this topic are actually pretty good, though you'll likely want to find an example to help you work through the specifics.

As always, let me know if you have any questions or if by following these steps something didn't work for you. Because of how bare bones this app is, it's likely that I glossed over some points for the sake of minimalism. Comment below with your feedback and feel free to email me or make GitHub issues with your questions.


[print]: http://print.scottylabs.org/
[weblogin]: https://login.cmu.edu
[hd-param]: https://developers.google.com/accounts/docs/OAuth2Login#hd-param
[extra-args]: https://python-social-auth.readthedocs.org/en/latest/configuration/settings.html#extra-arguments-on0auth-processes
[gappscmu]: https://github.com/jez/google-apps-cmu-login/
[psa-examples]: https://github.com/omab/python-social-auth/tree/master/examples/
[gitorial]: http://www.gitorial.com/
[gapps-gitorial]: http://www.gitorial.com/#/jez/25536683
[auth-user]: https://docs.djangoproject.com/en/dev/topics/auth/customizing/
