addEventListener('turbolinks:load', () => {
  const primaries = document.querySelectorAll('select[data-secondary-options]');

  for (let primary of primaries) {
    let secondary = document.querySelector(
      `select[data-secondary-id="${primary.dataset.primaryId}"]`
    );
    let secondaryOptions = JSON.parse(primary.dataset.secondaryOptions);

    primary.addEventListener('change', e => {
      let option, options, element;

      while ((option = secondary.firstChild)) {
        secondary.removeChild(option);
      }

      options = secondaryOptions[e.target.value];

      for (let option of options) {
        element = document.createElement('option');
        element.textContent = option;
        element.value = option;
        secondary.appendChild(element);
      }

      secondary.selectedIndex = 0;
    });
  }
});
