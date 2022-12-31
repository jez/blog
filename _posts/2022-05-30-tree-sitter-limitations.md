---
# vim:tw=90
layout: post
title: "Is tree-sitter good enough?"
date: 2022-05-30T04:43:46-04:00
description: >
  While tree-sitter is a neat project with lots of valid use cases, it isn't a silver
  bullet for all parsing-related projects.
math: false
categories: ['parsing', 'tree-sitter']
# subtitle:
# author:
# author_url:
---

**tl;dr**: no, or at the very least, "not for every use case." (Though I really wish it
were for the use cases I have, because it would save me a lot of work.)

<!-- more -->

> I'm guessing you already know what tree-sitter is because you clicked on the title. If
> you clicked because you were hoping to find out: [tree-sitter] is a relatively[^new] new
> project which aims to make writing fast, error-tolerant parsers take less work. To do
> that, it provides both pre-built parsers for common programming languages and a toolkit
> for building new parsers. It's known for use in various GitHub features by way of their
> [semantic] tool, which powers the code navigation tooltips that you sometimes see on
> GitHub.[^semantic]

[^new]:
  Is it still new? The GitHub repo has commits dating back to 2013, though I only
  first heard about it in 2017. It still has a feeling of newness about it, but I digress.

[^semantic]:
  The semantic repo actually has a [short overview][why-tree-sitter] of why they chose
  tree-sitter, along with some drawbacks.

For a lot of projects, tree-sitter is really nice! _Especially_ for projects where the
quality of the parser is less important than the quantity of languages supported. For
example: an editor syntax highlighter. It's more important that the editor highlight lots
of languages' syntax than it is that every language is highlighted perfectly. Another
example: building something like [ParEdit] for arbitrary languages. Or providing
jump-to-def that's mostly better than plain-text code search.[^approval] For a lot of
these applications it's actually _completely fine_ if there's a flagrant bug in one of the
grammars, because the project is still so useful in all the other languages.

[^approval]:
  Another neat use case, from work: every time a commit is pushed to an approved PR, the
  approval is dismissed, unless (using tree-sitter) the CI system detects that the parse
  tree hasn't changed. This spares comment and formatting changes the toil of a re-review.

But when the goals are flipped—it has to work for exactly one language, and the quality of
the parser is paramount—tree-sitter becomes less attractive. There are two questions I
would pose to anyone curious about using tree-sitter for their parser:

1.  Is serving autocompletion requests a key use cases?

    Serving autocompletion requests requires an unnaturally high parse fidelity, even when
    the buffer is ridiculed with syntax errors.

2.  How much do you care about crafting custom messages for syntax errors?

    Customizing syntax error messages becomes context-dependent very quickly. It's easy to
    maintain that context when your parser allows running arbitrary code, and hard when
    the parser is constrained to a declarative DSL.

If either of these goals are important, I'd recommend rolling your own parser (using the
technique of your choice). It comes down to flexibility: a tree-sitter grammar, with it's
declarative specification, provides a lot of neat features for free (like error recovery),
but places a ceiling on possibilities for future improvement.

Let me show some examples.[^bugs] The snippets of code below are exactly the kinds of
programs that people type in their editors, but which tree-sitter doesn't parse well
enough. You can follow along on the [tree-sitter online playground].

[^bugs]:
  It's entirely possible that I've just been _really_ unlucky, and that the problems I've
  found are all fixable with a few bug reports and a little ingenuity. But if it's
  going to take ingenuity anyways, isn't that the same as writing a parser myself?

\

Let's start with a Ruby program, alongside its parse result:

```ruby
f = ->(x) {
  x.
}
```

```{.numberLines .hl-8 .hl-9}
program [0, 0] - [3, 0]
  assignment [0, 0] - [2, 1]
    left: identifier [0, 0] - [0, 1]
    right: lambda [0, 4] - [2, 1]
      parameters: lambda_parameters [0, 6] - [0, 9]
        identifier [0, 7] - [0, 8]
      body: block [0, 10] - [2, 1]
        identifier [1, 2] - [1, 3]
        ERROR [1, 3] - [1, 4]
```

Here's what a comparable, syntactically-valid parse looks like:

```ruby
f = ->(x) {
  x.foo
}
```

```{.numberLines .hl-8 .hl-9 .hl-10}
program [0, 0] - [3, 0]
  assignment [0, 0] - [2, 1]
    left: identifier [0, 0] - [0, 1]
    right: lambda [0, 4] - [2, 1]
      parameters: lambda_parameters [0, 6] - [0, 9]
        identifier [0, 7] - [0, 8]
      body: block [0, 10] - [2, 1]
        call [1, 2] - [1, 7]
          receiver: identifier [1, 2] - [1, 3]
          method: identifier [1, 4] - [1, 7]
```

In the good parse, tree-sitter produces a `call` node. In the bad parse, it just produces
a `block` that has a list containing two elements. Ideally, what we'd see here is
something like this:

```
call
  receiver: identifier
  method: ERROR
```

Which tells us that there was a method call, what the receiver of the method call was so
we know where to start looking for methods to autocomplete, and that the syntax error was
localized to the method call.

There's a similar problem with constant accesses:

```ruby
f = ->(x) {
  A::
}
g = ->(x) {
  A::B
}
```

```{.numberLines}
program [0, 0] - [6, 0]
  # ...
      body: block [0, 10] - [2, 1]
        constant [1, 2] - [1, 3]
        ERROR [1, 3] - [1, 5]
  # ...
      body: block [3, 10] - [5, 1]
        scope_resolution [4, 2] - [4, 6]
          scope: constant [4, 2] - [4, 3]
          name: constant [4, 5] - [4, 6]
```

... and a similar problem with `@` (the start of an instance variable access), and with `x =` (the start of an assignment).

\

Maybe this example was a little contrived? Comparable programs written in JavaScript
actually parse the good way, so maybe that's just an indictment of tree-sitter-ruby, not
tree-sitter itself.

But this next snippet reproduces in both Ruby and JavaScript:

```js
class A {
  foo() {

  bar() {
  }
}
```

```
program [0, 0] - [6, 0]
  class_declaration [0, 0] - [5, 1]
    name: identifier [0, 6] - [0, 7]
    body: class_body [0, 8] - [5, 1]
      member: method_definition [1, 2] - [4, 3]
        name: property_identifier [1, 2] - [1, 5]
        parameters: formal_parameters [1, 5] - [1, 7]
        body: statement_block [1, 8] - [4, 3]
          expression_statement [3, 2] - [3, 9]
            call_expression [3, 2] - [3, 7]
              function: identifier [3, 2] - [3, 5]
              arguments: arguments [3, 5] - [3, 7]
            ERROR [3, 8] - [3, 9]
```

To make it more obvious why this parse tree is not great, it's basically the same parse
tree as produced by this program:

```js
class A {
  foo() {
    bar();
    {
  }
}
```

Some points:

- Even though `bar() { ... }` is valid method syntax, there's no definition of a method
  called `bar` in the parse. Instead, the parser thinks that there was a **function call**
  to a function named `bar` that doesn't exist.
- The syntax error shows up after the imagined call to `bar` (associated with the `{`
  immediately after the call to `bar`), not associated with the `foo` method.

If the user's cursor was inside the `bar` method and asking for completion results, we'd
be forced to serve them completion results as though their cursor was inside the
half-formed `foo` method, which produces completely wrong results.

This behavior is not unique to JavaScript. I've reproduced it almost verbatim in Ruby and
Java, and partially in most other tree-sitter parsers (C#, C++, Rust, etc.).

The best behavior here would be to point out that the curly braces are mismatched,[^rust]
and then recover assuming that the user fixed that mismatch, preserving the `bar` method.

[^rust]:
  Indeed, that's [exactly the error](https://play.rust-lang.org/?version=stable&mode=debug&edition=2021&gist=872bd946a8789aba9d49e07aef614819)
  on a comparable Rust example. (Rust's parser is hand-written.)

\

I could turn this into a post full of weird code snippets and poor parse results, but
that's not useful. What I'm trying to show is that when the demands are, "The one specific
language I care about has lots of idiosyncratic but common parse errors that I want to
handle well," then prepare to devote a substantial amount of time to tweaking anyways. I
prefer doing that in a setting that gives me maximum flexibility, so that I can be as
clever as I need to eke out good parse results.

Don't get me wrong, I still think tree-sitter is a great project with a neat new idea. I
also haven't shown how surprisingly good tree-sitter was on a lot of the examples I tried!
All I'm saying is that tree-sitter comes with tradeoffs, and that it's not useful to
respond to every complaint about an existing parser with, "If you just used tree-sitter,
your problems would go away," because that's not true. For a certain class of parsing
problems, tree-sitter is not quite good enough.

\

*If I've overlooked something, please let me know and I'll happily update this post (and
maybe even start using tree-sitter in my projects).*


[tree-sitter]: https://tree-sitter.github.io/tree-sitter/
[semantic]: https://github.com/github/semantic
[why-tree-sitter]: https://github.com/github/semantic/blob/master/docs/why-tree-sitter.md
[ParEdit]: https://www.emacswiki.org/emacs/ParEdit
[tree-sitter online playground]: https://tree-sitter.github.io/tree-sitter/playground
[craft a bug report here]: https://sorbet.run/?arg=--print=parse-tree-whitequark#%23%20typed%3A%20true%0A%23%20Share%20your%20example%20with%20%22Examples%20%3E%20Create%20issue%20with%20example%22%0A



