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

I get the sense that a lot of people looking for advice on how to run a codemod are simply
asking to be told, "don't worry, they're actually easy." Sometimes they are, but usually
the people desperate for codemod tips are also the people faced with running the gnarliest
codemods.

<!-- more -->

The biggest tip I can offer is to shift your mindset. Some of the tips below help make
codemods less painful, but after a certain scale, codemods are never going to be
pain-free. In fact **that's okay**, because it means the work is high-leverage—you're
one person sucking up the pain for the benefit of dozens, hundreds, or even thousands of
others. They get to ignore all the pain, and you get to claim all the impact.

That's tip 1: don't let the fact that you know a codemod will be painful keep you from
doing it. Like anything else, balance the pain with the payoff, and make a judgement call.

Alright cool now let's dive into some more tactical tips.

\

# 1. The unreasonable effectiveness of regular expressions

1.  A regex-based, find-and-replace tool supporting multiline matches[^fastmod] is often
    the only tool you need.

    You probably already know how to use regular expressions, so you can get started
    quickly and usually finish just as fast—either regex will be powerful enough to solve
    the problem outright, or let you prototype fast enough to realize, "yeah no, I'm
    definitely gonna need something more powerful for this."

1.  Don't give up so quickly on regex.

    Three or four oddly-specific regex can often take the place of an impossibly perfect
    regex. If you're struggling to find one regex that magically works in all cases, try
    making the regex so specific that you know it won't handle all the cases. The aim is
    to knock out the easiest 80% of cases, and then either repeat or fix the rest manually.

1.  Use age-old tricks like using `def foo\b`, `\.foo\(\b`, `= foo\(\b`, etc.

    The first one matches method definitions with the name `foo`. The latter two match
    calls to `foo` methods but not definitions.[^mostly] (This is basically the same tip
    as the last one.)

    This won't be as robust as using some sort of AST-based codemod tool, but it's way
    easier to remember than whatever the API of such a tool is, so you can start making
    progress quickly.

1.  Let the parser sanity-check your find-and-replace result.

    Here's a trick for when your regex sometimes fails in a way that causes a syntax
    error. First, run the regex and commit the result. Then run the language's parser over
    all the files, and list the files that now have syntax errors.[^sed] Revert all the
    changes the regex made to those files.

    Chances are that a huge portion of the original find and replace change was valid. The
    files whose changes had to be reverted can be handled separately (either with another
    oddly-specific regex, or by hand).

1.  Let the type checker be an input to your regex.

    Here's another trick.[^another] introduce a type error in such a way that the type
    checker will report an error at every place you want to codemod. (Sometimes this is as
    easy as changing a method definition's name, and sometimes it's the fact that there
    are the type errors that you're doing the codemod in the first place.)

    Then, run the type checker to get a list of locations, and then **only** run the regex
    on those locations.

    This might mean simply "run on any matching files" but sometimes you need something
    even more specific: "run on only the exact lines with type errors." I've written some
    tools to do [exactly that](/surgery-on-code/).

1.  Let your test suite be an input to your regex.

    Like the previous tip, except using test-only print statements to get the list of
    locations.

    For example, maybe we want to replace calls to `old_method` with `new_method`. In
    Ruby, we could do something like edit the implementation of `old_method` to log
    [caller(1..1)] every time it's called. After running our tests, the log will list every
    call site to `old_method` covered by our test suite, which we can then use to
    selectively apply our regex (using those [custom codemod tools](/surgery-on-code/)
    mentioned before).

1.  Let production logs be an input to your regex.

    This involves doing the same thing as the previous two tips above, but using
    production log lines.

    When dealing with production you might want to specifically avoid materializing a
    stack trace (because it can be slow), which is why you probably want to try with
    test-only logging first. Of course, if performance isn't a problem, or it can tolerate
    a short-term degradation during a codemod, go ahead.

[^fastmod]:
  If you don't have a preferred tool that meets these criteria, just use [fastmod].

[^mostly]:
  Mostly. But again, that's the whole point.

[^sed]:
  If the language doesn't have a way to list only the files with errors (and not the
  errors), just use `sed` to filter the command output.

[^another]:
  I like these tricks because they're easy to remember. Just run a tool that your codebase
  already uses and post-process its output. There's basically no additional setup nor time
  spent learning an esoteric codemod API.

[caller(1..1)]: https://ruby-doc.org/core-2.7.2/Kernel.html#method-i-caller

[fastmod]: https://github.com/facebookincubator/fastmod

# 2. When regex aren't good enough

1.  A few manual fixes are actually okay.

    The goal is to finish the codemod, not to 100% automate the codemod.[^automate] If
    you've tried and failed to entirely automate the codemod, there's no shame in doing a
    little bit of manual work to fix the rest of the cases.

    In my experience, anything smaller than ~75 files worth of things to codemod can
    usually be done by hand in an afternoon in a pinch (depending on how involved the
    change is). If the point is to finish the migration as quickly as possible, you might
    get further by just rolling up your sleeves for that last 10% than sinking another 3
    days into figuring out how to automate it.

1.  Your linter might have an API for writing auto-correctable lint rules.

    Here are the docs for how to write fixers attached to custom [ESLint] and [Rubocop]
    lint rules. The downside is that sometimes these APIs can be a little foreign or
    confusing. But compared to regex they're far less likely to be brittle.[^publish]

    Note that just like with regex scripts, you can use information from the type checker
    or the test suite to limit which files you use the lint rule on if you have to.

1.  It might finally be time for a language-specific, AST-based codemod tool.

    While most languages have pluggable linters, some languages go a step further and
    have dedicated codemod tools. These tend to be more common in languages like
    JavaScript that already have a rich ecosystem of source-to-source translation tools,
    but it's possible to find them in other languages too.

1.  Maybe use Vim?

    If you're already comfortable with Vim, it's a great way to partially automate the
    parts of the codemod that need manual intervention. Some tools you might want to look
    at:

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

1.  Check if your language supports pluggable static analyzers.

    This is basically the same approach as above, but as a first-class feature of your
    language's compiler. For example, Clang supports writing [compiler plugins] and C# has
    a [rich static analyzer] API. These APIs tend to be maximally powerful, as they can
    leverage nearly everything the compiler knows about a codebase, and sometimes more.
    You pay for it by these APIs tending to be the hardest to learn to use.

1.  This is an oddly specific suggestion, but since I do it a lot:

    [Sorbet] does not support pluggable static analyzers, but it does have an [autocorrect
    mechanism], where autocorrects are tied to error messages.

    In the past I've temporarily patched Sorbet (on a branch) to introduce a new, fake
    error[^fake] that includes an autocorrect which can take advantage of everything Sorbet
    knows. I run the patched version of Sorbet, apply the autocorrects, then throw away
    the patch.

[^automate]:
  This is true for most individuals doing codemods on large, proprietary codebases. This
  might not apply to you if you maintain some open-source tool and want to release an
  automated codemod alongside a breaking API change.

[ESLint]: https://eslint.org/docs/latest/developer-guide/working-with-rules#applying-fixes
[Rubocop]: https://docs.rubocop.org/rubocop/development.html#autocorrect

[^publish]:
  A nice side effect of writing a custom linter rule is that it can remain behind in the
  codebase, teaching people (via an error message) what the replacement for an old API is
  after the original codemod lands.

[compiler plugins]: https://clang.llvm.org/docs/ClangPlugins.html
[rich static analyzer]: https://learn.microsoft.com/en-us/dotnet/csharp/roslyn-sdk/tutorials/how-to-write-csharp-analyzer-code-fix

[Sorbet]: https://sorbet.org
[autocorrect mechanism]: https://sorbet.org/docs/cli#accepting-autocorrect-suggestions

[^fake]:
  Had the *goal* been to introduce an error in the first place, then I would of course
  land both the error and the autocorrect.


# 3. Managing the life cycle of a codemod

1.  Split the change into commits which are either entirely automated or entirely manual.

    Be very rigorous and do not edit an automated change in the same commit. This makes
    fixing conflicts easier (automated commits with conflicts are simply thrown away and
    regenerated).

1.  Clearly label which commits are automated and which are manual.

    This makes it easier for your reviewer, and for you to figure out the best way to
    resolve conflicts.

1.  Put the full command itself in the commit title for automated commits.

    That when a rebase fails midway, you'll see the command used to generate that commit
    directly in the status message. It's also nice for your reviewer, because they can
    review both the command that generated the change and the change itself.

1.  When rebasing, don't `pick` the automated commits, re-generate them.[^regen]

    This is not simply to avoid conflicts, but also to catch any new locations that have
    been added between when you started the codemod and now.

    If you're using the previous convention for Git commit messages, this is as easy as
    using `git rebase -i` and changing `pick abc123 ...` lines to simply `exec ...`.

1.  Run the codemod in three phases: prep, codemod, cleanup.

    Say you want to delete a deprecated method and replace it with a new one. Prep by
    adding the new method in its own change, and land that change. Run and land the
    codemod, but don't delete the old method. Finally cleanup by removing the method.

1.  Land enough prep changes that it's possible to run old and new code simultaneously.

    This won't always be possible, but it's worth striving for in every change. If the old
    and new code can live side by side, it'll be easier to land the change and
    importantly, to revert *parts* of a change (if there are problems) without having to
    rollback the entire change.

1.  Consider ignoring conflicts and fixing them later.

    Sometimes right as you're about to land a codemod, another change sneaks in that
    conflicts with it. Rather than re-running the whole codemod or attempting to fix the
    conflicts, consider just getting rid of your changes in files with conflicts, and
    landing the remaining files that don't have conflicts.

    After the first lands, you can land a second codemod change which modifies only the
    files that got dropped from the previous change.

    (This obviously only works if you've landed enough prep changes.)

1.  If you expect a codemod to be **really** long-lived, structure the whole thing as one
    big script.

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

    Now you should never need to rebase, and can always re-run the script when the code
    changes.

[^regen]:
  This is also another reason why regex-based tooling is great, as regex commands are
  usually fast enough to run during a rebase without having to pause and wait for the
  codebase to rebuild mid rebase.

# 4. How will I know if the change is okay?

1.  Rely on your existing safety rails.

    Ideally, your codebase has a type checker, a great test suite, some sort of gradual
    deploy procedures, and automated alerting.

    If not, maybe take the "move fast and break things" approach, where you land the
    codemod, and if landing it causes problems, the breakage has shown you the specific
    places in your infra that could be improved (like which tests to write, or which
    alerts to add). Also if you landed enough prep work, hopefully it's possible to only
    revert the problems, not the entire change.

1.  For some codemods, it's possible to write some sort of sanity check.

    For example, when rolling out a code formatter, you might be able to write a tool that
    says that the parsing the unformatted and formatted files produces equivalent ASTs.

    Another trick is to add some sort of debug assertion that an old method is never
    called (or that a method is always called in some post-codemod way), but still pass
    through to the old behavior in production.

    It's common to write these debug assertions such that they cause hard failures in
    tests, but in production only log an error. These logs can then be collected and fixed
    in a follow-up change.

\

Like I said up front, codemods involve pain. Some of the tips mentioned here can help ease
the pain, but the codemod is only really going to succeed if you embrace the pain and
power through. With any luck, you'll find that you had fun[^fun] when you get to announce
that it's finished.

[^fun]:
  For further reading, [The Fun Scale]. With any luck, you'll manage to avoid type 3 fun,
  and come back to run another codemod in the future.

[The Fun Scale]: https://www.rei.com/blog/climb/fun-scale
