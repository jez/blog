---
layout: post
title: "Sorbet Does Not Have FixMe Comments"
date: "2020-02-11 23:18:40 -0800"
comments: false
share: false
categories: ['sorbet', 'ruby', 'types']
description: >
  Sorbet has no way to ignore an error on a specific line with a magic
  comment, which makes things simple.
strong_keywords: false
---

<p></p>

<!-- more -->

Sorbet has no way to ignore an error on a specific line with a magic
comment. This is different from all other gradual static type checkers I
know about:

- TypeScript: `// @ts-ignore`
- Flow: `// $FlowFixMe`
- Hack: `// HH_FIXME`
- MyPy: `# type: ignore`

When I first joined the team, I was skeptical. But having seen it play
out in practice, it's actually worked great.

Instead of ignore comments, Sorbet has `T.unsafe`, which accepts
anything and returns it unchanged (so for example `T.unsafe(3)`
evaluates to `3`). The trick is that it forces Sorbet to forget the
type of the input statically. This confers the power to silence most
errors. For example:

```ruby
1 + '1'            # error: Expected `Integer` but found `String`
T.unsafe(1) + '1'  # no error
```

<a href="https://sorbet.run/#%20%20%20%20%20%20%20%20%201%20%20%2B%20'1'%20%20%23%20error%3A%20Expected%20%60Integer%60%20but%20found%20%60String%60%0AT.unsafe(1)%20%2B%20'1'%20%20%23%20no%20error">→ View on sorbet.run</a>

In this example, Sorbet knows that calling `+` on an Integer with a
String would raise an exception at runtime, and so it reports a static
type error. But wrapping the `1` in a call to `T.unsafe` causes Sorbet
to think that the expression `T.unsafe(1)` has type `T.untyped`. Then,
like for all untyped code, Sorbet admits the addition.

All Sorbet-typed Ruby programs must grapple with `T.untyped`. Every
Sorbet user has to learn how it works and what the tradeoffs of using it
are. In particular, that `T.untyped` is viral. Given a variable that's
`T.untyped`, all method calls on that variable will also be untyped:

```ruby
# typed: true
extend T::Sig

sig {params(x: T.untyped).void}
def foo(x)
  y = x.even?
# ^ type: T.untyped
  z = !y
# ^ type: T.untyped
end
```

<a href="https://sorbet.run/#%23%20typed%3A%20true%0Aextend%20T%3A%3ASig%0A%0Asig%20%7Bparams(x%3A%20T.untyped).void%7D%0Adef%20foo(x)%0A%20%20y%20%3D%20x.even%3F%0A%23%20%5E%20type%3A%20T.untyped%0A%20%20z%20%3D%20!y%0A%23%20%5E%20type%3A%20T.untyped%0Aend">→ View on sorbet.run</a>

In this example `x` enters the method as `T.untyped`, so calling the
method `.even?` propagates the `T.untyped` to `y`. Then again because
`y` is untyped, calling[^calling] `!` on it propgates the `T.untyped` to
`z`. There are plenty of reasons to [both embrace and avoid][gradual]
`T.untyped` in a type system but the point is: Sorbet's type system
already has it.

[^calling]: Did you know that `!x` in Ruby is syntactic sugar for `x.!()`, which means that you can override `!` to make it do something else?

Re-using `T.untyped` as the way to silence errors plays nicely with
everything else in Sorbet:

- Hover and jump to definition become tools to track down the source of
  silenced errors.

- Errors are effectively silenced at the source of the error. There are
  no errors downstream that only show up because an error was silenced
  earlier.

- We plan to eventually build a tool to show which parts of a file are
  untyped (to see things like which methods don't have signatures). That
  tool will trivially take suppressed errors into account.

The [Sorbet docs][gradual] bill `T.untyped` as the way to "turn off the
type system." By reusing `T.untyped` to supress errors, silencing one
error means silencing them all, which is a win for simplicity.


[gradual]: https://sorbet.org/docs/gradual



<!-- vim:tw=72
-->
