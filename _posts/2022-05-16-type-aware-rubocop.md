---
# vim:tw=90
layout: post
title: "What would a type-aware Rubocop look like?"
date: 2022-05-16T16:17:20-04:00
description:
  From time to time, someone asks, "Would Sorbet ever allow defining some sort of
  type-aware lint rules?" My answer has usually been "no," for a couple of reasons.
math: false
categories: ['sorbet', 'ruby', 'rubocop']
# subtitle:
# author:
# author_url:
---

_This post represents my opinions at a point in time. It's not necessarily the views of my
team or my employer._

From time to time, someone asks, "Would [Sorbet] ever allow defining some sort of type-aware
lint rules?" The answer has usually been "no," for a couple of reasons.

[Sorbet]: https://sorbet.org

<!-- more -->

The biggest open question is that it's not 100% clear what use cases people have in mind.
Most commonly people imagine "the full [Rubocop] API, but with types," but this is
underspecified, in my opinion.

[Rubocop]: https://rubocop.org/

### Should every AST node (i.e., every expression) have a type associated with it?

This would be particularly hard to support, because Sorbet aggressively simplifies the
AST from the start to the end of its pipeline. The Rubocop AST has something like 100
node types. Sorbet immediately simplifies this into an AST that only has 30 or so node
types, then subsequently keeps refining the AST until it only has about 15. The thing
Sorbet type checks looks nothing like the AST that you'd want if you were trying to write
a linter, because so much of it has been desugared, rewritten, or simplified.

Then finally right before type checking, Sorbet actually abandons the (tree-based) AST,
preferring to use a **control flow graph** (CFG) for type checking! A CFG is no longer
tree-based[^graph], which breaks a lot of the assumptions people make about what's
easy and hard to build in a linter rule.

[^graph]:
  It's a graph, where nodes are basic blocks and edges are control flow jumps between
  those blocks.

Because Sorbet type checks a CFG only, there's no tree-based structure inside Sorbet that
has types. _Maybe_ it's possible to take the type-annotated CFG and use it to reconstruct
some sort of typed AST, but that sounds brittle and error prone.

And finally, in the CFG Sorbet doesn't associate types with expressions, only types with
variables! This works because the act of building a CFG assigns all intermediate
expressions' results to a variable and then only dealing with variables from then on.

### Maybe types for just variables is enough?

This would likely be somewhat easier to implement, because Sorbet already does maintain
environments mapping variables to their types.

However, these data structures are expensive to maintain and therefore not long-lived.[^lsp]
Unlike Sorbet's symbol table, which exists indefinitely after creation, the environments
that track variable types only last as long as is required to type check a single
method.

[^lsp]:
  Sorbet's LSP editor integration gets around this by re-typechecking an entire method
  every time the user hovers over a variable. When these hover requests come as
  (infrequent) requests from the user, this is fine because Sorbet is already initialized.
  Powering a linter this way would either require that the Sorbet server be
  initialized for variable type every request (crazy slow), or somehow kept around
  persistently (brittle).

Maybe there could be an API like "please give me the type of the variable with this name,"
but again this would be tricky, because chances are the lint rule author wants to build
the lint rule on some tree-based data structure, and Sorbet only has the CFG. So there
would additionally need to be some mapping between environments (basic blocks) and AST
variable nodes, which again sounds pretty tricky and likely to break some assumptions.

### Even if this "give me the type of a variable" API works, is it enough?

Knowing the type of a variable on its own isn't very useful. The most common questions you
want ask of a type are:

1.  Is is this type a subtype of this other type?
1.  If a method with a given name is called on a receiver of this type, what are the
    _list_ of methods that would be dispatched to? (It's a list because the receiver could
    be a union type.)

The answer to (1) requires having the entire symbol table on hand (lots of memory). The
answer to (2) is subtle and complicated—Sorbet spends [about 4,000 lines of
code][calls.cc] answering it—and _also_ requires having the symbol table on hand.

[calls.cc]: https://github.com/sorbet/sorbet/blob/master/core/types/calls.cc

So it's probably not enough to just, e.g., return some JSON representation of one of
Sorbet's types. It'd also require having some structured representation of Sorbet's symbol
table, which brings us to our next question:

### Rubocop + types, or Sorbet + linter?

So far I've kind of assumed that we want to start with an existing linter (Rubocop) and
just add types. But what we've seen so far is that the things we'd need to get types into
Rubocop basically amount to exporting almost all of Sorbet's internal data structures.

Sorbet's internal data structures change all the time as we fix bugs, add features, and
refactor things. Having to commit to a stable API for every internal data structure
mentioned above would slow down how quickly we can improve the rest of Sorbet.

So maybe instead of exporting an API that Rubocop could use, we should build a linter into
Sorbet? This just has different tradeoffs:

- Sorbet has to reinvent the wheel on linter APIs (e.g., are lint rules specified in Ruby
  code with some new API? Does it attempt to copy as much of Rubocop's API as possible?
  What happens when there are papercut differences between what Sorbet's linter allows and
  what Rubocop does?)

- How are rules distributed? Are the rules written in Ruby, and Sorbet runs the Ruby code
  with some sort of FFI to expose the internal data structures? Does Sorbet embed some
  other scripting language for writing rules? Do people write rules as shared objects
  which Sorbet dynamically loads, akin to Ruby native extensions? Are the rules committed
  directly into the Sorbet repo, like how custom DSL and rewriter passes are right now?

### ... what do people actually want this for?

Whenever someone asks for a type-aware linter, here are a sampling of the answers given
when I ask, "What are you really trying to do?"

1.  "Ban calling `to_s` on `nil`, because I just spent half an hour tracking down a bug
    where I had a `T.nilable(Symbol)` that I called `to_s` on and got the wrong answer."

1.  "Update the [Performance/InefficientHashSearch] rule to only act on `Hash` values. Not
    all calls like `xs.values.include?` can be safely rewritten to `xs.value?`."

1.  "Do type-aware codemods, for example change all calls to `x.merchant_` to something
    like `ClassOfX.get_merchant(x.id)`"

1.  "Enforce that all methods returning `T::Boolean` have names ending in `?`"

[Performance/InefficientHashSearch]: https://docs.rubocop.org/rubocop-performance/cops_performance.html#performanceinefficienthashsearch

It's not clear that "just" building a type-aware linter necessarily solves these problems.

Doing (1) is hard—should we allow `Object#to_s`? You could still accidentally call `to_s` on
something that's `nil` inside a method that accepts `Object` if you do. Also there are
sometimes valid cases to call `to_s` on `nil` that no type system will help you discover!
This feature seems similar to the `#poison` pragma in C and C++, but there the language
makes it easier because `#include`'ed files are explicitly ordered, and it's easy to say
"after this point, the identifier is poisoned." (Also I'm not even sure how `#poison`
works with methods, not just C functions, where things like inheritance become a problem.)

Doing (2) relies on that hard feature we chatted about above: types for arbitrary
expressions, not just variables. If we don't have types for arbitrary expressions,
detecting this case in a cop requires essentially re-inventing Sorbet's inference
algorithm: `input.map {...}.filter {...}.values.include?`. We mentioned the difficulty in
exposing types for arbitrary expressions above.

The situation for (3) is something I can really relate to, as there are a lot of cases
where I can imagine this being useful. But rather than build this as a lint rule, we've
historically wanted to build these as IDE-mode code actions: the API is much more
constrained (no internal data structures needed) and the IDE already has the type
information in memory. Sorbet supports a limited number of refactorings now, but mostly
because we haven't spent time on it. It's reasonable to assume we'll build many more
refactorings in the future.

And finally, things like (4) can _already_ be done in Rubocop. It's slightly more annoying
(you have to write the code to parse Sorbet signature annotations manually) but Sorbet
signature annotations are very stable. Their syntax changes infrequently, and when it
does, it's usually minor and/or backwards compatible changes.

### ... is there anything like this in another language?

Here's one of Sorbet's explicit design principles:

> 3.  As simple as possible, but powerful enough
>
>     Overall, we are not strong believers in super-complex type systems. They have their
>     place, and we need a fair amount of expressive power to model (enough) real Ruby
>     code, but all else being equal we want to be simpler. We believe that such a system
>     scales better, and—most importantly—is easier for our users to learn & understand.
>
> — [Sorbet user-facing design principles](https://github.com/sorbet/sorbet/#sorbet-user-facing-design-principles)

Another way to read this is, "we let other people blaze trails, and then copy their good
ideas."

~~This question comes up often enough that it makes me want to imagine that some sort of
similar tool exists for other dynamically typed languages? But as far as I'm aware,
no sort of type-aware linter exists for TypeScript, Flow, or Mypy.[^comp] Not having any
sort of frame of reference makes it hard to gauge expectations people have when asking for
a tool like this.~~

[^comp]: ~~If you know of a comparable tool, please do share!~~

**Update, 2022-05-18**[^steved] There _are_ type-aware static analysis tools for C# and
TypeScript. Both languages were designed by the
[same person](https://en.wikipedia.org/wiki/Anders_Hejlsberg), so maybe this isn't
surprising. Unfortunately for Sorbet, they were architected to support static analysis
tooling
[from the
beginning](https://en.wikipedia.org/wiki/Roslyn_%28compiler%29#:~:text=Roslyn%20was%20designed%20with%20that%20intent%20from%20the%20beginning.).
Sorbet's current architecture was instead designed for batch type checking performance on
large monorepos,[^perf] and IDE support was grafted on later. Exposing hackable APIs has
so far not been considered.

[^steved]:
  Thanks to Steve Dignam for pointing out that not only does C# have static
  analysis APIs, but that TypeScript does as well, along with an ecosystem of type-aware
  lint rules.

[^perf]:
  All things considered, it's actually quite good at this.

For example, TypeScript offers a [compiler API][tsc-api], which is then used by the
TypeScript ESLint project, which allows defining [custom type-aware lint rules]. What can
we learn from this project?

[tsc-api]: https://github.com/microsoft/TypeScript/wiki/Using-the-Compiler-API
[custom type-aware lint rules]: https://typescript-eslint.io/docs/development/custom-rules#type-checking

- The TypeScript compiler API does not have any sort of backwards compatibility guarantee,
  so breaking changes are published from time to time.
- It appears that all TypeScript functionality can be accessed behind the API, including
  instantiating a stateful object representing the type checker, running the type checker
  end-to-end on a project, spawning an LSP server, etc.
- The way custom lint rules are written is by converting between ESLint's AST node type
  and TypeScript's AST node type. The TypeScript compiler APIs then allow asking for the
  type of an AST (i.e., expression). I haven't confirmed, but this leads me to believe
  that TypeScript itself is doing typechecking on the AST (maybe with some auxiliary
  structures to track control flow), not on a CFG like Sorbet, which makes it easier to
  present the kind of API that makes sense in a lint rule.

It's interesting to [browse the rules that require type information][requires-type-info]
to get a sense for what's possible. Things like `strict-boolean-expressions` and
`no-floating-promises` are examples of non-trivial lints using type information.

[requires-type-info]: https://cs.github.com/typescript-eslint/typescript-eslint?q=%22requiresTypeChecking%3A+true%22

I have spent very limited time looking into how things work exactly, so it's possible I'm
misrepresenting the ideas. In any case, I personally still draw the same conclusion:
clearly people in the TypeScript community derive value from building type-aware lint
rules, and TypeScript is well-architected to enable this. As mentioned in previous
sections, Sorbet's current architecture does not present the same conveniences.

### Competing priorities tend to win out

When attempting to build this feature, we'd of course have to judge the cost of what we'd
have to give up.

Overwhelmingly, the requests people have about Sorbet are:

- Please fix shape and tuple types.
- Please fix generics (classes and methods).
- Please make Sorbet work faster on large codebases, especially in IDE mode.
- Please build more refactoring tools. If IntelliJ can do it, I'd like Sorbet to do it too.

So far, these requests have taken priority over greenfield projects, including things like
a type-aware linter.

### "Maybe in the future..."

Those are my current thoughts on the topic. Obviously, a lot of these reasons are just "it's
hard," and maybe for someone else those things would be easy. Others are just selfish,
"it's convenient for us to not have to think about compatibility," and so they're easy to
disagree with. Some of them are, "there's no clear answer to this question," and sometimes
you can wave those away by just picking _any_ answer and living with it, rather than
searching for the best.

So while I don't think that Sorbet would _never_ get some sort of type-aware linter, so
far there are many factors that present a pretty high barrier to building something like
this. Hopefully this post sheds some light on why a type-aware linter for Sorbet does not
currently exist.





