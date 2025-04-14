---
# vim:tw=90 fo-=tc
layout: post
title: "Typing instance variables in mixins"
date: 2025-04-14T17:09:03-04:00
description: >
  Sorbet does not (yet?) have "abstract instance variables" for use inside abstract
  modules, but abstract methods are a close approximation.
math: false
categories: ['ruby', 'sorbet']
# subtitle:
# author:
# author_url:
---

**Problem**: you're using Sorbet, and there's a module or interface whose implementation depends on an instance variable having been initialized by the class that it's eventually mixed into.

**Solution**: make the interface depend on an abstract method instead (not an instance variable). Replace references of the instance variable in the module with the abstract method, and implement the abstract method by producing the instance variable.

# Setup

Let's say we've got some code like this, modeling a hierarchy of different kinds of users:

```{.ruby .numberLines .hl-14}
class User
  def initialize(user_id)
    @user_id = user_id
  end
end

class RegularUser < User; end
class AdminUser
  include Auditable
end

module Auditable
  def with_audit_log(action)
    puts("user=#{@user_id} starting action #{action}")
    yield
  end
end
```

We might want to make a `with_audit_log` helper method that we include in certain kinds of users that will do a lot of auditable actions. In that module we know that the `@user_id` method exists (because we're only going to include it in contexts where it exists), but Sorbet doesn't know that.

# Solution

Sorbet does not have a concept of abstract instance variables.[^1] To work around this, we need to:

1. define an abstract method for the instance variable
1. update usages of the instance variable to the method
1. implement the abstract method

This way Sorbet can check that all the required information is present every time we include the module somewhere.

<figure class="left-align-caption">

```{.ruby .numberLines .hl-5 .hl-6 .hl-9 .hl-16}
module Auditable
  extend T::Helpers
  abstract!

  sig { abstract.returns(UserID) }  # (1)
  private def user_id; end

  def with_audit_log(action)
    puts("user=#{user_id} starting action #{action}")  # (2)
    yield
  end
end

class User
  # ...
  private attr_reader :user_id   # (3)
end
```

<figcaption>
[View full example on sorbet.run →](https://sorbet.run/#%23%20typed%3A%20strict%0Aclass%20Module%3B%20include%20T%3A%3ASig%3B%20end%0A%0Aclass%20UserID%3B%20end%0A%0Aclass%20User%0A%20%20sig%20%7B%20params%28user_id%3A%20UserID%29.void%20%7D%0A%20%20def%20initialize%28user_id%29%0A%20%20%20%20%40user_id%20%3D%20user_id%0A%20%20end%0A%0A%20%20sig%20%7B%20returns%28UserID%29%20%7D%0A%20%20attr_reader%20%3Auser_id%0A%20%20private%20%3Auser_id%0Aend%0A%0Amodule%20Auditable%0A%20%20extend%20T%3A%3AHelpers%0A%20%20abstract!%0A%0A%20%20sig%20%7B%20abstract.returns%28UserID%29%20%7D%0A%20%20private%20def%20user_id%3B%20end%0A%0A%20%20sig%20do%0A%20%20%20%20type_parameters%28%3AU%29%0A%20%20%20%20%20%20.params%28%0A%20%20%20%20%20%20%20%20action%3A%20String%2C%0A%20%20%20%20%20%20%20%20blk%3A%20T.proc.returns%28T.type_parameter%28%3AU%29%29%0A%20%20%20%20%20%20%29%0A%20%20%20%20%20%20.returns%28T.type_parameter%28%3AU%29%29%0A%20%20end%0A%20%20def%20with_audit_log%28action%2C%20%26blk%29%0A%20%20%20%20Kernel.puts%28%22user%3D%23%7Buser_id%7D%20starting%20action%20%23%7Baction%7D%22%29%0A%20%20%20%20yield%0A%20%20end%0Aend%0A%0Amodule%20NotAUser%20%23%20error%3A%20Missing%20definition%20for%20abstract%20method%0A%20%20include%20Auditable%0Aend)
</figcaption>

</figure>

When we include this into the `AdminUser` class, Sorbet knows that the `user_id` method exists, because it came from the parent `User` class—no change to `AdminUser` is required, because [Sorbet allows implementing abstract methods via inheritance](https://sorbet.org/docs/abstract#letting-abstract-methods-be-implemented-via-inheritance).

If someone attempts to include this interface somewhere else, Sorbet will report an error:

```ruby
module NotAUser # error: Missing definition for abstract method
  include Auditable
end
```

**Note**: the `user_id` methods are `private`, which prevents people from calling it directly. That mimics how instance variables work (private methods and instance variables have the same visibility rules). This is optional: if you'd like the method to be public, make it public.

# Worse alternatives

There are some worse ways to solve this problem, and I want to take the time to point them out and also why they aren't as good.

## Declaring the instance variable's type with T.let

Something like this can be tempting:

```ruby
module Auditable
  sig { returns(UserID) }
  private def user_id
    @user_id ||= T.let(@user_id, T.nilable(UserID))
    T.must(@user_id)
  end

  def with_audit_log(action)
    puts("user=#{user_id} starting action #{action}")
    yield
  end
end
```

In this example, we use `||= T.let` to declare `@user_id` to `@user_id`, relying on the fact that instance variables that have not yet been assigned will evaluate to `nil`.

This is worse because Sorbet does not allow instance variables to be declared non-`nil` outside of the constructor—the abstract method approach allows declaring non-`nil` types.

## Using `requires_ancestor`

First off, the [experimental `requires_ancestor` feature](https://sorbet.org/docs/requires-ancestor) only applies to methods, not instance variables.

Even if that were changed, `requires_ancestor` is **anti-modular**: if you ever want to use the interface with some *other* ancestor that provides a `user_id` , you'd need to edit the definition of `Auditable` to mention both `T.any(User, ThatOtherClass)`.

In some sense, using abstract methods like this achieves a sort of duck typing. It doesn't matter which class provides the method: as long as it's called `user_id` and it has the right type, this module can be mixed into anything.

(Ultimately, `requires_ancestor` itself is experimental because the approach itself is problematic.)

# Appendix: What about "self-contained" instance variables?

If the module defines its own instance variables, e.g. for the purpose of caching some sort of state, there should be no problem. Just use `||=` like normal:

```ruby
sig { returns(Integer) }
def foo
  @foo ||= T.let(compute_foo, T.nilable(Integer))
end
```

(Things only get problematic when a module expects an instance variable to have already been set outside of its own logic.)

Note that in this case, as long as `compute_foo` returns `Integer`, the `foo` method can also return `Integer` without needing `T.must`—Sorbet knows that if the value is `nil`, it will be computed with `compute_foo`, so the method unconditionally returns a non-`nil` value.

[^1]:  This is mostly for simplicity—I'm not aware of any appeal to soundness why it could not gain them one day. Many other object-oriented languages do not make a distinction between methods and instance variables. For example, Scala traits can have abstract `val` declarations the same as it can have abstract `def` declarations.
