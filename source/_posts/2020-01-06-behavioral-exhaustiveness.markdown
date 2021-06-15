---
layout: post
title: "behavioral-exhaustiveness"
date: 2020-01-06 22:17:11 -0600
comments: false
share: false
categories: 
description: 
strong_keywords: true
fancy_blockquotes: true
published: false
---

This post is going to be for the fans of exhaustiveness. Don't count yourself among that crowd? Maybe I can convince you with one of these other posts:

- [Case Exhaustiveness in Flow] – a bit of a tutorial for harnessing exhaustiveness in Flow.

- [Union Types in Flow & Reason] – a post selling exhaustiveness for use  in JavaScript UIs.

- [Exhaustiveness Checking in Sorbet] – in case you want a refresher on Sorbet syntax.[^sorbet-examples]

[^sorbet-examples]: I work on Sorbet; I'd like there to be more Sorbet content online! So I'll be using Sorbet for all the examples in this post.

So you're already sold on exhaustiveness. Given that, I'm going to try to expand your perspective a little bit, because I think that most discussions of exhaustiveness only see half the picture. Let's start off with the half of the picture we're familiar with.

## Structural exhaustiveness

Consider that you're in the business of [processing invoices]; you'd need some code that might look like this to represent an invoice in the database:

[processing invoices]: https://stripe.com/billing

```ruby
class Invoice < T::Struct
  class State < T::Enum
    enums do
      Drafted = new
      Opened = new
      Paid = new
      Voided = new
    end
  end

  # The field on our model tracking which state
  # this invoice is in, governing which actions
  # are ok to take
  prop :state, State

  # ... some other props, not important ...
end
```

We'd interact with these invoices all over the place doing things like this:

```ruby
sig do
  params(state: Invoice::State)
  .returns(T::Array[Invoice::State])
end
def valid_next_states(state)
  case state
  when Invoice::State::Drafted then [Invoice::State::Opened]
  when Invoice::State::Opened  then # ...
  when Invoice::State::Paid    then # ...
  when Invoice::State::Voided  then # ...
  else
    # This is the part that guarantees we covered all cases:
    T.absurd(state)
  end
end
```

<a href="#TODO">→ View full example on sorbet.run</a>

This is a surefire recipe for exhaustiveness:

- Enumerate all possible *representations* of some structure. In our case, the state an invoice is in is represented by one of four enum values. These representations are concrete structures, which really exist at runtime.

- In our methods, Sorbet checks that we've handled all possible representations. This usually involves some sort of control-flow analysis.[^tabsurd]

[^tabsurd]: In Sorbet, `T.absurd` is that control flow construct, and under the hood it works *because* Sorbet implements a control-flow-sensitive type system. Other languages build out a special control flow construct to support exhaustiveness: **pattern matching**, which is usually powered by some sort of decision tree or pattern compiler.

More specifically, this is the recipe for what I call **structural exhaustiveness**. It's exhaustiveness by covering all the cases of a concrete structure. The thing is: not all exhaustiveness is structural!

## Behavioral exhaustiveness

Here's another way we could have written that program from before. First, there'd be an interface representing the notion of an invoice state, with methods for all the actions we might want to take:

```ruby
module Invoice::State
  extend T::Helpers
  interface!

  sig {abstract.returns(T::Array[Invoice::State])}
  def valid_next_states; end
end
```

And for each state, there's a class that implements all the methds from that interface:

```ruby
class Invoice::Drafted
  include Invoice::State

  sig {override.returns(T::Array[Invoice::State])}
  def valid_next_states; [Invoice::State::Opened]; end
end

# These cases look the same: include our interface
# and implement the abstract method.
class Invoice::Opened; ...; end
class Invoice::Paid;   ...; end
class Invoice::Voided; ...; end
```

<a href="#TODO">→ View full example on sorbet.run</a>

This example completely flips things around, but there's still exhaustiveness: by having each class implement the interface, Sorbet will error if we forgot to implement `valid_next_states` for any of the invoice states, for example:

```ruby
class Invoice::Opened # error: Missing definition for abstract method `valid_next_states`
  include Invoice::State
end
```

I call this form of exhaustiveness **behavioral exhaustiveness**, because the receipt for using it revolves around behaviors:

- First, we declare all the *behaviors* we care about. In this example, there's only one: how an invoice state behaves when asked for the `valid_next_states`.

- Then, Sorbet checks that all the behaviors have been implemented on all the subclasses.



<!-- vim:tw=72
-->
