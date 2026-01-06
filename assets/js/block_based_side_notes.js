;(function() {
  function hoistAbove() {
    const toHoist = document.querySelectorAll('main > .sidenote-wrapper + :not(.sidenote-wrapper)');
    for (let i = toHoist.length - 1; i >= 0; i--) {
      const source = toHoist[i];
      let target = source.previousElementSibling;
      while (target.previousElementSibling?.classList.contains('sidenote-wrapper')) {
        target = target.previousElementSibling;
      }
      source.parentNode.insertBefore(source, target);
    }
  }

  function sinkBelow() {
    const toHoist = document.querySelectorAll('main > :not(.sidenote-wrapper) + .sidenote-wrapper');
    for (let i = 0; i < toHoist.length; i++) {
      const source = toHoist[i].previousElementSibling;
      let target = source.nextElementSibling;
      while (target.classList.contains('sidenote-wrapper')) {
        target = target.nextElementSibling;
      }
      source.parentNode.insertBefore(source, target);
    }
  }

  if (window.matchMedia('screen')) {
    if (window.innerWidth <= 796) {
      hoistAbove();
    }
    let prevSize = window.innerWidth;
    // Needs to mirror breakpoints in :root settings in CSS variables
    // 745px = --main-width-narrow
    // 26px = --line-height
    // 169px = side note min width narrow
    const breakpoint = 26 + 550 + 26 + 169 + 26 - 1;
    window.addEventListener('resize', function() {
      const newSize = window.innerWidth;
      if (prevSize >= breakpoint && newSize < breakpoint) {
        hoistAbove();
      } else if (prevSize < breakpoint && newSize >= breakpoint) {
        sinkBelow();
      }
      prevSize = newSize;
    });
  }
})();
