;(function() {
  // Non-essential if user has JavaScript off. Just makes checkboxes look nicer.
  var selector = '.task-list > li > input[type="checkbox"]';
  var checkboxes = document.querySelectorAll(selector);
  Array.from(checkboxes).forEach((checkbox) => {
    var wasChecked = checkbox.checked;
    checkbox.disabled = false;
    checkbox.addEventListener('click', (ev) => {ev.target.checked = wasChecked});
  });
})();
