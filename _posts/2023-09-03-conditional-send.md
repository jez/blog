---
# vim:tw=90
layout: post
title: "Ruby's Conditional Send is not Safe Navigation"
date: 2023-09-03T10:06:27-05:00
description: >
  A brief explanation of why Ruby calls x&.foo "conditional send" and not "safe navigation."
math: false
categories: ['ruby', 'javascript', 'programming']
# subtitle:
# author:
# author_url:
---

**tl;dr**: Ruby has a feature called "conditional send" which looks very similar to JavaScript's "safe navigation" feature. Their key difference is short circuiting evaluation: Ruby chooses not to short circuit, because there *are* methods on `nil`, unlike `undefined` in JS.

Let's dive into an example. You can do this in Ruby:

```ruby
invoice&.amount
```

which calls `.amount` if `invoice` is not `nil`, or else evaluates to `nil` (skipping the call). You can do something similar in JavaScript, just with `?` instead of `&`:

```js
invoice?.amount
```

In my experience, most people first learn this feature in JavaScript, where it's called "safe navigation," and they bring the name with them when learning Ruby.

In fact, the feature Ruby has is not safe navigation but something else, called **conditional send**.

There's a subtle difference, only noticeable in a longer chain:

```js
invoice?.amount.format()
```

```ruby
invoice&.amount.format()
```

- The JavaScript version short circuits the entire remaining expression. If `invoice` is falsy, the `.format()` method is not called, and the whole expression evaluates to `undefined`.

- Meanwhile Ruby does the opposite: if `invoice` is `nil`, Ruby evaluates `invoice&.amount` to `nil` and then keeps going. The call to `.format()` still happens, but the call happens on `nil` (which is probably a bug).

To completely reproduce the JavaScript behavior in Ruby, we need to keep chaining the `&`:

```ruby
invoice&.amount&.format
```

Most Ruby linters will check for this and require programmers to put `&` on all method calls downstream of the first conditional send.

Why the difference? Or rather: why doesn't Ruby do what JavaScript does?

In JavaScript it never makes sense to access a property on `undefined`: `undefined` does not have any properties, nor is it possible to add any.

But in Ruby, `nil` inherits from `Object` (and thus `Kernel` and `BasicObject`), which means it has all the methods available to all objects. For example:

- `is_a?`
- `nil?`
- `hash`
- `to_s`

But even more: Ruby lets users monkey patch more methods onto `nil`. Two common methods available on `nil` in codebases using Rails are `blank?` and `present?`.

So Ruby chooses not to short circuit. There are enough methods available on `nil` that it would be too restrictive to unconditionally short circuit and not allow any further method calls.

The names of both features reflect this choice:

- Safe navigation evokes an image of navigating with a map. If at some point the navigation takes you to the edge of a cliff, it's time to stop.

- Conditional send refers to the object-oriented notion that calling a method can be thought of as sending a message to an object. It's "conditional" because that message might not get sent, and this choice is made independently for every method call (or equivalently, for every message we might send).

Inside the Ruby VM, Sorbet, and Rubocop rules, the AST node representing `x&.foo` is named "csend." And now you know why.

