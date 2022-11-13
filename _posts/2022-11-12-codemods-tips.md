---
# vim:tw=90
layout: post
title: "Tips for large-scale codemods"
date: 2022-11-12T21:34:51-05:00
description: >
  Some tips I've accumulated while working on a team that does a lot of codemods.
math: false
categories: ['codemods', 'devprod']
# subtitle:
# author:
# author_url:
---

I get the sense that people looking for advice on how to run a codemod are simply asking
to be told, "don't worry, they're actually easy." They _can_ be sometimes, but usually the
people desperate for codemod tips are also the people faced with running the gnarliest
codemods.

<!-- more -->

The biggest tip I can offer you is "shift your mindset." After a certain scale, codemods
always get at least a little painful. You're going to find some tips below that make
codemods less painful, but after a certain scale, you're never going to find a holy grail
tool that makes codemods painless. In fact **that's okay**, because:

- It means the work is **high-leverage**—you're one person sucking up the pain for the
  benefit of dozens, hundreds, or even thousands of others, and you get to claim all the
  impact.
- You're way more likely to finish the get the migration finished than you are by trying
  to shovel the work onto other teams' plates.

That's tip 1: don't let the fact that you know a codemod will be painful keep you from
doing it. Like anything else, balance the pain with the payoff, and make a judgement call.

Alright cool now let's dive into some more tactical tips.

\

# The unreasonable effectiveness of regular expressions

1.  A regex-based, find-and-replace tool with multiline matches lines is often the only
    tool you need.[^fastmod]

    You probably already know how to use regular expressions. Getting started with regular
    expressions will either show you that they're powerful enough to solve the problem
    outright, or be fast enough to prototype to the point where you realize, "yeah no, I'm
    definitely gonna need something more powerful for this."

1.  Don't give up so quickly on regex.

    Four hacky, specific regex can often take the place of an impossibly perfect regex. If
    you're struggling to find one regex that magically works in all cases, try making the
    regex so specific that you know it won't handle all the cases. The aim is to knock out
    the easiest 80% of cases, and then be left with a much smaller set of tricker things
    to codemod.

1.  Use age-old tricks like using `def foo\b`, `\.foo\(\b`, `= foo\(\b`, etc.

    The first one matches method definitions with the name `foo`. The latter two match
    calls to `foo` methods but not definitions.[^mostly] (This is basically the same tip
    as the last one.)

1.  Let the type checker be an input to your regex.

    Here's a trick: introduce a type error in such a way that the type checker will report
    an error at every place you want to codemod. (Sometimes this is as easy as changing
    a method definition's name. Sometimes the type checker errors are the reason why you
    have to do the codemod in the first place.)

    Then, run the type checker to get a list of locations, and then **only** run the regex
    on those locations.

    Sometimes you can get away with the locations being "any file with an error" but other
    times you're going to need something more specific. I've written some tools to support
    running [regex on specific lines of a file](/surgery-on-code/) in bulk.

1.  Let your test suite be an input to your regex.

    Like the previous tip, you can do things like raise test-only exceptions or insert
    test-only print statements to get a list of file locations to feed into the regex
    input.

    For example, maybe we want to replace calls to `old_method` with `new_method`. In
    Ruby, we can do something like log [caller(1..1)] to get the first entry in the
    backtrace at the top of `old_method`'s definition and feed those logs into our regex.

1.  Let production be an input to your regex.

    Do the same thing as above, but using production log lines (for obvious reasons, this
    only works with log lines, not exceptions like you might have been able to use in
    tests).

    When using this approach in production you might want to avoid doing things like
    looking at the stack trace specifically, as that can sometimes have unwanted
    performance impacts. (Of course, if performance isn't a problem, or it can tolerate a
    short-term degradation during a codemod, go ahead.)

[^fastmod]:
  If you don't have a preferred tool that meets these criteria, just use [fastmod].

[^mostly]:
  Mostly. But again, that's the whole point.

[caller(1..1)]: https://ruby-doc.org/core-2.7.2/Kernel.html#method-i-caller

[fastmod]: https://github.com/facebookincubator/fastmod

# When regex aren't good enough

1.  Your linter might have an API for writing auto-correctable lint rules.

    Here are the docs for how to write fixers attached to custom [ESLint] and [Rubocop]
    lint rules. The downside is that sometimes these APIs can be a little confusing to
    understand (slower spin up time). But compared to regex they're far less likely to be
    brittle.[^publish]

    Note that just like with regex scripts, you can use information from the type checker
    or the test suite to limit which files you use the lint rule on.

1.  A few manual fixes are actually okay.

    The goal is to finish the codemod, not to 100% automate the codemod. If you've tried
    all the above options and there are still 100 or fewer locations that need to change,
    you can probably knock them out in an afternoon (depending on how involved the change
    is).

    There's no shame in codemods that are 90% automated and 10% manual.

1.  Maybe use Vim?

    If you're already comfortable with Vim, some tools you might want to look at:

    ```
    :help gf
      Edit the file whose name is under the cursor

    :help gF
      Same as gf, but also position the cursor on the line number
      following the filename

    :help CTRL-W_gf
    :help CTRL-W_gF
      Prefixing gf or gF with <C-W> opens in a new tab (instead
      of the current buffer)

    :help %
      Jump to the matching paren or bracket under the cursor.

    :help q
    :help @
      Record and replay arbitrary keys.
    ```

    ```bash
    rg -n ... | vim -
    #               ^ reads content from stdin
    #  ^^ prefixes each result with filename:line
    ```

    Some codemods can be entirely automated with Vim. In others, using Vim with these
    tricks helps partially automate the manual parts.

1.  This is an oddly specific suggestion, but since I do it a lot:

    [Sorbet] has an [autocorrect mechanism], where autocorrects are tied to error
    messages. In the past I've patched Sorbet on a branch I never intend to commit. The
    branch reports a fake error and includes an autocorrect. I run the patched version of
    Sorbet, apply the autocorrects, then throw away the branch.

    (Had the *goal* been to introduce some new error in the first place then I would, of
    course, land both the error and the autocorrect.)

    If you're codemoding Ruby code, you might be able to do this. Depending on the
    language you're using, a similar approach might be available.[^analyzer] The benefit
    of this approach is that the autocorrect can rely on all the information Sorbet knows
    about the codebase in the codemod.


[Sorbet]: https://sorbet.org
[autocorrect mechanism]: https://sorbet.org/docs/cli#accepting-autocorrect-suggestions

[^analyzer]:
  Frequently, these things end up being called [static analyzers]. Different languages and
  compilers have varying degrees of support for building these.

[static analyzers]: https://learn.microsoft.com/en-us/dotnet/csharp/roslyn-sdk/tutorials/how-to-write-csharp-analyzer-code-fix


# Managing the complexity

1.  Split the change into entirely automated commits and entirely manual changes.

    Be very rigorous and do not edit an automated commit. This makes fixing conflicts
    easier (because conflicts in automated commits are fixed by throwing the commit away
    and re-running the script).

1.  Clearly label which commits are automated and which are manual.

    This makes it easier for your reviewer, and for you to figure out the best way to
    resolve conflicts.

    I like making the commit message title for automated commits be the command used
    to generate those changes. That when a rebase fails midway, you'll see the command
    used to generate that commit directly in the status message. It's also nice for your
    reviewer, because they can review both the command that generated the change and the
    changes.

1.  When rebasing, don't `pick` the automated commits, re-run the command that generated
    them.

    If you're using the previous convention for Git commit messages, this is as easy as
    using `git rebase -i` and changing `pick abc123 ...` lines to simply `exec ...`.

    This is also another reason why regex-based tooling is great, as regex tend to run
    fast and not require something like waiting for a sync script or a test run as input.

1.  Run the codemod in three phases: prep, codemod, cleanup.

    Say you want to delete a deprecated method, and replace it with a new one. Prep by
    adding the new method in its own change, and land that change. Run and land the
    codemod, but don't delete the old method. Finally the cleanup is removing the method.
    Try to land as many prep changes as possible.

    When structured like this, it's usually possible to fix conflicts by simply dropping
    codemod changes in files with conflicts. You can land the 99% of files that didn't
    have conflicts, and then make a second codemod change that re-runs the codemod on the
    files with conflicts.

1.  If you **really** expect a codemod to be long-lived, you probably want to structure
    the whole thing as one big script.

    It might look something like this:

    ```bash
    # Always run the migration fresh against origin/master
    git reset --hard origin/master

    # These prep branches are are still being reviewed and landed
    # Merge instead of rebase because it's simpler in the script.
    # (They might not all be stacked on each other, so they can be reviewed
    # and landed on their own.)
    #
    # As these branches land upstream, delete them from the script.
    git merge prep-branch-1 prep-branch-2

    # An example automated commit.
    #
    # Commit messages don't have to be full commands anymore,
    # because we have the complete script anyways.
    fastmod 'some thing' 'other thing'
    git commit -a -m "replace with other thing"

    # These commits are manual fixes to the automated commits.
    #
    # Each manual patch get a branch name so the ref can be
    # updated by the script each time.
    if ! git cherry-pick manual-patch-1; then
      read -p "Fix conflicts and commit in another session, then press Enter..."
    fi
    git checkout -B manual-patch-1

    # Note: now you can intermix automated and manual commits as needed,
    # growing the script as needed.
    ```

[ESLint]: https://eslint.org/docs/latest/developer-guide/working-with-rules#applying-fixes
[Rubocop]: https://docs.rubocop.org/rubocop/development.html#autocorrect

[^publish]:
  A nice side effect of writing a custom linter rule is that it can remain behind in the
  codebase, making it easier for people to resolve version control conflicts after the
  original codemod lands. Usually hacky regex scripts aren't robust enough to outlive
  their original run.

# How will I know if the change is okay?

1.  Rely on your existing safety rails.

    Ideally, your codebase has a type checker, a great test suite, some sort of gradual
    deploy procedures, and automated alerting.

    If not, maybe take the "move fast and break things" approach, where you land the
    codemod, and if landing it causes problems, the breakage has shown you the specific
    places in your infra that could be improved (like which tests to write, or which
    alerts to add).

1.  For some codemods, it's possible to write some sort of sanity check.

    For example, when rolling out a code formatter, you might be able to write a tool that
    says that the parsing the unformatted and formatted files produces equivalent ASTs.

    Another trick is to add some sort of debug assertion that an old method is never
    called (or that a method is always called in some post-codemod way), but still pass
    through to the old behavior in production.

    It's common for these debug assertions to cause tests to fail, but only log errors
    in production, which can then be collected and fixed in a following change.

\

Like I said up front, codemods are painful. Some of the tips mentioned here can help ease
the pain, but the codemod is only really going to succeed if you embrace the pain and
power through. It'll be fun[^fun] when you get to announce that it's done.

[^fun]:
  For further reading, [The Fun Scale]. With any luck, you'll manage to avoid type 3 fun,
  and come back to run another codemod in the future.

[The Fun Scale]: https://www.rei.com/blog/climb/fun-scale
