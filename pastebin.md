<!-- vim:tw=90
-->
Notably, Sorbet is the first project in this lineage of parsers to care excessively about
error recovery. Sorbet prizes editor integration highly, and if the parser produces no
parse result for an invalid Ruby file, no downstream editor functionality works (like
completion, jump to definition, and hover).

Now let's dive into the tips.


# Enable tracing, and make it good

Before I started working on this project, I treated Sorbet's parser like a black box. In
the spirit of "[Computers can be understood]," the first thing I did was enable traces for
our parser. Easy enough:

- Define the [`parse.trace`] variable in the grammar
- Call [`set_debug_level`] on the generated parser

Here's [the PR in Sorbet][4985].

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

The output is somewhat useful as is, but it can be better. First, all the `()` on the
"Next token is ..." lines means we haven't registered any `%printer`'s for our tokens--we
can easily get the trace to not only show that it read a `tIDENTIFIER` token, but also
what the name of that variable was. After adding one for `tIDENTIFIER` like this:

<figure>
```
%printer { yyo << $$->view(); } tIDENTIFIER
```
<figcaption>The `$$->view();` bit calls the `view` method on Sorbet's token type, which
converts it to a `std::string_view` suitable for printing.</figcaption>
</figure>

Now our traces look better:

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

So far I've been adding these `%printer`'s only as needed. You'll note that Bison even
lets you register them for non-terminals (not pictured, but the same mechanism).

The next step is to actually understand what these traces mean, but there's a short cut
for that.


# Compare traces for good and bad parses

This code is a syntax error in Ruby:

```ruby
def foo(x,); end
```

But this comes up all the time while people are typing in their editor, so let's recover
from it--we'll report the syntax error, but still produce a parse tree that sees the
methodd definition, rather than an empty parse tree.

The short cut to doing this:

1. Record a parser trace for the invalid parse
2. "Fix" the file so that it parses
3. Diff the two traces, and add an error recovery rule to the place where the trace
   differs.

In our case, I want `def foo(x,); end` to parse as if the user had properly written two
arguments, so that I can record the fact that the user started to introduce a second
argument. I'll record a trace for the program `def foo(x, y); end`, and diff it. The diff
looks like this:

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

Here we see that the error prevented `rule 665 (line 3428)` from firing, because it had
shifted `f_arg` and `","`, but then encountered `")"` which was an error. All we have to
do is go to that line and add an error case:

```{.diff .numberLines .hl-ll .hl-12 .hl-13 .hl-14}
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
                | f_arg tCOMMA error
                    {
                      $$ = $1;
                    }
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

This technique of comparing the trace output of "what it currently does" with "what I wish
it did" has been super useful.

# Understand Bison's error recovery algorithm

<!--
TODO(jez) Also worth noting that if you're using location information, the location of the
error token expands as it decides to throw things away (it's not just the location of the
lookahead token at the time a synatx error was encountered).
-->

There's a vague description of this algorithm [in the docs][Error-Recovery], but I found
that I had to make it more explicit before I could use it well. At a high level, this is
what Bison does:

- Encounter an error (i.e., it doesn't expected the current lookahead token).
- Report an error by calling the (user-defined) `parser::error` function.
  - This function is always called, and called even before attempting to shift the `error`
    token and recover from the error. This can be either a blessing (you know that adding
    `error` to a production rule will never prevent an error from being reported), or a
    curse (you don't get an easy way to customize the error message in context once an
    `error` rule is matched).
- Leave the lookahead token untouched, and immediately shift the `error` token.
- Check whether we can reduce. If we can't, *completely discard* the object on the stack
  immediately before the error token (i.e., whatever we had most recently shifted or
  reduced before encountering the syntax error).
  - If we can, reduce, and continue. Remember that the lookahead token will still be set
    to whatever it was when the error occurred.
  - If we can't, repeat. Keep discarding until we've matched a rule that consumed the
    `error` token or discarded everything, then continue reading new tokens.

It's conceptually very simple, which is convenient, but has a few gotchas:

- It's very easy to throw away important stuff. For example, Sorbet has a generic "attempt
to recover from anything" rule for `stmts`:

```
stmts: // nothing
        {
          $$ = driver.alloc.node_list();
        }
    | stmt
        {
          $$ = driver.alloc.node_list($1);
        }
    | stmts terms stmt
        {
          $1->emplace_back($3);
          $$ = $1;
        }
    | error
        {
          $$ = driver.alloc.node_list();
        }
```

This says that a list of statements is either empty, a single `stmt`, a `stmt` after a
list of `stmts` and any number of terminators (`:` or `\n`), or **any error**. But
consider how that interacts with this program:

```ruby
def foo
  1.times {
end
```

What happens here is that at the point where the error is encountered (the `end` token on
the third line), it will happily discard **all** previous objects, even the `def foo`,
before matching the `| error` rule. So even though we have an error recovery rule, in this
case, our parse is going to be empty anyways. Which bring us to our next tip.

# Using the `error` token well

I've found these tips for using Bison's `error` token useful, in light of how the error
recovery algorithm works:

-   Whenever possible, add as much preceding context to the production using the `error`
    token. Like in the example above, we added the `error` token up in the `f_arg:` rule
    so that we could write the rule like `| f_arg tCOMMA error`, instead of adding it to
    the rule for `f_norm_arg` with no preceding context, like `| error`.

    Adding the prefix has given me the best results for recovering from the error on my
    first attempted grammar edit without having to reason through conflicts, and also
    means that little to none of the already-parsed program has to be discarded.

-   Figure out what are the most common edits, and make every prefix of the stack along
    that edit have an `error` production. For example, consider inserting a new keyword
    arg:

    ```ruby
    foo(a, y: y) # contents before edit
    foo(a, x y: y)
    foo(a, x: y: y)
    foo(a, x: x y: y)
    foo(a, x: x, y: y) # edit finished
    ```

    Ideally there's an `error` production for every intermediate state here, because
    adding a keyword argument to a method call is common. Probably method calls and
    variable assignments will be the most commonly edited constructs in all languages.

# Try actually reading the generated parser

# The problem might be the lexer

- sorbet's lexer has states, sometimes will emit a `tNL`, sometimes it won't
- again: use trace diffs to figure out why it won't take a production rule you

# Take a program that parses, delete one token, make it parse

- This is very similar to how people make edits (renames, replaces)



[Computers can be understood]: https://blog.nelhage.com/post/computers-can-be-understood/
[`parse.trace`]: https://www.gnu.org/software/bison/manual/bison.html#Tracing
[`set_debug_level`]: https://www.gnu.org/software/bison/manual/bison.html#index-set_005fdebug_005flevel-on-parser
[4985]: https://github.com/sorbet/sorbet/pull/4985/files?w=1#diff-63fada7036ffcba42e6615c3b85615cb81d47aafbf88122a552a34fb799c06b5R17
[textual output]: https://www.gnu.org/software/bison/manual/bison.html#Understanding
[Error-Recovery]: https://www.gnu.org/software/bison/manual/bison.html#Error-Recovery


<!--

- Enable traces
- Make the traces good (printers for tokens)
- Read the traces to get a sense for how the error recovery algorithm works
- Look at the generated `txt` file to learn what the states mean
  - idea: show an annotated trace file in the blog post? (what all the numbers mean)
  - will also show you which states have conflicts
  - (rules in `[...]` are the conflicts, the one in `[...]` is not taken)
- Compare successful parses with unsuccessful parses (vimdiff)
- Go to the place where the two diverge, and add an error case
- Almost all the rules you add are going to end with `error`, but some might not
- Make special error nodes/error names
- You can use `@1`, ... to access the location information of the error token (you have to
  change the parser to thread this information through it)
- The error token's location will be set to the location of the lookahead token that
  caused the syntax error to be discovered.
- Rule of thumb (in my experience) for resolving conflicts is that I want as many tokens
  in from of the `error` token in a rule as possible
  - going to throw away less of the program, but also going to make it less likely to
    conflict
  - most of my conflicts come from attempting to put `| error [...]` in two adjacent
    productions.
- Figure out what are the most common edits, and make every incremental edit along that
  path recover. PRs can show you the kinds of edits people show up with, if you need a
  starting point--imagine someone typed out every character of a PR's diff serially.
- Probably method calls and variable assignments are the most important (that's where
  people are most likely to be editing)

- Have some sort of fallback rule
- Know that the fallback rule is going to conflict with some of the things you'll want
  to build.
- Midrule actions are real rules. Just give a name to the midrule, then use that rule in
  the place where you wanted to.
- Can do tricks to get better error messages too
- Note: yyerror is going to be called every time (you can check the generated code to see
  that yyerror is called well before the error token is even shifted)
- Sometimes you might want to change the lexer to make things easier to detect
- Rants about ruby (keyword method names, def/end instead of curly braces)
- Don't be afraid to read the the generated parser's source. One way to do this is to set
  a breakpoint on a line in your parser file. Another way is to grep for your actions'
  code in the generated file.

-->


