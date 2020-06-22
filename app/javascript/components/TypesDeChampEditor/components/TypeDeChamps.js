import React, { useReducer } from 'react';
import PropTypes from 'prop-types';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';

import { SortableContainer, addChampLabel } from '../utils';
import TypeDeChamp from './TypeDeChamp';
import typeDeChampsReducer from '../typeDeChampsReducer';

function TypeDeChamps({ state: rootState, typeDeChamps }) {
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
          <TypeDeChamp
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
          <FontAwesomeIcon icon="arrow-circle-down" />
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
          <FontAwesomeIcon icon="plus" size="sm" />
          &nbsp;&nbsp;
          {addChampLabel(state.isAnnotation)}
        </button>
        <button
          className="button primary"
          onClick={() => state.flash.success()}
        >
          Enregistrer
        </button>
      </div>
    </div>
  );
}

TypeDeChamps.propTypes = {
  state: PropTypes.object,
  typeDeChamps: PropTypes.array
};

export default TypeDeChamps;
