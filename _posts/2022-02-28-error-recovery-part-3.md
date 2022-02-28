---
# vim:tw=90
layout: post
title: "Parse Error Recovery in Sorbet: Part 3"
date: 2022-02-28T00:25:56-05:00
description: >
  This is the third post in a series about "things I've learned while making improvements
  to Sorbet's parser." Previously I discussed high level questions like why it's an
  important problem for Sorbet to solve and some approaches I decided not to take. This
  post switches gears to focus on specific tips and techniques I found useful while making
  parser changes.
math: false
categories: ['sorbet', 'parsing']
subtitle: "Tools and Techniques for Debugging a (Bison) Parser"
# author:
# author_url:
---

This is the third post in a series about "things I've learned while making improvements to
Sorbet's parser." Previously I discussed high level questions like why it's an important
problem for Sorbet to solve and some approaches I decided not to take. This post switches
gears to focus on specific tips and techniques I found useful while making parser changes.

<!-- more -->

- [Part 1: Why Recover from Syntax Errors][part1]
- [Part 2: What I Didn't Do][part2]
- **[Part 3: Tools and Techniques for Debugging a (Bison) Parser][part3]**
- (*coming soon*) Part 4: Bison's `error` Token
- (*coming soon*) Part 5: Backtracking, aka Lexer Hacks
- (*coming soon*) Part 6: Falling Back on Indentation, aka More Lexer Hacks

[part1]: /error-recovery-part-1/
[part2]: /error-recovery-part-2/
[part3]: /error-recovery-part-3/
[part4]: /error-recovery-part-4/
[part5]: /error-recovery-part-5/
[part6]: /error-recovery-part-6/

With that all out of the way, let's dive into the tips.

# Read the docs

Haha! You probably thought that by Googling for things you'd be able to find something
that lets you avoid reading the official docs. But it's boring for me to repeat everything
that's in the docs, and honestly the Bison and Ragel docs are rather comprehensive as far
as software documentation goes these days:

→ [Ragel User Guide](https://www.colm.net/files/ragel/ragel-guide-6.9.pdf)\
→ [Bison User Guide](https://www.gnu.org/software/bison/manual/bison.html)

But I will give you some tips for **how** to read the docs:

-   You ~always want the "HTML entirely on one web page" version of the Bison docs—it's
    way easier to ⌘F around one page.

-   Bison actually gets new, interesting features from version to version. Double check
    that the version of the docs you're reading actually match the version of Bison you're
    using. I haven't found an easy way to read old Bison docs online, so I usually just
    `grep` for things in the docs' sources:

    ```
    ❯ git clone https://github.com/akimd/bison
    ❯ git checkout v3.3.2
    ❯ grep -r 'error.*token' doc/
    doc/bison.texi:error.  If there is a @samp{..} token before the next
    doc/bison.texi:value of the error token is 256, unless you explicitly assigned 256
    ... many more results ...
    ```

-   I've found it valuable to actually take my time while reading the Bison docs. I've
    found a lot of things that turned out to be relevant later on because I took the time
    to read parts of the docs that didn't look immediately relevant.

But that's enough soapbox standing, now we return to regularly scheduled tips.

# Enable traces, and make them good

Before I started working on this project, I treated Sorbet's parser like a black box. In
the spirit of "[Computers can be understood]," the first thing I did was enable traces for
our parser. Easy enough:

- Define the [`parse.trace`] variable in the grammar
- Call [`set_debug_level`] on the generated parser

Here's [the PR in Sorbet][4985], which might help to make these two steps more concrete.

The trace output looks something like this:

```
❯ sorbet --trace-parser -e 'def foo; end'
Starting parse
Entering state 0
Reading a token: Next token is token "def" ()
Shifting token "def" ()
Entering state 4
Reading a token: Next token is token tIDENTIFIER ()
Shifting token tIDENTIFIER ()
Entering state 184

...
```

The output is somewhat useful as is, but it can be better. First, all the trailing `()` on
the "Next token is ..." lines are present because there aren't any `%printer`'s for those
tokens--we can easily get the trace to not only show that it read a `tIDENTIFIER` token,
but also what the name of that variable was. After adding one for `tIDENTIFIER` like this:

```
%printer { yyo << $$->view(); } tIDENTIFIER
```

The `$$->view();` bit calls the `view` method on Sorbet's token type, converting it to a string. Now our traces look better:

```
❯ sorbet --trace-parser -e 'def foo; end'
Starting parse
Entering state 0
Reading a token: Next token is token "def" ()
Shifting token "def" ()
Entering state 4
Reading a token: Next token is token tIDENTIFIER (foo)
Shifting token tIDENTIFIER (foo)
Entering state 184
Reading a token: Next token is token ";" ()
Reducing stack by rule 125 (line 1140):
   $1 = token tIDENTIFIER (foo)
-> $$ = nterm fname ()
...
```

So far I've been adding these `%printer`s only as I encounter the tokens that show up,
mostly because I'm too lazy to exhaustively define printers for all the tokens—Ruby has a
lot of tokens. You'll note that Bison even lets you register `%printer`s for non-terminals
(not pictured, but the same mechanism). You could use this to, like, print the currently
reduced AST for that non-terminal, or some other summary.

The next step is to actually understand what these traces mean, because it looks like
there's a lot of magic names and numbers, but there's a short cut for that.

# Diff traces for good and bad parses

This code is a syntax error in Ruby:

```ruby
def foo(x,); end
```

Bison has a fancy `error` token that we can use to recover from cases like this, but it's
hard to know where to add that `error` token into the grammar. Printing the trace file
would likely help us figure out where, but even when we're staring at the trace file it's
not entirely clear.

Luckily there's a short cut:

1.  Record a parser trace for the invalid parse.
2.  "Fix" the file so that it parses by only adding tokens, and record a trace for that
    parse.
    - This ensures that all the tokens present in the bad parse are also present in the
      good parse.
3.  `diff` (or `vimdiff`) the two traces, and add an error recovery rule to the place
    where the trace differs.

In our case, I want `def foo(x,); end` to parse as if the user had properly written two
arguments, so that I can record the fact that the user started to introduce a second
argument. I'll record a trace for the program `def foo(x, y); end`, and diff it. The diff
looks like this:

<figure class="left-align-caption">
```{.diff .numberLines .hl-30 .hl-31 .hl-32 .hl-33 .hl-34}
❯ sorbet --trace-parser -e 'def foo(x,); end' 2> trace-bad.txt;
  sorbet --trace-parser -e 'def foo(x, y); end' 2> trace-good.txt;
  diff -u trace-bad.txt trace-good.txt
--- trace-bad.txt       2022-01-16 14:40:51.168977798 -0800
+++ trace-good.txt      2022-01-16 14:40:51.728976581 -0800
@@ -53,45 +53,201 @@
 Next token is token "," ()
 Shifting token "," ()
 Entering state 752
+Reading a token: Next token is token tIDENTIFIER ()
+Shifting token tIDENTIFIER ()
+Entering state 541
+Reducing stack by rule 660 (line 3400):
+   $1 = token tIDENTIFIER ()
+-> $$ = nterm f_norm_arg ()
+Stack now 752 562 349 78 0
+Entering state 559
+Reducing stack by rule 661 (line 3408):
+   $1 = nterm f_norm_arg ()
+-> $$ = nterm f_arg_asgn ()
+Stack now 752 562 349 78 0
+Entering state 560
 Reading a token: Next token is token ")" ()
-Error: popping token "," ()
+Reducing stack by rule 662 (line 3414):
+   $1 = nterm f_arg_asgn ()
+-> $$ = nterm f_arg_item ()
+Stack now 752 562 349 78 0
+Entering state 901
+Reducing stack by rule 665 (line 3428):
+   $1 = nterm f_arg ()
+   $2 = token "," ()
+   $3 = nterm f_arg_item ()
+-> $$ = nterm f_arg ()
...
```
<figcaption>
  This example shows `diff -u` in the command line, but when I'm looking at these traces I
  almost exclusively use `vimdiff`, because it lets me expand surrounding context, search
  for keywords, etc. And it looks nicer.
</figcaption>
</figure>


Looking at the highlighted lines near the bottom, we see that eventually the good parse
was able to reduce `nterm f_arg` by combining `f_arg`, `","`, and `f_arg_item`. The trace
tells us that this happened in `rule 665 (line 2428)`. That line number is the actual
source line number in our `*.ypp` grammar file.

All we have to do is go to that line and add an error case, which is pretty easy:

```{.diff .numberLines .hl-11 .hl-12 .hl-13 .hl-14}
           f_arg: f_arg_item
                    {
                      $$ = driver.alloc.node_list($1);
                    }
                | f_arg tCOMMA f_arg_item
                    {
                      auto &list = $1;
                      list->emplace_back($3);
                      $$ = list;
                    }
+               | f_arg tCOMMA error
+                   {
+                     $$ = $1;
+                   }
```

And now the parser reports the error but continues to recover from the error:

```
❯ sorbet -p parse-tree-whitequark -e 'def foo(x,); end'
s(:def, :foo,
  s(:args,
    s(:arg, :x)), nil)
-e:1: unexpected token ")" https://srb.help/2001
     1 |def foo(x,); end
                  ^
Errors: 1
```

This technique of comparing the trace for "what it currently does" against "what I wish
it did" has been super useful, because it often shows exactly the point where the trace
diverged, along with the reason. In this example, the `f_arg_item` was never reduced, but
sometimes the difference will be something like "the lexer didn't read a token" or "the
lexer read a token, but because of the state the lexer was in, it was the wrong token."
Whatever the cause, comparing traces usually shows the problem.

This particular example also showed an example of using Bison's `error` token. I'll talk
more about what this `error` token means in the next post.

<p style="width: 50%; float: left; text-align: left;">
  [← Part 2: Why Recover from Syntax Errors][part2]
</p>
<p style="width: 50%; float: right; text-align: right;">
  (*coming soon*) Part 4: Bison's `error` Token →
</p>

<br>


[Computers can be understood]: https://blog.nelhage.com/post/computers-can-be-understood/
[`parse.trace`]: https://www.gnu.org/software/bison/manual/bison.html#Tracing
[`set_debug_level`]: https://www.gnu.org/software/bison/manual/bison.html#index-set_005fdebug_005flevel-on-parser
[4985]: https://github.com/sorbet/sorbet/pull/4985/files?w=1#diff-63fada7036ffcba42e6615c3b85615cb81d47aafbf88122a552a34fb799c06b5R17
