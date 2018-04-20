---
layout: post
title: "Case Exhaustiveness in Flow"
date: 2018-04-15 20:02:26 -0700
comments: false
share: false
categories: ['javascript', 'types', 'flow', 'programming']
description: >
  Compared to some other languages, Flow's story around exhaustiveness
  checking within 'if / else' and 'switch' statements leaves something to
  be desired. By default, Flow doesn't do any exhaustiveness checks! But
  we can opt-in to exhaustiveness checking one statement at a time.
  In this post, we'll discover from the ground up how Flow's
  exhaustiveness checking behaves.
strong_keywords: false
---

Compared to some other languages, [Flow]'s story around exhaustiveness
checking within `if / else` and `switch` statements leaves something to
be desired. By default, Flow doesn't do any exhaustiveness checks! But
we **can** opt-in to exhaustiveness checking one statement at a time.

[Flow]: https://flow.org/

In this post, we'll discover from the ground up how Flow's
exhaustiveness checking behaves. But if you're just looking for the
result, here's a snippet:

## TL;DR

```js
type A = {tag: "A"};
type B = {tag: "B"};
type AorB = A | B;

const absurd = <T>(x: empty): T => {
  throw new Error('This function will never run!');
}

const allGood = (x: AorB): string => {
  if(x.tag === "A") {
    return "In branch A";
  } else if (x.tag === "B") {
    return "In branch B";
  } else {
    return absurd(x);
  }
}

const forgotTagB = (x: AorB): string => {
  if(x.tag === "A") {
    return "In branch A";
  } else {
    // B. This type is incompatible with the expected param type of empty.
    return absurd(x);
  }
}
```

## How Exhaustiveness Behaves in Flow

[**Read on flow.org/try/**](https://flow.org/try/#0PTAEAEDMBsHsHcBQiQrACQKYCdOnngBYCGAbnsaAC4CeADngOQCCs2AQo-gJZWHXxYoUsWzdiAOyoBnNIloNQzUAF5QAbyrEA5gC5QAImYGAvgG559PO1Uatew+1MWFeVh1vKAPqHYXEAMawEtJUoJASAIy2ABQAHvru7ACU+qFiEtqqAHwaiKCg3JDxAHT2qipqRgbJ6vkFoLhUAK7YEoYAku0ARtiSAfzGFgUmoJjQ0nh1DY2YLW2dPX0SA74Gw6AmiFtyIErQ0Pjjh5IAJqDasLCnADSg3c1h8CRhRUegxKfnlBKY8KABYiTAD8aFAADE2GM4sQALZ0aCYO4EWaQYgBKhQvgUbqwcjhbiI0AAPWoQmx93GCF0cksigAwrZNDp9AZ6c46W42Ow2Iy1N5fKAfPT-EEQmEIgAmWIJJTc3mpUDpbiZHJ5ApFUrlSpVYzJdUNJqtdoGLr3ZarIb1UbjSYGgpGhampb9fhODZbHaoPYAdWIvA+SswYtuhTCrgBhGDAGtpABCMEAFRejGklMBzTtKMzmG+AOIVAGAFpiAdQIxbZguL1XSVdmAfS9CpB3rDiNG8Jh0fwayt+Jg4gjuAFeKDUGCAKIAJSnAHkp-oZkvl6BADCkgABSQBtpIA4P6VVAy2hKoGT3DTEdPhRWsHhBe43SJ8F4-EkhXh0GHvGgNCLjt+52aEinJgkAqrmdZiqE4QSAAzDKiTytg9KKsqqoqLk0zNlqOgVLqNT2rM8wmmavaWus1pjBMeBvFhWQ6o4eEYQ6czGos5qumsHrbMg3pgAAClG8B3NIQi8KmsywiqpwqlkmbUE2BCMLgoASLAYRBOQB4fGWFKApM0h1nsAAycxiZ85wUr8-yMPSXC6ZgNLjns05zguK5uQUG47nuB5HieZ5WIUaYqkEN5UHeD5Ph87TcG+H5UF+P7MW0uagABQEgX+4HBJBEQACxwXKHAKmk+7SWqGGanEZTYXR1T6oxBEsc6bF9koZEjBRdrUVV2qVPR9X1ExhGsSRbrtZsnVUS2NE4YY7IDTMv4jRa-DspxXrAGCfoBpQkwhiUB1hnuhKHHwKqxnJBattw2iEGES1pcBoGnAmezsI8RyMPi6Uqrw4w0ACeI4ClpanVG+Z6UeuhnRI0bSQA+miAT2fWoCNldKL0swAByoCnCJaZmYG6XEM00BqUCSL3B9QLRhCcD-JioC8XOABqE6XU8eCAhIjBhNocxycDDmbYE2UShIACsBVJMV3llWhBqVdVtF9XV+FLc1o1tR6k3NqAM21U4C2GklREuq17rkZW+uG2r80a2by3sWt1uUfh8T6Jg8K0MkGwFHw2AIMpfygBO2BB9gMSMMQ3TSK0pyMH71pcajyZMIHweWWHEdsFw76-B8uL4o+Za-BpjQAXc3TBqTkxgqJaYqWEdCwNI0jhXgTMQfuzQYoGIjQM0eCwC2EYVj7NCMGCMQGOnSmiHgKnCKWw9Be0FLe3QtBBlQNSox0LYop8sDb3JF50AWVA4O0mAaTQzzA8iVbnJMXeEBeOCR6AsKYO3OiYAbkfPAkA2CXHDEIImFlQ52XCFCekItkA9yggANhlghJCJVNKKwqsUHqNU1Z6kdsNLWK0dZuy6tNfBqsqjG2IU1YiZCrYdRtg1PY9JfIf38ooC8wVryXzCvePAj4+BjEnnWGYnsxHbxoMnGYmd-jZ3DpHaOsd47YETnIzYqceL02DtfA4aZZIGCwDQO4HQ4FpUDPSOMoAADKQgLFBDJqcXmLcg74j4FdM6aZpAiNWPAIE0ISCZjCuQEoBhUbvXDFw0AAjr4LAvNId8t14oA0kCpGgZUmY5mrrXHMYc7GGRVGpfh0B-QhBFqAXIKkiwARzKcIsA46C4HbtwbK+gJyDmDNfb47QgQd20BIX+UhQBQkgABDE7T2iAjLGcS8oQuyv2IP8F8zTWkd2CAZTavpuYvhAnEc+aZugAyRpiTSFJ4k30vEzSgUZoAMGwOESZYVgiILBDHOOCcuAXgsnCbm15YTBC-KlSY5xKyPyUqAp5PjnkrFeRII8kInkDjhAiFGew7pUDoNIXQIASABGjAAkoJBpAdgOCUMBwBL6EoAcAUgsBuCNIAAwlAAOwlEiMAfGARpDAAACIFmIEWVmjLTgkqoLCaAABiUgug1EJzFuKIu6jzhqAADyJmyFIrevt9CJnKvUBRId-jKLYKor5Gik4WHMEg8WUE2XoKKohZCpVULoXqMrXquETZDQYRbUiusbbdRVrNAwdCGqa0YexZhE1g1UNDbVB2kanakJduNG07sU3DQVRo+IWjPSDSXEqnKEgAAcTqeQuqwQrD1Go8GJsIQxItUaA2DAzXrEN3r+r0KdNGy2HbWFFvYZw35AVeFXlCp3HgojN7dIxClS+fRYTUACqPaRtAJGmxzZa04+b1pAA)

Here we have a type `AorB` with two variants;

```js
type A = {tag: "A"};
type B = {tag: "B"};
type AorB = A | B;

const fn1 = (x: AorB): string => {
  if(x.tag === "A"){
    return "In branch A";
  } else {
    return "In branch B";
  }
}
```

All well and good, but what if we add a new case?
For example, what if we take the snippet above and add this:

```js
type C = {tag: "C"};
type AorBorC = A | B | C;

const fn2 = (x: AorBorC): string => {
  if(x.tag === "A") {
    return "In branch A";
  } else {
    return "In branch B";
  }
}
```

Wait a second, it type checks!

That's because we used a catch-all `else` branch. What if we make each
branch explicit?

```js
// ERROR:                 ┌─▶︎ string. This type is incompatible with an implicitly-returned undefined.
const fn3 = (x: AorBorC): string => {
  if(x.tag === "A") {
    return "In branch A";
  } else if (x.tag === "B") {
    return "In branch B";
  }
}
```


Phew, so it's reminding us that we're not covering all the cases.
Let's add the new `C` case:

```js
// ERROR:                 ┌─▶︎ string. This type is incompatible with an implicitly-returned undefined.
const fn4 = (x: AorBorC): string => {
  if(x.tag === "A") {
    return "In branch A";
  } else if (x.tag === "B") {
    return "In branch B";
  } else if (x.tag === "C") {
    return "In branch C";
  }
}
```


Hmm: it still thinks that we might return `undefined`, even though we've
definitely covered all the cases... 🤔

What we **can** do is add a default case, but ask Flow to **prove** that
we can't get there, using Flow's `empty` type:

```js
const fn5 = (x: AorBorC): string => {
  if(x.tag === "A") {
    return "In branch A";
  } else if (x.tag === "B") {
    return "In branch B";
  } else if (x.tag === "C") {
    return "In branch C";
  } else {
    (x: empty);
    throw new Error('This will never run!');
  }
}
```


The `throw new Error` line above will never run, because it's not
possible to construct a value of type `empty`.[^empty] ("There are no
values in the empty set.")

[^empty]: Of course, this presumes that Flow's type system is sound, which it isn't. It's possible to accidentally inhabit `empty` if you use `any`! Moral of the story: be *very* diligent about eradicating `any`.

If we adopt this pattern everywhere, we'd see this error message if we
forgot to add the new case for `C`:

```js
const fn6 = (x: AorBorC): string => {
  if(x.tag === "A") {
    return "In branch A";
  } else if (x.tag === "B") {
    return "In branch B";
  } else {
    // C. This type is incompatible with empty.
    (x: empty);
    throw new Error('absurd');
  }
}
```

Flow tells us "Hey, I found a C! So I couldn't prove that this switch
was exhaustive."

But this pattern is slightly annoying to use, because ESLint complains:

```
no-unused-expressions: Expected an assignment or function call and instead saw an expression.
```

We can fix this by factoring that `empty ... throw` pattern into a
helper function:

```js
// 'absurd' is the name commonly used elsewhere for this function. For example:
// https://hackage.haskell.org/package/void-0.7.1/docs/Data-Void.html#v:absurd
const absurd = <T>(x: empty): T => {
  throw new Error('absurd');
};

const fn7 = (x: AorBorC): string => {
  if(x.tag === "A") {
    return "In branch A";
  } else if (x.tag === "B") {
    return "In branch B";
  } else if (x.tag === "C") {
    return "In branch C";
  } else {
    return absurd(x);
  }
}

const fn8 = (x: AorBorC): string => {
  if(x.tag === "A") {
    return "In branch A";
  } else if (x.tag === "B") {
    return "In branch B";
  } else {
    // C. This type is incompatible with the expected param type of empty.
    return absurd(x);
  }
}
```

So there you have it! You can put that helper function (`absurd`) in a
file somewhere and import it anywhere. You could even give it a
different name if you want! I've been using this pattern in all the Flow
code I write these days and it's been nice to rely on it when doing
refactors.


<!-- vim:tw=72
-->
