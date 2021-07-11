---
# vim:tw=72
layout: post
title: "Linkers & Ruby C Extensions"
date: 2020-06-07 12:05:07 -0500
comments: false
share: false
categories: ['linux', 'ruby', 'c']
description: >
  I recently learned that linkers are really cool.
---

I recently learned that linkers are really cool. It all started when I
saw an error message that looked something like this:

```
❯ rake test
symbol lookup error: /home/jez/.../foo.so: undefined symbol bar
```

I [already wrote](/search-down-the-stack/) about finding where this
error was coming from. The tl;dr is that it was coming from GNU's libc
implementation:

```
❯ rg -t c 'symbol lookup error'
dl-lookup.c
876:      _dl_signal_cexception (0, &exception, N_("symbol lookup error"));
```

That led me to a fun exploration of how linux linkers work, and how Ruby
C extensions rely on them.

I always knew that Ruby C extensions existed (that they [break all the
time][nokogiri] is a constant reminder...) but I never really connected
the dots between "here's some C code" and how Ruby actually runs that
code.

[nokogiri]: https://twitter.com/asolove/status/1261339091485917184

Ruby C extensions are just shared libraries following certain
conventions. Specifically, a Ruby C extension might look like this:

```c
#include "ruby.h"

VALUE my_foo(VALUE self, VALUE val) {
  return rb_funcall(self, rb_intern("puts"), 1, val)
}

// This function's name matters:
void Init_my_lib() {
  rb_define_method(rb_cObject, "foo", my_foo);
}
```

The important part is that the name of that `Init_my_lib` function
matters. When Ruby sees a line like

```ruby
require_relative './my_lib'
```

it looks for a file called `my_lib.so` (or `my_lib.bundle` on macOS),
asks the operating system to load that file as a shared library, and
then looks for a function with the name `Init_my_lib` inside the library
it just loaded.

When that function runs, it's a chance for the C extension to do
the same sorts of things that a normal Ruby file might have done if it
had been `require`'d. In this example, it defines a method `foo` at the
top level, almost like the user had written normal Ruby code like this:

<figure>
```ruby
def foo(val)
  puts val
end
```
<figcaption>my_lib.rb</figcaption>
</figure>

That's kind of wild! That means:

- C programs can load libraries dynamically at runtime, using arbitrary
  user input.
- C programs can then ask if there's a function defined in that library
  with an arbitrary name, and get a function pointer to call it if there
  is!

I was pretty shocked to learn this, because my mental model of how
linking worked was that it split evenly into two parts:

- "My application is statically linked, where all the code and libraries
  my application depends on are compiled into my binary."

- "My application is dynamically linked, which means my binary
  pre-declares some libraries that must be loaded before my program can
  start running."

There's actually a third option!

Then I looked into what code Ruby actually calls to do this. I found the
code in `dln.c`:


<figure>
```c
/* Load file */
if ((handle = (void*)dlopen(file, RTLD_LAZY|RTLD_GLOBAL)) == NULL) {
    error = dln_strerror();
    goto failed;
}
```
<figcaption>dln.c</figcaption>
</figure>

[→ View on github.com](https://github.com/ruby/ruby/blob/37c2cd3fa47c709570e22ec4dac723ca211f423a/dln.c#L1341)

Ruby uses the `dlopen(3)` function in libc to request that an arbitrary
user library be loaded. From the man page:

> The function dlopen() loads the dynamic shared object (shared library)
> file named by the null-terminated string filename and returns an
> opaque "handle" for the loaded object.
>
> --- man dlopen

The next thing Ruby does with this opaque `handle` is to find if the
thing it just loaded has an `Init_<...>` function inside it:

<figure>
```c
init_fct = (void(*)())(VALUE)dlsym(handle, buf);
if (init_fct == NULL) {
    const size_t errlen = strlen(error = dln_strerror()) + 1;
    error = memcpy(ALLOCA_N(char, errlen), error, errlen);
    dlclose(handle);
    goto failed;
}
```
<figcaption>dln.c</figcaption>
</figure>

[→ View on github.com](https://github.com/ruby/ruby/blob/37c2cd3fa47c709570e22ec4dac723ca211f423a/dln.c#L1363-L1369)

It uses `dlsym(3)` (again in libc) to look up a method with an arbitrary
name (`buf`) inside the library it just opened (`handle`). That function
must exist—if it doesn't, it's not a valid Ruby C extension and Ruby
reports an error.

If `dlsym` found a function with the right name, it stores a function
pointer into `init_fct`, which Ruby immediately dereferences and calls:

<figure>
```c
/* Call the init code */
(*init_fct)();
```
<figcaption>dln.c</figcaption>
</figure>

[→ View on github.com](https://github.com/ruby/ruby/blob/37c2cd3fa47c709570e22ec4dac723ca211f423a/dln.c#L1370-L1371)

It's still kind of mind bending to think that C provides this level of
"dynamism." I had always thought that being a compiled language meant
that the set of functions a C program could call was fixed at compile
time, but that's not true at all!

This search led me down a rabbit hole of learning more about linkers,
and now I think they're super cool—and far less cryptic! I **highly**
recommend *Chapter 7: Linking* from [Computer Systems: A Programmer's
Perspective] if this was interesting to you.

[Computer Systems: A Programmer's Perspective]: http://www.csapp.cs.cmu.edu/
