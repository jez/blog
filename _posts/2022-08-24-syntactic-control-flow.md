---
# vim:tw=90
layout: post
title: "Control Flow in Sorbet is Syntactic"
date: 2022-08-24T17:30:43-04:00
description:
  An exploration of why Sorbet lets control flow affect variables' types, but not methods'
  types.
math: false
categories: ['ruby', 'sorbet', 'types']
# subtitle:
# author:
# author_url:
---

People always ask me, "Why does Sorbet think this is nil? I just checked that it's not!"
So much so, that it's at the very top of the [Sorbet FAQ](https://sorbet.org/docs/faq)

That doc answers what is happening and what to do to fix it, but doesn't really answer why
its like that. A common follow up question looks something like this:

> Having to use local variables as mentioned in Sorbet's [limitations of
> flow-sensitivity](https://sorbet.org/docs/flow-sensitive#limitations-of-flow-sensitivity)
> docs is annoying. Idiomatic Ruby doesn't use local variables nearly as much as Sorbet
> requires. What gives?

**TL;DR**: Sorbet's type inference algorithm requires being given a fixed data structure
modeling control flow inside a method. Type inference doesn't get to change that structure,
so the things Sorbet learns while from inference don't retroactively change Sorbet's view
of control flow. (This is in line with the other popular type systems for dynamically
typed languages.) As a result control flow must be a function of local syntax alone
(variables), not global nor semantic information (methods).

But that's packing a lot in at once, so let's take a step back.

In this post whenever I say type inference I basically mean assigning types to variables,
and using the types of variables to resolve calls to methods. Type inference in Sorbet
needs two things:

- A symbol table, which maps names to global program definitions (like classes and
  methods, and their types). Sorbet spends a ton of time building a symbol table
  representing an entire codebase before it ever starts running type inference.

- A control flow graph, which is a data structure that models the flow of control through
  a single method. Sorbet builds these graphs on the fly right before running type
  inference.

Since type inference requires the control flow graph, clearly building the control flow
graph can't require type inference. Instead, it has to build a control flow graph using
only the method's abstract syntax tree (or AST). Since all Sorbet has is an AST, the
control flow only reflects syntax-only observations, like "these two variables are the
same" and "an if condition branches on the value of this variable." Sorbet can draw these
observations exclusively from the syntactic structure of the current method, with no need
to consult the symbol table, let alone run inference.

This brings us to our central conflict: knowing which method (or methods!) a given call
site resolves to is **not** a syntactic property. Consider this snippet:

```ruby
if [true, false].sample
  x = 0
else
  x = nil
end

x.even?
```

The meaning of `x.even?` depends on the type of `x`, which depends on the earlier control
flow in the method. That means that if a program branches on a **method return value**,
Sorbet cannot draw any interesting observations about control flow.

This gets to be a problem for methods whose meaning involves some claim like, "I always
return the same thing every time I'm called." Sorbet can't know whether `x.foo` refers to
one of those constant methods or a method that returns a random number every time, so it
has to assume the worst.

Here's a pathological example:

<figure class="left-align-caption">

```{.ruby .numberLines .hl-25 .hl-26 .hl-27}
class FooIsAttr
  sig {returns(T.nilable(Integer))}
  attr_accessor :foo
end

class FooIsMethod
  sig {returns(T.nilable(Integer))}
  def foo
    # Returns something different every call
    [0, nil].sample
  end
end

sig {params(x: Integer).void}
def takes_integer(x); end

# Have to run inference to get type of `x`
# (running inference requires control flow)
if [true, false].sample
  x = FooIsAttr.new
else
  x = FooIsMethod.new
end

# x.foo returns the same thing only if x is `FooIsAttr`
if x.foo
  takes_integer(x.foo) # error
end
```

<figcaption>
  [→ View on sorbet.run](https://sorbet.run/#%23%20typed%3A%20true%0Aclass%20Module%3B%20include%20T%3A%3ASig%3B%20end%0Aextend%20T%3A%3ASig%0A%0Aclass%20FooIsAttr%0A%20%20sig%20%7Breturns%28T.nilable%28Integer%29%29%7D%0A%20%20attr_accessor%20%3Afoo%0Aend%0A%0Aclass%20FooIsMethod%0A%20%20sig%20%7Breturns%28T.nilable%28Integer%29%29%7D%0A%20%20def%20foo%0A%20%20%20%20%23%20Returns%20something%20different%20every%20call%0A%20%20%20%20%5B0%2C%20nil%5D.sample%0A%20%20end%0Aend%0A%0Asig%20%7Bparams%28x%3A%20Integer%29.void%7D%0Adef%20takes_integer%28x%29%3B%20end%0A%0A%23%20Have%20to%20run%20inference%20to%20get%20type%20of%20%60x%60%0A%23%20%28running%20inference%20requires%20control%20flow%29%0Aif%20%5Btrue%2C%20false%5D.sample%0A%20%20x%20%3D%20FooIsAttr.new%0Aelse%0A%20%20x%20%3D%20FooIsMethod.new%0Aend%0A%0A%23%20x.foo%20returns%20the%20same%20thing%20only%20if%20x%20is%20%60FooIsAttr%60%0Aif%20x.foo%0A%20%20takes_integer%28x.foo%29%20%23%20error%0Aend)
</figcaption>

</figure>

Note the two calls to `x.foo` at the very end of the snippet:

- Knowing whether the second call to `x.foo` is non-nil requires knowing whether `x.foo`
  returns the same thing across subsequent calls.
- Knowing *that* requires knowing whether `foo` refers to an `attr_accessor` method or
  some other method.
- Knowing *that* requires knowing the type of `x`.
- Knowing *that* requires understanding the control flow in the method.
- So we can't make understanding the control flow in the method require knowing whether
  the second call to `x.foo` returns the same thing.
  - But we *can* make it require knowing whether a variable has been assigned to between
    two variable accesses.

# Properties and attributes in other languages

Unfortunately, this all means that Sorbet can only track control flow-sensitive types on
variables, not methods. This is the exact same limitation that other popular gradual type
checkers **except** for one difference: both JavaScript and Python make a **syntactic**
distinction between method calls (which have parentheses) versus property/attribute access
(which don't):

```ruby
x.foo   # <- syntactically a property (JS) or attribute (Python)
x.foo() # <- syntactically a method call
```

In Ruby, **both** `x.foo` and `x.foo()` correspond to method calls,[^methods] so Sorbet
models them as such. But in TypeScript, Flow, and Mypy,[^others] that small, syntactic
difference is enough to allow treating properties and attributes different from methods.

[^methods]:
  This is true even if `foo` was defined with `attr_reader :foo`!

[^others]:
  And maybe other control-flow sensitive type systems, too. Feel free to send me more
  examples.

[→ View example in TypeScript
Playground](https://www.typescriptlang.org/play?#code/MYGwhgzhAECC0G8BQ1oQPYFsCmAFATugA7b4AuAngFzQB2ArpgEanQA+09tAJtgGYBLWtm4BuFGizYAstjIALdNwAUAShoNmrDl16Dh3RNHxz6+WqOgBfJDaR8uwMgPS1owLEXplssNTXhkVBMyMzdhAHc4NXEbB1onFzcyMABrbAgAOUYWfGUADw0c0lVECQ9aDBBsADoQdABzAtVYpHtHZ1dobHywTCJqgEZlMADSoOgBPmgRmowcAmJSSnGJVBT0rOK8sDmpRZJyChaJG3W0jOytHb2FwkOV1vaEzrcevoHsACY1MtQpmYefreXxqW54e7LY5-VDQDaXbbKIFeHx+VTgg5Qk6oM5wi5ba5IzwgtEYyFHE52eKJLrvfrVADMIzGMIBs3mMjkihUqlWsLxmyuuXZUlkCiUamx1gk8IJwt2HLF3MlsSAA)\
[→ View example in Try
Flow](https://flow.org/try/#0PQKgBAAgZgNg9gdzCYAoVBjGBDAzrsAQTAG9Uwxc4BbAUwAUAnOAB1sYBcBPALjAH4AdgFdqAI3YBucpRq0AsrQ4ALOABMAFAEo+Q0RMakAvqhOoowwRg4BLOILAYaLYR1qFtfYmQqMlwxgdBWiQPLWkTCytbezAObABrWlwAOX12DQAPPhFxdi1SGSdBKhhaADp4AHMs8NN0KOs7B1pM7GoWMoBGDWwvAp8wGygwXvKqOiZWdm4BmQp4pNT0xjGJhmY2Ti46ihMFxOS0vNXscbkprdmIhssm2Nb2ztoAJm1CimHRpw7Xd21zpNNjMdh8KHFDssThofi43GFARtpttdmB9hClscDDDnH8EetLiC6mZGjEWm0OmUAMy9fpgr5rOSKFTqbRzcEYo4rRl0ZmqTRaVHoxZc6FndZ81mCiJAA)\
[→ View example in mypy
Playground](https://mypy-play.net/?mypy=latest&python=3.10&flags=strict&gist=3e149c861a4f10dc474fd473021b0345)\

In all the above examples, we see that the type of `variable.property` is aware of control
flow, the types of `expression().property` and `variable.method()` are not.

Unfortunately, the direct analogue to properties in Ruby are instance variables like
`@property`, which have the limitation that they can can only be accessed inside their
owning class. It's like if JavaScript only allowed `this.property` instead of allowing the
call site to be any arbitrary expression like `x.property`. In Ruby, you can't write
`x.@property`.[^ivar_get]

[^ivar_get]:
  You can do something similar: `x.instance_variable_get(:@property)`, but again this is a
  method, not a property access—someone could have overridden the `.instance_variable_get`
  method!

If you **do** use instance variables in Ruby with Sorbet, they behave
comparably[^ivar_bug] to their counterparts in other languages:

[^ivar_bug]:
  There's a [known bug](https://github.com/sorbet/sorbet/issues/1374) in the
  implementation at the time of writing, but it occurs somewhat rarely in practice so we
  haven't prioritized fixing it.

[→ View example on sorbet.run](https://sorbet.run/#%23%20typed%3A%20strict%0A%0Aclass%20A%0A%20%20extend%20T%3A%3ASig%0A%0A%20%20sig%20%7Bvoid%7D%0A%20%20def%20initialize%0A%20%20%20%20%40some_property%20%3D%20T.let%28nil%2C%20T.nilable%28Integer%29%29%0A%20%20end%0A%0A%20%20sig%20%7Bparams%28x%3A%20Integer%29.void%7D%0A%20%20def%20takes_number%28x%29%0A%20%20%20%20puts%20x%0A%20%20end%0A%0A%20%20sig%20%7Bvoid%7D%0A%20%20def%20example1%0A%20%20%20%20if%20%40some_property%0A%20%20%20%20%20%20takes_number%28%40some_property%29%0A%20%20%20%20end%0A%20%20%20%20takes_number%28%40some_property%29%0A%20%20end%0Aend)

Seen from this lens, I think it's fair to say that Sorbet is doing the best it can with
what it has. If you disagree and have a suggestion for how Sorbet could do better, feel
free to reach out.

# Extra thoughts

It's maybe worth noting that even the Ruby VM itself cheats a little here: yes `x.foo` is
technically a method call, but if that method was defined via `attr_reader`, the Ruby VM
has special handling to make it run much, much faster than had the method been defined
manually. So while you can think of these two things as doing the same thing, the first
one will run much faster:

```ruby
attr_reader :foo
def foo; @foo; end
```

I take this to mean that even the Ruby VM itself realizes that there is value in having
something property like. It just unfortunately didn't make it into the language itself.

It's interesting to imagine a future where Sorbet treats `x.foo` and `x.foo()` separately.
For example, it could **require** that non-constant, nullary methods be written with
trailing `()` even though Ruby doesn't require it. Then a follow up change might be able
to build on that invariant, to treat `x.foo` like a property access instead of a method
call.

But not only are there some high-level design and low-level technical problems standing in
the way of implementing this right now, there's also a social problem: almost every Ruby
style guide and linter requires the opposite, namely that nullary methods **never** be
called with `()` explicitly. Solving social problems tends to involve waging holy wars,
which is never all that fun.

And to throw another wrench into the picture: recent versions of JavaScript added getters,
which allow executing an arbitrary method on property access. Python has had computed
`@property` declarations since version 2.2. Notably, TypeScript, Flow, and mypy simply do
not implement getters the same way as methods, even though they arguably should for
soundness:

[→ View example on TypeScript
Playground](https://www.typescriptlang.org/play?#code/MYGwhgzhAECC0G8BQ1oQPYFsCmAFATugA7b4AuAngFzQB2ArpgEanQA+09tAJtgGYBLWtm4BuFGizYAstjIALdNwAUAShoNmrDl16Dh3RNHxz6+WqOgBfCQHM5knAHE5ZUmo2MW+dpx78hEUQJVAE+aGVpMAUAOnwwHiw1aAAeaAAGGIBWVWDUfPyTMjNaaABGcQKraGwQCGw8gsLTc0r8m1QbGyQ+LmAyAXRS4CwiejdYDzhGopK6bAB3ODVxG17afsHSsjAAa2wIADkvdwAPTy18XORUEdoMEGwYkHRbZVPVVaQevoGhmtOYEwREeZWUYBosGuEjCETAMQwOAIxFIlGhBR2+yOJ3w4IRUmRJHIFE+Eg60ExB2OlzxiLwhCJaK+Pw2f1K2EBwMeACZkjdoLDlCNgeNsJNVPikQzUSTGqhKdiacKxhM1JL6SjiaTOhIFdTvELRqLxerCTLSd11pt-hygSDsABmcGQ9EC8K0qSyBRKNSu+V7Kk4j04L2KFSqbXWXUBxUG+F00M+iPMq1sgF2x4AFmdcFdgvjUhcZDcVzlFJj+vcBecrlIkfJeqD1ewRZLFqAA)\
[→ View example on Try
Flow](https://flow.org/try/#0PQKgBAAgZgNg9gdzCYAoVBjGBDAzrsAQTAG9Uwxc4BbAUwAUAnOAB1sYBcBPALjAH4AdgFdqAI3YBucpRq0AsrQ4ALOABMAFAEo+Q0RMakAvjIDmS2XQDiSju226R49qRkUAllDAb52FQDpGbEE1Gm0wAB4wAAZ-AFYtVwpk5MYlYUZBMABGaRSjMFoYXFoklNT0zLzkkwoTE1QoYUEMDnc4LIwaFmE7QgciMrSODKzBWiR+rWkTJpa2jrAObABrWlwAOX17AA8+JwNEsgouwSoYWn94Uw0d6dQGudb2rNod7GoWC+yNbD5CI4yTzebD+Kh0JisdjcQEpZZrTbbRi-MFySFsThce51GTw9ZbZzI0HghjMDEwmboJ4LV7vT4XABM4WOYGBGi6n16tCmqIhZOhWLKFDxiMJ7O6XJ5JPRAuxYFqS1W+KR4s5fW0vNJUMx90ezWeizeHy+tAAzL9-rDWV4USTFCp1NorcKlaKDLa5PbVJotHKFSKCe7iZ6lN6nZTGvqaYU6SaACwWohWtnB6y2djOxUIwP2VO0GwcOyMP24105omagtF3VAA)\
[→ View example on mypy
Playground](https://mypy-play.net/?mypy=latest&python=3.10&flags=strict&gist=753c6fdd9c640d3c5cfba896894e95bd)\

If it were not so common in Ruby for **all** nullary methods to be called without `()`,
instead of just those defined with `attr_reader` or something similar, maybe Sorbet could
have chosen the same trade-off.
