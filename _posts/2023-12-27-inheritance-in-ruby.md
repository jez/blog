---
# vim:tw=90 fo-=tc
layout: post
title: "Inheritance in Ruby, in pictures"
date: 2023-12-28T12:31:20-08:00
description: >
  A solid grasp of the tools Ruby provides for inheritance, like include and extend, helps write better code. But the concepts are often learned hastily—this post revisits them in depth.
math: false
categories: ['ruby', 'sorbet', 'types', 'in-pictures']
# subtitle:
# author:
# author_url:
---

A solid grasp of the tools Ruby has for inheritance helps with writing better code.[^esp]  On the other hand, when most people learn Ruby they learn just enough of what `include` and `extend` mean to get their job done (sometimes even less 🫣).

[^esp]:
  {-} Especially Ruby code typed with Sorbet where inheritance underlies things like abstract methods, interfaces, and generic types.

I'd like to walk through some examples of inheritance in Ruby and draw little diagrams to drive their meaning home. The goal is to have inheritance in Ruby "click."

# The `<` operator

Before we can get to what `include` and `extend` do, let's start with classes and superclasses.

```ruby
class Parent
  def on_parent; end
end

class Child < Parent
end

Child.new.on_parent
```

This is as simple as it gets. Most languages use the `extends` keyword to inherit from a class. Ruby cutely uses the `<` token, but otherwise it's very straightforward. When we call `on_parent` on an instance of `Child`, Ruby finds the right method to call by walking the inheritance hierarchy up to where that method is defined on `Parent`.

I picture Ruby's `<` operator as working something like this:

[^multiple]

[^multiple]:
  {-} Nerd alert: these diagrams will be ignoring multiple inheritance. To be more accurate we'd have to draw them showing that classes can have one parent class and multiple parent modules. But Ruby linearizes the hierarchy, so this conceptual model of "follow a single chain up" will be good enough. Multiple inheritance can be a future post.

![](/assets/img/light/inheritance-in-ruby/parent-child-class-instance.png){.center style="max-width:229px"}
![](/assets/img/dark/inheritance-in-ruby/parent-child-class-instance.png){.center style="max-width:229px"}

In particular, I picture classes like puzzle pieces. The pieces have tabs and blanks[^jigsaw] which allow other classes to slot in, forming an inheritance hierarchy.

[^jigsaw]:
  {-} "Tabs" and "blanks" are the [names Wikipedia uses] for these spots on jigsaw puzzles.

[names Wikipedia uses]: https://en.wikipedia.org/wiki/Jigsaw_puzzle#Puzzle_pieces

Checking whether a class is a subclass of another amounts to following the chain upwards. If you can reach `ClassB` from `ClassA`, then `a.is_a?(ClassB)`.

Method dispatch does the same up-the-chain search, stopping in each class to look for a method with the given name. Does `Child` have a method named `on_parent`? Nope, so let's go up and keep checking. Does `Parent`? Yep—let's dispatch to that definition.

**Here's the first wrench Ruby throws into the inheritance mix**: the `<` operator not only sets up a relationship between the classes themselves, it **also** makes the singleton class of `Child` inherit from the singleton class of `Parent`.

I'll show what I mean in code first:

```{.ruby .numberLines .hl-2 .hl-8 .hl-13}
class Parent
  def self.on_parent; end
end

class Child < Parent
end

Parent.new.on_parent # ❌
Parent.on_parent     # ✅
Child.on_parent      # ✅
```

Now the `on_parent` method is on the singleton class because of the `def self.` (compared with just `def` before). Since it's defined on the singleton class, it's only possible to call it on the class object itself, not on instances of the class. And more than that, it's available on the singleton class of `Child`, because the `<` operator **also** set up an inheritance relationship on the singleton classes.

Which means we need a slightly more involved picture to show what the `<` operator is doing, which I'll represent as this red/blue jigsaw piece:

![](/assets/img/light/inheritance-in-ruby/parent-child-class.png){.center style="max-width:466px"}
![](/assets/img/dark/inheritance-in-ruby/parent-child-class.png){.center style="max-width:465.5px"}

The `<` operator takes a normal class and a singleton class and links them up with another normal and singleton class, so we get two inheritance relationships for the price of one `<` token in our code.

We're going to work our way up to a full toolbox of these inheritance jigsaw pieces. As a sneak preview:

![](/assets/img/light/inheritance-in-ruby/inherit-include-extend.png){style="max-width:561.5px"}
![](/assets/img/dark/inheritance-in-ruby/inherit-include-extend.png){style="max-width:562px"}

Don't worry if that doesn't click yet, we'll get there. But first, a detour about why we even want the `<` operator to work like this in the first place.

\

# Wait, why do we care about inheriting both?

Ruby has a rich link between a class and its singleton class. The `<` operator just preserves this link across inherited classes. Let's unpack these observations.

In Ruby, singleton classes are first-class objects. You can pass them around and call methods on them just like any other object:

```ruby
class A; end

foo(A)
puts(A.name)
```

Not only are they first class, but it's seamless to reflect from an instance of a class up to the object's class:

```ruby
a.class # => A
```

To take it a step further: objects in Ruby are instantiated by calling `new`,[^new] a singleton class method:

[^new]:
  {-} In Ruby `new` is not a keyword, it's a normal method! (It's unlike the `new` keyword in C++ or Java.)

```ruby
class A; end
class B; end

def instantiate_me(klass)
  # instantiation is dynamic dispatch:
  klass.new
end
instantiate_me(A)
instantiate_me(B)
```

These two methods form an intrinsic link between a class and its singleton class. They power all sorts of neat code in the wild, too. For example [Sorbet's `T::Enum`][tenum] class looks something like this under the hood:

[tenum]: https://sorbet.org/docs/tenum

[^tenum]

[^tenum]:
  {-} This `TypedEnum` class is a simplification of Sorbet's `T::Enum`, which is more robust. But the full implementation fits in a [single file][enum.rb] if you're curious.

[enum.rb]: https://github.com/sorbet/sorbet/blob/07b23e6e421d3c182023ad4c220bfd65ebf8b482/gems/sorbet-runtime/lib/types/enum.rb#L42

```{.ruby .numberLines .hl-5 .hl-12}
class TypedEnum
  def self.values = @values ||= {}
  def self.make_value(string_name)
    return v if (v = values[string_name])
    self.new(string_name)
  end
  private_class_method :new, :make_value

  def to_s = @string_name
  def initialize(string_name)
    @string_name = string_name
    self.class.values[string_name] = self
  end
end
```

This `TypedEnum` class implements the typesafe enum pattern[^typedenum], which is a way of guaranteeing that there are only a fixed set of instances of a class, which can only be compared to values of the same enum (not unrelated enums).

[^typedenum]:
  {-} Popularized by Joshua Block in Effective Java, First Edition, Item 21, in response to the observation that much Java code would use magic integers to represent enumerations. (The same thing happens in Ruby, but with magic Symbols and Strings in addition to just Integers.)

You'd define an enum using this abstraction something like this:

```ruby
class Suit < TypedEnum
  CLUBS    = make_value("clubs")
  DIAMONDS = make_value("diamonds")
  HEARTS   = make_value("hearts")
  SPADES   = make_value("spades")
end
```

It's so concise in Ruby[^concise]  because of the special relationship between a class and its singleton class:

[^concise]:
  {-} "Concise" versus the original Java pattern. Sorbet's `T::Enum` makes the pattern even more concise.

![](/assets/img/light/inheritance-in-ruby/self-class-self-new.png){.center style="max-width:563.5px"}
![](/assets/img/dark/inheritance-in-ruby/self-class-self-new.png){.center style="max-width:563.5px"}

First, the implementation of `initialize` can reflect back up to the class with `self.class.values` to share information across all instances of a class.

Second, the singleton class method `make_value` calls `self.new`, which uses **dynamic dispatch** to instantiate an instance of whatever class `make_value` was called on (like `Suit` above). This dynamic dispatch only works because the `<` operator set up an inheritance relationship on the singleton class, too!

![](/assets/img/dark/inheritance-in-ruby/typed-enum-suit.png){style="max-width:738.5px"}
![](/assets/img/light/inheritance-in-ruby/typed-enum-suit.png){style="max-width:739px"}

Third, the `TypedEnum` class encapsulates all of the logic for what it means to be a typesafe enum. The `Suit` class has no implementation of its own, relying entirely on method resolution up the inheritance chain.

To recap: the cool part about attached classes and singleton classes and inheritance in Ruby is that there's this link between instance and singleton, via `self.class` and `self.new`. **This link is preserved** by having the `<` operator also create an inheritance relationship between singleton classes.

## Aside: `self.new` and `self.class` in the type system

My main focus here is to show how Ruby models inheritance, but now's a perfect time to sneak in a note about how Sorbet works.

Because this `self.new`/`self.class` link is so special, Sorbet captures it in the type level, as well:

```{.ruby .numberLines .hl-5 .hl-6 .hl-11 .hl-12}
sig do
  params(n: String).returns(T.attached_class)
end
def self.make_value(n)
  self.new(n)
# ^^^^^^^^^^^ T.attached_class (of TypedEnum)
end

sig { params(n: String).void }
def initialize(n)
  self.class
# ^^^^^^^^^^ T.class_of(TypedEnum)
end
```

If you call `self.new` inside of a singleton class method, the type that you get back is what's called `T.attached_class`. It's a weird name. People who use Ruby are very familiar with having the singleton class called the singleton class. They usually _don't_ have a name for this other class, but it's called the attached class: it's the name that the Ruby VM uses, and it's also the name that Sorbet uses.

Here's how to think about what this type means: it is _the_ type in Sorbet that exists to model what `new` does. It models the linkage from a singleton class back down to its attached class. And it respects dynamic dispatch:

```ruby
class Parent
  sig { returns(T.attached_class) }
  def make; self.new; end
end
class Child < Parent; end

parent = Parent.make  # => Parent
child =  Child.make   # => Child
```

There's only one definition of the `make` method, but the two calls to `make` above have different types. Sorbet knows that if `make` is called on `Parent`, the expression will have type `Parent`, and if called on `Child` will have type `Child`. That's the power of `T.attached_class`, and it's precisely the type that captures how `new` works.

In the opposite direction, `T.class_of(...)` is the type that represents following the link from the attached class up to the singleton class by way of `self.class`. It says, "Whatever class you are currently in, if you call `self.class` you will get `T.class_of(<whatever class you are currently in>)`."

For our `initialize` method defined in the `TypedEnum` class, `self.class` has type `T.class_of(TypedEnum)`. It's the name Sorbet uses for the singleton class—the Ruby VM would use the name `#<Class:TypedEnum>`, instead. Sorbet and the Ruby VM represent the concept of a singleton class with different names.

For more on these types, check out the Sorbet docs:

→ [`T.class_of`](https://sorbet.org/docs/class-of)\
→ [`T.attached_class`](https://sorbet.org/docs/attached-class)

But now let's get back to inheritance in Ruby.

\

# The `include` operator

So far we've only been talking about classes. Ruby also has modules, which are kind of weird.

```ruby
module IParent
  def foo; end
  def self.bar; end
end

class Child
  include IParent
end

Child.new.foo # ✅
Child.bar     # ❌
#
```

If we think of classes as both "a grouping of methods" and "the ability to make instances of that class," modules are _only_ the ability to group methods. You can't instantiate a module: you can only use them to make this little namespace for methods.

But we _can_ use those modules in inheritance chains. The instance method `foo` in our example above can be called on instances of `Child` because of how `include` works. But importantly: the singleton class method `bar` **cannot** be called on the class object `Child`, unlike with the `<` operator.

In picture form, `include` is a puzzle piece that only links up module instance methods with the child class:

![](/assets/img/light/inheritance-in-ruby/parent-child-include.png){style="max-width:466px"}
![](/assets/img/dark/inheritance-in-ruby/parent-child-include.png){style="max-width:465.5px"}

There's something shocking here: not only do we _not_ have a puzzle piece that links up the singleton class of the module into the singleton class of the child, **there isn't even a tab** on `T.class_of(IParent)`. It's smooth on the bottom. It is _not actually possible_ for a module's singleton class to be inherited. If we wanted to put a term to what's happening here: module singleton classes are **final**. They cannot be inherited.

That comes with some interesting consequences.

- It means a module's members are never inherited, so if you have this `self.bar` method, you are never going to be able to call it other than by calling it directly like `IParent.bar`.

  I say "members" because it's not just the methods: classes can have other kinds of members, most notably generic types, which I'll revisit in a future post. But importantly, those members are never inherited. Module singleton classes are final.

- It also has consequences for subtyping. When we look at the type `T.class_of(IParent)` which represents the singleton class of `IParent`, there is no type that is a subtype of that type. For example, `T.class_of(Child)` is a singleton class, but it is **not** a subtype of `T.class_of(IParent)`. In code:

  [^subtype_lt]

  ```ruby
  sig { params(klass: T.class_of(IParent)).void }
  def foo(klass); end

  foo(Child) # ❌
  ```

  You cannot call `foo(Child)` because the `Child` object has type `T.class_of(Child)` which is not a subtype of the parameter's type `T.class_of(IParent)`.

- And finally, having no extension point **breaks the link** between `self.new` and `self.class`.

  With a class's singleton and attached class pair, there would be a link via `self.class` and `self.new`. Modules do not have that—the singleton class is just, like, floating out in la la land. If a module instance method calls `self.class`, it's not clear which class that resolves to. If a module singleton method calls `self.new`, that will raise a `NoMethodError` exception at runtime.

[^subtype_lt]:
  {-} You don't even need to use Sorbet to show this point; you can observe the same thing by evaluating `p(Child < IParent)` and see that it's false.

Sometimes these limitations are fine: for example this does not matter for [the `Enumerable` module][enumerable] in the Ruby standard library, which deals entirely with instance methods. But sometimes they're not fine.

[enumerable]: https://ruby-doc.org/3.2.2/Enumerable.html#module-Enumerable-label-Usage

# The `extend` operator

We might think, "Okay, well maybe this is just what Ruby's extend is meant to fix! Maybe `extend` is the thing that preserves that link."

But no, even when using `extend` there's no way to get at the methods defined on the module's singleton class.

```{.ruby .numberLines .hl-10 .hl-11}
module IParent
  def foo; end
  def self.bar; end
end

class Child
  extend IParent
end

Child.new.foo # ❌
Child.foo     # ✅
Child.bar     # ❌ (still)
```


`extend` does something _else_, which is: if you `extend` a module, it still takes the instance methods (because that's the only extension point there is on modules), but it slots them into the child class's singleton class:

![](/assets/img/light/inheritance-in-ruby/parent-child-extend.png){.center style="max-width:525px"}
![](/assets/img/dark/inheritance-in-ruby/parent-child-extend.png){.center style="max-width:525px"}

In picture form, there's this weird half-red, half-blue puzzle piece that makes it so that
`IParent` is an ancestor of `T.class_of(Child)` instead of being an ancestor of `Child`. It exposes instance methods on the module as singleton class methods on `Child`.

What it definitely doesn't do is inherit the module's singleton class, because module singleton classes are final.

So that basically wraps up inheritance in Ruby:

![](/assets/img/light/inheritance-in-ruby/inherit-include-extend.png){style="max-width:561.5px"}
![](/assets/img/dark/inheritance-in-ruby/inherit-include-extend.png){style="max-width:562px"}

With classes, we have this puzzle piece which takes instance methods to instance methods and singleton class methods to singleton class methods. It's cool because it preserves that link between instance and singleton.

But with modules, **that link breaks down** and the only[^prepend] tools that we really have are `include` and `extend`, which only affect instance methods in the module.

[^prepend]:
  {-} You could argue these aren't the "only" tools because there's also `prepend`, but it doesn't act different from `include` with respect to this link.

# Wait, why do we care if modules don't work like classes?

It matters because sometimes a class already has a superclass. For example, every Ruby struct descends from the `Struct` class, every `activerecord` model in Rails descends from the `ActiveRecord::Base` class, etc. Sometimes we want to make reusable units of code that slot into any class, comprised of both instance and singleton class methods, that link up using `self.new` and `self.class`.

So what are we to do? What if we need a **mixin** that wants to mix in both instance and singleton class methods?

Well, one option is "just use two modules." This is gross, but it works:

```{.ruby .numberLines .hl-9 .hl-10}
module IParent
  def foo; end
end
module IParentClass
  def bar; end
end

class Child
  include IParent
  extend IParentClass
end

Child.new.foo # ✅
Child.bar     # ✅
```

By convention, we could say that `IParent` contains all the instance methods, and that `IParentClass` contains all the methods that are meant to be singleton class methods, and make sure _by convention_ that `IParentClass` is extended wherever `IParent` is included. So anyone who wants to use this `IParent` abstraction has to be sure to always mention two class names, one with `include` and one with `extend`.

That works—that makes both of these methods available, where `foo` is an instance method and `bar` is a singleton class method on `Child`.

If we look at the puzzle pieces again, include is doing one thing to one module, extend is doing something else to some other module, and if we squint it _kind_ of looks like our class inheritance puzzle piece?

![](/assets/img/light/inheritance-in-ruby/include-plus-extend.png){style="max-width:704px"}
![](/assets/img/dark/inheritance-in-ruby/include-plus-extend.png){style="max-width:704PX"}

But we still have two modules, and they're kind of just floating apart, unconnected to each other. It's clunky. It was nicer with `<`, where we just had a single puzzle piece that linked the attached and singleton classes.

# The `mixes_in_class_methods` annotation

As it turns out, Ruby allows _changing_ what `include` means.

I've already written about one tool which changes the meaning of `include`:

→ [ActiveSupport's `Concern`, in pictures](/concern-inheritance/)

_If you don't use Sorbet, you probably just want to skip the rest of this post, and continue reading that one instead._

For historical reasons that might make it into another post, Sorbet invents its own mechanism to achieve a result similar to `ActiveSupport::Concern` which it calls [`mixes_in_class_methods`]. The basic idea is to codify the "`include` + `extend`" convention from above:

[`mixes_in_class_methods`]: https://sorbet.org/docs/abstract#interfaces-and-the-included-hook

```{.ruby .numberLines .hl-8 .hl-12}
module IParent
  extend T::Helpers
  def foo; end

  module ClassMethods
    def bar; end
  end
  mixes_in_class_methods(ClassMethods)
end

class Child
  include IParent
end
```

Sorbet provides this `mixes_in_class_methods` annotation, and using it in a module _changes the meaning_ of `include` for the module with the annotation. The new meaning of `include` is twofold:

- The original `include` still happens like normal, so when `Child` has `include IParent` it will still inherit from `IParent`.

- But then **also**: the `include` will find the associated `ClassMethods` module and act as though that module was `extend`'ed on line 12. So `T.class_of(Child)` will descend from `IParent::ClassMethods`.

In a picture:

![](/assets/img/light/inheritance-in-ruby/mixes-in-class-methods.png){.center style="max-width:476.5px"}
![](/assets/img/dark/inheritance-in-ruby/mixes-in-class-methods.png){.center style="max-width:476.5px"}

We get this really wacky-shaped puzzle piece, where our two modules are still _kind of_ unrelated to each other, but they're at least closer together. It acts like an `include` and `extend` in one, but people don't have to mention the `extend`.

## Where `mixes_in_class_methods` falls short

So far so good except... it doesn't quite work the way you'd hope it might. The `mixes_in_class_methods` annotation is kind of dumb: it doesn't pay attention to whether the `include` happens into a class, or into another module. And if it happens into another module, it will still act like the `extend` was written _right there_:

```{.ruby .numberLines .hl-11 .hl-12}
  module IParent
    extend T::Helpers
    def foo; end
  
    module ClassMethods
      def bar; end
    end
    mixes_in_class_methods(ClassMethods)
  end

  module IChild; include IParent; end
# ^^^^^^
  class Grandchild; include IChild; end
```

The implicit `extend` happens on line 11, because `IParent` is the only class that has the `mixes_in_class_methods` annotation, and that's where `IParent` is included.

But that means that `T.class_of(Grandchild)` doesn't have `IParent::ClassMethods` as an ancestor, because `IChild` is a module, and module singleton classes are final:

![](/assets/img/light/inheritance-in-ruby/mixes-in-class-methods-into-module.png){.center style="max-width:469px"}
![](/assets/img/dark/inheritance-in-ruby/mixes-in-class-methods-into-module.png){.center style="max-width:468.5px"}

`T.class_of(IChild)` is a module's singleton class, which means it's final, and will never be an ancestor of anything.

**This is the biggest sharp edge** to be aware of about `mixes_in_class_methods`—modules defined this way can't have dependencies on each other. It's annoying.

When this comes up, one way to fix it is to just _not mention_ `mixes_in_class_methods` in the upstream dependencies, falling back to the explicit "`include` + `extend`" convention from before

```{.ruby .numberLines .hl-7 .hl-15 .hl-16 .hl-17 .hl-29 .hl-30 .hl-31 .hl-32}
module IParent
  def foo; end
  module ClassMethods
    def bar; end
  end

  # NO mixes_in_class_methods here
end

module IChild
  extend T::Helpers
  include IParent

  module ClassMethods
    # IParent doesn't have mixes_in_class_methods.
    # Need to manually include here.
    include IParent::ClassMethods
  end
  mixes_in_class_methods(IChild)
end

class Grandchild
  # Can still depend on `IChild` in the convenient
  # way, because it's at the bottom of the stack
  include IChild
end

class Child
  # IParent doesn't have mixes_in_class_methods.
  # Need to manually extend here.
  include IParent
  extend IParent::ClassMethods
end
```

The `IParent` module is upstream of the `IChild` module, so `IParent` doesn't use `mixes_in_class_methods`. Meanwhile `IChild` is not upstream of any other modules, so it's free to use `mixes_in_class_methods` like before.

Since `IParent` does not have `mixes_in_class_methods`, we have to fall back to our "convention-only" approach before. We see this on lines 17 and 32, where the `IParent::ClassMethods` have to be brought in manually.

But having done that, at least `T.class_of(Child)` now has the ancestor chain we were looking for, where `IParent::ClassMethods` is an ancestor:

![](/assets/img/light/inheritance-in-ruby/mixes-in-class-methods-include-class-methods.png){.center style="max-width:469px"}
![](/assets/img/dark/inheritance-in-ruby/mixes-in-class-methods-include-class-methods.png){.center style="max-width:469px"}

I should say: I consider this to be a wart in Sorbet's design.[^wart] When we look at [how `ActiveSupport::Concern` works](/concern-inheritance/), it' more like what you'd expect: it's a bit more recursive or viral about linking up the `ClassMethods` classes when stacking modules on top of modules. Hopefully simply being aware of this sharp edge in `mixes_in_class_methods` is enough for now.

[^wart]:
  {-} It's a long-term goal of mine to fix this one day, either by implementing support for `Concern` in Sorbet or even replacing `mixes_in_class_methods` with `Concern`.

\

# Inheritance in Ruby

Some things we learned in this post:

- It's cool that classes are first-class objects in Ruby.

- Being first-class means that it's easy to follow the link from a singleton class down to the attached class (with `self.new`) and back up (with `self.class`).

- Ruby's `<` operator for inheriting classes preserves this link, by making a class's singleton class descend from its parent's singleton class.

- That link breaks down for modules, because module singleton classes are final. No amount of `include` nor `extend` change that fact.

- It's possible to use modules to approximate class inheritance in Ruby, using `ClassMethods` modules either by convention or with things like `mixes_in_class_methods`.

- Sorbet's `mixes_in_class_methods` isn't as smart as Rails' `ActiveSupport::Concern` when it comes to mixing modules into other modules (but maybe one day will be).

It was only after internalizing these concepts that I started feeling _in control_ when working in Ruby codebases. Hopefully seeing things laid out this way makes you feel more in control as well.

\

\

- - - - -

# Appendix: Further reading

Some links that I think are pretty interesting and relate to the topics covered in this post:

- [Dynamic vs. Static Dispatch], by Lukas Atkinson

  A discussion of what we mean when we say dynamic dispatch or static dispatch, with a particular focus on C++, where even instance methods use static dispatch by default unless you explicitly use the `virtual` keyword.

- [Interface Dispatch], also by Lukas Atkinson

  A follow-up post discussing how multiple inheritance can be implemented under the covers, discussing implementation considerations in C++, Java, C#, Go, and Rust, and the tradeoffs that each makes in service of the flavor of multiple inheritance each chooses to support.

- [Versioning, Virtual, and Override: A Conversation with Anders Hejlsberg, Part IV], interview with Bruce Eckle and Bill Venners

  "Anders Hejlsberg, the lead C# architect, talks about why C# instance methods are non-virtual by default and why programmers must explicitly indicate an override."

- [Why doesn't Java allow overriding of static methods?], Stack Overflow answer by ewernli

  Classes do not exist as objects in Java. With `myObject.getClass()` you get only a "description" of the class, not the class itself. The difference is subtle.

- [Dynamic Productivity with Ruby: A Conversation with Yukihiro Matsumoto, Part II], another interview with Bill Venners

  "Yukihiro Matsumoto, the creator of the Ruby programming language, talks about morphing interfaces, using mix-ins, and the productivity benefits of being concise in Ruby."

- [Setting Multiple Inheritance Straight], by Michele Simionato

  "I have argued many times that multiple inheritance is bad. Is it possible to set it straight without loosing too much expressive power? My strait module is a proof of concept that it is indeed possible. Read and wonder ..."

[Dynamic vs. Static Dispatch]: https://lukasatkinson.de/2016/dynamic-vs-static-dispatch/
[Interface Dispatch]: https://lukasatkinson.de/2018/interface-dispatch/
[Versioning, Virtual, and Override: A Conversation with Anders Hejlsberg, Part IV]: https://www.artima.com/articles/versioning-virtual-and-override
[Why doesn't Java allow overriding of static methods?]: https://stackoverflow.com/questions/2223386/why-doesnt-java-allow-overriding-of-static-methods/2223408#2223408
[Dynamic Productivity with Ruby: A Conversation with Yukihiro Matsumoto, Part II]: https://www.artima.com/articles/dynamic-productivity-with-ruby#part2
[Setting Multiple Inheritance Straight]: https://www.artima.com/weblogs/viewpost.jsp?thread=246488

