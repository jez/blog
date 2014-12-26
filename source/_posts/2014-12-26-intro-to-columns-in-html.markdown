---
layout: post
title: "Intro to Columns in HTML"
date: 2014-12-26 12:00:00 -0600
comments: true
categories: [html, webdev, best-practices]
description: >
  A simple introduction to columns and designing with a grid in HTML & CSS.
image:
  feature: /images/lincoln-memorial-columns.jpg
  credit: Wikimedia Commons
  creditlink: http://upload.wikimedia.org/wikipedia/commons/5/5d/Lincoln_memorial_columns.jpg
share: true
---

HTML and CSS can be frustrating when first starting out. Despite all you try, nothing is in the right place. I've advised more than a few friends on how to figure out this mystery and I've noticed a pattern: people don't realize they should be using a grid.

<!-- more -->

## Positioning Content

When something doesn't align correctly on the page, a natural phrase to Google is "make div align right" or "move div up." In other media where content is positioned absolutely, like when using text boxes in Microsoft Word, these might be the right queries. With HTML & CSS, though, they're off point. Don't get me wrong, there's definitely a time for `position: absolute`, but if this comes up when you're trying to make grids you're likely on the wrong path.

In HTML, the page is drawn from top to bottom, left to right. This means that your page ends up being aligned how words in a book are. Once the first word has taken up a certain amount of space, the next word starts filling up the space after it. The trick then, is knowing _how much_ space the first item takes up, and how to resize it appropriately so that the second item "falls into place."

## Blocks and Inline Elements

The easiest way to explain block and inline elements is to continue our book analogy. Block elements are like titles and headings---they take up the entire page width, spanning from the left border to the right border. That's why if you put two headings as close as possible to each other, they'll still each have their own lines. There's no "room" for it to be any other way! Meanwhile, inline elements are like individual words. Where one word stops, the next one begins. A word takes up no more space than is required to size it compactly.

Disregarding some special cases, _every HTML element_ falls into one of these two categories. Below are some examples of block elements and inline elements:

| Block | Inline   |
|:-----:|:--------:|
| `div` | `span`   |
| `h1`  | `a`      |
| `p`   | `strong` |
| `ul`  | `image`  |
| `li`  | `br`     |
| `pre` | `button` |

We know that we need to use a div to house our columns. The problem is, divs are a block elements, so they'll span the whole width of the page. Luckily, there's a relatively simple (though non-intuitive) fix to get our divs to line up.

## Floating Content

Let's take a look at what we've got so far. We want to have two columns, so our HTML is going to look like this:

```html HTML for two columns
<div class="row">
  <div class="left column">
    <!-- Your left content here -->
  </div>
  <div class="right column">
    <!-- Your right content here -->
  </div>
</div>
```

Straightforward enough. Knowing what we know about block elements, what if we just set the width of the columns to 50%?

```css Half-width columns
.column {
  /* arbitrary value for this example */
  height: 300px;

  width: 50%;
}

/* so we can tell them appart */
.left { background: red; }
.right { background: blue; }
```

[Let's try it out and see what happens][pen1]

Uh oh, it looks like our columns aren't next to each other! In fact, it looks suspciously like something we mentioned earlier: if two page headings are as close together as possible, they'll still be placed on their own lines. We can verify that this is the case by using the [Chrome dev tools][chromedev]. Inspecting the red div, we see the culprit:

{% img /images/left-column-margin.png %}

For those familiar with the Chrome dev tools, that yellow-orange box is Chrome's attempt to show us the invisible _margin_ present on our div. Since divs are block elements, by default there's enough margin on the div to make it fill up the whole width of the page.

The solution, if you saw from the CodePen, is to add the property `float: left` to the columns. This essentially instructs the browser not to add that extra margin: instead of being positioned absolutely between the two sides of the screen, it should float to one side and forget about the other. This leaves room for the second column to file into place next to it.

Go [back to the pen][pen1] and uncomment the relevant line. [Observe][pen2] that we've accomplished exactly what we wanted to.

## Going Forward

Cool, this solves the problem of having two columns! What's next?

- How would we make three columns? Four columns? Twelve columns?
- Once we have multiple columns, how can we skip columns? (__Hint__: just because we have a column doesn't mean we have to put something in it)
- We can add multiple rows by duplicating the outer "row" div.
    - What if we want two 33%-width columns in the first row, but one 33%-width column in the second row? (This is actually a good one to work through. You might want to look into the `clear: both` CSS property)
- The `border-left` and `border-right` CSS properties allow us to add a border to a div. We can even use _fancy CSS queries_ (see below) to only add a border in between columns. But if we add a border, the columns overflow onto their own rows! Can you fix this?
    - __Warning__: this one is the hardest. You will want to look into `box-sizing: border-box` and the "CSS box model"

As it turns out, HTML/CSS grids are a very heavily studied point of design. So much so, that people build entire _CSS frameworks_ around providing the building blocks to make grids easily. Here's a list:

- [Bootstrap][bootstrap]
- [Foundation][foundation]
- [Semantic UI][semantic]
- [Unsemantic][unsemantic]

Bootstrap is by far the most common (once you see it, you'll start to realize how many sites look incredibly similar). However, many people misuse Bootstrap their first time around. [This article][whygrid] demystifies and documents how and why the Bootstrap 3 grid works.

Even once you're an HTML and CSS master, it can still be frustrating. (Actually, I'd believe it if the experts were the most frustrated!). I love answering question and trying to explain things, so if you need some help working through the exercises above or you're working on a personal project, I'd love to see if I can help out! Protip: put your code on GitHub or somewhere else that's easily accessible so that it's easy to share changes quickly.

## Appendix

I mentioned an example about "fancy CSS queries" above. This is certainly advanced territory, but it's something that I get asked a lot by beginners so here goes.

Basically, the problem is that you only want vertical line separators in between columns, not on the edges. In ASCII art:

```plain Beautiful ASCII Art Diagram

        |        |
  col1  |  col2  | col 3
        |        |

        ^        ^
        | these. |
```

(Thank you, thank you, I know my drawings are beautiful XD).

You already know that you can use `.class` and `#id` to select items based on their classes and IDs. But there are [tons more query selectors][csssel] you can use! I'll use one to accomplish what we want with the vertical dividers:

```css Super Fancy CSS Selectors
.column {
  height: 300px;
  /* Try uncommenting me! */
  float: left;
  width: 50%;
  /* this kind of solves the "overflow" exersise I posted above YOLO */
  box-sizing: border-box;
}

/* marvel at the fanciness! */
.column:not(:last-child) {
  border-right: 5px solid black;
}

.left { background: red; }
.right { background: blue; }
```

You can combine this with a nice padding (`padding: 50px` should do the trick) on the `.column`, and you've got yourself a vertical divider!

## Update

After writing this post, I discovered a couple articles talking about the new
`flexbox` feature. From what I can tell, it looks promising in terms of ease of
use and browser compatibility. That being said, many common CSS frameworks still
use `float: left`, so the content presented here is still good information to
know. If you're having trouble getting floats to work, though, maybe you should
look into `flexbox` instead!


{% include jake-on-the-web.markdown %}

[pen1]: http://codepen.io/Z1MM32M4N/pen/qENvdx?editors=110
[pen2]: http://codepen.io/Z1MM32M4N/pen/XJKGdg?editors=110
[chromedev]: https://developer.chrome.com/devtools

[bootstrap]: http://getbootstrap.com/
[foundation]: http://foundation.zurb.com/
[semantic]: http://semantic-ui.com/
[unsemantic]: http://unsemantic.com/

[whygrid]: http://www.helloerik.com/the-subtle-magic-behind-why-the-bootstrap-3-grid-works
[csssel]: http://code.tutsplus.com/tutorials/the-30-css-selectors-you-must-memorize--net-16048
