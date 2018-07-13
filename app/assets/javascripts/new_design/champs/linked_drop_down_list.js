document.addEventListener('turbolinks:load', function() {
  var primaries, i;

  primaries = document.querySelectorAll('select[data-secondary-options]');
  for (i = 0; i < primaries.length; i++) {
    primaries[i].addEventListener('change', function(e) {
      var option, options, element, primary, secondary, secondaryOptions;

      primary = e.target;
      secondary = document.querySelector('select[data-secondary-id="' + primary.dataset.primaryId + '"]');
      secondaryOptions = JSON.parse(primary.dataset.secondaryOptions);

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
