---
# vim:tw=90
layout: post
title: "ActiveSupport's Concern, in pictures"
date: 2023-08-26T15:43:12-04:00
description: >
  A series of pictures which show how Rails's ActiveSupport::Concern works to redefine
  what inheritance means in Ruby.
math: false
categories: ['ruby', 'in-pictures']
# subtitle:
# author:
# author_url:
---

I spent some time digging into Rails' [`ActiveSupport::Concern`] module. How it behaves
surprised me a little bit, so I figured I'd write up what I learned.

[`ActiveSupport::Concern`]: https://api.rubyonrails.org/classes/ActiveSupport/Concern.html

<!-- more -->

:::{.note .blue}

------
ℹ️ If you only have a shaky understanding of `include` and `extend` in Ruby, you might want to [start with this post first], which takes a deep dive into Ruby's built-in tools for inheritance.
------

:::

[start with this post first]: /inheritance-in-ruby/

Consider this snippet, using plain Ruby inheritance features:

```{.ruby .numberLines .hl-5 .hl-9}
module IParent
end

module IChild
  include IParent
end

class Parent
  include IChild
end

class Child < Parent
end
```

We can ask Ruby to print out the ancestor hierarchy for the classes in this
snippet:[^appendix]

[^appendix]:
  {-} See the appendix for the code I used to generate these printouts

```{.wide}
ancestors of IChild          = [IParent]
ancestors of #<Class:IChild> = [...]
────────────────────────────────────────────────────────────────────────
ancestors of Parent          = [IChild, IParent, ...]
ancestors of #<Class:Parent> = [...]
────────────────────────────────────────────────────────────────────────
ancestors of Child          = [Parent, IChild, IParent, ...]
ancestors of #<Class:Child> = [#<Class:Parent>, ...]
```

... but I don't like printouts—I'd rather have pictures. So here's a picture of the same
thing:

![](/assets/img/light/concern-1.png){style="max-width: 854px;"}

![](/assets/img/dark/concern-1.png){style="max-width: 854px;"}

Some conventions in this picture:

- Classes and modules are boxes.
- A line from one box pointing to another shows ancestor information.
- The box being pointed to is the ancestor.
- All classes and modules have singleton classes (shown overlapping).

Since the snippet was plain Ruby, hopefully everything we see is familiar:

- Calling `include` immediately records an ancestor. We called `include` twice, once
  inside `IChild` (on line 5) and once inside Parent (on line 9). Wherever there was a
  call to `include`, there's also an arrow.

- Module singleton classes are never inherited.

- By contrast, when one class inherits from another, the parent's singleton class is
  inherited.

Don't ask me why there's all these rules, this is just how Ruby behaves.

From time to time, [we might wish] Ruby did something differently, allowing modules to
define singleton class methods that can get mixed in alongside their instance
methods. Luckily we don't even have to wish: Ruby is nearly infinitely flexible, and so
people created `ActiveSupport::Concern` to allow this (with only a few restrictions).

[we might wish]: /inheritance-in-ruby/#wait-why-do-we-care-about-inheriting-both

Here's how to use `ActiveSupport::Concern`:

```{.ruby .numberLines .hl-5 .hl-9 .hl-20}
module IParent
end

module IChild
  extend ActiveSupport::Concern

  include IParent

  module ClassMethods
    # Despite being declared as an instance method,
    # this will act like a singleton class method.
    def foo; end
  end
end

class Parent
  include IChild
end

Parent.foo # ✨ magic ✨

class Child < Parent
end
```

In this example, let's say that `IChild` wanted to declare some singleton class methods on
whatever class it was eventually `include`'d into. All it has to do is `extend
ActiveSupport::Concern` and then define `module ClassMethods`[^name] inside itself. The
library will make sure that this module gets `extend`'ed into whichever class eventually
writes `include IChild`.

[^name]:
  {-} The `ClassMethods` name is special to `ActiveSupport::Concern`, not Ruby. It also
  allows defining a `class_methods do ... end` block, but that does nothing more than
  define this module and then run the block inside it.

And to drive the point home, here's a picture:

![](/assets/img/light/concern-2.png){style="max-width: 532px;"}

![](/assets/img/dark/concern-2.png){style="max-width: 532px;"}

Beautiful, just like we'd expect.

One problem though: what if it's not `IChild` that wants to define the singleton class
methods, but rather `IParent`?

```{.ruby .numberLines .hl-2 .hl-4 .hl-17}
module IParent
  extend ActiveSupport::Concern

  module ClassMethods
    def bar; end
  end
end

module IChild
  include IParent
end

class Parent
  include IChild
end

Parent.bar # dang 😰

class Child < Parent
end
```

Suddenly this doesn't work: the `ClassMethods` module gets `extend`ed at the point where
the `include IParent` happens. That means that we'd be able to call `IChild.bar`, but
that's beside the point: we wanted those methods to be available as if they were singleton
class methods on `Parent`. We can see where things went wrong in the picture:

![](/assets/img/light/concern-3.png){style="max-width: 554.5px;"}

![](/assets/img/dark/concern-3.png){style="max-width: 554.5px;"}

And again, `ActiveSupport::Concern` has already thought of this case: it defers `extend`ing
the `ClassMethods` all the way until the first non-`Concern`. So we can simply declare
`IChild` as a `Concern` too (even if it doesn't have any `ClassMethods`). That will ensure
that `IParent::ClassMethods` end up on `#<Class:Parent>`.

It's a single-line change:

```{.ruby .numberLines .hl-10 .hl-19}
module IParent
  extend ActiveSupport::Concern

  module ClassMethods
    def bar; end
  end
end

module IChild
  extend ActiveSupport::Concern

  include IParent
end

class Parent
  include IChild
end

Parent.bar # ✨ magic restored ✨

class Child < Parent
end
```

And when we look at the picture:

![](/assets/img/light/concern-4.png){style="max-width: 883px;"}

![](/assets/img/dark/concern-4.png){style="max-width: 883px;"}

Wait, _what_ is going _on_?

First of all, `ClassMethods` was _only_ `extend`ed into `Parent`, not also into `IChild`.
I suppose that makes sense; maybe there's no real use for those `ClassMethods` to also end
up on the ([childless]) singleton class of `IChild`. In all likelihood, those methods were
going to be things like "create an instance of the current class" which is something that
doesn't make sense for module singleton class methods to be doing. I will admit that
my expectation was that `ClassMethods` would get `extend`'ed onto _every_ module singleton
class that `include`'d the attached class, to mimic how it works when inheriting classes.

[childless]: /inheritance-in-ruby/#the-include-operator

**But what really surprised me**: despite _literally_ having the `include IParent` line in
its class body, `IParent` is _not_ an ancestor of `IChild`. 🤯

Instead, it's only when `IChild` is eventually `include`'d into `Parent` that that
`include IParent` line has an effect. We see that there are two lines coming out of
`Parent`: one directly to `IChild` (makes sense), and then one that skips directly from
`Parent` to `IParent`.

This is kind of wild to me,[^wild] because it literally changes the meaning of `include`
inside an `ActiveSupport::Concern` module.

[^wild]:
  {-} Even more wild is that it's done all [in plain Ruby], using [append_features].

[in plain Ruby]: https://github.com/rails/rails/blob/55412cd9257dc27a8a9175529857ce5f2d81f92f/activesupport/lib/active_support/concern.rb#L112
[append_features]: https://docs.ruby-lang.org/en/master/Module.html#method-i-append_features

Full disclosure: I don't know why this is. If you'll allow me to guess, I'd say because
`ActiveSupport::Concern` is not only designed to let you mix singleton class methods into
the right place, but _also_ to register callbacks to run arbitrary code once the
concern is mixed in there. These callbacks might do things like "call a DSL method in the
context of a database model," or something. The methods that callback calls won't exist
until the very end of the `include` chain, when the `Concern` gets mixed into the model.

\

With any luck maybe that clears things up a bit. If I've gotten something wrong, or this
leaves you with even more questions, feel free to reach out.

\

- - - - -

\

# Appendix: relationship with type systems

Sorbet has a similar but different feature, called [`mixes_in_class_methods`]. I don't
know the history of it, nor why it appears to work so differently from
`ActiveSupport::Concern` despite being clearly inspired by the `ClassMethods` pattern.
I'll have to ask around for the history on that.

[`mixes_in_class_methods`]: https://sorbet.org/docs/abstract#interfaces-and-the-included-hook

Separately, building Sorbet's relatively new [`has_attached_class!`] feature, I kept
finding it really clunky to use in combination with `mixes_in_class_methods`. The behavior
`ActiveSupport::Concern` has around `ClassMethods` would make some annoyances with
`has_attached_class!` go away. But at this rate, making a change to how
`mixes_in_class_methods` is sure to break some other code. But maybe there's a way to
build better support for `Concern`-ish things more generally, so that new code might be
able to move away from `mixes_in_class_methods`. I have not given this much thought.

[`has_attached_class!`]: https://sorbet.org/docs/attached-class#has_attached_class-tattached_class-in-module-instance-methods

And as one final point: by changing how `include` works, it changes the meaning of this
expression: `if IChild < IParent`. This is a very not fun thing to think about the
consequences of if you're trying to build a type system for Ruby. I'm struggling to think
of how to use this fact to come up with some sort of contradiction between what would be
predicted by the type system and what would actually happen at runtime. If you can come up
with one I'd be very curious to see it.


# Appendix: support code

I wrote some random helper functions to print the "ancestors of ..." information that I
used to figure out how to draw the pictures in this post. Here's the code:

<details>
<summary>Click to show code</summary>

```{.ruby .wide}
require 'active_support/concern'

def interesting_ancestors(mod)
  non_self_ancestors = mod.ancestors[1..]
  interesting = non_self_ancestors.filter do |ancestor|
    ![
      Class, Module, Object, Kernel, BasicObject,
      ActiveSupport::Concern,
      Object.singleton_class, BasicObject.singleton_class
    ].include?(ancestor)
  end.map(&:to_s)
  if interesting.size != non_self_ancestors.size
    interesting << "..."
  end
  pretty_mod =
    if mod.singleton_class?
      "#{mod}"
    else
      "#{mod}         "
    end
  puts("ancestors of #{pretty_mod} = [#{interesting.join(", ")}]")
end

def all_interesting_ancestors(*mods)
  first = true
  mods.each do |mod|
    unless first
      puts('─' * 72)
    end
    interesting_ancestors(mod)
    interesting_ancestors(mod.singleton_class)

    first = false
  end
end
```

It's not particularly pretty, but it works for the four snippets in this post.

</details>

# Appendix: all ancestor information

I only showed the first printout, and then skipped straight to pictures. Here's the
printouts for all four examples:

<details>
<summary>Click to show all printouts</summary>

```{.wide}
❯ for i in {1..4}; do echo; ruby concern$i.rb ; echo ; done

ancestors of IChild          = [IParent]
ancestors of #<Class:IChild> = [...]
────────────────────────────────────────────────────────────────────────
ancestors of Parent          = [IChild, IParent, ...]
ancestors of #<Class:Parent> = [...]
────────────────────────────────────────────────────────────────────────
ancestors of Child          = [Parent, IChild, IParent, ...]
ancestors of #<Class:Child> = [#<Class:Parent>, ...]


ancestors of IChild          = [IParent]
ancestors of #<Class:IChild> = [...]
────────────────────────────────────────────────────────────────────────
ancestors of Parent          = [IChild, IParent, ...]
ancestors of #<Class:Parent> = [IChild::ClassMethods, ...]
────────────────────────────────────────────────────────────────────────
ancestors of Child          = [Parent, IChild, IParent, ...]
ancestors of #<Class:Child> = [#<Class:Parent>, IChild::ClassMethods, ...]


ancestors of IChild          = [IParent]
ancestors of #<Class:IChild> = [IParent::ClassMethods, ...]
────────────────────────────────────────────────────────────────────────
ancestors of Parent          = [IChild, IParent, ...]
ancestors of #<Class:Parent> = [...]
────────────────────────────────────────────────────────────────────────
ancestors of Child          = [Parent, IChild, IParent, ...]
ancestors of #<Class:Child> = [#<Class:Parent>, ...]


ancestors of IChild          = []
ancestors of #<Class:IChild> = [...]
────────────────────────────────────────────────────────────────────────
ancestors of Parent          = [IChild, IParent, ...]
ancestors of #<Class:Parent> = [IParent::ClassMethods, ...]
────────────────────────────────────────────────────────────────────────
ancestors of Child          = [Parent, IChild, IParent, ...]
ancestors of #<Class:Child> = [#<Class:Parent>, IParent::ClassMethods, ...]
```

</details>

