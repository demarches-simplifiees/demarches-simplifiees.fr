import Vue from 'vue';
import Draggable from 'vuedraggable';
import { fire, debounce } from '@utils';

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
  const { directUploadsUrl, dragIconUrl } = el.dataset;

  const state = {
    typesDeChamp: JSON.parse(el.dataset.typesDeChamp),
    typesDeChampOptions: JSON.parse(el.dataset.typesDeChampOptions),
    directUploadsUrl,
    dragIconUrl,
    isAnnotation: el.dataset.type === 'annotation',
    unsavedItems: new Set(),
    unsavedInvalidItems: new Set(),
    version: 1
  };

  new Vue({
    el,
    data: {
      state,
      update: null
    },
    render(h) {
      return h(DraggableList, {
        props: {
          state: this.state,
          update: this.update,
          updateAll: this.updateAll
        }
      });
    },
    mounted() {
      const [update, updateAll] = createUpdateFunctions(
        this,
        state.isAnnotation
      );

      this.update = update;
      this.updateAll = updateAll;
    }
  });
}

function createUpdateFunctions(app, isAnnotation) {
  let isSaving = false;
  const form = app.$el.closest('form');

  const update = ([id, isValid], refresh = true) => {
    app.state.unsavedItems.add(id);
    if (isValid) {
      app.state.unsavedInvalidItems.delete(id);
    } else {
      app.state.unsavedInvalidItems.add(id);
    }
    if (refresh) {
      app.state.version += 1;
    }
    updateAll();
  };

  const updateAll = debounce(() => {
    if (isSaving) {
      updateAll();
    } else if (
      app.state.typesDeChamp.length > 0 &&
      app.state.unsavedInvalidItems.size === 0
    ) {
      isSaving = true;
      app.state.unsavedItems.clear();
      app.state.version += 1;
      fire(form, 'submit');
    }
  }, 500);

  addEventListener('ProcedureUpdated', event => {
    const { types_de_champ, types_de_champ_private } = event.detail;

    app.state.typesDeChamp = isAnnotation
      ? types_de_champ_private
      : types_de_champ;
    isSaving = false;
    updateFileInputs();
  });

  return [update, updateAll];
}

// This is needed du to the way ActiveStorage javascript integration works.
// It is built to be used with traditional forms. Another way would be to not use
// high level ActiveStorage abstractions (and maybe this is what we should do in the future).
function updateFileInputs() {
  for (let element of document.querySelectorAll('.direct-upload')) {
    let hiddenInput = element.nextElementSibling;
    let fileInput = hiddenInput.nextElementSibling;
    element.remove();
    hiddenInput.remove();
    fileInput.value = '';
    fileInput.removeAttribute('disabled');
  }
}
