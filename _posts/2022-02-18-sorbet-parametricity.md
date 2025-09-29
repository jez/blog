---
# vim:tw=90 fo-=tc
layout: post
title: "Sorbet, Generics, and Parametricity"
date: 2022-02-18T02:59:55-05:00
description:
  There's an interesting property in programming languages with generic types called
  "parametricity" that says all functions with a given generic type have to behave
  similarly, which is a powerful tool for understanding generic code.
math: false
categories: ['ruby', 'sorbet', 'plt']
# subtitle:
# author:
# author_url:
---

Consider this snippet of Ruby code using Sorbet:

<!-- more -->

<figure class="left-align-caption">

```{.ruby .numberLines .hl-11}
# typed: true
extend T::Sig

sig do
  type_parameters(:U)
    .params(x: T.type_parameter(:U))
    .returns(T.type_parameter(:U))
end
def fake_identity_function(x)
  case x
  when Integer then return 0
  #                 ^^^^^^^^ error
  else return x
  end
end
```

<figcaption>
  [→ View on sorbet.run]()
</figcaption>

</figure>

It has the same signature as the identity function (which returns its argument unchanged), but doesn't actually do that in all cases. In particular, on the highlighted line it checks the type of `x` at runtime, and if it's an `Integer`, it always returns `0`, regardless of the input.

Sorbet flags this as an error (see the full error message in [the sorbet.run link][fake_identity_function]). Sometimes I get asked: "Why? The signature just says that the output has to be the same as the input, and `Integer` is the same as `Integer`."

[fake_identity_function]: https://sorbet.run/#%23%20typed%3A%20true%0Aextend%20T%3A%3ASig%0A%0Asig%20do%0A%20%20type_parameters%28%3AU%29%0A%20%20%20%20.params%28x%3A%20T.type_parameter%28%3AU%29%29%0A%20%20%20%20.returns%28T.type_parameter%28%3AU%29%29%0Aend%0Adef%20fake_identity_function%28x%29%0A%20%20case%20x%0A%20%20when%20Integer%20then%20return%200%0A%20%20else%20return%20x%0A%20%20end%0Aend

But thing about generic methods is that their signatures place stronger constraints on the implementation of the method—in this case the signature mandates that the result **value** is the input **value**, not just some other value with the same type.

The hand-wavy intuition for how to think about what's going on is to mentally read the `type_parameters(:U)` in the signature as "for all," specifically, "the behavior of this function is the same *for all* choices of the type parameters."

In that light, generics put a pretty hefty constraint on the implementation of a generic method—which is actually a good thing! It means that the caller of the method can make stronger guarantees about what the method can or cannot do, even seeing only the types. For example:

```ruby
sig do
  type_parameters(:U, :V)
    .params(x: T.type_parameter(:U), y: T.type_parameter(:V))
    .returns(T.any(T.type_parameter(:U), T.type_parameter(:V)))
end
```

From this signature we're guaranteed that the method has to return exactly one of the arguments we provided (`x` or `y`) and nothing else. It can't invent some third value and return that.

But the constraints come within reason: the types don't say anything about what side effects the function might have. This isn't particularly unique to generics (Sorbet doesn't track side effects in the types, regardless of whether it's a generic method), but it is worth noting as a sneaky way that methods can do different things with different arguments. Going back to our `fake_identity_function` example from earlier:

<figure class="left-align-caption">

```{.ruby .numberLines .hl-12 .hl-15}
# typed: true
extend T::Sig

sig do
  type_parameters(:U)
    .params(x: T.type_parameter(:U))
    .returns(T.type_parameter(:U))
end
def fake_identity_function(x)
  case x
  when Integer
    puts(x.even?)
    x
  else
    x.even? # error: Method `even?` does not exist
    x
  end
end
```

<figcaption>
  [→ View on sorbet.run](https://sorbet.run/#%23%20typed%3A%20true%0Aextend%20T%3A%3ASig%0A%0Asig%20do%0A%20%20type_parameters%28%3AU%29%0A%20%20%20%20.params%28x%3A%20T.type_parameter%28%3AU%29%29%0A%20%20%20%20.returns%28T.type_parameter%28%3AU%29%29%0Aend%0Adef%20fake_identity_function%28x%29%0A%20%20case%20x%0A%20%20when%20Integer%0A%20%20%20%20x.even%3F%0A%20%20%20%20x%0A%20%20else%0A%20%20%20%20x.even%3F%0A%20%20%20%20x%0A%20%20end%0Aend)
</figcaption>

</figure>

In this example, the side effect of calling `puts(x.even?)` only happens if the type is `Integer`, breaking the intuition that the behavior of this function is uniform for all input types.

If Sorbet wanted,[^1] it could prevent this particular form of anti-uniformity by not allowing any [control-flow-sensitive] type updates. But it wouldn't change the fact that, for example, one implementation of `fake_identity_function` could always print one log line, while another implementation could always print two log lines. The only uniformity guarantees we get are about specifically what's captured in the input and output types.

[^1]:
  Unlike everything we've discussed so far, I'm not actually sure whether that was a conscious decision or an accident. But it is a pretty useful feature in practice.

[control-flow-sensitive]: <https://sorbet.org/docs/flow-sensitive>

It turns out that there's a name for this property of generic functions: [parametricity]. It's a fancy word but it basically means what we've talked about here: the implementation of generic functions are constrained to basically only do one thing, modulo side-effects. It goes further than just intuition though, and people have done interesting work to formalize the intuitions into proofs.

[parametricity]: <https://en.wikipedia.org/wiki/Parametricity>
