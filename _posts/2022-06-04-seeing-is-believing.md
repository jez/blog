---
# vim:tw=90
layout: post
title: "With types, seeing is believing"
date: 2022-06-04T23:31:51-04:00
description: >
  You don't first convince everyone that types are good, and then start adopting types.
  Instead, you adopt types first and then let people see for themselves what types do for
  them.
math: false
categories: ['sorbet', 'devprod']
subtitle: "Alternatively: How to adopt Sorbet at your company"
# author:
# author_url:
---

From time to time I get asked something like this:

> I write a lot of Ruby at work. In past projects I've really enjoyed and benefited from
> a statically typed language. But on my current team, people aren't as excited.
>
> What can I say to them to get them to change their mind, so we can start using types in
> Ruby?

In my experience, this framing is backwards. You don't first convince everyone that types
are good, and then start adopting types. Instead, you put them to sleep, enter their
dream, and plant the idea that types are good—ah, wait, wrong storyline. Instead, you adopt
types first and then let people see for themselves what types do for them. The people
opposed to types won't be convinced to start liking them by anything you can tell them or
ask them to read.

<!-- more -->

In all of the cases where I've seen Sorbet be adopted, the process looked like
this:

1. An ambitious team (or even individual) who really, really wants types in Ruby does the
   work to get an initial pass at adoption passing in CI.[^grind] Importantly, the initial
   pass does a minimal amount of work, so that it doesn't take long to get here.

   For [Sorbet], that means only checking at [`# typed: false`], which enables Sorbet in
   every file but only does the most basic checks, like checking for syntax errors and
   typos in constant literals.

1. That initial version sits silently in the codebase over a period of days or weeks. When
   new changes introduce new type errors, it pings the enthusiastic types adoption team;
   they figure out whether it caught a real bug or whether the tooling could be improved
   (for example, for syncing type definitions for third-party code). It does **not** ping
   the unsuspecting user yet.

   When we did this to roll out Sorbet at Stripe, this manifested as a job that ran on the
   `master` branch[^master] in CI, but if it failed it would send a Slack message to us,
   not tell the user that their change was broken.

1. This process repeats until the pings are only **high-signal** pings. When there's an
   error, it represents actual bugs (or maybe doesn't ping: remember, most files are still
   `# typed: false`).

1. Double check at this point that it's easy to configure whatever editors your team uses
   to put the errors directly in the editor. You likely already did this for yourself
   while working on the initial migration.

   Sorbet exposes an [LSP server] via the `--lsp` command line flag to allow integrating
   with arbitrary editors, and also publishes a [VS Code extension] for people who want a
   one-click, low-config solution.

1. The time has come to enforce that the codebase type checks in CI. You and your team
   effectively beta-tested it on behalf of the organization and decided it wasn't going to
   bring development to a halt. Flip the switch, and if need be, remind people that this
   is still an experiment. "We can try it out for a while and re-evaluate later—it's still
   the same language."

   Most code still has no explicit type annotations and limited type checking (due to the
   `# typed: false`), but now more teams can experiment with enabling stricter type
   checking in the sections of the codebase they own.[^gradual]

1. Finally, the important part: **show** people how good Sorbet is, don't tell them. Fire
   up Sorbet on your codebase, delete something, and watch as the error list populates
   instantly. Jump to definition on a constant. Try autocompleting something.

   Notice how we're **not** showing off the type system and how expressive it might
   be. We're showing off what the type system actually lets them do! Be more productive at
   their job.

[^grind]:
  This can be somewhat of a grind, and is all too often done during nights and weekends,
  though high-trust teams do a good job of carving out time for experiments like this.

[^master]:
  Limiting to `master`, instead of all branches, is a convenient way to get a sense for
  whether enforcing types would have actually blocked someone. It's far more likely that
  in-progress branches with type failures also have failing tests, and that the type
  failure would have done a _better_ job at alerting the user to the problem.

[^gradual]:
  This is the whole point of "gradual" in [gradual type checking].

In my experience trying to bring static types to Ruby users, seeing is really believing.
I've seen this exact same story or slight variations of it play out in just about
every successful adoption case.

While it's true that the type checker is going to prevent people from writing valid code
they used to be able to write, every gradual type system has [escape hatches] to opt out
of those checks in some way. But it's the feeling of instant feedback and powerful editor
features that's impossible to convince someone of until they've had the chance to see it
in their own editor, on the files they work with.

One final, important note: **be supportive**. Advertise a single place for anyone to ask
questions and get quick responses.[^quick] Admit that this will likely lead to being
overworked for a bit until it takes off. In the long run as adoption and experience using
the type checker spreads, other teammates will start to help out with the evangelism as
the benefits spread outward.

[^quick]:
  Like, actually quick. "Notify for new Slack every message" quick. If you queue questions
  into some ticketing system and respond tomorrow, people will lose patience with _types
  overall_ not just with you.

[Sorbet]: https://sorbet.org
[`# typed: false`]: https://sorbet.org/docs/static#file-level-granularity-strictness-levels
[LSP Server]: https://microsoft.github.io/language-server-protocol/
[VS Code extension]: https://sorbet.org/docs/vscode
[gradual type checking]: https://sorbet.org/docs/gradual
[escape hatches]: https://sorbet.org/docs/troubleshooting#escape-hatches

