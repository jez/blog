---
layout: post
title: "Prefer .then() over .catch()"
date: 2018-05-31 15:58:52 -0700
comments: false
share: false
categories: ['flow', 'fragment', 'javascript']
description: >
  When designing asynchronous APIs that could error in Flow, prefer
  using `.then` for both successful and failure cases. Flow exposes a
  relatively unsafe library definition for the `.catch` method, so it's
  best to avoid it if you can.
---

When designing asynchronous APIs that could error in Flow, prefer using
`.then` for both successful and failure cases. Flow exposes a relatively
unsafe library definition for the `.catch` method, so it's best to avoid
it if you can.

<!-- more -->

# Problem

What does this look like in practice? Say you're thinking about writing
code that looks similar to this:

<figure>

```{.js .numberLines}
// "Success" and "failure" types (definitions omitted)
import type {OkResult, ErrResult} from 'src/types';

const doSomething = (): Promise<OkResult> => {
  return new Promise((resolve, reject) => {
    // call resolve(...) when it worked, but
    // cal reject(...) when it failed.
  });
};

doSomething
  .then((res) => ...)
  .catch((err) => ...)
```

<figcaption>Bad code; don't do this</figcaption>
</figure>

This is okay code, but not great. Why? Because Flow won't prevent us
from calling `reject(...)` with something that's **not** of type
`ErrResult`, and it won't warn us when we try to use `err` incorrectly.
Concretely, if we had this type definition:

```js
type ErrResult = string;
```

Flow wouldn't prevent us from doing this:

```js
// number, not a string!
reject(42);
```

nor from doing this:

```js
// boolean, not a string!
.catch((err: boolean) => ...);
```


# Solution

As mentioned, we can work around this by only using `resolve` and
`.then`. For example, we can replace our code above with this:

<figure>

```{.js .numberLines}
// Helper function for exhaustiveness.
// See here: https://blog.jez.io/flow-exhaustiveness/
import {absurd} from 'src/absurd';

import type {OkResult, ErrResult} from 'src/types';

// Use a union type to mean "success OR failure"
type Result =
  | {|tag: 'ok', val: OkResult|}
  | {|tag: 'err', val: ErrResult|};

//     Use our new union type ──┐
const doSomething = (): Promise<Result> => {
  return new Promise((resolve, reject) => {
    // call resolve({tag: 'ok',  val: ...}) when it worked, and
    // call resolve({tag: 'err', val: ...}) when it failed
  });
};

doSomething
  // Use a switch statement in the result:
  .then((res) => {
    switch (res.tag) {
      case 'ok':
        // ...
        break;
      case 'err':
        // ...
        break;
      default:
        // Guarantees we covered all cases.
        absurd(res);
        break;
    }
  })
```

<figcaption>Better code than before</figcaption>
</figure>

There's a lot of benefits in this newer code:

- Using `resolve` is much safer than `reject`. Flow will always warn us
  if we call `resolve` with an improperly-typed input.

- Using `.then` is the same. Flow will warn for improper usage, **and**
  even correctly infer the type of `res` in our handler.

- We got exhaustiveness as a bonus. We now handle all errors, whereas
  before it was easy to forget to include a `.catch`.


# Caveats

Of course, there are some times when the you're interfacing with code
not under your control that exposes critical functionality over
`.catch`. In these cases, it's not an option to just "not use `.catch`".
Instead, you have two options.

If you trust that the library you're using will never "misbehave",
you can ascribe a narrow type to the `.catch` callback function:

```js
// If I know that throwNumber will always call `reject` with a
// number, I can stop the loose types from propagating further
// with an explicit annotation:
throwNumber
  .then(() => console.log("Didn't throw!"))
  //         ┌── explicit annotation
  .catch((n: number) => handleWhenRejected(n))
```

If you aren't comfortable putting this much trust in the API, you
should instead ascribe `mixed` to the result of the callback.

```js
throwNumber
  .then(() => console.log("Didn't throw!"))
  //         ┌── defensive annotation
  .catch((n: mixed) => {
    if (typeof n === 'number') {
      handleWhenRejected(n);
    } else {
      // Reports misbehavior to an imaginary observability service
      tracker.increment('throwNumber.unexpected_input');
    }
  });
```

<!-- vim:tw=72
-->
