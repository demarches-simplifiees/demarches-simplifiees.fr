import React, { useReducer } from 'react';
import { PlusIcon, ArrowCircleDownIcon } from '@heroicons/react/outline';

import { SortableContainer, addChampLabel } from '../utils';
import { TypeDeChampComponent } from './TypeDeChamp';
import typeDeChampsReducer from '../typeDeChampsReducer';
import type { TypeDeChamp, State } from '../types';

type TypeDeChampsProps = {
  state: State;
  typeDeChamps: TypeDeChamp[];
};

export function TypeDeChamps({
  state: rootState,
  typeDeChamps
}: TypeDeChampsProps) {
  const [state, dispatch] = useReducer(typeDeChampsReducer, {
    ...rootState,
    typeDeChamps
  });

  const hasUnsavedChamps = state.typeDeChamps.some(
    (tdc) => tdc.id == undefined
  );

  return (
    <div className="champs-editor">
      <SortableContainer
        onSortEnd={(params) => dispatch({ type: 'onSortTypeDeChamps', params })}
        lockAxis="y"
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
      {state.typeDeChamps.length === 0 && (
        <h2>
          <ArrowCircleDownIcon className="icon-size" />
          &nbsp;&nbsp;Cliquez sur le bouton «&nbsp;
          {addChampLabel(state.isAnnotation)}&nbsp;» pour créer votre premier
          champ.
        </h2>
      )}
      <div className="footer">&nbsp;</div>
      <div className="buttons">
        <button
          className="button"
          disabled={hasUnsavedChamps}
          onClick={() =>
            dispatch({
              type: 'addNewTypeDeChamp',
              done: () => dispatch({ type: 'refresh' })
            })
          }
        >
          <PlusIcon className="icon-size" />
          &nbsp;&nbsp;
          {addChampLabel(state.isAnnotation)}
        </button>
        <a className="button accepted" href={state.continuerUrl}>
          Continuer &gt;
        </a>
      </div>
    </div>
  );
}
