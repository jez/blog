---
# vim:tw=72
layout: post
title: "Typed Errors in Sorbet"
date: 2021-06-04 22:12:37 -0700
comments: false
share: false
categories: ['ruby', 'sorbet', 'types']
description: >
  Sorbet's union types in method returns provide a low-friction, high
  value way to model how methods can fail.
strong_keywords: false
fancy_blockquotes: false
---

<!-- more -->

<p></p>

I really like this post from Matt Parsons, [The Trouble with Typed
Errors][trouble-typed]. It's written for an audience writing Haskell,
but if you can grok Haskell syntax, it's worth the read because the
lessons apply broadly to most statically typed programming languages.

If you haven't read it (or it's been a while) the setup is basically:
typing errors is hard, and nearly every solution is either brittle,
clunky, verbose, or uses powerful type system features that we didn't
want to have to reach for.

Hidden towards the bottom of the post, we find:

> In PureScript or OCaml, you can use open variant types to do this
> flawlessly. Haskell doesn't have open variants, and the attempts to
> mock them end up quite clumsy to use in practice.

What Matt calls "open variant types" I call **ad hoc union types** (see
my previous post about [checked exceptions and
Sorbet][checked-exceptions]). Naming aside, Sorbet has them! We don't
have to suffer from clunky error handling!

I thought it'd be interesting to show what Matt meant in this quote by
translating his example to Sorbet.

I wrote a complete, working example, but rather than repeat the whole
thing here, I'm just going to excerpt the good stuff. If you're wondering
how something is defined in full, check the full example:

<a href="https://sorbet.run/#%23%20typed%3A%20strict%0A%0A%23%20This%20is%20a%20re-implementation%20of%20Matt%20Parsons's%20%22The%20Trouble%20with%20Typed%0A%23%20Errors%22%20in%20Sorbet%20(Ruby)%20because%20I%20think%20Sorbet%20happens%20to%20handle%20it%0A%23%20pretty%20well%20all%20things%20considered.%0A%23%0A%23%20%20%20%20%20%3Chttps%3A%2F%2Fwww.parsonsmatt.org%2F2018%2F11%2F03%2Ftrouble_with_typed_errors.html%3E%0A%23%0A%23%20Specifically%2C%20he%20mentions%0A%23%0A%23%20%20%20%20%20In%20PureScript%20or%20OCaml%2C%20you%20can%20use%20open%20variant%20types%20to%20do%20this%0A%23%20%20%20%20%20flawlessly.%0A%23%0A%23%20and%20Sorbet%20more%20or%20less%20has%20those%20(untagged%20unions).%20It's%20interesting%0A%23%20to%20see%20what%20that%20means%20for%20being%20able%20to%20track%20errors%2C%20because%20we%0A%23%20actually%20use%20Sorbet%20in%20a%20huge%20codebase%20at%20work.%20Tracking%20all%20the%20kinds%0A%23%20of%20errors%20that%20could%20happen--and%20no%20more--can%20make%20code%20far%20easier%20to%0A%23%20understand.%0A%0A%23%20To%20run%20this%20file%3A%0A%23%0A%23%20%20%20gem%20install%20sorbet-runtime%0A%23%20%20%20ruby%20typed-errors.rb%0A%0Arequire%20'sorbet-runtime'%0A%0A%23%20There's%20a%20bug%20in%20Sorbet%20that%20forces%20us%20to%20wrap%20all%20this%20code%20in%20a%0A%23%20class%2C%20but%20I%20have%20a%20PR%20open%20to%20fix%20it.%20For%20now%2C%20we%20tolerate%20it.%0Aclass%20Main%0A%20%20extend%20T%3A%3ASig%0A%0A%20%20%23%20-----%20Custom%20error%20types%20-----%0A%0A%20%20%23%20Defining%20custom%20data%20types%20is%20a%20little%20clunky%20in%20Ruby%20%2F%20Sorbet.%20You%0A%20%20%23%20have%20to%20chose%20whether%20you%20want%20a%20plain%20class%2C%20an%20enum%2C%20a%20sealed%0A%20%20%23%20class%20hierarchy%2C%20etc.%20In%20a%20real%20codebase%2C%20I%20think%20if%20you%20were%20going%0A%20%20%23%20to%20this%20length%20to%20care%20for%20errors%20the%20kinds%20of%20errors%20that%20you%20have%0A%20%20%23%20are%20usually%20pretty%20rich%20(e.g.%2C%20there's%20a%20message%20and%20context%20with%0A%20%20%23%20the%20failures)%2C%20so%20you'd%20probably%20go%20with%20the%20sealed%20class%20hierarchy.%0A%20%20%23%0A%20%20%23%20For%20this%20example%2C%20I%20chose%20three%20different%20ways%20to%20just%20show%20them%20all.%0A%0A%20%20class%20HeadError%0A%20%20end%0A%0A%20%20class%20LookupError%20%3C%20T%3A%3AEnum%0A%20%20%20%20enums%20do%0A%20%20%20%20%20%20KeyWasNotPresent%20%3D%20new%0A%20%20%20%20end%0A%20%20end%0A%0A%20%20module%20ParseError%0A%20%20%20%20extend%20T%3A%3AHelpers%0A%20%20%20%20sealed!%0A%0A%20%20%20%20class%20UnexpectedChar%20%3C%20T%3A%3AStruct%0A%20%20%20%20%20%20include%20ParseError%0A%20%20%20%20%20%20prop%20%3Amessage%2C%20String%0A%20%20%20%20end%0A%0A%20%20%20%20class%20RanOutOfInput%0A%20%20%20%20%20%20include%20ParseError%0A%20%20%20%20end%0A%20%20end%0A%0A%20%20%23%20-----%20Helper%20methods%20-----%0A%0A%20%20%23%20Again%2C%20concise%20syntax%20is%20not%20Sorbet's%20strong%20suit.%20The%20signature%0A%20%20%23%20annotations%20are%20pretty%20verbose%20here%20(especially%20generics)%20but%20they%0A%20%20%23%20pretty%20much%20exactly%20map%20to%20the%20Haskell%20functions%20in%20the%20post.%0A%0A%20%20sig%20do%0A%20%20%20%20%20%20params(xs%3A%20String)%0A%20%20%20%20%20%20.returns(T.any(String%2C%20HeadError))%0A%20%20end%0A%20%20def%20self.head(xs)%0A%20%20%20%20case%20xs.size%0A%20%20%20%20when%200%20then%20HeadError.new%0A%20%20%20%20else%20T.must(xs%5B0%5D)%0A%20%20%20%20end%0A%20%20end%0A%0A%20%20sig%20do%0A%20%20%20%20type_parameters(%3AK%2C%20%3AV)%0A%20%20%20%20%20%20.params(%0A%20%20%20%20%20%20%20%20hash%3A%20T%3A%3AHash%5BT.type_parameter(%3AK)%2C%20T.type_parameter(%3AV)%5D%2C%0A%20%20%20%20%20%20%20%20key%3A%20T.type_parameter(%3AK)%0A%20%20%20%20%20%20)%0A%20%20%20%20%20%20.returns(T.any(T.type_parameter(%3AV)%2C%20LookupError))%0A%20%20end%0A%20%20def%20self.lookup(hash%2C%20key)%0A%20%20%20%20if%20hash.key%3F(key)%0A%20%20%20%20%20%20hash.fetch(key)%0A%20%20%20%20else%0A%20%20%20%20%20%20LookupError%3A%3AKeyWasNotPresent%0A%20%20%20%20end%0A%20%20end%0A%0A%20%20sig%20do%0A%20%20%20%20params(source%3A%20String).returns(T.any(Integer%2C%20ParseError))%0A%20%20end%0A%20%20def%20self.parse(source)%0A%20%20%20%20case%20source%0A%20%20%20%20when%20%22%22%20then%20ParseError%3A%3ARanOutOfInput.new%0A%20%20%20%20else%0A%20%20%20%20%20%20begin%0A%20%20%20%20%20%20%20%20Integer(source%2C%2010)%0A%20%20%20%20%20%20rescue%20ArgumentError%20%3D%3E%20exn%0A%20%20%20%20%20%20%20%20ParseError%3A%3AUnexpectedChar.new(message%3A%20exn.message)%0A%20%20%20%20%20%20end%0A%20%20%20%20end%0A%20%20end%0A%0A%20%20%23%20-----%20Composing%20errors%20-----%0A%0A%20%20STR_MAP%20%3D%20T.let(%7B%0A%20%20%20%20%224__%22%20%3D%3E%20%222%22%0A%20%20%7D%2C%20T%3A%3AHash%5BString%2C%20String%5D)%0A%0A%20%20sig%20do%0A%20%20%20%20params(str%3A%20String)%0A%20%20%20%20%20%20.returns(T.any(Integer%2C%20HeadError%2C%20LookupError%2C%20ParseError))%0A%20%20end%0A%20%20def%20self.foo(str)%0A%20%20%20%20%23%20These%20%60return%60%20lines%20are%20definitely%20not%20as%20convenient%20as%20do%0A%20%20%20%20%23%20notation%20in%20Haskell%2C%20but%20the%20interesting%20thing%20is%20that%20they're%0A%20%20%20%20%23%20still%20pretty%20nice%3A%20because%20of%20flow-sensitive%20typing%2C%20the%20type%20of%0A%20%20%20%20%23%20%60c%60%20changes%2C%20as%20commented%3A%0A%20%20%20%20c%20%3D%20head(str)%20%23%20%3D%3E%20c%20%3A%20T.any(String%2C%20HeadError)%0A%20%20%20%20return%20c%20unless%20c.is_a%3F(String)%0A%20%20%20%20%23%20%3D%3E%20c%20%3A%20String%0A%20%20%20%20r%20%3D%20lookup(STR_MAP%2C%20str)%0A%20%20%20%20return%20r%20unless%20r.is_a%3F(String)%0A%20%20%20%20parse(%22%23%7Bc%7D%23%7Br%7D%22)%0A%20%20end%0A%0A%20%20%23%20This%20method%20doesn't%20call%20%60head%60%20like%20before%2C%20so%20it%20doesn't%20need%20to%0A%20%20%23%20have%20%60HeadError%60%20in%20the%20return%20type.%0A%20%20sig%20do%0A%20%20%20%20params(str%3A%20String)%0A%20%20%20%20%20%20.returns(T.any(Integer%2C%20LookupError%2C%20ParseError))%0A%20%20end%0A%20%20def%20self.bar(str)%0A%20%20%20%20r%20%3D%20lookup(STR_MAP%2C%20str)%0A%20%20%20%20return%20r%20unless%20r.is_a%3F(String)%0A%20%20%20%20parse(r)%0A%20%20end%0A%0A%20%20p%20foo(%224__%22)%0A%20%20p%20bar(%224__%22)%0Aend%0A%0A%23%20Because%20%60T.any%60%20can%20create%20ad%20hoc%2C%20untagged%20union%20types%20anywhere%2C%0A%23%20there's%20no%20need%20to%20define%20an%20%60AllErrorsEver%60%20data%20type%20like%20the%20reader%0A%23%20was%20tempted%20to%20in%20the%20Typed%20Errors%20blog%20post.%0A%23%0A%23%20If%20you%20find%20that%20a%20particular%20set%20of%20errors%20are%20showing%20up%20super%0A%23%20frequently%2C%20you%20can%20lurk%20them%20into%20a%20type%20alias%3A%0A%23%0A%23%20%20%20%20%20MostCommonErrors%20%3D%20T.type_alias%20%7BT.any(LookupError%2C%20ParseError)%7D%0A%23%0A%23%20and%20then%20use%20this%20alias%20in%20various%20places.%0A%23%0A%23%20One%20other%20note%3A%20to%20make%20this%20pattern%20nicer%2C%20code%20might%20want%20to%0A%23%20explicitly%20box%20up%20successful%20results%2C%20with%20a%20type%20like%0A%23%0A%23%20%20%20%20%20class%20Ok%20%3C%20T%3A%3AStruct%0A%23%20%20%20%20%20%20%20extend%20T%3A%3AGeneric%0A%23%20%20%20%20%20%20%20Type%20%3D%20type_member%0A%23%20%20%20%20%20%20%20prop%20%3Aval%2C%20Type%0A%23%20%20%20%20%20end%0A%23%0A%23%20So%20then%20you'd%20have%0A%23%20%20%20%20%20T.any(Ok%5BString%5D%2C%20MostCommonErrors)%0A%23%20and%20you%20could%20do%20make%20all%20the%20%60return%60%20lines%20always%20look%20the%20same%3A%0A%23%20%20%20%20%20return%20x%20unless%20x.is_a%3F(Ok)%0A%23%20but%20the%20flipside%20would%20mean%20that%20you'd%20have%20to%20use%20%60.val%60%20at%20all%20the%0A%23%20places%20that%20you%20would%20have%20normally%20used%20%60x%60%3A%0A%23%20%20%20%20%20parse(x.val)%0A%23%20so%20it's%20maybe%20not%20worth%20it.%0A%0A">→ View on sorbet.run</a>

First, here's how we'd type the three running helper methods from Matt's
post:

```ruby
# Returns the first letter of the input,
# or returns `HeadError` if empty
sig {params(xs: String).returns(T.any(String, HeadError))}
def self.head(xs); ...; end


# Gets the value for `key` in `hash`, or returns LookupError.
#
# This is normally defined in the stdlib, and in trying to
# match Matt's post, it ends up not being super idiomatic,
# but the types still work out.
sig do
  type_parameters(:K, :V)
    .params(
      hash: T::Hash[T.type_parameter(:K), T.type_parameter(:V)],
      key: T.type_parameter(:K)
    )
    .returns(T.any(T.type_parameter(:V), LookupError))
end
def self.lookup(hash, key); ...; en


# Convert a String to an integer, or return ParseError.
sig {params(source: String).returns(T.any(Integer, ParseError))}
def self.parse(source); ...; end
```

Notice how in all three cases, we use a normal [Sorbet union type] in
the return, like `T.any(String, HeadError)`. All of the error types are
just user-defined classes. For example, `HeadError` is just defined like
this:

```ruby
class HeadError; end
```

And `ParseError` is defined using [sealed classes] and [typed structs]
to approximate algebraic data types in other typed languages:

```ruby
module ParseError
  extend T::Helpers
  sealed!

  class UnexpectedChar < T::Struct
    include ParseError
    prop :message, String
  end

  class RanOutOfInput
    include ParseError
  end
end
```

Then at the caller side, it's simple to handle the errors:

```ruby
sig do
  params(str: String)
    .returns(T.any(Integer, HeadError, LookupError, ParseError))
end
def self.foo(str)
  c = head(str) # => c : T.any(String, HeadError)
  return c unless c.is_a?(String)
  # => c : String
  r = lookup(STR_MAP, str)
  return r unless r.is_a?(String)
  parse("#{c}#{r}")
end
```

The idea is that the return type includes the possible errors, so we
have to handle them. This example handles the errors by checking for
success and returning early with the error otherwise. This manifests in
the return type of `foo`, which mentions four outcomes:

- a successful result (`Integer`)
- three kinds of failures (`HeadError`, `LookupError`, and `ParseError`)

It would have worked equally well to handle and recover from any or all
of the errors: Sorbet knows exactly which error is returned by which
method, so there's never a burden of handling more errors than are
possible.

It's fun that what makes this work is Sorbet's natural [flow-sensitive
typing], not some special language feature. Notice how before and after
the first early return, Sorbet updates its knowledge of the type of `c`
(shown in the comments) because it knows how `is_a?` works.

Another example: if some other method only calls `lookup` and `parse`
(but not `head`), it doesn't have to mention `HeadError` in its return:

```ruby
sig do
  params(str: String)
    # does need to mention HeadError
    .returns(T.any(Integer, LookupError, ParseError))
end
def self.bar(str)
  r = lookup(STR_MAP, str)
  return r unless r.is_a?(String)
  parse(r)
end
```

And while there's never a **need** to predeclare one monolithic error type
(like `AllErrorsEver` in Matt's post), if it happens to be convenient,
Sorbet still lets you, using type aliases. For example, maybe there are
a bunch of methods that all return `LookupError` and `ParseError`. We
can factor that out into a type alias:

```ruby
MostCommonErrors = T.type_alias {T.any(LookupError, ParseError)}
```

That's it! Sorbet's union types in method returns provide a
low-friction, high value way to model how methods can fail.

[trouble-typed]: https://www.parsonsmatt.org/2018/11/03/trouble_with_typed_errors.html
[checked-exceptions]: https://blog.jez.io/union-types-checked-exceptions/
[Sorbet union type]: https://sorbet.org/docs/union-types
[flow-sensitive typing]: https://sorbet.org/docs/flow-sensitive
[sealed classes]: https://sorbet.org/docs/sealed
[typed structs]: https://sorbet.org/docs/tstruct
