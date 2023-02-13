---
# vim:tw=0
layout: post
title: "Problems typing equality in Ruby"
date: 2023-01-24T16:12:15-05:00
description:
  "TypeScript has this really handy error that flags when it looks like two values of unrelated types are getting compared. I would love to build the same error into Sorbet, but there are two features which make that hard: custom overrides of `==` and subtyping. Here are some heuristics we might consider building in Sorbet, and why they don't work."
math: false
categories: ['sorbet', 'types', 'ruby']
# subtitle:
# author:
# author_url:
---

TypeScript has this really handy error that flags when it looks like two values of unrelated types are getting compared:

<figure class="left-align-caption">

```{.typescript}
function f(x: number, y: string) {
  if (x === y) {
    //  ^^^ error: This comparison appears to be unintentional because
    //             the types 'number' and 'string' have no overlap.
    console.log(x, y);
  }
}
```

<figcaption>
[View in TypeScript Playground →](https://www.typescriptlang.org/play?#code/GYVwdgxgLglg9mABMAFADwFyLCAtgIwFMAnAGkQE8sBnKYmMAcwEpEBvAKEURmEXUQBeYZVadu3CAmpwANoQB0suI3TkKzANxdEAXw66gA)
</figcaption>

</figure>

I would love to build the same error into Sorbet, but there are two features which make that hard: custom overrides of `==` and subtyping. Here are some heuristics we might consider building in Sorbet, and why they don't work.

# Heuristic 1

> Reject all calls to `==` when the operand types don't overlap.

The problem: Ruby equality methods make liberal use of implicit type conversions and other tricks. Some examples in the standard library:

- `Array`, `Hash`, and `String` allow the right operand to implement a method (`to_ary`, `to_hash`, or `to_str`, respectively) that gets called implicitly on arguments whose type does not match the receiver.

- In addition to implicit conversions, most numeric types (for example, `Integer` and `Float`) will call `other == self` whenever `self == other` initially returns `false`. Here's an example:

  ```{.ruby}
  class A
    def ==(other)
      other.is_a?(A) || other == 0
    end
  end

  p(0 == A.new) # => true
  ```

  This allows classes like `Process::Status`[^ps] in the standard library to be compared interchangeably with `Integer`.

[^ps]:
  {-} In one sense, it's neat: you can have methods like `status.success?` without monkey patching `Integer`, and while still allowing code like `0 == status`.

Library and application authors pattern their code off of precedents set in the standard library. Implicit conversions like these surface throughout real-world Ruby code.

# Heuristic 2

> Reject all calls to `==` when the operand types don't overlap, as long as the types being compared don't have a custom `==` method.

Maybe we pessimistically assume that **any** override of `==` might do something wacky. In response, we could limit the check to calls on types that don't override `BasicObject#==`.

First of all, that's almost crippling on its own! When `==` isn't overridden it defaults to reference equality, but people use `==` most often to compare structures, not references! Ruby provides `equal?` for reference equality—seeing a call to `==` (not to `equal?`) is a strong indicator that the author doesn't want reference equality.

Even if we were satisfied with how limiting this heuristic is, it's still not enough, this time because of subtyping:

```{.ruby .numberLines .hl-2 .hl-3 .hl-9}
class Foo; end
class FooChild < Foo
  def ==(other); true; end
end
class Bar; end

sig {params(x: Foo, y: Bar).void}
def example(x, y)
  if x == y
    p(x, y)
  end
end
```

In this case, `Foo` and `Bar` do not overlap[^interface] `Foo` does not override `==`. Unfortunately that says nothing about what subclasses of `Foo` might do. In this example, `Foo` has a subclass called `FooChild` with a custom override that misbehaves. (I've made it always return `true` for simplicity, but you can just as well imagine it doing some sort of implicit conversion.) Thus, subtyping has defeated our heuristic.

[^interface]:
  {-} Note that `Foo` and `Bar` do not overlap because they are classes. If one of them had been a module, [they would overlap], also defeating the equality check.

[they would overlap]: https://sorbet.org/docs/intersection-types#understanding-how-intersection-types-collapse

If the left operand had been [`final!`] Sorbet could rule out caveats like this, but then our heuristic would be so limited as to be surprising: few classes are `final!`, and few classes which rely on `==` do so for reference equality. Someone may see this class of error once, assume it applies more widely than it does, and then be shocked when a problem sneaks past the check.

[`final!`]: https://sorbet.org/docs/final

# Heuristic 3

> Add custom logic for `==` which knows about the implicit conversions specific standard library classes do.

Maybe trying to be as general as possible is the wrong approach? We could try picking only a few important classes in the standard library and special case the check for those types.

For example,[^symbol] if we pretend that `Symbol` is final (it's not but maybe we pretend anyways), we could require that the right operand's type overlaps with `Symbol`, catching attempts to compare for equality against `String` (super common).

[^symbol]:
  {-} This is not merely an example—this is the approach we've implemented it [here][6649].

[6649]: https://github.com/sorbet/sorbet/pull/6649

This only gets us as far as types that don't do implicit conversions. For a type like `String`, even though we know it allows comparisons against "anything that defines `to_str`" and Sorbet can look up whether such a method exists during inference, subtyping once again gets in our way:

```{.ruby .numberLines .hl-2 .hl-3 .hl-8}
class AbstractParent; end
class Child < AbstractParent
  def to_str; ""; end
end

sig {params(x: String, y: AbstractParent).void}
def example(x, y)
  if x == y
    p(x, y)
  end
end
```

In the comparison of `String` and `AbstractParent`, the types don't overlap **and** `AbstractParent` doesn't implement `to_str`. But `Child` does, which defeats the heuristic.

Sorbet could both assume `String` is `final!` **and** check that the right operand is `final!`, and then implement the check (the last time subtyping got in our way, it was only with the left operand). Adding one more constraint makes this heuristic even less useful and more surprising than the previous.

# A manual approach?

Maybe I'm a zealous Sorbet user who acknowledges that the problem can't be solved for every class. I still want to report an error whenever one of my classes is compared using `==` on mismatched types—can I take the problem into my own hands? It's technically as simple as adding a signature:

```{.ruby .numberLines .hl-1 .hl-6}
class A < T::Struct
  extend T::Sig

  const :val, Integer

  sig {params(other: A).returns(T::Boolean)}
  def ==(other)
    case other
    when A then self.val == other.val
    else false
    end
  end
end
```

The signature requires that `other` has type `A`. Done! Well, this fixes the immediate problem (`x == y` reports an error if `y` is an `A`), but it causes two of its own.

First, this is technically an incompatible override (see [A note on variance] for more). As it happens, Sorbet silences the error because the RBI definition for `BasicObject#==` is not marked `overridable`.[^overridable] Maybe you declare "ignorance is bliss," ignore the voice telling you that all incompatible overrides are bad, and blaze ahead.

[A note on variance]: https://sorbet.org/docs/override-checking#a-note-on-variance

[^overridable]:
  {-} At this point, marking it overridable would be a backwards incompatible change, requiring existing `==` signatures to start mentioning `override`, likely with no benefit.

This leads to our second problem, heterogeneous collections.

```{.ruby .numberLines .hl-1}
sig {params(xs: T::Array[T.any(Integer, A)]}
def example(xs)
  xs.include?(0) # 💥
end
```

Ruby's `include?` method calls `==` under the hood. Even if the program never mentions a literal call to `==` with `A` and `Integer`, it still might happen indirectly by way of `include?` if `xs` has any `A` values in it. But now instead of returning `false`, the `sig` on our `A#==` method will raise an exception!

That's a problem.[^runtime] To fix it, we could try marking the `sig` with `checked(:never)`, but then Sorbet's dead code checking would prevent us from handling other types in our method body.

[^runtime]:
  {-} You might be tempted to think of this as an indictment of [runtime checking], but I don't. In my opinion, this is the runtime type system flagging a real problem (incompatible override) which the static type system couldn't catch because of gradual typing.

[runtime checking]: /runtime-type-checking/

Another attempted fix might be to use an overloaded signature. These aren't allowed outside of standard library signatures, but here's what would happen if they were:

<figure class="left-align-caption">

```{.ruby .numberLines .hl-6 .hl-7 .hl-16}
class A < T::Struct
  extend T::Sig

  const :val, Integer

  sig {params(other: A).returns(T::Boolean)}
  sig {params(other: BasicObject).returns(FalseClass)}
  def ==(other)
    case other
    when A then self.val == other.val
    else false
    end
  end
end

sig {params(x: A, y: T.nilable(A)).void}
def example(x, y)
  if x == y
    p(x, y)
  end
end
```

```
editor.rb:19: This code is unreachable https://srb.help/7006
    22 |    p(x, y)
            ^^^^^^^
    editor.rb:18: This condition was always `falsy` (`FalseClass`)
    21 |  if x == y
             ^^^^^^
  Got `FalseClass` originating from:
    editor.rb:18:
    21 |  if x == y
             ^^^^^^
Errors: 1
```

<figcaption>
[View on sorbet.run →](https://sorbet.run/#%23%20typed%3A%20__STDLIB_INTERNAL%0Aextend%20T%3A%3ASig%0A%0Aclass%20A%20%3C%20T%3A%3AStruct%0A%20%20extend%20T%3A%3ASig%0A%0A%20%20const%20%3Aval%2C%20Integer%0A%0A%20%20sig%20%7Bparams%28other%3A%20A%29.returns%28T%3A%3ABoolean%29%7D%0A%20%20sig%20%7Bparams%28other%3A%20BasicObject%29.returns%28FalseClass%29%7D%0A%20%20def%20%3D%3D%28other%29%0A%20%20%20%20case%20other%0A%20%20%20%20when%20A%20then%20self.val%20%3D%3D%20other.val%0A%20%20%20%20else%20false%0A%20%20%20%20end%0A%20%20end%0Aend%0A%0Asig%20%7Bparams%28x%3A%20A%2C%20y%3A%20T.nilable%28A%29%29.void%7D%0Adef%20example%28x%2C%20y%29%0A%20%20if%20x%20%3D%3D%20y%0A%20%20%20%20p%28x%2C%20y%29%0A%20%20end%0Aend)
</figcaption>

</figure>

The overloaded signature specifies that if `other` is `A` the comparison happens, but if `other` is any other type, the method returns `FalseClass`. The resulting errors aren't quite as obvious: errors now show up indirectly as dead code errors, rather than something descriptive at the point of the problem. It's unclear whether hard-to-understand errors are better than no errors.

However, Sorbet's overload resolution doesn't work well with these signatures.[^decompose] `T.nilable(A)` is not a subtype of `A`, causing Sorbet to apply the `BasicObject` overload. This means Sorbet ascribes `FalseClass` to `res`, which is wrong when `y` is non-`nil` at runtime.

[^decompose]:
  {-} Writing this post made me wonder if Sorbet _should_ do something smarter here, like try to decompose the argument type and combine all the overloads that apply to each component. But that's getting into territory where I can't think of any prior art, which sets off my ⚠️ bad idea ⚠️  radar. (For example, TypeScript behaves like Sorbet when porting the above example.)

All of this leads me to the conclusion that not only have we failed to add heuristics to Sorbet to solve this, it's not even really practical for users to take the problem into their own hands.

\

\

It's an unfortunate state of affairs, and one that we likely can't fix. The best advice I can offer is just to be aware of this and try to write thorough tests. Like I mentioned above, the approach we'll likely have to take is insert ad hoc checks for specific standard library classes that are subclassed infrequently in practice and that do no implicit conversions. It will be possible to create false positives errors, and we'll have to live with that.

- - - - -

# Appendix: What do other languages do?

Some languages require that for two things to be equal, their types must always be the same. For example, in Haskell the `Eq` type class only provides a function of type `(Eq a) => a -> a -> Bool`. All the occurrences of `a` in that signature force the left and right operands of `==` to have matching types.

Other languages say that the two operands' types must be the same by default, but allow opting into comparisons between other types explicitly. This is how both Rust ([example](https://doc.rust-lang.org/std/cmp/trait.PartialEq.html#how-can-i-compare-two-different-types)) and C++ work.

Java has basically all the same problems as Sorbet faces with Ruby. `java.lang.Object` implements `equals` by default for all classes and its argument takes another `Object`. The wild thing to me is that the Java designers must have been aware of the way other typed languages handled equality—it's not like Java takes this approach because it started from an untyped language! C++ had operator overloading powering `==` all the way back in the 80s, well before Java appeared (to say nothing of Haskell or ML languages).

Mypy implements behavior like TypeScript, but it's behind a `--strict-equality` flag. It suffers the [same problems as above](https://github.com/python/mypy/issues/14410) because it has overridable `__eq__` methods and subtyping, but the maintainers have made the call that since individual projects can choose to opt in and since implicit conversions are more rare in Python, the problems are tolerable.

Flow implements the same check that TypeScript does, but only for `==` not for `===` (from my limited poking).
