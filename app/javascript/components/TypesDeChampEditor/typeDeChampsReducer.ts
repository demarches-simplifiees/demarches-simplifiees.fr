import { debounce } from '@utils';
import {
  createTypeDeChampOperation,
  destroyTypeDeChampOperation,
  moveTypeDeChampOperation,
  updateTypeDeChampOperation,
  estimateFillDuration
} from './operations';
import type { TypeDeChamp, State, Flash, OperationsQueue } from './types';

type AddNewTypeDeChampAction = {
  type: 'addNewTypeDeChamp';
  done: (estimatedFillDuration: number) => void;
};

type AddNewRepetitionTypeDeChampAction = {
  type: 'addNewRepetitionTypeDeChamp';
  params: { typeDeChamp: TypeDeChamp };
  done: (estimatedFillDuration: number) => void;
};

type UpdateTypeDeChampAction = {
  type: 'updateTypeDeChamp';
  params: {
    typeDeChamp: TypeDeChamp;
    field: keyof TypeDeChamp;
    value: string | boolean;
  };
  done: (estimatedFillDuration: number) => void;
};

type RemoveTypeDeChampAction = {
  type: 'removeTypeDeChamp';
  params: { typeDeChamp: TypeDeChamp };
  done: (estimatedFillDuration: number) => void;
};

type MoveTypeDeChampUpAction = {
  type: 'moveTypeDeChampUp';
  params: { typeDeChamp: TypeDeChamp };
};

type MoveTypeDeChampDownAction = {
  type: 'moveTypeDeChampDown';
  params: { typeDeChamp: TypeDeChamp };
};

type OnSortTypeDeChampsAction = {
  type: 'onSortTypeDeChamps';
  params: { oldIndex: number; newIndex: number };
};

type RefreshAction = {
  type: 'refresh';
  params: { estimatedFillDuration: number };
};

export type Action =
  | AddNewTypeDeChampAction
  | AddNewRepetitionTypeDeChampAction
  | UpdateTypeDeChampAction
  | RemoveTypeDeChampAction
  | MoveTypeDeChampUpAction
  | MoveTypeDeChampDownAction
  | OnSortTypeDeChampsAction
  | RefreshAction;

export default function typeDeChampsReducer(
  state: State,
  action: Action
): State {
  switch (action.type) {
    case 'addNewTypeDeChamp':
      return addNewTypeDeChamp(state, state.typeDeChamps, action.done);
    case 'addNewRepetitionTypeDeChamp':
      return addNewRepetitionTypeDeChamp(
        state,
        state.typeDeChamps,
        action.params,
        action.done
      );
    case 'updateTypeDeChamp':
      return updateTypeDeChamp(
        state,
        state.typeDeChamps,
        action.params,
        action.done
      );
    case 'removeTypeDeChamp':
      return removeTypeDeChamp(
        state,
        state.typeDeChamps,
        action.params,
        action.done
      );
    case 'moveTypeDeChampUp':
      return moveTypeDeChampUp(state, state.typeDeChamps, action.params);
    case 'moveTypeDeChampDown':
      return moveTypeDeChampDown(state, state.typeDeChamps, action.params);
    case 'onSortTypeDeChamps':
      return onSortTypeDeChamps(state, state.typeDeChamps, action.params);
    case 'refresh':
      return {
        ...state,
        typeDeChamps: [...state.typeDeChamps],
        estimatedFillDuration: action.params.estimatedFillDuration
      };
  }
}

function addTypeDeChamp(
  state: State,
  typeDeChamps: TypeDeChamp[],
  insertAfter: { index: number; target: HTMLDivElement } | null,
  done: (estimatedFillDuration: number) => void
) {
  const typeDeChamp = {
    ...state.defaultTypeDeChampAttributes
  };

  createTypeDeChampOperation(typeDeChamp, state.queue)
    .then(async () => {
      if (insertAfter) {
        // Move the champ to the correct position server-side
        await moveTypeDeChampOperation(
          typeDeChamp as TypeDeChamp,
          insertAfter.index,
          state.queue
        );
      }
      state.flash.success();
      const estimatedFillDuration = await estimateFillDuration(state.queue);
      done(estimatedFillDuration);
      if (insertAfter) {
        insertAfter.target.nextElementSibling?.scrollIntoView({
          behavior: 'smooth',
          block: 'start',
          inline: 'nearest'
        });
      }
    })
    .catch((message) => state.flash.error(message));

  let newTypeDeChamps: TypeDeChamp[] = [
    ...typeDeChamps,
    typeDeChamp as TypeDeChamp
  ];
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

function addNewTypeDeChamp(
  state: State,
  typeDeChamps: TypeDeChamp[],
  done: (estimatedFillDuration: number) => void
) {
  return addTypeDeChamp(state, typeDeChamps, findItemToInsertAfter(), done);
}

function addNewRepetitionTypeDeChamp(
  state: State,
  typeDeChamps: TypeDeChamp[],
  { typeDeChamp }: AddNewRepetitionTypeDeChampAction['params'],
  done: (estimatedFillDuration: number) => void
) {
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

function updateTypeDeChamp(
  state: State,
  typeDeChamps: TypeDeChamp[],
  { typeDeChamp, field, value }: UpdateTypeDeChampAction['params'],
  done: (estimatedFillDuration: number) => void
) {
  if (field == 'type_champ' && !typeDeChamp.drop_down_list_value) {
    switch (value) {
      case 'linked_drop_down_list':
        typeDeChamp.drop_down_list_value =
          '--Fromage--\nbleu de sassenage\npicodon\n--Dessert--\néclair\ntarte aux pommes\n';
        break;
      case 'drop_down_list':
      case 'multiple_drop_down_list':
        typeDeChamp.drop_down_list_value = 'Premier choix\nDeuxième choix';
    }
  }

  if (field.startsWith('options.')) {
    const [, optionsField] = field.split('.');
    typeDeChamp.editable_options = typeDeChamp.editable_options || {};
    typeDeChamp.editable_options[optionsField] = value as string;
  } else {
    Object.assign(typeDeChamp, { [field]: value });
  }

  getUpdateHandler(typeDeChamp, state)(done);

  return {
    ...state,
    typeDeChamps: [...typeDeChamps]
  };
}

function removeTypeDeChamp(
  state: State,
  typeDeChamps: TypeDeChamp[],
  { typeDeChamp }: RemoveTypeDeChampAction['params'],
  done: (estimatedFillDuration: number) => void
) {
  destroyTypeDeChampOperation(typeDeChamp, state.queue)
    .then(() => {
      state.flash.success();
      return estimateFillDuration(state.queue);
    })
    .then((estimatedFillDuration: number) => {
      done(estimatedFillDuration);
    })
    .catch((message) => state.flash.error(message));

  return {
    ...state,
    typeDeChamps: arrayRemove(typeDeChamps, typeDeChamp)
  };
}

function moveTypeDeChampUp(
  state: State,
  typeDeChamps: TypeDeChamp[],
  { typeDeChamp }: MoveTypeDeChampUpAction['params']
) {
  const oldIndex = typeDeChamps.indexOf(typeDeChamp);
  const newIndex = oldIndex - 1;

  moveTypeDeChampOperation(typeDeChamp, newIndex, state.queue)
    .then(() => state.flash.success())
    .catch((message) => state.flash.error(message));

  return {
    ...state,
    typeDeChamps: arrayMove(typeDeChamps, oldIndex, newIndex)
  };
}

function moveTypeDeChampDown(
  state: State,
  typeDeChamps: TypeDeChamp[],
  { typeDeChamp }: MoveTypeDeChampDownAction['params']
) {
  const oldIndex = typeDeChamps.indexOf(typeDeChamp);
  const newIndex = oldIndex + 1;

  moveTypeDeChampOperation(typeDeChamp, newIndex, state.queue)
    .then(() => state.flash.success())
    .catch((message) => state.flash.error(message));

  return {
    ...state,
    typeDeChamps: arrayMove(typeDeChamps, oldIndex, newIndex)
  };
}

function onSortTypeDeChamps(
  state: State,
  typeDeChamps: TypeDeChamp[],
  { oldIndex, newIndex }: OnSortTypeDeChampsAction['params']
) {
  moveTypeDeChampOperation(typeDeChamps[oldIndex], newIndex, state.queue)
    .then(() => state.flash.success())
    .catch((message) => state.flash.error(message));

  return {
    ...state,
    typeDeChamps: arrayMove(typeDeChamps, oldIndex, newIndex)
  };
}

function arrayRemove<T>(array: T[], item: T) {
  array = Array.from(array);
  array.splice(array.indexOf(item), 1);
  return array;
}

function arrayMove<T>(array: T[], from: number, to: number) {
  array = Array.from(array);
  array.splice(to < 0 ? array.length + to : to, 0, array.splice(from, 1)[0]);
  return array;
}

const updateHandlers = new WeakMap();
function getUpdateHandler(
  typeDeChamp: TypeDeChamp,
  { queue, flash }: { queue: OperationsQueue; flash: Flash }
) {
  let handler = updateHandlers.get(typeDeChamp);
  if (!handler) {
    handler = debounce(
      (done: (estimatedFillDuration: number) => void) =>
        updateTypeDeChampOperation(typeDeChamp, queue)
          .then(() => {
            flash.success();
            return estimateFillDuration(queue);
          })
          .then((estimatedFillDuration: number) => {
            done(estimatedFillDuration);
          })
          .catch((message) => flash.error(message)),
      200
    );
    updateHandlers.set(typeDeChamp, handler);
  }
  return handler;
}

function findItemToInsertAfter() {
  const target = getLastVisibleTypeDeChamp();

  if (target) {
    return {
      target,
      index: parseInt(target.dataset.index ?? '0') + 1
    };
  } else {
    return null;
  }
}

function getLastVisibleTypeDeChamp() {
  const typeDeChamps =
    document.querySelectorAll<HTMLDivElement>('[data-in-view]');
  const target = typeDeChamps[typeDeChamps.length - 1];

  if (target) {
    const parentTarget = target.closest<HTMLDivElement>('[data-repetition]');
    if (parentTarget) {
      return parentTarget;
    }
    return target;
  }
}
