---
# vim:tw=90
layout: post
title: "GC.compact in Pictures"
date: 2020-12-18T15:03:58-05:00
description: >-
  Ruby's opt-in GC compaction is both really cool and also kind of scary, so we're going
  to chat about both, with pictures.
math: false
categories: ['ruby', 'in-pictures']
# subtitle:
# author:
# author_url:
---

> **Editing note**: This post first appeared in a work-internal email. It was first
> cross-posted to this blog December 12, 2022.

At a high level, Ruby's garbage collection algorithm is a mark-and-sweep collector. In
Ruby 2.7, Ruby's GC algorithm gets a little more sophisticated: not only does it
mark-and-sweep, but it can be asked to compact memory!

This is both really cool and also kind of scary, so we're going to chat about both, with
pictures.

The Ruby VM manages memory on behalf of the programmer. Internally, it knows which parts
of memory correspond to allocated and free things:

![](/assets/img/light/gc-compact-ruby-mem.png)

![](/assets/img/dark/gc-compact-ruby-mem.png)

When you do something like

``` ruby
x = MyClass.new
```

Ruby will allocate enough space to hold that value behind the scenes. When that object
isn't needed anymore, it'll get freed. Over the life cycle of an application that
allocates and frees a lot (read: literally every Ruby program), memory can get pretty
fragmented: even though there might be space available, it might not all be contiguous.
That means:

-   it's not available for the operating system to give to someone else
-   there might not be space for a "big" allocation if all that's left are "small" holes

That second one can be pretty annoying:

![](/assets/img/light/gc-compact-oom.png)

![](/assets/img/dark/gc-compact-oom.png)

A neat innovation in GC algorithms is what are called **compacting garbage collection**
algorithms. These kinds of algorithms periodically (either automatically, on on request),
shuffle all the allocated memory around so that it lines up nicely, with no gaps:

![](/assets/img/light/gc-compact-compaction.png)

![](/assets/img/dark/gc-compact-compaction.png)

That's what was added in Ruby 2.7! Just call:

``` ruby
GC.compact
```

in a Ruby program to request that the VM runtime compact its heap. That's great! It means
our programs go out of memory less frequently, can run with more headroom (to handle spiky
workloads), and can get better cache locality.

If we had called `GC.compact` before we asked the Ruby VM to do a bunch of allocations
(maybe, in between every handful of API requests), then there's a greater chance that Ruby
will be able to give us the memory we ask for:

![](/assets/img/light/gc-compact-no-oom.png)

![](/assets/img/dark/gc-compact-no-oom.png)

… phew! So compacting garbage collection seems great, right?

In theory yes. In practice, it's a bit trickier, especially because many Ruby gems using
Ruby's C extension API.

In a Ruby C extension, the extension has its own memory, and some of the things it stores
can be pointers into the Ruby VM's heap. As long as those values don't move around on the
heap, the pointers will be valid as long as the object is still alive.

But in Ruby 2.7, `GC.compact` causes memory to shuffle around, which can have some really
annoying consequences:

![](/assets/img/light/gc-compact-mem-crash.png)

![](/assets/img/dark/gc-compact-mem-crash.png)

In this example, we've got a Ruby C extension with a pointer into the Ruby VM's heap.
After one round of GC compaction, that pointer has been completely invalidated: the
pointer is pointing at unallocated data 😱

Scarier still, is that something could be allocated into that (now available) spot! In
that case, it will appear to the C extension like its value just changed out of thin air
to something else entirely. That can cause all sorts of wild problems. Some examples:

-   A `TypeError` or similar exception, because the new value is a completely different
    type
-   Database corruption bugs, because maybe the new value is "good enough" that it doesn't
    crash anything, and makes its way all the way to the database, even though it's the
    wrong value.

Probably the most annoying part: these bugs can be near impossible to reproduce. What gets
allocated (or not allocated) into any given slot depends heavily on the arbitrary order in
which objects are allocated and freed over the lifetime of a running service. This makes
it hard (though not always impossible) to write test cases or reproduce the problems in a
staging environment.

This caused more than a handful of problems at work as we upgraded from Ruby 2.6 to Ruby
2.7. Of course, there's a solution: the Ruby C extension API includes functions that
declare which values the C extension expects not to move:

``` c
VALUE my_global_hash;

void Init_my_c_extension() {
  my_global_hash = rb_hash_new();

  // (*) This requests that the GC not move this object:
  rb_gc_mark(my_global_hash);
}
```

So far in the Ruby 2.7 upgrade, every problem we saw in production that wasn't first
caught by CI has been fixed by either patching a C extension to use `rb_gc_mark` in more
places, or upgrading a gem that has already been fixed.

If you want to read more about this sort of stuff:

-   Aaron "tenderlove" Patterson (author of the 2.7 GC compaction changes) gave a talk about it:\
    → [Compacting Heaps in Ruby 2.7](https://www.youtube.com/watch?v=1F3gXYhQsAY)
-   Aaron's ticket tracking the GC changes does a good job of explaining the intricacies\
    → [Manual Compaction for MRI's GC (`GC.compact`)](https://bugs.ruby-lang.org/issues/15626)
-   Alan Wu's list of tips for debugging memory movement problems:\
    → [Checking Ruby C extensions for object movement crashes](https://alanwu.space/post/check-compaction/)

And if you have any questions, please let me know!
