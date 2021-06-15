---
layout: post
title: "Surgery on Code from the Command Line"
date: 2019-07-30 09:32:48 -0700
comments: false
share: false
categories: ['bash', 'unix']
description: >
  One problem that comes up all the time for me is needing to manipulate
  files only on specific lines. Like, “find and replace this pattern,
  but only on specific lines.” In this post, I’ll introduce the CLI
  tools I’ve made to solve this class of problems with some examples.
strong_keywords: false
fancy_blockquotes: true
---

I'm frequently faced wth problems like "find and replace this pattern,
but only on specific lines," especially lines that have type errors on
them. I've built three new CLI tools that fit the need to operate on a
specific set of lines in a codebase. In this post I'll walk through a
couple examples to show them in action.

<!-- more -->

For the impatient, the tools that I've built are:

- [`multi-grep`]

  Like `grep`, but search for a pattern only at the specified
  locations, printing the locations where a match was found.

- [`multi-sub`]

  Substitute a pattern with a replacement at the specified locations,
  editing the file in place.

- [`diff-locs`]

  Convert a unified diff (like the output of `git diff`) into a list
  of locations affected by that diff.

With the quick intros out of the way, let's dive into some examples.

## `multi-grep`

Consider the file `locs.txt` below which is a list of `filename:line`
pairs:

```plain locs.txt
file_a.txt:13
file_a.txt:22
file_a.txt:79
file_b.txt:10
file_b.txt:11
```

(I call such `filename:line` pairs "locations" or "locs.")

Also consider that our project is huge, and has many more files
than just `file_a.txt` and `file_b.txt`. To filter the `locs.txt` list
to only the lines that contain the pattern "hello", we can use
`multi-grep`:

```bash
❯ multi-grep 'hello' locs.txt
file_a.txt:13
file_b.txt:10
```

The output means that only line 13 in `file_a.txt` and line 10 in
`file_b.txt` contain `hello`, given our initial set of 5 locs. The
search completely ignored all other files in the project because they
weren't mentioned in `locs.txt`. Searching with `multi-grep` scales with
the size of the input list, not with the size of the codebase being
searched.

This was a contrived example, but let's keep plowing forward with the
basics so we can apply them to a real example.

## `multi-sub`

If `multi-grep` is like `grep`, `multi-sub` is like `sed` but with only
the substitute command (`s/find/replace/`). Taking our previous example,
`multi-sub` finds and replaces a pattern on specific input lines:

```bash
❯ multi-sub 'hello' 'goodbye' locs.txt
# ... file_a.txt:13 edited: s/hello/goodbye/ ...
# ... file_b.txt:10 edited: s/hello/goodbye/ ...
```

In our previous example, only locations `file_a.txt:13` and
`file_b.txt:10` matched the pattern `hello`. So after running this
`multi-sub` command, those two files will be updated in place. On both
lines, `hello` will be replaced with `goodbye`.

## A larger example

With the basics out of the way, let's tackle a real-world problem. I
work with the output of [Sorbet] a lot, so I've used it for this next
example (Sorbet is a type checker for Ruby). When Sorbet detects type
errors in a program, it generates output like this:

```
test/payment_methods/update.rb:648: Method `[]` does not exist on `NilClass` component of `T.nilable(T::Hash[T.untyped, T.untyped])` http://go/e/7003
     648 |   assert_equal(nil, previous['billing_details']['address']['line1'])
                               ^^^^^^^^^^^^^^^^^^^^^^^^^^^

test/payment_methods/update.rb:649: Method `[]` does not exist on `NilClass` component of `T.nilable(T::Hash[T.untyped, T.untyped])` http://go/e/7003
     649 |   assert_equal(nil, previous['card']['checks']['address_line1_check'])
                               ^^^^^^^^^^^^^^^^

test/payment_methods/webhooks.rb:610: Method `[]` does not exist on `NilClass` component of `T.nilable(T::Hash[T.untyped, T.untyped])` http://go/e/7003
     610 |   assert_equal(2, notification['card']['exp_month'])
                             ^^^^^^^^^^^^^^^^^^^^

... many more errors ...

Errors: 253
```

The error messages look a lot better with colors! If you don't believe
me, you can [try Sorbet in the browser][sorbet.run] and see for
yourself.

The example above is inspired by real output that we saw at Stripe while
iterating on Sorbet. In this specific case, one of my coworkers had
improved Sorbet to track more information statically, which uncovered a
bunch of new type errors.

On the Sorbet team, we have a policy that before landing changes like
this, we modify Stripe's monorepo to preemptively silence the new
errors. Jordan Brown has a great article on the [Flow blog] justifying
this technique, so I'll skip the why and focus only on how to carry out
codemods like this.

As seen above, Sorbet error output always looks like
`filename.rb:line:Error message`. With a little massaging, this will
feed directly into `multi-sub`. Also notice that on the lines with
errors, the file contents always looked something like this:

```ruby
foo['bar']
```

To tell Sorbet to silence the errors on these lines, we'll need to wrap
the variable in a call to `T.unsafe(...)`:

```ruby
T.unsafe(foo)['bar']
```

This instructs to Sorbet to [forget all static type
information][T.unsafe] about the variable, thus silencing the error.
The key is to only perform this edit on lines with errors---
we'd hate to needlessly throw away type information by changing
unrelated lines! For things like this, `grep` and `sed` are often too
coarse-grained, because accessing a hash like this in Ruby is abundantly
common.

With `multi-sub`, we can write a really simple regex targetting these
hash lookups, but scope the regex to only lines in the error output:

```bash
# (1) Type check the project
❯ srb tc 2>&1 | \
  # (2) Filter the error output to only have the top-level error lines
  sed -e '/^ /d; /^$/d; /^Errors:/d' | \
  # (3) Chop off the error message, keeping only the filename:line
  cut -d : -f 1-2 | \
  # (4) Use multi-sub to replace things like foo[ with T.unsafe(foo)[
  multi-sub '\([a-zA-Z0-9_]+\)\[' 'T.unsafe(\1)['
```

Take a look through the four steps in the bash oneliner above:

1. Type check the project, then
2. filter out every line that doesn't have a location, then
3. chop of the error messages, and finally
4. use `multi-sub` to perform the substitution.

The net result is to update the files in place, performing the
substitution only on the lines with errors. Altogether once more, but on
one line, making use of a shell alias that I have to abbreviate the
inner two steps:

```bash
❯ srb tc 2>&1 | onlylocs | multi-sub '\([a-zA-Z0-9_]+\)\[' 'T.unsafe(\1)['
```

So with a super short bash oneliner, we've done a mass codemod that
fixes hundreds of errors at once, without having to silence more than
necessary.

If `grep` and `sed` are like chainsaws, I like to think of `multi-grep`
and `multi-sub` like scalpels---ideal for performing surgery on a
codebase. Regular expressions are often super imprecise tools for
codemods. But by scoping down the regex to run only on specific lines,
it doesn't matter. The added precision from explicit locations makes up
for how blunt regular expressions are.


## `diff-locs`

I've built one more command in the same spirit as `multi-grep` and
`multi-sub`, except that instead of consuming locations, it emits them.
Specifically, given a diff it outputs one `filename:line` pair for every
line that was affected by the diff.[^added] It's ideal for consuming the
output of `git show` or `git diff`:

[^added]: It defaults to only lines affected after the diff applies, but there's an option to make it show both added and removed lines.

```
❯ git show HEAD | diff-locs
test/payment_methods/update.rb:648
test/payment_methods/update.rb:649
test/payment_methods/webhooks.rb:610
```

I frequently use `diff-locs` to tweak codemods that I've already
committed. For example, we could go back and add a TODO comment above
each new `T.unsafe` call:

```bash
# (1) Generate a diff from git
❯ git show HEAD | \
  # (2) Convert the diff to a list of locations
  diff-locs | \
  # (3) Use multi-sub to insert a comment before each line
  multi-sub '^\( *\)' $'\\1# TODO: Unsilence this error\n\\1'
```

Recapping the pipeline above:

1. Use `git show` to generate a diff, then
2. convert the diff to a list of locations with `diff-locs`, and finally
3. insert a comment before each location with `multi-sub`.

`diff-locs` is particularly handy because after the first codemod, there
won't be type errors anymore! So to get a list of locations to perform
the edit on, we'd have had to check out the commit before fixing the
errors, save the list of errors to a file, go back, and finally do the
edit we wanted to in the first place.

Instead, we can take advantage of the fact that all that information is
already stored in git history, skipping a bunch of steps. (And asking
git to show a diff is way faster than asking Sorbet to re-typecheck a
whole project 😅)


## Aside: The implementations

One thing I'd like to point out is that I took some care to make sure
these commands weren't eggregiously slow. I prototyped these commands
with some hacky scripts, but after doing some rather large codemods I
got annoyed with them taking minutes to finish.

Some things that make these new commands fast:

- `multi-grep` and `multi-sed` re-use an already opened file to avoid
  reading extra information.
- `multi-grep` is written in Standard ML, `multi-sub` is written in
  OCaml, and `diff-locs` is written in Haskell---all languages which
  have great optimizing compilers. This means much better performance
  than a scripting language.

If you're curious, you can read through their implementations on GitHub:

- [`multi-grep`]
- [`multi-sub`]
- [`diff-locs`]

As always if you have questions or notice issues please don't hesitate
to reach out!


[`multi-grep`]: https://github.com/jez/multi-grep
[`multi-sub`]: https://github.com/jez/multi-sub
[`diff-locs`]: https://github.com/jez/diff-locs
[Sorbet]: https://sorbet.org
[sorbet.run]: https://sorbet.run
[Flow blog]: https://medium.com/flow-type/upgrading-flow-codebases-40ef8dd3ccd8
[T.unsafe]: https://sorbet.org/docs/troubleshooting#escape-hatches


<!-- vim:tw=72
-->
