import React, { useReducer } from 'react';
import { PlusIcon } from '@heroicons/react/outline';

import { SortableContainer, addChampLabel } from '../utils';
import { TypeDeChampComponent } from './TypeDeChamp';
import typeDeChampsReducer from '../typeDeChampsReducer';
import type { State, TypeDeChamp } from '../types';

export function TypeDeChampRepetitionOptions({
  isVisible,
  state: parentState,
  typeDeChamp
}: {
  isVisible: boolean;
  state: State;
  typeDeChamp: TypeDeChamp;
}) {
  const [state, dispatch] = useReducer(typeDeChampsReducer, parentState);

  if (isVisible) {
    return (
      <div className="repetition flex-grow cell">
        <SortableContainer
          onSortEnd={(params) =>
            dispatch({ type: 'onSortTypeDeChamps', params })
          }
          useDragHandle
        >
          {state.typeDeChamps.map((typeDeChamp, index) => (
            <TypeDeChampComponent
              dispatch={dispatch}
              idx={index}
              index={index}
              isFirstItem={index === 0}
              isLastItem={index === state.typeDeChamps.length - 1}
              key={`champ-${typeDeChamp.id}`}
              state={state}
              typeDeChamp={typeDeChamp}
            />
          ))}
        </SortableContainer>
        <button
          className="button"
          onClick={() =>
            dispatch({
              type: 'addNewRepetitionTypeDeChamp',
              params: { typeDeChamp },
              done: (estimatedFillDuration: number) =>
                dispatch({ type: 'refresh', params: { estimatedFillDuration } })
            })
          }
        >
          <PlusIcon className="icon-size" />
          &nbsp;&nbsp;
          {addChampLabel(state.isAnnotation)}
        </button>
      </div>
    );
  }
  return null;
}
