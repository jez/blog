---
# vim:tw=90
layout: post
title: "Mimicking Opaque Types in Sorbet"
date: 2020-12-12T20:45:47-05:00
description: >-
  I saw a neat trick the other day for how to combine a handful of Sorbet's existing
  features to mimic opaque types.
math: false
categories: ['ruby', 'sorbet', 'types']
# subtitle:
# author:
# author_url:
---

> **Editing note**: This post first appeared in a Stripe-internal email. It was first
> cross-posted to this blog December 12, 2022.

I saw a neat trick the other day in Stripe's Ruby codebase. It combines different features
of Sorbet in a cute way to mimic a feature called [opaque
types](https://en.wikipedia.org/wiki/Opaque_data_type) present in other typed languages
([Haskell](https://wiki.haskell.org/Newtype),
[Rust](https://doc.rust-lang.org/rust-by-example/generics/new_types.html),
[Flow](https://flow.org/en/docs/types/opaque-types/)). Opaque types allow making an
abstract type, where the implementation of a type is hidden. In pseudocode, we might
define an abstract type for emails like this:

``` haskell
-- Some abstract (opaque) type
type Email

-- All the ways to create that type
parse : String -> T.nilable(Email)

-- All the ways to use that type
extract_user : Email -> String
extract_hostname : Email -> String
```

This says, "There's some type called `Email`, but I won't tell you the concrete structure
of the type. Instead, I'm going to provide you with functions for creating that type, and
for using that type." Since the concrete structure isn't known, the public interface is
the only way to interact with the type.

Here's the interesting parts of the implementation. In classic Sorbet fashion, it's kind
of verbose 😅

``` ruby
module TypeIsOpaque; extend T::Helpers; final!; end
private_constant :TypeIsOpaque

Underlying = T.type_alias {String}
private_constant :Underlying

Type = T.type_alias {T.any(TypeIsOpaque, Underlying)}
```

[→ View complete example on sorbet.run](https://sorbet.run/#%23%20typed%3A%20strict%0A%0Amodule%20Email%0A%20%20extend%20T%3A%3ASig%0A%20%20extend%20T%3A%3AHelpers%0A%0A%20%20%23%20Make%20this%20a%20%22true%22%20namespace%3A%20only%20way%20to%20access%20the%0A%20%20%23%20private%20constants%20below%20is%20to%20reopen%20this%20module.%0A%20%20final!%0A%0A%20%20module%20TypeIsOpaque%3B%20extend%20T%3A%3AHelpers%3B%20final!%3B%20end%0A%20%20private_constant%20%3ATypeIsOpaque%0A%0A%20%20Underlying%20%3D%20T.type_alias%20%7BString%7D%0A%20%20private_constant%20%3AUnderlying%0A%0A%20%20Type%20%3D%20T.type_alias%20%7BT.any%28TypeIsOpaque%2C%20Underlying%29%7D%0A%0A%0A%20%20%23%20This%20private%20method%20allows%20converting%20freely%20between%20the%0A%20%20%23%20opaque%20type%20and%20the%20underlying%20type%20ONLY%20within%20%60Email%60.%0A%20%20sig%28%3Afinal%29%20%7Bparams%28opaque%3A%20Type%29.returns%28Underlying%29%7D%0A%20%20private_class_method%20def%20self.unwrap_opaque%28opaque%29%0A%20%20%20%20%23%20This%20is%20actually%20safe%2C%20because%20there%20can%20be%20no%20instances%20of%0A%20%20%20%20%23%20TypeIsOpqaue%2C%20so%20it%20can%20only%20be%20of%20type%20Underlying.%0A%20%20%20%20T.unsafe%28opaque%29%0A%20%20end%0A%0A%20%20sig%28%3Afinal%29%20%7Bparams%28raw_input%3A%20String%29.returns%28T.nilable%28Type%29%29%7D%0A%20%20def%20self.parse%28raw_input%29%0A%20%20%20%20%23%20This%20is%20a%20terrible%20way%20to%20actually%20parse%20emails.%0A%20%20%20%20%23%20All%20I'm%20trying%20to%20show%20is%20the%20type-level%20stuff.%0A%20%20%20%20if%20%2F%5B%5E%40%5D%2B%40%5B%5E%40%5D%2B%2F%20%3D~%20raw_input%0A%20%20%20%20%20%20raw_input%0A%20%20%20%20else%0A%20%20%20%20%20%20nil%0A%20%20%20%20end%0A%20%20end%0A%20%20sig%28%3Afinal%29%20%7Bparams%28email%3A%20Type%29.returns%28String%29%7D%0A%20%20def%20self.extract_user%28email%29%0A%20%20%20%20user%2C%20_hostname%20%3D%20unwrap_opaque%28email%29.split%28%2F%40%2F%29%0A%20%20%20%20%23%20this%20must%20is%20ok%20because%20of%20Email%3A%3AType's%20invariant%0A%20%20%20%20T.must%28user%29%0A%20%20end%0A%20%20sig%28%3Afinal%29%20%7Bparams%28email%3A%20Type%29.returns%28String%29%7D%0A%20%20def%20self.extract_hostname%28email%29%0A%20%20%20%20_user%2C%20hostname%20%3D%20unwrap_opaque%28email%29.split%28%2F%40%2F%29%0A%20%20%20%20T.must%28hostname%29%0A%20%20end%0Aend%0A%0Aemail%20%3D%20T.must%28Email.parse%28'jez%40example.com'%29%29%0A%23%20not%20great%20error%3A%20would%20like%20to%20show%20%60T.nilable%28Email%3A%3AType%29%60%2C%0A%23%20but%20the%20type%20alias%20expands%20itself%0AT.reveal_type%28email%29%0A%0A%23%20Error%20when%20trying%20to%20use%20an%20email%20as%20a%20String%0A%23%20%28slightly%20weird%20message%2C%20but%20still%20an%20error%29%0Aemail.length%0A%0A%23%20Can%20only%20use%20allowed%20operations%3A%0AEmail.extract_hostname%28email%29%20%23%20ok%0AEmail.unwrap_opaque%28email%29%20%20%20%20%23%20not%20ok%0A%0AEmail.extract_hostname%28'not%20an%20email'%29%20%23%20ok%20%28sadly%29%0A%0A%23%20Can%20only%20mention%20the%20opaque%20type%2C%20not%20the%20underlying%20type%0AT.let%28email%2C%20Email%3A%3AType%29%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%23%20ok%0AT.let%28'jez%40example.com'%2C%20Email%3A%3AUnderlying%29%20%23%20not%20ok%20%28private%20constant%29%0Acase%20email%0Awhen%20String%20then%20%0Awhen%20Email%3A%3ATypeIsOpaque%20then%20%23%20not%20ok%20%28private%20constant%29%0Aelse%20T.absurd%28email%29%0Aend)

Let's break down what's going on here:

- `TypeIsOpaque` is a private, final module. A [final
  module](https://sorbet.org/docs/final) can never be included in a class, so this type is
  **uninhabited**: there are no values of type `TypeIsOpaque`. Being private powers the
  opacity, as we'll see. The name is crafted to give people a semblance of a hint as to
  what's going on if they see it in error messages.

- `Underlying` is a (transparent) type alias to `String`. It says that our abstract email
  type is really a `String` at runtime, even if it isn't a `String` for the purposes of
  type checking.

- `Type` (fully qualified: `Email::Type`) is the public interface to our abstract type.
  It's a union of the two (private) types above. Since they're both private, users can
  only mention `Email::Type` and not `Email::Underlying` nor `Email::TypeIsOpaque`.

That's it! We have an abstract type that's always a `String` at runtime but (mostly) can't
be used like a `String` statically. Let's see it in action:

``` ruby
email = T.must(Email.parse('jez@example.com'))

# statically, it's an `Email::Type` (even though the error expands the type alias)
T.reveal_type(email) # Revealed type: `T.any(Email::TypeIsOpaque, String)`

# at runtime, it's a `String` (not some wrapper class)
T.unsafe(email).class # => String
```

Note that the type is so opaque, we can't even *ask for the runtime class* without using
`T.unsafe`!

Some more things that can and can't be done:

``` ruby
# We CAN'T call `String` methods:
email.length # error: Method `length` does not exist

# We CAN call the public interface methods with a parsed email:
Email.extract_user(email)     # ok
Email.extract_hostname(email) # ok

# [bug] We CAN call the public interface methods with raw strings:
Email.extract_user('not an email') # ok (sadly)

# We CAN'T (safely) unwrap the union to the underlying type:
case email
when Email::TypeIsOpaque then # error: Non-private reference to private constant
when String then
else T.absurd(email)
end

# We CAN ONLY mention `Email::Type` in signatures:
sig {returns(Email::Type)}         # ok
sig {returns(Email::Underlying)}   # error: Non-private reference to private const
sig {returns(Email::TypeIsOpaque)} # error: Non-private reference to private const
```

Users could of course still call `T.unsafe` to use `Email::Type` and `String`
interchangeably, but that's something to discourage in code review (and is a perennial
problem in Sorbet anyways, not unique to opaque types).

Again, you should probably take a look at the complete, interactive example; it'll teach a
lot more:

[→ View complete example on sorbet.run](https://sorbet.run/#%23%20typed%3A%20strict%0A%0Amodule%20Email%0A%20%20extend%20T%3A%3ASig%0A%20%20extend%20T%3A%3AHelpers%0A%0A%20%20%23%20Make%20this%20a%20%22true%22%20namespace%3A%20only%20way%20to%20access%20the%0A%20%20%23%20private%20constants%20below%20is%20to%20reopen%20this%20module.%0A%20%20final!%0A%0A%20%20module%20TypeIsOpaque%3B%20extend%20T%3A%3AHelpers%3B%20final!%3B%20end%0A%20%20private_constant%20%3ATypeIsOpaque%0A%0A%20%20Underlying%20%3D%20T.type_alias%20%7BString%7D%0A%20%20private_constant%20%3AUnderlying%0A%0A%20%20Type%20%3D%20T.type_alias%20%7BT.any%28TypeIsOpaque%2C%20Underlying%29%7D%0A%0A%0A%20%20%23%20This%20private%20method%20allows%20converting%20freely%20between%20the%0A%20%20%23%20opaque%20type%20and%20the%20underlying%20type%20ONLY%20within%20%60Email%60.%0A%20%20sig%28%3Afinal%29%20%7Bparams%28opaque%3A%20Type%29.returns%28Underlying%29%7D%0A%20%20private_class_method%20def%20self.unwrap_opaque%28opaque%29%0A%20%20%20%20%23%20This%20is%20actually%20safe%2C%20because%20there%20can%20be%20no%20instances%20of%0A%20%20%20%20%23%20TypeIsOpqaue%2C%20so%20it%20can%20only%20be%20of%20type%20Underlying.%0A%20%20%20%20T.unsafe%28opaque%29%0A%20%20end%0A%0A%20%20sig%28%3Afinal%29%20%7Bparams%28raw_input%3A%20String%29.returns%28T.nilable%28Type%29%29%7D%0A%20%20def%20self.parse%28raw_input%29%0A%20%20%20%20%23%20This%20is%20a%20terrible%20way%20to%20actually%20parse%20emails.%0A%20%20%20%20%23%20All%20I'm%20trying%20to%20show%20is%20the%20type-level%20stuff.%0A%20%20%20%20if%20%2F%5B%5E%40%5D%2B%40%5B%5E%40%5D%2B%2F%20%3D~%20raw_input%0A%20%20%20%20%20%20raw_input%0A%20%20%20%20else%0A%20%20%20%20%20%20nil%0A%20%20%20%20end%0A%20%20end%0A%20%20sig%28%3Afinal%29%20%7Bparams%28email%3A%20Type%29.returns%28String%29%7D%0A%20%20def%20self.extract_user%28email%29%0A%20%20%20%20user%2C%20_hostname%20%3D%20unwrap_opaque%28email%29.split%28%2F%40%2F%29%0A%20%20%20%20%23%20this%20must%20is%20ok%20because%20of%20Email%3A%3AType's%20invariant%0A%20%20%20%20T.must%28user%29%0A%20%20end%0A%20%20sig%28%3Afinal%29%20%7Bparams%28email%3A%20Type%29.returns%28String%29%7D%0A%20%20def%20self.extract_hostname%28email%29%0A%20%20%20%20_user%2C%20hostname%20%3D%20unwrap_opaque%28email%29.split%28%2F%40%2F%29%0A%20%20%20%20T.must%28hostname%29%0A%20%20end%0Aend%0A%0Aemail%20%3D%20T.must%28Email.parse%28'jez%40example.com'%29%29%0A%23%20not%20great%20error%3A%20would%20like%20to%20show%20%60T.nilable%28Email%3A%3AType%29%60%2C%0A%23%20but%20the%20type%20alias%20expands%20itself%0AT.reveal_type%28email%29%0A%0A%23%20Error%20when%20trying%20to%20use%20an%20email%20as%20a%20String%0A%23%20%28slightly%20weird%20message%2C%20but%20still%20an%20error%29%0Aemail.length%0A%0A%23%20Can%20only%20use%20allowed%20operations%3A%0AEmail.extract_hostname%28email%29%20%23%20ok%0AEmail.unwrap_opaque%28email%29%20%20%20%20%23%20not%20ok%0A%0AEmail.extract_hostname%28'not%20an%20email'%29%20%23%20ok%20%28sadly%29%0A%0A%23%20Can%20only%20mention%20the%20opaque%20type%2C%20not%20the%20underlying%20type%0AT.let%28email%2C%20Email%3A%3AType%29%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%23%20ok%0AT.let%28'jez%40example.com'%2C%20Email%3A%3AUnderlying%29%20%23%20not%20ok%20%28private%20constant%29%0Acase%20email%0Awhen%20String%20then%20%0Awhen%20Email%3A%3ATypeIsOpaque%20then%20%23%20not%20ok%20%28private%20constant%29%0Aelse%20T.absurd%28email%29%0Aend)

But now, I'd like to answer some common questions I imagine people will have.

### Is this really useful?

Maybe the email example isn't so motivating, but hopefully the idea of "zero overhead
abstract types" are. Some more examples to spark your imagination:

- Database foreign key IDs. Make one opaque type for each kind of database object. Then
  you can say "this method accepts only user IDs, or only charge IDs." The type system
  guarantees that different object types' IDs aren't interchangeable. It could even
  guarantee that if you have an ID, it represents an actual record in the database (or at
  least, a record that existed in the database). (Stripe's in-house ORM actually does this
  for certain tokens.)

- HTML-sanitized strings. Draw a type-level distinction between "a String that came from
  the user and might have unescaped-HTML characters" and "a String that has had all it's
  characters escaped." Avoid defensively HTML-escaping because the type system tracks it.

### Isn't this really verbose?

Yep! But it's easy to tack on concise syntax later. We've punted around some ideas for
this over the years, but there are still a few unanswered questions which is the main
reason why we haven't built something yet:

-   Should opaque types be file-private (like sealed classes), module-private (like
    `private` and `private_constant`), or package private?
-   Should converting between the opaque and underlying type be explicit or implicit?
-   Should the implementation be built on top of existing features (like the workaround
    above, but with syntactic sugar), or should Sorbet have a separate concept of "opaque
    type alias"?

None of these are insurmountable, but we prefer to let real-world usage and needs guide
the features we build ("Would this have prevented an incident?" vs "Wouldn't this be
nice?")

Also, building custom syntax for this into Sorbet would give us a chance to fix the bug
mentioned above, where the opaque type isn't quite opaque enough.

### Doesn't Sorbet already have abstract classes and methods? Why prefer opaque types?

A good point! For some kinds of abstract types, [abstract classes or
interfaces](https://sorbet.org/docs/abstract) work totally fine.

But interfaces need classes to implement them. If I invent some application-specific
interface, I probably shouldn't monkey patch it into a standard library class like
`String`. The alternative would be to make some sort of wrapper class which implements the
interface:

``` ruby
class StringWrapper < T::Struct
  # (1) Wrap a String
  const :underlying, String

  # (2) Implement the interface
  include Email
  # ... override to implement the methods ...
end
```

But that means twice as many allocations (one allocation for the `StringWrapper`, one for
the `String`) and worse memory locality (the `String` isn't always in memory near the
`StringWrapper`). For frequently-allocated objects like database IDs, that can make
already slow operations even slower.

\

This trick isn't a complete substitute for opaque types, and I still would love to
implement them some day. But I love discovering clever tricks like this that people use to
make Sorbet do what they wish it could do.

*Thanks to David Judd for implementing this trick at Stripe, so that I could stumble on it.*
