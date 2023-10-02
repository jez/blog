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

<figure class="left-align-caption">

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

<figcaption>
[Full example on sorbet.run →](https://sorbet.run/#%23%20typed%3A%20true%0Aextend%20T%3A%3ASig%0A%0Aclass%20Amount%20%3C%20T%3A%3AStruct%0A%20%20prop%20%3Aamount%2C%20BigDecimal%0A%20%20prop%20%3Acurrency%2C%20String%0Aend%0A%0Asig%20do%0A%20%20type_parameters%28%3AU%29%0A%20%20%20%20.params%28%0A%20%20%20%20%20%20amount%3A%20T.any%28T.all%28T.type_parameter%28%3AU%29%2C%20NilClass%29%2C%20Amount%29%0A%20%20%20%20%29%0A%20%20%20%20.returns%28T.any%28T.all%28T.type_parameter%28%3AU%29%2C%20NilClass%29%2C%20String%29%29%0Aend%0Adef%20get_currency%28amount%29%0A%20%20if%20amount.nil%3F%0A%20%20%20%20return%20amount%0A%20%20else%0A%20%20%20%20return%20amount.currency%0A%20%20end%0Aend%0A%0Asig%20do%0A%20%20params%28%0A%20%20%20%20amount%3A%20Amount%2C%0A%20%20%20%20maybe_amount%3A%20T.nilable%28Amount%29%2C%0A%20%20%20%20nil_class%3A%20NilClass%0A%20%20%29%0A%20%20.void%0Aend%0Adef%20example%28amount%2C%20maybe_amount%2C%20nil_class%29%0A%20%20res%20%3D%20get_currency%28amount%29%0A%20%20T.reveal_type%28res%29%20%23%20%3D%3E%20String%0A%0A%20%20res%20%3D%20get_currency%28maybe_amount%29%0A%20%20T.reveal_type%28res%29%20%23%20%3D%3E%20T.nilable%28String%29%0A%0A%20%20res%20%3D%20get_currency%28nil_class%29%0A%20%20T.reveal_type%28res%29%20%23%20%3D%3E%20T.nilable%28String%29%0A%0A%20%20res%20%3D%20get_currency%28T.unsafe%28amount%29%29%0A%20%20T.reveal_type%28res%29%20%23%20%3D%3E%20T.nilable%28String%29%0Aend)
</figcaption>

</figure>

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

\

- - - - -

## Update, 2023-10-02

I realized that the signature above gets a lot more clear if Sorbet were to support some
sort of syntax for placing bounds on generic methods' type parameters. For example using a
hypothetical syntax:

```{.ruby .numberLines .hl-2}
sig do
  type_parameters(U: NilClass)
    .params(amount: T.any(T.type_parameter(:U), Amount))
    .returns(T.any(T.type_parameter(:U), String))
end
def get_currency(amount)
  if amount.nil?
    return amount
  else
    return amount.currency
  end
end
```

This signature says that the `T.type_parameter(:U)` is upper bounded by `NilClass` (and
not lower bounded, and therefore assumes the normal lower bound of `T.noreturn`).

Written like this, it becomes maybe more clear how this signature works:

- If the caller passes in a possibly `nil` value, Sorbet infers `T.type_parameter(:U)` to
  its upper bound.
- Otherwise, Sorbet is free to leave the inferred type at the lower bound of `T.noreturn`,
  and `T.any(T.noreturn, Amount)` is simply the same as `Amount`.


[generic methods]: https://sorbet.org/docs/generics#generic-methods
[doesn't support overloads]: https://sorbet.org/docs/error-reference#5040
[intersection type]: https://sorbet.org/docs/intersection-types
[bounded method generics]: https://sorbet.org/docs/generics#placing-bounds-on-generic-methods
[parametricity]: https://blog.jez.io/sorbet-parametricity/
