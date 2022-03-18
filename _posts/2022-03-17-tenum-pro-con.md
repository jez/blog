---
# vim:tw=90
layout: post
title: "T::Enum Pros & Cons"
date: 2022-03-17T19:13:16-04:00
description: >
  A short note about why <code>T::Enum</code> is not great but also kinda great.
math: false
categories: ['fragment', 'sorbet']
# subtitle:
# author:
# author_url:
---

One feature that Sorbet doesn't have[^yet][^but-actually] but gets requested frequently
is support for literal string and symbol types. Something like `T.any(:left, :right)`,
which is a type that allows either the symbol literal `:left` or `:right`, but no other
`Symbol`s much less other types of values. The closest that Sorbet has to this right now
is typed enums:

[^yet]:
  Yet. The biggest limitation is just that Sorbet's approach to type inference is designed
  to run fast and be simple to understand, sometimes sacrificing power.

[^but-actually]:
  ... but actually Sorbet already has these types internally 😅 It's just that it doesn't
  have syntax for people to write them in type annotations. And lo, it's [because they're
  buggy], but for the things where Sorbet needs to use them internally we can
  intentionally work around the known bugs, so it hasn't been worth the pain to fix.


```ruby
class LeftOrRight < T::Enum
  enums do
    Left = new
    Right = new
  end
end
```

TypeScript, Flow, and Mypy all have literal types. You probably have felt yourself wanting
this. I don't really have to explain why they're nice. But I'll do it anyways, just to
prove that I hear you.

\

## 👎 `T::Enum` cannot be combined in ad hoc unions.

That's a fancy way of saying we'd like to be able to write `T.any(:left, :right)` in any
type annotation, without first having to pre-declare the new union type to the world. I
spoke at length about how the existence of ad hoc union types make handling exceptional
conditions [more pleasant than checked exceptions][ad-hoc-exceptions], so I'm right there
with you in appreciating that feature.

## 👎 `T::Enum` is verbose.

Even if you wanted to pre-declare the enum type. Consider:

```ruby
LeftOrRight = T.type_alias {T.any(:left, :right)}
```

Boom. One line, no boilerplate. Wouldn't that be nice?


## 👎 It's hard to have one `T::Enum` be a subset of another.

This comes up so frequently that there's [an FAQ entry][subset] about it. The answer is
yet more verbosity and boilerplate.

\

So I hear you. But I wanted to say a few things in defense of `T::Enum`, because I think
that despite how nice it might be to have literal types (and again, we may yet build them
one day), there are still *a lot of points* in favor of `T::Enum` as it exists today.

\

## 🚀 Every IDE feature Sorbet supports works for `T::Enum`.

`T::Enum`s are just normal constants. Sorbet supports finding all constant references,
renaming constants, autocompleting constant names, jumping to a constant's definition,
hovering over a constant to see its documentation comment. Also all of those features work
on both the enum class itself and each individual enum value.

We could _maybe_ support completion for symbol literals in limited circumstances, but it
would be the first of its kind in Sorbet. Same goes for rename, and maybe find all
references. Jump to Definition I guess would want to jump not to the actual definition,
but rather to the signature that specified the literal type? It's weird.

## 🙊 `T::Enum` guards against basically all typos.

Even in `# typed: false` files! Even when calling methods that take don't have signatures,
or that have loose signatures like `Object`! Incidentally, this is basically the same
reason why find all references can work so well.

## 🤝 It requires being intentional.

Code gets out of hand really quickly when people try to cutely interpolate strings into
other strings that hold meaning. I'd much rather deal with this:

```ruby
direction = [left_or_right, up_or_down]
```

than this:

```ruby
direction = "#{left_or_right}__#{up_or_down}"
```

If you try to do this with `T::Enum` you get strings that look like:

```ruby
'#<LeftOrRight::Left>__#<UpOrDown::Up>'
```

which confuses people, so they ask how to do the thing they're trying to do, which is a
perfect opportunity to talk them down from that cliff. If people decide that yes, this
really is the API we need, we can be intentional about it with `.serialize`:

```ruby
direction = "#{left_or_right.serialize}__#{up_or_down.serialize}"
```

## 🕵️ It's easy to search for.

This is a small one, but I'll mention it anyways. It's quick to search the Sorbet docs for
`T::Enum` and get to the right page. It's similarly easy to find examples of it being used
in a given codebase, to learn from real code. There's no unique piece of syntax in
`T.any(:left, :right)` that is a surefire thing to search for.

[because they're buggy]: https://sorbet.run/#%23%20typed%3A%20true%0Ax%20%3D%20%3Adefault%0A%0A1.times%20do%0A%20%20%23%20Sorbet%20does%20not%20report%20an%20error%20here%0A%20%20%23%20%28it%20would%20have%20to%20start%20doing%20so%29%0A%20%20x%20%3D%20%3Afirst%0Aend%0A%0AT.reveal_type%28x%29%20%23%20Sorbet%20shows%20the%20wrong%20type%20here%0A%0A%23%20Sorbet%20can't%20tell%20the%20difference%20bewteen%20a%20hash%20literal%0A%23%20with%20a%20variable%20key%20versus%20with%20a%20symbol%20literal%20key%0A%23%20at%20the%20time%20that%20inference%20happens.%0AT.reveal_type%28%7Bx%20%3D%3E%20nil%7D%29%0AT.reveal_type%28%7B%3Adefault%20%3D%3E%20nil%7D%29

[ad-hoc-exceptions]: /union-types-checked-exceptions/

[subset]: https://sorbet.org/docs/tenum#defining-one-enum-as-a-subset-of-another-enum
