import React, { useReducer } from 'react';
import PropTypes from 'prop-types';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';

import { SortableContainer, addChampLabel } from '../utils';
import TypeDeChamp from './TypeDeChamp';
import typeDeChampsReducer from '../typeDeChampsReducer';

function TypeDeChampCondition({ isVisible, state: parentState, typeDeChamp }) {
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
        <button
          className="button"
          onClick={() =>
            dispatch({
              type: 'addNewConditionTypeDeChamp',
              params: { typeDeChamp },
              done: () => dispatch({ type: 'refresh' })
            })
          }
        >
          <FontAwesomeIcon icon="plus" size="sm" />
          &nbsp;&nbsp;
          {addChampLabel(state.isAnnotation)}
        </button>
      </div>
    );
  }
  return null;
}

TypeDeChampCondition.propTypes = {
  isVisible: PropTypes.bool,
  state: PropTypes.object,
  typeDeChamp: PropTypes.object
};

export default TypeDeChampCondition;
