---
layout: post
title: "Surgery on codebases from the CLI"
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
---

One problem that comes up all the time for me is needing to manipulate
files only on specific lines. Like, "find and replace this pattern, but
only on specific lines." In this post, I'll introduce the CLI tools
I've made to solve this class of problems with some examples.

<!-- more -->

For the impatient, the tools that I've built are:

- [`multi-grep`]
  - Like `grep`, but search for a pattern only at the specified
    locations, printing the locations where a match was found.
- [`multi-sub`]
  - Substitute a pattern with a replacement in place only at the
    specified locations.
- [`diff-locs`]
  - Convert a unified diff (like the output of `git diff`) into a list
    of locations affected by that diff.

Now rather than trying to explain exactly how they work, let's just dive
into some examples.

## `multi-grep`

Consider that we have a list of filename:line pairs---which I call
"locations" or "locs"---formatted like this:

```plain locs.txt
file_a.txt:13
file_a.txt:22
file_a.txt:79
file_c.txt:10
file_c.txt:11
```

Also consider that our project has files `file_{a,b,c}.txt` in it. If we
want to filter this list to **only** the lines that contain the pattern
`hello`, this is a perfect use case for `multi-grep`:

```
❯ multi-grep 'hello' locs.txt
file_a.txt:13
file_c.txt:10
```

This output tells us that only line 13 in `file_a.txt` and line 10 in
`file_c.txt` contain `hello` from our initial set of 5 locs. And the
search will completely ignore `file_b.txt`, because it wasn't mentioned
in any locs in `locs.txt`.

This is of course a contrived example, but let's keep plowing forward
with the basics so we can apply them to a real example.

## `multi-sub`

If `multi-grep` is like `grep`, `multi-sub` is like `sed` but with only
the substitute command (`s/find/replace/`). Taking our previous example,
`multi-sub` finds and replaces a pattern on specific input lines:

```bash
❯ multi-sub 'hello' 'goodbye' locs.txt
# ... file_a.txt:13 updated in place -> s/hello/goodbye/ ...
# ... file_c.txt:10 updated in place -> s/hello/goodbye/ ...
```

In our previous example, only locations `file_a.txt:13` and
`file_c.txt:10` matched the pattern `hello`. So after running
`multi-sub`, those two files will be updated in place, with `hello`
becoming `goodbye` only at those two locations.

## A larger example

Now that we have the basics out of the way, we can get into some meatier
examples. I work with the output of [Sorbet] a lot, so all my examples
are going to feature it (Sorbet is a type checker for Ruby). When it
detects errors in a program, it generates output like this:

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
errors, the output always looks something like this:

```ruby
foo['bar']
```

To silence the errors on these lines, we can modify the line to this:

```ruby
T.unsafe(foo)['bar']
```

which will cause Sorbet to [forget static type information][T.unsafe]
about the variable (thus silencing the error). The key point is that we
**only** want to change the lines with errors. We'd hate to accidentally
change lines unrelated to the errors, and needlessly lose static types!
This is why `grep` is often too coarse-grained of a tool.

Instead, we can write a really simple regex, but scope it to only the
lines in the error output:

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

This updates the files in place, performing the substitution only on the
lines with errors. Altogether in one line, making use of a shell alias
that I have to abbreviate the inner two steps:

```bash
❯ srb tc 2>&1 | onlylocs | multi-sub '\([a-zA-Z0-9_]+\)\[' 'T.unsafe(\1)['
```

So with a super short bash oneliner, we've done a mass codemod that
fixes hundreds of errors at once, without having to silence more than
necessary.

If `grep` and `sed` are like chainsaws, I like to think of `multi-grep`
and `multi-sub` like scalpels---ideal for performing surgery on a
codebase. Regex are often super imprecise tools for codemods. But by
scoping down the regex to run only on specific lines, it doesn't
matter. The added precision from location information makes up for a
blunt regular expression.


## `diff-locs`

I've built one more command in the same spirit as `multi-grep` and
`multi-sub`, except that instead of consuming locations, it emits them.
Specifically, given a diff it outputs one `filename:line` pair for every
line that was affected by the diff.[^added] For example, if we committed
the substitutions made by the example in the previous section, the
output from `diff-locs` would look like this:

[^added]: It defaults to only lines affected after the diff applies, but there's an option to make it show both added and removed lines.

```
❯ git show HEAD | diff-locs
test/payment_methods/update.rb:648
test/payment_methods/update.rb:649
test/payment_methods/webhooks.rb:610
```

This command is useful for following up on codemods that have already
been performed to tweak them in some way. For example, maybe we want to
go back and add a comment with a TODO to unsilence the error:

```bash
# (1) Generate a diff from git
❯ git show HEAD | \
  # (2) Convert the diff to a list of locations
  diff-locs | \
  # (3) Use multi-sub to insert a comment before each line
  multi-sub '^\( *\)' $'\\1# TODO: Unsilence this error\n\\1'
```

This is super handy. After the first codemod, the type errors won't
exist anymore, so we can't just re-run Sorbet to get it to print the
locations again. Instead, we can take advantage of the fact that that
information is already stored in git history to regenerate it on demand.


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

Other than that, if you have questions or notice issues, please don't
hesitate to reach out!


[`multi-grep`]: https://github.com/jez/multi-grep
[`multi-sub`]: https://github.com/jez/multi-sub
[`diff-locs`]: https://github.com/jez/diff-locs
[Sorbet]: https://sorbet.org
[Flow blog]: https://medium.com/flow-type/upgrading-flow-codebases-40ef8dd3ccd8
[T.unsafe]: https://sorbet.org/docs/troubleshooting#escape-hatches


<!-- vim:tw=72
-->
