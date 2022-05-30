---
# vim:tw=90
layout: post
title: "Is tree-sitter good enough?"
date: 2022-05-30T04:43:46-04:00
description: TODO
math: false
categories: ['parsing', 'tree-sitter']
# subtitle:
# author:
# author_url:
---

My answer: mostly no, or at the very least not for all cases, though I really wish it
were good enough for the use cases I have, because then I would have less work to do.

<!-- more -->

I'm guessing you already know what tree-sitter is because you clicked on the title. If
you clicked because you were hoping to find out: [tree-sitter] is a relatively[^new] new
project which aims to make writing fast, error-tolerant parsers take less work. To do
that, it provides both pre-built parsers for common programming languages and a toolkit
for building new parsers. It's known for use in various GitHub features by way of their
[semantic] tool, which powers the code navigation tooltips that you sometimes see on
GitHub.[^semantic]

[^new]:
  Is it still new? The GitHub repo has commits dating back to 2013, though I only
  first heard about it in 2017. It still has a feeling of newness about it, but I digress.

[^semantic]:
  The semantic repo actually has a [short overview][why-tree-sitter] of why they chose
  tree-sitter, along with some drawbacks.

I see a lot of talk about tree-sitter these days. And for a lot of projects, it's really
nice! This is especially true for projects that want to be able to parse a super wide
variety of languages with an otherwise uniform API with the least amount of manual work.
Things like writing a syntax highlighter in an editor, or building something like
[ParEdit] for arbitrary languages, or providing best-effort jump-to-definition
results.[^approval]

[^approval]:
  Another neat use case, from work: every time a commit is pushed to an approved PR, the
  approval is dismissed, unless (using tree-sitter) the CI system detects that the parse
  tree hasn't changed. This spares comment and formatting changes the toil of a re-review.

When those goals are flipped—it has to work for exactly one language, and "best-effort"
isn't enough—tree-sitter becomes less attractive. As someone who works on language tooling
[professionally](https://jez.io/#work) and is lazy, it's kind of disappointing. As much as
tree-sitter enthusiasts sell it as a magical solution that can free me from having to
think about parsers, it's just not been that silver bullet in my experience.

There are two questions I would pose to anyone curious about using tree-sitter for their
parser:

1.  Is serving autocompletion requests going to be one of your use cases?
2.  How much do you care about custom messages for syntax errors?

If either or both of these are important, I'd probably recommend rolling your own parser,
either using a parser generator or using recursive descent by hand. The longer lived your
project is, the more these constraints are going to be hard to accomplish in tree-sitter.

At this point, I should caveat this by saying that I've come to these conclusions having
spent far less time with tree-sitter than I have with other parsing techniques, so maybe I
only think they're harder than they actually are because I lack a depth of tree-sitter
experience.

When investigating tree-sitter as a replacement for an existing parser, it's been too easy
to find parses from tree-sitter that don't look like what I'd expect out of a parser that
is meant to handle the kinds of errors programmers write in the real world.

It's entirely possible that I've just been _really_ unlucky, and that the problems I've
found are all fixable with a few bug reports and a little elbow grease. But it just seems
to me that if I'm going to have to spend time fixing bugs anyways, it may as well be in a
parser I've written myself.

Let me show what I mean. Here are some snippets of code that I hope you'll agree
represents code someone might write mid-edit, for which you want to both (1) provide
autocompletion results for and (2) provide a human-friendly error message for. Following
the code snippet is the parse result produced by the corresponding tree-sitter grammar for
that language. You can follow along on the [tree-sitter online playground].

\

Let's start with a Ruby program:

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

By way of comparison, here's what a valid parse looks like:

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

Which tells us (1) that there was a method call, (2) what the receiver of the method call
was so we know where to start looking for methods to autocomplete, (3) that the syntax
error was localized to the method call.

There's a similar problem with constants accesses:

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

\

Maybe this example was a little contrived, because a comparable program written in
JavaScript actually parses the way I'd hoped the Ruby one did. Okay, maybe it's just a bug
in the Ruby grammar?

This next snippet reproduces in both Ruby and JavaScript:

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

It's hard to see what's going on here without matching up the line numbers in the parse
tree. Here's essentially what the snippet above looks like to tree-sitter:

```js
class A {
  foo() {
    this.bar() {
  }
}
```

Some points:

- Even though `bar() { ... }` is valid method syntax, that's gone. The parser thinks that
  there was a call to a method named `bar` on an implicit receiver (i.e., `this`).
- The syntax error shows up after the imagined call to `bar`, not associated with the
  `foo` method.

It gets even worse if the snippet changes so that `bar` actually has parameters and code in
the method body.[^worse] With a parse that drops the `bar` method definition entirely, the
user no longer receives autocompletion results inside `bar` until they fix the error in
`foo`.

[^worse]:
  The parameters become call-site arguments, and the code acts as though it was written
  inside `foo` not `bar`.

The best error message here would be to point out to the author that their curly braces
are mismatched,[^rust] and then ideally use that information to recover when parsing.

[^rust]:
  Indeed, that's [exactly the error](https://play.rust-lang.org/?version=stable&mode=debug&edition=2021&gist=872bd946a8789aba9d49e07aef614819)
  on a comparable Rust example. (Rust's parser is hand-written.)

\

I could turn this into a post full of weird code snippets and poor parse results, but
that's not useful. What I'm trying to show is that when the demands are "the one specific
language I care about has lots of idiosyncratic parse errors that are super common when in
an editor," then you're still going to be limited by the quality of the particular
tree-sitter grammar you're working with. Fixing bugs in that grammar requires working
within the constraints tree-sitter imposes to be able to power all the grammar-agnostic
features (best-effort error recovery, uniform API, etc.) that it provides.

On the other hand, if you control the whole parser, you can bend it however you want. You
arguably do more work, but you at least have the option of doing more work (with the
reward of better results).

Don't get me wrong, I still think tree-sitter is a great project with a neat new idea, and
it's done more to make parsing more accessible than any recent effort. But too many people
tout it as something with no tradeoffs, and I just don't think that's fair.

If you think I'm overlooking something, please let me know and I'll happily update this
post, and maybe even start using tree-sitter in my projects.

\

# Appendix: Sorbet

This is the part where I get to gleefully show off Sorbet's parser, which I'm quite proud
of.

```ruby
# typed: true
class A
  def foo
    puts('inside foo')

  puts('after (outside) foo')

  def bar(x)
    x.
  end
end
```

The parse tree:

```ruby
s(:class,
  s(:const, nil, :A), nil,
  s(:begin,
    s(:def, :foo, nil,
      s(:begin,
        s(:send, nil, :puts,
          s(:str, "inside foo")))),
    s(:send, nil, :puts,
      s(:str, "after (outside) foo")),
    s(:def, :bar,
      s(:args,
        s(:arg, :x)),
      s(:send,
        s(:lvar, :x), :<method-name-missing>))))
```

The errors:

```
editor.rb:10: unexpected token "end" https://srb.help/2001
    10 |  end
          ^^^

editor.rb:11: unexpected token "end of file" https://srb.help/2001
    11 |end
    12 |

editor.rb:3: Hint: this "def" token might not be properly closed https://srb.help/2003
     3 |  def foo
          ^^^
    editor.rb:11: Matching `end` found here but is not indented as far
    11 |end
        ^^^
Errors: 3
```

If you use Sorbet and ever come across a file where you either didn't get the
autocompletion results that you wanted or you thought a syntax error was particularly
confusing, feel free to [craft a bug report here] and I'd be happy to take a look.

[tree-sitter]: https://tree-sitter.github.io/tree-sitter/
[semantic]: https://github.com/github/semantic
[why-tree-sitter]: https://github.com/github/semantic/blob/master/docs/why-tree-sitter.md
[ParEdit]: https://www.emacswiki.org/emacs/ParEdit
[tree-sitter online playground]: https://tree-sitter.github.io/tree-sitter/playground
[craft a bug report here]: https://sorbet.run/?arg=--print=parse-tree-whitequark#%23%20typed%3A%20true%0A%23%20Share%20your%20example%20with%20%22Examples%20%3E%20Create%20issue%20with%20example%22%0A



