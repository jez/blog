---
# vim:tw=90
layout: post
title: "Only return nil if given nil"
date: 2023-09-15T18:28:50-04:00
description: >
  A quick post showing how to write a type that people commonly want to be able to write,
  where the return type is only nil if the input was nilable.
math: false
categories: ['sorbet', 'ruby']
# subtitle:
# author:
# author_url:
---

Sometimes you might want a Sorbet method signature like, "Returns `T.nilable` **only if**
the input is `T.nilable`. But if the input is non-`nil`, then so is the output."

With clever usage of Sorbet generics, this is possible!

```{.ruby .numberLines .hl-4}
sig do
  type_parameters(:U)
    .params(
      amount: T.any(T.all(T.type_parameter(:U), NilClass), Amount)
    )
    .returns(T.any(T.all(T.type_parameter(:U), NilClass), String))
end
def get_currency(amount)
  if amount.nil?
    return amount
  else
    return amount.currency
  end
end
```

And then calling this method looks like this:

```{.ruby .numberLines .hl-10}
sig do
  params(
    amount: Amount,
    maybe_amount: T.nilable(Amount),
    nil_class: NilClass
  )
  .void
end
def example(amount, maybe_amount, nil_class)
  res = get_currency(amount)
  T.reveal_type(res) # => String

  res = get_currency(maybe_amount)
  T.reveal_type(res) # => T.nilable(String)

  res = get_currency(nil_class)
  T.reveal_type(res) # => T.nilable(String)
end
```

Some things to note about how it works:

### It's using Sorbet's support for [generic methods].

In other languages, you might try to do something like this with overloaded signatures,
but Sorbet [doesn't support overloads], except in limited circumstances.

### It uses `T.all` (an [intersection type]) to approximate [bounded method generics].

For the time being, Sorbet doesn't have first class support for placing bounds on
generic method type parameters, so we have to approximate them with intersection types.

### The upper bound is `NilClass`, not `T.nilable(Amount)`!

This is the main trick. This lets us _either_ return the thing we wanted (in our case,
`String`), or _the input_ if the input is `nil`.

```ruby
T.all(T.type_parameter(:U), NilClass)
```

Returning something with a generic type means returning the exact input,[^parametricity]
not merely "something with the same type as the input."

[^parametricity]:
  {-} This constraint about returning the input unchanged is an example of [parametricity
  in action][parametricity].

So instead of having `return nil` on line 10, we have to write `return amount`.

\

When we call `get_currency(amount)`, where `amount` is known to be non-`nil`, Sorbet is
smart enough to know that `get_currency` returns `String`!

What's happening here is that Sorbet is inferring the `T.type_parameter(:U)` to
`T.noreturn`, which then collapses into `String`, because `T.any(T.noreturn, String)` is
just `String`.


[generic methods]: https://sorbet.org/docs/generics#generic-methods
[doesn't support overloads]: https://sorbet.org/docs/error-reference#5040
[intersection type]: https://sorbet.org/docs/intersection-types
[bounded method generics]: https://sorbet.org/docs/generics#placing-bounds-on-generic-methods
[parametricity]: https://blog.jez.io/sorbet-parametricity/
