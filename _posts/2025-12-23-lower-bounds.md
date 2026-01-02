---
# vim:tw=90 fo-=tc
layout: post
title: "Why have lower bounds on generics?"
date: 2025-12-23T15:46:34-05:00
description: >
  Lower bounds expand the list of ways to create a value of that type. They behave similar to union types in that regard, but they fill a particular niche that only they can fill, relating to subtyping.
math: true
categories: ['sorbet', 'ruby', 'plt', 'types']
# subtitle:
# author:
# author_url:
---

What's the point of lower bounds on generic types? For a while, I took for granted that you may as well have lower bounds if you have upper bounds, but that otherwise they're mostly for academic symmetry, not something practical. After looking further, this is the best answer I can come up with:

- Lower bounds expand the list of **ways to create** a value of that type (like how upper bounds expand the list of things to do with a value of that type).

- Lower bounds are similar to **union types** in the same way that upper bounds are similar to intersection types. Thus, if a language has union+intersection types, it almost doesn't need bounds at all.

- Lower bounds allow for **richer subtyping relationships** than union types, while being more verbose in some cases.

# Lower bounds let you create

Here's a generic box that holds values that might be uninitialized:

```{.ruby .numberLines .hl-2 .hl-11}
class MaybeUninitBox
  Elem = type_member { {lower: NilClass} }

  sig { params(val: Elem).void }
  def initialize(val = nil)
    @val = val
  end

  sig { void }
  def unset!
    @val = nil
  end

  sig { returns(Elem) }
  def val = @val
end
```

The lower bound allows implementing the `unset!` method by writing `nil` into `@val`. Without the lower bound, Sorbet would report an error on line 11, saying that `NilClass` is not a subtype of `Elem`.

I've written in the past how [every type is defined by its intro and elim forms][intro-elim], namely that every type is defined by how you create values of a certain type (introduction forms), and which operations use those values (elimination forms). There's a satisfying duality, and I regret that people over index on defining a type's elim forms, forgetting to think about the intro forms.

[intro-elim]: /intro-elim/

The lower bound on `Elem` lets the implementation of `MaybeUninitBox` introduce a value of type `Elem` out of thin air. Without the lower bound, there would be no way for the implementation to create one if it were not explicitly given one by the caller.


\


`MaybeUninitBox` as implemented is kind of clunky. The fact that the box might be uninitialized leaks through to the element type itself: users must declare it nilable:

```{.ruby .numberLines .hl-7}
# What we want to write, but can't:
box = MaybeUninitBox[String].new
#                    ^^^^^^ ⛔️
# error: `String` is not a supertype of lower bound of `Elem`

# What we have to write instead:
box = MaybeUninitBox[T.nilable(String)].new
box.val # => T.nilable(String)
```

The `T.nilable(...)` on line 7 is redundant from the user's perspective: shouldn't `MaybeUninitBox` hide that as an implementation detail? We'd like to only say what the box stores when it's initialized.

This consequence is downstream of the fact that `nil` is not a member of all reference types in Sorbet. In a language like Scala, where `null` is a value of all reference types, things are a little cleaner at the call site:

```{.scala .hl-4}
class MaybeUninitBox[Elem >: Null](var value: Elem = null):
  def unset(): Unit = value = null

val box = MaybeUninitBox[String]()
println(box.value)
```

Of course, this terseness comes at the expense of the [billion dollar mistake](https://www.infoq.com/presentations/Null-References-The-Billion-Dollar-Mistake-Tony-Hoare/).

Sorbet can achieve the same terseness using union types, without needing to treat `nil` as a value of every type.

# Union types approximate lower bounds

The Sorbet docs call out how to [achieve something similar to upper bounds](https://sorbet.org/docs/generics#placing-bounds-on-generic-methods) on generic methods using intersection types, despite Sorbet not having syntax for bounds on generic methods. It works the other way too: you can approximate lower bounds with union types:

```{.ruby .numberLines .hl-2 .hl-6 .hl-11 .hl-18}
class MaybeUninitBox2
  Elem = type_member   # ← no bound

  sig { params(val: T.nilable(Elem)).void }
  def initialize(val = nil)
    @val = val
  end

  sig { void }
  def unset!
    @val = nil
  end

  sig { returns(T.nilable(Elem)) }
  def val = @val
end

box = MaybeUninitBox2[Integer].new
#                     ^^^^^^^ ✅
```

In this example, there are no bounds on `Elem`, and the (inferred) type of `@val` is `T.nilable(Elem)` (or explicitly: `T.any(NilClass, Elem)`, a union type). The implementation can still store `nil` into `@val` directly in the `unset!` method, like when we were using a lower bound. But unlike before, the constructor call omits the `T.nilable(...)` when providing the element typ.

We might then ask: what's the point of `lower` bounds at all? If we can always approximate them with union types, and it seems like they're actually _better_ in terms of usability, why would we ever want a lower bound?

\


# Lower bounds have richer subtyping

Lower bounds are more powerful than union types when it comes to subtyping. Let's see how that plays out if we tried to make this `MaybeUninitBox` ascribe to some `IBox` interface:

```ruby
module IBox
  interface!
  Elem = type_member

  sig { abstract.returns(Elem) }
  def val; end
end
```

`MaybeUninitBox`, the version that uses a lower bound, ascribes to this interface.

`MaybeUninitBox2`, the version that uses `T.nilable(Elem)` instead of a lower bound, has an incompatible override error if we try to implement this interface:

<figure class="left-align-caption">

```ruby
class MaybeUninitBox2
  include IBox
  # ...

  sig { override.returns(T.nilable(Elem)) }
  #                   ⛔️ ^^^^^^^^^^^^^^^
  #    Return type `T.nilable(Elem)` does not match
  #    return type of abstract method `IBox#val`
  #    Super method defined with return type `Elem`
  def val = @val
end
```

<figcaption>
[View full example on sorbet.run →](https://sorbet.run/#%23%20typed%3A%20true%0Aclass%20Module%3B%20include%20T%3A%3ASig%2C%20T%3A%3AHelpers%3B%20end%0A%0Amodule%20IBox%0A%20%20extend%20T%3A%3AGeneric%0A%20%20interface!%0A%20%20Elem%20%3D%20type_member%0A%0A%20%20sig%20%7B%20abstract.returns%28Elem%29%20%7D%0A%20%20def%20val%3B%20end%0Aend%0A%0Aclass%20MaybeUninitBox2%0A%20%20extend%20T%3A%3AGeneric%0A%20%20Elem%20%3D%20type_member%0A%20%20include%20IBox%0A%0A%20%20sig%20%7B%20params%28val%3A%20T.nilable%28Elem%29%29.void%20%7D%0A%20%20def%20initialize%28val%20%3D%20nil%29%0A%20%20%20%20%40val%20%3D%20val%0A%20%20end%0A%0A%20%20sig%20%7B%20void%20%7D%0A%20%20def%20unset!%0A%20%20%20%20%40val%20%3D%20nil%0A%20%20end%0A%0A%20%20sig%20%7B%20override.returns%28T.nilable%28Elem%29%29%20%7D%0A%20%20def%20val%20%3D%20%40val%0Aend%0A%0Abox%20%3D%20MaybeUninitBox2%5BInteger%5D.new%20%23%20%E2%9C%85%0A)
</figcaption>
</figure>

The return type in the implementation is **wider** than the return type of the interface, and that causes an error. Methods must have a return type that's the same or narrower to be a compatible override.

Thus you might be forced to use lower bounds instead of union types if you want both to create values of a type without having been given one first, and you want the thing you're building to fit into a pre-existing subtyping relationship.

\

# Lower bounds are common because of `fixed`

"I don't think I really care about that subtyping thing in practice, so I don't need lower bounds." Are you sure? Where I work, I see a lot of code that looks like this:

```{.ruby}
class AbstractMutator
  ModelType = type_member

  sig { abstract.returns(T::Class[ModelType]) }
  def self.model_class; end
end

class MyMutator < AbstractMutator
  ModelType = type_member { {fixed: MyModel} }

  sig { override.returns(T::Class[ModelType]) }
  def self.model_class = MyModel
end
```

This is a trick Sorbet encourages for anyone who needs to [reify generic types at runtime](https://sorbet.org/docs/generics#reifying-generics-at-runtime), and it's powered by lower bounds (though you can be forgiven for failing to notice at first).

The `fixed` bound on `ModelType` implicitly specifies an `upper` and `lower` bound, but it's the `lower` bound that allows returning `MyModel` from `model_class`. Without the lower bound, we wouldn't be able to introduce values of type `ModelType` (or in this case, `T::Class[ModelType]`), and thus we wouldn't be able to safely implement `model_class`.

\

# What about lower bounds on generic methods?

Here's the type of the `Array#+` method in Sorbet's RBIs:

```ruby
sig do
  type_parameters(:U)
    .params(arg0: T::Enumerable[T.type_parameter(:U)])
    .returns(T::Array[T.any(Elem, T.type_parameter(:U))])
end
def +(arg0); end
```

The idea is that the `Enumerable` to append to the current `Array` doesn't have to have a matching element type: Sorbet knows that the resulting element type will be the union of the old and the new.

Spiritually, this is the same as a type like this in Scala, which has syntax for lower bounds on generic methods:

```scala
def +[U >: Elem](arg0: Enumerable[U]): Array[U]
```

Union types are more intuitive, in my opinion. To understand the Scala example, you have to know that if `arg0` is passed a type unrelated to `Elem`, the inferred type for `U` **will be** the union type, by nature of how the inference constraint is solved. Scala 2 didn't have union types though, which is likely why it's so common to see lower bounds on methods there. With Scala's emphasis on immutable collection libraries, you'd never be able to widen the type with an immutable operation. That is, if you started with a `List[Nothing]` i.e. the empty list, you'd never be able to append `List[Int]` to it.

Note that even for method lower bounds, they're still defining an intro form. A type-correct implementation of the `+` method would be to return `this` (Scala's `self`), which has type `Array[Elem]`. The `[U >: Elem]` lower bound allows using `Array[Elem]` in a place where need `Array[U]` is required.

\

I have a more robust understanding of generic lower bounds now. They're the dual to upper bounds, so they're nice to have from a theoretical standpoint, but they also enable certain programming patterns, like being able to introduce values of a certain type, while retaining subtyping relationships via inheritance. If there's no inheritance at play, they've very similar to union types (just like how upper bounds are similar to intersection types), and they're virtually essential if you have subtyping but no union types.



\

\

# References

I first learned about the idea that union types approximate lower bounds in a footnote in [The Design Principles of the Elixir Type System](https://arxiv.org/pdf/2306.06391), by Castagna, et al.:

> We did not specify lower bounds since they are not frequently used and they can be encoded by union types, e.g., \(\forall(s \leq \alpha). \alpha \rightarrow \alpha \, \stackrel{\textrm{def}}{=} \, \forall(\alpha). (s \vee \alpha) \rightarrow (s \vee \alpha)\); upper bounds can be encoded, too, this time by intersections (e.g., \(\forall(s \leq \alpha \leq t). \alpha \rightarrow \alpha \, \stackrel{\textrm{def}}{=} \, \forall(\alpha). ((s \vee \alpha) \wedge t) \rightarrow ((s \vee \alpha) \wedge t)\), but their frequency justifies the introduction of a specific syntax.

I first learned about the limitation of using union and intersection types to approximate bounds from [_Programming with Union, Intersection, and Negation Types_](https://www.irif.fr/~gc/papers/set-theoretic-types-2022.pdf), by Castagna:

> Notice however that the form of bounded polymorphism we obtain by this encoding is limited, insofar as two bounded types maybe in a subtyping relation only if they have the same bounds, yielding a second-class polymorphism more akin to [Fun](https://doi.org/10.1145/6041.6042) (where [subtyping] is possible only for \(s_1 = s_2\)) than to [\(F_{\lt:}\)](https://doi.org/10.1006/inco.1994.1013) (which allows [subtyping] even for \(s_1 \neq s_2\)).

I learned about the prevalence of lower bounds in Scala from [_Programming in Scala_](https://www.artima.com/shop/programming_in_scala_5ed), by Odersky et al., which is honestly an incredible book for learning more about Sorbet, despite being entirely focused on Scala (which makes sense, given Sorbet's lineage, but also is a testament to how long the Scala community has been thinking about type-focused object-oriented programming).

> This shows that variance annotations and lower bounds play well together. They are a good example of type-driven design, where the types of an interface guide its detailed design and implementation. In the case of queues, it's likely you would not have thought of the refined implementation of enqueue with a lower bound. But you might have decided to make queues covariant, in which case, the compiler would have pointed out the variance error for enqueue. Correcting the variance error by adding a lower bound makes enqueue more general and queues as a whole more usable.

The example of lower bounds in the _Programming in Scala_ book includes this snippet, which elucidates a previous point I had [discovered myself](https://blog.jez.io/invariant-type-member-trick/), attributing the conclusion to _type-driven design_ leading to a design that is more general than it otherwise might have been.
