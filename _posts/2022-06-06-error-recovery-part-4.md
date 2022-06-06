---
# vim:tw=90
layout: post
title: "Parse Error Recovery in Sorbet: Part 4"
date: 2022-06-06T01:56:49-04:00
description: >
  This is the fourth post in a series about things I've learned while making improvements
  to Sorbet's parser. With the last post, I talked about some tools and techniques that
  I've found useful while hacking on Sorbet's Bison-based parser. This post is going to
  continue that theme by explaining in a little more detail the primary tool Bison has for
  adding error recovery to a parser—the special `error` token.
math: false
categories: ['sorbet', 'parsing']
# subtitle:
# author:
# author_url:
---

This is the fourth post in a series about "things I've learned while making improvements
to Sorbet's parser." With the last post, I talked about some tools and techniques that
I've found useful while hacking on Sorbet's [Bison]-based parser. This post is going to
continue that theme by explaining in a little more detail the primary tool Bison has for
adding error recovery to a parser: the special `error` token.

<!-- more -->

You don't _really_ need to read the previous posts for this post to be useful, but if in
case you want to queue them up to read later, here's the list:

[Bison]: https://www.gnu.org/software/bison/

- [Part 1: Why Recover from Syntax Errors][part1]
- [Part 2: What I Didn't Do][part2]
- [Part 3: Tools and Techniques for Debugging a (Bison) Parser][part3]
- **[Part 4: Bison's `error` Token][part4]**
- (*coming soon*) Part 5: Backtracking, aka Lexer Hacks
- (*coming soon*) Part 6: Falling Back on Indentation, aka More Lexer Hacks

[part1]: /error-recovery-part-1/
[part2]: /error-recovery-part-2/
[part3]: /error-recovery-part-3/
[part4]: /error-recovery-part-4/
[part5]: /error-recovery-part-5/
[part6]: /error-recovery-part-6/

That being said, if you're also trying to hack on a Bison parser to make it recover from
errors, I hate to say it but this post is not going to be a substitute for the [official
docs on Error Recovery][bison-error]. You're going to want to spend some time skimming
that section of the docs if you haven't already.

\

Bison needs explicit annotations within a grammar to provide syntax error recovery. This
is in contrast with parser tools like [tree-sitter],[^tree-sitter] which automatically
generate the error recovery for for you. Concretely, Bison requires inserting special
`error` tokens in production rules that should participate in error recovery.

[^tree-sitter]:
  If you're curious, I've written some other with assorted [thoughts on tree-sitter].

To get the most out of Bison's error recovery mode, it's crucial to understand what it's
actually doing with those `error` tokens.

# Bison's error recovery algorithm

There's a vague description of the algorithm [in the docs][bison-error], but I found
that I had to make the algorithm more explicit before I could understand what was and
wasn't possible.

At a high level, this is what Bison does:

1.  It encounters an error. By which we mean: neither shifting the lookahead token nor
    reducing the current stack is a valid action given the current lookahead token).

1.  It reports the error by calling the (user-defined) `yyerror`[^yyerror] function.

    Importantly, this function is **always** called.[^happy] Even if a production rule
    eventually consumes the error token and successfully recovers from the parse error, an
    error will have been reported.

    Also note that it's impossible[^delay] to delay calling `yyerror` until it's clear
    that no production rule matched the `error` token, since the `yyerror` function is
    called even before attempting to **shift** the `error` token, less reduce a rule that
    uses it. For similar reasons, this makes it more complicated to allow the eventual
    error rule to provide extra context on the error message

1.  Next, Bison looks to see it can shift the `error` token, given what the current stack
    contents and parser state are. It leaves the current lookahead token untouched for the
    time being.

    If it can shift the `error` token, it does so. Bison has finished recovering from the
    syntax error. The parse continues, using the untouched lookahead token. If it shifted
    the lookahead token, another one is lexed as normal.

1.  If it **can't** shift the `error` token, Bison **completely discards** the object on
    the top of the stack.

    To make that clear, if the parser stack looked something like this:

    ```ruby
    # def foo
    #   x.
    # end

    stack = ['def', identifier, '\n', expression, '.']
    lookahead = 'end'
    ```

    and Bison found no matching error production rule, it would throw away the `'.'` token
    that it had already shifted onto the parser stack:

    ```ruby
    stack = ['def', identifier, '\n', expression]
    lookahead = 'end'
    ```

    and then loop back to the previous step, checking to see whether it's now possible to
    shift the `error` token. This process repeats until Bison has gobbled up the whole
    stack or some production rule consumes the error token.

1.  If Bison's [Location Tracking] feature is on (which allows using `@1`, `@2`,
    etc. in semantic actions to get the locations associated with components of the rule),
    it's worth knowing how the `error` token's location is set. Bison sets the error
    location to span from the last thing it discarded from the stack all the way to the
    lookahead token that induced the error. If it discarded nothing, then the range would
    just be the location of the lookahead token.

    Using the example above, if the `'.'` token was the only token Bison had to discard,
    the error token's location would be set to span from that `'.'` token all the way to
    the `'end'` lookahead token.

[^yyerror]:
  In C++ parsers, this is called `parser::error`.

[^happy]:
  Other parser generators, for example [Happy] for Haskell but do _not_ necessarily report
  an error when an `error` token is produced.

[^delay]:
  Sorbet gets around this limitation by appending parse errors to a temporary queue, only
  flushing them to the user once parsing has completed. Sorbet sometimes
  [mutates][replace_last_diag] the last element of the queue inside semantic actions to
  improve the error message with specific information about the parse failure.

Most Bison grammars have a catch all `| error` production somewhere, like this one in
Sorbet's parser:

<figure class="left-align-caption">
```{.yacc .numberLines .hl-4}
stmts: %empty { /* ... */ }
     | stmt { /* ... */ }
     | stmts newline stmt { /* ... */ }
     | error { /* ... */ }
```
<figcaption>
Snippet of Sorbet's parser. [View on GitHub →](https://github.com/sorbet/sorbet/blob/e961ac4ee7c4e425e5b5f14a03b7ce20c3bdbbc2/parser/parser/cc/grammars/typedruby.ypp#L653-L657)
</figcaption>
</figure>

The nice thing about a rule like this is that it provides coarse grained error recovery
at a high level without requiring special cases for every production in the grammar. It
works because no matter what happens to be on the stack, it'll always eventually match (as
long as we're in the parser state corresponding to `stmts`) because eventually Bison will
have discarded the entire stack.

It'll definitely throw away a lot of stuff, but at least it'll let the parse continue
instead of failing to produce any parse result. For example, if there was no parse error
further down in the file, and the error occurred near the top, this rule gets us lots of
error recovery for little work. But yeah, it's not great to throw that much stuff away.

We're going to want to put more `error` tokens in more targeted places. For that, I've
come up with a handful of strategies to make the most of Bison's error recovery.

# Figure out the most common edit paths

Even though Bison requires a lot of `error` annotations to get good parse results, you can
get good bang for your buck by figuring out the most common edit paths. For example,
here's every intermediate edit when the user adds a keyword argument to a Ruby method:

```ruby
foo(a, x: x) # contents before edit
foo(a, x: x,)
foo(a, x: x, y)
foo(a, x: x, y:)
foo(a, x: x, y: y) # edit finished
```

Ideally there's an `error` production for every intermediate state, because adding a
keyword argument to a method call is common. On the other hand, you can likely get away
not adding rules for uncommon syntax errors.

If you want, you can take the guesswork out of what's common and what's not by measuring,
assuming you have a corpus of syntax errors you can sample from.[^corpus] The
semi-automated approach to measurement, which is what I've personally used: when there's a
syntax error and the parse result is "bad" according to some heuristic (like: the parse is
completely empty, or there was a partial parse result but it was too bad to find any
completion suggestions at the user's cursor), log the bad source buffer to a file, and
then go triage the logged files, fixing the most common errors first.

[^corpus]:
  For example, we gather usage metrics from every Sorbet user at Stripe.

The annoying part about that approach is the manual triage work of opening up the logged
buffers, identifying which part of the file had the parse error, and blaming it to some
section of the parser. An idea I've had (but not implemented) for a more automatic
approach: when there's a syntax error that's never recovered (or that's handled by some
"catch all" production rule), log the lookahead token and parser state where the error
happened. Cross reference parser states with what's in the [textual report] on the parser
to get approximate line numbers in the grammar that need to be updated. States that show
up the most commonly are the ones in need of dedicated `error` rules.

# The `error` token is usually last

With the most common edit paths in hand, I've usually had the most success by following
two tips for crafting the error rules.

1.  Put the `error` token as the very last token in the production rule. It can be
    tempting to try writing rules like this, where the `error` token is followed by some
    other stuff:

    ```yacc
      | args ',' arg { /* ... */ }
      | args ',' error arg  { /* ... */ }
    ```

    Sometimes this works, but in my experience, it's much easier to reason about conflicts
    when the `error` token is the last token in a rule.

2.  Put the `error` token **only** after terminals. There's almost never conflicts in the
    grammar when putting the `error` token after a `','` or `'='` token, but there usually
    are when putting it after something like an `args` non-terminal.

    Intuitively this makes sense, because the `args` production itself probably has a
    bunch of rules that have consume an `error` token at the end, causing the conflicts.
    The non-terminal might even have a catch-all `| error` rule.

In situations where I haven't been able to trivially follow these rules, I've usually been
able to go into the preceding non-terminal rule (like `args`) and sprinkle `error` tokens
judiciously inside _that_ rule to allow following these rules.

Unfortunately, there have definitely been times where that hasn't worked, which will be
the topic of a future post.
<!-- TODO(jez) Link to the indentation post here, when written -->

# Consider using `yyclearin`

After recovering from a parse error using the `error` token, the lookahead token will
still be set to whatever it was that caused the error to happen in the first place.

If for whatever reason you think that attempting to continue the parse with that token
would just screw things up again, you can use the `yyclearin` macro[^yyclearin] to clear
out the lookahead token, which will cause Bison to request another token from the lexer.

[^yyclearin]:
  In the C++ skeleton, this is available using `yyla.clear()` instead.

We're not currently using this in Sorbet because I've replaced most places where it might
have been useful with some even more powerful techniques (discussed in a future part), but
I figured I may as well mention it.
<!-- TODO(jez) Link to part 5 lexer hacks here -->

# Invent a special AST node for errors

Consider this parse error:

```ruby
def foo
  x =
end
```

The rule for parsing an assignment with no error is looks like this, and produces an
`assign` node in the AST:

<figure class="left-align-caption">
```{.yacc .numberLines}
arg: lhs '=' arg_rhs
       {
         $$ = driver.build.assign(self, $1, $2, $3);
       }
   | ...
```
<figcaption>
Snippet of Sorbet's parser. [View on GitHub →](https://github.com/sorbet/sorbet/blob/e961ac4ee7c4e425e5b5f14a03b7ce20c3bdbbc2/parser/parser/cc/grammars/typedruby.ypp#L1285-L1288)
</figcaption>
</figure>

To handle the error case, we still have the `lhs` and the `'='`, but we don't have the
`arg_rhs`. The parser will detect that `'end'` is not a valid `arg_rhs`, and shift the
`error` token for us to recognize:

```{.yacc .numberLines .hl-5 .hl-7}
arg: lhs '=' arg_rhs
       {
         $$ = driver.build.assign(self, $1, $2, $3);
       }
   | lhs '=' error
       {
         $$ = driver.build.assign(self, $1, $2, /* ... ? ... */);
       }
   | ...
```

It's unclear what to use in place of `$3`, because `error` doesn't have an associated
semantic value. To fill the void, we can invent a special AST `error_node`
type.[^error_node]

<figure class="left-align-caption">
```{.yacc .numberLines .hl-7 .hl-8}
arg: lhs '=' arg_rhs
       {
         $$ = driver.build.assign(self, $1, $2, $3);
       }
   | lhs '=' error
       {
         auto enode = driver.build.error_node(self, @2.endPos(), @3.endPos());
         $$ = driver.build.assign(self, $1, $2, enode);
       }
   | ...
```
<figcaption>
Snippet of Sorbet's parser. [View on GitHub →](https://github.com/sorbet/sorbet/blob/e961ac4ee7c4e425e5b5f14a03b7ce20c3bdbbc2/parser/parser/cc/grammars/typedruby.ypp#L1289-L1303)
</figcaption>
</figure>

[^error_node]:
  Slight fib; Sorbet actually creates a [constant literal node] with a magic name for
  backwards compatibility reasons.\
  \
  "What's up with that `endPos` stuff?"\
  There's some discussion in the full source on GitHub.

This special AST node allows phases downstream of the parser to pretend the parse
succeeded. In particular, it's easy to detect where the syntax error occurred when
responding to completion requests (which is important, because in the above example, the
syntax error is also where the user's cursor is).

# Read the generated parser's source

To close, I'd like to point out that everything in this post that I didn't find in the
official docs, I taught myself by browsing the source code generated by Bison. Despite
being generated, it's actually pretty well commented, and with a bit of elbow grease you
might even be able to get your IDE to let you use jump to def in it.

Some nice things about browsing the source:

- It's never out of sync with the version of Bison you're using (unlike the official docs,
  which only track the latest version).

- You can see exactly what happens and in what order. For example, reading the source is
  how I convinced a colleague that no, using `error` productions did not mean we would be
  preventing errors from being reported. It was faster to read the source than attempt to
  find whether the docs mentioned this.

- You can see what fun, undocumented APIs are actually available to you. For example, the
  docs talk about `yylval` and `yylloc`, which are supposed to store the semantic value
  and location of the lookahead token. But in the C++ skeleton, these things have been
  renamed (without documentation) to `yyla.value` and `yyla.location`, respectively.

Reading the generated parser's source code reinforced my understanding of Bison's parsing
algorithm and made it easier to debug when things went wrong.

All this being said, I've run into plenty of limitations when attempting to improve
Sorbet's parser. In the next post, I'll explain one such example, why using `error` tokens
alone wasn't enough, and how I tweaked Sorbet's lexer to aid the parser in error recovery.

<p style="width: 50%; float: left; text-align: left;">
  [← Part 3: Tools and Techniques for Debugging a (Bison) Parser][part3]
</p>
<p style="width: 50%; float: right; text-align: right;">
  (*coming soon*) Part 5: Backtracking, aka Lexer Hacks →
</p>

<br>

[bison-error]: https://www.gnu.org/software/bison/manual/bison.html#Error-Recovery
[Location Tracking]: https://www.gnu.org/software/bison/manual/bison.html#Tracking-Locations
[tree-sitter]: https://tree-sitter.github.io/tree-sitter/
[thoughts on tree-sitter]: /categories/#tree-sitter
[Happy]: https://www.haskell.org/happy/
[replace_last_diag]: https://github.com/sorbet/sorbet/blob/e961ac4ee7c4e425e5b5f14a03b7ce20c3bdbbc2/parser/parser/cc/grammars/typedruby.ypp#L1976-L1981
[constant literal node]: https://github.com/sorbet/sorbet/blob/e961ac4ee7c4e425e5b5f14a03b7ce20c3bdbbc2/parser/Builder.cc#L911-L913
[textual report]: https://www.gnu.org/software/bison/manual/bison.html#Understanding
