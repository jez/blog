---
# vim:tw=90
layout: post
title: "Parse Error Recovery in Sorbet: Part 2"
date: 2022-02-22T03:56:34-05:00
description: >
  This is the second post in a series about "things I've learned while making improvements
  to Sorbet's parser." Specifically, it's about approaches I considered but decided
  against.
math: false
categories: ['sorbet', 'parsing']
subtitle: "What I Didn't Do"
# author:
# author_url:
---

This is the second post in a series about "things I've learned while making improvements
to Sorbet's parser." Specifically, it's about approaches I considered but decided against.

<!-- more -->

- [Part 1: Why Recover from Syntax Errors][part1]
- **[Part 2: What I Didn't Do][part2]**
- [Part 3: Tools and Techniques for Debugging a (Bison) Parser][part3]
- (*coming soon*) Part 4: Bison's `error` Token
- (*coming soon*) Part 5: Backtracking, aka Lexer Hacks
- (*coming soon*) Part 6: Falling Back on Indentation, aka More Lexer Hacks

[part1]: /error-recovery-part-1/
[part2]: /error-recovery-part-2/
[part3]: /error-recovery-part-3/
[part4]: /error-recovery-part-4/
[part5]: /error-recovery-part-5/
[part6]: /error-recovery-part-6/

Before we get started, I should say: I'm not, like, an expert at writing parsers. In fact
of all the changes I've made to Sorbet, it's definitely up there for "changes I've been
least qualified to have made." But at the end of the day my test cases passed
:upside_down_face: Take my experiences with as many or as few grains of salt as you'd
like. This also means that if you want to suggest other alternatives or otherwise teach me
something new, I'm all ears!

First, a little bit of history. Sorbet's parser was originally a part of the [TypedRuby]
project.[^typedruby]  In turn, TypedRuby sourced its parser by porting the grammar file in
the [whitequark parser] from [Racc] (a Yacc-like parser generator for Ruby) to [Bison] (a
Yacc-like parser generator for C/C++). Sorbet imported the source code of the TypedRuby
parser and continued to modify it over time as Ruby syntax evolved. The lexer uses [Ragel]
(also inherited from whitequark by way of TypedRuby) and tends to be quite stateful
compared to other lexers I've seen—a point which we'll come back to in future posts.

[^typedruby]:
  [TypedRuby] was an aspirational Ruby type checker implemented in Rust that predated
  Sorbet. It is now abandoned.

Importantly...

- Sorbet's parser does not use [Ripper], the parser built into the Ruby VM itself.

  Ripper is meant to be used as a library from Ruby code, not from C++ like Sorbet needs
  for performance.

  Okay technically that's a lie. The [rubyfmt] project manages to depend on Ripper from
  Rust by exposing it via Ruby's support for native (C) extensions. **But** doing that
  comes with [significant build complexity][configure-make], because it has the effect of
  basically importing Ruby's whole `configure && make` build step.

  Meanwhile it was super easy to import the TypedRuby parser as a self-contained unit with
  basically no questions asked (and remember: Sorbet predates rubyfmt). It's also nice to
  be free from upstream[^upstream] constraints: I can mess around in Sorbet's parser as
  much as I want and the only people I have to defend my choices to are my teammates, not
  the Ruby maintainers.

- Sorbet's parser does not use [tree-sitter].

  Tree-sitter is tool whose main goals are basically 100% aligned with Sorbet's needs in a
  parser: fast enough to run on every keystoke, robust enough to handle syntax errors, and
  native-code friendly. It would seem like a no-brainer for Sorbet to use.

  Unfortunately when I looked closely, it didn't actually pan out. I used the [tree-sitter
  playground] to test a bunch of syntax errors where I wanted to be able to respond to
  completion requests for to see what the parse result looked like. In some cases it
  worked okay, but for the cases I cared about the most (mostly those involving `x.`), the
  results weren't good enough. If I was going to have to manually hack on a parser to get
  it to do what I wanted, I figured I'd rather just stick with what Sorbet already had.

  On top of that tree-sitter is still pretty young, and almost everyone who is using
  tree-sitter right now is using it for two use cases: syntax highlighting, and code
  navigation. If the parse result generates the wrong thing (imagine there's a bug in the
  grammar file that no one else has reported yet), oh well, maybe the colors are wrong or
  the jump-to-def goes to the wrong place. In Sorbet, it would mean either reporting an
  error when there isn't one, or not reporting an error when there is one, both of which
  are particularly bad.

  Given that it was both (1) going to take extra hacks to get working instead of being a
  drop-in solution and (2) potentially trade Sorbet's mature parser for a less-mature
  parser, it didn't seem worth pursuing.

- Sorbet's parser is not hand-written with [recursive descent].

  Many people whose opinions I respect have told me that there's a reason why so many
  people hand-write their parsers: error recovery is easier when given the flexibility to
  bend the whole parser to your will.

  But there isn't an existing hand-written Ruby parser I could start from, and I didn't
  want to completely stall progress with a bug-for-bug rewrite when I already had some
  ideas for how to make the existing parser better. Basically this approach has the same
  tradeoffs as adopting tree-sitter (lots of work with too many unknowns).

[^upstream]:
  I should note that I'm not opposed to upstreaming the changes I've made to Sorbet's
  parser. Some of them intentionally break Ruby compatibility (in minor ways), and
  even the changes that don't would likely require effort to get them merged properly. If
  you find my changes and want to submit them upstream, please go ahead!

All of these claims about Sorbet's parser were true when I started, and they haven't
changed. You'll notice that in most cases the justification is "I don't have time to do
X" and not "doing X is wrong." My biggest constraint in improving the parser has been
making small, fast, iterative improvements. I wanted to be left with something to show
even if I had to stop working on the parser sooner than expected. It's possible that
someone with more time or more patience will want to revisit one of these approaches in
the future, and if you do I'd love to hear about it!

Anyways, that rules out the most common refrains from onlookers. But there was another,
more unconventional approach I considered and decided against: using [dead_end].
`dead_end` isn't a Ruby parser but rather a tool that hijacks Ruby's syntax error
reporting mechanism[^hijack] to improve the message for certain syntax errors.
Specifically, it'll try to show error messages in cases like this:

[^hijack]:
  It turns out, all ("all") you have to do is is monkey patch `require` to `rescue
  SyntaxError`. Thanks Ruby :slightly_smiling_face:

```{.ruby .numberLines .hl-4 .hl-8}
class A
  def foo
    # ... lots of code ...
  # ← dead_end error: missing `end` keyword

  def bar
  end
end # ← ruby default error: unexpected token "end of file"
```

Missing an `end` keyword is a super common class of Ruby syntax errors,[^curly] and
`dead_end` already works particularly well at reporting them, so it was tempting to
~~steal~~ reuse either the code or the ideas.

[^curly]:
  One of my biggest Ruby syntax gripes is that it isn't a curly brace language like C or
  JavaScript. Any sensibly editor will **immediately** insert the matching `}` after first
  typing `{`. But most Ruby editors will only insert the `end` matching some statement
  after a full line has been typed and `<Enter>` has been pressed, if anything. This means
  that unclosed `if`/`while`/`do`/`def`/`class` statements are **abundantly** common in
  Ruby, and this class of error (mismatched pairs) is trickier than the average error.

Early on I had decided not to use the code directly (it's written in Ruby, and I didn't
want to add a runtime dependency on Ruby to Sorbet). But in the end, I decided not to use
its recovery algorithm either.

The algorithm is [described in more detail here][dead_end-algo], but the tl;dr is that it
uses indentation to search for mismatched snippets, expanding and discarding lines from
the search frontier when it finds portions of a Ruby file that properly parse at a given
indentation level.

The problem with taking that idea verbatim is that the end result is basically just a set
of lines in the source file that contain the error. But knowing those lines, there's still
no parse result for those lines. For example:

```{.ruby .numberLines .hl-3}
def foo
  # ... code before ...
  if arbitrary_expression().
  # ... code after ...
end
```

`dead_end` could point to line 3 as the problem, but then I'd still have to parse that
line to be able to e.g. service a completion request after the `.`, which is _basically_
the situation we started with, because the parser would still be on the hook for the full
complexity of what that `arbitrary_expression()` could represent. So I put the `dead_end`
algorithm itself aside as well.

**But!** the general idea of using indentation to guide recovery proved out to be pretty
useful—most Ruby editors will auto-indent and -dedent correctly for most edits—and there
was another way to take advantage of it in Sorbet's parser, along with some other tricks.
The next few posts will discuss those tricks!

<p style="width: 50%; float: left; text-align: left;">
  [← Part 1: Why Recover from Syntax Errors][part1]
</p>
<p style="width: 50%; float: right; text-align: right;">
  [Part 3: Tools and Techniques for Debugging a (Bison) Parser →][part3]
</p>

<br>


[TypedRuby]: https://github.com/typedruby/typedruby
[whitequark parser]: https://github.com/whitequark/parser

[Racc]: https://rubygems.org/gems/racc
[Bison]: https://www.gnu.org/software/bison/
[Ragel]: http://www.colm.net/open-source/ragel/

[Ripper]: https://ruby-doc.org/stdlib-2.7.3/libdoc/ripper/rdoc/Ripper.html
[rubyfmt]: https://github.com/penelopezone/rubyfmt
[configure-make]: https://github.com/penelopezone/rubyfmt/blob/trunk/librubyfmt/build.rs

[tree-sitter]: https://tree-sitter.github.io/tree-sitter/
[tree-sitter playground]: https://tree-sitter.github.io/tree-sitter/playground

[recursive descent]: https://en.wikipedia.org/wiki/Recursive_descent_parser

[dead_end]: https://github.com/zombocom/dead_end
[dead_end-algo]: https://schneems.com/2020/12/01/squash-unexpectedend-errors-with-syntaxsearch/
