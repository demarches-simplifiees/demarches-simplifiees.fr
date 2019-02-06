import Vue from 'vue';
import Draggable from 'vuedraggable';

import DraggableItem from './DraggableItem';
import DraggableList from './DraggableList';

Vue.component('Draggable', Draggable);
Vue.component('DraggableItem', DraggableItem);

addEventListener('DOMContentLoaded', () => {
  const el = document.querySelector('#champs-editor');
  if (el) {
    initEditor(el);
  }
});

function initEditor(el) {
  const { directUploadUrl, dragIconUrl, saveUrl } = el.dataset;

  const state = {
    typesDeChamp: JSON.parse(el.dataset.typesDeChamp),
    typesDeChampOptions: JSON.parse(el.dataset.typesDeChampOptions),
    directUploadUrl,
    dragIconUrl,
    saveUrl,
    isAnnotation: el.dataset.type === 'annotation',
    prefix: 'procedure',
    inFlight: 0,
    flash: new Flash()
  };

  // We add an initial type de champ here if form is empty
  if (state.typesDeChamp.length === 0) {
    state.typesDeChamp.push({
      type_champ: 'text',
      types_de_champ: []
    });
  }

  new Vue({
    el,
    data: {
      state
    },
    render(h) {
      return h(DraggableList, {
        props: {
          state: this.state
        }
      });
    }
  });
}

class Flash {
  constructor(isAnnotation) {
    this.element = document.querySelector('#flash_messages');
    this.isAnnotation = isAnnotation;
  }
  success() {
    if (this.isAnnotation) {
      this.add('Annotations privées mises à jour.');
    } else {
      this.add('Formulaire mis à jour.');
    }
  }
  error(message) {
    this.add(message, true);
  }
  clear() {
    this.element.innerHTML = '';
  }
  add(message, isError) {
    const html = `<div id="flash_message" class="center">
      <div class="alert alert-fixed ${
        isError ? 'alert-danger' : 'alert-success'
      }">
        ${message}
      </div>
    </div>`;

    this.element.innerHTML = html;

    setTimeout(() => {
      this.clear();
    }, 6000);
  }
}
