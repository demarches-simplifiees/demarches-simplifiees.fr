import scrollToComponent from 'react-scroll-to-component';
import { debounce } from '@utils';
import {
  createTypeDeChampOperation,
  destroyTypeDeChampOperation,
  moveTypeDeChampOperation,
  updateTypeDeChampOperation
} from './operations';

export default function typeDeChampsReducer(state, { type, params, done }) {
  switch (type) {
    case 'addNewTypeDeChamp':
      return addNewTypeDeChamp(state, state.typeDeChamps, done);
    case 'addFirstTypeDeChamp':
      return addFirstTypeDeChamp(state, state.typeDeChamps, done);
    case 'addNewRepetitionTypeDeChamp':
      return addNewRepetitionTypeDeChamp(
        state,
        state.typeDeChamps,
        params.typeDeChamp,
        done
      );
    case 'updateTypeDeChamp':
      return updateTypeDeChamp(state, state.typeDeChamps, params, done);
    case 'removeTypeDeChamp':
      return removeTypeDeChamp(state, state.typeDeChamps, params);
    case 'moveTypeDeChampUp':
      return moveTypeDeChampUp(state, state.typeDeChamps, params);
    case 'moveTypeDeChampDown':
      return moveTypeDeChampDown(state, state.typeDeChamps, params);
    case 'onSortTypeDeChamps':
      return onSortTypeDeChamps(state, state.typeDeChamps, params);
    case 'refresh':
      return { ...state, typeDeChamps: [...state.typeDeChamps] };
    default:
      throw new Error(`Unknown action "${type}"`);
  }
}

function addTypeDeChamp(state, typeDeChamps, insertAfter, done) {
  const typeDeChamp = {
    ...state.defaultTypeDeChampAttributes,
    order_place: typeDeChamps.length
  };

  createTypeDeChampOperation(typeDeChamp, state.queue)
    .then(async () => {
      if (insertAfter) {
        // Move the champ to the correct position server-side
        await moveTypeDeChampOperation(
          typeDeChamp,
          insertAfter.index,
          state.queue
        );
      }
      state.flash.success();
      done();
      if (insertAfter) {
        scrollToComponent(insertAfter.target.nextElementSibling);
      }
    })
    .catch(message => state.flash.error(message));

  let newTypeDeChamps = [...typeDeChamps, typeDeChamp];
  if (insertAfter) {
    // Move the champ to the correct position client-side
    newTypeDeChamps = arrayMove(
      newTypeDeChamps,
      typeDeChamps.length,
      insertAfter.index
    );
  }

  return {
    ...state,
    typeDeChamps: newTypeDeChamps
  };
}

function addNewTypeDeChamp(state, typeDeChamps, done) {
  return addTypeDeChamp(state, typeDeChamps, findItemToInsertAfter(), done);
}

function addNewRepetitionTypeDeChamp(state, typeDeChamps, typeDeChamp, done) {
  return addTypeDeChamp(
    {
      ...state,
      defaultTypeDeChampAttributes: {
        ...state.defaultTypeDeChampAttributes,
        parent_id: typeDeChamp.id
      }
    },
    typeDeChamps,
    null,
    done
  );
}

function addFirstTypeDeChamp(state, typeDeChamps, done) {
  const typeDeChamp = { ...state.defaultTypeDeChampAttributes, order_place: 0 };

  createTypeDeChampOperation(typeDeChamp, state.queue)
    .then(() => done())
    .catch(message => state.flash.error(message));

  return {
    ...state,
    typeDeChamps: [...typeDeChamps, typeDeChamp]
  };
}

function updateTypeDeChamp(
  state,
  typeDeChamps,
  { typeDeChamp, field, value },
  done
) {
  typeDeChamp[field] = value;

  getUpdateHandler(typeDeChamp, state)(done);

  return {
    ...state,
    typeDeChamps: [...typeDeChamps]
  };
}

function removeTypeDeChamp(state, typeDeChamps, { typeDeChamp }) {
  destroyTypeDeChampOperation(typeDeChamp, state.queue)
    .then(() => state.flash.success())
    .catch(message => state.flash.error(message));

  return {
    ...state,
    typeDeChamps: arrayRemove(typeDeChamps, typeDeChamp)
  };
}

function moveTypeDeChampUp(state, typeDeChamps, { typeDeChamp }) {
  const oldIndex = typeDeChamps.indexOf(typeDeChamp);
  const newIndex = oldIndex - 1;

  moveTypeDeChampOperation(typeDeChamp, newIndex, state.queue)
    .then(() => state.flash.success())
    .catch(message => state.flash.error(message));

  return {
    ...state,
    typeDeChamps: arrayMove(typeDeChamps, oldIndex, newIndex)
  };
}

function moveTypeDeChampDown(state, typeDeChamps, { typeDeChamp }) {
  const oldIndex = typeDeChamps.indexOf(typeDeChamp);
  const newIndex = oldIndex + 1;

  moveTypeDeChampOperation(typeDeChamp, newIndex, state.queue)
    .then(() => state.flash.success())
    .catch(message => state.flash.error(message));

  return {
    ...state,
    typeDeChamps: arrayMove(typeDeChamps, oldIndex, newIndex)
  };
}

function onSortTypeDeChamps(state, typeDeChamps, { oldIndex, newIndex }) {
  moveTypeDeChampOperation(typeDeChamps[oldIndex], newIndex, state.queue)
    .then(() => state.flash.success())
    .catch(message => state.flash.error(message));

  return {
    ...state,
    typeDeChamps: arrayMove(typeDeChamps, oldIndex, newIndex)
  };
}

function arrayRemove(array, item) {
  array = Array.from(array);
  array.splice(array.indexOf(item), 1);
  return array;
}

function arrayMove(array, from, to) {
  array = Array.from(array);
  array.splice(to < 0 ? array.length + to : to, 0, array.splice(from, 1)[0]);
  return array;
}

const updateHandlers = new WeakMap();
function getUpdateHandler(typeDeChamp, { queue, flash }) {
  let handler = updateHandlers.get(typeDeChamp);
  if (!handler) {
    handler = debounce(
      done =>
        updateTypeDeChampOperation(typeDeChamp, queue)
          .then(() => {
            flash.success();
            done();
          })
          .catch(message => flash.error(message)),
      200
    );
    updateHandlers.set(typeDeChamp, handler);
  }
  return handler;
}

function findItemToInsertAfter() {
  const target = getFirstTarget();

  return {
    target,
    index: parseInt(target.dataset.index) + 1
  };
}

function getFirstTarget() {
  const [target] = document.querySelectorAll('[data-in-view]');
  if (target) {
    const parentTarget = target.closest('[data-repetition]');
    if (parentTarget) {
      return parentTarget;
    }
    return target;
  }
}
