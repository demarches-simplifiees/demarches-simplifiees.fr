document.addEventListener('turbolinks:load', function() {
  var primaries, i, primary, secondary, secondaryOptions;

  primaries = document.querySelectorAll('select[data-secondary-options]');
  for (i = 0; i < primaries.length; i++) {
    primary = primaries[i];
    secondary = document.querySelector('select[data-secondary-id="' + primary.dataset.primaryId + '"]');
    secondaryOptions = JSON.parse(primary.dataset.secondaryOptions);

    primary.addEventListener('change', function(e) {
      var option, options, element;

      while ((option = secondary.firstChild)) {
        secondary.removeChild(option);
      }

      options = secondaryOptions[e.target.value];

      for (i = 0; i < options.length; i++) {
        option = options[i];
        element = document.createElement("option");
        element.textContent = option;
        element.value = option;
        secondary.appendChild(element);
      }

      secondary.selectedIndex = 0;
    });
  }
});
