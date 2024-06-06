---
# vim:tw=90 fo-=tc
layout: post
title: "Old vs new case statement in Ruby"
date: 2024-05-31T16:22:05-04:00
description: >
  A quick note on why I prefer Ruby's old case/when syntax over the new pattern matching syntax with case/in.
math: false
categories: ['fragment', 'ruby']
# subtitle:
# author:
# author_url:
---

A quick, loosely-formed note on why I prefer Ruby's `case`/`when` syntax to the new pattern matching syntax with `case`/`in`.

### The `case`/`when` syntax is less brittle to modifications

Let's say you start with this:

```ruby
A = Struct.new(:foo)
B = Struct.new(:bar)

def example(a_or_b)
  case a_or_b
  in A(foo)
    p(foo)
  in B(bar)
    p(bar)
  end
end

example(A.new(0))
example(B.new(1))
```

And you want to add another field to `B`:

```ruby
B = Struct.new(:bar, :qux)
# ...
example(B.new(1, ''))
```

This requires changing the case that handles `B` in `example`, even though it doesn't touch the new `qux` field. If you don't change it, you'll get a `NoMatchingPatternError` exception at runtime:

```
❯ ruby example.rb
0
example.rb:7:in `example': #<struct B bar=1, qux=2> (NoMatchingPatternError)
        from example.rb:16:in `<main>'
```

There are two ways to deal with this this:

- Only use keyword-based patterns (requires defining the struct with `keyword_init: true`). Sometimes out of your control.

- Use normal `case`/`when` statements.

  ```ruby
  case a_or_b
  when A
    p(a_or_b.foo)
  when B
    p(a_or_b.bar)
  end
  ```

I find it annoying that adding new features triggers "breaking" changes in unrelated, downstream code.

### It can be prone to merge conflicts

If you and a colleague are working on the same piece of code, you can easy end up in a situation where you both add a new field. Consider starting with this:

```ruby
AStructWithManyOptionalFields = Struct.new(
  :a,
  :struct,
  :with,
  :many,
  :fields
  keyword_init: true
)

# ...

case x
when AStructWithManyOptionalFields(a:)
  # ...
end
```

The `case` statement only reads the field `a`. But maybe you and a colleague add a field and use it in this `case` statement at the same time:

```{.ruby .numberLines .hl-5 .hl-7}
AStructWithManyOptionalFields = Struct.new(
  :a,
  :struct,
  :with,
  :very,
  :many,
  :optional,
  :fields
  keyword_init: true
)
```

You edit the `case` statement like this:

```ruby
when AStructWithManyOptionalFields(a:, very:)
```

And your colleague like this:


```ruby
when AStructWithManyOptionalFields(a:, optional:)
```

Even if the two changes wouldn't have conflicted on their own (based on how the body of the method was written), now they're going to conflict.

Maybe in practice there would have already been a conflict (because of where these options are passed when `AStructWithManyOptionalFields` is constructed, or because of the structure of the body of the `case` arms). But had we used `case`/`when` statements, there would have been one fewer location with the potential to introduce a merge conflict.


### Sorbet considerations

You could argue that I shouldn't be allowed to complain about this, because it's within my power to change Sorbet. So instead of complaining, I'll just list the current limitations (that one day we'll improve).

- Sorbet doesn't support types for patterns. All variables introduced by Ruby pattern match statements are untyped.

- There isn't autocompletion for field names in patterns, regardless of whether the field is a positional or keyword field. (Autocompletion for getter methods is trivial, because they're just normal methods.)

- Neither Find All References nor Rename Symbol currently see the pattern names, meaning that these editor features won't work as well as if the code just used getter methods.

All of this being said, I spot checked other languages' IDE support for these features, and despite having typed support for pattern matching, many of them (especially Python type checkers) did not yet have support for these IDE features.

In defense of pattern matching, the fact that it raises a `NoMatchingPatternError` will one day be a **benefit** to type safety—these patterns will have opt-out exhaustiveness checking, instead of the opt-in exhaustiveness checking that exists with `T.absurd` today.
\

\

Taken all together, these are small grievances, but the thing is that I don't personally feel like the benefit of being able to use a pattern statement to shorten something like `x.foo` to `foo` is worth the cost of these paper cuts. I'll keep using `case`/`when` in my own code for the time being.


