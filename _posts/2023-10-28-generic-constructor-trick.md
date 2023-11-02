---
# vim:tw=90 fo-=t
layout: post
title: "A trick for generic constructors in Sorbet"
date: 2023-10-28T16:09:02-04:00
description: >
  There's a bit of a clever trick with T.all and T.attached_class that allows Sorbet to infer better types for constructors of generic classes.
math: false
categories: ['ruby', 'sorbet']
# subtitle:
# author:
# author_url:
---

Sorbet does not infer generic types when constructing an instance of a generic class.

```ruby
set = Set.new([1])
T.reveal_type(set) # => T::Set[T.untyped]
```

You'd hope[^bug] that Sorbet would **either** report an error, requiring a type annotation instead of implicitly assuming `T.untyped` (like how other type annotations are required in `# typed: strict` files), **or** be smart enough to infer a suitable type from the provided arguments. Some day it will.

[^bug]:
  {-} This is a bit of a longstanding bug. See [#3768] and [#4450].

[#3768]: https://github.com/sorbet/sorbet/issues/3768
[#4450]: https://github.com/sorbet/sorbet/issues/4450

But in the mean time, if you want to build your own generic classes that **don't** suffer from this limitation, there's another way forward: defining a custom constructor with a clever signature.

The end solution is going to look something like this:

<figure class="left-align-caption">
```ruby
sig do
  type_parameters(:Elem)
    .params(val: T.type_parameter(:Elem))
    .returns(T.all(T.attached_class, Box[T.type_parameter(:Elem)]))
end
def self.new(val)
```
<figcaption>
[View final example on sorbet.run →][final-example]
</figcaption>
</figure>

But for that to make sense, let's build up to it.

# Recap of the problem

```{.ruby .numberLines .hl-5 .hl-6 .hl-12}
class Box
  extend T::Generic
  Elem = type_member

  sig { params(val: Elem).void }
  def initialize(val)
    @val = val
  end
end

box = Box.new(0)
T.reveal_type(box) # => Box[T.untyped]

box = Box[Integer].new(0)
T.reveal_type(box) # => Box[Integer]
```

If we naively define a generic `Box` class like this, `Box.new(0)` will neither report an error nor infer the correct `Box[Integer]` type. Users of our class can correct this themselves with `Box[Integer].new(0)`, but few people know to do this.

The problem here comes from Sorbet's default implementation of `Class#new`: by default, Sorbet uses only the type of the receiver to decide the result type. We can fix the problem by defining our own constructor as a **generic method** whose return type is inferred from the arguments.

# Defining a custom constructor

To fix, we can define our own constructor:[^new]

[^new]:
  {-} If you don't like overriding `Class#new`, the same tricks work with a custom constructor like `def self.make` which calls `self.new`. If you do this, you likely also want `private_class_method :new`.

```{.ruby .numberLines .hl-5 .hl-6 .hl-7 .hl-15}
class Box
  # ...

  sig do
    type_parameters(:Elem)
      .params(val: T.type_parameter(:Elem))
      .returns(Box[T.type_parameter(:Elem)])
  end
  def self.new(val)
    super
  end
end

box = Box.new(0)
T.reveal_type(box) # => Box[Integer]
```

Now the inferred type is `Box[Integer]` even though we didn't provide an explicit type annotation like `Box[Integer].new(...)`.

This signature is pretty good, but we can actually do better. This signature says that the result will **always** be a `Box`, even if called on subclasses of `Box`:

```{.ruby .numberLines .hl-6}
class ChildBox < Box
  # ...
end

box = ChildBox.new(0)
T.reveal_type(box) # => Box[Integer]
```

Notice that the `ChildBox.new` call produces a `Box`, because our override of `new` said "I always return `Box[...]`." We can fix that with clever use of `T.all` and `T.attached_class`.

# Handling subclasses with `T.all` and `T.attached_class`

<figure class="left-align-caption">

```{.ruby .numberLines .hl-7 .hl-20 .hl-21}
class Box
  # ...

  sig do
    type_parameters(:Elem)
      .params(val: T.type_parameter(:Elem))
      .returns(T.all(T.attached_class, Box[T.type_parameter(:Elem)]))
  end
  def self.new(val)
    super
  end
end

class ChildBox < Box
  # ...
end

box = Box.new(0)
T.reveal_type(box) # => Box[Integer]
box = ChildBox.new(0)
T.reveal_type(box) # => ChildBox[Integer]
```
<figcaption>
[View full example on sorbet.run →][final-example]
</figcaption>
</figure>

Now, calling `new` on a `Box` produces `Box[Integer]`, while `new` on a `ChildBox` produces `ChildBox[Integer]`.

How this works is that `T.attached_class` acts a little bit like `T.attached_class[_]`:[^syntax] it represents whatever the current attached class is (either `Box` or `ChildBox`), but knows nothing about the applied type arguments. Meanwhile, the `Box[T.type_parameter(:Elem)]` knows about the type arguments, but has an overly broad view of the class those arguments are applied to.

Combining everything with `T.all` asks Sorbet to collapse all the parts pairwise: pick the most specific class to apply arguments to, and pick the most specific of all the supplied type arguments.

[^syntax]:
  {-} This `[_]` syntax doesn't exist, but hopefully it's suggestive that in this case, `T.attached_class` actually stands for some generic type, because the attached class of `Box` **is** generic.

[final-example]: https://sorbet.run/#%23%20typed%3A%20true%0Aclass%20Module%3B%20include%20T%3A%3ASig%3B%20end%0A%0Aclass%20Box%0A%20%20extend%20T%3A%3AGeneric%0A%20%20Elem%20%3D%20type_member%0A%0A%20%20sig%20%7B%20params%28val%3A%20Elem%29.void%20%7D%0A%20%20def%20initialize%28val%29%0A%20%20%20%20%40val%20%3D%20val%0A%20%20end%0A%0A%20%20sig%20do%0A%20%20%20%20type_parameters%28%3AElem%29%0A%20%20%20%20%20%20.params%28val%3A%20T.type_parameter%28%3AElem%29%29%0A%20%20%20%20%20%20.returns%28T.all%28T.attached_class%2C%20Box%5BT.type_parameter%28%3AElem%29%5D%29%29%0A%20%20end%0A%20%20def%20self.new%28val%29%0A%20%20%20%20super%0A%20%20end%0Aend%0A%0Aclass%20ChildBox%20%3C%20Box%0A%20%20Elem%20%3D%20type_member%0Aend%0A%0Abox%20%3D%20Box.new%280%29%0AT.reveal_type%28box%29%20%23%20%3D%3E%20Box%5BInteger%5D%0Abox%20%3D%20ChildBox.new%280%29%0AT.reveal_type%28box%29%20%23%20%3D%3E%20ChildBox%5BInteger%5D%0A

