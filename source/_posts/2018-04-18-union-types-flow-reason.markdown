---
layout: post
title: "Union Types in Flow & Reason"
date: 2018-04-18 22:43:26 -0700
comments: false
share: false
categories: ['flow', 'types', 'javascript', 'reasonml']
description: >
  Union types are powerful yet often overlooked. At work, I've been using
  Flow which thankfully supports union types. But as I've refactored
  more of our code to use union types, I've noticed that our bundle size
  has been steadily increasing!
strong_keywords: false
---


Union types are powerful yet often overlooked. At work, I've been using
Flow which [thankfully supports union types][flow-union]. But as I've
refactored more of our code to use union types, I've noticed that our
bundle size has been steadily increasing!

<!-- more -->

In this post, we're going to explore why that's the case. We'll start
with a problem which union types can solve, flesh out the problem to
motivate why union types are definitely the solution, then examine the
resulting cost of introducing them. In the end, we'll compare Flow to
other compile-to-JS languages on the basis of how they represent union
types in the compiled output. I'm especially excited about [Reason], so
we'll talk about it the most.


## Setup: Union Types in a React Component

Let's consider we're writing a simple React 2FA[^2fa] modal.
We'll be using Flow, but you can pretend it's TypeScript if you want.
The mockup we were given looks like this:

[^2fa]: 2FA: two-factor authentication

[![A sample mockup for a two-factor authenticaion modal](/images/2fa-mockup.jpeg)](/images/2fa-mockup.jpeg)

In this mockup:

- There's a loading state while we send the text message.
- We'll show an input for the code after the message is sent.
- There's no failure screen (it hasn't been drawn up yet).

We'll need some way for our component to know which of the three screens
is visible. Let's use a [union type][flow-union] in Flow:

```js
type Screen =
  | 'LoadingScreen'
  | 'CodeEntryScreen'
  | 'SuccessScreen';
```

Union types are a perfect fit! 🎉  Union types document intent and can
help guard against mistakes. Fellow developers and our compiler can
know "these are all the cases." In particular, Flow can warn us when
we've [forgotten a case][absurd].

Our initial implementation is working great. After sharing it with the
team, someone suggests adding a "cancel" button in the top corner. It
doesn't make sense to cancel when the flow has already succeeded, so
we'll exclude it from the last screen:

[![Adding a close button to our modal](/images/2fa-close-btn.jpeg)](/images/2fa-close-btn.jpeg)

No problem: let's write a function called `needsCancelButton` to
determine if we need to put a cancel button in the header of a
particular screen:

```js
const needsCancelButton = (screen: Screen): boolean => {
  // Recall: 'SuccessScreen' is the last screen,
  // so it shouldn't have a cancel button.
  return screen !== 'SuccessScreen';
};
```

Short and sweet. 👌 Everything seems to be working great, until...


## `switch`: Optimizing for Exhaustiveness

The next day, we get some updated mocks from the design team. This time,
they've also drawn up a "failure" screen for when the customer has
entered the wrong code too many times:

[![The failure screen for our modal](/images/2fa-failure-screen.jpeg)](/images/2fa-failure-screen.jpeg)

We can handle this---we'll just add a case to our `Screen` type:

```js
type Screen =
  | 'LoadingScreen'
  | 'CodeEntryScreen'
  | 'SuccessScreen'
  // New case to handle too many wrong attempts:
  | 'FailureScreen';
```

But now **there's a bug** in our `needsCancelButton` function. 😧 We
should only show a close button on screens where it makes sense, and
`'FailureScreen'` is not one of those screens. Our first reaction after
discovering the bug would be to just blacklist `'FailureScreen'` too:

```js
const needsCancelButton = (screen: Screen): boolean => {
  return (
    screen !== 'SuccessScreen' ||
    screen !== 'FailureScreen'
  );
};
```

But we can do better than just fixing the **current** bug. We should
write code so that when we add a new case to a union type, our type
checker alerts us before a **future** bug even happens. What if instead
of a silent bug, we got this cheery message from our type checker?

> Hey, you forgot to add a case to `needsCancelButton` for the new
> screen you added. *🙂*
>
> --- your friendly, neighborhood type checker

Let's go back and rewrite `needsCancelButton` so that it **will** tell
us this when adding new cases. We'll use a `switch` statement with
[something special in the `default` case][absurd]:

```js
const impossible = <T>(x: empty): T => {
  throw new Error('This case is impossible.');
}

const needsCancelButton = (screen: Screen): boolean => {
  switch (screen) {
    case 'LoadingScreen':
      return true;
    case 'CodeEntryScreen':
      return true;
    case 'SuccessScreen':
      return false;
    default:
      // (I named this function 'absurd' in my earlier post:
      // https://blog.jez.io/flow-exhaustiveness/)
      // This function asks Flow to check for exhaustiveness.
      //
      // [flow]: Error: Cannot call `impossible` with `screen` bound to `x` because string literal `FailureScreen` [1] is incompatible with empty [2].
      return impossible(screen);
  }
}
```

[**(Play with it on Try Flow →)**](https://flow.org/try/#0PTAEAEDMBsHsHcBQiAuBPADgU1AZQMYBOWWAdqALyKigA+oA5ADKwCGAJgJakDmBxZBtTqMAwrHZYAoqRSE0-EqSE16DXAFd8+LAGddiwcLUAxVp2gbih5QG5k+WKV0pQnALYZY+zgCNoOBSgADwAKgB8ABQAHgBcoFie6ACU8aGU4aAA3sIoABaECKCkWPCgUoSFhJEMoXmcuqD4rLo4DW6e3rp+AQB0DMn2AL4OTi7FJOy6oqykOtAAQhooKE6UoJG6RErxNqmgvrCwAbMZ2cK68Jwo+HkbWwKkyec0NM2tjCwc3HzbgrHCV6gYgoKzkOQaLD2IHvHAMcSSGRyBR-ZQAoE0EFg0AQqGApotOGabR6AyohjojFYwjkSCsaCtaGvECgACqc1g7ncZFcq1AkE40RxeRwJjgZSwlVghHxLNhjDMFisWBsFNlYGBWFBNP59MZ+MkdI00BQlKB1PIHi8Pn8WE2qMGwhGQyAA)

Now Flow is smart enough to give us an error! Making our code safer, one
`switch` statement at a time. 😅 Union types in Flow are a powerful way
to use types to guarantee correctness. But to get the most out of union
types, **always[^always] access them** through a `switch` statement.
Every time we use a union type without an exhaustive switch statement,
we make it harder for Flow to tell us where we've missed something.

[^always]: "Always" is a very strong statement. Please use your best judgement. But know that if you're not using a `switch`, you're trading off the burden of exhaustiveness & correctness from the type checker to the programmer!


## Correctness, but at what cost?

You might not have noticed, but we paid a subtle cost in rewriting
our `needsCancelButton` function. Let's compare our two functions:

```js
// ----- before: 62 bytes (minified) -----

const needsCancelButton = (screen) => {
  return screen !== 'SuccessScreen';
};

// ----- after: 240 bytes (minified) -----

const impossible = (x) => {
  throw new Error('This case is impossible.');
};

const needsCancelButton = (screen) => {
  switch (screen) {
    case 'LoadingScreen':
      return true;
    case 'CodeEntryScreen':
      return true;
    case 'SuccessScreen':
      return false;
    default:
      return impossible(screen);
  }
};
```

With just an equality check, our function was small: 62 bytes minified.
But when we refactored to use a `switch` statement, its size shot up to
240 bytes! That's a 4x increase, just to get exhaustiveness. Admittedly,
`needsCancelButton` is a bit of a pathological case. But in general: as
we make our code bases **more safe** using Flow's union types of string
literals, our **bundle size bloats**!


## Types and Optimizing Compilers

One of the many overlooked promises of types is the claim that by
writing our code with **higher-level abstractions**, we give more
information to the compiler. The compiler can then generate code that
captures our original intent, but as efficiently as possible.

Flow is decidedly **not** a compiler: it's only a type checker. To run
JavaScript annotated with Flow types, we first strip the types (with
something like Babel). All information about the types vanishes when we
run the code.[^strip-types] What can we achieve if we were to **keep the
types around** all the way through compilation?

[^strip-types]: Even though TypeScript defines both a language **and** a compiler for that language, in practice it's not much different from Flow here. A goal of the TypeScript compiler is to generate JavaScript that closely resembles the original TypeScript, so it doesn't do compile-time optimizations based on the types.

[Reason] (i.e., ReasonML) is an exciting effort to bring all the
benefits of the OCaml tool chain to the web. In particular, Reason
works using OCaml's mature optimizing compiler alongside BuckleScript
(which turns OCaml to JavaScript) to emit great code.

To see what I mean, let's re-implement our `Screen` type and
`needsCancelButton` function, this time in Reason:

```js
type screen =
  | LoadingScreen
  | CodeEntryScreen
  | SuccessScreen;

let needsCancelButton = (screen: screen): bool => {
  switch (screen) {
  | LoadingScreen => true;
  | CodeEntryScreen => true;
  | SuccessScreen => false;
  }
};
```

Looks pretty close to JavaScript with Flow types, doesn't it? The
biggest difference is that the `case` keyword was replaced with the `|`
character. Making the way we define and use union types look the same is
a subtle reminder to always pair union types with `switch` statements!
[^copy/paste] Another difference: Reason handles exhaustiveness checking
out of the box. 🙂

[^copy/paste]: More than being a nice reminder, it makes it easy to copy / paste our type definition as boilerplate to start writing a new function!

What does the Reason output look like?

```js
// Generated by BUCKLESCRIPT VERSION 3.0.1, PLEASE EDIT WITH CARE
'use strict';

function needsCancelButton(screen) {
  if (screen >= 2) {
    return false;
  } else {
    return true;
  }
}
```

[**(Play with it on Try Reason →)**](https://reasonml.github.io/en/try.html?rrjsx=true&reason=C4TwDgpgBAzgxgJwhAdlAvAKClAPlAGQHsBDAEwEsUBzAZUWRWzygGEiyIBRFYBEeklTN8tAK5w4EGDEGMA3JkwAbCMCgpkZGKxIopygEJjgwImnRQAFPCEoAXLAaoAlI4BGRIsowA+KADezDAA7hTAcAAW1raMLoEihKSUNHKoflB8YhCKOPjsnDx8As4W-lk5ieKS0rKlGQBmJMowlTgAvpjtikA)

Not bad! Telling Reason that our function was exhaustive let it optimize
the entire `switch` statement back down to a single `if` statement. In
fact, it gets even better: when we run this through `uglifyjs`, it
removes the redundant `true` / `false`:

```js
"use strict";
function needsCancelButton(n){
  return !(n>=2)
}
```

Wow! This is actually **better** than our initial, hand-written `if`
statement. Reason compiled what used to be a string literal
`'SuccessScreen'` to just the number `2`. Reason can do this safely
because custom-defined types in Reason **aren't** strings, so it doesn't
matter if the names get mangled.

Taking a step back, Reason's type system delivered on the promise of
types in a way Flow couldn't:

- We wrote high-level, expressive code.
- The type checker gave us strong guarantees about our code's
  correctness via exhaustiveness.
- The compiler translated that all to tiny, performant output.

I'm really excited about Reason. 😄 It has a delightful type system and
is backed by a decades-old optimizing compiler tool chain. I'd love to
see more people take advantage of improvements in type systems to write
better code!


- - -


## Appendix: Other Compile-to-JS Runtimes

The above analysis only considered Flow + Babel and Reason. But then I
got curious about how other typed languages that compile to JavaScript
compare on the optimizations front:

### TypeScript

Despite being a language **and** compiler, TypeScript maintains a
goal of compiling to JavaScript that closely resembles the source
TypesScript code. TypeScript also has two language constructs for
working with exhaustiveness:

- union types, analogous to what Flow has, and
- `enum`s, which are basically like Java's `enum`s.

With union types, TypeScript behaves basically the same as Flow 🙁. But
what was surprising: `enum`s compressed **even worse**:

```js
var Screen_;
(function (Screen_) {
    Screen_[Screen_["LoadingScreen"] = 0] = "LoadingScreen";
    Screen_[Screen_["CodeEntryScreen"] = 1] = "CodeEntryScreen";
    Screen_[Screen_["SuccessScreen"] = 2] = "SuccessScreen";
})(Screen_ || (Screen_ = {}));
var impossible = function (x) {
    throw new Error('This case is impossible.');
};
var needsCancelButton = function (screen) {
    switch (screen) {
        case Screen_.LoadingScreen:
            return true;
        case Screen_.CodeEntryScreen:
            return true;
        case Screen_.SuccessScreen:
            return false;
        default:
            return impossible(screen);
    }
};
```

[**TypeScript Playground →**][typescript]

[typescript]: https://www.typescriptlang.org/play/#src=enum%20Screen_%20%7B%0D%0A%20%20%20%20LoadingScreen%2C%0D%0A%20%20%20%20CodeEntryScreen%2C%0D%0A%20%20%20%20SuccessScreen%2C%0D%0A%7D%0D%0A%0D%0Aconst%20impossible%20%3D%20%3CT%3E(x%3A%20never)%3A%20T%20%3D%3E%20%7B%0D%0A%20%20throw%20new%20Error('This%20case%20is%20impossible.')%3B%0D%0A%7D%0D%0A%0D%0Aconst%20needsCancelButton%20%3D%20(screen%3A%20Screen_)%3A%20boolean%20%3D%3E%20%7B%0D%0A%20%20switch%20(screen)%20%7B%0D%0A%20%20%20%20case%20Screen_.LoadingScreen%3A%0D%0A%20%20%20%20%20%20return%20true%3B%0D%0A%20%20%20%20case%20Screen_.CodeEntryScreen%3A%0D%0A%20%20%20%20%20%20return%20true%3B%0D%0A%20%20%20%20case%20Screen_.SuccessScreen%3A%0D%0A%20%20%20%20%20%20return%20false%3B%0D%0A%20%20%20%20default%3A%0D%0A%20%20%20%20%20%20return%20impossible(screen)%3B%0D%0A%20%20%7D%0D%0A%7D

- It's not smart enough to optimize away the `impossible` call.
- It keeps around a JavaScript object representing the collection of
  enum values at run time, in a format that doesn't minify well.


## PureScript

PureScript is another high-level language like Reason. Both Reason and
PureScript have data types where we can define unions with custom
constructor names. Despite that, PureScript's generated code is
significantly worse than Reason's.

```js
"use strict";
var LoadingScreen = (function () {
    function LoadingScreen() {};
    LoadingScreen.value = new LoadingScreen();
    return LoadingScreen;
})();
var CodeEntryScreen = (function () {
    function CodeEntryScreen() {};
    CodeEntryScreen.value = new CodeEntryScreen();
    return CodeEntryScreen;
})();
var SuccessScreen = (function () {
    function SuccessScreen() {};
    SuccessScreen.value = new SuccessScreen();
    return SuccessScreen;
})();
var needsCancelButton = function (v) {
    if (v instanceof LoadingScreen) {
        return true;
    };
    if (v instanceof CodeEntryScreen) {
        return true;
    };
    if (v instanceof SuccessScreen) {
        return false;
    };
    throw new Error("Failed pattern match at Main line 10, column 1 - line 10, column 39: " + [ v.constructor.name ]);
};
```

- It's generating ES5 classes for each data constructor.
- It compiles pattern matching to a series of `instanceof` checks.
- Even though it **knows** the match is exhaustive, it still emits a
  `throw` statement in case the pattern match fails!

Admittedly, I didn't try that hard to turn on optimizations in the
compiler. Maybe there's a flag I can pass to get this `Error` to go
away. But that's pretty disappointing, compared to how small Reason's
generated code was!

## Elm

I list Elm in the same class as Reason and PureScript. Like the other
two, it lets us define custom data types, and will automatically warn
when us pattern matches aren't exhaustive. Here's the code Elm
generates:

```js
var _user$project$Main$needsCancelButton = function (page) {
	var _p0 = page;
	switch (_p0.ctor) {
		case 'LoadingScreen':
			return true;
		case 'CodeEntryScreen':
			return true;
		default:
			return false;
	}
};
var _user$project$Main$SuccessScreen = {ctor: 'SuccessScreen'};
var _user$project$Main$CodeEntryScreen = {ctor: 'CodeEntryScreen'};
var _user$project$Main$LoadingScreen = {ctor: 'LoadingScreen'};
```

- It's using string literals, much like Flow and TypeScript.
- It's smart enough to collapse the last case to just use `default`
  (at least it doesn't `throw` in the `default` case!)
- The variable names are long, but these would still minify well.

It's interesting to see that even though Reason, PureScript, and Elm all have ML-style datatypes, Reason is the only one that uses an integer representation for the constructor tags.


[flow-union]: https://flow.org/en/docs/types/unions/
[absurd]: /flow-exhaustiveness/
[Reason]: https://reasonml.github.io/


<!-- vim:tw=72
-->
