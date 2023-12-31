---
# vim:tw=90 fo-=tc
layout: post
title: "Why don't constructors have override checking?"
date: 2023-12-31T00:14:09-05:00
description: >
  A discussion of how constructors in typical typed object-oriented languages get away with not having to solve a problem that plagues Sorbet.
math: false
categories: ['ruby', 'sorbet', 'types']
# subtitle:
# author:
# author_url:
---

This year I spent a lot of time looking at how constructors work in object oriented languages.

# Ruby

For example, Ruby constructors look like this:

```ruby
class Box
  def initialize(val)
    @val = val
  end
end

box = Box.new('hello')
```

It's interesting because you define `initialize` as an instance method, but then you call a `new` as a singleton class method. We can do some digging to figure out how that works:

```ruby
❯ irb -r"./box"
irb(main):001:0> Box.method(:new).source_location
=> nil
irb(main):002:0> Box.method(:new).owner
=> Class
```

A nil `source_location` usually means it's a method defined in the Ruby VM, so the easiest thing is to grep the Ruby VM source code:

```{.plain .wide .numberLines .hl-5}
~/github/ruby/ruby ((HEAD detached at v3_3_0))
❯ rg 'Class.*"new"'
object.c
4417:    rb_undef_method(CLASS_OF(rb_cNilClass), "new");
4478:    rb_define_method(rb_cClass, "new", rb_class_new_instance_pass_kw, -1);
4498:    rb_undef_method(CLASS_OF(rb_cTrueClass), "new");
4510:    rb_undef_method(CLASS_OF(rb_cFalseClass), "new");
```

We can pull up the implementation of `Class#new`, which is split across a couple functions:

<figure class="left-align-caption">

```{.c .wide .numberLines .hl-6 .hl-7}
VALUE
rb_class_new_instance_pass_kw(int argc, const VALUE *argv, VALUE klass)
{
    VALUE obj;

    obj = rb_class_alloc(klass);
    rb_obj_call_init_kw(obj, argc, argv, RB_PASS_CALLED_KEYWORDS);

    return obj;
}
```

<figcaption>
[object.c:2125-2134](https://github.com/ruby/ruby/blob/v3_3_0/object.c#L2125-L2134)
</figcaption>
</figure>

<figure class="left-align-caption">

```{.c .wide .numberLines .hl-5}
void
rb_obj_call_init_kw(VALUE obj, int argc, const VALUE *argv, int kw_splat)
{
    PASS_PASSED_BLOCK_HANDLER();
    rb_funcallv_kw(obj, idInitialize, argc, argv, kw_splat);
}
```

<figcaption>
[eval.c:1705-1710](https://github.com/ruby/ruby/blob/v3_3_0/eval.c#L1705-L1710)
</figcaption>
</figure>

From this we gather that the implementation of `Class#new` is basically the same as this Ruby code:

```ruby
class Class
  def new(...)
    obj = self.alloc
    obj.initialize(...)
    obj
  end
end
```

The `alloc` method asks the garbage collector to allocate memory for the new instance (but does not initialize it). Then with an instance in hand, Ruby can dispatch to the `initialize` instance method.

If the class doesn't implement an `initialize` method, the dispatch goes all the way up to `BasicObject#initialize`, which takes no arguments and returns `nil`.

# Java

There's a lot of similarity to the way it works in Java, but there are also quite a few differences.

```java
class Box {
  Object val;
  Box(Object val) {
    this.val = val;
  }
}

class Main {
  public static void main(String[] args) {
    var box = new Box("hello");
    System.out.println(box.val);
  }
}
```

To figure out how this works, we can take a look at the Java bytecode:

```{.plain .wide .extra-wide .numberLines .hl-1 .hl-12 .hl-13 .hl-14 .hl-15}
❯ javac Box.java && javap -c Main
Compiled from "Box.java"
class Main {
  Main();
    Code:
       0: aload_0
       1: invokespecial #1                  // Method java/lang/Object."<init>":()V
       4: return

  public static void main(java.lang.String[]);
    Code:
       0: new           #7                  // class Box
       3: dup
       4: ldc           #9                  // String hello
       6: invokespecial #11                 // Method Box."<init>":(Ljava/lang/Object;)V
       9: astore_1
      10: getstatic     #14                 // Field java/lang/System.out:Ljava/io/PrintStream;
      13: aload_1
      14: getfield      #20                 // Field Box.val:Ljava/lang/Object;
      17: invokevirtual #24                 // Method java/io/PrintStream.println:(Ljava/lang/Object;)V
```

These numbers like `#7` and `#11` are references into the constant pool, which is basically like static data in a class file. You can see the whole pool with `javap -v` instead of `javap -c`, but it's long and basically just shows what's in the comment so I omitted it.

Some of my observations:

- The "allocate memory" step and the "initialize the instance" step are separate bytecode instructions ([`new`][new-op] vs [`invokespecial`]). In Ruby, there's only one bytecode instruction (the call to the `.new` method), and the logic is hidden behind that method call. But otherwise, they both have these two steps.

  This smells a lot like inlining even if it's technically not, and I'd bet that allows the JIT a better chance to optimize it (versus a Ruby JIT having to guess whether a call to `.new` is this very common "alloc + initialize" use case or something else).

- Just like how Ruby has an `initialize` method, in Java there's this special `<init>` method. Experience tells me that's a clever trick compilers/VMs use when they want to be able to use normal methods for something internally, but don't want that fact to leak to users.

  For example, because `x.<init>()` is a syntax error, no one can ever call the constructor a second time. Meanwhile in Ruby, you can technically call `x.initialize` whenever you want.

- It's using [`invokespecial`], which is basically a cross breed between static and dynamic dispatch. The dispatch target is resolved at compile time: it takes the method to call as a bytecode operand, like `#11`, which is a reference into the constant pool. In this way it's just like `inovkestatic`. But unlike `invokestatic`, `invokespecial` expects a method receiver to be on the VM stack in addition to the call's arguments, the same way that an instance method call would work. So despite essentially doing static dispatch, it's still going to bind `this` to a value when the method runs.

- There's a default constructor, but it isn't called via dynamic dispatch up to the top of the object hierarchy (like `BasicObject#initialize` in Ruby). Rather, if a class doesn't have a user-defined constructor, the Java compiler emits an explicit `invokespecial` to the `Object."<init>"` method directly (or whatever the parent of the current class is).

- If a child class does not have a constructor, and the parent class has a non-nullary constructor, that's an error—the child class must declare some sort of constructor and explicitly call `super(...)` with whatever arguments the parent class's constructor needs.

  ```ruby
  class Parent {
    Parent(int x) {}
  }

  class Child extends Parent {
    // ❌must declare constructor and call `super(...)`
  }
  ```

[new-op]: https://docs.oracle.com/javase/specs/jvms/se21/html/jvms-6.html#jvms-6.5.new
[`invokespecial`]: https://docs.oracle.com/javase/specs/jvms/se21/html/jvms-6.html#jvms-6.5.invokespecial
[`invokestatic`]: https://docs.oracle.com/javase/specs/jvms/se21/html/jvms-6.html#jvms-6.5.invokestatic

# Ramifications for override checking

I was looking into these things because I was curious about how typed, object-oriented languages like Java and Scala and C++ handle [override compatibility checking] (Liskov substitution checking) for constructors.

[override compatibility checking]: https://sorbet.org/docs/override-checking#a-note-on-variance

The answer is: they don't, because they don't function like other instance methods. In fact, they're almost entirely like static methods, except for the fact that they have `this` bound, via the fancy `invokespecial` instruction.[^special] Just like static methods, these special `<init>` methods aren't inherited, can't be called via `super`, and don't get override checking.

[^special]:
  {-} In fact they're called "instance initialization methods," and they're [defined here][init].

[init]: https://docs.oracle.com/javase/specs/jvms/se21/html/jvms-2.html#jvms-2.9

But this answer isn't satisfying for Ruby and Sorbet. Ruby allows calling `new` polymorphically, since singleton class methods are dispatched dynamically, not statically. Sorbet can't get away with the "skip all override checking on constructors" argument that Java and other typed, object-oriented languages can.

[first-class-objects]: /inheritance-in-ruby/#wait-why-do-we-care-about-inheriting-both

Ruby is not the only language that has first-class objects... How do other languages handle this, like Python, TypeScript, Flow, and Hack?

Python and Flow ignore the problem. Hack at least has an annotation that lets you opt into the checks. Sorbet also has such an annotation (either `abstract`[^abstract] or `overridable`), but people aren't required to annotate them so it doesn't catch as many bugs as it should and I find that pretty unsatisfying.

[^abstract]:
  {-} By the way, allowing `abstract` constructors already breaks with tradition: constructors are not normally allowed to be abstract. But that's kind of a side-effect of how constructors act like static methods, and in Java/Scala/C++ static methods are not allowed to be abstract either. Since they're not inherited nor called polymorphically, what would be the point of an abstract constructor in those languages? This is why the [Abstract Factory pattern] is so notorious, because it's the only way to get polymorphic constructors in those languages.

[Abstract Factory pattern]: https://en.wikipedia.org/wiki/Abstract_factory_pattern

The funny thing is that TypeScript just sidesteps the issue by way of [structural typing]. In TypeScript `typeof Parent` is not compatible with `typeof Child` if their constructors are different. (In a nominal type system, simply having `Child` descend from `Parent` should be the only factor in determining whether those types are compatible).

[structural typing]: https://en.wikipedia.org/wiki/Structural_type_system

On the one hand there's a certain elegance to this approach. But in the small amount of time I've spent writing code in structurally typed languages (TypeScript, Go), I've been super annoyed by the fact that I can't just change a type of an interface method and see all the methods whose types I need to update. Instead, I get errors repeated at every call site where an object no longer satisfies some required interface, far away from where I'll need to write code to fix the problem. But that's a personal rant, and regardless: Sorbet is not a structural type system so it can't steal this solution.

This problem is still unsolved in Sorbet ([#7274], [#7309], [#7555]). At least it's not alone in leaving it unsolved, but I _would_ like to make it better one day, especially given [how frequently](/inheritance-in-ruby/) people use `new` polymorphically in Ruby.

[#7274]: https://github.com/sorbet/sorbet/issues/7274
[#7309]: https://github.com/sorbet/sorbet/issues/7309
[#7555]: https://github.com/sorbet/sorbet/issues/7555

\

\

- - - - -

# Bonus: ramifications for generic type inference

The other reason why I wanted to look at this was to see how languages deal with the overlap between constructors and type inference:

```scala
class Box[Value](x: Value) {
  val value = x
}

@main def main() =
  val box = Box(0)
  println(box.value)
```

This Scala program infers a type of `Box[int]` for the `box` variable. The corresponding program in Sorbet would look like

```ruby
class Box
  extend T::Generic
  Value = type_member
  sig { params(x: Value).void }
  def initialize(x)
    @value = x
  end
end

box = Box.new(0)
```

Except that Sorbet doesn't infer a type of `Box[Integer]`, it infers a type of `Box[T.untyped]`. The problem is that `initialize` isn't a generic method, like

```ruby
sig do
  type_parameters(:U)
    .params(x: T.type_parameter(:U))
    .void
  end
end
def initialize(x); end
```

Sorbet only infers types for a method's generic type parameters, not for the class's generic type parameters used in a method. I was wondering if any other language addressed this by being clever and assuming that the "static part" of the constructor was actually a method in its own right, which had a signature mirroring the instance method part:

```ruby
class Box
  # ...

  # Implicitly assume something like this method was defined:
  sig do
    type_parameters(:Value)
      .params(x: T.type_parameter(:Value))
      .returns(T.all(T.attached_class), Box[T.type_parameter(:Value)])
  end
  def self.new(x)
    super
  end
end
```

So for example, Sorbet would pretend like the singleton class `new` method would:

- Have one type parameter for every type member in the class.
- Replace every occurrence of a type member in the signature with the corresponding type parameter.
- Use [ths trick](/generic-constructor-trick/) for the return value, so it respects being called on a subclass of the current class.

From looking into other languages, I mostly convinced myself that other languages' type inference algorithms are different enough from Sorbet that they represent the inference constraints in such a different way that it isn't worth asking whether they do this (Sorbet somewhat famously does a very [simple form of inference] that doesn't generate constraints before solving them). Regardless, I think that something along these lines could work for Sorbet in the future.

[simple form of inference]: https://blog.nelhage.com/post/why-sorbet-is-fast/#simple-type-inference

