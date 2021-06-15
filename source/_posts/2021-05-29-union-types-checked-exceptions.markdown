---
# vim:tw=72
layout: post
title: "Sorbet Does Not Have Checked Exceptions"
date: 2021-05-29 01:21:41 -0700
comments: false
share: false
categories: ['ruby', 'sorbet', 'types']
description: "Sorbet does not support checked exceptions, and I don't think it ever should."
strong_keywords: false
fancy_blockquotes: true
---

Here's a common question I get asked about Sorbet:

> Does Sorbet support checked exceptions, like Java?

(In fact, this was the [first question] I was asked at my [first
conference talk].)

[first question]: https://youtu.be/odmlf_ezsBo?t=1921
[first conference talk]: https://jez.io/talks/state-of-sorbet-2019/

The answer: Sorbet doesn't support checked exceptions, and I don't think
it ever should.

<!-- more -->

Before I dive in, there are two pretexts I'm assuming: either you asked
this question and someone linked you this post, or the post title was
enough to catch your attention. Either way, I'm going to take for
granted that you know what I mean by "checked exceptions." If you want a
quick refresher, jump down to the [Appendix](#appendix) and then come
back.

My claim is that checked exceptions are a poor man's ad hoc union types,
that since Sorbet has ad hoc union types it doesn't need checked
exceptions. I'll discuss this claim in three parts:

- I'll give some background on what it means for union types to be "ad
  hoc," which applies to Sorbet's union types but are somewhat rare.
- I'll describe a translation from checked exceptions in Java to
  union-typed returns in Ruby with a concrete example.
- I'll give evidence for why the union types approach is better.

(If you want to skip straight to the good stuff, the analysis [is down
here](#analysis).)

## Background: Sorbet's union types

> The throws clause is the only point in the entire Java language that
> allows union types. You can tack "throws A,B,C" onto a method
> signature meaning it might throw A or B or C, but outside of the
> throws clause you cannot say "type A or B or C" in Java.
>
> — James Iry, *[Checked Exceptions Might Have Their Place, But It Isn't
> In Java][jamesiry]* (2012)

Sorbet supports [union types]. More specifically, Sorbet's union types
are ad hoc: any number of types can be unioned together on demand:

```ruby
sig {returns(T.any(A, B, C))}
def foo; ...; end
```

By contrast, many languages with union types require predeclaring a
union's variants, for example in Rust:

```rust
enum AorBorC {
    A(A),
    B(B),
    C(C),
}
```

That Sorbet allows defining union types on demand is similar to Java's
`throws` clause, but more powerful: `throws A, B, C` is not a type,
while `T.any(A, B, C)` is. We'll see why that matters below.

## Example: From checked exceptions to union types

Using Sorbet's ad hoc union types, it's mechanical to convert Java-style
checked exceptions to Sorbet-annotated Ruby. To demonstrate:

```java
Currency parseCurrency(String currencyStr) throws ParseException {
    Currency currency = KNOWN_CURRENCIES.get(currencyStr);
    if (currency == null) {
        throw new ParseException(
          "'" currencyStr + "' is not a valid currency", 0);
    }

    return currency;
}
```

This is a somewhat contrived Java method, but it'll be good enough to
demonstrate the concepts.

If `parseCurrency` is given a string it can't handle, it raises a
`ParseException`. It declares this with `throws` because
`ParseException` is a checked exception. If the currency string is
recognized, it returns some `Currency` object.

Here's how we'd write that in Sorbet:

```ruby
# (0) Ruby's standard library doesn't have `ParseException`,
# so I've re-implemented it.
class ParseError < T::Struct
  const :message, String
  const :offset, Integer
end

# (1) return type + `throws` becomes just `returns`
# (2) Return type uses `T.any`
sig do
  params(currency_str: String)
    .returns(T.any(Currency, ParseError))
end
def parse_currency(currency_str)
  currency = KNOWN_CURRENCIES[currency_str]
  if currency.nil?
    # (3) `throw` becomes `return`
    return ParseError.new(
      message: "'#{currency_str}' is not a valid currency",
      offset: 0
    )
  end

  currency
end
```

The important changes:

1. Where Java had a return type and a `throws` clause, Sorbet just has a
   return type.
1. Sorbet's return type is a union type (`T.any(...)`). It mentions the Java
   method's return type and all the exceptions mentioned in the `throws`.
1. Where the Java example uses `throw`, the Ruby example uses `return`.

Our translation isn't complete until we see how the `parseCurrency`
caller side changes. In Java, we call `parseCurrency` like this:

```java
Charge createCharge(int amount, String currencyStr) throws ParseException {
    Currency currency = parseCurrency(currencyStr);
    return new Charge(amount, currency);
}
```

With Sorbet, this snippet becomes:

```ruby
sig do
  params(amount: Integer, currency_str: String)
    .returns(T.any(Charge, ParseError))
end
def create_charge(amount, currency_str)
  currency = parse_currency(currency_str)
  return currency unless currency.is_a?(Currency)

  Charge.new(amount: amount, currency: currency)
end
```

As before, the `throws` clause in Java becomes a union-typed return in Ruby.

The new bit is the explicit `return ... unless ...`. Whereas uncaught
exceptions implicitly bubble up to the caller, return values only bubble
up if explicitly returned. This is a key benefit of the union types
approach, which brings us to our next section.

<h2 id="analysis">Analysis: Why the union types approach is better</h2>

To recap, Sorbet's union types are ad hoc, much in the same sense as the
classes mentioned in Java's `throws` clause. When converting from `Java` to
`Ruby`, a single, union-typed return takes the place of a separate return
type and `throws` clause.

First off, this translation preserves the best parts of checked
exceptions:

- A method's failure modes still appear in an **explicit, public API**.

  In both Java and Ruby, the method signature behaves as machine-checked
  error documentation.

- Ad hoc error specifications enable **low-friction composition**.

  In both Java and Ruby, if our method is the first to combine two
  methods with unrelated failure modes, there's no ceremony to
  predeclare that combination. Instead, we just mention one more class
  in the method's signature.

But this approach is not only as good, it's better, because:

- As a language feature, **union types are not special**.

  Union types are types. Like other types, we can store them in
  variables. We can factor common error recovery code into helper
  functions. We can map functions returning union types over lists. We
  can write type aliases that abbreviate commonly-grouped error classes.
  We can't do any of this with checked exceptions, and this is the most
  common complaint against them.

- Union types have **call-site granularity**, not method-body
  granularity.

  The union types approach forces a choice of how to handle errors at
  each call site. This is more robust in the face of changing code,
  because new call sites should not necessarily inherit the error
  handling logic of existing call sites. Just because one
  `ParseException` was uncaught and mentioned in the `throws` does not
  mean all of them should be.

And finally, let me get out ahead of some common counter arguments.

> The union types approach requires more typing at the call site!

Yep. But I've already counted this as a blessing, not a curse.

> But real-world Ruby code already uses exceptions!

Yep. But in Java too, the world is already split into checked and
unchecked exceptions. In both Java and Ruby, exceptions are a fact of
life, and you'll always need a way to deal with unexpected exceptions
(e.g., comprehensive tests, automated production alerting, etc.).

> With checked exceptions, I could handle all the failures at once!

That's true; with checked exceptions, it's easy to write a single
`catch` statement that handles all failures due to, say, a
`ParseException` in a whole region of code, avoiding the need for code
repetition.

The upshot is that with union types, we can just use functions. Take
everything in the `catch` body, put it in a helper function, and call it
at each call site.  This cuts down on duplication, and I already
mentioned how call-site granularity is a win.

## I love union types

That's pretty much it. Sorbet doesn't need checked exceptions, it
already has ad hoc union types.


- - - - -

<h2 id="appendix">Appendix: Checked Exceptions</h2>

As a quick refresher, [checked exceptions] are a feature popularized by
Java. The syntax looks like this:

```java
void doThing() throws MyException {
    // ...
}
```

The `throws` keyword is a part of the method's signature, just like
argument and return types. It declares that this method might throw
`MyException`.

Since it's a part of this method's signature the `throws` annotation
will be checked at all call sites (just like argument and return types).
A method containing calls to `doThing` must either `catch` all mentioned
exceptions or repeat any maybe-thrown-but-uncaught exceptions in its own
`throws` clause.

If a method throws multiple classes of exceptions, they can all be
listed:

```java
void doThing() throws MyException, YourException, AnotherException {
    // ...
}
```

The argument in favor of checked exceptions is that they're explicit and
machine-checked. Users don't have to guess at what a method might throw,
or hope that there's accurate documentation—all benefits shared by
static typing in general, which is a sympathetic goal.

Checked exceptions seem like a good feature on paper. In practice,
they're generally regretted. I'm nowhere near the first person to come
to this conclusion, so instead I'll link you to some previous
discussions:

- [The Trouble with Checked Exceptions][andershejlsberg], A Conversation
  with Anders Hejlsberg
- [Checked Exceptions Might Have Their Place, But It Isn't In
  Java][jamesiry], by James Iry
- [Vexing Exceptions], by Eric Lippert

(The last one isn't actually about checked exceptions: it's just about
exceptions and I like it, so I included it.)

Java has been copied and imitated for decades. Among all the features we
see other languages copy from Java, checked exceptions are absent.

[union types]: https://sorbet.org/docs/union-types
[checked exceptions]: https://en.wikibooks.org/wiki/Java_Programming/Checked_Exceptions
[trouble-typed-errors]: https://www.parsonsmatt.org/2018/11/03/trouble_with_typed_errors.html
[andershejlsberg]: https://www.artima.com/articles/the-trouble-with-checked-exceptions
[jamesiry]: http://james-iry.blogspot.com/2012/02/checked-exceptions-might-have-their.html
[Vexing Exceptions]: https://ericlippert.com/2008/09/10/vexing-exceptions/
