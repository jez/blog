---
layout: post
title: "Profiling in Haskell for a 10x Speedup"
date: 2019-05-20 03:13:34 +0800
comments: false
share: false
categories: ['haskell']
description: >
  I wrote up a toy project in Haskell and profiled it to learn about
  Haskell's profiling tools and about profiling code in general.
  Profiling in Haskell with Stack is super easy...
strong_keywords: false
---

I wrote up a toy project in Haskell and profiled it to learn about
Haskell's profiling tools and about profiling code in general.
Profiling in Haskell with Stack is super easy; to prove it I'll walk
through the problem I was trying to solve, my slow first solution, and
how I used Haskell's profiling tools to find and fix some egregiously
slow parts of the code.

<!-- more -->

I had three takeaways from this little project:

- Guessing at how to make code faster works sometimes, but:
- profiling in Haskell is actually super painless, and is a way better
  use of my time than guessing at what's slow.
- With repeated profiling it's definitely possible to make reasonably
  fast Haskell.

The source code and profiling data for this project is all available
[on GitHub][bingo-sim]. Also the Appendix below has a bunch of links to
help you find the interesting parts of the code.


## Problem: simulating probabilities

The problem I wanted to solve was to simulate the probability of winning
one carnival game I got to play while on vacation recently. The game
itself is super simple and purely luck-based. The rules:

1.  There's a 6 × 6 grid, each with a special character identifying it.
2.  There are 36 tiles, each with a character matching one grid space
    (and there are no duplicates, so all characters are accounted for).
3.  Initially, all tiles are placed face down.
4.  To play, a contestant chooses 15 of the 36 tiles and flips them
    over.
5.  The contestant then places the flipped tiles onto the correct spots.
6.  If placing the 15 tiles forms a bingo in any row, column, or full
    diagonal, it's a win. Otherwise, it's a loss.

The game setup in real life looked something like this:

[![Taiwan Carnival Bingo](/images/taiwan-carnival-bingo.jpg)](/images/taiwan-carnival-bingo.jpg)

([Image credit](https://www.b-kyu.com/2014/07/hua-yuan-night-market-tainan-taiwan.html))

My question was: how lucky should we considider ourselves if we win?
I'm sure I could have answered this exactly with some combinatorics, but
that seemed boring. Instead, I wanted to write a program solve it:
generate random boards, and check how many of them have bingos.


## Naive solution

In the course of playing around with this problem, I implemented a bunch
of different solutions—about 5 in total, each one faster than the next.
At a high level, each solution followed this pattern:

- generate a board uniformly at random
- count how many of the generated boards had bingos

All the solutions exploited the fact that **where** the characters on
the board are and **what** characters are on the tiles don't matter. The
only thing that matters is whether a tile ends up on a specific grid
space, which means boards can just be vectors of bits.

[Attempt #1] was *really* slow, so we won't talk about it 😅

[Attempt #2] was a little bit faster (but not by much, which made me
disappointed—more on this later). The solution looked like this:

- Our 6 × 6 grids are represented as bit-matrices in row-major order, so
  we can store them in a 64-bit unsigned int ([`Word64`]) and only use
  the 36 least significant bits. A `1` on our board means "one of the 15
  tiles we picked matched this grid spot."

- To generate a random board, we start with a board of 15 consecutive
  `1`'s (`0x7fff`) and then use the [Fisher-Yates shuffle] to shuffle
  the bits amongst the 36 available bits.

  Fisher-Yates shuffle is actually really simple, which is nice.
  Here's the [six lines][fisher-yates-bits] to implement it in Haskell
  on a bit vector:

```haskell
shuffleBits :: RandomGen g => g -> Board -> Int -> (Board, g)
shuffleBits gen board 1 = (board, gen)
shuffleBits gen (Board bs) n =
  -- (Maybe) swap the current MSB with one of the lesser bits
  let (i, gen') = randomR (0, n - 1) gen
      bs'       = swapBits bs (n - 1) i
  -- Recurse on the lesser bits
  in  shuffleBits gen' (Board bs') (n - 1)
```

- We generate 100,000 random boards using the above method, and check
  how many boards have at least one bingo.


## Clever, but not in the right ways

All told, I thought the approach in [Attempt #2] was pretty clever. It
used a single `Word64` (instead of a larger structure like a list) to
represent the board, so it should have had needed to allocate a lot. And
because it was just a `Word64`, it could use bit operations to
manipulate the board and check for bingos, avoiding the need to walk a
large structure.

But when I ran this on my 2017 MacBook Pro (i7-7920HQ CPU @ 3.10GHz, 16
GB memory), it was still really slow:

```
❯ time .stack-work/install/x86_64-osx/lts-13.21/8.6.5/bin/bingo-sim 100000
Trials:   100000
Bingos:   3529
Hit rate: 0.03529
  0.71s user  0.02s system  98% cpu  0.738 total
```

(Note that we're running `time` on the compiled binary directly, instead
of running with `stack exec --`; we don't care for the overhead from
running via Stack).

So even after using a bit vector for the board, it took 738ms. To be
clear, these results for [Attempt #2] were an improvement over my even
slower [Attempt #1], but not by much—maybe by 200ms. 700ms+ seemed
excessive.


## How to profile Haskell code

Determined to make it faster, at this point I resigned myself from
guessing and looked up how to profile Haskell code. Turns out, with
Stack it's **super** simple:

```bash
# Rebuild with profiling information
❯ stack build --profile

# Run the code with runtime profiling enabled
❯ stack exec -- bingo-sim 100000 +RTS -p -RTS
```

That's all it took, and it generated a `bingo-sim.prof` file that had a
bunch of lines that looked like this:

```
COST CENTRE              MODULE  SRC  no.  entries  %time %alloc   %time %alloc
...
  randomR                ...     ...  ...  ...       0.8    0.0    84.9   83.5
  randomIvalIntegral     ...     ...  ...  ...       6.9   13.4    84.1   83.5
   randomIvalInteger     ...     ...  ...  ...      21.3   29.2    77.2   70.1
    randomIvalInteger.f  ...     ...  ...  ...      11.0    2.4    41.5   31.5
```

There's a bunch of extra information in the actual `.prof` file (which
you can [see on GitHub][bingo-sim.2.prof]) but the important parts for
me were the four columns at the end. The first two are the proporion of
execution time and allocated memory attributable to this cost center
specifically. The last two are the same, but include the resources of
all sub cost centers.

(I found the [GHC User Guide] super helpful to learn everything I wanted
to know about this format, what a cost center is, and some tips for
profiling in general).

So the glaring thing that jumps out from the data: we're spending 85% of
our 738ms running time **generating random numbers**. All my effort
spent optimizing memory, but it was the PRNG that was slow the whole
time. 😣


## Fast PRNG in Haskell

738ms × 0.849 ≈ 600ms+ spent generating random numbers seemed like an
absurd abount of time. Non-cryptographically secure pseudo random number
generation shouldn't take this long. And indeed, after a bit of
searching I came across [this reddit thread] complaining about how slow
`System.Random` in Haskell is for PRNG, and then moments later I found
[this article] from Chris Wellons comparing various PRNGs for
performance... Exactly what I was looking for 👌

So for [Attempt #3], I took his [suggested PRNG] and ported it from
[C][xoshiro256starstar.c] to [Haskell][Prng.hs].

And lo and behold, it was faster. A lot faster:

```
❯ time .stack-work/install/x86_64-osx/lts-13.21/8.6.5/bin/bingo-sim 100000
Trials:   100000
Bingos:   3670
Hit rate: 0.0367
  0.11s user  0.01s system  90% cpu  0.126 total
```

Yep. That just went from 738ms to 126ms, for a 5.8x speedup 🤯

With a result this good, we might ask ourselves what we had to give up
in the process—things this good usually come at a price. The biggest one
that I notice is that the API I provide for random number generation is
far less generic.

My [`Prng.hs`][Prng.hs] is a direct translation of the C to Haskell. It
only generates 64-bit unsigned ints. `System.Random` has an arguably
nicer API, using type classes to generate random ints, characters, etc.,
allowing users to implement generators for their custom types, and
having helpers for generating random values within a range and sequences
of random numbers.

It's possible we could prune some of the fat from `System.Random`'s
default implementations without also changing the underlying random
number generator, and see a considerable speedup. It's also possible we
could make [`Prng.hs`][Prng.hs] export instances of the appropriate type
classes, and again also see a partial speedup.

But considering that I wasn't using any of that extra stuff, I figured
I'd just keep it simple. The code to generate random boards hardly
changed:

```haskell
shuffleBits :: Prng.State -> Board -> Int -> (Board, Prng.State)
shuffleBits gen board 1 = (board, gen)
shuffleBits gen (Board bs) n =
  let n'           = n - 1
      (rand, gen') = next gen
      -- Uses `mod` instead of `randomR` to generate within a range
      i            = rand `mod` (fromIntegral n)
      bs'          = swapBits bs n' (fromIntegral i)
  in  shuffleBits gen' (Board bs') n'
```


## Further speedups

Spurred on by the thrill of the previous speedup, I kept going. By this
time I'd learned the value in following the `.prof` output. The output
led me to [Attempt #4], which refactored the PRNG into CPS avoid
allocating a tuple, and then [Attempt #5], where I added some
`BangPatterns`.

At the end of it all, my simulation ran in just 70ms!

```
❯ time .stack-work/install/x86_64-osx/lts-13.21/8.6.5/bin/bingo-sim 100000
Trials:   100000
Bingos:   3670
Hit rate: 0.0367
  0.06s user   0.01s system   92% cpu   0.070 total
```

This is a 10x speedup over my dissapointing [Attempt #2], and a 12.8x
speedup over my super naive [Attempt #1]. Not bad for a first attempt at
profiling in Haskell!

I found this super encouraging. Given how easy the tooling is to get
started with, how well documented things are, and my satisfaction with
the results, I'm very likely to reach for profiling tools in the future.


## Appendix: Links

The entire source is [on GitHub][bingo-sim].

I wrote up all five of my attepts as separate GitHub commits, so if you
want to compare and constrast the approaches feel free:

- [Attempt #1] (899ms)
- [Attempt #2] (738ms)
- [Attempt #3] (126ms)
- [Attempt #4] (101ms)
- [Attempt #5] (70ms)

I also had never used Haddock before, so I used this project as an
opportunity to learn how to build and write Haddock. I published the
docs on GitHub pages if you want to browse them:

- [Docs](https://jez.io/bingo-sim/)

And I also put the source for all the `.prof` files I generated for each
attempt:

- [`bingo-sim.1.prof`]
- [`bingo-sim.2.prof`]
- [`bingo-sim.3.prof`]
- [`bingo-sim.4.prof`]
- [`bingo-sim.5.prof`]

If you have any questions about anything, feel free to [reach out]!


[bingo-sim]: https://github.com/jez/bingo-sim
[README]: https://github.com/jez/bingo-sim#readme

[Attempt #1]: https://github.com/jez/bingo-sim/commit/994481b
[Attempt #2]: https://github.com/jez/bingo-sim/commit/8886a66
[Attempt #3]: https://github.com/jez/bingo-sim/commit/0a04839
[Attempt #4]: https://github.com/jez/bingo-sim/commit/4048469
[Attempt #5]: https://github.com/jez/bingo-sim/commit/eafa39f

[`bingo-sim.1.prof`]: https://github.com/jez/bingo-sim/blob/master/prof/bingo-sim.1.prof
[`bingo-sim.2.prof`]: https://github.com/jez/bingo-sim/blob/master/prof/bingo-sim.2.prof
[`bingo-sim.3.prof`]: https://github.com/jez/bingo-sim/blob/master/prof/bingo-sim.3.prof
[`bingo-sim.4.prof`]: https://github.com/jez/bingo-sim/blob/master/prof/bingo-sim.4.prof
[`bingo-sim.5.prof`]: https://github.com/jez/bingo-sim/blob/master/prof/bingo-sim.5.prof

[`Word64`]: http://hackage.haskell.org/package/base-4.12.0.0/docs/Data-Word.html#t:Word64
[Fisher-Yates shuffle]: https://en.wikipedia.org/wiki/Fisher–Yates_shuffle
[fisher-yates-bits]: https://github.com/jez/bingo-sim/blob/8886a66/src/BingoSim/Simulation.hs#L111-L126

[GHC User Guide]: https://downloads.haskell.org/~ghc/latest/docs/html/users_guide/profiling.html


[this reddit thread]: https://www.reddit.com/r/haskell/comments/7ma9rd/in_your_professional_experience_how_suitable_is/
[this article]: Finding the Best 64-bit Simulation PRNG
[suggested PRNG]: http://xoshiro.di.unimi.it/
[xoshiro256starstar.c]: http://xoshiro.di.unimi.it/xoshiro256starstar.c
[Prng.hs]: https://github.com/jez/bingo-sim/blob/8886a66/src/BingoSim/Prng.hs

[reach out]: https://jez.io/


<!-- vim:tw=72
-->
