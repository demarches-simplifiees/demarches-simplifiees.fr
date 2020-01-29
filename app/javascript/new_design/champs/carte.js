async function initialize() {
  const elements = document.querySelectorAll('.carte');

  if (elements.length) {
    for (let element of elements) {
      loadAndDrawMap(element);
    }
  }
}

async function loadAndDrawMap(element) {
  const data = JSON.parse(element.dataset.geo);
  const editable = element.classList.contains('edit');

  if (editable) {
    const { drawEditableMap } = await import('../../shared/carte-editor');

    drawEditableMap(element, data);
  } else {
    const { drawMap } = await import('../../shared/carte');

    drawMap(element, data);
  }
}

async function loadAndRedrawMap(element, data) {
  const { redrawMap } = await import('../../shared/carte-editor');

  redrawMap(element, data);
}

addEventListener('turbolinks:load', initialize);

addEventListener('carte:update', ({ detail: { selector, data } }) => {
  const element = document.querySelector(selector);

  loadAndRedrawMap(element, data);
});
