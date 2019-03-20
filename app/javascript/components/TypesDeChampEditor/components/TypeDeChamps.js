import React, { useReducer, useRef } from 'react';
import PropTypes from 'prop-types';

import { SortableContainer, addChampLabel } from '../utils';
import TypeDeChamp from './TypeDeChamp';
import typeDeChampsReducer from '../typeDeChampsReducer';

function TypeDeChamps({ state: rootState, typeDeChamps }) {
  const lastTypeDeChampRef = useRef(null);
  const [state, dispatch] = useReducer(typeDeChampsReducer, {
    ...rootState,
    lastTypeDeChampRef,
    typeDeChamps
  });

  if (state.typeDeChamps.length === 0) {
    dispatch({
      type: 'addFirstTypeDeChamp',
      done: () => dispatch({ type: 'refresh' })
    });
  }

  return (
    <div className="champs-editor">
      <SortableContainer
        onSortEnd={params => dispatch({ type: 'onSortTypeDeChamps', params })}
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
      <div className="footer">&nbsp;</div>
      <div className="buttons">
        <button
          className="button"
          onClick={() =>
            dispatch({
              type: 'addNewTypeDeChamp',
              done: () => dispatch({ type: 'refresh' })
            })
          }
        >
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
