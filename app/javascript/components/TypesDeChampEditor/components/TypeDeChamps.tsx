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

  const formattedEstimatedFillDuration = state.estimatedFillDuration
    ? Math.max(1, Math.round(state.estimatedFillDuration / 60)) + ' mn'
    : '';

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
              done: (estimatedFillDuration: number) => {
                dispatch({
                  type: 'refresh',
                  params: { estimatedFillDuration }
                });
              }
            })
          }
        >
          <PlusIcon className="icon-size" />
          &nbsp;&nbsp;
          {addChampLabel(state.isAnnotation)}
        </button>
        {state.estimatedFillDuration > 0 && (
          <span className="fill-duration">
            Durée de remplissage estimée&nbsp;:{' '}
            <a
              href="https://doc.demarches-simplifiees.fr/tutoriels/tutoriel-administrateur#g.-estimation-de-la-duree-de-remplissage"
              target="_blank"
              rel="noopener noreferrer"
            >
              {formattedEstimatedFillDuration}
            </a>
          </span>
        )}
        <a className="button accepted" href={state.continuerUrl}>
          Continuer &gt;
        </a>
      </div>
    </div>
  );
}
