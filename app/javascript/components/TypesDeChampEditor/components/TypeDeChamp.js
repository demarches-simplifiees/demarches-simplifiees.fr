import React from 'react';
import PropTypes from 'prop-types';
import { sortableElement, sortableHandle } from 'react-sortable-hoc';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';

import DescriptionInput from './DescriptionInput';
import LibelleInput from './LibelleInput';
import MandatoryInput from './MandatoryInput';
import MoveButton from './MoveButton';
import TypeDeChampCarteOption from './TypeDeChampCarteOption';
import TypeDeChampCarteOptions from './TypeDeChampCarteOptions';
import TypeDeChampDropDownOptions from './TypeDeChampDropDownOptions';
import TypeDeChampPieceJustificative from './TypeDeChampPieceJustificative';
import TypeDeChampRepetitionOptions from './TypeDeChampRepetitionOptions';
import TypeDeChampTypesSelect from './TypeDeChampTypesSelect';

const TypeDeChamp = sortableElement(
  ({ typeDeChamp, dispatch, idx: index, isFirstItem, isLastItem, state }) => {
    const isDropDown = [
      'drop_down_list',
      'multiple_drop_down_list',
      'linked_drop_down_list'
    ].includes(typeDeChamp.type_champ);
    const isFile = typeDeChamp.type_champ === 'piece_justificative';
    const isCarte = typeDeChamp.type_champ === 'carte';
    const isExplication = typeDeChamp.type_champ === 'explication';
    const isHeaderSection = typeDeChamp.type_champ === 'header_section';
    const isRepetition = typeDeChamp.type_champ === 'repetition';
    const canBeMandatory =
      !isHeaderSection && !isExplication && !state.isAnnotation;

    const updateHandlers = createUpdateHandlers(
      dispatch,
      typeDeChamp,
      index,
      state.prefix
    );

    const typeDeChampsTypesForRepetition = state.typeDeChampsTypes.filter(
      ([, type]) => !EXCLUDE_FROM_REPETITION.includes(type)
    );

    return (
      <div
        ref={isLastItem ? state.lastTypeDeChampRef : null}
        data-index={index}
        className={`type-de-champ form flex column justify-start ${
          isHeaderSection ? 'type-header-section' : ''
        }`}
      >
        <div
          className={`flex justify-start section head ${
            !isHeaderSection ? 'hr' : ''
          }`}
        >
          <DragHandle />
          <TypeDeChampTypesSelect
            handler={updateHandlers.type_champ}
            options={state.typeDeChampsTypes}
          />
          <div className="flex justify-start delete">
            <button
              className="button small icon-only danger"
              onClick={() =>
                dispatch({ type: 'removeTypeDeChamp', params: { typeDeChamp } })
              }
            >
              <FontAwesomeIcon icon="trash" title="Supprimer" />
            </button>
          </div>
        </div>
        <div
          className={`flex justify-start section ${
            isDropDown || isFile || isCarte ? 'hr' : ''
          }`}
        >
          <div className="flex column justify-start">
            <MoveButton
              isEnabled={!isFirstItem}
              icon="arrow-up"
              onClick={() =>
                dispatch({
                  type: 'moveTypeDeChampUp',
                  params: { typeDeChamp }
                })
              }
            />
            <MoveButton
              isEnabled={!isLastItem}
              icon="arrow-down"
              onClick={() =>
                dispatch({
                  type: 'moveTypeDeChampDown',
                  params: { typeDeChamp }
                })
              }
            />
          </div>
          <div className="flex column justify-start">
            <LibelleInput handler={updateHandlers.libelle} isVisible={true} />
            <MandatoryInput
              handler={updateHandlers.mandatory}
              isVisible={canBeMandatory}
            />
          </div>
          <div className="flex justify-start">
            <DescriptionInput
              isVisible={!isHeaderSection}
              handler={updateHandlers.description}
            />
          </div>
        </div>
        <div className="flex justify-start section shift-left">
          <TypeDeChampDropDownOptions
            isVisible={isDropDown}
            handler={updateHandlers.drop_down_list_value}
          />
          <TypeDeChampPieceJustificative
            isVisible={isFile}
            directUploadUrl={state.directUploadUrl}
            filename={typeDeChamp.piece_justificative_template_filename}
            handler={updateHandlers.piece_justificative_template}
            url={typeDeChamp.piece_justificative_template_url}
          />
          <TypeDeChampCarteOptions isVisible={isCarte}>
            <TypeDeChampCarteOption
              label="Quartiers prioritaires"
              handler={updateHandlers.quartiers_prioritaires}
            />
            <TypeDeChampCarteOption
              label="Cadastres"
              handler={updateHandlers.cadastres}
            />
            <TypeDeChampCarteOption
              label="Parcelles Agricoles"
              handler={updateHandlers.parcelles_agricoles}
            />
          </TypeDeChampCarteOptions>
          <TypeDeChampRepetitionOptions
            isVisible={isRepetition}
            state={{
              ...state,
              typeDeChampsTypes: typeDeChampsTypesForRepetition,
              prefix: `repetition-${index}`,
              typeDeChamps: typeDeChamp.types_de_champ || []
            }}
            typeDeChamp={typeDeChamp}
          />
        </div>
      </div>
    );
  }
);

TypeDeChamp.propTypes = {
  dispatch: PropTypes.func,
  idx: PropTypes.number,
  isFirstItem: PropTypes.bool,
  isLastItem: PropTypes.bool,
  state: PropTypes.object,
  typeDeChamp: PropTypes.object
};

const DragHandle = sortableHandle(() => (
  <div className="handle small icon-only icon move-handle">
  </div>
));

function createUpdateHandler(dispatch, typeDeChamp, field, index, prefix) {
  return {
    id: `${prefix ? `${prefix}-` : ''}champ-${index}-${field}`,
    name: field,
    value: typeDeChamp[field],
    onChange: ({ target }) =>
      dispatch({
        type: 'updateTypeDeChamp',
        params: {
          typeDeChamp,
          field,
          value: readValue(target)
        },
        done: () => dispatch({ type: 'refresh' })
      })
  };
}

function createUpdateHandlers(dispatch, typeDeChamp, index, prefix) {
  return FIELDS.reduce((handlers, field) => {
    handlers[field] = createUpdateHandler(
      dispatch,
      typeDeChamp,
      field,
      index,
      prefix
    );
    return handlers;
  }, {});
}

export const FIELDS = [
  'cadastres',
  'description',
  'drop_down_list_value',
  'libelle',
  'mandatory',
  'order_place',
  'parcelles_agricoles',
  'parent_id',
  'piece_justificative_template',
  'private',
  'quartiers_prioritaires',
  'type_champ'
];

function readValue(input) {
  return input.type === 'checkbox' ? input.checked : input.value;
}

const EXCLUDE_FROM_REPETITION = [
  'carte',
  'dossier_link',
  'repetition',
  'siret'
];

export default TypeDeChamp;
